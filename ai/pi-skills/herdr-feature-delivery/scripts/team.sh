#!/usr/bin/env bash
# Deterministic layout, launch, candidate freezing, and teardown for the
# herdr-feature-delivery skill. Run `team.sh help` for usage.
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEAMS_ROOT="${FEATURE_TEAMS_ROOT:-$HOME/.pi/feature-teams}"
AGENT_ROLES=(implementer reviewer tophatter)
EXCLUDED_TOOLS="ask,memory_read,memory_update,memory_append,memory_search,memory_list,subagent,team_spawn,adversarial_review,worktree"
HERDR="${HERDR_BIN_PATH:-$(command -v herdr || true)}"

usage() {
  cat <<'EOF'
Usage: team.sh <command> [args]

Planner commands
  up <slug> --worktree DIR [--title TEXT] [--base SHA] [--pack NAME]...
            [--model ROLE=PROVIDER/ID:THINKING]... [--pane PLANNER_PANE] [--allow-dirty]
      Build the planner/implementer/reviewer/tophatter/shell/status layout around the planner pane.
      Rerunning up for an existing slug reuses its folder, base, packs, sessions, and watched PR.
  start <role> [--resume]           Start implementer, reviewer, or tophatter with its model and context.
  send <role> <message>             Prompt a role and return once it is working. Never waits for completion.
  freeze <round>                    Save the worktree diff against base as candidate rN.
  verify <round> [--ref REF] [--base SHA]
                                    Check that REF's committed diff is byte-identical to candidate rN.
  pr <number|url> [--delta]         Point the status pane at the published PR. Gitstream by default;
                                    a delta.shopify.io URL or --delta selects a Delta PR.
  notify <message> | --clear        Tell Gaurav the planner needs him, or clear the request.
  down [--force] [--keep-shell]     Close the panes up created and keep the team folder.

Reviewer commands (two-reviewer rounds)
  xreview start <round> review|crosscheck
                                    Run the cross-reviewer headless in the background.
  xreview wait [--timeout SECONDS]  Block until it finishes (default 1800). Exit 2 means still running.
  xreview status                    Running or finished, with report and log paths.
  board                             The status pane's live loop; up starts it.

Shell commands (TEAM_SLUG is preset in the shell pane)
  status                            Pane states, recent ledger entries, and worktree status.
  delta <rA> <rB>                   Diff two frozen candidates.

Every command except up accepts --team SLUG; it defaults to $TEAM_SLUG.
EOF
}

die() { echo "team.sh: $*" >&2; exit 1; }
warn() { echo "team.sh: $*" >&2; }

require_herdr() {
  [[ "${HERDR_ENV:-}" == 1 ]] || die "not running inside Herdr (HERDR_ENV != 1)"
  [[ -x "$HERDR" ]] || die "herdr binary not found"
  command -v jq >/dev/null || die "jq is required"
}

default_model() {
  case "$1" in
    implementer) echo "anthropic/claude-opus-5-5:xhigh" ;;
    reviewer) echo "anthropic/claude-fable-5-1:max" ;;
    cross-reviewer) echo "openai-1m/gpt-6-astra:xhigh" ;;
    tophatter) echo "openai/gpt-6.1-sol:xhigh" ;;
    *) die "unknown role: $1 (expected one of: ${AGENT_ROLES[*]})" ;;
  esac
}

load_team() {
  [[ -n "${1:-}" ]] || die "no team: pass --team SLUG or set TEAM_SLUG"
  SLUG="$1"
  DIR="$TEAMS_ROOT/$SLUG"
  [[ -f "$DIR/team.json" ]] || die "no team at $DIR"
}

field() { jq -r "$1" "$DIR/team.json"; }

update_team() {
  local tmp
  tmp=$(mktemp)
  jq "$@" "$DIR/team.json" >"$tmp" && mv "$tmp" "$DIR/team.json"
}

ledger() {
  local event=${1//|//}
  printf '| %s | %s |\n' "$(date '+%Y-%m-%d %H:%M')" "${event//$'\n'/ }" >>"$DIR/ledger.md"
}

pane_exists() { "$HERDR" pane get "$1" >/dev/null 2>&1; }

agent_status() {
  "$HERDR" agent get "$1" 2>/dev/null | jq -r '.result.agent.agent_status // empty' || true
}

split_pane() {
  local target=$1 direction=$2 ratio=$3 cwd=$4
  shift 4
  "$HERDR" pane split "$target" --direction "$direction" --ratio "$ratio" --cwd "$cwd" --no-focus "$@" |
    jq -er '.result.pane.pane_id'
}

pack_files() {
  local role=$1 pack roles path
  shift
  [[ "$role" == cross-reviewer ]] && role=reviewer
  for pack in "$@"; do
    while read -r roles path; do
      [[ -z "${roles:-}" || "$roles" == \#* || -z "${path:-}" ]] && continue
      [[ ",$roles," == *",$role,"* ]] || continue
      path=${path/#\~/$HOME}
      if [[ -f "$path" ]]; then echo "$path"; else warn "pack $pack lists a missing file, skipped: $path"; fi
    done <"$SKILL_DIR/packs/$pack.txt"
  done
}

new_untracked() {
  git -C "$1" ls-files --others --exclude-standard | grep -vxF -f "$DIR/untracked-baseline" || true
}

cmd_up() {
  local slug=${1:-}
  [[ -n "$slug" && "$slug" != -* ]] || die "usage: team.sh up <slug> --worktree DIR [options]"
  shift
  [[ "$slug" =~ ^[a-z][a-z0-9-]{0,19}$ ]] || die "slug must match [a-z][a-z0-9-]{0,19}"
  local worktree="" title="" base="" planner="${HERDR_PANE_ID:-}" allow_dirty=0
  local packs=() models='{}' pack
  while (($#)); do
    case "$1" in
      --worktree) worktree=$2; shift 2 ;;
      --title) title=$2; shift 2 ;;
      --base) base=$2; shift 2 ;;
      --pack) packs+=("$2"); shift 2 ;;
      --model)
        [[ "$2" == *=*/*:* ]] || die "--model expects ROLE=PROVIDER/ID:THINKING"
        default_model "${2%%=*}" >/dev/null
        models=$(jq -c --arg r "${2%%=*}" --arg m "${2#*=}" '. + {($r): $m}' <<<"$models")
        shift 2
        ;;
      --pane) planner=$2; shift 2 ;;
      --allow-dirty) allow_dirty=1; shift ;;
      *) die "unknown option for up: $1" ;;
    esac
  done
  require_herdr
  [[ -n "$planner" ]] || die "no planner pane: run inside Herdr or pass --pane"
  [[ -d "$worktree" ]] || die "--worktree must be an existing directory"
  worktree=$(cd "$worktree" && pwd)
  local root branch
  root=$(git -C "$worktree" rev-parse --show-toplevel 2>/dev/null) || die "--worktree is not inside a git repository"
  branch=$(git -C "$root" rev-parse --abbrev-ref HEAD)

  DIR="$TEAMS_ROOT/$slug"
  local previous='{}' pane
  if [[ -f "$DIR/team.json" ]]; then
    previous=$(cat "$DIR/team.json")
    for pane in $(jq -r '.panes | to_entries[] | select(.key != "planner") | .value' <<<"$previous"); do
      pane_exists "$pane" && die "team $slug still has live pane $pane; run team.sh down --team $slug first"
    done
    [[ -n "$base" ]] || base=$(jq -r '.base' <<<"$previous")
    [[ -n "$title" ]] || title=$(jq -r '.title' <<<"$previous")
    if ((${#packs[@]} == 0)); then
      while IFS= read -r pack; do packs+=("$pack"); done < <(jq -r '.packs[]' <<<"$previous")
    fi
    models=$(jq -c --argjson new "$models" '(.models // {}) + $new' <<<"$previous")
  else
    if ((!allow_dirty)) && [[ -n "$(git -C "$root" status --porcelain --untracked-files=no)" ]]; then
      die "worktree has uncommitted tracked changes; commit or isolate them, or pass --allow-dirty if they belong to this feature"
    fi
  fi
  base=$(git -C "$root" rev-parse "${base:-HEAD}^{commit}")
  title=${title:-$slug}
  local have_base=0
  for pack in "${packs[@]}"; do [[ "$pack" == base ]] && have_base=1; done
  ((have_base)) || packs=(base "${packs[@]}")
  for pack in "${packs[@]}"; do [[ -f "$SKILL_DIR/packs/$pack.txt" ]] || die "unknown pack: $pack"; done

  local pane_json tab workspace count
  pane_json=$("$HERDR" pane get "$planner" 2>/dev/null) || die "planner pane $planner not found"
  tab=$(jq -r '.result.pane.tab_id' <<<"$pane_json")
  workspace=$(jq -r '.result.pane.workspace_id' <<<"$pane_json")
  count=$("$HERDR" pane list --workspace "$workspace" | jq --arg t "$tab" '[.result.panes[] | select(.tab_id == $t)] | length')
  [[ "$count" == 1 ]] || die "tab $tab has $count panes; run up from a tab that holds only the planner"

  mkdir -p "$DIR"/{memory/core,memory/knowledge,memory/history/daily,candidates,implementer,reviewer,cross-reviewer,tophatter/evidence,publication}
  echo '{"injection": {"activeProjects": "off", "dailyContext": "off", "knowledge": "off", "history": "off", "autoPersist": "off"}}' >"$DIR/memory/config.json"
  [[ -f "$DIR/untracked-baseline" ]] || git -C "$root" ls-files --others --exclude-standard >"$DIR/untracked-baseline"

  local agent_env=(--env "PI_MEMORY_DIR=$DIR/memory" --env "TEAM_DIR=$DIR" --env "TEAM_SLUG=$slug"
    --env "TEAM_SH=$SKILL_DIR/scripts/team.sh")
  local shell_env=(--env "TEAM_DIR=$DIR" --env "TEAM_SLUG=$slug" --env "TEAM_SH=$SKILL_DIR/scripts/team.sh"
    --env "TEAM_GS=$(command -v gs || echo gs)")
  local shell status implementer reviewer tophatter
  shell=$(split_pane "$planner" right 0.6667 "$worktree" "${shell_env[@]}")
  status=$(split_pane "$shell" down 0.72 "$worktree" "${shell_env[@]}")
  implementer=$(split_pane "$planner" right 0.5 "$worktree" "${agent_env[@]}")
  reviewer=$(split_pane "$planner" down 0.5 "$worktree" "${agent_env[@]}")
  tophatter=$(split_pane "$implementer" down 0.5 "$worktree" "${agent_env[@]}")
  "$HERDR" pane rename "$planner" planner >/dev/null
  "$HERDR" pane rename "$implementer" implementer >/dev/null
  "$HERDR" pane rename "$reviewer" reviewer >/dev/null
  "$HERDR" pane rename "$tophatter" tophatter >/dev/null
  "$HERDR" pane rename "$shell" shell >/dev/null
  "$HERDR" pane rename "$status" status >/dev/null

  jq -n \
    --arg slug "$slug" --arg title "$title" --arg workspace "$workspace" --arg tab "$tab" \
    --arg planner "$planner" --arg implementer "$implementer" --arg reviewer "$reviewer" \
    --arg tophatter "$tophatter" --arg shell "$shell" --arg status "$status" \
    --arg worktree "$worktree" --arg root "$root" --arg branch "$branch" --arg base "$base" \
    --argjson packs "$(printf '%s\n' "${packs[@]}" | jq -R . | jq -sc .)" \
    --argjson models "$models" --argjson previous "$previous" --arg now "$(date -u +%FT%TZ)" \
    '{slug: $slug, title: $title, workspace: $workspace, tab: $tab,
      panes: {planner: $planner, implementer: $implementer, reviewer: $reviewer, tophatter: $tophatter, shell: $shell, status: $status},
      worktree: $worktree, root: $root, branch: $branch, base: $base, packs: $packs, models: $models,
      sessions: ($previous.sessions // {}), pr: ($previous.pr // null),
      created_at: ($previous.created_at // $now), updated_at: $now}' \
    >"$DIR/team.json"

  cat >"$DIR/context.md" <<EOF
# Feature team context

- Feature: $title
- Agreed plan: $DIR/plan.md
- Team folder: $DIR
- Worktree: $worktree
- Branch: $branch
- Base commit: $base
- Planner pane: $planner
- Gaurav's shell pane: $shell. Never type into, read, or close it.
- Team tool: $SKILL_DIR/scripts/team.sh (also in \$TEAM_SH)

After writing the report for an assignment, ping the planner exactly once:

    $HERDR agent prompt $planner "DONE <your role> <assignment>: <report path> — <one-line result>"
    $HERDR agent prompt $planner "BLOCKED <your role> <assignment>: <report path> — <what you need>"
EOF

  if [[ ! -f "$DIR/ledger.md" ]]; then
    cat >"$DIR/ledger.md" <<EOF
# $title ($slug)

One line per transition. team.sh logs its own actions; the planner logs reports, verdicts, gates, and Gaurav's decisions.

| When | Event |
|---|---|
EOF
  fi
  ledger "Team up in $tab: planner $planner, implementer $implementer, reviewer $reviewer, tophatter $tophatter, shell $shell, status $status. Base ${base:0:12}, packs ${packs[*]}"
  "$HERDR" pane run "$status" "$SKILL_DIR/scripts/team.sh board --team $slug" >/dev/null

  echo "team $slug is up in $tab"
  echo "  planner $planner | implementer $implementer | reviewer $reviewer | tophatter $tophatter | shell $shell | status $status"
  echo "  folder $DIR"
  echo "  worktree $worktree ($branch, base ${base:0:12})"
}

cmd_start() {
  local team=${TEAM_SLUG:-} role="" resume=0
  while (($#)); do
    case "$1" in
      --team) team=$2; shift 2 ;;
      --resume) resume=1; shift ;;
      -*) die "unknown option for start: $1" ;;
      *) role=$1; shift ;;
    esac
  done
  [[ "$role" != cross-reviewer ]] || die "the cross-reviewer runs inside the reviewer; see team.sh xreview"
  default_model "$role" >/dev/null
  require_herdr
  load_team "$team"
  local spec pane model thinking
  spec=$(field ".models[\"$role\"] // empty")
  spec=${spec:-$(default_model "$role")}
  model=${spec%:*}
  thinking=${spec##*:}
  pane=$(field ".panes[\"$role\"]")
  pane_exists "$pane" || die "$role pane $pane no longer exists; rerun team.sh up $SLUG"

  local file pack packs=() system="$DIR/$role/system.md"
  while IFS= read -r pack; do packs+=("$pack"); done < <(field '.packs[]')
  {
    cat "$SKILL_DIR/references/roles/common.md"
    printf '\n'
    cat "$SKILL_DIR/references/roles/$role.md"
    printf '\n'
    cat "$DIR/context.md"
    while IFS= read -r file; do
      printf '\n---\nPreference file: %s\n\n' "$file"
      cat "$file"
    done < <(pack_files "$role" "${packs[@]}")
  } >"$system"

  local excluded=$EXCLUDED_TOOLS
  [[ "$role" == reviewer ]] && excluded+=",edit"
  local args=(--model "$model" --thinking "$thinking" --exclude-tools "$excluded" --append-system-prompt "$system")
  if ((resume)); then
    local session
    session=$(field ".sessions[\"$role\"] // empty")
    [[ -n "$session" && -f "$session" ]] || die "no recorded session for $role"
    args+=(--session "$session")
  fi
  local launch="pi ${args[*]}"
  ((${#launch} < 1000)) || die "launch command is ${#launch} characters; herdr truncates typed commands at 1024"

  "$HERDR" agent start "$SLUG-$role" --kind pi --pane "$pane" --timeout 90000 -- "${args[@]}" >/dev/null
  local session_path
  session_path=$("$HERDR" agent get "$pane" | jq -r '.result.agent.agent_session.value // empty')
  [[ -z "$session_path" ]] || update_team --arg r "$role" --arg s "$session_path" '.sessions[$r] = $s'
  ledger "Started $role in $pane ($model:$thinking)$( ((resume)) && echo ", resumed")"
  echo "$role started in $pane ($model:$thinking)"
  echo "  session ${session_path:-not reported yet}"
}

cmd_send() {
  local team=${TEAM_SLUG:-} role="" message=""
  while (($#)); do
    case "$1" in
      --team) team=$2; shift 2 ;;
      *)
        if [[ -z "$role" ]]; then role=$1; else message=${message:+$message }$1; fi
        shift
        ;;
    esac
  done
  [[ -n "$role" && -n "$message" ]] || die "usage: team.sh send <role> <message>"
  [[ "$role" != cross-reviewer ]] || die "the cross-reviewer runs inside the reviewer; see team.sh xreview"
  require_herdr
  load_team "$team"
  default_model "$role" >/dev/null
  local pane
  pane=$(field ".panes[\"$role\"]")
  "$HERDR" agent prompt "$pane" "$message" --wait --until working --timeout 30000 >/dev/null ||
    die "$role did not start working; inspect it with: $HERDR agent read $pane --source recent-unwrapped --lines 60"
  ledger "Sent $role: ${message:0:160}"
  echo "$role is working. React to its DONE or BLOCKED ping; do not wait on it."
}

cmd_freeze() {
  local team=${TEAM_SLUG:-} round=""
  while (($#)); do
    case "$1" in
      --team) team=$2; shift 2 ;;
      *) round=${1#r}; shift ;;
    esac
  done
  [[ "$round" =~ ^[0-9]+$ ]] || die "usage: team.sh freeze <round>"
  load_team "$team"
  local root base out
  root=$(field .root)
  base=$(field .base)
  out="$DIR/candidates/r$round"
  [[ ! -e "$out" ]] || die "candidate r$round already exists"
  mkdir -p "$out/files"
  : >"$out/deleted"

  local untracked f
  untracked=$(new_untracked "$root")
  {
    git -C "$root" diff --binary --no-color --no-ext-diff "$base"
    while IFS= read -r f; do
      [[ -n "$f" ]] || continue
      git -C "$root" diff --binary --no-color --no-ext-diff --no-index -- /dev/null "$f" || true
    done <<<"$untracked"
  } >"$out/patch"

  {
    git -C "$root" diff --name-only --no-renames "$base"
    printf '%s\n' "$untracked"
  } | while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    if [[ -e "$root/$f" || -L "$root/$f" ]]; then
      mkdir -p "$out/files/$(dirname "$f")"
      cp -P "$root/$f" "$out/files/$f"
    else
      printf '%s\n' "$f" >>"$out/deleted"
    fi
  done

  local sha stat count
  sha=$(shasum -a 256 "$out/patch" | cut -d' ' -f1)
  echo "$sha" >"$out/sha256"
  stat=$(git -C "$root" diff --shortstat "$base" | sed 's/^ *//')
  count=$(grep -c . <<<"$untracked" || true)
  ledger "Froze r$round: sha256 $sha (${stat:-no tracked changes}; $count new untracked)"
  echo "r$round sha256 $sha"
  echo "  ${stat:-no tracked changes}; $count new untracked file(s)"
  echo "  $out/patch"
}

candidate_paths() {
  local cand=$1
  (cd "$cand/files" && find . \( -type f -o -type l \) | sed 's|^\./||')
  cat "$cand/deleted"
}

materialize() {
  local cand=$1 dest=$2 path=$3 root=$4 base=$5
  if [[ -e "$cand/files/$path" || -L "$cand/files/$path" ]]; then
    mkdir -p "$dest/$(dirname "$path")"
    cp -P "$cand/files/$path" "$dest/$path"
  elif grep -qxF -- "$path" "$cand/deleted"; then
    :
  elif git -C "$root" cat-file -e "$base:$path" 2>/dev/null; then
    mkdir -p "$dest/$(dirname "$path")"
    git -C "$root" show "$base:$path" >"$dest/$path"
  fi
}

cmd_delta() {
  local team=${TEAM_SLUG:-} rounds=()
  while (($#)); do
    case "$1" in
      --team) team=$2; shift 2 ;;
      *) rounds+=("${1#r}"); shift ;;
    esac
  done
  ((${#rounds[@]} == 2)) || die "usage: team.sh delta <rA> <rB>"
  load_team "$team"
  local a="$DIR/candidates/r${rounds[0]}" b="$DIR/candidates/r${rounds[1]}" root base tmp path
  [[ -d "$a" && -d "$b" ]] || die "unknown candidate; frozen: $(ls "$DIR/candidates" | tr '\n' ' ')"
  root=$(field .root)
  base=$(field .base)
  tmp=$(mktemp -d)
  trap "rm -rf '$tmp'" EXIT
  mkdir -p "$tmp/r${rounds[0]}" "$tmp/r${rounds[1]}"
  { candidate_paths "$a"; candidate_paths "$b"; } | sort -u | while IFS= read -r path; do
    [[ -n "$path" ]] || continue
    materialize "$a" "$tmp/r${rounds[0]}" "$path" "$root" "$base"
    materialize "$b" "$tmp/r${rounds[1]}" "$path" "$root" "$base"
  done
  if (cd "$tmp" && git diff --no-index --quiet "r${rounds[0]}" "r${rounds[1]}"); then
    echo "r${rounds[0]} and r${rounds[1]} are identical"
  else
    (cd "$tmp" && git diff --no-index --no-prefix "r${rounds[0]}" "r${rounds[1]}") || true
  fi
}

cmd_verify() {
  local team=${TEAM_SLUG:-} round="" ref=HEAD base=""
  while (($#)); do
    case "$1" in
      --team) team=$2; shift 2 ;;
      --ref) ref=$2; shift 2 ;;
      --base) base=$2; shift 2 ;;
      *) round=${1#r}; shift ;;
    esac
  done
  [[ "$round" =~ ^[0-9]+$ ]] || die "usage: team.sh verify <round> [--ref REF] [--base SHA]"
  load_team "$team"
  local cand="$DIR/candidates/r$round" root expected actual path mismatches=0
  [[ -d "$cand" ]] || die "candidate r$round does not exist"
  root=$(field .root)
  base=${base:-$(field .base)}
  expected=$(candidate_paths "$cand" | sort -u)
  actual=$(git -C "$root" diff --name-only --no-renames "$base" "$ref" | sort -u)
  if [[ "$expected" != "$actual" ]]; then
    echo "Changed paths differ between r$round and $ref (< candidate, > $ref):"
    diff <(printf '%s\n' "$expected") <(printf '%s\n' "$actual") | grep '^[<>]' || true
    mismatches=1
  fi
  while IFS= read -r path; do
    [[ -n "$path" ]] || continue
    if [[ -e "$cand/files/$path" || -L "$cand/files/$path" ]]; then
      if ! git -C "$root" cat-file -e "$ref:$path" 2>/dev/null; then
        echo "missing at $ref: $path"
        mismatches=1
      elif ! git -C "$root" show "$ref:$path" | cmp -s - "$cand/files/$path"; then
        echo "content differs: $path"
        mismatches=1
      fi
    elif git -C "$root" cat-file -e "$ref:$path" 2>/dev/null; then
      echo "present at $ref but deleted in r$round: $path"
      mismatches=1
    fi
  done <<<"$expected"
  local head
  head=$(git -C "$root" rev-parse --short "$ref")
  if ((mismatches)); then
    ledger "Verify r$round vs $ref ($head): DIFFERENT"
    echo "DIFFERENT: $ref ($head) does not match candidate r$round"
    return 1
  fi
  ledger "Verify r$round vs $ref ($head): IDENTICAL"
  echo "IDENTICAL: $ref ($head) matches candidate r$round ($(grep -c . <<<"$expected") paths)"
}

render_board() {
  local width role pane state states=() latest
  width=$({ stty size </dev/tty; } 2>/dev/null | cut -d' ' -f2) || true
  [[ "$width" =~ ^[0-9]+$ ]] || width=${COLUMNS:-100}
  local checked=""
  [[ ! -f "$DIR/remote-state.json" ]] || checked=" · remote checked $(jq -r '.checked_at[11:16]' "$DIR/remote-state.json")Z"
  printf '%s (%s)   %s%s\n' "$(field .title)" "$SLUG" "$(date '+%H:%M:%S')" "$checked"
  if [[ -s "$DIR/needs-gaurav" ]]; then
    printf '\033[1;33m>> Waiting on Gaurav: %s\033[0m\n' "$(head -n 1 "$DIR/needs-gaurav")"
  fi
  for role in planner implementer reviewer tophatter; do
    pane=$(field ".panes.$role")
    if pane_exists "$pane"; then
      state=$(agent_status "$pane")
      state=${state:-no agent}
    else
      state=closed
    fi
    [[ "$role" != reviewer || -z "$(xreview_pid)" ]] || state+=" (+ cross-reviewer)"
    states+=("$role $state")
  done
  printf '%s\n' "${states[0]} · ${states[1]} · ${states[2]} · ${states[3]}"
  latest=$(ls "$DIR/candidates" 2>/dev/null | sed 's/^r//' | sort -n | tail -1)
  [[ -z "$latest" ]] || echo "candidate r$latest $(cut -c1-12 "$DIR/candidates/r$latest/sha256")"
  local state="$DIR/remote-state.json"
  [[ ! -f "$state" ]] || jq -r 'select(.sync != null) | .sync
    | "sync: \(.relation | gsub("_"; " ")) \u00b7 origin \(.origin) \u00b7 local \(.local[0:7]) \u00b7 Delta \(.delta[0:7]) \u00b7 Gitstream \(.gitstream[0:7]) \u00b7 \(.branch)"' \
    "$state" | cut -c1-"$width"
  if [[ -z "$(field '.pr // empty')" ]]; then
    :
  elif [[ ! -f "$state" || "$(jq -r '.pr // empty' "$state")" != "$(field .pr)" ]]; then
    echo "PR #$(field .pr): first check pending"
  elif [[ "$(jq -r '.head // empty' "$state")" == "" ]]; then
    echo "PR #$(field .pr): the PR tools returned no data at $(jq -r '.checked_at[11:16]' "$state")Z; retrying"
  else
    jq -r --arg provider "$(field '.pr_provider // "gitstream"')" '"\(if $provider == "delta" then "Delta " else "" end)PR #\(.pr) \(.pr_state // "?") @\((.head // "?")[0:7]) · \(if .ci.sha == null then "CI no data" else "CI \(.ci.ok) ok \(.ci.failed | length) failed \(.ci.pending) pending" end) · Binks \(.binks.state // "?") (\(.binks.outstanding)) · \(.comments | length) comments",
      (if (.ci.failed | length) > 0 then "  failed: " + (.ci.failed | join(", ")) else empty end)' "$state"
  fi
  echo "recent:"
  { grep '^| 20' "$DIR/ledger.md" || true; } | tail -n 6 | sed -E 's/^\| [0-9-]+ ([0-9:]+) \| (.*) \|$/  \1 \2/' | cut -c1-"$width"
}

cmd_status() {
  local team=${TEAM_SLUG:-}
  [[ "${1:-}" == --team ]] && team=${2:-}
  require_herdr
  load_team "$team"
  render_board
  echo
  git -C "$(field .root)" status --short | head -20
}

run_with_timeout() {
  local seconds=$1 pid killer status=0
  shift
  "$@" &
  pid=$!
  (sleep "$seconds" && kill "$pid") >/dev/null 2>&1 &
  killer=$!
  wait "$pid" || status=$?
  pkill -P "$killer" 2>/dev/null || true
  kill "$killer" 2>/dev/null || true
  return "$status"
}

fetch_json() {
  local dir=$1 filter=$2 out
  shift 2
  out=$(cd "$dir" && run_with_timeout 120 "$@" 2>/dev/null | jq -c "$filter" 2>/dev/null) || true
  [[ -n "$out" ]] || out='{}'
  echo "$out"
}

remote_tip() {
  local root=$1 remote=$2 branch=$3 out rc=0
  out=$(run_with_timeout 60 git -C "$root" ls-remote --exit-code --refs "$remote" "refs/heads/$branch" 2>/dev/null) || rc=$?
  if ((rc == 0)); then
    echo "${out%%[[:space:]]*}"
  elif ((rc == 2)); then
    echo absent
  else
    echo unknown
  fi
}

sync_relation() {
  local root=$1 delta=$2 gitstream=$3
  if [[ "$delta" == unknown || "$gitstream" == unknown ]]; then
    echo unknown
  elif [[ "$delta" == absent && "$gitstream" == absent ]]; then
    echo unpublished
  elif [[ "$delta" == absent ]]; then
    echo gitstream_only
  elif [[ "$gitstream" == absent ]]; then
    echo delta_only
  elif [[ "$delta" == "$gitstream" ]]; then
    echo in_sync
  elif git -C "$root" merge-base --is-ancestor "$gitstream" "$delta" 2>/dev/null; then
    echo delta_ahead
  elif git -C "$root" merge-base --is-ancestor "$delta" "$gitstream" 2>/dev/null; then
    echo gitstream_ahead
  elif git -C "$root" cat-file -e "$delta^{commit}" 2>/dev/null && git -C "$root" cat-file -e "$gitstream^{commit}" 2>/dev/null; then
    echo diverged
  else
    echo unknown_objects
  fi
}

sync_state() {
  local root=$1 branch=$2 origin=gitstream local delta gitstream
  if [[ -z "$branch" ]] || [[ "$branch" =~ ^(main|master|HEAD)$ ]] ||
    ! git -C "$root" remote get-url delta >/dev/null 2>&1 || ! git -C "$root" remote get-url gitstream >/dev/null 2>&1; then
    echo '{}'
    return
  fi
  [[ "$(git -C "$root" remote get-url origin 2>/dev/null)" == *delta.shopify.io* ]] && origin=delta
  local=$(git -C "$root" rev-parse --verify --quiet "refs/heads/$branch" || echo absent)
  delta=$(remote_tip "$root" delta "$branch")
  gitstream=$(remote_tip "$root" gitstream "$branch")
  jq -n --arg branch "$branch" --arg origin "$origin" --arg local "$local" --arg delta "$delta" --arg gitstream "$gitstream" \
    --arg relation "$(sync_relation "$root" "$delta" "$gitstream")" \
    '{branch: $branch, origin: $origin, local: $local, delta: $delta, gitstream: $gitstream, relation: $relation}'
}

delta_api() {
  local token=$1 path=$2 out
  out=$(printf 'Authorization: Bearer %s\nAccept: application/json\n' "$token" |
    run_with_timeout 60 curl -sf -H @- "https://delta.shopify.io/api/v3$path") || return 1
  jq -e . >/dev/null 2>&1 <<<"$out" || return 1
  echo "$out"
}

fetch_delta_view() {
  local repo=$1 pr=$2 token pull issue inline reviews
  token=$(run_with_timeout 60 /opt/dev/bin/git-credential-dev-delta token 2>/dev/null) || token=""
  [[ -n "$token" ]] || { echo '{}'; return; }
  pull=$(delta_api "$token" "/repos/$repo/pulls/$pr") || pull='{}'
  issue=$(delta_api "$token" "/repos/$repo/issues/$pr/comments?per_page=100") || issue='[]'
  inline=$(delta_api "$token" "/repos/$repo/pulls/$pr/comments?per_page=100") || inline='[]'
  reviews=$(delta_api "$token" "/repos/$repo/pulls/$pr/reviews?per_page=100") || reviews='[]'
  jq -cn --argjson p "$pull" --argjson i "$issue" --argjson c "$inline" --argjson r "$reviews" '
    if ($p.head.sha // null) == null then {} else {
      author: $p.user.login,
      state: (if $p.merged then "merged" else $p.state end),
      headSha: $p.head.sha,
      headRef: $p.head.ref,
      comments: ([($i + $c)[] | {id: (.id | tostring), author: .user.login, url: .html_url}]
        + [$r[] | {id: ("review-" + (.id | tostring)), author: .user.login, url: .html_url, review: .state}])
    } end'
}

refresh_remote() {
  local pr provider worktree root previous branch ci='{}' binks='{}' view='{}' out event planner
  pr=$(field '.pr // empty')
  provider=$(field '.pr_provider // "gitstream"')
  worktree=$(field .worktree)
  root=$(field .root)
  previous=$(jq -c . "$DIR/remote-state.json" 2>/dev/null || echo null)
  if [[ -n "$pr" && "$provider" == delta ]]; then
    view=$(fetch_delta_view "$(field '.pr_repo // "shop/world"')" "$pr")
    local head
    head=$(jq -r '.headSha // empty' <<<"$view")
    [[ -z "$head" ]] || ci=$(fetch_json "$worktree" '{sha, checks: [.checks[] | {name, status, required, url}]}' \
      /opt/dev/bin/devx ci status --commit "$head" --json)
    binks=$(fetch_json "$worktree" '{binks_state, findings: {outstanding: .findings.outstanding}}' \
      /opt/dev/bin/devx binks status "https://delta.shopify.io/$(field '.pr_repo // "shop/world"')/pull/$pr" --json)
  elif [[ -n "$pr" ]]; then
    ci=$(fetch_json "$worktree" '{sha, checks: [.checks[] | {name, status, required, url}]}' \
      /opt/dev/bin/devx ci status --pr "$pr" --json)
    binks=$(fetch_json "$worktree" '{binks_state, findings: {outstanding: .findings.outstanding}}' \
      /opt/dev/bin/devx binks status "$pr" --json)
    view=$(fetch_json "$worktree" '{author: (.author | if type == "object" then (.login // .name) else . end), state, headSha, headRef, comments: [.comments[]? | {id, author: .authorLogin, url}]}' \
      "${TEAM_GS:-gs}" pr view "$pr" --json --comments)
  fi
  branch=$(jq -r '.headRef // empty' <<<"$view")
  [[ -n "$branch" ]] || branch=$(jq -r 'if .pr == $pr then (.head_ref // empty) else empty end' --arg pr "$pr" <<<"$previous")
  [[ -n "$branch" ]] || branch=$(git -C "$root" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
  out=$(jq -n -f "$SKILL_DIR/scripts/pr-watch.jq" --arg pr "$pr" --arg provider "$provider" --arg now "$(date -u +%FT%TZ)" \
    --argjson ci "$ci" --argjson binks "$binks" --argjson view "$view" \
    --argjson sync "$(sync_state "$root" "$branch")" --argjson prev "$previous") || { warn "remote refresh failed"; return 0; }
  jq '.state' <<<"$out" >"$DIR/remote-state.json"
  planner=$(field .panes.planner)
  while IFS= read -r event; do
    [[ -n "$event" ]] || continue
    ledger "Status: $event"
    "$HERDR" agent prompt "$planner" "STATUS ${pr:+${provider/gitstream/} pr #$pr: }$event" >/dev/null 2>&1 ||
      warn "could not ping the planner: $event"
  done < <(jq -r '.events[]' <<<"$out")
}

cmd_board() {
  local team=${TEAM_SLUG:-}
  [[ "${1:-}" == --team ]] && team=${2:-}
  require_herdr
  load_team "$team"
  local every=${TEAM_BOARD_SECONDS:-30} remote_every=${TEAM_BOARD_PR_SECONDS:-180} last=0 watched="" pr now
  if [[ "${TEAM_GS:-}" == /* ]]; then
    PATH="$(dirname "$TEAM_GS"):$PATH"
    export PATH
  fi
  while true; do
    now=$(date +%s)
    pr=$(field '.pr // empty')
    if [[ "$pr" != "$watched" ]] || ((now - last >= remote_every)); then
      refresh_remote || true
      last=$now
      watched=$pr
    fi
    printf '\033[H\033[2J'
    render_board || true
    sleep "$every"
  done
}

cmd_pr() {
  local team=${TEAM_SLUG:-} pr="" provider=gitstream repo=shop/world
  while (($#)); do
    case "$1" in
      --team) team=$2; shift 2 ;;
      --delta) provider=delta; shift ;;
      https://delta.shopify.io/*/pull/*)
        provider=delta
        repo=$(sed -E 's#^https://delta\.shopify\.io/([^/]+/[^/]+)/pull/.*#\1#' <<<"$1")
        pr=$(sed -E 's#^.*/pull/([0-9]+).*#\1#' <<<"$1")
        shift
        ;;
      https://*/pulls/*) pr=$(sed -E 's#^.*/pulls/([0-9]+).*#\1#' <<<"$1"); shift ;;
      *) pr=${1#\#}; shift ;;
    esac
  done
  [[ "$pr" =~ ^[0-9]+$ ]] || die "usage: team.sh pr <number|url> [--delta]"
  load_team "$team"
  update_team --arg pr "$pr" --arg provider "$provider" --arg repo "$repo" '.pr = $pr | .pr_provider = $provider | .pr_repo = $repo'
  ledger "Watching $provider PR #$pr"
  echo "the status pane now watches $provider PR #$pr"
}

cmd_notify() {
  local team=${TEAM_SLUG:-} clear=0 message=""
  while (($#)); do
    case "$1" in
      --team) team=$2; shift 2 ;;
      --clear) clear=1; shift ;;
      *) message=${message:+$message }$1; shift ;;
    esac
  done
  require_herdr
  load_team "$team"
  if ((clear)); then
    rm -f "$DIR/needs-gaurav"
    ledger "Gaurav responded"
    echo "cleared"
    return
  fi
  [[ -n "$message" ]] || die "usage: team.sh notify <what the planner needs> | --clear"
  printf '%s\n' "$message" >"$DIR/needs-gaurav"
  "$HERDR" notification show "$(field .title) needs you" --body "$message" --sound request >/dev/null ||
    warn "herdr notification failed"
  ledger "Asked Gaurav: $message"
  echo "notified Gaurav"
}

cmd_down() {
  local team=${TEAM_SLUG:-} force=0 keep_shell=0
  while (($#)); do
    case "$1" in
      --team) team=$2; shift 2 ;;
      --force) force=1; shift ;;
      --keep-shell) keep_shell=1; shift ;;
      *) die "unknown option for down: $1" ;;
    esac
  done
  require_herdr
  load_team "$team"
  local role pane state
  if ((!force)); then
    for role in "${AGENT_ROLES[@]}"; do
      pane=$(field ".panes.$role")
      state=$(agent_status "$pane")
      [[ "$state" != working && "$state" != blocked ]] || die "$role is $state; pass --force to close it anyway"
    done
    [[ -z "$(xreview_pid)" ]] || die "the cross-reviewer is running; pass --force to stop it"
  fi
  local xpid
  xpid=$(xreview_pid)
  if [[ -n "$xpid" ]]; then kill -TERM -- "-$xpid" 2>/dev/null && echo "stopped cross-reviewer (pid $xpid)"; fi
  for role in "${AGENT_ROLES[@]}" status; do
    pane=$(field ".panes.$role // empty")
    if [[ -n "$pane" ]] && pane_exists "$pane"; then "$HERDR" pane close "$pane" >/dev/null && echo "closed $role ($pane)"; fi
  done
  pane=$(field .panes.shell)
  if ((keep_shell)) || ! pane_exists "$pane"; then
    :
  elif [[ "${HERDR_PANE_ID:-}" == "$pane" ]]; then
    warn "run from the shell pane, so it stays open; close it yourself"
  elif "$HERDR" pane process-info --pane "$pane" | jq -e '.result.process_info | .foreground_process_group_id == .shell_pid' >/dev/null; then
    "$HERDR" pane close "$pane" >/dev/null && echo "closed shell ($pane)"
  else
    warn "shell pane $pane is running a command, so it stays open"
  fi
  pane=$(field .panes.planner)
  pane_exists "$pane" && "$HERDR" pane rename "$pane" --clear >/dev/null
  ledger "Team down"
  echo "team $SLUG is down; folder kept at $DIR"
}

xreview_pid() {
  local run="$DIR/cross-reviewer/run.json" pid=""
  [[ -f "$run" ]] && pid=$(jq -r '.pid // empty' "$run")
  if [[ -n "$pid" && ! -f "$DIR/cross-reviewer/exit" ]] && kill -0 "$pid" 2>/dev/null; then echo "$pid"; fi
}

xreview_start() {
  local round=${1#r} step=${2:-} dir="$DIR/cross-reviewer"
  [[ "$round" =~ ^[0-9]+$ && ( "$step" == review || "$step" == crosscheck ) ]] ||
    die "usage: team.sh xreview start <round> review|crosscheck"
  [[ -z "$(xreview_pid)" ]] || die "the cross-reviewer is already running; use team.sh xreview wait"
  local assignment="$DIR/reviewer/r$round-assignment.md" lead_report="$DIR/reviewer/r$round-report.md" report prompt
  if [[ "$step" == review ]]; then
    [[ -f "$assignment" ]] || die "missing $assignment"
    report="$dir/r$round-report.md"
    prompt="Two-reviewer round $round, step 1: independent review. Read the lead reviewer's assignment at $assignment and review the same candidate. Write your report to $report, not to the report path in that assignment. Do not open anything else under $DIR/reviewer/ during this step."
  else
    [[ -f "$lead_report" ]] || die "write your own report $lead_report before starting the cross-check"
    [[ -f "$dir/r$round-report.md" ]] || die "run the review step for round $round first"
    report="$dir/r$round-crosscheck.md"
    prompt="Two-reviewer round $round, step 2: cross-check. Read the lead reviewer's independent report at $lead_report. Mark each of its findings CONFIRMED or DISPUTED with evidence, add anything it made you see, and keep or withdraw your own step 1 findings only as the reviewer role allows. Write $report."
  fi
  [[ ! -e "$report" ]] || mv "$report" "$report.superseded-$(date +%Y%m%dT%H%M%S)"

  local spec model thinking sid system="$dir/system.md" log="$dir/r$round-$step.log" pi_bin file pack packs=()
  spec=$(field '.models["cross-reviewer"] // empty')
  spec=${spec:-$(default_model cross-reviewer)}
  model=${spec%:*}
  thinking=${spec##*:}
  pi_bin=$(command -v pi) || die "pi is not on PATH"
  sid=$(field '.sessions["cross-reviewer-id"] // empty')
  if [[ -z "$sid" ]]; then
    sid=$(uuidgen | tr '[:upper:]' '[:lower:]')
    update_team --arg s "$sid" '.sessions["cross-reviewer-id"] = $s'
  fi
  while IFS= read -r pack; do packs+=("$pack"); done < <(field '.packs[]')
  {
    cat "$SKILL_DIR/references/roles/common.md"
    printf '\n'
    cat "$SKILL_DIR/references/roles/reviewer.md"
    printf '\n'
    cat "$SKILL_DIR/references/roles/cross-reviewer.md"
    printf '\n'
    sed '/^After writing the report/,$d' "$DIR/context.md"
    while IFS= read -r file; do
      printf '\n---\nPreference file: %s\n\n' "$file"
      cat "$file"
    done < <(pack_files cross-reviewer "${packs[@]}")
  } >"$system"

  rm -f "$dir/exit" "$dir/exit.logged"
  {
    echo '#!/usr/bin/env bash'
    printf 'cd %q || exit 97\n' "$(field .worktree)"
    printf '/usr/bin/env -u HERDR_ENV -u HERDR_SOCKET_PATH -u HERDR_PANE_ID -u HERDR_TAB_ID -u HERDR_WORKSPACE_ID PI_MEMORY_DIR=%q \\\n' "$DIR/memory"
    printf '  %q -p --model %q --thinking %q --exclude-tools %q --append-system-prompt %q --session-id %q %q >%q 2>&1\n' \
      "$pi_bin" "$model" "$thinking" "$EXCLUDED_TOOLS,edit" "$system" "$sid" "$prompt" "$log"
    printf 'echo $? >%q\n' "$dir/exit"
  } >"$dir/run.sh"
  perl -MPOSIX -e 'POSIX::setsid(); exec @ARGV' bash "$dir/run.sh" </dev/null >/dev/null 2>&1 &
  local pid=$!
  jq -n --argjson round "$round" --arg step "$step" --argjson pid "$pid" --arg report "$report" --arg log "$log" \
    --arg model "$spec" --arg started "$(date -u +%FT%TZ)" \
    '{round: $round, step: $step, pid: $pid, report: $report, log: $log, model: $model, started_at: $started}' >"$dir/run.json"
  ledger "Cross-reviewer started: r$round $step ($spec)"
  echo "cross-reviewer running r$round $step ($spec), pid $pid"
  echo "  report $report"
  echo "  next: team.sh xreview wait (give the bash call a timeout above 1800 seconds)"
}

xreview_wait() {
  local timeout=$1 dir="$DIR/cross-reviewer" waited=0 run pid
  [[ -f "$dir/run.json" ]] || die "the cross-reviewer has not been started"
  run=$(cat "$dir/run.json")
  pid=$(jq -r .pid <<<"$run")
  while [[ ! -f "$dir/exit" ]]; do
    if ! kill -0 "$pid" 2>/dev/null; then
      sleep 1
      [[ -f "$dir/exit" ]] && break
      die "the cross-reviewer stopped without a status; see $(jq -r .log <<<"$run")"
    fi
    if ((waited >= timeout)); then
      echo "the cross-reviewer is still running after ${timeout}s; call team.sh xreview wait again"
      return 2
    fi
    sleep 5
    waited=$((waited + 5))
  done
  local code report label
  code=$(cat "$dir/exit")
  report=$(jq -r .report <<<"$run")
  label="r$(jq -r .round <<<"$run") $(jq -r .step <<<"$run")"
  if [[ ! -f "$dir/exit.logged" ]]; then
    ledger "Cross-reviewer finished: $label, exit $code"
    : >"$dir/exit.logged"
  fi
  if [[ "$code" == 0 && -s "$report" ]]; then
    echo "cross-reviewer finished $label: $report"
  else
    echo "cross-reviewer failed $label (exit $code, report $([[ -s "$report" ]] && echo present || echo missing)); log $(jq -r .log <<<"$run")"
    return 1
  fi
}

xreview_status() {
  local dir="$DIR/cross-reviewer" run
  [[ -f "$dir/run.json" ]] || { echo "cross-reviewer: not started"; return 0; }
  run=$(cat "$dir/run.json")
  if [[ -n "$(xreview_pid)" ]]; then
    echo "cross-reviewer: running r$(jq -r .round <<<"$run") $(jq -r .step <<<"$run") since $(jq -r .started_at <<<"$run")"
  elif [[ -f "$dir/exit" ]]; then
    echo "cross-reviewer: finished r$(jq -r .round <<<"$run") $(jq -r .step <<<"$run"), exit $(cat "$dir/exit")"
  else
    echo "cross-reviewer: stopped without a status"
  fi
  echo "  report $(jq -r .report <<<"$run")"
  echo "  log $(jq -r .log <<<"$run")"
}

cmd_xreview() {
  local team=${TEAM_SLUG:-} timeout=1800 args=()
  while (($#)); do
    case "$1" in
      --team) team=$2; shift 2 ;;
      --timeout) timeout=$2; shift 2 ;;
      *) args+=("$1"); shift ;;
    esac
  done
  [[ "$timeout" =~ ^[0-9]+$ ]] || die "--timeout expects seconds"
  load_team "$team"
  mkdir -p "$DIR/cross-reviewer"
  case "${args[0]:-}" in
    start) xreview_start "${args[1]:-}" "${args[2]:-}" ;;
    wait) xreview_wait "$timeout" ;;
    status) xreview_status ;;
    *) die "usage: team.sh xreview start <round> review|crosscheck | wait [--timeout SECONDS] | status" ;;
  esac
}

command=${1:-help}
(($#)) && shift
case "$command" in
  up | start | send | freeze | delta | verify | pr | notify | status | board | down | xreview) "cmd_$command" "$@" ;;
  help | -h | --help) usage ;;
  *) die "unknown command: $command (see team.sh help)" ;;
esac
