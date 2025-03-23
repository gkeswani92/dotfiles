# Gaurav's Dotfiles

A modern, organized collection of configuration files and scripts to set up a development environment quickly and consistently across different machines.

## 🚀 Features

- **Shell**: Zsh with Oh-My-Zsh and custom plugins
- **Terminal**: iTerm2 with custom themes and configurations
- **Prompt**: Starship prompt with custom configuration
- **Git**: Enhanced Git configuration with useful aliases and scripts
- **Terminal Multiplexer**: Tmux and Zellij for session management
- **Aesthetics**: Custom color schemes, fonts, and welcome screen
- **Aliases**: Productivity-boosting aliases and functions
- **Cross-Platform**: Works on macOS and Linux

## 📦 What's Included

- **Shell**
  - Zsh configuration with Oh-My-Zsh
  - Custom plugins (syntax highlighting, autosuggestions, etc.)
  - Aliases for common tasks
  - Custom functions for productivity

- **Git**
  - Enhanced Git aliases and configuration
  - Custom Git scripts for common workflows
  - Git Delta for better diffs
  - Interactive rebase tool

- **Terminal**
  - iTerm2 color schemes
  - Programming fonts with ligatures
  - Welcome screen with useful information
  - Terminal icons and colors

- **Tools**
  - Zellij terminal multiplexer with custom layouts
  - Tmux configuration
  - Fzf fuzzy finder
  - Vim configuration and color schemes

## 🔧 Installation

### One-line Install

```bash
curl https://raw.githubusercontent.com/gkeswani92/dotfiles/main/install.sh | sh
```

### Manual Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/gkeswani92/dotfiles.git ~/dotfiles
   ```

2. Run the install script:
   ```bash
   cd ~/dotfiles
   ./install.sh
   ```

3. Restart your terminal or run:
   ```bash
   source ~/.zshrc
   ```

## ⚙️ Configuration Structure

```
dotfiles/
├── git/                  # Git configuration and scripts
│   ├── .gitconfig        # Global Git configuration
│   ├── plugins/          # Git plugins (delta, interactive rebase)
│   └── scripts/          # Custom Git scripts
├── local-development/    # Local development configurations
│   └── zellij/           # Zellij layouts and configs
├── ruby/                 # Ruby configuration
├── shell/                # Shell configuration
│   ├── .zshrc            # Zsh configuration
│   └── tmux.conf         # Tmux configuration
├── terminal/             # Terminal enhancements
│   ├── aliases.zsh       # Terminal aliases
│   ├── fonts/            # Terminal font configuration
│   ├── prompt/           # Shell prompt configuration (Starship)
│   ├── themes/           # Terminal color schemes
│   └── welcome.sh        # Terminal welcome screen
├── vim/                  # Vim configuration
│   ├── .vimrc            # Vim configuration
│   └── colors/           # Vim color schemes
├── CLAUDE.md             # Instructions for Claude AI assistant
├── install.sh            # Main installation script
└── README.md             # Documentation
```

## 📋 Usage Guide

### Shell Aliases

- Navigate directories easily:
  ```
  .. - Go up one directory
  ... - Go up two directories
  ```

- Enhanced listing:
  ```
  ls - List files with icons
  ll - Long listing with icons
  tree - Show directory tree
  ```

- Git shortcuts:
  ```
  g - Git status
  gs - Git status
  gl - Git log with graph
  ```

- Useful functions:
  ```
  mkcd <dir> - Create and change to directory
  extract <file> - Extract any archive format
  weather - Show weather forecast
  ```

### Terminal Welcome Screen

The terminal welcome screen provides:
- Current date and time
- Dotfiles status
- Current git project information
- Daily programming quote
- Reminder of useful commands

### Custom Git Commands

- `git cob` - Fuzzy checkout branch
- `git credit` - Add co-author to commit
- `git delete-local-merged` - Clean merged branches
- `git undo` - Undo last commit
- `git unpushed` - Show unpushed commits
- `git up` - Pull with change summary

## 🔄 Updating

To update your dotfiles to the latest version:

```bash
cd ~/dotfiles
git pull
./install.sh
```

## 🛠️ Customization

### Adding Custom Aliases

Edit `~/dotfiles/terminal/aliases.zsh` to add your own aliases.

### Modifying the Welcome Screen

Edit `~/dotfiles/terminal/welcome.sh` to customize your welcome message.

### Changing Terminal Theme

1. Import one of the theme files from `~/dotfiles/terminal/themes/` in iTerm2
2. Select it in iTerm2 preferences

## 🧰 Tech Stack

- [Oh-My-Zsh](https://ohmyz.sh/)
- [Starship Prompt](https://starship.rs/)
- [Git Delta](https://github.com/dandavison/delta)
- [Zellij](https://zellij.dev/)
- [Molokai](https://github.com/tomasr/molokai) (Vim color scheme)
- [Eza](https://github.com/eza-community/eza) (Modern ls replacement)
