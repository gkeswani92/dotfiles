#!/bin/bash
#
# Dotfiles Installation Script
# ----------------------------
# This script sets up a complete development environment by:
# - Installing Oh-My-Zsh and plugins
# - Setting up Git with custom scripts and tools
# - Configuring terminal aesthetics (themes, fonts, prompt)
# - Creating symlinks to configuration files
# - Installing development tools and utilities
#
# Usage: ./install.sh
#
# The -e option causes the script to exit immediately if any command fails
set -e

# Define the path to your dotfiles
export DOTFILES_PATH=$HOME/dotfiles

# Print section headers in a consistent, visible format
print_section() {
  echo ""
  echo "========================================"
  echo "✅ $1"
  echo "========================================"
}

# Step 1: Ensure dotfiles are available locally
print_section "Setting up dotfiles repository"
if test -d $DOTFILES_PATH; then
  echo "Dotfiles already cloned to $DOTFILES_PATH"
else
  echo "Cloning dotfiles repository to $DOTFILES_PATH"
  git clone https://github.com/gkeswani92/dotfiles $DOTFILES_PATH
fi

# Step 2: Install and configure Oh-My-Zsh
print_section "Setting up Zsh with Oh-My-Zsh"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing Oh-My-Zsh framework"
  sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "Oh-My-Zsh already installed"
fi

echo "Installing Oh-My-Zsh custom plugins for enhanced functionality"
ZSH_CUSTOM=${ZSH_CUSTOM:=$HOME/.oh-my-zsh/custom}
[ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ] && git clone https://github.com/zsh-users/zsh-completions $ZSH_CUSTOM/plugins/zsh-completions
[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
[ ! -d "$ZSH_CUSTOM/plugins/zsh-history-substring-search" ] && git clone https://github.com/zsh-users/zsh-history-substring-search.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
[ ! -d "$ZSH_CUSTOM/plugins/fzf-tab" ] && git clone https://github.com/Aloxaf/fzf-tab ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-tab

# Step 3: Install Git utilities and custom scripts
print_section "Setting up Git enhancements"
echo "Installing custom Git scripts for improved workflows"
sudo cp -r $DOTFILES_PATH/git/scripts/* /usr/local/bin/
sudo chmod 755 /usr/local/bin/git-cob  # More secure permissions (rwxr-xr-x)

echo "Installing Git tools (interactive rebase, delta for better diffs)"
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS installation using Homebrew
  echo "Using Homebrew for macOS installations"
  brew install git-interactive-rebase-tool
  brew install git-delta
else
  # Linux installation using dpkg
  echo "Using dpkg for Linux installations"
  sudo dpkg -i $DOTFILES_PATH/git/plugins/*.deb
fi

# Step 4: Install command-line utilities and tools
print_section "Installing development tools and utilities"
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS tools
  echo "Installing command-line tools via Homebrew:"
  echo "  - fzf (fuzzy finder)"
  echo "  - eza (modern ls replacement)"
  echo "  - git-absorb (automatically create fixup commits)"
  echo "  - zellij (terminal multiplexer)"
  brew install fzf
  brew install eza
  brew install git-absorb
  brew install zellij
else
  # Linux tools
  echo "Installing command-line tools via apt:"
  sudo apt-get install -y fzf
  sudo apt-get install -y exa
  sudo apt install -y git-absorb
fi

# Step 5: Set up Vim configuration
print_section "Setting up Vim"
echo "Installing Vim color schemes and plugins"
mkdir -p $HOME/.vim/colors
cp $DOTFILES_PATH/vim/colors/* $HOME/.vim/colors/

# Step 6: Configure terminal aesthetics
print_section "Enhancing terminal appearance"
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "Setting up terminal color schemes"
  # Check if iTerm2 is installed
  if [ -d "/Applications/iTerm.app" ]; then
    # Create the defaults directory if it doesn't exist
    defaults_dir="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
    mkdir -p "$defaults_dir"

    # Create ColorPresets directory if it doesn't exist
    colorpresets_dir="$HOME/Library/Application Support/iTerm2/ColorPresets"
    mkdir -p "$colorpresets_dir"

    # Copy themes to iTerm2 color presets directory
    cp $DOTFILES_PATH/terminal/themes/*.itermcolors "$colorpresets_dir/" 2>/dev/null || true
    echo "Terminal themes installed. Open iTerm2 preferences → Profiles → Colors → Color Presets to apply them."
  else
    echo "iTerm2 not found. Themes are available in $DOTFILES_PATH/terminal/themes/ for manual installation."
  fi
  
  # Install developer fonts with ligatures
  echo "Installing programming fonts with ligatures"
  chmod +x $DOTFILES_PATH/terminal/fonts/install-fonts.sh
  $DOTFILES_PATH/terminal/fonts/install-fonts.sh
fi

# Step 7: Create symlinks to configuration files
print_section "Creating configuration symlinks"
echo "Creating symlinks to connect dotfiles with their expected locations"

# Ensure Zellij config directory exists
mkdir -p ~/.config/zellij

# Create all symlinks
ln -sf $DOTFILES_PATH/git/.gitconfig ~/.gitconfig
ln -sf $DOTFILES_PATH/ruby/.pryrc ~/.pryrc
ln -sf $DOTFILES_PATH/shell/tmux.conf ~/.tmux.conf
ln -sf $DOTFILES_PATH/shell/.zshrc ~/.zshrc
ln -sf $DOTFILES_PATH/vim/.vimrc ~/.vimrc
ln -sf $DOTFILES_PATH/local-development/zellij/bp-full.kdl ~/.config/zellij/bp-full.kdl
ln -sf $DOTFILES_PATH/local-development/zellij/bp-orgs-only.kdl ~/.config/zellij/bp-orgs-only.kdl

# Step 8: Install and configure shell prompt
print_section "Setting up shell prompt"
echo "Installing Starship prompt for a customized and informative shell experience"
chmod +x $DOTFILES_PATH/terminal/prompt/starship/install-starship.sh
$DOTFILES_PATH/terminal/prompt/starship/install-starship.sh

# Step 9: Set up terminal welcome screen
print_section "Configuring terminal welcome screen"
echo "Setting up welcome screen with useful information and quotes"
chmod +x $DOTFILES_PATH/terminal/welcome.sh

# Step 10: Install zoxide for smart directory navigation
print_section "Setting up zoxide directory jumper"
echo "Installing zoxide for smarter directory navigation"
chmod +x $DOTFILES_PATH/terminal/zoxide/install-zoxide.sh
$DOTFILES_PATH/terminal/zoxide/install-zoxide.sh

# Step 11: Install developer tools (optional)
print_section "Installing additional developer tools"
echo "Checking for GitHub CLI to install GitHub Copilot..."
if command -v gh >/dev/null 2>&1; then
  echo "Installing GitHub Copilot CLI extension"
  gh extension install github/gh-copilot
else
  echo "GitHub CLI (gh) not found - skipping Copilot installation"
  echo "To install GitHub CLI later, visit: https://cli.github.com/"
fi

# Completion message
print_section "Installation Complete!"
echo "Your development environment has been successfully configured."
echo "Please restart your terminal or run 'source ~/.zshrc' to apply all changes."
echo ""
echo "To update your dotfiles in the future, run:"
echo "  cd $DOTFILES_PATH && git pull && ./install.sh"
