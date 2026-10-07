---
name: rewrite-github-issue
description: Transforms messy GitHub issues into clear, actionable descriptions. Use when asked to "rewrite issue #123", "clean up this GitHub issue", "summarize issue thread", "write a description for this empty issue", or when an issue has 10+ comments needing consolidation.
---

# Rewrite GitHub Issue

Transform lengthy GitHub issue threads into clear, structured descriptions that engineers can act on immediately.

## Core Principle

**Clarity above all.** An engineer without context should understand what to do in 30 seconds.

## Quick Decision

| Issue State            | Action                                           |
| ---------------------- | ------------------------------------------------ |
| Has body + comments    | Rewrite: Extract signal, discard noise           |
| Empty body, only title | Investigate: Search codebase, write description  |
| Has Slack thread       | Preserve: Keep original at bottom in `<details>` |

## Workflow

### Step 1: Fetch the Issue

```bash
gh issue view <issue-number> --repo <owner/repo> --comments
# Or with URL:
gh issue view <URL> --comments
```

### Step 2: Choose Path

**Empty issue?** → See [references/empty-issues.md](references/empty-issues.md)

**Has content?** → Continue below

### Step 3: Extract Signal

Read the entire thread. Note:

| Signal (Keep)                | Noise (Discard)                |
| ---------------------------- | ------------------------------ |
| Problem statement            | "+1", "me too", "thanks"       |
| Error messages, stack traces | Resolved clarifying questions  |
| Root cause analysis          | Superseded debugging attempts  |
| Proposed solutions           | Off-topic tangents             |
| Design decisions             | Duplicate information          |
| Code snippets                | Social exchanges               |
| Screenshots/images           | Meta-comments about the issue  |

### Step 4: Handle Images

If the issue contains images:

1. Download with `curl -sO <URL>` (public images)
   - For GitHub-hosted images: `curl -L -H "Authorization: token $(gh auth token)" "<URL>" -o image.png`
2. View with Read tool to understand content
3. Include in rewrite with descriptive context

See [references/handling-images.md](references/handling-images.md) for details.

### Step 5: Structure the Rewrite

```markdown
## Description
[Problem in 1-3 sentences. Impact. Why it matters.]

### Screenshots
[If available - descriptive title + context + image]

## Proposed Solution
[Implementation approach. Key constraints. Open questions.]

## Acceptance Criteria
- [ ] [Criterion 1]
- [ ] [Criterion 2]

---

<details>
<summary>Original Slack Thread (Reference)</summary>

[ENTIRE ORIGINAL THREAD - UNEDITED]

</details>
```

### Step 6: Preserve Technical Accuracy

**Always preserve exactly:**

- Error messages and codes
- Version numbers
- Code snippets with proper formatting
- Performance metrics
- Links to related issues/PRs

### Step 7: Update the Issue

Present rewrite for review, then:

```bash
gh issue edit <issue-number> --body "<new-description>"
gh issue comment <issue-number> --body "Updated issue description to consolidate discussion. Original preserved at bottom."
```

## Rewriting Patterns

### Bug Reports

```markdown
## Description
[Bug behavior] occurs when [conditions]. Affects [users/systems] by [impact].

### Screenshots
**Current Behavior (Bug)**
[Description]:
![Bug screenshot](URL)

## Root Cause
[Technical explanation]

## Proposed Solution
[Fix approach with code snippet if relevant]
```

### Feature Requests

```markdown
## Description
[User need] requires [feature]. Current gap: [what's missing].

## Proposed Solution
Implementation: [approach]

Key requirements:
- [requirement 1]
- [requirement 2]

Out of scope: [excluded items]
```

### Investigation Issues

```markdown
## Description
[Observable problem] with [symptoms]. Investigation needed.

## Proposed Solution
Investigation plan:
1. [step 1]
2. [step 2]

Known data points:
- [finding 1]
- [finding 2]
```

## Long Threads (50+ Comments)

Use these compression targets:

| Comments | Key Points to Extract |
| -------- | --------------------- |
| 10-20    | 3-5                   |
| 20-50    | 5-8                   |
| 50-100   | 8-12                  |
| 100+     | 12-15                 |

**Pattern: Last State Wins**
When understanding evolved through discussion, capture the final, correct conclusion—not the journey.

**Pattern: Thematic Grouping**
Bundle related technical points even if scattered across comments.

See [references/rewriting-patterns.md](references/rewriting-patterns.md) for advanced techniques.

## Slack Thread Preservation

**CRITICAL:** Always preserve original Slack threads at the bottom.

Format:

```markdown
---

<details>
<summary>Original Slack Thread (Reference)</summary>

<!-- PASTE ENTIRE ORIGINAL THREAD HERE - NO EDITING -->

</details>
```

**Why:** Maintains audit trail, preserves exact quotes/timestamps, allows verification.

## Best Practices

| Do                                   | Don't                        |
| ------------------------------------ | ---------------------------- |
| Lead with impact                     | Bury the problem             |
| Use active voice                     | Use passive voice            |
| Be specific: "500 errors on /users"  | Be vague: "API is broken"    |
| Include metrics: "3.5s → 180ms"      | Say "made it faster"         |
| Highlight open questions             | Pretend decisions are made   |
| Link related issues/PRs              | Lose context                 |

## Validation Checklist

Before finalizing, ask:

- [ ] Could an engineer without context understand what to do?
- [ ] Are all critical technical details preserved?
- [ ] Is the Slack thread preserved at bottom (if applicable)?
- [ ] Are images included with descriptive context?
- [ ] Are open questions explicitly called out?

## References

- [references/rewriting-patterns.md](references/rewriting-patterns.md) - Advanced condensing techniques
- [references/empty-issues.md](references/empty-issues.md) - Writing descriptions from scratch
- [references/handling-images.md](references/handling-images.md) - Image analysis workflow
- [examples/before-raw-issue.md](examples/before-raw-issue.md) - Example messy thread
- [examples/after-rewritten.md](examples/after-rewritten.md) - Same issue rewritten
