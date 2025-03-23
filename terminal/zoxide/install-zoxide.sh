#!/bin/bash
# Script to install and configure zoxide
# https://github.com/ajeetdsouza/zoxide
#
# Zoxide is a smarter cd command that remembers which directories you use most frequently,
# so you can "jump" to them in just a few keystrokes.

echo "✅ Installing zoxide - a smarter cd command"

# Install zoxide
if [[ "$OSTYPE" == "darwin"* ]]; then
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

# Add default configuration
cat > "$(dirname "$0")/config.zsh" << 'EOL'
# Zoxide Configuration
# https://github.com/ajeetdsouza/zoxide

# Initialize zoxide with zsh
if command -v zoxide >/dev/null 2>&1; then
  # Initialize with standard settings
  eval "$(zoxide init zsh)"

  # Custom aliases for zoxide
  alias cd="z"         # Replace standard cd with zoxide
  alias zz="z -"       # Go back to the previous directory
  alias zi="z -i"      # Interactive selection using fzf
  alias zl="z -l"      # List all directories in the database with their scores
  alias zc="z -c"      # Restricts matches to subdirectories of the current directory
  alias zf="zi"        # Fuzzy finder alias for interactive selection
fi
EOL

echo "✅ Zoxide installation complete!"
echo "The configuration has been added to: $(dirname "$0")/config.zsh"