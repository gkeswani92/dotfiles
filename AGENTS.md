# AGENTS.md - Guidelines for AI Assistants

## Repository Purpose
This repository contains dotfiles and configuration for various development tools including shell, git, vim, and tmux.

## Commands
- Install from a local checkout: `./install.sh`
- Preview profile-dependent configuration: `./install.sh --config-only --dry-run`
- Configure Git, layouts, and AI without installing software: `./install.sh --config-only`
- Preview AI only: `./install.sh --ai-only --dry-run`
- Test machine setup offline: `python3 -m unittest discover -s tests -v`
- AI resources are scoped under `ai/shared`, `ai/personal`, and `ai/work`; see `ai/README.md`.
- The machine-wide personal/work role is local data in `~/.config/dotfiles/profile`, never a Git-tracked setting; it controls Git and work integrations as well as AI.
- Live Git config is a local include wrapper. Signing preferences belong in `~/.config/dotfiles/git/<role>.local.gitconfig`, never tracked config.

## Code Style Guidelines
- Shell scripts: Use shebang (`#!/bin/bash`), comments for complex logic
- Error handling: Use `set -e` for early exit on errors 
- Script structure: Check for command/tool existence before use
- Path variables: Use consistent `$HOME` and `$DOTFILES_PATH` variables
- Symlinks: Use `ln -sf` pattern for dotfile linking
- Conditionals: Use `[[ "$OSTYPE" == "darwin"* ]]` for macOS detection
- Tool installation: OS-specific installs via package managers (brew/apt)
- Git scripts: Place in `git/scripts/` and use consistent naming (`git-*`)
- Configuration files: Place in respective tool directories

## Platform Support
- macOS (primary)
- Linux distributions with apt package manager
- Shopify Spin environments