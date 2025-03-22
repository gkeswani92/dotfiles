# CLAUDE.md - Guidelines for AI Assistants

## Repository Purpose
This repository contains dotfiles and configuration for various development tools including shell, git, vim, and tmux.

## Commands
- Install: `curl https://raw.githubusercontent.com/gkeswani92/dotfiles/main/install.sh | sh`
- No specific build/lint/test commands as this is a dotfiles repo

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