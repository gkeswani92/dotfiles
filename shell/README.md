# Shell Configuration

This directory contains configuration files for your shell environment (Zsh) and terminal multiplexer (Tmux).

## Contents

- `.zshrc`: Zsh shell configuration
- Tmux configuration has been moved to `/terminal/tmux/`

## Zsh Configuration (`.zshrc`)

The Zsh configuration sets up your shell environment with:

### Oh-My-Zsh Setup
- Initializes Oh-My-Zsh with the "robbyrussell" theme
- Configures automatic updates
- Sets proper locale and PATH variables

### Plugin Configuration
Enables and configures the following plugins:
- `git`: Git integration and aliases
- `zsh-completions`: Enhanced tab completion
- `zsh-autosuggestions`: Fish-like suggestions
- `zsh-syntax-highlighting`: Command syntax highlighting
- `zsh-history-substring-search`: History search with up/down arrows
- `fzf-tab`: Fuzzy-finder tab completion

### Environment Variables
- `DOTFILES_PATH`: Path to your dotfiles directory
- `EDITOR`: Default editor (VS Code locally, Vim for remote sessions)
- `LANG`: Language and locale settings

### Tool Integration
- ASDF version manager
- NVM (Node Version Manager)
- iTerm2 shell integration
- Homebrew environment setup

### Zellij Integration
Aliases for starting Zellij with custom layouts:
- `bp-full-local-dev`: Full development environment layout
- `bp-orgs-only-dev`: Organizations-only development layout

## Usage

These configurations are automatically applied during the dotfiles installation process.

### Custom Configuration

If you want to add personal Zsh configurations without modifying the main `.zshrc`, you can create:

```bash
touch ~/.zshrc.local
```

And then add to your `.zshrc`:

```bash
# Load local customizations if present
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
```

This allows for machine-specific configurations that won't be tracked in the dotfiles repository.