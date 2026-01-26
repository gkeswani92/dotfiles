# Neovim + LazyVim Tutorial

A comprehensive guide to getting started with your Neovim configuration.

## Table of Contents

1. [First Launch](#first-launch)
2. [Basic Navigation](#basic-navigation)
3. [Essential Keybindings](#essential-keybindings)
4. [File Management](#file-management)
5. [Code Editing](#code-editing)
6. [Search & Find](#search--find)
7. [Git Integration](#git-integration)
8. [LSP Features](#lsp-features)
9. [Customization](#customization)
10. [Cheat Sheet](#cheat-sheet)

---

## First Launch

### Initial Setup

```bash
# Launch Neovim
nvim
```

On first launch:
1. **lazy.nvim** will automatically install itself
2. All plugins will be downloaded (~30-60 seconds)
3. Treesitter parsers will compile
4. You'll see the dashboard when ready

### Check Health

After installation, run this to verify everything works:

```
:checkhealth
```

Look for any red errors. Common fixes:
- Missing language servers: `:Mason` to install
- Missing formatters: `brew install stylua prettier`

---

## Basic Navigation

### Modes

| Mode | How to Enter | Purpose |
|------|--------------|---------|
| Normal | `Esc` or `jk` | Navigate, run commands |
| Insert | `i`, `a`, `o` | Type text |
| Visual | `v`, `V`, `Ctrl+v` | Select text |
| Command | `:` | Run ex commands |

### Movement

| Key | Action |
|-----|--------|
| `h j k l` | Left, Down, Up, Right |
| `w` | Next word |
| `b` | Previous word |
| `0` | Start of line |
| `$` | End of line |
| `gg` | Top of file |
| `G` | Bottom of file |
| `Ctrl+d` | Page down (centered) |
| `Ctrl+u` | Page up (centered) |
| `{` / `}` | Previous/next paragraph |
| `%` | Jump to matching bracket |

### Quick Escape

```
jk  or  kj  →  Escape to Normal mode
```

No need to reach for the Escape key!

---

## Essential Keybindings

The **leader key** is `Space`. Press it to see all available commands via which-key.

### Most Used

| Keybinding | Action |
|------------|--------|
| `Space` | Open command palette (which-key) |
| `Space Space` | Find files |
| `Space /` | Search in project |
| `Space ,` | Switch buffer |
| `Space e` | File explorer |
| `Ctrl+s` | Save file |
| `Space q` | Quit |
| `Space w` | Save |

### Windows & Splits

| Keybinding | Action |
|------------|--------|
| `Ctrl+h/j/k/l` | Navigate between splits |
| `Ctrl+arrows` | Resize splits |
| `Space -` | Split horizontal |
| `Space \|` | Split vertical |

### Buffers (like tabs)

| Keybinding | Action |
|------------|--------|
| `Shift+h` | Previous buffer |
| `Shift+l` | Next buffer |
| `Space bd` | Close buffer |
| `Space ,` | Buffer picker |

---

## File Management

### File Explorer (mini.files)

```
Space e  →  Open file explorer
```

In the explorer:
| Key | Action |
|-----|--------|
| `j/k` | Navigate |
| `Enter` | Open file/folder |
| `h` | Go up a directory |
| `l` | Enter directory |
| `-` | Go to parent |
| `a` | Create file/folder |
| `d` | Delete |
| `r` | Rename |
| `q` | Close |

### Quick File Access

| Keybinding | Action |
|------------|--------|
| `Space ff` | Find files (fuzzy) |
| `Space fr` | Recent files |
| `Space fb` | Browse buffers |

---

## Code Editing

### Text Manipulation

| Keybinding | Action |
|------------|--------|
| `dd` | Delete line |
| `yy` | Copy line |
| `p` | Paste below |
| `P` | Paste above |
| `u` | Undo |
| `Ctrl+r` | Redo |
| `>>` | Indent |
| `<<` | Unindent |
| `gcc` | Toggle comment (line) |
| `gc` (visual) | Toggle comment (selection) |

### Surround (change quotes, brackets)

| Command | Action |
|---------|--------|
| `cs"'` | Change `"text"` to `'text'` |
| `cs'<p>` | Change `'text'` to `<p>text</p>` |
| `ds"` | Delete surrounding `"` |
| `ysiw"` | Surround word with `"` |

### Multi-cursor Alternative

Visual block mode:
```
Ctrl+v  →  Select column
I       →  Insert at all lines
Esc     →  Apply to all
```

### Move Lines

In visual mode:
| Key | Action |
|-----|--------|
| `J` | Move selection down |
| `K` | Move selection up |

---

## Search & Find

### Telescope (Fuzzy Finder)

| Keybinding | Action |
|------------|--------|
| `Space ff` | Find files |
| `Space fg` | Live grep (search content) |
| `Space fb` | Find buffers |
| `Space fh` | Help tags |
| `Space fr` | Recent files |
| `Space fc` | Git commits |
| `Space fs` | Git status |

**In Telescope:**
| Key | Action |
|-----|--------|
| `Ctrl+j/k` | Navigate results |
| `Enter` | Open file |
| `Ctrl+v` | Open in vertical split |
| `Ctrl+x` | Open in horizontal split |
| `Ctrl+t` | Open in new tab |
| `Esc` | Close |

### In-file Search

| Key | Action |
|-----|--------|
| `/` | Search forward |
| `?` | Search backward |
| `n` | Next match |
| `N` | Previous match |
| `*` | Search word under cursor |
| `Esc` | Clear search highlight |

### Flash (Quick Jump)

Press `s` in normal mode to activate flash jump:
1. Type 1-2 characters
2. Labels appear on matches
3. Press label to jump

---

## Git Integration

### Lazygit

```
Space gg  →  Open Lazygit
```

Full-featured git TUI inside Neovim.

### Gitsigns (Inline Git)

Your config shows git blame on the current line automatically.

| Keybinding | Action |
|------------|--------|
| `]h` | Next hunk (change) |
| `[h` | Previous hunk |
| `Space ghs` | Stage hunk |
| `Space ghr` | Reset hunk |
| `Space ghp` | Preview hunk |
| `Space ghb` | Blame line |

### Git Telescope

| Keybinding | Action |
|------------|--------|
| `Space fc` | Browse commits |
| `Space fs` | Git status |

---

## LSP Features

Language Server Protocol gives you IDE features.

### Navigation

| Keybinding | Action |
|------------|--------|
| `gd` | Go to definition |
| `gr` | Find references |
| `K` | Hover documentation |
| `gD` | Go to declaration |
| `gi` | Go to implementation |

### Code Actions

| Keybinding | Action |
|------------|--------|
| `Space ca` | Code actions (fixes) |
| `Space rn` | Rename symbol |
| `Space cf` | Format file |

### Diagnostics (Errors/Warnings)

| Keybinding | Action |
|------------|--------|
| `[d` | Previous diagnostic |
| `]d` | Next diagnostic |
| `Space xx` | Open diagnostics list |

### Trouble (Better Diagnostics)

```
Space xx  →  Toggle Trouble panel
```

Shows all errors/warnings in a navigable list.

---

## Copilot

GitHub Copilot is enabled. Suggestions appear automatically.

| Key | Action |
|-----|--------|
| `Tab` | Accept suggestion |
| `Ctrl+]` | Dismiss |
| `Alt+]` | Next suggestion |
| `Alt+[` | Previous suggestion |

---

## UI Features

### Zen Mode (Focused Editing)

```
Space z  →  Toggle Zen Mode
```

Removes all distractions for focused writing/coding.

### Which-Key

Just press `Space` and wait. A popup shows all available commands grouped by category.

### Dashboard

The startup screen. Access it anytime:
```
:Dashboard
```

---

## Plugin Management

### Lazy.nvim

```
Space l  →  Open Lazy plugin manager
```

| Key | Action |
|-----|--------|
| `i` | Install plugins |
| `u` | Update plugins |
| `c` | Check for updates |
| `s` | Sync (install + clean) |
| `p` | Profile startup time |

### Mason (LSP/Formatter Installer)

```
:Mason  →  Open Mason
```

Search and install language servers, formatters, linters.

**Recommended installs:**
- `typescript-language-server`
- `lua-language-server`
- `prettier`
- `stylua`
- `eslint-lsp`

---

## Customization

### Config File Locations

All config is in `~/dotfiles/nvim/`:

```
nvim/
├── init.lua              # Entry point
├── lua/
│   ├── config/
│   │   ├── autocmds.lua  # Auto commands
│   │   ├── keymaps.lua   # Key bindings
│   │   ├── lazy.lua      # Plugin manager setup
│   │   └── options.lua   # Neovim options
│   └── plugins/
│       ├── colorscheme.lua  # Theme
│       ├── coding.lua       # LSP, completion
│       ├── editor.lua       # Editor enhancements
│       └── ui.lua           # UI components
```

### Adding a Plugin

Edit `~/.config/nvim/lua/plugins/` and add a new file or edit existing:

```lua
-- lua/plugins/my-plugin.lua
return {
  {
    "author/plugin-name",
    event = "VeryLazy",  -- lazy load
    opts = {
      -- plugin options
    },
  },
}
```

Save and run `:Lazy sync`

### Changing Theme

Edit `lua/plugins/colorscheme.lua`:

```lua
opts = {
  flavour = "mocha",  -- latte, frappe, macchiato, mocha
}
```

### Adding Keymaps

Edit `lua/config/keymaps.lua`:

```lua
local map = vim.keymap.set
map("n", "<leader>xx", "<cmd>SomeCommand<cr>", { desc = "Description" })
```

---

## Cheat Sheet

```
NAVIGATION
───────────────────────────────────────────
Space         Leader (shows all commands)
Space Space   Find files
Space e       File explorer
Ctrl+h/j/k/l  Move between windows
Shift+h/l     Previous/next buffer

SEARCH
───────────────────────────────────────────
Space ff      Find files
Space fg      Search in files (grep)
Space fr      Recent files
/             Search in file
n/N           Next/previous match

CODE
───────────────────────────────────────────
gd            Go to definition
gr            Find references
K             Hover docs
Space ca      Code actions
Space rn      Rename
[d / ]d       Prev/next diagnostic
gcc           Toggle comment

GIT
───────────────────────────────────────────
Space gg      Lazygit
]h / [h       Next/prev hunk
Space ghs     Stage hunk

EDITING
───────────────────────────────────────────
jk            Escape to normal mode
Ctrl+s        Save
u / Ctrl+r    Undo / Redo
dd            Delete line
yy            Yank (copy) line
p             Paste
cs"'          Change surround " to '

UI
───────────────────────────────────────────
Space z       Zen mode
Space l       Lazy (plugins)
Space q       Quit
:Mason        LSP installer
:checkhealth  Verify setup
```

---

## Learning Path

### Week 1: Basics
- [ ] Navigate with `hjkl`
- [ ] Use `Space Space` to find files
- [ ] Save with `Ctrl+s`
- [ ] Escape with `jk`
- [ ] Use `Space e` for file explorer

### Week 2: Editing
- [ ] Delete, yank, paste (`dd`, `yy`, `p`)
- [ ] Visual mode selections (`v`, `V`)
- [ ] Comment with `gcc`
- [ ] Undo/redo (`u`, `Ctrl+r`)

### Week 3: Search & Navigation
- [ ] Telescope grep (`Space fg`)
- [ ] Go to definition (`gd`)
- [ ] Find references (`gr`)
- [ ] Buffer switching (`Space ,`)

### Week 4: Git & Advanced
- [ ] Lazygit (`Space gg`)
- [ ] Gitsigns hunks (`]h`, `[h`)
- [ ] Diagnostics (`Space xx`)
- [ ] Code actions (`Space ca`)

---

## Tips

1. **Press Space and wait** — Which-key will show you everything
2. **Use Telescope for everything** — Finding files, grep, buffers, git
3. **Let LSP help you** — Hover with `K`, go to definition with `gd`
4. **Copilot is on** — Just start typing, suggestions will appear
5. **Lazygit is powerful** — `Space gg` for a full git TUI

## Getting Help

- `:help keyword` — Built-in help
- `:Telescope help_tags` — Search help
- `:checkhealth` — Diagnose issues
- LazyVim docs: https://lazyvim.org
