#!/bin/bash
set -e

# Define paths
DOTFILES_PATH="$HOME/dotfiles"
ZELLIJ_CONFIG_PATH="$HOME/.config/zellij"

# Create required directories
echo "Creating Zellij configuration directories..."
mkdir -p "$ZELLIJ_CONFIG_PATH"
mkdir -p "$ZELLIJ_CONFIG_PATH/layouts"

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

# Create symlinks
echo "Creating symlinks for Zellij configuration..."
ln -sf "$DOTFILES_PATH/terminal/zellij/config.kdl" "$ZELLIJ_CONFIG_PATH/config.kdl"

# Link layout files
echo "Creating symlinks for Zellij layouts..."
for layout in "$DOTFILES_PATH/terminal/zellij/layouts"/*.kdl; do
    layout_file=$(basename "$layout")
    ln -sf "$layout" "$ZELLIJ_CONFIG_PATH/layouts/$layout_file"
done

# Link in business-platform layouts to ~/.config/zellij/
echo "Creating symlinks for business platform layouts..."
for bp_layout in "$DOTFILES_PATH/local-development/zellij"/*.kdl; do
    bp_layout_file=$(basename "$bp_layout")
    ln -sf "$bp_layout" "$ZELLIJ_CONFIG_PATH/$bp_layout_file"
done

# Make sure the file is executable
chmod +x "$DOTFILES_PATH/terminal/zellij/install-zellij.sh"

echo "Zellij configuration installed successfully!"
echo "You can start Zellij with: zellij"
echo "Or use a specific layout: zellij --layout dev"