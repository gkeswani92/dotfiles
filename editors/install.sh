#!/bin/bash
set -e

# Load utility functions
source "$DOTFILES_PATH/scripts/install_utils.sh"

# Set up Vim configuration
setup_vim() {
  print_section "Setting up Vim"
  echo "Installing Vim color schemes and plugins"
  ensure_dir "$HOME/.vim/colors"
  cp "$DOTFILES_PATH/vim/colors/"* "$HOME/.vim/colors/" 2>/dev/null || true
  
  # Create symlink for .vimrc
  ln -sf "$DOTFILES_PATH/vim/.vimrc" "$HOME/.vimrc"
  
  echo "Vim setup complete!"
}

# Set up VS Code
setup_vscode() {
  print_section "Setting up VS Code"
  
  OS=$(detect_os)
  
  if [ "$OS" = "macos" ]; then
    # VS Code settings
    VSCODE_DIR="$HOME/Library/Application Support/Code/User"
    if [ -d "$VSCODE_DIR" ] || mkdir -p "$VSCODE_DIR" 2>/dev/null; then
      echo "Linking VS Code settings..."
      ln -sf "$DOTFILES_PATH/vscode/settings.json" "$VSCODE_DIR/settings.json"
    else
      echo "Couldn't create VS Code settings directory"
    fi
    
    # Cursor settings (VS Code fork)
    CURSOR_DIR="$HOME/Library/Application Support/Cursor/User"
    if [ -d "$CURSOR_DIR" ] || mkdir -p "$CURSOR_DIR" 2>/dev/null; then
      echo "Linking Cursor settings..."
      ln -sf "$DOTFILES_PATH/vscode/settings.json" "$CURSOR_DIR/settings.json"
    else
      echo "Couldn't create Cursor settings directory"
    fi
    
    echo "VS Code setup complete!"
  else
    echo "Skipping VS Code setup for non-macOS systems"
  fi
}

# Main installation
setup_vim
setup_vscode