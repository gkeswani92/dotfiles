# Tmux Configuration

This directory contains the configuration for Tmux, a terminal multiplexer that allows you to run multiple terminal sessions within a single window.

## Contents

- `tmux.conf`: The main configuration file for Tmux

## Features

- **Modern Look**: Clean status bar with Catppuccin theme compatibility
- **Improved Keybindings**: More intuitive shortcuts for daily use
- **Mouse Support**: Full mouse integration for scrolling, selecting, and resizing
- **Enhanced Navigation**: Vim-style pane movement
- **Copy Mode**: Vim keybindings for copy/paste operations
- **Convenient Splits**: Easy window and pane management
- **Performance Optimizations**: Reduced escape time and increased history limit

## Key Bindings

| Keybinding | Action |
|------------|--------|
| `Ctrl+a` | Prefix key (instead of default `Ctrl+b`) |
| `Prefix + r` | Reload tmux configuration |
| `Prefix + \|` | Split window horizontally |
| `Prefix + -` | Split window vertically |
| `Prefix + c` | Create a new window |
| `Prefix + n` | Next window |
| `Prefix + p` | Previous window |
| `Prefix + h/j/k/l` | Navigate between panes (Vim-style) |
| `Alt+Arrow` | Navigate between panes without prefix |
| `Prefix + H/J/K/L` | Resize panes |
| `Prefix + Ctrl+x` | Toggle synchronize-panes mode |

## Copy Mode

- Enter copy mode: `Prefix + [` 
- Start selection: `v` (in copy mode)
- Copy selection: `y` (in copy mode)
- Selection is automatically copied to system clipboard

## Plugin Support (Optional)

The configuration includes commented sections for popular plugins. To use them:

1. Install Tmux Plugin Manager (TPM):
   ```bash
   git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
   ```

2. Uncomment the plugin section in `tmux.conf`
   
3. Install plugins by pressing `Prefix + I`

Included plugins (commented by default):
- tmux-sensible: Sensible default settings
- tmux-resurrect: Save and restore sessions
- tmux-continuum: Automatic session saving
- tmux-yank: Better copy/paste integration
- vim-tmux-navigator: Seamless navigation between Vim and tmux

## Usage Tips

1. Start a new tmux session:
   ```bash
   tmux
   ```

2. Start a named session:
   ```bash
   tmux new -s mysession
   ```

3. Attach to an existing session:
   ```bash
   tmux attach -t mysession
   ```

4. List running sessions:
   ```bash
   tmux ls
   ```

5. Detach from current session: `Prefix + d`

## Customization

Feel free to modify the `tmux.conf` file to suit your needs. After making changes, reload the configuration with `Prefix + r` or by running:
```bash
tmux source-file ~/.tmux.conf
```