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
git clone https://github.com/gkeswani92/dotfiles.git ~/dotfiles && ~/dotfiles/install.sh
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

### Personal and Work Machine Profiles

The first installer run asks whether this is a **personal or work machine** and saves the choice in `~/.config/dotfiles/profile` (outside Git). Subsequent runs reuse it. This is a machine-wide choice, not an AI-only flag.

| Configuration | Personal | Work |
|---|---|---|
| Git email | `gauravkeswani92@gmail.com` | `gaurav.keswani@shopify.com` |
| Git aliases, editor, diff tools | Shared | Shared |
| Signing settings | Machine-local personal overrides | Machine-local work overrides |
| Shopify URL rewrites, dev Git include, World maintenance | Not included | Included |
| dev/tec/Spin shell setup, BP aliases/layouts, Quick Demo installation | Not activated/installed | Enabled |
| Pi | Personal defaults; Mermaid + Git Context | Work defaults and capabilities |

```bash
./install.sh --config-only --dry-run        # Preview profile-dependent configuration
./install.sh --config-only                  # Configure Git, Zellij, and AI; no software installs
./install.sh --config-only --replace-conflicts # Archive and replace independent conflicting files
./install.sh --config-only --reconfigure-profile # Change the machine role consistently
./install.sh                                # Full installation for the saved machine role
./install.sh --ai-only                      # Refresh AI only, without changing Git or installing tools
```

`--ai-only` restricts an operation, not the scope of personal/work separation. Once Git is managed, changing the role requires `--config-only` or the full installer so Git and AI cannot end up on different roles. Plain `--dry-run` previews profile-dependent configuration; it is not a simulation of package installation.

Live `~/.gitconfig` is now a local include wrapper, not a symlink into Git. Signing settings live in `~/.config/dotfiles/git/{personal,work}.local.gitconfig`; your current personal signing key and signing preference are preserved there. No private keys, authentication credentials, or credential stores are copied. See [Git configuration](git/README.md).

Work-only installer-owned BP layout links are archived when choosing Personal. Independent custom layouts and already-installed software are not deleted; this is configuration separation, not sandboxing. Reload the shell after changes.

Personal Pi has shared Mermaid/Git Context skills plus a visible Herdr `/feature-team` workflow with local-only status and human-approved preference lessons. Shopify packages and work-specific resources are installed only in work mode. See [AI setup and migration](ai/README.md) for backups, local settings, and work package bootstrapping.

## ⚙️ Configuration Structure

```
dotfiles/
├── ai/                   # Machine-scoped AI resources (shared/personal/work)
├── scripts/              # Machine profile selection and safe configuration installers
├── tests/                # Offline setup regression tests
├── git/                  # Git configuration and scripts
│   ├── .gitconfig        # Shared Git settings (no identity or signer)
│   ├── personal.gitconfig # Personal identity
│   ├── work.gitconfig    # Work identity and Shopify integrations
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
├── AGENTS.md             # Instructions for AI coding agents
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

### Test Machine Configuration

```bash
python3 -m unittest discover -s tests -v
```

Tests use temporary home directories. Full installer tests run both machine roles and reruns with mocked package managers and Git clones; no packages are installed and no network/provider calls are made.

### Full Installer Acceptance and Work Migration

The full macOS installer preflights shared shell/editor configs as well as Git, layouts, and AI. Independent conflicting files are not overwritten without `--replace-conflicts`, and replaced resources are archived. Git scripts and the work Demo command use `~/.local/bin` without sudo. Oh-My-Zsh repairs preserve existing custom plugins/themes and do not rewrite `.zshrc`. Existing tools/fonts are skipped; verification failures return a nonzero exit code.

On the personal Mac, the real full installer and a repeat run completed with **22 checks passing**; `doctor.sh` passed all 26 checks. The run repaired an incomplete Oh-My-Zsh installation and installed the previously missing `bat`. Work full-installer control flow is tested offline, not yet on the actual work machine. Linux full installation has not been acceptance-tested.

Before pulling on the work machine, review `git status` and back up current Git/signing preferences and any uncommitted configuration edits. This matters if live config is still a symlink into the old checkout: pulling changes those targets before migration can inspect them. Keep backups outside the checkout; do not discard local edits to make pulling succeed.

After pulling on work:

```bash
./install.sh --config-only --dry-run   # Choose Work; inspect conflicts and the destination
./install.sh                         # Choose Work again if the preview did not save a role
./doctor.sh
git config --show-origin --get user.email
git config --show-origin --get user.signingkey
```

If an older saved profile says Personal, use `--reconfigure-profile` to select Work. If conflicts block installation, inspect them and rerun with `--replace-conflicts` only when you intend to archive and replace them. Verify your work signer against your pre-pull backup; local work signing preferences belong in `~/.config/dotfiles/git/work.local.gitconfig`. Keep Pi credentials/history in their correct work directory; the installer does not infer or move them. Start `pi` to bootstrap the configured work package if absent, then rerun `--ai-only` to add its extra links.

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
