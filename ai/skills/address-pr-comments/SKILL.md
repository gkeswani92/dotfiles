---
name: address-pr-comments
description: Pull unresolved PR review comments, summarize them, discuss approach, then implement fixes. Use when asked to address PR comments, pull PR feedback, or handle review threads.
---

# Address PR Review Comments

## Workflow

Follow these steps strictly in order. Do NOT skip to implementation.

### Step 1: Fetch unresolved review threads

Use the GitHub GraphQL API via `gh` CLI to pull all unresolved review threads. Include `databaseId` on comments so we can react to them later:

```bash
gh api graphql -f query='
{
  repository(owner: "OWNER", name: "REPO") {
    pullRequest(number: PR_NUMBER) {
      reviewThreads(first: 50) {
        nodes {
          isResolved
          comments(first: 10) {
            nodes {
              databaseId
              author { login }
              body
              path
              line
            }
          }
        }
      }
    }
  }
}' --jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false) | {path: .comments.nodes[0].path, line: .comments.nodes[0].line, comment_id: .comments.nodes[0].databaseId, comments: [.comments.nodes[] | {author: .author.login, body: .body}]}'
```

Store the `comment_id` for each thread -- this is used in Step 5 to add reactions.

Extract the owner/repo from the PR URL. If no URL is provided, check for an open PR on the current branch using `gh pr view`.

### Step 2: Summarize in a table

Present ALL unresolved threads in a markdown table:

| # | File | Line | Reviewer | Summary | Urgency | My Take |
|---|------|------|----------|---------|---------|---------|
| 1 | path/to/file.rb | 42 | reviewer | One-line summary of the comment | High/Medium/Low | Your assessment of whether it makes sense, whether it's in scope, and what the fix would look like |

**Urgency levels:**
- **High**: Correctness issue, bug, or blocking concern that must be addressed
- **Medium**: Valid improvement that strengthens the code (test quality, naming, observability)
- **Low**: Nit, style preference, or suggestion that could be deferred

**My Take** should include:
- Whether you agree with the feedback
- Whether the change is in scope for this PR or should be deferred
- If it requires code changes, what those changes would look like at a high level
- Any tradeoffs or concerns (e.g., Rubocop constraints, test infrastructure requirements)

### Step 3: Discuss with the user

Use the AskUserQuestion tool to ask about any threads where:
- You're unsure whether the user agrees with the feedback
- There are multiple valid approaches to address the comment
- The change might have implications beyond what's obvious
- You need context about past decisions or reviewer relationships

Do NOT ask about threads where the fix is obvious and non-controversial.

### Step 4: Confirm plan of action

After discussion, present a clear plan:

```
Plan:
- Thread 1: [action] - [brief description of change]
- Thread 2: [action] - [brief description of change]
- Thread 3: No change - [reason]
```

For any thread where the decision is "No change" or "Skip", draft a reply message the user can post on the PR thread. The reply should:
- Be written in the user's voice (direct, concise, technical, no fluff)
- Explain WHY we're not making the change (not just "we decided not to")
- Reference concrete constraints (Rubocop thresholds, existing coverage, scope boundaries, etc.)
- Acknowledge the reviewer's point before explaining the decision
- Avoid em dashes

Example:
> Good call. I tried this but inlining the filter_map pushes matching_signal_gids to cyclomatic complexity 6/5, which Rubocop rejects. The separate method exists specifically to stay under that threshold. Same output, just split to satisfy the linter.

Wait for user confirmation before proceeding.

### Step 5: Implement and respond

Only after user confirms:
1. Make the code changes
2. Run style checks (`dev style` on changed files)
3. Run relevant tests
4. Run typecheck if source files changed
5. For threads we resolved with code changes, add a thumbs up reaction to the reviewer's comment:
   ```bash
   gh api --method POST repos/{owner}/{repo}/pulls/comments/{comment_id}/reactions -f content='+1'
   ```
   Use the `comment_id` captured in Step 1. Ask the user before adding reactions.
6. Report results

## Rules

- **Never skip the discussion step.** Even if all comments seem straightforward, present the table and get confirmation.
- **Never implement before confirming.** The user may disagree with a reviewer's suggestion or want to handle it differently.
- **Read the actual code** before forming your take. Don't opine on code you haven't seen.
- **Check for Rubocop/style implications** when suggesting refactors. Mention if a suggested change would violate linter rules.
- **Distinguish "our code" from "pre-existing code".** If a reviewer comments on code we didn't write in this PR, flag it as out of scope but note whether it's worth fixing.
- **Draft reply messages** when the user asks. Avoid em dashes in reply text.
