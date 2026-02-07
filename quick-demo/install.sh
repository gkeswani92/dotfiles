#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load nvm if available (needed for npm/quick in non-interactive shells)
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Install gum via brew if missing
if brew list gum &>/dev/null; then
  echo "✅ gum is already installed, skipping..."
else
  echo "Installing gum..."
  brew install gum
fi

# Check for quick (Shopify-only package, skip if unavailable)
if command -v quick &>/dev/null; then
  echo "✅ quick is already installed, skipping..."
else
  echo "⚠️  quick CLI not found (Shopify-only package), skipping..."
fi

# Symlink demo to /usr/local/bin
chmod +x "$SCRIPT_DIR/demo"
ln -sf "$SCRIPT_DIR/demo" /usr/local/bin/demo
echo "✅ Linked demo → /usr/local/bin/demo"
