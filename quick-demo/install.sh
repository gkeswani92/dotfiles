#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
source "$SCRIPT_DIR/../scripts/profile.sh"
profile=$(dotfiles_read_profile)
if [ "$profile" != work ]; then
  echo 'Quick Demo is work-only; no changes made.'
  exit 0
fi

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

# User-owned bin directory; never overwrite an independent local command.
mkdir -p "$HOME/.local/bin"
demo_path="$HOME/.local/bin/demo"
if [ -e "$demo_path" ] || [ -L "$demo_path" ]; then
  if [ ! -L "$demo_path" ] || ! [ "$demo_path" -ef "$SCRIPT_DIR/demo" ]; then
    echo "Conflict: $demo_path; use install.sh --replace-conflicts to archive and replace it." >&2
    exit 1
  fi
else
  ln -s "$SCRIPT_DIR/demo" "$demo_path"
fi
echo "✅ Linked demo → $demo_path"
