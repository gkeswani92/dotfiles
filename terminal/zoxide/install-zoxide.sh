#!/bin/bash
set -e
# Script to install and configure zoxide
# https://github.com/ajeetdsouza/zoxide
#
# Zoxide is a smarter cd command that remembers which directories you use most frequently,
# so you can "jump" to them in just a few keystrokes.

echo "✅ Installing zoxide - a smarter cd command"

# Install zoxide
if command -v zoxide >/dev/null 2>&1; then
  echo 'Zoxide is already installed, skipping...'
elif [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS installation
  if command -v brew >/dev/null 2>&1; then
    echo "Installing zoxide via Homebrew..."
    brew install zoxide
  else
    echo "Homebrew not found. Please install Homebrew first."
    exit 1
  fi
else
  # Linux installation
  if command -v apt-get >/dev/null 2>&1; then
    echo "Installing zoxide via apt..."
    sudo apt-get update
    sudo apt-get install -y zoxide
  elif command -v dnf >/dev/null 2>&1; then
    echo "Installing zoxide via dnf..."
    sudo dnf install -y zoxide
  else
    echo "Installing zoxide via cargo..."
    if ! command -v cargo >/dev/null 2>&1; then
      echo "Installing Rust first..."
      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
      source "$HOME/.cargo/env"
    fi
    cargo install zoxide
  fi
fi

# config.zsh is already tracked; installation must not regenerate repository files.

echo "✅ Zoxide installation complete!"
echo "Shared configuration (not regenerated): $(dirname "$0")/config.zsh"