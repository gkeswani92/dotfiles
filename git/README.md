# Git Configuration

This directory contains Git configuration files and custom scripts to enhance the Git experience.

## Contents

- `.gitconfig`: Global Git configuration with aliases, settings, and integrations
- `plugins/`: Git plugins (delta, interactive-rebase)
- `scripts/`: Custom Git scripts for improved workflows

## Custom Git Scripts

### git-cob

Fuzzy branch checkout - uses fzf to interactively select and checkout branches.

Usage:
```bash
git cob
```

### git-credit

Quickly add co-author to commit messages for pair programming.

Usage:
```bash
git credit "Colleague Name" colleague@example.com
```

### git-delete-local-merged

Remove local branches that have been merged into the current branch.

Usage:
```bash
git delete-local-merged
```

### git-undo

Undo the last commit while keeping changes.

Usage:
```bash
git undo
```

### git-unpushed

Display commits that exist locally but haven't been pushed to remote.

Usage:
```bash
git unpushed
```

### git-up

Enhanced version of git pull that shows a better summary of changes.

Usage:
```bash
git up
```

## Git Aliases

The `.gitconfig` file contains several useful aliases:

- `git hist`: Pretty log with graph
- `git graph`: Detailed graph of commits
- `git d`: Show differences
- `git dc`: Show differences in cached files
- `git ds`: Show differences in staged files
- `git log`: Simplified log format
- `git br`: List branches
- `git co`: Checkout
- `git st`: Status
- `git cm`: Commit
- `git push`: Push current branch to origin
- `git pull`: Pull current branch from origin

## Git Plugins

- **git-delta**: Enhanced diff viewer with syntax highlighting and side-by-side view
- **git-interactive-rebase-tool**: Better UI for interactive rebase operations