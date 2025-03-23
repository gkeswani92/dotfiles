# Enhanced Shell History

This directory contains configurations to significantly improve your shell history experience with better search capabilities and deduplication.

## Features

### Enhanced History Configuration (`history-config.zsh`)

- **Larger History Size**: Stores 50,000 commands in history (up from the default)
- **Timestamps**: Records when commands were executed
- **Smart Deduplication**: Automatically removes duplicate commands
- **Reduced Blank Lines**: Removes unnecessary whitespace
- **Multi-Session Sharing**: History is shared between terminal sessions
- **Incremental Saving**: Commands are saved as they're executed

### FZF History Search (`fzf-history.zsh`)

- **Fuzzy Search**: Find commands by typing fragments
- **Visual Selection**: See multiple matches at once
- **Command Preview**: Preview selected commands before execution
- **Command Editing**: Edit commands before executing them with Ctrl+E
- **Command Viewing**: View command details without executing with Ctrl+V
- **Sorting**: Toggle between chronological and relevance sorting with Ctrl+R

## Keyboard Shortcuts

- `Ctrl+R`: Open fuzzy history search
- `Ctrl+E` (in search): Edit selected command before executing
- `Ctrl+V` (in search): View selected command without executing
- `Ctrl+R` (in search): Toggle sort order
- `Ctrl+P` / `Up Arrow`: Navigate history up
- `Ctrl+N` / `Down Arrow`: Navigate history down

## Utility Functions

- `hist_deduplicate`: Manually deduplicate history file
- `hist_stats`: Show history statistics and most used commands
- `hist_find <pattern>`: Search history for specific pattern
- `hist_add <command>`: Add a command to history without executing it

## Usage Examples

```bash
# See your most frequently used commands
hist_stats

# Search history for git commands
hist_find "git"

# Manually clean up your history file
hist_deduplicate

# Add a command to history for later use
hist_add git push origin main --force-with-lease
```

## Configuration

The history settings can be customized by editing `history-config.zsh`:

- `HISTSIZE`: Number of commands to keep in memory
- `SAVEHIST`: Number of commands to save to disk
- Various `setopt` flags control how history behaves

You can enable automatic history deduplication on shell startup by uncommenting the appropriate line in `history-config.zsh`, but note that this can slightly slow down shell startup time.