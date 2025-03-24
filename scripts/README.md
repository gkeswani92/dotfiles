# Scripts Directory

This directory contains utility scripts used for dotfiles installation and management.

## Contents

- `install_utils.sh`: Shared utility functions used by all installation scripts
- `install_devtools.sh`: Installation script for developer tools

## How It Works

The modular installation system works as follows:

1. The main `install.sh` in the root directory orchestrates the installation process
2. It calls component-specific installation scripts in each directory
3. Each component script is self-contained and handles its own installation
4. All scripts use shared utilities from `install_utils.sh`

## Adding New Components

To add a new component:

1. Create a new directory for your component
2. Add an `install.sh` script to that directory
3. In your script, source the utilities: `source "$DOTFILES_PATH/scripts/install_utils.sh"`
4. Update the main `install.sh` to call your new component's install script

## Utilities

The `install_utils.sh` script provides useful functions:

- `print_section`: Print formatted section headers
- `command_exists`: Check if a command exists
- `brew_install_if_needed`: Install a brew package if not already installed
- `ensure_dir`: Create a directory if it doesn't exist
- `source_file`: Safely source a file
- `run_script`: Run a script with proper permissions
- `detect_os`: Detect operating system
- `ensure_homebrew`: Install Homebrew if needed