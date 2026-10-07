---
name: dynamic-requirements-tophat
description: Manually top-hat Dynamic Requirements PRs with real local console execution and produce concise PR Testing evidence. Use when verifying the Dynamic Requirements stack, exercising schema/policy/evaluation/dispatch behavior, or updating its PR Testing sections.
---

# Dynamic Requirements top-hatting

Read and follow [`end-to-end-tophat-evidence`](../end-to-end-tophat-evidence/SKILL.md) first. This skill adds Dynamic Requirements-specific boundaries and approved examples.

Verify one PR at a time, bottom-up. Prove only the behavior introduced by that PR; isolate and exclude up-stack behavior.

## Safety

- Never send synthetic signals to a shared Trust environment.
- Prefer real local collaborators and local persisted state over fixtures.
- Obtain explicit approval before adding temporary untracked artifacts under a World zone.
- Wrap temporary Organizations rows in `requires_new: true` transactions and raise `ActiveRecord::Rollback`.
- Intercept external publication and up-stack enqueue boundaries when they are outside the PR under test.
- Delete local policy records, neutralize reusable local intent state, remove temporary artifacts, stop started services, and confirm `git status --short` is clean.
- Do not edit a PR until Gaurav approves the proposed Testing section.

## Per-PR workflow

1. Read the PR diff/body and state its exact independent claim.
2. Choose the highest public entry point owned by the PR, normally GraphQL or the production operation.
3. Establish real preconditions first: registered schema, policy definition, stored policy, database state, or flag state.
4. Prefer a real local Trust policy and verify it through Organizations' actual primary-read client.
5. Show temporary cross-system artifact definitions in the Testing section, but omit incidental local creation mechanics.
6. Add transparent observers only where non-use/order matters. Observers record arguments and call `super`; fault injection must be explicit.
7. Run the happy path and relevant negative paths, capturing exact output.
8. Prove rollback and local-system cleanup.

## Evidence hierarchy

Use the smallest set that establishes the contract:

1. Public GraphQL response or production operation result.
2. Exact persisted database projection.
3. Matching structured log and bounded StatsD calls.
4. Real collaborator call arguments, such as `read_target: :primary`, when architecturally important.
5. For validation PRs, each exact public failure response plus its downstream-call and persisted-row proof. A compact table may supplement, but not replace, these payloads.
6. Final rollback query returning no rows.

Do not paste automated-test summaries, broad setup transcripts, server boot logs, or unrelated up-stack evidence. Capture low-level SQL/connection diagnostics in the raw transcript, but omit them from the PR when the design decision and tests already establish the point.

## Statement-to-output discipline

- Put each executed statement immediately before its exact observed output.
- Never paste detached JSON, hashes, metric arguments, or log fragments without their generating command.
- Clearly label tables as explanatory summaries when they reformat exact observations.
- Do not fabricate IDs, timestamps, GIDs, messages, counts, or cleaned-up output.
- Distinguish a method-boundary invocation from downstream delivery or ingestion.

## PR update

1. Fetch the body as data with `gs pr view <N> --json`; never round-trip rendered CLI output.
2. Replace only `### Testing`, preserving earlier sections verbatim.
3. Apply with `gs pr edit <N> --body-file <file> --json`.
4. Fetch the body back with `gs pr view <N> --json` and compare the exact body string.
5. Verify expected section order and reject pollution containing `Reviews:`, `binks`, `parent: #`, or `head sha`.

## Local browser demo mode

When asked to prepare a human-run Dynamic Requirements demo, also read [`local-end-to-end-demo`](../local-end-to-end-demo/SKILL.md).

Use the proven narrative:

```text
activate local Trust policy with aggregate placeholder
→ create a passing DR in Completeness Engine GraphiQL
→ observe aggregate true and policy in compliance
→ create a second DR requiring a missing field
→ observe the shared aggregate false and policy out of compliance
→ reset policy, signals, rows, queues, and debounce locks
```

Required local surfaces are Trust Battery UI/workers, Business Platform GraphiQL and worker, Query Engine with deterministic seeded data, the local Feast registry/emulator, Kafka, and Identity for browser authentication. Start Identity before Business Platform so its OAuth client registers during boot.

Prefer `~/dynamic-requirements-demo/` when its handles, worktree path, and branch remain compatible. Inspect `status.sh`, artifacts, schema GIDs, and active rows rather than assuming saved processes or state are current. Its `prepare-next-run.sh` is the proven fast rehearsal reset; it intentionally resets the complete local Trust Bigtable emulator and must never target a shared environment.

On macOS, if the ordinary forked Business Platform Hedwig pool crashes in `pg` while opening Query Engine, use the workspace's documented non-forked Hedwig process. It preserves the real delayed queue, serialized job, job class, Query Engine read, Kafka publication, and Trust processing while omitting only the failing local fork.

## Approved #232 pattern

The accepted shape for the stack root is:

- show the temporary Trust policy YAML;
- show the real GraphQL success response;
- query the exact persisted row;
- show the matching structured creation log and authorization/create metrics;
- show each schema-validation GraphQL failure payload with Trust-read, enqueue, and row counts;
- prove transaction rollback.
