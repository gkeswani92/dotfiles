# Terminal Enhancements

This directory contains configurations and scripts to enhance your terminal experience.

## Contents

- `aliases.zsh`: Productivity-boosting shell aliases and functions
- `fonts/`: Terminal font configuration and installation scripts
- `prompt/`: Shell prompt configuration (Starship)
- `themes/`: Terminal color schemes
- `welcome.sh`: Terminal welcome screen

## Terminal Aliases (`aliases.zsh`)

The aliases file provides shortcuts for common operations:

- **Navigation**:
  - `..`, `...`, `....`: Go up one, two, or three directories
  - `~`: Go to home directory

- **File Operations**:
  - `ls`, `ll`, `la`: Enhanced file listings with icons and colors
  - `tree`: Directory structure in tree format
  - `mkdir`, `cp`, `mv`, `rm`: Safe versions with confirmation

- **Git Shortcuts**:
  - `g`: Git status
  - `gs`: Git status
  - `gl`: Git log with graph

- **Utility Functions**:
  - `mkcd`: Create and enter directory
  - `extract`: Extract any archive format
  - `weather`: Show weather forecast
  - `serve`: Start HTTP server in current directory

## Terminal Fonts (`fonts/`)

Configuration for developer-friendly fonts with programming ligatures:

- JetBrains Mono Nerd Font
- Fira Code Nerd Font
- Cascadia Code

The `install-fonts.sh` script automates the installation process.

## Shell Prompt (`prompt/`)

Starship prompt configuration for a beautiful and informative command line prompt.

Features:
- Shows git branch and status
- Displays programming language versions
- Indicates command execution time
- Customizable layout and colors

## Terminal Themes (`themes/`)

Color schemes for iTerm2 and other terminal emulators:

- Catppuccin: Soothing pastel theme
- Tokyo Night: Cool dark theme inspired by Tokyo at night
- Dracula: Popular dark theme with vibrant accents
- Nord: Arctic, north-bluish color palette

## Welcome Screen (`welcome.sh`)

A colorful and informative welcome message displayed when opening a new terminal session:

- Current date and time
- Dotfiles status (branch and last commit)
- Current git project information
- Daily programming quote
- Quick reference of useful commands

## Usage

Most of these enhancements are automatically applied during dotfiles installation.

To manually:

1. Source aliases:
   ```bash
   source ~/dotfiles/terminal/aliases.zsh
   ```

2. Run welcome screen:
   ```bash
   ~/dotfiles/terminal/welcome.sh
   ```

3. Install fonts:
   ```bash
   ~/dotfiles/terminal/fonts/install-fonts.sh
   ```

4. Install Starship prompt:
   ```bash
   ~/dotfiles/terminal/prompt/starship/install-starship.sh
   ```