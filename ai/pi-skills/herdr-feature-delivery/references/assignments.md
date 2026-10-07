# Assignment templates

Write each assignment in the team folder, fill every bracket, and send it with `team.sh send <role> "Read <path> and follow it." --team <slug>`. Standing rules already live in each agent's system prompt; do not repeat them, and never contradict the preference packs.

## Agreed plan

Path: `plan.md`. Write it once after `team.sh up`, and update it only when Gaurav changes the plan.

```markdown
# Plan: [feature]

Agreed with Gaurav: [date; conversation, issue, or doc it came from]
Links: [issue, design doc, related PRs, stack position]

## Goal and acceptance criteria
[Observable outcomes that define done]

## Decisions
[Each decision with its rationale. Quote Gaurav where he set a constraint.]

## Approach
[Intended shape, nearest precedent if known, sequencing]

## Scope
In: [...]
Out: [...]
Protected: [...]

## Rejected alternatives
[Each option considered and why it lost]

## Open questions
[Must be empty before implementation starts, or name who resolves each one]
```

## Round 1: approach and implementation

Path: `implementer/r1-assignment.md`

```markdown
# Round 1: [feature]

Source of truth: plan.md[, plus anything it links that the implementer must read]
Read first: [domain knowledge files, by absolute path]
Skills to load: [repository and zone skills]

## Goal
[Observable outcome and acceptance criteria]

## Scope
In: [files, zones, behaviors]
Out: [explicit exclusions]
Protected: [paths or state to preserve byte-for-byte]

## Validation
[Focused tests, full-suite baseline, checks, generated artifacts, mutation probes]

## Deliverables
1. Approach note at implementer/r1-approach.md. Ping DONE and wait for the go-ahead.
2. Implementation report at implementer/r1-report.md.
```

## Fix round

Path: `implementer/rN-assignment.md`

```markdown
# Round N fixes: [feature]

Current candidate: r[N-1] ([sha256])
Apply exactly: [finding IDs with the accepted fix, or Gaurav's feedback verbatim]
Do not change: [everything else, or named areas]
Validation: [what to rerun]
Report: implementer/rN-report.md
```

## Review

Path: `reviewer/rN-assignment.md`. Round 1 and any round that changes behavior or contracts are two-reviewer rounds; small fix rounds are single. On a two-reviewer round the reviewer runs the cross-reviewer itself and pings once, with `reviewer/rN-verdict.md`.

```markdown
# Review round N: [feature]

Mode: [two-reviewer | single]
Requirements: plan.md[, plus domain files]
Candidate: candidates/rN/patch, SHA-256 [sha]
Previous candidate: [r(N-1), or none]. From round 2, review the delta; `team.sh delta r(N-1) rN --team [slug]` prints it.
Implementer evidence: implementer/r1-approach.md and implementer/rN-report.md
Focus: [risk areas, open questions, contracts to probe]
Report: [reviewer/rN-verdict.md for two-reviewer rounds | reviewer/rN-report.md for single rounds]
```

## Top-hat prep, at kickoff

Path: `tophatter/prep-assignment.md`

```markdown
# Top-hat prep: [feature]

Claims to prove: [exact user-visible or public-API behavior, from plan.md's acceptance criteria]
Production path: [entry point through final persisted or observable state]
Skills to load: end-to-end-tophat-evidence[, domain top-hat skill]
Environment notes: [services, zones, known local issues]
Report: tophatter/prep-report.md with the scenario plan and environment status
```

## Top-hat run, after the local commit

Path: `tophatter/runN-assignment.md`

```markdown
# Top-hat run N: [feature]

Commit: [HEAD sha] on [branch]; `team.sh verify` reported it IDENTICAL to candidate r[M]
Plan: tophatter/prep-report.md[, with these changes]
Approved environment actions: [resets or restarts Gaurav approved, or none]
Evidence folder: tophatter/evidence/runN/
Report: tophatter/runN-report.md with setup, journey, raw artifact paths, untested boundaries, final state, and cleanup proof
```

## Planner reconciliation checklist

- Is every finding tied to the stated contract?
- Did the implementer change only owned files?
- Does each new test fail when its claimed behavior is removed?
- Has every required test, typecheck, lint, package, and generated-artifact check run against the exact candidate?
- Did the top-hat exercise the exact commit that will be published?
- Are local bridges and untested production hops explicit?
- Are all flags, rows, services, permissions, and artifacts restored?
- Has Gaurav reviewed the diff and approved each publication step?
