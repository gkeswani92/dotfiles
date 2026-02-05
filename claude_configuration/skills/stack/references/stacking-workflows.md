# Stacking Workflows

This document provides detailed stacking patterns and advanced workflows for Graphite.

## Understanding Stack Architecture

### Mental Model

A stack is a chain of dependent branches where each branch builds on the previous:

```
main (trunk)
 │
 └── auth-api          PR #101: Add authentication API
      │
      └── auth-ui      PR #102: Add login UI (depends on #101)
           │
           └── auth-tests  PR #103: Add auth tests (depends on #102)
```

Key principles:
- Each branch has exactly one parent
- Changes flow downward (parent → child)
- Reviews can happen in parallel
- Merging happens bottom-up

### Why Stack?

**Without stacking:**
```
main ←── giant-feature-branch (2000+ lines, days to review)
```

**With stacking:**
```
main ← auth-api (200 lines) ← auth-ui (300 lines) ← auth-tests (150 lines)
         ↓                      ↓                      ↓
      Review in 20 min      Review in 30 min       Review in 15 min
```

## Basic Stacking Workflow

### Starting a New Stack

```bash
# 1. Start from trunk
gt checkout main

# 2. Create first branch
echo "api changes" > api.js
gt create -am "feat(api): add user endpoint"

# 3. Stack second branch on top
echo "frontend changes" > frontend.js
gt create -am "feat(ui): add user page"

# 4. Stack third branch
echo "test changes" > test.js
gt create -am "test: add user tests"

# 5. Submit entire stack
gt submit --stack
```

### Viewing Your Stack

```bash
# Full view with PR status
gt log

# Output example:
# ◉ test-user-tests (PR #103 - Draft)
# │ test: add user tests
# │
# ◉ feat-user-page (PR #102 - Changes Requested)
# │ feat(ui): add user page
# │
# ◉ feat-user-endpoint (PR #101 - Approved)
# │ feat(api): add user endpoint
# │
# ◉ main

# Compact view
gt ls
```

### Navigating the Stack

```bash
gt up          # Move to child branch
gt down        # Move to parent branch
gt top         # Jump to top of stack
gt bottom      # Jump to bottom (first branch above trunk)
gt checkout    # Interactive branch picker
```

## Handling Review Feedback

### Updating a Branch Mid-Stack

When a reviewer requests changes to a branch in the middle of your stack:

```bash
# 1. Checkout the branch needing changes
gt checkout feat-user-endpoint

# 2. Make the requested edits
vim api.js

# 3. Amend the commit
gt modify -a

# 4. Graphite automatically restacks children
# 5. Push all updated branches
gt submit --stack
```

### What Happens During Restack

When you modify a branch mid-stack, Graphite:
1. Rebases all child branches onto the updated parent
2. Resolves simple conflicts automatically
3. Prompts for manual resolution if needed
4. Updates PR commits on GitHub

### Resolving Restack Conflicts

```bash
# If conflicts occur during restack:
# 1. Git shows conflict markers
# 2. Resolve manually
vim conflicted-file.js

# 3. Stage resolved files
git add conflicted-file.js

# 4. Continue the restack
gt continue
```

## Advanced Patterns

### Inserting a Branch Mid-Stack

Need to add a branch between existing branches:

```bash
# Currently at branch B, want to insert X between A and B
gt checkout branch-a
gt create --insert -am "feat: new intermediate change"

# Stack is now: main → A → X → B → C
```

### Splitting a Large Branch

Turn one large branch into multiple smaller ones:

```bash
gt checkout large-branch
gt split

# Interactive mode offers three split strategies:
# 1. By commit - each commit becomes a branch
# 2. By hunk - select diff hunks per branch
# 3. By file - group files into branches
```

### Folding Branches Together

Combine a branch into its parent:

```bash
gt checkout child-branch
gt fold

# child-branch commits are added to parent
# child-branch is deleted
# grandchildren are reparented to parent
```

### Reordering Branches

Change the order of branches in a stack:

```bash
gt reorder

# Opens interactive editor:
# 1. feat-api
# 2. feat-ui
# 3. feat-tests
#
# Reorder lines to change stack order
```

### Moving a Branch to Different Parent

```bash
gt checkout branch-to-move
gt move --onto new-parent

# Or interactively:
gt move
```

## Collaboration Patterns

### Working on Someone Else's Stack

```bash
# Fetch teammate's stack
gt get teammate/feature-branch

# Now you have their entire stack locally
gt log  # View the stack

# Make changes
gt checkout their-branch
vim file.js
gt modify -a
gt submit
```

### Preventing Accidental Edits

Lock branches you don't want modified:

```bash
# Freeze a branch
gt checkout sensitive-branch
gt freeze

# Attempts to modify will fail
gt modify -a  # Error: branch is frozen

# Unfreeze when ready
gt unfreeze
```

### Multiple Developers on One Stack

Best practices:
1. Communicate before modifying shared branches
2. Use `gt get` to pull latest changes
3. Use `gt freeze` on branches others are reviewing
4. Submit with `--update-only` to avoid creating duplicate PRs

## Stack Maintenance

### Syncing with Trunk

Regular sync keeps your stack current:

```bash
gt sync

# This command:
# 1. Pulls latest main/master
# 2. Restacks all branches onto updated trunk
# 3. Prompts to delete merged branches
# 4. Updates remote PR state
```

### Handling Merge Conflicts with Trunk

```bash
gt sync

# If conflicts with trunk:
# 1. Resolve conflicts at the bottom branch first
vim conflicted-file.js
git add conflicted-file.js
gt continue

# 2. Conflicts may cascade up - resolve each in turn
```

### Cleaning Up Merged Branches

After PRs are merged:

```bash
gt sync  # Prompts to delete merged branches

# Or manually delete:
gt delete merged-branch
```

## Absorb Workflow

The `absorb` command intelligently distributes staged changes:

```bash
# Scenario: You made changes that should go to different branches

# 1. Stage your changes
git add file1.js file2.js

# 2. Absorb distributes changes to the commits that touched those lines
gt absorb

# file1.js changes go to feat-api (which originally added file1.js)
# file2.js changes go to feat-ui (which originally added file2.js)
```

Absorb is useful for:
- Fixing issues across multiple branches at once
- Adding missing pieces to the correct commits
- Maintaining clean, focused commits

## Common Scenarios

### Scenario: Reviewer Approved Bottom, Wants Changes on Top

```bash
# Stack: A (approved) → B (changes requested) → C

# 1. Fix branch B
gt checkout B
vim files.js
gt modify -a

# 2. C is automatically restacked
# 3. Submit updates
gt submit --stack
```

### Scenario: Need to Ship Bottom Urgently

```bash
# Stack: A (ready) → B (in progress) → C (in progress)

# 1. Merge just A via Graphite web or:
gt checkout A
gt merge

# 2. Sync to update local state
gt sync

# 3. B and C are now based on main (with A's changes)
```

### Scenario: Abandoning Part of Stack

```bash
# Stack: A → B (don't need anymore) → C

# Option 1: Delete B, reparent C
gt checkout B
gt delete
# C is now a child of A

# Option 2: Pop B, keep changes uncommitted
gt checkout B
gt pop
# Changes are now unstaged, branch is gone
```

### Scenario: Converting Existing Branches to Stack

```bash
# Have untracked branches: feat-1, feat-2, feat-3

# Track them in order:
gt checkout feat-1
gt track --parent main

gt checkout feat-2
gt track --parent feat-1

gt checkout feat-3
gt track --parent feat-2

# Now they form a stack
gt log
```
