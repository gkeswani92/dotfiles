# Productivity Tools Tutorial

Quick reference for all tools installed via dotfiles.

---

## Table of Contents

1. [fzf - Fuzzy Finder](#fzf---fuzzy-finder)
2. [eza - Modern ls](#eza---modern-ls)
3. [zoxide - Smart cd](#zoxide---smart-cd)
4. [zellij - Terminal Multiplexer](#zellij---terminal-multiplexer)
5. [fd - Fast File Search](#fd---fast-file-search)
6. [lazygit - Git TUI Client](#lazygit---git-tui-client)
7. [btop - System Monitor](#btop---system-monitor)
8. [dua - Disk Usage Analyzer](#dua---disk-usage-analyzer)
9. [git-delta - Better Diffs](#git-delta---better-diffs)
10. [git-absorb - Auto Fixup Commits](#git-absorb---auto-fixup-commits)

---

## fzf - Fuzzy Finder

Interactive fuzzy search for files, history, and more.

### Key Bindings (in shell)

| Binding | Action |
|---------|--------|
| `ctrl+r` | Search command history |
| `ctrl+t` | Search files in current directory |
| `alt+c` | cd into selected directory |

### Key Bindings (in fzf)

| Key | Action |
|-----|--------|
| `ctrl+j/k` or `up/down` | Navigate results |
| `enter` | Select |
| `tab` | Multi-select |
| `ctrl+c` or `esc` | Cancel |

### Common Usage

```bash
# Pipe anything to fzf
cat file.txt | fzf              # Search lines
ps aux | fzf                    # Search processes
git branch | fzf                # Search branches

# Preview files
fzf --preview 'cat {}'          # Preview file contents
fzf --preview 'head -50 {}'     # Preview first 50 lines

# Use with other commands
vim $(fzf)                      # Open selected file in vim
cd $(find . -type d | fzf)      # cd to selected directory
git checkout $(git branch | fzf) # Checkout selected branch
```

---

## eza - Modern ls

Replaces `ls` with colors, icons, and git integration.

### Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `ls` | `eza --icons --group-directories-first` | Basic listing |
| `ll` | `eza --icons -la` | Long listing |
| `la` | `eza --icons -a` | Show hidden |
| `lt` | `eza --icons -la --sort=modified` | Sort by time |
| `tree` | `eza --icons --tree` | Tree view |
| `lsd` | `eza --icons -D` | Directories only |
| `lsf` | `eza --icons -f` | Files only |
| `lsh` | `eza --icons -la --sort=size --reverse` | Sort by size |

### Common Usage

```bash
# Basic
ls                              # List with icons
ll                              # Long format with details
la                              # Include hidden files

# Sorting
lt                              # Sort by modification time
lsh                             # Sort by size (largest first)

# Tree view
tree                            # Full tree
eza --tree --level=2            # Limit depth

# Git integration (automatic)
ll                              # Shows git status per file
```

---

## zoxide - Smart cd

Tracks your most-used directories and jumps to them.

### Commands

| Command | Description |
|---------|-------------|
| `z <query>` | Jump to best match |
| `zi <query>` | Interactive selection with fzf |
| `z -` | Go to previous directory |
| `zoxide query <query>` | Show what z would match |

### Common Usage

```bash
# Jump to frequently used directories
z dotfiles                      # Jump to ~/dotfiles
z proj                          # Jump to ~/projects (partial match)
z doc down                      # Jump to ~/Documents/Downloads

# Interactive mode
zi                              # Browse all tracked directories
zi proj                         # Browse matches for "proj"

# How it works
# - Tracks directories you visit with cd
# - Ranks by "frecency" (frequency + recency)
# - Partial matches work (z dot → ~/dotfiles)
```

---

## zellij - Terminal Multiplexer

Modern terminal multiplexer (like tmux but friendlier).

### Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `zj` | `zellij` | Start zellij |
| `zjl` | `zellij --layout` | Start with layout |
| `zjls` | `zellij list-sessions` | List sessions |
| `zja` | `zellij attach` | Attach to session |

### Key Bindings (default)

All commands start with `Ctrl+p` (leader key).

| Binding | Action |
|---------|--------|
| `ctrl+p` then `n` | New pane (right) |
| `ctrl+p` then `d` | New pane (down) |
| `ctrl+p` then `x` | Close pane |
| `ctrl+p` then `arrow` | Move between panes |
| `ctrl+p` then `f` | Toggle fullscreen |
| `ctrl+p` then `w` | Toggle floating |
| `ctrl+p` then `e` | Scroll mode |
| `ctrl+p` then `s` | Search |
| `ctrl+p` then `c` | New tab |
| `ctrl+p` then `1-9` | Switch to tab |
| `ctrl+p` then `q` | Quit |
| `ctrl+p` then `o` | Session manager |

### Session Management

```bash
# Start new session
zellij                          # Anonymous session
zellij -s myproject             # Named session

# List and attach
zjls                            # List all sessions
zja myproject                   # Attach to "myproject"
zellij attach -c myproject      # Create or attach

# Layouts
zjl dev                         # Start with "dev" layout
```

---

## fd - Fast File Search

Replaces `find`. Ignores .git and node_modules by default.

### Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `f` | `fd` | Basic search |
| `fh` | `fd --hidden` | Include hidden files |
| `fa` | `fd --hidden --no-ignore` | Include everything |

### Common Usage

```bash
# Find files by name
fd readme                       # Files containing "readme"
fd -e js                        # All .js files
fd -e ts src/                   # .ts files in src/ directory

# Find by type
fd -t f                         # Files only
fd -t d                         # Directories only
fd -t l                         # Symlinks only

# Execute commands on results
fd -e jpg -x convert {} {.}.png # Convert all jpg to png
fd -e test.ts -x npm test {}    # Run tests on test files

# Advanced
fd '^test.*\.js$'               # Regex pattern
fd -E node_modules              # Exclude directory
fd -s README                    # Case-sensitive search
fd --changed-within 1d          # Modified in last day
```

---

## lazygit - Git TUI Client

Visual git interface for staging, committing, branching.

### Alias

| Alias | Command | Description |
|-------|---------|-------------|
| `lg` | `lazygit` | Open lazygit |

### Key Bindings

#### Global

| Key | Action |
|-----|--------|
| `?` | Show help |
| `q` | Quit |
| `h/l` | Navigate panels left/right |
| `j/k` | Navigate items up/down |
| `enter` | Focus/select |
| `esc` | Go back/cancel |

#### Files Panel (1)

| Key | Action |
|-----|--------|
| `space` | Stage/unstage file |
| `a` | Stage all |
| `d` | Discard changes |
| `e` | Edit file |
| `o` | Open file |
| `i` | Add to .gitignore |

#### Staging View (within file)

| Key | Action |
|-----|--------|
| `enter` | Enter file to stage hunks |
| `space` | Stage/unstage hunk |
| `v` | Select lines (visual mode) |
| `a` | Stage/unstage all hunks |

#### Commits Panel (4)

| Key | Action |
|-----|--------|
| `c` | Commit |
| `A` | Amend last commit |
| `p` | Pick commit (rebase) |
| `r` | Reword commit |
| `s` | Squash commit |
| `f` | Fixup commit |
| `d` | Drop commit |
| `ctrl+j/k` | Move commit up/down |

#### Branches Panel (3)

| Key | Action |
|-----|--------|
| `space` | Checkout branch |
| `n` | New branch |
| `d` | Delete branch |
| `M` | Merge into current |
| `r` | Rebase onto current |
| `R` | Rename branch |

#### Stash Panel

| Key | Action |
|-----|--------|
| `s` | Stash changes |
| `space` | Apply stash |
| `g` | Pop stash |
| `d` | Drop stash |

### Common Workflows

**Interactive rebase:**
1. Go to Commits panel (`4`)
2. Navigate to commit to edit
3. Press `e` to start interactive rebase
4. Use `s` (squash), `f` (fixup), `r` (reword)
5. Continue or abort with options shown

**Stage specific lines:**
1. Navigate to file in Files panel
2. Press `enter` to see diff
3. Use `v` to select lines
4. Press `space` to stage selection

---

## btop - System Monitor

Replaces `top` and `htop`. Beautiful graphs and mouse support.

### Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `top` | `btop` | Open btop |
| `htop` | `btop` | Open btop |

### Key Bindings

#### Navigation

| Key | Action |
|-----|--------|
| `up/down` | Select process |
| `left/right` | Change sorting |
| `enter` | Show process details |
| `tab` | Cycle panels |

#### Process Management

| Key | Action |
|-----|--------|
| `k` | Kill process (SIGTERM) |
| `K` | Kill process (SIGKILL) |
| `t` | Toggle tree view |
| `r` | Reverse sort order |
| `f` | Filter processes |
| `/` | Search processes |

#### Display

| Key | Action |
|-----|--------|
| `m` | Toggle memory display |
| `n` | Toggle network display |
| `d` | Toggle disk display |
| `g` | Toggle GPU display |
| `c` | Toggle CPU cores |
| `1-4` | Preset layouts |

#### General

| Key | Action |
|-----|--------|
| `h` or `?` | Help |
| `q` | Quit |
| `esc` | Back/cancel |
| `o` | Options menu |

---

## dua - Disk Usage Analyzer

Replaces `du` and `ncdu`. Interactive mode with deletion support.

### Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `dui` | `dua interactive` | Interactive mode |
| `dus` | `dua --apparent-size` | Show apparent size |

### Interactive Mode Key Bindings

#### Navigation

| Key | Action |
|-----|--------|
| `j/k` or `up/down` | Navigate |
| `enter` | Enter directory |
| `u` or `backspace` | Go up/parent |
| `o` | Open in system viewer |
| `gg` | Go to top |
| `G` | Go to bottom |

#### Deletion

| Key | Action |
|-----|--------|
| `d` | Mark for deletion |
| `x` | Delete marked items |
| `esc` | Clear marks |

#### Display

| Key | Action |
|-----|--------|
| `s` | Toggle size format |
| `c` | Toggle item count |
| `r` | Refresh |
| `?` | Help |
| `q` | Quit |

### Command Line Usage

```bash
# Basic usage
dua                             # Current directory
dua /path/to/dir                # Specific directory
dua -t 10                       # Top 10 largest

# Interactive mode
dua i                           # Short for interactive
dua interactive /path           # Interactive in specific dir

# Multiple directories
dua ~/Downloads ~/Documents     # Compare directories
```

---

## git-delta - Better Diffs

Syntax-highlighted diffs with line numbers. Configured automatically via `.gitconfig`.

### Features

- Syntax highlighting for diffs
- Line numbers
- Side-by-side view option
- Word-level diff highlighting

### Usage

Delta is automatic - it enhances all git commands that show diffs:

```bash
git diff                        # Enhanced diff
git show                        # Enhanced commit view
git log -p                      # Enhanced log with patches
git blame                       # Enhanced blame
```

### Customization

Add to `.gitconfig` for side-by-side view:
```ini
[delta]
    side-by-side = true
```

---

## git-absorb - Auto Fixup Commits

Automatically creates fixup commits for staged changes.

### Usage

```bash
# Stage your fixes
git add -p                      # Stage specific changes

# Let git-absorb figure out which commits to fix
git absorb                      # Creates fixup! commits

# Rebase to apply the fixups
git rebase -i --autosquash main
```

### How It Works

1. You make changes to fix something in a previous commit
2. Stage those changes
3. Run `git absorb`
4. It analyzes which commits introduced the lines you changed
5. Creates `fixup!` commits targeting those commits
6. Run interactive rebase with `--autosquash` to apply

### Example Workflow

```bash
# Realize you need to fix something in a commit from 5 commits ago
vim src/file.js                 # Make the fix
git add src/file.js             # Stage it
git absorb                      # Creates fixup! commit automatically
git rebase -i --autosquash HEAD~10  # Apply the fixup
```

---

## Quick Reference Card

| Task | Command |
|------|---------|
| **Search** | |
| Find files by name | `fd readme` or `f readme` |
| Find .ts files | `fd -e ts` |
| Fuzzy search history | `ctrl+r` |
| Fuzzy search files | `ctrl+t` |
| **Navigation** | |
| Jump to directory | `z <partial-name>` |
| Interactive jump | `zi` |
| List files | `ll` (long) or `ls` |
| Tree view | `tree` |
| **Git** | |
| Open git TUI | `lg` |
| Stage specific lines | `lg` → file → `enter` → `v` → select → `space` |
| Auto-create fixup | `git add -p && git absorb` |
| **System** | |
| Monitor system | `btop` or `top` |
| Kill process | `btop` → select → `k` |
| Find large files | `dui` |
| Delete large files | `dui` → `d` to mark → `x` to delete |
| **Terminal** | |
| New zellij pane | `ctrl+p` then `n` |
| Split down | `ctrl+p` then `d` |
| Switch pane | `ctrl+p` then arrow |
