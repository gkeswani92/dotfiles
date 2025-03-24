#!/bin/bash
set -e

# Define paths
DOTFILES_PATH="$HOME/dotfiles"
NVIM_CONFIG_PATH="$HOME/.config/nvim"

# Check if Neovim is installed
if ! command -v nvim &> /dev/null; then
    echo "Neovim is not installed. Installing now..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS installation
        if ! command -v brew &> /dev/null; then
            echo "Homebrew is required but not installed. Please install Homebrew first."
            exit 1
        fi
        brew install neovim ripgrep fd
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Ubuntu/Debian installation
        sudo apt-get update
        sudo apt-get install -y neovim ripgrep fd-find
    else
        echo "Unsupported operating system. Please install Neovim manually."
        exit 1
    fi
fi

# Set up LazyVim
echo "Setting up LazyVim..."

# Backup existing config if it exists
if [ -d "$NVIM_CONFIG_PATH" ]; then
    echo "Backing up existing Neovim configuration..."
    mv "$NVIM_CONFIG_PATH" "${NVIM_CONFIG_PATH}.backup.$(date +%Y%m%d%H%M%S)"
fi

# Create config directory
mkdir -p "$NVIM_CONFIG_PATH"

# Clone LazyVim starter
echo "Installing LazyVim..."
git clone https://github.com/LazyVim/starter "$NVIM_CONFIG_PATH"
rm -rf "$NVIM_CONFIG_PATH/.git"

# Copy custom configuration files
echo "Applying custom configurations..."
cp -r "$DOTFILES_PATH/terminal/neovim/config/"* "$NVIM_CONFIG_PATH/"

# Install additional language support
echo "Setting up language support..."
mkdir -p "$NVIM_CONFIG_PATH/lua/plugins"

# Add our custom plugin configurations if they don't exist in the starter template
for plugin_file in "$DOTFILES_PATH/terminal/neovim/plugins/"*.lua; do
    if [ -f "$plugin_file" ]; then
        plugin_name=$(basename "$plugin_file")
        if [ ! -f "$NVIM_CONFIG_PATH/lua/plugins/$plugin_name" ]; then
            cp "$plugin_file" "$NVIM_CONFIG_PATH/lua/plugins/"
        fi
    fi
done

# Setup themes based on our terminal themes
if [ ! -f "$NVIM_CONFIG_PATH/lua/plugins/colorscheme.lua" ]; then
    cp "$DOTFILES_PATH/terminal/neovim/plugins/colorscheme.lua" "$NVIM_CONFIG_PATH/lua/plugins/"
fi

echo "Neovim with LazyVim has been successfully installed!"
echo "Start Neovim with 'nvim' to complete the setup and install plugins."
echo "LazyVim will automatically install all plugins on first launch."