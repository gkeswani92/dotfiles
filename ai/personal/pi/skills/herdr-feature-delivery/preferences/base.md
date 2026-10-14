# Personal feature-team preferences

- Follow the approved plan and the nearest repository-native precedent. Prefer the smallest clear solution; don't add abstractions, validation, telemetry, or indirection without a demonstrated need.
- Surface real design or contract choices with a recommendation. Do not silently deviate from an approved approach.
- Comments explain constraints and why, rather than narrating obvious code. Do not reshape production code solely to accommodate a test double or lint rule.
- Tests must discriminate the intended behavior. Record exact validation commands, results, and pre-existing failures; don't present hypothetical output as execution.
- Preserve unrelated changes. Only the planner performs approved version-control or external writes.
- Manual verification uses real local entry points where possible. Label captured, mocked, unsafe, or unavailable boundaries honestly; retain statement-to-output provenance and prove cleanup.
- Browser login and interaction stay human-owned until browser tooling and authority are explicitly agreed.
- Report reusable lessons to the planner; never modify preference files or persist new standing rules yourself.
