---
name: herdr-feature-delivery
description: Deliver a personal feature with Gaurav's visible Herdr planner, implementer, reviewer, tophatter, reserved shell, and local status board. Use for /feature-team or requests to spin up this visible team. Includes explicit human-approved lessons and preference packs.
compatibility: Requires Herdr with HERDR_ENV=1, its Pi integration, Pi with openai-codex/gpt-6.1-sol, jq, Python 3, Git, and the project's development tools.
---

# Personal Herdr feature delivery

Use only `scripts/team.sh` to build, launch, coordinate, freeze, and tear down this team. Read the `herdr` skill before controlling Herdr. Never replace these visible roles with headless subagents. There is no cross-reviewer, remote watcher, or browser automation integration.

## Layout and models

```text
planner     | implementer | Gaurav's shell
reviewer    | tophatter   | local status
```

| Role | Model | Thinking | Authority |
|---|---|---|---|
| planner | openai-codex/gpt-6.1-sol | xhigh | This session; plan, reconcile, talk to Gaurav, perform individually approved VCS/external writes |
| implementer | openai-codex/gpt-6.1-sol | high | Change code and tests, validate; never commit |
| reviewer | openai-codex/gpt-6.1-sol | xhigh | Independently review frozen candidates; write reports, never edit product code |
| tophatter | openai-codex/gpt-6.1-sol | high | Own local environment verification, evidence, and cleanup; never edit product code |

Launch the planner with `pi --model openai-codex/gpt-6.1-sol --thinking xhigh`. The prompt cannot change the current session's model or thinking; if those aren't selected, ask Gaurav to select them before launch. Role defaults live in the runner; change a role only when Gaurav asks, with `--model role=provider/id:thinking`, and record why. Do not silently substitute models. Confirm availability with `pi --list-models`.

## Hard gates

- Never commit, push, create/edit a PR or issue, trigger CI, deploy, or perform any external write until Gaurav approves that exact step. Never merge unless explicitly asked for that PR.
- Ask before deviating from the approved plan or making unresolved product/contract/design choices. Recommend the correct design, not the least churn.
- Members never modify remote state or Git configuration. Reviewer and tophatter never modify product code. Treat these as instructions, not a filesystem sandbox: bash remains available.
- Preserve unrelated worktree changes and protected artifacts. Never bypass interactive authentication, overwrite, deployment, or destructive confirmations.
- The shell belongs to Gaurav: no agent types into, reads, or closes it. Tear down with `--keep-shell`.
- Do not inspect other workspaces or create a different topology without Gaurav's request.
- Never automatically persist a lesson. Approval of a fix is not approval of a standing preference.

## Planner coordination

- Send with `team.sh send`, then end the turn. React to DONE/BLOCKED pings; never wait on agents or poll their progress. Stay available to Gaurav.
- Read the report header first, then relevant sections. Verify evidence without duplicating the member's work.
- Advance phases without asking permission for routine next steps. Stop for gates, real decisions, or unresolved blockers.
- Log reports, verdicts, gates, and decisions as one line in `ledger.md`. The runner logs its actions itself.
- For anything needing Gaurav, run `team.sh notify "<what you need>" --team <slug>`. Clear it with `notify --clear` when he responds.
- Keep all roles alive through feedback until Gaurav dismisses the team.

## Context and persistence

Team artifacts live in `~/.pi/feature-teams/personal/<slug>/`: plan, context, ledger, role assignments/reports, saved session paths, candidates, evidence, and lesson proposals. This is the memory needed for team continuity; no memory extension or work knowledge bank is used.

Read `preferences/base.md` and `preferences/learned.md` before planning. The base pack loads both into member standing context. At launch/resume the runner also appends project lessons from `<repo>/.pi/preferences/feature-team.md` and team lessons from `<team>/preferences.md`. Read these yourself when present. Resolve other relative pack paths against this skill directory.

Agents do not see the planner's conversation. Put agreed decisions, constraints, and rejected alternatives in `plan.md`; point each assignment to it. Use [references/assignments.md](references/assignments.md). Standing role rules live in [common](references/roles/common.md), [implementer](references/roles/implementer.md), [reviewer](references/roles/reviewer.md), and [tophatter](references/roles/tophatter.md). Don't contradict those files in assignments.

## Phases

### 1. Intake

Use an already approved plan if one exists; don't reopen settled decisions. Otherwise agree on the goal, acceptance criteria, scope, contract/design decisions, repository/branch, protected files, and validation. Load relevant repository skills. Ask only what source files cannot answer.

### 2. Team up

The planner must be the only pane in its tab. The worktree must be clean except for this feature's approved changes. `up` does not create a Git worktree.

```bash
T="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}/skills/herdr-feature-delivery/scripts/team.sh"
$T up <slug> --worktree <existing-directory> --title "<feature>"
# Write plan.md before starting any member.
$T start implementer --team <slug>
$T start tophatter --team <slug>
```

Use `--allow-dirty` only for changes belonging to this feature. Post the plan's path and a short summary, then continue; Gaurav can correct the transcription. His shell gets `$TEAM_SH` and `$TEAM_SLUG`; `status`, `delta`, and `lesson list/show/approve` are available there.

### 3. Implement

Send the approach/implementation assignment and top-hat prep together. Check the implementer's approach against the plan, packs, and nearest precedent before giving the go-ahead. On completion, check validation evidence, then `freeze 1`. The implementer stops editing after DONE until reassigned.

### 4. Review/fix loop

Start the reviewer on the first frozen candidate. Send the review assignment and exact SHA-256. Validate each finding against code and contract, reject unsupported findings with a reason, and send accepted fixes. Freeze each new candidate and ask for delta review until `Verdict: SATISFIED`. One independent reviewer only; no cross-review phase.

### 5. Human review

Present stats, key hunks/design decisions, validation, reviewer verdict, resolved findings, top-hat readiness, and a proposed commit message. While Gaurav reviews, forward his feedback to the implementer and freeze fixes; pause reviewer/tophatter. After he finishes, propose necessary delta review and verification. He decides.

### 6. Local commit and top-hat

On explicit commit approval, the planner creates the approved local commit(s), pushes nothing, and runs `verify <round>`. It must report IDENTICAL. Send a top-hat assignment for that exact HEAD. This is the full manual verification; prep wasn't a completed top-hat. Code gaps go back through implementation/review. Temporary local environment changes must be approved and restored.

### 7. Final validation and optional publication

Coordinate required tests/checks against the exact commit. Present top-hat evidence and untested boundaries. If Gaurav wants publication, propose the commands and PR body; execute only after approval. No remote status polling or comment watcher. Verify any published head with `verify --ref <ref>`; changed behavior needs delta review/verification.

### 8. Teardown/recovery

After explicit dismissal:

```bash
$T down --keep-shell --team <slug>
```

Teardown refuses while members are working or blocked. Never force without permission. Team artifacts survive. After a restart, `up` reuses the folder/base/packs/models, but refuses if previous panes still exist: inspect/reuse those instead of creating duplicates. Once old panes are gone, `up` then `start <role> --resume` restores recorded sessions. Keep using the same saved profile.

## Human-approved lessons (available now)

After user feedback exposes a reusable rule, or a member reports a potential lesson:

1. Check existing preferences for duplicates/conflicts. Distinguish a general rule from a one-off fix. Ask when unclear.
2. Propose **one concise rule**, with rationale, concrete evidence, and the narrowest scope:
   - `team`: this feature only, stored with its artifacts;
   - `project`: this repository, in `.pi/preferences/feature-team.md`;
   - `personal`: all personal feature teams, in tracked `preferences/learned.md`.
3. Write the exact proposed wording to a scratch file in the team folder and register it:

```bash
$T lesson propose <id> --team <slug> --scope personal \
  --rule-file <absolute-rule-file> --reason "<why reusable>" \
  --evidence "<report/file/feedback reference>"
```

4. Present the exact wording, scope, target file, and reason to Gaurav. Notify him. Tell him to run **in his reserved shell**:

```bash
$TEAM_SH lesson show <id>
$TEAM_SH lesson approve <id>
```

The approval command prints the exact rule and asks him to type a proposal-specific confirmation through his controlling terminal. Never run approve for him, answer its prompt, manufacture confirmation, or type into his shell. There is deliberately no `--yes` flag. Proposal/target changes invalidate approval; revised wording or stale targets require a new proposal id. `lesson reject <id>` records a rejection without preference changes. Feedback or ordinary conversational approval alone does not apply the rule.

5. When Gaurav tells you he approved, read the proposal status and preference file to confirm. Read the rule yourself and send its file path to every live member for the next assignment; appended prompts do not hot-update automatically. New/resumed members load the approved preferences in standing context.
6. Record the lesson's application in the ledger. Personal/project file changes stay **uncommitted** until separately approved. If a project lesson changes the feature diff after freezing, create a new candidate; don't pretend the old candidate still matches.

No credentials, private work context, one-time task state, or automatic session summaries belong in preference packs. This terminal gate is a deliberate approval workflow, not a security boundary against an agent with arbitrary shell access.

## Completion

Report implementation summary, reviewer verdict, exact commit/candidate, checks, top-hat evidence/untested boundaries, cleanup proof, lessons proposed/approved, and anything awaiting Gaurav.
