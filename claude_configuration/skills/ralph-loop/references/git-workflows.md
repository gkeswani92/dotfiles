# Git Workflows Reference

Ralph Loop supports two git workflows and two branch strategies. This reference covers both options.

## Overview

### Git Workflows

| Workflow | Description | Best For |
|----------|-------------|----------|
| `vanilla` (default) | Standard git commands | Teams not using Graphite, simpler setup |
| `graphite` | Graphite CLI for stacked PRs | Teams using Graphite, complex stacks |

### Branch Strategies

| Strategy | Description | Best For |
|----------|-------------|----------|
| `independent` (default) | Each task branches from base_branch | Unrelated changes, parallel review |
| `stacked` | Each task branches from previous task | Sequential changes, dependent PRs |

## Configuration

Set these in your PRD file:

```yaml
name: my-feature
base_branch: main
git_workflow: vanilla     # or "graphite"
branch_strategy: independent  # or "stacked"
```

---

## Vanilla Git Workflow

Works with standard git commands. No additional tools required.

### Independent Branches (vanilla + independent)

Each task creates a branch from `base_branch`:

```
main ─┬─ feature-task-1 (PR #1)
      ├─ feature-task-2 (PR #2)
      └─ feature-task-3 (PR #3)
```

**Commands used by Ralph Loop:**
```bash
# Before each task
git checkout main
git pull origin main

# After implementing
git checkout -b <branch-name>
git add .
git commit -m "message"
git push -u origin <branch-name>
```

**Pros:**
- PRs can be reviewed/merged in any order
- No rebasing needed when base changes
- Simpler conflict resolution

**Cons:**
- Changes in one PR not available to others
- May need to merge sequentially anyway

### Stacked Branches (vanilla + stacked)

Each task branches from the previous task's branch:

```
main ── feature-task-1 ── feature-task-2 ── feature-task-3
          (PR #1)           (PR #2)           (PR #3)
```

**Commands used by Ralph Loop:**
```bash
# Before first task
git checkout main

# Before subsequent tasks
git checkout <previous-task-branch>

# After implementing
git checkout -b <branch-name>
git add .
git commit -m "message"
git push -u origin <branch-name>
```

**After completion:**
- Create PRs manually targeting appropriate base
- Or use `gh pr create --base <previous-branch>`

**Pros:**
- Each task builds on previous changes
- Logical progression visible in PRs

**Cons:**
- Manual rebasing if earlier PRs change
- Must merge PRs in order

---

## Graphite Workflow

Uses Graphite CLI (`gt`) for stacked pull request management.

### Installation

```bash
# macOS
brew install withgraphite/tap/graphite

# npm
npm install -g @withgraphite/graphite-cli

# Initialize in repo
gt init
```

### Stacked Branches (graphite + stacked)

The recommended combination for Graphite users:

```
main ── task-1 ── task-2 ── task-3  (managed stack)
```

**Commands used by Ralph Loop:**
```bash
# Before first task
git checkout main

# Before subsequent tasks
git checkout <previous-task-branch>

# After implementing
git add .
git commit -m "message"
gt create <branch-name>

# After ALL tasks complete
gt submit --stack
```

**Pros:**
- Graphite manages stack relationships
- Automatic rebasing with `gt restack`
- Stack visualization in GitHub

**Cons:**
- Requires Graphite CLI
- Team needs Graphite familiarity

### Essential Graphite Commands

```bash
# Create a stacked branch
gt create <branch-name>

# Submit entire stack as PRs
gt submit --stack

# View stack structure
gt log

# Sync with remote
gt sync

# Rebase entire stack
gt restack

# Navigate stack
gt up      # Move to child branch
gt down    # Move to parent branch
gt top     # Move to top of stack
gt bottom  # Move to trunk
```

---

## Creating PRs After Ralph Loop

### Vanilla Workflow

After all tasks complete, create PRs manually:

```bash
# For independent branches - each PR targets main
gh pr create --base main --head feature-task-1
gh pr create --base main --head feature-task-2
gh pr create --base main --head feature-task-3

# For stacked branches - each PR targets its parent
gh pr create --base main --head feature-task-1
gh pr create --base feature-task-1 --head feature-task-2
gh pr create --base feature-task-2 --head feature-task-3
```

### Graphite Workflow

Ralph Loop automatically runs:

```bash
gt submit --stack
```

This creates/updates all PRs in the stack with proper dependencies.

---

## Handling Conflicts

### Vanilla Git

```bash
# Update base branch
git checkout main
git pull origin main

# Rebase your branch
git checkout feature-task-1
git rebase main

# Resolve conflicts, then
git add .
git rebase --continue

# Force push (if already pushed)
git push --force-with-lease origin feature-task-1
```

### Graphite

```bash
# Sync with remote
gt sync

# If conflicts, resolve then
gt continue

# Or abort
gt abort

# Rebase entire stack
gt restack
```

---

## Which Configuration to Choose?

### Use `vanilla` + `independent` when:
- Team doesn't use Graphite
- Changes are unrelated
- Want simplest setup
- PRs can be merged in any order

### Use `vanilla` + `stacked` when:
- Team doesn't use Graphite
- Changes are sequential/dependent
- Willing to manually manage rebasing

### Use `graphite` + `stacked` when:
- Team uses Graphite
- Changes are sequential/dependent
- Want automated stack management
- Want GitHub stack visualization

### Use `graphite` + `independent` when:
- Team uses Graphite
- Want Graphite's PR management
- But changes are unrelated

---

## Quick Reference: Vanilla Git Commands

```bash
# Branch operations
git checkout -b <branch>      # Create and switch
git checkout <branch>         # Switch to branch
git branch -d <branch>        # Delete local branch
git push -u origin <branch>   # Push and track

# Commit operations
git add .                     # Stage all changes
git commit -m "message"       # Commit
git commit --amend            # Amend last commit

# Remote operations
git pull origin <branch>      # Pull changes
git push origin <branch>      # Push changes
git push --force-with-lease   # Force push safely

# Rebase operations
git rebase <base>             # Rebase onto base
git rebase --continue         # Continue after conflict
git rebase --abort            # Abort rebase
```

---

## Quick Reference: Graphite Commands

```bash
# Stack creation
gt create <branch>            # Create stacked branch
gt submit --stack             # Submit entire stack

# Navigation
gt log                        # View stack
gt up / gt down               # Navigate stack
gt top / gt bottom            # Jump to ends

# Maintenance
gt sync                       # Sync with remote
gt restack                    # Rebase entire stack
gt fix                        # Fix stack issues

# Branch management
gt delete <branch>            # Delete and restack
gt rename <new-name>          # Rename branch
gt track                      # Track untracked branch
```
