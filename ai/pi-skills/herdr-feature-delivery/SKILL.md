---
name: herdr-feature-delivery
description: Delivers a feature or issue end to end with Gaurav's visible Herdr team (planner, implementer, reviewer, cross-reviewer, tophatter, and a shell pane reserved for Gaurav), built and launched by scripts/team.sh. Use for /feature-team, "spin up the team", or any request to implement, review, and top-hat an issue with visible agent panes and human approval gates.
compatibility: Requires Pi running inside Herdr (HERDR_ENV=1), jq, and the repository's development tools.
---

# Herdr feature delivery

This skill is the source of truth for the team's layout, models, context, and gates. Build and launch the team only through `scripts/team.sh`. Do not hand-roll Herdr layout or launch commands, and do not improvise models.

## Team

```text
┌─────────────┬─────────────┬─────────────┐
│ planner     │ implementer │    shell    │
├─────────────┼─────────────┤             │
│ reviewer    │ tophatter   ├─────────────┤
│             │             │   status    │
└─────────────┴─────────────┴─────────────┘
```

| Pane | Model | Authority |
|---|---|---|
| planner | This Pi session | Plans, reconciles, talks to Gaurav, writes memory, and performs approved VCS and external writes |
| implementer | `anthropic/claude-opus-5-5` · xhigh | Changes code and tests and validates them; never commits |
| reviewer | `anthropic/claude-fable-5-1` · max | Reviews frozen candidates; on two-reviewer rounds also runs the cross-reviewer and writes the merged verdict; never edits |
| cross-reviewer | `openai-1m/gpt-6-astra` · xhigh · 1M | No pane: runs headless inside the reviewer's pane through `team.sh xreview`. Second, independent review from a different model family; never edits |
| tophatter | `openai/gpt-6.1-sol` · xhigh · 1M | Owns the local environment, real entry points, evidence, and cleanup |
| shell | None | Gaurav's terminal. No agent ever types into, reads, or closes it |
| status | Script | Live board of agents, candidates, and the ledger. Once the branch is pushed it watches Delta and Gitstream sync; after publication, also the Gitstream or Delta PR's CI, Binks, comments, reviews, and head. Pings the planner on changes |

The model table lives in `team.sh`. Override a role only when Gaurav asks (`--model reviewer=provider/id:thinking` on `up`) and log why in the ledger. If a model is unavailable, check `pi --list-models` and ask before substituting. If GPT-6.1 Sol is too slow or rate-limited for a top-hat, propose the previous tophatter, `--model tophatter=openai-1m/gpt-5.6-sol:xhigh`. Pi lists GPT-6.1 Sol at 272K; the tophatter's 1M window comes from a `modelOverrides` entry in `~/.pi/agent/models.json`, so check `pi --list-models` shows it at 1M before relying on it.

## Hard gates

- Never commit, push, create or edit a PR or issue, trigger CI, deploy, or perform another external write until Gaurav approves that step.
- Never merge unless Gaurav explicitly asks to merge that exact PR.
- Any deviation from a Gaurav-approved plan (mechanism, names, scope) needs his approval before execution.
- Surface real product, contract, and design choices to Gaurav with a recommendation. When one option is the correct design, recommend it; churn is never an argument against correctness.
- Agents never modify remote state, and the reviewers never edit files.
- Preserve unrelated worktree changes and protected artifacts byte-for-byte.
- Never bypass interactive deployment, overwrite, authentication, or destructive confirmations.
- Keep delegated work in the visible panes. Never replace these roles with headless subagents unless Gaurav asks. The cross-reviewer is the one headless agent, at Gaurav's request: it runs inside the reviewer's pane.

## How the planner operates

- **Never wait on agents.** Send work with `team.sh send`, end the turn, and react when a `DONE` or `BLOCKED` ping arrives. Do not call `herdr agent wait`, do not poll, and stay available to Gaurav between pings.
- **Read the report header first** (`Status`, `Result`, `Candidate`, `Needs from planner`), then only the sections you need.
- **Keep moving.** Advance through phases without asking whether to start the next one. Stop only for a gate, a real decision, or a blocker agents cannot resolve.
- **Verify, don't duplicate.** Check delegated work against code and evidence; don't redo it.
- **Keep the ledger.** Log every report, verdict, gate, and decision as one line in `ledger.md`; `team.sh` logs its own actions.
- **Own memory.** Only the planner writes memory. Record milestones in dailyContext and point to the ledger instead of mirroring every transition.
- **Tell Gaurav when you need him.** At every gate, real decision, browser step, and blocker, run `team.sh notify "<what you need>"`. It pops a Herdr notification and marks the status board. Run `team.sh notify --clear` when he responds.
- **React to `STATUS` pings.** The status pane pings on CI failures and greens, new Binks findings, new human comments, head moves you didn't make, and PR state changes. Triage each one (failing checks and their logs, the intent of each comment), then bring Gaurav a proposal. Retries, replies, and pushes still need his approval.
- **Handle `BRANCH` pings with the `delta` skill.** They mean Gitstream has commits Delta lacks (the next Delta push can overwrite them), or Delta-to-Gitstream forwarding has been stuck for 10 minutes. Inspect both tips as that skill describes before any push.

## Context

- **Standing context** goes in each agent's system prompt. `team.sh start` combines `references/roles/common.md`, the role file, the generated `context.md` (planner pane, ping commands, worktree, base), and the role's preference packs into `<role>/system.md`. It survives compaction, and the file shows exactly what the agent was given.
- **The agreed plan** lives in the team folder's `plan.md`. Agents can't see the planner's conversation, so it carries every decision, constraint, and rejected option, and every assignment points to it.
- **Per-round context** goes in assignment files: feature, scope, domain files, candidate, and report path. Use [the assignment templates](references/assignments.md). Never restate or contradict the preference packs in an assignment.
- **Memory isolation.** Agents run with `PI_MEMORY_DIR` inside the team folder, so the memory bank is neither injected into their prompts nor written by them. Give them knowledge files by path.
- **Packs.** `packs/base.txt` always applies. Add `--pack organizations` for work under `areas/platforms/organizations`. Pick domain knowledge files per feature with memory_search and list them in assignments.
- **Lessons loop.** When Gaurav's review teaches a rule that isn't captured yet, write or update the knowledge file, add it to the right pack, and include it in running agents' next assignment.

## Team folder

`~/.pi/feature-teams/<slug>/` survives reboots, unlike `/tmp`. It holds `team.json`, `context.md`, `plan.md`, `ledger.md`, `candidates/rN/` (patch, SHA-256, post-image files, and deleted paths), one folder per role for its `system.md`, assignments, and reports, `tophatter/evidence/`, `publication/` for commit messages and PR bodies, and the status pane's `remote-state.json` and `needs-gaurav`. Use `/tmp` only for scratch files.

## Phases

### 1. Intake

1. If you and Gaurav already agreed a plan earlier in this session, that plan is approved. Don't re-plan or re-ask what it settled; resolve only what it left open.
2. Otherwise, resolve the issue, acceptance criteria, design, decisions, repository, branch or stack, and VCS provider, and agree a short plan with verifiable success criteria. Ask only what the source of truth cannot answer.
3. Load every matching repository skill. Pick or claim the worktree; it must be clean except for work that belongs to this feature (pass `--allow-dirty` to `up` for that).
4. Read the packs you will apply, and select domain knowledge files.

### 2. Team up

Load the `herdr` skill. From the planner pane, which must be the only pane in its tab:

```bash
T=~/.pi/agent/skills/herdr-feature-delivery/scripts/team.sh
$T up <slug> --worktree <zone-dir> --title "<feature>" [--pack organizations]
$T start implementer --team <slug>
$T start tophatter --team <slug>
```

Between `up` and the first `start`, write `plan.md` in the team folder from [the plan template](references/assignments.md#agreed-plan). Quote Gaurav where he set a constraint or rejected an option. Post its path and a short summary to Gaurav, then continue without waiting; he can stop you if the transcription is off.

Pass `--team <slug>` to every later planner command; the shell pane presets it. Start the reviewer when the first candidate is frozen. Tell Gaurav that `git diff`, `$TEAM_SH status`, `$TEAM_SH delta r1 r2`, and `$TEAM_SH xreview status` work in his shell pane. The status pane runs `team.sh board`; if it ever stops, `$TEAM_SH board` restarts it there.

### 3. Approach and implementation

1. Send the round 1 assignment and the top-hat prep assignment together.
2. When the approach note arrives, check it against the packs, the nearest precedent, and the approved plan, then send the go-ahead or corrections. Bring Gaurav only real design choices; otherwise post a two-line FYI and continue.
3. When the implementation report arrives, check the validation evidence, then run `team.sh freeze 1`.
4. Handle top-hat prep blockers as they arrive. Environment resets and restarts need Gaurav's approval.

### 4. Review loop

1. Send the review assignment for the frozen candidate. Round 1, and any round that changes behavior or contracts, is `Mode: two-reviewer`: the reviewer runs the cross-reviewer itself (independent reviews, one cross-check each way, a merged verdict) and pings once with `reviewer/rN-verdict.md`. Small fix rounds are `Mode: single`.
2. Validate each finding against the code and the contract. Settle `Disputed` findings yourself when the code decides them, and ask Gaurav when a dispute is a real tradeoff. Reject findings that don't hold and log the reason.
3. Send accepted findings as a fix round, freeze the next candidate, and send the next review.
4. Repeat until `Verdict: SATISFIED`. Fold LOW and INFO findings into a fix round or carry them to the human gate.
5. If the reviewer reports that the cross-reviewer failed, log it and tell Gaurav. Both reviewers are premium models and share his $300/day premium cap.

### 5. Human review gate

Present the changed files and stats, key hunks and design choices, validation results, the consolidated verdict, resolved findings, and any disputes the reviewers left open, top-hat prep status, the proposed commit message and PR body, and ready-to-run commands for the shell pane (`git diff --stat`, `git diff`, `$TEAM_SH delta rA rB`).

While Gaurav reviews:

- Send his feedback to the implementer as fix rounds, and freeze each result.
- Pause the reviewer and tophatter until he says his review is complete.
- When it is complete, propose the reruns his changes need: a delta review if behavior or contracts changed, nothing for pure readability changes or deletions. Gaurav decides.

### 6. Local commit and top-hat

1. On approval, create the approved local commits. Push nothing.
2. `team.sh verify <round>` must report IDENTICAL for HEAD.
3. Send the top-hat run assignment for that exact commit. This is the only full top-hat.
4. If it exposes a product gap, return to phase 3 or 4. Environment-only fixes stay uncommitted and are restored exactly.

### 7. Final validation and publication

1. Run or coordinate every required test, typecheck, lint, package, and generated-artifact check against the exact commit.
2. Present the top-hat evidence and final PR body. On approval, push and create or update the PR with the repository's tools. In World, follow the `delta` skill for every push: `origin` may be Delta, forwarding to Gitstream is asynchronous, and PRs, CI, and Merge Garden still run on Gitstream. The PR's Testing section uses the evidence from this exact commit. Then run `team.sh pr <number-or-url> --team <slug>` so the status pane watches it. A Gitstream number or Meteorite URL watches Gitstream; a `delta.shopify.io/.../pull/<n>` URL (or `--delta`) watches a Delta PR.
3. After publishing, run `team.sh verify <round> --ref <published-head> [--base <new-base>]`. If it reports IDENTICAL, skip any fresh review or top-hat. Otherwise send a delta review, and rerun the top-hat only if behavior-bearing code changed.
4. Verify the remote head, PR body, thread state, and CI acceptance by structured readback. Stop before merge.

### 8. Standby and teardown

Keep every role alive through CI and review feedback; a consumed report doesn't end a role. Run `team.sh down --team <slug>` only after Gaurav approves the final candidate with no further iteration, dismisses the team, or the PR loop completes. It refuses while an agent is working or blocked or the cross-reviewer is running, closes only the panes it created (the status pane included), leaves a busy shell open, clears the planner label, and keeps the team folder.

To recover after a restart or a closed pane, rerun `team.sh up` with the same slug; it reuses the folder, base, packs, and sessions. Then run `team.sh start <role> --resume --team <slug>` for each role.

## Completion report

Implementation summary; reviewer verdict; top-hat path and untested boundaries; tests and checks; cleanup proof; VCS and CI state; anything awaiting Gaurav.
