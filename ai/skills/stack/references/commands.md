# Graphite CLI Complete Command Reference

This document contains the complete reference for all `gt` CLI commands with full options and usage examples.

## Global Flags

Available across all commands:

| Flag | Description |
|------|-------------|
| `--help` | Show help for any command |
| `--cwd <path>` | Run from a specific directory |
| `--debug` | Enable debug output |
| `--interactive` | Force interactive mode |
| `--verify` | Verify branch metadata |
| `--quiet` | Suppress non-essential output |

## Branch Navigation

### gt checkout

Switch to a branch interactively or by name.

```bash
gt checkout           # Interactive branch picker
gt checkout <branch>  # Switch to specific branch
gt co                 # Alias
```

### gt up / gt down

Move up or down within the stack.

```bash
gt up       # Move up one branch
gt up 2     # Move up two branches
gt u        # Alias

gt down     # Move down one branch
gt down 3   # Move down three branches
gt d        # Alias
```

### gt top / gt bottom

Jump to stack endpoints.

```bash
gt top      # Go to top of current stack
gt t        # Alias

gt bottom   # Go to bottom of current stack
gt b        # Alias
```

### gt log

Display stack structure and PR information.

```bash
gt log         # Full branch and PR information
gt log short   # Compact list of branches
gt ls          # Alias for gt log short
```

Options:
- `--json` - Output as JSON
- `--steps <n>` - Limit to n branches

## Branch Creation & Modification

### gt create

Create a new branch stacked on top of the current branch.

```bash
gt create                           # Create empty branch (prompts for name)
gt create <name>                    # Create branch with specific name
gt create -m "message"              # Create with commit message
gt create --all -m "message"        # Stage all files and create
gt create -am "message"             # Short form: stage all + message
gt c -am "feat: new feature"        # Shortest form
```

Options:
| Option | Alias | Description |
|--------|-------|-------------|
| `--all` | `-a` | Stage all changes |
| `--message <msg>` | `-m` | Commit message |
| `--patch` | `-p` | Interactive staging |
| `--insert` | | Insert between current and parent |
| `--no-verify` | | Skip pre-commit hooks |

### gt modify

Amend or add commits to the current branch.

```bash
gt modify                    # Amend with staged changes
gt modify --all              # Stage all and amend
gt modify -a                 # Short form
gt modify --commit           # Add new commit (don't amend)
gt modify -c                 # Short form
gt modify --commit --all     # Stage all, add new commit
gt modify -ca                # Short form
gt modify -cam "message"     # Stage all, new commit with message
gt m -a                      # Shortest amend form
```

Options:
| Option | Alias | Description |
|--------|-------|-------------|
| `--all` | `-a` | Stage all changes |
| `--commit` | `-c` | Create new commit instead of amending |
| `--message <msg>` | `-m` | Commit message (for new commits) |
| `--patch` | `-p` | Interactive staging |
| `--no-edit` | | Keep existing commit message |
| `--no-verify` | | Skip pre-commit hooks |

### gt absorb

Distribute staged changes to relevant commits in the stack.

```bash
git add <files>   # Stage specific changes
gt absorb         # Automatically distribute to correct commits
gt ab             # Alias
```

Graphite analyzes the staged changes and automatically amends them to the commits that originally touched those lines.

### gt split

Split a branch into multiple branches by commit, hunk, or file.

```bash
gt split          # Interactive split mode
gt sp             # Alias
```

Split modes:
- **By commit** - Each commit becomes a separate branch
- **By hunk** - Split by individual diff hunks
- **By file** - Split by file changes

### gt squash

Combine commits in the current branch.

```bash
gt squash         # Squash all commits into one
gt sq             # Alias
gt squash -n 3    # Squash last 3 commits
```

Options:
- `-n <count>` - Number of commits to squash
- `--message <msg>` - New commit message

## Stack Reorganization

### gt move

Change a branch's parent in the stack.

```bash
gt move                     # Interactive parent selection
gt move --onto <branch>     # Move onto specific branch
gt move --insert            # Insert between branches
```

### gt fold

Merge current branch into its parent.

```bash
gt fold           # Fold current branch into parent
```

Combines the current branch's changes into the parent branch and removes the current branch.

### gt reorder

Rearrange branches within the stack.

```bash
gt reorder        # Interactive reorder mode
```

Opens an interactive editor to reorder branches in the stack.

### gt delete

Remove branches from the stack.

```bash
gt delete                    # Delete current branch
gt delete <branch>           # Delete specific branch
gt delete --force            # Force delete without confirmation
```

Children of deleted branches are restacked onto the deleted branch's parent.

### gt pop

Remove branch but preserve changes as uncommitted.

```bash
gt pop            # Remove branch, keep changes unstaged
```

### gt restack

Ensure each branch has its parent in Git history.

```bash
gt restack        # Restack current branch and descendants
gt restack --all  # Restack all tracked branches
```

### gt rename

Rename the current branch.

```bash
gt rename <new-name>    # Rename current branch
```

## Remote Synchronization

### gt sync

Sync all branches with remote, cleanup merged branches.

```bash
gt sync           # Full sync operation
```

This command:
1. Pulls latest changes into trunk (main/master)
2. Restacks all open PRs onto updated trunk
3. Prompts to delete locally merged branches
4. Updates PR metadata

Options:
- `--no-delete` - Skip merged branch cleanup prompt
- `--no-restack` - Skip restacking
- `--force` - Force sync even with conflicts

### gt submit

Push branches and create/update PRs.

```bash
gt submit                   # Push current + downstack branches
gt submit --stack           # Push entire stack
gt ss                       # Alias for --stack
gt submit --update-only     # Update existing PRs only
gt submit -u                # Short form
gt ss -u                    # Update entire stack
```

Options:
| Option | Alias | Description |
|--------|-------|-------------|
| `--stack` | `-s` | Submit entire stack |
| `--update-only` | `-u` | Only update existing PRs |
| `--draft` | | Create PRs as drafts |
| `--publish` | | Convert drafts to ready |
| `--no-verify` | | Skip pre-push hooks |
| `--reviewers <users>` | `-r` | Request reviewers |
| `--no-edit` | | Skip PR description editing |

### gt get

Fetch a branch or stack from remote.

```bash
gt get <branch>             # Fetch specific branch
gt get <user>/<branch>      # Fetch from teammate's fork
```

Used for collaboration - pulls a teammate's stack locally.

## Branch Tracking

### gt track

Start tracking an existing Git branch with Graphite.

```bash
gt track                    # Track current branch
gt track <branch>           # Track specific branch
gt track --parent <branch>  # Specify parent branch
gt tr                       # Alias
```

### gt untrack

Stop tracking a branch (removes from Graphite, keeps Git branch).

```bash
gt untrack                  # Untrack current branch
gt untrack <branch>         # Untrack specific branch
gt utr                      # Alias
```

### gt freeze / gt unfreeze

Lock branches to prevent accidental modifications.

```bash
gt freeze         # Lock current branch
gt unfreeze       # Unlock current branch
```

Frozen branches cannot be modified by `gt modify` or `gt restack`.

## PR Operations

### gt pr

Open PR pages in browser.

```bash
gt pr             # Open current branch's PR
gt pr --stack     # Open all PRs in stack
```

### gt merge

Merge PRs via Graphite.

```bash
gt merge          # Merge current PR
gt merge --stack  # Merge entire stack (from top)
```

## Recovery

### gt undo

Reverse the most recent Graphite operation.

```bash
gt undo           # Undo last operation
```

Supports undoing: create, modify, delete, fold, split, squash, reorder, move, restack.

### gt continue

Continue after resolving conflicts.

```bash
gt continue       # Continue interrupted operation
```

Use after manually resolving merge conflicts during restack or other operations.

## Information

### gt info

Display information about current branch.

```bash
gt info           # Show branch metadata
gt info --json    # Output as JSON
```

### gt branch

List and manage branches.

```bash
gt branch         # List all tracked branches
gt branch -a      # Include untracked branches
```

## Configuration

### gt config

Configure CLI settings.

```bash
gt config         # Interactive configuration
```

### gt auth

Authenticate with GitHub.

```bash
gt auth --token <token>     # Set GitHub token
gt auth                     # Interactive auth
```

### gt completion

Set up shell completion.

```bash
gt completion >> ~/.zshrc       # Add zsh completion
gt completion >> ~/.bashrc      # Add bash completion
gt fish >> ~/.config/fish/completions/gt.fish  # Fish shell
```

## MCP Server

### gt mcp

Start the Model Context Protocol server for AI integration.

```bash
gt mcp            # Start MCP server
```

Used by AI tools (Claude Code, Cursor) to interact with Graphite programmatically.

## Git vs Gt Command Comparison

Understanding how `gt` commands map to traditional Git workflows:

### Creating Branches/Commits

**Git (traditional):**
```bash
git branch task_search && git checkout task_search
git add --all && git commit --message 'add index for searching tasks'
```

**Graphite:**
```bash
gt create --all --message 'add index for searching tasks'
# or shorter:
gt c -am 'add index for searching tasks'
```

Key insight: Use `gt create` every time you would `git commit` when checkpointing work.

### Fixup/Amendment Commits

**Git (traditional):**
```bash
git commit --fixup=<commit hash>
git rebase --interactive --autosquash=<commit hash>~1
```

**Graphite:**
```bash
gt checkout 'branch-name'
gt modify --all
gt submit --stack
```

### Syncing with Remote

**Git (traditional):**
```bash
git checkout main
git pull
git checkout <my-branch>
git merge main  # or git rebase main
```

**Graphite:**
```bash
gt sync
gt checkout <my-branch>
gt restack
```

The key distinction: `gt restack` automatically manages dependency relationships across stacked branches.

### Rebasing a Stack

**Git (traditional):**
```bash
# Must manually rebase each branch in order
git checkout branch1 && git rebase main
git checkout branch2 && git rebase branch1
git checkout branch3 && git rebase branch2
# ... repeat for each branch
```

**Graphite:**
```bash
gt sync  # Handles entire stack automatically
```

## Installation

### Homebrew (Recommended)

```bash
brew install withgraphite/tap/graphite
gt --version
```

### NPM

```bash
npm install -g @withgraphite/graphite-cli@stable
gt --version
```

Node.js v22 recommended; current versions supported.

### Windows

Install via npm or use Homebrew/npm through WSL (Windows Subsystem for Linux).

### Linux (Ubuntu)

Requires Git 2.38.0+. Update Git first:
```bash
sudo add-apt-repository ppa:git-core/ppa
sudo apt update
sudo apt install git
```

### Beta Releases

```bash
# Homebrew
brew install withgraphite/tap/graphite-beta

# NPM
npm install -g @withgraphite/graphite-cli@beta
```

## Authentication

1. Visit https://app.graphite.com/activate
2. Sign in with GitHub
3. Copy the pre-filled command: `gt auth --token abcdef123456`
4. Run in terminal

Token saves to `~/.graphite_user_config`.

## Environment Variables

| Variable | Description |
|----------|-------------|
| `GRAPHITE_IGNORE_GIT_VERSION=1` | Override Git version check (not recommended) |
| `GT_EDITOR` | Override editor for interactive operations |
| `GT_PAGER` | Override pager for long output |
| `GRAPHITE_PROFILE` | Select auth profile for multi-account |
| `GRAPHITE_DISABLE_TELEMETRY` | Disable anonymous usage telemetry |
