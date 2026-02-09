# Cursor IDE Power-User Tutorial

A workflow-oriented guide to stop reaching for the mouse. Organized by **what you're trying to do**, structured as progressive levels to build muscle memory incrementally.

> All shortcuts are macOS. Cursor is a VSCode fork — these work in both.

---

## Level 1: Navigation (Stop Using the Mouse)

| Shortcut | Action |
|---|---|
| `Cmd+P` | Go to file by name (replaces clicking the file tree) |
| `Cmd+Shift+O` | Go to symbol in current file (jump to function/class) |
| `Cmd+T` | Go to symbol across entire workspace |
| `Cmd+G` | Go to line number |
| `Ctrl+-` / `Ctrl+Shift+-` | Navigate back / forward (after jumping to definitions) |
| `Cmd+Shift+.` | Focus breadcrumbs (navigate file structure from the top bar) |

**The habit to break:** Scrolling through the file tree or using Cmd+Shift+F to find a file you already know the name of. Use `Cmd+P` instead — it's fuzzy, so `ukb` matches `useKeyBindings.ts`.

---

## Level 2: Code Intelligence (Stop Doing Codebase Search)

| Shortcut | Action |
|---|---|
| `F12` / `Cmd+Click` | Go to definition |
| `Shift+F12` | Find all references |
| `Cmd+Shift+F12` | Go to implementation |
| `Option+F12` | Peek definition (inline preview without leaving current file) |
| `F2` | Rename symbol (across all files) |
| `Cmd+.` | Quick fix / code actions |

**The habit to break:** Grepping for a function name to find where it's defined or used. `F12` goes to the definition instantly. `Shift+F12` shows every reference. `F2` renames it everywhere.

---

## Level 3: Editing (Stop Selecting with Mouse)

| Shortcut | Action |
|---|---|
| `Cmd+D` | Select next occurrence (multi-cursor) |
| `Cmd+Shift+L` | Select ALL occurrences |
| `Option+Up/Down` | Move line up/down |
| `Option+Shift+Up/Down` | Duplicate line up/down |
| `Cmd+Shift+K` | Delete entire line |
| `Cmd+L` | Select entire line |
| `Option+Click` | Add cursor at click position |
| `Cmd+Option+Up/Down` | Add cursor above/below |
| `Cmd+Shift+\` | Jump to matching bracket |

**The habit to break:** Manually selecting text to change a variable name in 5 places. `Cmd+D` five times, then type the replacement once.

---

## Level 4: Cursor AI Features (The Multiplier)

| Shortcut | Action |
|---|---|
| `Tab` | Accept AI suggestion (Cursor Tab — much smarter than Copilot) |
| `Cmd+Right` | Accept next word only (partial accept) |
| `Cmd+K` | Inline edit with AI (select code first, describe the change) |
| `Cmd+L` | Open AI chat panel |
| `Cmd+Shift+L` | Add selected code to chat as context |
| `Cmd+I` | Open Composer (agent mode, multi-file edits) |
| `Cmd+Shift+I` | Full-screen Composer |
| `Cmd+.` | Mode menu (switch between Ask/Edit/Agent) |
| `Cmd+/` | Cycle AI models |

**@ symbols in chat:** `@filename` (add a file as context), `@codebase` (search the whole project), `@web` (search the web), `@docs` (reference documentation).

**The workflow:** Select confusing code → `Cmd+L` to ask about it. Select code to change → `Cmd+K` to describe what you want. For multi-file changes, use `Cmd+I` Composer in agent mode.

---

## Level 5: Panels & Window Management

| Shortcut | Action |
|---|---|
| `Cmd+B` | Toggle sidebar |
| `Cmd+J` | Toggle bottom panel |
| `` Cmd+` `` | Toggle terminal |
| `Cmd+\` | Split editor |
| `Cmd+1/2/3` | Focus editor group 1/2/3 |
| `Cmd+Shift+E` | Focus file explorer |
| `Cmd+Shift+F` | Focus search |
| `Cmd+Shift+G` | Focus source control |
| `Cmd+Shift+X` | Focus extensions |

---

## Level 6: Terminal Power

| Shortcut | Action |
|---|---|
| `Cmd+K` (in terminal) | AI-powered terminal command generation |
| `Cmd+Return` (in terminal) | Run AI-generated command |
| `Cmd+T` (custom) | New terminal |

---

## Cheat Sheet — Top 25

| # | Shortcut | What it does |
|---|---|---|
| 1 | `Cmd+P` | Go to file |
| 2 | `Cmd+Shift+O` | Go to symbol in file |
| 3 | `F12` | Go to definition |
| 4 | `Shift+F12` | Find all references |
| 5 | `Ctrl+-` | Navigate back |
| 6 | `F2` | Rename symbol |
| 7 | `Cmd+D` | Select next occurrence |
| 8 | `Cmd+Shift+L` | Select all occurrences |
| 9 | `Option+Up/Down` | Move line |
| 10 | `Cmd+Shift+K` | Delete line |
| 11 | `Cmd+K` | AI inline edit |
| 12 | `Cmd+L` | AI chat |
| 13 | `Cmd+I` | Composer (agent) |
| 14 | `Tab` | Accept AI suggestion |
| 15 | `Cmd+.` | Quick fix / code actions |
| 16 | `Option+F12` | Peek definition |
| 17 | `Cmd+Shift+\` | Jump to matching bracket |
| 18 | `Cmd+Option+Up/Down` | Add cursor above/below |
| 19 | `Cmd+B` | Toggle sidebar |
| 20 | `Cmd+J` | Toggle bottom panel |
| 21 | `` Cmd+` `` | Toggle terminal |
| 22 | `Cmd+\` | Split editor |
| 23 | `Cmd+G` | Go to line |
| 24 | `Cmd+T` | Go to workspace symbol |
| 25 | `Cmd+Shift+.` | Focus breadcrumbs |

---

## One Week Challenge

Build muscle memory by focusing on one level at a time. Force yourself to use the shortcut even when the mouse feels faster — it won't after day 3.

**Day 1-2: Navigation only**
- Every time you want to open a file → `Cmd+P`
- Every time you want to find a function → `Cmd+Shift+O`
- Every time you click a function call → `F12` instead
- After jumping, use `Ctrl+-` to go back

**Day 3-4: Add editing**
- Change a variable name → `Cmd+D` repeatedly, then type
- Move code around → `Option+Up/Down`
- Delete a line → `Cmd+Shift+K` (not select-all then delete)
- Try multi-cursor with `Cmd+Option+Down` for aligned edits

**Day 5-6: Add AI features**
- Confusing code? Select it → `Cmd+L` → ask
- Want to refactor? Select it → `Cmd+K` → describe
- Need a whole feature? `Cmd+I` → describe in agent mode
- Practice partial accept with `Cmd+Right` on Tab suggestions

**Day 7: Full workflow integration**
- Hide the sidebar (`Cmd+B`) — navigate entirely with `Cmd+P`
- Split editor (`Cmd+\`) for side-by-side work
- Use `Cmd+1/2` to switch between splits
- Manage terminal with `` Cmd+` `` and `Cmd+T`
