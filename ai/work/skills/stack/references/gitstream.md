# Reference: Gitstream (`gs`)

> Load this only when [SKILL.md](../SKILL.md) has established that the stack lives on
> **Gitstream**, or that new work should start there.

Gitstream holds the PR data; **Meteorite** (`meteorite.shopify.io`) presents it; `gs` is the CLI
for both the branches and the PRs. One tool covers what used to take `gt` plus `gh`.

`gs` is in-house and recent, so do not extrapolate from `gh`/`gt` habits — the traps below are
the ones that actually bite. Any verb `gs` does not own passes straight through to `git`, so
`gs status`, `gs diff`, and `gs checkout <branch>` behave exactly like their `git` equivalents.

---

## Golden rules for this surface

1. **A Gitstream PR is not a GitHub PR.** They are separate objects in separate stores. The
   number ranges do not overlap, though, so a PR number is globally unambiguous — which is why
   surface-agnostic tooling like `devx ci` happily takes either. Surface-specific tooling does
   not: `gs pr <n>` and `gh pr <n>` are asking different systems about different things.

2. **Never use `gh` for pull requests here — reads included.** Not `gh pr view`, not
   `gh pr checks`, not `gh pr list`, not for review state. A Meteorite PR has no GitHub
   counterpart, so a `gh` read is not a fallback; it returns nothing, or someone else's PR.
   Everything PR-shaped goes through `gs pr …`. (`gh issue view` is still fine — issues are not
   PRs.)

3. **Never use the Meteorite, GitHub, or Graphite web write buttons.** No web editor, commit
   suggestions, rebase/squash/update-branch, or merge button.

---

## Core workflow

### Build a stack

```bash
# 1. Do your work

# 2. Create the branch — the argument is a NAME, not a commit message
gs create <handle>/<short-kebab-description>

# 3. Stage and commit in one step
gs modify -a -m "<commit message>"

# 4. Submit
gs submit --stack

# 5. Publish the new PRs you want reviewed
gs pr ready <number>
```

Repeat steps 2–4 for each PR in the stack. **Submit incrementally** as each PR is completed —
don't wait until all the code is written.

Branch names are yours to choose; match the repo's convention (in World, usually
`<handle>/<short-kebab-description>`).

### Change a PR

`gs modify` is the single verb for putting work into a branch. It amends the branch's own
commit and restacks descendants automatically.

```bash
gs modify            # amend, keeping the existing message
gs modify -a         # stage every working-tree change first (incl. untracked), then amend
gs modify -m "<msg>" # amend and replace the message
```

On a freshly created branch that has no commit of its own yet, `gs modify -m` creates the first
commit rather than amending. So the same verb covers "start this branch" and "update this
branch" — you never need `git commit` plus a manual restack.

To change a PR further down the stack, go to the branch that owns the lines:

```bash
gs checkout <branch>
gs modify -a
gs top
gs submit --stack
```

The descendant restack happens as part of `gs modify`, so the upstack follows automatically.
There is no `absorb` equivalent — edit the lines where they actually live.

### Refresh a stack

```bash
gs sync --rebase
```

`gs sync` is the refresh command: it fetches trunk and fast-forwards it, plans cleanup of
merged/closed branches (including unrelated dead ones), and restacks onto the new trunk. Pass
`--rebase` explicitly (or `--reset`) — off a TTY it will not prompt to reconcile a diverged
branch, it just warns and skips. It refuses on a dirty tree, and counts untracked files as dirty.

`gs get --rebase` is the narrower tool and **not** Graphite's `gt get`. It pulls only the
server-projected stack for the current branch — materialising branches missing locally,
fast-forwarding ones that are behind, leaving ahead ones alone — and never touches trunk, so the
stack stays based on your stale trunk. Reach for it to fetch someone else's PR
(`gs get <pr-number-or-url>`), or when you deliberately want the stack refreshed without trunk
moving underneath it. Bare `gs get` on a trunk is refused.

Either way, some branches may have merged into trunk and will drop out of the stack. That's
normal. Tracked branches whose local refs are gone can be cleared with `gs untrack --missing`
(add `--reparent` to keep their children).

After a refresh, base-PR changes may need `dev up` — always prefer `dev up` over
`bin/rails db:migrate`, because it converges the whole environment (dependencies, datastores,
migrations across all databases) rather than one default database.

### Update the local `main` branch

`gs sync` skips a trunk ref another worktree owns (World keeps `main` in `~/world/trees/root/src`);
no flag overrides it. Stacks are unaffected — the restack uses fetched `origin/main` — but
`merge-base main HEAD` tooling (`bin/style --include-branch-commits`, `dev check`) then widens to
the whole trunk gap. Fast-forward it where it lives:

```bash
git -C ~/world/trees/root/src pull --ff-only origin main
```

Name `origin main`; bare `git pull` drags every branch (~1 min regardless). Don't run bare `gs sync`
there for trunk alone — it restacks too, rewriting any stack in flight.

### Submit and draft state

```bash
gs submit --stack        # new PRs land as draft; existing PRs are untouched
gs pr ready <n>          # publish
gs pr ready --undo <n>   # back to draft
```

`--publish` creates new PRs ready-for-review, and applies **only** to PRs created in that same
invocation — it never republishes an existing draft. Prefer the two-step form anyway: a draft PR
does not auto-trigger CI, which gives you a beat to check the PR before it burns CI capacity.

`gs submit` derives a new PR's title from the commit subject and its body from the commit body,
so a good commit message is a good first draft of the PR.

**`gs submit` refuses on a stale stack.** If any branch shows `(needs restack)` in `gs log -s`,
run `gs restack` first. Off a TTY it will not prompt — it just refuses.

### Read PRs

```bash
gs pr view <n>              # metadata, reviewers, one-hop stack, body, reviews
gs pr view <n> --comments   # + issue comments and inline review threads
gs pr view <n> --json       # machine-readable
gs pr checks <n>            # CI checks (exit 8 = still pending)
gs pr list                  # your open PRs
gs pr diff <n>
```

If you cannot establish something from `gs` — review state, for instance — **ask the user**.
Do not reach for `gh`; it is looking at a different object.

### Edit PRs

```bash
gs pr edit <n> --title "<title>" --body-file <path>
gs pr edit <n> --add-label <label> --add-assignee <shopify-email>
gs pr comment <n> --body "<text>"
gs pr review <n> --approve
gs pr resolve <n> <thread-id>        # thread ids come from `gs pr view <n> --comments`
```

Reviewer, `--base`, and milestone edits are not wired yet and exit `6`. `gs submit` handles base
retargeting for you.

### Navigate and inspect

```bash
gs pr stack            # server view: the live stack of PRs
gs log -s              # local view: branches, parents, staleness, PR numbers
gs stack parent        # current branch's parent
gs stack children      # current branch's children
gs checkout <branch>   # git passthrough
gs up / gs down        # one branch up/down
gs top / gs bottom     # stack endpoints
```

`gs log -s` annotates branches with `(pr #N)`, `(needs restack)`, `(frozen)`, and
`(missing locally)`. `gs up` refuses at a leaf and prompts at a fork; a dirty tree blocks
navigation before any checkout.

---

## If you know Graphite

Most verbs map across, but four differences cause real breakage:

| Graphite | Gitstream | Why it matters |
|----------|-----------|----------------|
| `gt create -m "<msg>"` | `gs create <branch-name>` then `gs modify -a -m "<msg>"` | `gs create` takes a **name** and makes no commit. There is no `-m` on it. |
| `gt absorb` | *(nothing)* | Check out the owning branch and `gs modify`; descendants restack automatically. |
| `gt get` | `gs sync --rebase` | Same word, different tool: `gs get` refreshes only the server-projected stack and never fetches trunk. `gs sync` is the one that maps to `gt get`. |
| `gt submit --publish` republishes existing drafts | `gs submit --publish` only affects newly created PRs | The Graphite footgun is not present here. |

`gs restack`, `gs undo`, `gs continue`, `gs abort`, `gs track`, `gs untrack`, `gs move --onto`,
`gs delete`, and the navigation verbs behave as their `gt` equivalents do.

---

## Recovery

| Symptom | Cause | Fix |
|---------|-------|-----|
| `(needs restack)` / submit refuses | Parent moved | `gs restack` |
| `not tracked` | Branch missing from local `.gs` state | `gs track --parent <parent>`, or `gs track --stack` from the tip to adopt a whole local chain |
| Conflict during restack/get/sync/modify | Upstack conflicts | Resolve files, `git add`, then `gs continue` (or `gs abort`) |
| Wrong branch created | — | `gs undo` |
| Wrong parent | Bad topology | `gs move --onto <correct-parent>` |
| Tracked branches whose refs are gone | Merged stack cleaned up | `gs untrack --missing` |
| `gs modify` refuses | Clean tree, nothing to amend | Stage something, or use `-a` |

---

## CI

CI is triggered explicitly and is unaffected by the move to Gitstream. **No mirror check is
needed** — submit, then run CI.

```bash
devx ci run -b <branch>          # selective, impact-based — use for iterative signal
devx ci run --full -b <branch>   # full pre-merge suite — run once, as final validation
devx ci status --pr <n>          # or -b <branch>; PR numbers are unambiguous across surfaces
gs pr checks <n>                 # per-PR check state (exit 8 = pending)
```

- Hold `--full` until the PR is stable: threads resolved, rebased on `main`, approved. Every
  push re-triggers the AI reviewer independently of CI, so full runs fired early are wasted.
- Never add `[skip ci]` / `[ci skip]` to a commit message.
- **Merging is user-gated.** Get the PR to ready-to-merge and stop. Do not merge by any method
  unless the user explicitly asks for *that* PR.

---

## Commit messages

1. **First line:** short summary of what the commit does
2. **Blank line**
3. **Body:** why the change was made, what it affects

```
Add validation for user email addresses

The signup form was accepting malformed emails which caused
downstream issues in the notification service. This adds
client-side validation matching the server-side rules.
```

---

## Planning work

Before writing code, determine:

1. **Feature flag?** Most work should be behind a flag. If yes, confirm the flag name with the
   user (see below).

2. **Stack structure?** One PR or several? If several, propose the structure in your plan:
   ```
   PR 1: Add API endpoint (behind f_feature_name)
   PR 2: Add UI components (behind f_feature_name)
   PR 3: Remove feature flag (blocked until 100%)
   ```

   Useful ways to split a stack: by layer (migration → API → UI), by component, by dependency
   order, by risk (riskiest at the bottom, so it is cheap to revert), or by review speed (quick
   reviews at the bottom so they merge and unblock the rest). Keep each PR small enough to
   review in one sitting, and independently understandable — if a reviewer needs an upstack PR
   to make sense of this one, the split is wrong.

3. **Review strategy?** Different PRs may need different reviewers. Note this in the plan if
   relevant.

### Gathering context from existing PRs

When working with existing PRs (fixing issues, reorganising, follow-ups), load the PR
description before making changes:

```bash
gs pr view <n>
```

If the description references an issue ("Closes #123"), follow the link and load it too —
issues are often in a different repo:

```bash
gh issue view <number> --repo <owner/repo> --json body,title,url
```

PR descriptions and linked issues carry intent, requirements, and constraints that aren't
visible in the code. Don't skip this.

---

## Feature flag pattern

Most work should be protected by feature flags. This typically means **2+ PRs**:

1. **Feature PRs:** Introduce functionality behind the flag
2. **Cleanup PR (top of stack):** Remove flag references, blocked until 100% rollout

**Flag types:** shop-based (membership driven by shop), app-based (driven by app), or
subject-less (global on/off).

**Flag naming.** If no flag is specified, suggest one in the plan as
`f_<snake_case_feature_name>` — e.g. `f_user_auth_flow`, `f_checkout_v2`. The user confirms the
name before work begins.

```
main
 └── [#auth] Add auth API (behind f_user_auth)
      └── [#auth] Add login UI (behind f_user_auth)
           └── [#auth] Remove f_user_auth flag
                ↑ Blocked: "Do not merge until f_user_auth is at 100%"
```

---

## PR quality

**Consult the `pr-authoring` skill (or similar) for comprehensive guidance on writing PR titles
and descriptions.**

**Blockers first.** Always highlight warnings/blockers at the very top:

```markdown
> [!WARNING]
> - [ ] PR was generated by AI—<@github username> has reviewed it
> - Do not merge until `f_user_auth` flag is at 100%
> - Do not merge until PR below is deployed
```

**Diagrams:**

| Type | Tool | Good for |
|------|------|----------|
| Simple | Inline Mermaid | Flow charts, decision trees, simple sequence diagrams |
| Complex | `/diagram` skill | Architecture, better aesthetics, formatting control |

Delegate diagram generation to a subagent—don't bloat the main conversation with rendering.

---

## Quick command reference

| Task | Command |
|------|---------|
| Is this a Gitstream stack? | `gs pr stack` |
| Local stack view | `gs log -s` |
| Track an existing branch | `gs track --parent main` (`--stack` for a whole chain) |
| Create stacked branch | `gs create <branch-name>` |
| Commit / amend | `gs modify -a [-m "<msg>"]` |
| Rebase descendants | `gs restack` |
| Refresh a stack (default) | `gs sync --rebase` |
| Pull server-projected stack only (no trunk fetch) | `gs get --rebase` |
| Update local `main` (World: owned by the root worktree) | `git -C ~/world/trees/root/src pull --ff-only origin main` |
| Fetch someone else's PR | `gs get <pr-number-or-url>` |
| Submit stack | `gs submit --stack` |
| Publish a PR | `gs pr ready <n>` |
| Edit a PR | `gs pr edit <n> --title … --body-file …` |
| Read a PR | `gs pr view <n> [--comments] [--json]` |
| CI checks | `gs pr checks <n>` |
| Navigate | `gs checkout`, `gs up`, `gs down`, `gs top`, `gs bottom` |
| Undo / recover | `gs undo`, `gs continue`, `gs abort` |
