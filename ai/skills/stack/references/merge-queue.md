# Merge Queue

This document covers Graphite's stack-aware merge queue setup and configuration.

## Overview

The Graphite Merge Queue automates rebasing during merges and keeps the trunk branch stable. Unlike traditional merge queues, it's specifically designed to handle stacked PRs efficiently.

## Key Benefits

### Problem Prevention

The merge queue addresses:
- Frequent trunk branch failures from incompatible concurrent merges
- Consistent rebasing delays blocking developers
- Lengthy CI checks combined with high PR merge rates

### Stack-Aware Processing

When multiple PRs from the same stack are queued together:
- Validates them in parallel rather than sequentially
- Enables "fast-forward merge" without re-running CI
- Significantly faster than traditional sequential merge queues

### Speed Advantage

Traditional merge queues slow teams by enforcing sequential commit validation. Graphite optimizes:
- Merge order optimization
- Concurrent/batched processing
- Stack-aware validation

## Merge Strategies

### 1. Rebase

Changes rebase on trunk with commits preserved (equivalent to GitHub's "Rebase and merge").

```
Before:            After merge:
main               main
 └── PR #1          └── commit A
      └── PR #2          └── commit B
```

Best for: Teams that want to preserve individual commit history.

### 2. Squash

Each PR is squashed to a single commit when merged.

```
Before:            After merge:
main               main
 └── PR #1          └── squashed commit (PR #1)
      (3 commits)        └── squashed commit (PR #2)
      └── PR #2
           (2 commits)
```

Best for: Teams that prefer clean, linear history with one commit per PR.

### 3. Fast-Forward Merge

Optional setting for either Rebase or Squash strategies. When enabled:
- Multiple stacked PRs can be merged together without re-running CI
- Each PR's CI only needs to pass once
- Dramatically speeds up stack merging

## Setup

### Prerequisites

1. Graphite Team or Enterprise plan
2. Graphite App installed on your organization
3. Admin access to configure GitHub branch protection

### Step 1: Enable Merge Queue in Graphite

1. Navigate to https://app.graphite.com/settings/merge-queue
2. Click "Add merge queue"
3. Select target repository via dropdown
4. Click "Next" to configure settings

### Step 2: Configure GitHub Branch Protection

**Push Permissions:**
1. Go to repository Settings → Branches → Branch protection rules
2. If push restrictions enabled, add `graphite-app` to actors with push access
3. **Recommended**: Make `graphite-app` the only actor with push access (encourages queue usage)

**Bypass PR Permissions:**
1. Enable "Allow specified actors to bypass required pull requests"
2. Add `graphite-app` to the bypass list
3. This enables faster merging with optimizations

### Step 3: Configure GitHub Rulesets (if using)

1. Go to repository Settings → Rules → Rulesets
2. Add `Graphite App` to the **Bypass list**
3. Set to "Always allow"
4. Apply to all rulesets affecting your merge queue repository and branch

### Step 4: Configure Merge Queue Options

| Option | Description |
|--------|-------------|
| Default Merge Strategy | Rebase (preserve commits) or Squash (single commit) |
| Timeout | Upper limit on queue residence time |
| Merge Label | GitHub label to queue PRs via GitHub UI |
| Required Checks | Which CI checks must pass |
| Auto-merge Stacks | Merge entire stack when bottom is ready |

**Merge Label Notes:**
- Users without Graphite accounts can queue PRs via label
- They'll be prompted to create a Graphite account
- Label automatically cascades through stacks

## Using the Merge Queue

### Adding PRs to Queue

**From Graphite Web:**
1. Open the PR
2. Click "Add to merge queue" button
3. PR enters queue and runs validation

**From CLI:**
```bash
gt merge          # Add current PR to queue
gt merge --stack  # Add entire stack to queue
```

### Queue Status

The merge queue shows:
- Current queue position
- Validation status (running, passed, failed)
- Estimated merge time

### Queue Notifications

Graphite comments on PRs at three key points:
1. When added to the queue
2. When merged successfully
3. If removed or failed

## Optimizations

### Three Core Optimizations

#### 1. Fast-Forward Merge

Run CI on all PRs in a stack in parallel rather than sequentially. Enables faster processing of stacked pull requests.

```
Traditional queue:
PR #1 → wait CI (10 min) → merge → PR #2 → wait CI (10 min) → merge
Total: 20+ minutes

Graphite with fast-forward:
PR #1 + PR #2 → validate together → merge both
Total: ~10 minutes
```

#### 2. Parallel CI

Processes multiple stacks simultaneously using speculative execution.

**Performance Improvements:**
- Average teams: 1.5x faster merges (33% decrease in p95 latency)
- Heavy stacking users: 2.5x faster merges (60% decrease in p95)

**Execution Modes:**

| Mode | Description | Trade-off |
|------|-------------|-----------|
| Individual CI | Run CI on each PR | Highest correctness |
| Top-only CI | Run CI only on topmost PR | Faster, less strict |

**Technical Details:**
- Creates temporary draft PRs with `gtmq_` branch prefix
- Speculative testing before PR reaches front of queue
- Successfully merged PRs show as "closed" in GitHub (Graphite shows "merged")

**Requirements:**
- `graphite-app` bot must bypass merge restrictions
- Repository must support draft PRs

#### 3. Batching (Private Beta)

Groups multiple stacks and runs CI in parallel on batches.

**Failure Handling:**

| Strategy | Description |
|----------|-------------|
| Full parallel isolation | Checks every stack individually |
| Bisection | Identifies issues with fewer CI runs |

### CI Cost Considerations

Parallel execution only increases CI runs when tests fail in the queue:
- **Reliable test suites**: Minimal additional CI runs
- **Flaky tests**: May cause more CI runs; consider fixing flaky tests first

### Parallel Validation Example

```
Without parallel:
Stack A (3 PRs) → 30 min CI → merge → Stack B (2 PRs) → 20 min CI → merge
Total: 50 minutes

With parallel:
Stack A + Stack B → validate together → merge both
Total: ~30 minutes (limited by longest CI)
```

### Speculative Execution

The queue pre-rebases PRs while waiting:
- Reduces merge time when PR reaches front
- Detects conflicts early
- Updates queue position estimates
- Begins CI before PR is technically "next"

## Troubleshooting

### PR Stuck in Queue

**Causes:**
- CI checks taking too long
- Conflicts with other queued PRs
- Required checks not configured correctly

**Solutions:**
1. Check CI status in GitHub Actions
2. Review merge queue logs in Graphite
3. Manually remove and re-add to queue

### PR Ejected from Queue

**Causes:**
- CI failed
- Conflicts with merged changes
- Required approvals revoked

**Solutions:**
1. Fix CI failures and re-add
2. Rebase on latest main: `gt sync && gt submit`
3. Re-request approvals

### Conflicts During Merge

If conflicts arise:
1. PR is removed from queue
2. Notification posted to PR
3. Developer must resolve locally:
   ```bash
   gt sync
   # Resolve conflicts
   gt continue
   gt submit
   ```
4. Re-add to merge queue

## External Merge Queue Integration

For teams using external merge queues (like GitHub's native queue or Mergify), Graphite offers a beta integration:

### Setup

1. Go to Repository Settings → Merge Queue
2. Select "External merge queue"
3. Configure to work with your existing queue

### Limitations

External queue integration:
- Doesn't provide stack-aware optimizations
- May require sequential merging of stacked PRs
- Still provides Graphite's UI and PR management benefits

## Best Practices

### 1. Keep Stacks Small

Smaller stacks merge faster:
- 3-5 PRs per stack is optimal
- Each PR should be independently reviewable
- Split large features across multiple stacks if needed

### 2. Require All Checks

Configure all critical CI checks as required:
- Prevents broken code from merging
- Maintains trunk stability
- Catch issues before they block others

### 3. Use Fast-Forward for Stacks

Enable fast-forward merge for repositories with many stacked PRs:
- Dramatically reduces merge time
- Maintains CI integrity
- Best balance of speed and safety

### 4. Monitor Queue Health

Regular monitoring:
- Average queue wait time
- Failure/ejection rate
- Most common failure reasons

Address patterns:
- Flaky tests causing ejections
- Slow CI delaying merges
- Frequent conflicts suggesting coordination issues
