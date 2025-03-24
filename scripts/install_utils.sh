#!/bin/bash
# Utility functions for dotfiles installation

# Print section headers in a consistent, visible format
print_section() {
  echo ""
  echo "========================================"
  echo "✅ $1"
  echo "========================================"
}

# Check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to check if a brew package is installed
brew_install_if_needed() {
  if brew list "$1" &>/dev/null; then
    echo "✅ $1 is already installed, skipping..."
  else
    echo "Installing $1..."
    brew install "$1"
  fi
}

# Function to create directory if it doesn't exist
ensure_dir() {
  if [ ! -d "$1" ]; then
    mkdir -p "$1"
    echo "Created directory: $1"
  fi
}

# Function to source a file safely
source_file() {
  if [ -f "$1" ]; then
    source "$1"
  else
    echo "Warning: File $1 not found, skipping..."
  fi
}

# Function to run a script with proper permissions
run_script() {
  local script="$1"
  if [ -f "$script" ]; then
    chmod +x "$script"
    "$script"
  else
    echo "Warning: Script $script not found, skipping..."
  fi
}

# Detect OS
detect_os() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "macos"
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "linux"
  else
    echo "unknown"
  fi
}

# Check for Homebrew on macOS
ensure_homebrew() {
  if ! command_exists brew; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    echo "Homebrew already installed"
  fi
}