#!/bin/bash
set -e

# Load utility functions
source "$DOTFILES_PATH/scripts/install_utils.sh"

# Install additional developer tools
install_dev_tools() {
  print_section "Installing additional developer tools"
  
  # Install GitHub CLI and Copilot
  echo "Checking for GitHub CLI to install GitHub Copilot..."
  if command_exists gh; then
    echo "Installing GitHub Copilot CLI extension"
    gh extension install github/gh-copilot
  else
    echo "GitHub CLI (gh) not found - skipping Copilot installation"
    echo "To install GitHub CLI later, visit: https://cli.github.com/"
  fi
  
  echo "Developer tools setup complete!"
}

# Main installation
install_dev_tools