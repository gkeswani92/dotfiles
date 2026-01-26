# Git Configuration Tutorial

This guide covers all the custom git scripts, aliases, and tools configured in this dotfiles repo.

## Table of Contents

1. [Custom Git Scripts](#custom-git-scripts)
2. [Git Aliases](#git-aliases)
3. [Delta (Better Diffs)](#delta-better-diffs)
4. [Interactive Rebase Tool](#interactive-rebase-tool)
5. [Performance Optimizations](#performance-optimizations)

---

## Custom Git Scripts

These scripts are installed to `/usr/local/bin/` and can be run as `git <script-name>`.

### git cob — Checkout Branch with Fuzzy Search

Interactively checkout a branch using fzf. Shows branch name, last commit date, author, and commit message.

```bash
git cob
```

**What you'll see:**
```
  feature/api-v2 | (2 days ago) John Doe - Add API endpoints
  fix/login-bug  | (5 days ago) Jane Smith - Fix OAuth redirect
> main           | (1 week ago) Bot - Merge pull request #123
```

Use arrow keys to navigate, type to filter, Enter to checkout.

---

### git recent — Show Recently Checked Out Branches

See branches you've worked on recently (from git reflog).

```bash
# List last 15 branches
git recent

# Show last 10 branches
git recent -n 10

# Interactively checkout a recent branch (with fzf)
git recent -c
```

**Output:**
```
Recent branches:

 1. feature/new-dashboard
 2. fix/memory-leak
 3. main
 4. feature/api-refactor
 5. hotfix/security-patch
```

**Pro tip:** Use `git recent -c` when you can't remember the exact branch name you were on yesterday.

---

### git fixup — Create Fixup Commits

Amend a previous commit without interactive rebase hassle.

```bash
# Interactive: select commit with fzf
git fixup

# Fixup a specific commit
git fixup abc123

# Fixup AND immediately squash it
git fixup abc123 --squash
```

**Workflow example:**
```bash
# You made a typo in a commit 3 commits ago
git log --oneline -5
# abc123 Add user authentication
# def456 Fix tests
# ghi789 Update docs

# Stage your fix
git add src/auth.js

# Create fixup commit for abc123
git fixup abc123

# Later, when ready to push, squash it:
git rebase -i --autosquash main
```

---

### git undo — Undo Last Commit (Keep Changes)

Soft reset the last commit. Your changes stay staged.

```bash
git undo
```

**Before:**
```
abc123 (HEAD) Oops wrong commit message
def456 Previous commit
```

**After:**
```
def456 (HEAD) Previous commit
# Your changes from abc123 are now staged
```

**Use cases:**
- Wrong commit message
- Forgot to add a file
- Want to split into multiple commits

---

### git unpushed — Show Unpushed Changes

See the diff of commits you haven't pushed yet.

```bash
git unpushed
```

Shows the full diff between your local branch and origin. Useful before pushing to review what you're about to share.

---

### git up — Pull with Change Summary

Like `git pull` but shows what changed.

```bash
git up
```

**Output:**
```
Updating abc123..def456
Fast-forward
Log:
  def456 Add new feature
  abc123 Fix bug in parser
```

Shows a concise log of new commits pulled down.

---

### git credit — Change Commit Author

Quickly change the author of the last commit (for pair programming).

```bash
git credit "Jane Doe" jane@example.com
```

This amends the last commit with the new author while keeping the same message and changes.

---

### git delete-local-merged — Clean Up Merged Branches

Delete all local branches that have been merged into HEAD.

```bash
git delete-local-merged
```

**What it does:**
- Finds branches merged into current branch
- Excludes `master` and current branch
- Deletes them locally

Run this periodically to keep your branch list clean.

---

## Git Aliases

Quick shortcuts defined in `.gitconfig`. Use these daily.

### Viewing Changes

| Alias | Command | Description |
|-------|---------|-------------|
| `git d` | `git diff` | Show unstaged changes |
| `git dc` | `git diff --cached` | Show staged changes |
| `git ds` | `git diff --staged` | Same as above |
| `git staged` | `git diff --cached` | Show what will be committed |
| `git unstaged` | `git diff` | Show what won't be committed |

### Logs

| Alias | Command | Description |
|-------|---------|-------------|
| `git l` | `git log` | Standard log |
| `git log` | `git log --oneline` | Compact one-line log |
| `git latest` | `git log --oneline -1` | Show only the last commit |
| `git hist` | (pretty format) | Colored graph with author info |
| `git graph` | (pretty format) | Visual branch graph (last 9 commits) |
| `git current` | (pretty format) | Show current commit info |

**Try these:**
```bash
# Beautiful commit history
git hist

# Visual branch graph
git graph

# What's the current commit?
git current
```

### Navigation

| Alias | Command | Description |
|-------|---------|-------------|
| `git co` | `git checkout` | Switch branches |
| `git com` | `git checkout main` | Jump to main branch |
| `git br` | `git branch` | List/manage branches |
| `git st` | `git status` | Show working tree status |

### Committing

| Alias | Command | Description |
|-------|---------|-------------|
| `git cm` | `git commit` | Create a commit |
| `git cp` | `git cherry-pick` | Cherry-pick a commit |

### Syncing

| Alias | Command | Description |
|-------|---------|-------------|
| `git fo` | `git fetch origin` | Fetch from origin |
| `git pull` | Pull current branch | Pulls your branch from origin |
| `git push` | Push current branch | Pushes your branch to origin |
| `git pushf` | Force push (safe) | Uses `--force-with-lease` |

### Stashing

| Alias | Command | Description |
|-------|---------|-------------|
| `git gs` | `git stash` | Stash changes |
| `git unstash` | `git stash pop` | Pop stashed changes |

### Utility

| Alias | Command | Description |
|-------|---------|-------------|
| `git branch-name` | Get current branch | Outputs just the branch name |

---

## Delta (Better Diffs)

Delta replaces the default git diff output with syntax-highlighted, side-by-side diffs.

### Features Enabled

- **Side-by-side view**: See old and new code next to each other
- **Line numbers**: Easy to reference specific lines
- **Syntax highlighting**: Nord theme for code coloring
- **Navigation**: Press `n`/`N` to jump between diff sections

### Using Delta

Delta is automatically used for:
- `git diff`
- `git log -p`
- `git show`
- `git reflog`

### Navigation Keys (in delta pager)

| Key | Action |
|-----|--------|
| `n` | Next diff section |
| `N` | Previous diff section |
| `q` | Quit |
| `/` | Search |
| `g` | Go to top |
| `G` | Go to bottom |

### Example Output

```
─────────────────────────────────────────────────────────────────────
src/auth.js
─────────────────────────────────────────────────────────────────────
│  1 │  1 │ function login(user, pass) {
│  2 │    │-  return oldAuth(user, pass);
│    │  2 │+  return newAuth(user, pass, { secure: true });
│  3 │  3 │ }
```

---

## Interactive Rebase Tool

A better UI for `git rebase -i`. Instead of editing text, you get an interactive TUI.

### How to Use

```bash
git rebase -i HEAD~5
```

This opens the interactive-rebase-tool instead of vim.

### Key Bindings

| Key | Action |
|-----|--------|
| `j/k` | Move down/up |
| `p` | Pick |
| `r` | Reword |
| `e` | Edit |
| `s` | Squash |
| `f` | Fixup |
| `d` | Drop |
| `J/K` | Move commit down/up |
| `q` | Abort |
| `w` | Write and execute |

### Common Workflows

**Squash last 3 commits:**
```bash
git rebase -i HEAD~3
# Mark commits 2 and 3 with 's' (squash)
# Press 'w' to execute
```

**Reorder commits:**
```bash
git rebase -i HEAD~5
# Use J/K to move commits up/down
# Press 'w' to execute
```

**Edit a commit message:**
```bash
git rebase -i HEAD~3
# Press 'r' on the commit to reword
# Press 'w' to execute
```

---

## Performance Optimizations

Your config includes several performance boosts:

### Commit Graph

```ini
[core]
  commitGraph = true
[gc]
  writeCommitGraph = true
```

Speeds up `git log`, `git merge-base`, and other graph-walking operations.

### Protocol v2

```ini
[protocol]
  version = 2
```

Faster fetches and clones with Git protocol version 2.

### Patience Diff Algorithm

```ini
[diff]
  algorithm = patience
```

Produces more readable diffs, especially for code with moved blocks.

### Pull with Rebase

```ini
[pull]
  rebase = true
```

Automatically rebases instead of creating merge commits when pulling.

---

## Quick Reference Card

```
DAILY WORKFLOW
─────────────────────────────────────
git st                  # Check status
git d                   # See changes
git dc                  # See staged changes
git cob                 # Switch branch (fuzzy)
git recent -c           # Switch to recent branch
git com                 # Go to main
git push                # Push current branch
git pushf               # Force push (safe)

HISTORY & LOGS
─────────────────────────────────────
git hist                # Pretty log
git graph               # Branch graph
git latest              # Last commit
git unpushed            # What haven't I pushed?

FIXING MISTAKES
─────────────────────────────────────
git undo                # Undo last commit (keep changes)
git fixup <commit>      # Amend old commit
git fixup               # Interactive fixup

CLEANUP
─────────────────────────────────────
git delete-local-merged # Remove merged branches
git up                  # Pull with summary

PAIR PROGRAMMING
─────────────────────────────────────
git credit "Name" email # Change commit author
```

---

## Troubleshooting

### "git cob" shows no branches
Make sure fzf is installed: `brew install fzf`

### Delta not showing colors
Check your terminal supports 256 colors. Try: `echo $TERM`

### Interactive rebase opens vim instead of TUI
Ensure interactive-rebase-tool is installed: `brew install git-interactive-rebase-tool`

### "git push" says "no upstream branch"
Your config uses `push.default = current`, so just run `git push -u origin HEAD` once.
