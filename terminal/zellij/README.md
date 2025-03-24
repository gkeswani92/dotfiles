# Zellij Configuration

[Zellij](https://zellij.dev/) is a modern terminal multiplexer (like tmux) designed for efficiency and ease of use. This directory contains configuration files and layouts for Zellij optimized for macOS.

## Features

- **macOS-Optimized**: Configured with macOS-specific key bindings (Alt key, which is Option on Mac)
- **Multiple Themes**: Includes Catppuccin, Dracula, Tokyo Night, and Nord themes
- **Productive Layouts**: Pre-configured layouts for different workflows
- **Tmux-like Bindings**: Familiar keybindings for tmux users

## Installation

Run the installation script:

```bash
./install-zellij.sh
```

This will:
1. Install Zellij if not already installed (using Homebrew on macOS)
2. Create necessary configuration directories
3. Symlink configuration files to `~/.config/zellij/`
4. Set up pre-defined layouts

## Available Layouts

- **Default Layout**: General-purpose development with editor and terminal
- **Dev Layout**: Project-focused with Git integration and server tabs
- **BP Full Layout**: Complete business platform development environment
- **BP Orgs Layout**: Organizations-only development layout

## Usage

### Basic Commands

- Start Zellij with default layout: `zellij`
- Start with specific layout: `zellij --layout dev`
- Start BP full layout: `zellij --layout bp-full`
- Start BP orgs layout: `zellij --layout bp-orgs-only`

### Key Bindings

#### Quick Actions (Normal Mode)

- `Alt+b` - Switch to tmux mode (Alt is the Option key on Mac)
- `Alt+arrow keys` - Navigate between panes
- `Alt+Shift+arrow keys` - Resize current pane
- `Alt+n` - Create new pane
- `Alt+w` - Close current pane
- `Alt+f` - Toggle fullscreen for current pane
- `Alt+d` - Detach from session
- `Alt+r` - Enter resize mode

#### Tmux Mode (after pressing `Alt+b`)

- `Esc` - Exit tmux mode
- `h/j/k/l` - Navigate left/down/up/right
- `v` - Split pane horizontally
- `b` - Split pane vertically
- `c` - Create new tab
- `n/p` - Go to next/previous tab
- `x` - Close current pane
- `z` - Toggle fullscreen
- `Space` - Cycle layouts

## Customization

To create custom layouts:

1. Create a new `.kdl` file in `layouts/` directory
2. Define your layout using Zellij's layout language
3. Run the installation script to symlink your new layout

For detailed layout configuration options, refer to the [Zellij documentation](https://zellij.dev/documentation/).

## Aliases

Add these aliases to your `.zshrc` or `.bashrc`:

```bash
alias zj="zellij"
alias zjl="zellij --layout"
alias zjdev="zellij --layout dev"
alias zjbpfull="zellij --layout bp-full"
alias zjbporgs="zellij --layout bp-orgs-only"
```