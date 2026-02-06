# Tmux Tutorial

A beginner-friendly guide to tmux, configured for this dotfiles repo.

## Table of Contents

1. [Core Concepts](#core-concepts)
2. [Getting Started](#getting-started)
3. [Sessions](#sessions)
4. [Windows](#windows)
5. [Panes](#panes)
6. [Copy Mode](#copy-mode)
7. [Plugins](#plugins)
8. [Claude Code Agent Teams](#claude-code-agent-teams)
9. [Common Workflows](#common-workflows)
10. [Troubleshooting](#troubleshooting)
11. [Cheat Sheet](#cheat-sheet)
12. [Learning Path](#learning-path)

---

## Core Concepts

Tmux organizes your terminal into three layers:

```
Session (project workspace)
  └── Window (like a browser tab)
       └── Pane (split within a window)
```

- **Session** — A named workspace. You can detach from it and reattach later, even after closing your terminal.
- **Window** — A full-screen view inside a session. Switch between them like tabs.
- **Pane** — A split within a window. View multiple things side by side.

### The Prefix Key

Almost every tmux command starts with the **prefix key**. This config uses:

```
Ctrl+a  (hold Ctrl, press a, release both, then press the next key)
```

Written as `Prefix + <key>` throughout this guide. Example: `Prefix + c` means press `Ctrl+a`, release, then press `c`.

> **Note:** The default tmux prefix is `Ctrl+b`. This config changes it to `Ctrl+a` because it's easier to reach.

---

## Getting Started

### First Launch

```bash
# Start a new session
tmux

# Start a named session (recommended)
tmux new -s work
```

You'll see your normal shell with a **status bar** at the top showing:
- Left: session name in purple
- Center: window list
- Right: time, date, hostname

### Install Plugins (First Time)

On first launch, install the configured plugins:

1. Press `Prefix + I` (capital I) — this runs TPM's install
2. Wait for "TMUX environment reloaded"
3. Done! Plugins are now active.

### Verify It Works

```bash
# Check tmux is running
tmux list-sessions

# Check plugins are installed
ls ~/.tmux/plugins/
# Should see: tpm, tmux-sensible, tmux-resurrect, tmux-continuum, tmux-yank
```

---

## Sessions

Sessions are the top-level containers. Use them to separate projects.

### Create & Manage

```bash
# New named session
tmux new -s myproject

# New session from within tmux
Prefix + :new -s another-project
```

### Detach & Reattach

This is tmux's killer feature — your session keeps running in the background.

```bash
# Detach from current session
Prefix + d

# List sessions
tmux ls

# Reattach to a session
tmux attach -t myproject
# or short form
tmux a -t myproject

# Reattach to last session
tmux a
```

### Switch & Kill

| Action | Command |
|--------|---------|
| List sessions (interactive) | `Prefix + s` |
| Rename session | `Prefix + $` |
| Kill session | `tmux kill-session -t name` |
| Kill all sessions | `tmux kill-server` |

---

## Windows

Windows are tabs within a session. The status bar shows all windows.

| Binding | Action |
|---------|--------|
| `Prefix + c` | Create new window |
| `Prefix + n` | Next window |
| `Prefix + p` | Previous window |
| `Prefix + 0-9` | Jump to window by number |
| `Prefix + ,` | Rename current window |
| `Prefix + &` | Close current window |
| `Prefix + w` | List all windows (interactive picker) |

> Windows are numbered starting at 1 (configured in this dotfiles).

---

## Panes

Panes split a window into multiple views. This is where you'll spend most of your time.

### Splitting

| Binding | Action |
|---------|--------|
| `Prefix + \|` | Split horizontally (side by side) |
| `Prefix + -` | Split vertically (top/bottom) |

> These are custom bindings from our config. Default tmux uses `%` and `"`.

### Navigating

| Binding | Action |
|---------|--------|
| `Alt + Arrow` | Move between panes (no prefix needed) |
| `Prefix + h/j/k/l` | Move between panes (vim style) |

### Resizing

| Binding | Action |
|---------|--------|
| `Prefix + H` | Resize left (5 cells) |
| `Prefix + J` | Resize down (5 cells) |
| `Prefix + K` | Resize up (5 cells) |
| `Prefix + L` | Resize right (5 cells) |

Hold the key to keep resizing (repeat is enabled for 600ms).

### Zoom & Close

| Binding | Action |
|---------|--------|
| `Prefix + z` | Zoom pane (toggle fullscreen) |
| `Prefix + x` | Close pane (with confirmation) |

### Synchronize Panes

Run the same command in all panes simultaneously:

```
Prefix + Ctrl+x    # Toggle sync on/off
```

---

## Copy Mode

Tmux has a scroll-back buffer you can search and copy from. This config uses vim-style bindings.

### Enter & Navigate

| Binding | Action |
|---------|--------|
| `Prefix + [` | Enter copy mode |
| `q` | Exit copy mode |
| `j/k` | Scroll down/up |
| `Ctrl+d / Ctrl+u` | Page down/up |
| `g / G` | Top/bottom of buffer |
| `/` | Search forward |
| `?` | Search backward |
| `n / N` | Next/previous search result |

### Select & Copy

| Binding | Action |
|---------|--------|
| `v` | Begin selection |
| `y` | Copy selection to clipboard |
| Mouse drag | Select and copy automatically |

> **tmux-yank** plugin handles clipboard integration across platforms.

---

## Plugins

This config includes these plugins (managed by TPM):

| Plugin | Purpose |
|--------|---------|
| **tmux-sensible** | Better defaults (larger scrollback, UTF-8, etc.) |
| **tmux-resurrect** | Save and restore sessions across tmux restarts |
| **tmux-continuum** | Auto-save sessions every 15 minutes |
| **tmux-yank** | Cross-platform clipboard support |

### Plugin Commands

| Binding | Action |
|---------|--------|
| `Prefix + I` | Install new plugins |
| `Prefix + U` | Update plugins |
| `Prefix + alt+u` | Uninstall removed plugins |

### Resurrect (Save/Restore Sessions)

| Binding | Action |
|---------|--------|
| `Prefix + Ctrl+s` | Save session |
| `Prefix + Ctrl+r` | Restore session |

Continuum auto-saves every 15 minutes and auto-restores on tmux start, so you rarely need to save manually.

---

## Claude Code Agent Teams

Tmux is the recommended way to use Claude Code's agent teams feature, which lets multiple Claude agents work in parallel across split panes.

### Setup

1. Ensure `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS: "1"` is in your Claude Code settings
2. Set tmux as your teammate mode — in Claude Code settings or `~/.claude/settings.json`:

```json
{
  "teammateMode": "tmux"
}
```

### Workflow

1. Start a tmux session:
   ```bash
   tmux new -s claude-work
   ```

2. Launch Claude Code:
   ```bash
   claude
   ```

3. When Claude spawns agent teammates, they'll appear as new tmux panes automatically

4. You can watch agents work in real-time across panes

5. Use `Alt + Arrow` to switch between panes and monitor progress

### Tips

- Use `Prefix + z` to zoom into a specific agent's pane
- Sessions persist — if you detach, agents keep working
- Use `Prefix + s` to manage multiple Claude sessions for different projects

---

## Common Workflows

### Development Session

```bash
# Start a named session
tmux new -s dev

# Split into editor + terminal
Prefix + |        # Split right for terminal
Prefix + h        # Go back to left pane (editor)

# Add a bottom pane for logs
Prefix + -        # Split bottom
```

Result:
```
┌──────────────┬──────────────┐
│              │              │
│   Editor     │   Terminal   │
│              │              │
├──────────────┤              │
│   Logs       │              │
└──────────────┴──────────────┘
```

### Persistent Workspaces

```bash
# Start work
tmux new -s project-x
# ... set up your panes and run processes ...

# End of day — detach
Prefix + d

# Next day — reattach
tmux a -t project-x
# Everything is exactly as you left it
```

### Multiple Projects

```bash
# Project A
tmux new -s frontend

# Detach
Prefix + d

# Project B
tmux new -s backend

# Switch between them
Prefix + s    # Interactive session picker
```

---

## Troubleshooting

### Colors Look Wrong

If colors are off, ensure your terminal emulator supports 256 colors and true color:

```bash
# Test true color support
printf "\x1b[38;2;255;100;0mTRUE COLOR\x1b[0m\n"
```

The config sets `screen-256color` with true color overrides. If you're using iTerm2 or Kitty, this should work out of the box.

### Clipboard Not Working

The tmux-yank plugin handles clipboard automatically. If copy isn't working:

```bash
# macOS — pbcopy should be available
which pbcopy

# Linux — install xclip or xsel
sudo apt install xclip
```

### Prefix Key Not Responding

1. Make sure the config is loaded: `tmux source ~/.tmux.conf`
2. Verify prefix: `tmux show -g prefix` — should show `C-a`
3. If `Ctrl+a` conflicts with your shell (beginning of line), use `Ctrl+a, a` to send it through

### Plugins Not Loading

```bash
# Re-clone TPM
rm -rf ~/.tmux/plugins/tpm
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Reload config and install
tmux source ~/.tmux.conf
# Then press Prefix + I
```

### Mouse Scroll Shows History Instead of Scrollback

Mouse mode is enabled in this config. Scrolling enters copy mode. Press `q` to exit.

---

## Cheat Sheet

### Essentials (You'll Use Daily)

| Binding | Action |
|---------|--------|
| `Prefix + \|` | Split horizontally |
| `Prefix + -` | Split vertically |
| `Alt + Arrow` | Move between panes |
| `Prefix + z` | Zoom pane |
| `Prefix + c` | New window |
| `Prefix + n/p` | Next/prev window |
| `Prefix + d` | Detach session |
| `tmux a` | Reattach |

### Session Management

| Command | Action |
|---------|--------|
| `tmux new -s name` | New named session |
| `tmux ls` | List sessions |
| `tmux a -t name` | Attach to session |
| `tmux kill-session -t name` | Kill session |
| `Prefix + s` | Session picker |
| `Prefix + $` | Rename session |

### Pane Operations

| Binding | Action |
|---------|--------|
| `Prefix + x` | Close pane |
| `Prefix + H/J/K/L` | Resize pane |
| `Prefix + Ctrl+x` | Sync panes toggle |
| `Prefix + [` | Enter copy mode |

### Plugins

| Binding | Action |
|---------|--------|
| `Prefix + I` | Install plugins |
| `Prefix + U` | Update plugins |
| `Prefix + Ctrl+s` | Save session (resurrect) |
| `Prefix + Ctrl+r` | Restore session (resurrect) |

### Config

| Binding | Action |
|---------|--------|
| `Prefix + r` | Reload tmux config |

---

## Learning Path

### Week 1: Basics

- Start and quit tmux (`tmux` / `exit`)
- Learn `Prefix + |` and `Prefix + -` for splits
- Navigate panes with `Alt + Arrow`
- Use `Prefix + z` to zoom
- Detach (`Prefix + d`) and reattach (`tmux a`)

### Week 2: Windows & Sessions

- Create windows (`Prefix + c`) and switch (`Prefix + n/p`)
- Name your sessions (`tmux new -s name`)
- Practice the session picker (`Prefix + s`)
- Let continuum auto-save — verify by killing/restarting tmux

### Week 3: Copy Mode & Clipboard

- Enter copy mode (`Prefix + [`)
- Search scrollback with `/`
- Select with `v`, copy with `y`
- Try mouse selection (drag to copy)

### Week 4: Muscle Memory

- Stop using `Alt + Arrow` — try `Prefix + h/j/k/l`
- Set up a standard dev layout you like
- Use Claude Code agent teams in tmux
- Explore tmux's command mode: `Prefix + :`
