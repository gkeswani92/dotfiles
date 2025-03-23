#!/bin/bash

# Script to install programming fonts with ligatures
# This will install popular coding fonts with ligature support

echo "✅ Installing developer fonts with ligatures"

if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS installation using Homebrew
  
  # Install fonts directly (no need for tap anymore)
  
  # Install JetBrains Mono Nerd Font (includes ligatures and icons)
  echo "Installing JetBrains Mono Nerd Font..."
  brew install --cask font-jetbrains-mono-nerd-font || true
  
  # Install Fira Code Nerd Font (popular for coding)
  echo "Installing Fira Code Nerd Font..."
  brew install --cask font-fira-code-nerd-font || true
  
  # Install Cascadia Code (Microsoft's developer font)
  echo "Installing Cascadia Code..."
  brew install --cask font-cascadia-code || true
  
  # Hack Nerd Font is another great option
  echo "Installing Hack Nerd Font..."
  brew install --cask font-hack-nerd-font || true
  
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