# Best Practices

This document covers best practices for reviewing stacked PRs, creating stacks, and organization setup.

## For Reviewers

### 1. Review PRs Independently

Review each PR in a stack as though it was an independent change. If understanding requires context from other PRs, request the author restructure the stack.

**Why**: Each PR should be self-contained and reviewable on its own merits.

### 2. Review Promptly

Don't delay reviews waiting for downstack approvals. Serializing reviews negates the time benefits of stacking.

**Anti-pattern:**
```
Wait for PR #1 approval → then review PR #2 → then review PR #3
```

**Better:**
```
Review all PRs as they become ready, in parallel if possible
```

### 3. Start from the Bottom

When tagged on multiple PRs in a stack, begin reviewing the lowest PR (closest to main) and work upward.

**Why**:
- Bottom PRs are foundational
- Changes at bottom may invalidate upper PRs
- Logical dependency order

### 4. Check for Upstack Changes

Look for orange indicators showing code changes further up the stack:

1. Navigate to those changes for context
2. Return to current review using keyboard shortcuts
3. Use stack visualization to understand relationships

### 5. Provide Actionable Feedback

- Be specific about what needs to change
- Explain why the change is needed
- Suggest concrete alternatives when rejecting approaches

## For Stack Authors

### 1. Separate Logically

Each PR should be independently understandable and reviewable.

**Good separation:**
```
PR 1: Add database migration
PR 2: Add API endpoint using new schema
PR 3: Add frontend consuming API
PR 4: Add tests
```

**Poor separation:**
```
PR 1: Half of a feature
PR 2: Other half (neither works alone)
```

### 2. Submit Promptly

Open PRs for review as soon as ready, even while stacking additional changes on top.

**Why**:
- Reviews can start while you continue working
- Parallel progress
- Earlier feedback

### 3. Use Draft Status Appropriately

| Status | When to Use |
|--------|-------------|
| Draft | Actively working, not ready for review |
| Ready | Ready for review, even if stacking more on top |

Only open (non-draft) PRs should be review-ready.

### 4. Choose Relevant Reviewers

Assign reviewers suited to each individual change rather than the same team for every PR.

**Example:**
```
PR 1 (Database): @backend-team
PR 2 (API): @api-team
PR 3 (Frontend): @frontend-team
```

Use Graphite automations to automate based on file paths.

### 5. Enable Merge Automation

Use "merge when ready" to streamline merging once approvals are obtained. Only disable for PRs requiring manual intervention.

### 6. Keep PRs Small

Target sizes:
- **Ideal**: < 200 lines changed
- **Acceptable**: < 400 lines changed
- **Consider splitting**: > 400 lines

Smaller PRs:
- Get reviewed faster
- Have fewer bugs
- Are easier to understand
- Merge more quickly

## Stack Structure Frameworks

### Framework 1: By Layer

Organize by architectural layer:

```
main
 └── database-migration
      └── backend-api
           └── frontend-ui
                └── tests
```

**Best for**: Full-stack features

### Framework 2: By Component

Organize by feature component:

```
main
 └── user-model
      └── user-service
           └── user-controller
```

**Best for**: Backend features

### Framework 3: By Dependency

Order by what depends on what:

```
main
 └── utility-functions
      └── core-logic
           └── feature-implementation
```

**Best for**: Library/utility work

### Framework 4: By Risk

Put riskiest changes at bottom:

```
main
 └── risky-refactor (easy to revert)
      └── feature-using-refactor
           └── additional-enhancements
```

**Best for**: Refactoring with new features

### Framework 5: By Review Speed

Put quick-to-review at bottom:

```
main
 └── config-change (quick review)
      └── simple-migration (quick review)
           └── complex-feature (longer review)
```

**Best for**: Unblocking faster merges

## Organization Setup

### 1. Update GitHub Branch Protection

**Disable these settings:**
- "Dismiss stale approvals when new commits are pushed"
- "Require approval of the most recent reviewable push"

**Why**: These settings cause problems with stacked PRs where rebasing is common.

### 2. Set Up Reviewer Automations

Use Graphite automations instead of CODEOWNERS for:
- More granular control
- Better monorepo support
- File path-based assignment

**Example automation:**
```
Condition: Files match `src/backend/**`
Action: Add reviewer @backend-team

Condition: Files match `src/frontend/**`
Action: Add reviewer @frontend-team
```

### 3. Flag Large PRs

Automate warnings on PRs exceeding thresholds:

```
Condition: Lines changed > 250 OR Files changed > 25
Action: Post comment suggesting stack decomposition
```

### 4. Configure Branch Naming

Standardize branch naming with `gt config`:
- Add team/user prefix
- Include date if needed
- Restrict characters for consistency

### 5. Set Up CI Optimizations

Configure CI to:
- Ignore `graphite-base/*` branches
- Use Graphite's CI optimizer for stacks
- Skip redundant runs on middle-of-stack PRs

## Common Anti-Patterns

### Anti-Pattern: Mega PR

**Problem**: Single PR with 2000+ lines spanning multiple concerns.

**Solution**: Break into stack of focused PRs, each addressing one concern.

### Anti-Pattern: Dependent PRs That Can't Stand Alone

**Problem**: PR #2 is meaningless without PR #1's context.

**Solution**: Each PR should be independently valuable. Restructure if needed.

### Anti-Pattern: Waiting for Full Stack Approval

**Problem**: Not merging bottom PRs until entire stack is approved.

**Solution**: Merge approved bottom PRs immediately. Reduces risk, gets value deployed faster.

### Anti-Pattern: Same Reviewers for Everything

**Problem**: Assigning the same person to every PR in stack.

**Solution**: Match reviewers to PR content. Frontend expert reviews frontend, etc.

### Anti-Pattern: Never Using Draft Status

**Problem**: Opening PRs for review while still actively changing them.

**Solution**: Use draft status until PR is actually ready for review.

## Handling Common Scenarios

### Scenario: Reviewer Requests Changes to Bottom PR

1. Check out the affected branch: `gt checkout bottom-pr`
2. Make requested changes
3. Amend: `gt modify -a`
4. Resubmit stack: `gt submit --stack`
5. Graphite automatically restacks dependent PRs

### Scenario: Need to Add PR Between Existing PRs

```bash
gt checkout existing-pr
gt create --insert -am "new intermediate change"
```

The `--insert` flag places new branch between current and its parent.

### Scenario: Bottom PR Approved, Ready to Merge

1. Merge immediately via Graphite UI
2. Run `gt sync` locally to update
3. Continue working on remaining stack

### Scenario: Merge Conflict in Stack

```bash
gt sync
# Conflicts appear
# Resolve conflicts in editor
git add <resolved-files>
gt continue
gt submit --stack
```

### Scenario: Abandoning a PR Mid-Stack

```bash
gt checkout pr-to-abandon
gt delete
# Children automatically reparent to deleted PR's parent
```

## Metrics to Track

### Team Health Indicators

| Metric | Target | Warning |
|--------|--------|---------|
| Average PR size | < 300 lines | > 500 lines |
| Time to first review | < 4 hours | > 24 hours |
| Review cycles | < 2 | > 4 |
| Merge time | < 1 day | > 3 days |

### Stacking Adoption

| Metric | Good Sign |
|--------|-----------|
| PRs per stack | 2-5 average |
| Stack merge rate | > 50% merged together |
| Restack frequency | Low (good stack hygiene) |

Use Graphite Insights to track these metrics over time.
