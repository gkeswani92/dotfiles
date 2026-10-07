---
name: local-end-to-end-demo
description: Design, prepare, rehearse, and reset a fully local browser-driven end-to-end product demo across multiple services, databases, queues, workers, registries, authentication, and UIs. Use when asked to set up a demo environment, make a cross-service flow demonstrable by a human, prepare browser tabs and queries, or create repeatable setup/status/reset/cleanup scripts.
---

# Local end-to-end demo

Treat a live demo as a small product. It must have a deterministic story, real local boundaries, browser-operable entry points, health checks, and a fast reset.

For manual PR evidence rather than a presentation, also read [`end-to-end-tophat-evidence`](../end-to-end-tophat-evidence/SKILL.md). A demo optimizes for a human narrative; a top-hat optimizes for claim isolation and reviewer evidence.

## 1. Define the audience-visible story

Write the state sequence before starting services. Prefer three visible beats:

1. **Before:** a meaningful placeholder, empty, inactive, or non-compliant state.
2. **Action:** a public UI/API operation produces an immediate response.
3. **Convergence:** asynchronous work changes persisted state in another UI.

When useful, add a contrast step that reverses the result, such as `placeholder → true → false`. This proves the system is evaluating new input rather than displaying a hardcoded happy path.

Name the exact values, IDs, handles, URLs, and expected transitions. Avoid a narrative whose success depends on interpreting logs alone.

## 2. Map every boundary

Build a boundary table before implementation:

| Boundary | Example | Required proof |
| --- | --- | --- |
| Browser entry | GraphiQL, admin UI | Human can authenticate and submit |
| Write path | GraphQL mutation | Exact response and committed row |
| Dispatch | after-commit enqueue | Serialized job and queue |
| Worker | real local job processor | Job starts and completes |
| Read model | projection/query service | Deterministic seeded subject |
| Publication | local Kafka/RPC | Exact output value and identifier |
| Downstream processing | consumer/policy worker | Accepted state and re-evaluation |
| Final UI | policy/signal inspector | Visible value and status transition |

Label each boundary `real local`, `observed`, or `intentionally isolated`. Do not call the demo end to end while an unexplained fake sits in the main path.

## 3. Make safety structural

- Never publish synthetic signals or events to shared, staging, or production systems.
- Pin every collaborator to local hosts, emulators, databases, and Kafka.
- Use dedicated demo IDs, artifact handles, origins, and external references.
- Real asynchronous workers require committed local state; use explicit cleanup rather than rollback-only rows.
- Keep durable helpers outside the repository. Copy only temporary untracked artifacts into zone artifact directories.
- Record baseline `git status`; after generated commands, restore only drift observed from those commands.
- Never commit or push demo artifacts unless explicitly requested.

## 4. Separate lifecycle commands

Provide small, idempotent commands with one responsibility:

```text
setup     install artifacts, build local registries, configure flags
start     launch dependencies in the required order
status    check processes, URLs, fixtures, flags, and current demo state
open      open browser tabs and identify query/variables files
watch     print the audience-visible state transition
reset     delete rows, clear jobs/locks, restore placeholder state
stop      stop only demo application processes
cleanup   reset, stop, and remove temporary artifacts/registries
```

A presenter should not need to reconstruct shell history. Store PIDs and logs in the demo workspace, make repeated `start` safe, and make `status` explain whether the environment is ready.

## 5. Distinguish one-time setup from each run

One-time setup may include sparse-checkout expansion, `dev up`, migrations already checked into the repository, registry generation, emulator tables, and authentication services.

A normal demo run should be only:

```text
start → activate/open → execute → observe → reset
```

Do not put slow dependency installation or shared authentication renewal on the critical presentation path.

## 6. Choose deterministic fixtures and contrasts

Use a seeded local subject whose important values are known and inspectable. Design paired scenarios:

- one minimal requirement that certainly passes;
- one additional requirement that certainly fails because a named field is absent.

Verify both against the real read model before rehearsing. Use separate external references so the public response visibly distinguishes the two operations.

For aggregates, explain the combination rule in audience language:

```text
passing requirement AND failing requirement → aggregate false
```

## 7. Treat registries and artifact caches as services

Declarative systems often need more than a YAML file:

1. install the temporary artifact;
2. validate it through the runtime catalog;
3. generate any code or feature definitions;
4. apply only to an isolated local registry/emulator;
5. copy/export the registry where the consuming app expects it;
6. create emulator tables;
7. restart processes that cache definitions.

Use frozen package-manager modes where possible. Before any apply/deploy command, prove the target is a local emulator and refuse otherwise.

## 8. Start authentication before authenticated apps

Browser readiness includes the login path. Start local Identity/OAuth before the app that dynamically registers its client, then start or restart the app.

Preflight the exact browser URL. A healthy `curl` to an internal host does not prove that employee SSO, redirects, cookies, CSRF, or GraphiQL work. Open the real tab before the meeting and complete any interactive SSO prompt.

## 9. Verify asynchronous execution, not only enqueue

Separate these observations:

1. row committed;
2. dispatcher accepted the job;
3. delayed enqueuer released it after debounce;
4. worker began the expected class;
5. read model returned the subject;
6. producer published the exact value;
7. downstream consumer accepted it;
8. final UI converged.

Inspect stale jobs and concurrency/debounce locks during rehearsal. A successful mutation plus an unchanged UI often means the row exists but worker delivery stalled.

If the standard local worker crashes because of a native fork issue, preserve the real queue and job loop while omitting only the failing local process fork. Document the deviation and verify that serialization, delay, worker class, read, publication, and downstream processing remain real.

## 10. Rehearse the human path twice

Console execution is useful for diagnosis, but it does not validate the presentation.

1. Run the exact browser steps the presenter will use.
2. Capture the public response, committed row, worker execution, publication, and final UI.
3. Run the contrast transition.
4. Time the reset.
5. Reset to a truly fresh state.
6. Repeat the browser path once without agent intervention.

Leave the presenter at the first intended screen, not at the final rehearsed state.

## 11. Make reset trustworthy and fast

A reset must handle all durable state that can contaminate the next run:

- primary database rows, including soft-deleted rows;
- emitted signal and policy state;
- delayed jobs, recovered jobs, and concurrency/debounce locks;
- flags or local configuration overrides;
- cached registries when handles change.

Print the post-reset invariant, for example:

```text
policy=absent dynamic_requirements=0 queue=empty
```

Warn before resetting an entire local emulator. Provide an explicit non-interactive flag only for deliberate scripted local resets. Measure reset duration before promising it during a meeting.

## 12. Debug in boundary order

When the final value does not change, check in this order:

1. Did the browser operation return success?
2. Was the expected row committed and active?
3. Is the feature flag enabled for the exact subject ID format?
4. Did after-commit dispatch run?
5. Is a debounce/concurrency lock suppressing the job?
6. Did the worker execute rather than crash or only enqueue?
7. Did it read the expected local subject and artifact version?
8. Did it compute the expected result across every active row?
9. Did publication target local Kafka/service endpoints?
10. Did the downstream consumer store the signal and re-evaluate?
11. Is the UI reading the same entity, definition, and latest version?

Do not rerun the mutation blindly; duplicate rows may change the aggregate or obscure the original failure.

## Deliverables

Leave behind:

- a short presenter-first `README.md`;
- exact query and separate variables files for each beat;
- artifact templates;
- setup/start/status/open/watch/reset/stop/cleanup scripts;
- per-process logs;
- a shared-environment safety statement;
- the expected state sequence and recovery checklist.

## Worked pattern: Dynamic Requirements

A strong policy demo is:

```text
activate policy with aggregate placeholder
→ create DR requiring an existing field
→ real worker publishes aggregate true
→ create second DR requiring a missing field
→ same aggregate becomes false
→ one-command reset returns policy absent and DR count zero
```

This demonstrates activation, primary-read policy resolution, after-commit dispatch, grouping of multiple runtime requirements, Query Engine evaluation, publication, Trust ingestion, and policy convergence.

## Source

- Gaurav Keswani and Pi, fully local Dynamic Requirements browser demo and team presentation, September 4, 2026.
