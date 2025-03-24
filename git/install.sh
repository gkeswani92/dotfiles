#!/bin/bash
set -e

# Load utility functions
source "$DOTFILES_PATH/scripts/install_utils.sh"

# Set up Git utilities and custom scripts
setup_git() {
  print_section "Setting up Git enhancements"
  
  # Create symlink for .gitconfig
  ln -sf "$DOTFILES_PATH/git/.gitconfig" "$HOME/.gitconfig"
  
  echo "Installing custom Git scripts for improved workflows"
  sudo cp -r "$DOTFILES_PATH/git/scripts/"* /usr/local/bin/
  sudo chmod 755 /usr/local/bin/git-*  # Set executable permissions
  
  # Install Git tools based on OS
  echo "Installing Git tools"
  OS=$(detect_os)
  
  if [ "$OS" = "macos" ]; then
    # macOS installation using Homebrew
    echo "Using Homebrew for macOS Git tools installation"
    ensure_homebrew
    
    # Install Git tools
    brew_install_if_needed git-interactive-rebase-tool
    brew_install_if_needed git-delta
    brew_install_if_needed git-absorb
  elif [ "$OS" = "linux" ]; then
    # Linux installation using dpkg
    echo "Using dpkg for Linux installations"
    sudo dpkg -i "$DOTFILES_PATH/git/plugins/"*.deb
    sudo apt install -y git-absorb
  else
    echo "Unsupported OS for Git tools installation"
  fi
  
  echo "Git setup complete!"
}

# Main installation
setup_git