#!/bin/bash

# Script to install programming fonts with ligatures
# This will install popular coding fonts with ligature support

echo "✅ Installing developer fonts with ligatures"

if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS installation using Homebrew
  
  # Helper function to check if a font cask is installed and install if needed
  brew_cask_install_if_needed() {
    local font_name=$1
    local font_cask=$2
    
    if brew list --cask "$font_cask" &>/dev/null; then
      echo "✅ $font_name already installed, skipping..."
    else
      echo "Installing $font_name..."
      brew install --cask "$font_cask"
    fi
  }
  
  # Install fonts directly
  brew_cask_install_if_needed "JetBrains Mono Nerd Font" "font-jetbrains-mono-nerd-font"
  brew_cask_install_if_needed "Fira Code Nerd Font" "font-fira-code-nerd-font"
  brew_cask_install_if_needed "Cascadia Code" "font-cascadia-code"
  brew_cask_install_if_needed "Hack Nerd Font" "font-hack-nerd-font"
  
  echo "Font installation complete!"
  echo "To use these fonts:"
  echo "1. Open iTerm2 → Preferences → Profiles → Text"
  echo "2. Select 'Font' and choose one of the installed fonts"
  echo "3. Make sure 'Use ligatures' is checked for ligature support"
else
  # Linux installation
  echo "This script is intended for macOS. For Linux systems, please run:"
  echo "Use a different font installation method for Linux."
fi