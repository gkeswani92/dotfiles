#!/bin/bash

# Script to install and configure Starship prompt
# https://starship.rs/

echo "✅ Installing Starship prompt"

if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS installation using Homebrew
  if command -v brew >/dev/null 2>&1; then
    echo "Installing Starship via Homebrew..."
    brew install starship
  else
    echo "Homebrew not found. Installing Starship directly..."
    curl -sS https://starship.rs/install.sh | sh
  fi
else
  # Linux installation
  echo "Installing Starship..."
  curl -sS https://starship.rs/install.sh | sh
fi

# Configure Starship
echo "Configuring Starship..."
mkdir -p ~/.config
ln -sf "$(dirname "$0")/starship.toml" ~/.config/starship.toml

# Detect shell and add Starship initialization
DETECTED_SHELL="$(basename "$SHELL")"
case "$DETECTED_SHELL" in
  zsh)
    # Check if Starship is already initialized in .zshrc
    if ! grep -q "starship init" ~/.zshrc; then
      echo "Adding Starship initialization to .zshrc..."
      echo '# Initialize Starship prompt' >> ~/.zshrc
      echo 'eval "$(starship init zsh)"' >> ~/.zshrc
    else
      echo "Starship already initialized in .zshrc"
    fi
    ;;
  bash)
    # Check if Starship is already initialized in .bashrc
    if ! grep -q "starship init" ~/.bashrc; then
      echo "Adding Starship initialization to .bashrc..."
      echo '# Initialize Starship prompt' >> ~/.bashrc
      echo 'eval "$(starship init bash)"' >> ~/.bashrc
    else
      echo "Starship already initialized in .bashrc"
    fi
    ;;
  *)
    echo "Unsupported shell: $DETECTED_SHELL"
    echo "Please manually add the following to your shell configuration:"
    echo 'eval "$(starship init '"$DETECTED_SHELL"')"'
    ;;
esac

echo "✅ Starship prompt installation complete!"
echo "You may need to restart your terminal or run 'source ~/.zshrc' for changes to take effect."
echo "Your shell prompt should now be using Starship with a custom configuration."