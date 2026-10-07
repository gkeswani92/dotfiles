---
name: end-to-end-tophat-evidence
description: Plan and run manual end-to-end top-hats, capture exact observable proof, and publish concise PR Testing sections. Use when asked to top-hat a change, manually verify a PR, exercise a real local flow, or improve PR testing evidence.
---

# End-to-end top-hat evidence

Manually prove one change through the highest useful production entry point, then publish only the evidence a reviewer needs to trust the behavior.

## 1. Define the verification contract

Before running anything:

1. Name the exact behavior introduced by this PR.
2. Separate down-stack prerequisites from this PR's behavior and up-stack consequences.
3. Choose success and negative scenarios that can falsify the claim.
4. State which boundaries will be real, observed, captured, or fault-injected.
5. Agree on side effects, cleanup, and whether temporary local artifacts are allowed.

For stacked PRs, verify bottom-up. Each PR must stand on its own; do not use an up-stack result as proof for a lower PR.

## 2. Prefer real execution

Use, in order:

1. The public API or UI entry point.
2. The production operation/service entry point when no public surface exists yet.
3. Real local collaborators, databases, queues, flags, and seeded data.
4. Fixtures or synthetic objects only when the real boundary is unsafe or unavailable.

Prefer persisted local state over mocked return values. When temporary cross-system definitions are needed, show their relevant definition in the PR so reviewers understand the scenario; omit incidental mechanics used to load or store them locally.

Never send synthetic test traffic or signals to a shared environment. Do not imply a captured method call reached downstream ingestion.

## 3. Isolate only the unsafe boundary

Keep production code real up to the narrowest external or asynchronous boundary.

A passive observer should record arguments and call `super`. A captured boundary may return a controlled result when the real effect would be unsafe. Fault injection must be explicit in both the executed statement and the PR prose.

Examples:

- Capture an external publication call instead of sending it.
- Capture the final queue enqueue while exercising the real dispatcher.
- Raise at that same boundary to prove failure handling.
- Observe database queries or collaborator calls without replacing their behavior.

Do not stub an entire collaborator when a real local instance is available.

## 4. Respect asynchronous visibility

A separate worker connection cannot see an uncommitted rollback-only row. Choose deliberately:

- To prove dispatch ordering safely, capture the final enqueue and query row visibility inside that capture.
- To run job code while retaining rollback, invoke it synchronously in the transaction and disclose that delivery was not asynchronous.
- To test real asynchronous delivery, commit local state, run the worker, and perform explicit cleanup. Obtain approval before relaxing rollback-only safety.

Do not conflate enqueue acceptance, job execution, and downstream publication. They are separate claims and often belong to different PRs.

## 5. Establish preconditions first

Before the action, print the exact state that makes the scenario meaningful:

- request or mutation variables;
- policy/configuration/feature-flag definition;
- persisted rows or absence of rows;
- active/inactive or placeholder/value state;
- seeded subject data;
- real collaborator readback.

A negative result is not evidence unless its precondition is visible.

## 6. Capture proof at several boundaries

Use the smallest useful combination:

1. Public response or production operation return.
2. Exact persisted database projection.
3. External call or enqueue arguments.
4. Structured logs.
5. Bounded metrics.
6. Negative-path non-use: zero collaborator calls, loader construction, queries, evaluation, enqueue, or publication.
7. Rollback and cleanup readback.

For validation PRs, show each exact public failure payload—field/path, code, message, and null result where applicable. A table may summarize but must not replace those responses.

## 7. Preserve statement-to-output provenance

Every output in the PR must be attributable:

```text
executed statement
exact observed output
```

Rules:

- Never paste detached JSON, hashes, log fields, or metrics.
- Show the statement that produced a projection or observer output.
- Label reformatted tables as explanatory summaries.
- Do not invent or prettify IDs, timestamps, GIDs, messages, counts, or values.
- Keep complete raw scripts and transcripts under `/tmp` for auditability.

## 8. Shape the PR Testing section

A strong section usually contains:

```markdown
### Testing

- **Development-console end-to-end top-hat.** Scenario, real boundaries,
  captured unsafe boundary, rollback/cleanup, and shared-environment disclaimer.

Relevant temporary definition, if needed.

Executed public/production call.
Exact response.

Database query.
Exact persisted state.

Log/metric or external-boundary statement.
Exact output.

Negative calls and exact failure responses.
Non-use and zero-row proof.

Rollback/cleanup query.
Exact empty/restored output.
```

Optimize for reviewer confidence, not transcript completeness. Keep server boot logs, environment repair, artifact-loading mechanics, generated test counts, and redundant connection diagnostics in raw artifacts rather than the PR.

## 9. Clean up completely

Before reporting completion:

- Roll back temporary transactional rows.
- Delete committed local test records created across services.
- Restore feature-flag assignments and configuration to their exact prior state.
- Neutralize durable local triggers when deletion is unsupported.
- Remove temporary artifacts.
- Stop only services started for the top-hat.
- Confirm the relevant clients return empty/restored state.
- Confirm the repository worktree is clean.

If cleanup is incomplete, say so and do not present the run as complete.

## 10. Publish safely

Do not edit the PR until the user approves the proposed Testing section.

When updating a PR:

1. Fetch the current body as structured data, not rendered CLI output.
2. Preserve all approved sections and replace only `### Testing` unless asked otherwise.
3. Apply through the PR's owning provider.
4. Fetch the body back as structured data and compare the exact string.
5. Verify section order and reject accidental CLI/reviewer pollution.
6. Report the PR URL and readback hash.

For `shop/world` Meteorite PRs, use `gs`; never mix providers and never merge as part of top-hatting.

## Anti-patterns

- Hypothetical examples presented as execution.
- Automated-test summaries used as manual proof.
- Large synthetic JSON objects with no generating statement.
- Broad mocks that bypass the code under review.
- Shared-environment test writes.
- Running up-stack behavior to prove a lower PR.
- Claiming downstream metric/log ingestion from a captured method invocation.
- Publishing every diagnostic merely because it was collected.
- Leaving flags, services, rows, queued jobs, or temporary files behind.
