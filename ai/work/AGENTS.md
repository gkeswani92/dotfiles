# Global Agent Instructions

## Behavioral Guidelines

### 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:

- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

### 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:

```txt
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## Delegated Review Validation Ownership

When coordinating an implementer and an independent reviewer:

- The implementer and lead own routine validation: tests, typechecks, linters, formatters, package checks, builds, generators, and service setup.
- The reviewer evaluates the artifact, test discrimination, and supplied validation evidence; it must not routinely rerun those checks for confidence.
- A reviewer may run one narrow, cheap probe only for a concrete suspected defect that cannot be resolved by reading code or existing evidence, and must explain why it was necessary.
- Missing duplicated reviewer validation is never a finding.
- The lead runs or coordinates the final required validation against the exact candidate before publication or team cleanup.

## Slack Thread Replies

When I ask you to draft or revise a reply to a Slack thread, end your turn with a message that contains only the draft, so `/copyslack` copies exactly that text:

- No preamble, headings, notes, or sign-off in that final message, and don't wrap the draft in a code block or quote.
- Put any context, questions, or change notes in an earlier message, before your last tool call.
- Still copy the draft with `pbcopy` and verify it as usual; `/copyslack` overwrites that copy with rich text when I run it.

## Searching My Notes (qmd)

qmd indexes my Obsidian vault and Pi memory: meeting notes, 1:1s, design decisions, and project history for CE, DCO, Attestations, DR/DC, Entities, and Trust. In Pi, use the `qmd_query` tool; elsewhere, use the `qq` command. Skip this section if neither is available.

- Search it before design or implementation decisions in those areas, and whenever I ask about past decisions, people, or meetings.
- Use the `work`, `daily`, and `pi-memory` collections. Search `career` only when I ask.
- Cite the note you relied on. Notes record what was discussed, not what shipped, so confirm current behavior in code.

## Organizations Codebase Conventions

- **StatsD**: Always use `BusinessPlatformStatsD.track(` instead of `StatsD.increment` — it adds data tag cleaning.
- **Verdict flags in tests**: Always use the `Verdict.disable_flag_for` helper — no manual stubbing of `Verdict::Flag.enabled?`.
- **Avoid OpenStruct**: Use `Struct` or `Data.define` instead. OpenStruct is discouraged.

## Dev Execution Requirements

**CRITICAL: Always use /opt/dev/bin/dev for dev commands**

The path for `dev` commands like `dev test`, `dev style`, `dev server`, etc. are accessible via `/opt/dev/bin/dev`

When running commands in background or non-interactive shells, always use the full path `/opt/dev/bin/dev` instead of just `dev`.
