---
name: production-safe-flagged-change
description: Safely changes behavior on a live production code path behind a feature or Verdict flag by preserving the current implementation as the disabled branch, isolating the new implementation as the enabled branch, testing both, rolling out gradually, and deleting the old branch after 100% soak. Use when modifying an endpoint, worker, consumer, or UI flow that already serves production traffic.
---

# Production-safe flagged change

Use this pattern when changing a live path whose current behavior must remain available during rollout.

## Core shape

```text
flag false -> current production implementation
flag true  -> new implementation
```

Keep the two paths visibly separate. Do not refactor the current path through new shared plumbing merely to reduce duplication. Temporary duplication is cheaper than an ambiguous rollback boundary.

## Before editing

1. Capture the current implementation and its tests from the exact base commit.
2. Name the public behavior and operational side effects that must remain unchanged.
3. Choose one branch point before the first new side effect, query, transformation, or collaborator.
4. Confirm the flag subject and failure default. A flag failure must select the safe current path.
5. Identify all surfaces that must use the same assignment to avoid mismatched states.

## Implementation

1. Keep the current implementation intact in the disabled branch.
2. Put new queries, writes, collaborators, transformations, and errors only in the enabled branch.
3. Share only code that was already shared before the change, or immutable helpers whose behavior is proven identical.
4. Keep the flag handle literal at the decision site when repository cleanup tooling relies on code search.
5. Document intentional temporary duplication and the exact cleanup step.

## Tests

Prove both lanes independently.

Flag false:

- exercises the current implementation;
- receives the same inputs and output;
- preserves existing errors, fallbacks, logs, metrics, and side effects;
- never reaches new collaborators or data stores.

Flag true:

- exercises the complete new behavior;
- covers success, failure, and boundary cases;
- proves the expected new collaborators and side effects.

Also test flag failure or missing configuration when the framework allows it. In Organizations tests, use `enable_flag_for` and `disable_flag_for`, never manual `Verdict::Flag.enabled?` stubs.

## Rollout

1. Create the flag inert at 0%.
2. Deploy with every production subject on the disabled path.
3. Enable controlled non-merchant or test subjects first.
4. Compare errors, latency, data-store load, logs, and business output between lanes.
5. Expand deliberately while keeping rollback available.
6. Coordinate related flags and policy/data activation so disabling one surface does not strand users.
7. After 100% rollout and soak, create a cleanup PR that removes the flag, disabled path, temporary duplication, flag definition, and obsolete tests.

## Safety limits

This pattern minimizes behavioral rollout risk but is not completely risk-free. New code still loads, flag evaluation still runs, boot and syntax can still fail, and an accidental assignment can expose the new path. Keep CI, local tests, monitoring, and rollback plans.

If the new path writes durable state, determine what happens when the flag is turned off after writes occur. A code rollback may require stopping creation, deactivating policies, replaying work, or repairing data.

## Source

- Gaurav Keswani, September 9, 2026: use an explicit current-path/new-path flag split for changes to live production systems, then remove the old path after 100% rollout.
- Dynamic Requirements #172 validationSchema rollout discussion.
