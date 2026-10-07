# CLAUDE.md - Guidelines for AI Assistants

## Repository Purpose
This repository contains dotfiles and configuration for various development tools including shell, git, vim, and tmux.

## Commands
- Install from a local checkout: `./install.sh`
- Preview AI setup: `./install.sh --ai-only --dry-run`
- Test AI setup offline: `python3 -m unittest discover -s tests -v`
- AI resources are scoped under `ai/shared`, `ai/personal`, and `ai/work`; see `ai/README.md`.
- Machine identity is local data in `~/.config/dotfiles/profile`, never a Git-tracked setting.

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