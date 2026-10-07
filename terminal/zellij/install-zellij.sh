#!/bin/bash
set -e

# Define paths
DOTFILES_PATH="$HOME/dotfiles"
source "$DOTFILES_PATH/scripts/profile.sh"
profile=$(dotfiles_read_profile)
python3 "$DOTFILES_PATH/scripts/setup-machine.py" --profile "$profile" --layouts-only --check

# Check if Zellij is installed
if ! command -v zellij &> /dev/null; then
    echo "Zellij is not installed. Installing now..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS installation
        if ! command -v brew &> /dev/null; then
            echo "Homebrew is required but not installed. Please install Homebrew first."
            exit 1
        fi
        brew install zellij
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux installation
        if command -v apt-get &> /dev/null; then
            # For systems with apt (Debian, Ubuntu, etc.)
            sudo apt-get update
            sudo apt-get install -y zellij
        elif command -v cargo &> /dev/null; then
            # Install using Cargo if available
            cargo install --locked zellij
        else
            echo "Could not determine package manager. Please install Zellij manually."
            exit 1
        fi
    else
        echo "Unsupported operating system. Please install Zellij manually."
        exit 1
    fi
fi

# Use the same safe, role-aware reconciliation as the main installer.
python3 "$DOTFILES_PATH/scripts/setup-machine.py" --profile "$profile" --layouts-only

echo "Zellij configuration installed successfully!"
echo "You can start Zellij with: zellij"
echo "Or use a specific layout: zellij --layout dev"