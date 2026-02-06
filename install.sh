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
sudo chmod 755 /usr/local/bin/git-cob /usr/local/bin/git-fixup /usr/local/bin/git-recent  # More secure permissions (rwxr-xr-x)

echo "Installing Git tools (interactive rebase, delta for better diffs)"
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS installation using Homebrew
  echo "Using Homebrew for macOS installations"

  # Function to check if a brew package is installed
  brew_install_if_needed() {
    if brew list "$1" &>/dev/null; then
      echo "✅ $1 is already installed, skipping..."
    else
      echo "Installing $1..."
      brew install "$1"
    fi
  }

  # Install Git tools
  brew_install_if_needed git-interactive-rebase-tool
  brew_install_if_needed git-delta
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
  echo "  - tmux (terminal multiplexer)"
  echo "  - fzf (fuzzy finder)"
  echo "  - eza (modern ls replacement)"
  echo "  - git-absorb (automatically create fixup commits)"
  echo "  - zellij (terminal multiplexer)"
  echo "  - fd (fast file search)"
  echo "  - lazygit (git TUI client)"
  echo "  - btop (system monitor)"
  echo "  - dua-cli (disk usage analyzer)"
  echo "  - atuin (enhanced shell history)"
  echo "  - fastfetch (system info display)"
  echo "  - thefuck (command correction)"

  # Install tools using our helper function
  brew_install_if_needed tmux
  brew_install_if_needed fzf
  brew_install_if_needed eza
  brew_install_if_needed git-absorb
  brew_install_if_needed zellij
  brew_install_if_needed fd
  brew_install_if_needed lazygit
  brew_install_if_needed btop
  brew_install_if_needed dua-cli
  brew_install_if_needed atuin
  brew_install_if_needed fastfetch
  brew_install_if_needed thefuck
else
  # Linux tools
  echo "Installing command-line tools via apt:"
  sudo apt-get install -y tmux
  sudo apt-get install -y fzf
  sudo apt-get install -y exa
  sudo apt install -y git-absorb
  sudo apt install -y fd-find
  sudo apt install -y btop
  # lazygit and dua-cli require manual installation on Linux
  echo "Note: lazygit and dua-cli may need manual installation on Linux"
  echo "  lazygit: https://github.com/jesseduffield/lazygit#installation"
  echo "  dua-cli: cargo install dua-cli"

  # Install atuin (shell history)
  echo "Installing atuin shell history..."
  curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | bash

  # Install fastfetch (system info display)
  echo "Installing fastfetch..."
  sudo apt install -y fastfetch 2>/dev/null || echo "Note: fastfetch may need manual installation on older Linux versions"

  # Install thefuck (command correction)
  echo "Installing thefuck..."
  pip3 install thefuck --user 2>/dev/null || sudo pip3 install thefuck
fi

# Step 5: Set up Vim configuration
print_section "Setting up Vim"
echo "Installing Vim color schemes and plugins"
mkdir -p $HOME/.vim/colors
cp $DOTFILES_PATH/vim/colors/* $HOME/.vim/colors/

# Step 5b: Set up Neovim with LazyVim
print_section "Setting up Neovim"
if [[ "$OSTYPE" == "darwin"* ]]; then
  brew_install_if_needed neovim
else
  echo "Installing Neovim..."
  sudo apt-get install -y neovim 2>/dev/null || {
    echo "Installing Neovim from appimage..."
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
    chmod u+x nvim.appimage
    sudo mv nvim.appimage /usr/local/bin/nvim
  }
fi

echo "Linking Neovim configuration (LazyVim)..."
mkdir -p $HOME/.config/nvim

# Check if symlinks already point to our dotfiles
if [ -L "$HOME/.config/nvim/init.lua" ] && [ "$(readlink $HOME/.config/nvim/init.lua)" = "$DOTFILES_PATH/nvim/init.lua" ]; then
  echo "Neovim symlinks already configured, skipping..."
else
  # Backup existing config if it's not empty and not already our symlinks
  if [ -d "$HOME/.config/nvim" ] && [ "$(ls -A $HOME/.config/nvim 2>/dev/null)" ]; then
    backup_name="nvim.backup.$(date +%Y%m%d%H%M%S)"
    echo "Backing up existing nvim config to ~/.config/$backup_name"
    mv $HOME/.config/nvim $HOME/.config/$backup_name
    mkdir -p $HOME/.config/nvim
  fi
  ln -sf $DOTFILES_PATH/nvim/init.lua $HOME/.config/nvim/init.lua
  ln -sf $DOTFILES_PATH/nvim/lua $HOME/.config/nvim/lua
  ln -sf $DOTFILES_PATH/nvim/.stylua.toml $HOME/.config/nvim/.stylua.toml
  echo "Neovim configured! Run 'nvim' to install plugins automatically."
fi

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

# Ensure config directories exist
mkdir -p ~/.config/zellij/layouts
mkdir -p ~/.config/atuin
mkdir -p ~/Library/Application\ Support/Code/User/

# Create all symlinks
ln -sf $DOTFILES_PATH/git/.gitconfig ~/.gitconfig
ln -sf $DOTFILES_PATH/ruby/.pryrc ~/.pryrc
ln -sf $DOTFILES_PATH/terminal/tmux/tmux.conf ~/.tmux.conf
ln -sf $DOTFILES_PATH/shell/.zshrc ~/.zshrc
ln -sf $DOTFILES_PATH/vim/.vimrc ~/.vimrc
ln -sf $DOTFILES_PATH/terminal/prompt/starship/starship.toml ~/.config/starship.toml
ln -sf $DOTFILES_PATH/terminal/atuin/config.toml ~/.config/atuin/config.toml

# Set up Zellij configuration
echo "Setting up Zellij configuration..."
ln -sf $DOTFILES_PATH/terminal/zellij/config.kdl ~/.config/zellij/config.kdl
ln -sf $DOTFILES_PATH/local-development/zellij/bp-full.kdl ~/.config/zellij/bp-full.kdl
ln -sf $DOTFILES_PATH/local-development/zellij/bp-orgs-only.kdl ~/.config/zellij/bp-orgs-only.kdl

# Link layout files
for layout in $DOTFILES_PATH/terminal/zellij/layouts/*.kdl; do
  layout_file=$(basename "$layout")
  ln -sf "$layout" "$HOME/.config/zellij/layouts/$layout_file"
done

# Editor settings (macOS only)
if [[ "$OSTYPE" == "darwin"* ]]; then
  # VS Code settings
  VSCODE_DIR="$HOME/Library/Application Support/Code/User"
  if [ -d "$VSCODE_DIR" ] || mkdir -p "$VSCODE_DIR" 2>/dev/null; then
    echo "Linking VS Code settings..."
    ln -sf $DOTFILES_PATH/vscode/settings.json "$VSCODE_DIR/settings.json"
    ln -sf $DOTFILES_PATH/vscode/keybindings.json "$VSCODE_DIR/keybindings.json"
  else
    echo "Couldn't create VS Code settings directory"
  fi

  # Cursor settings (VS Code fork)
  CURSOR_DIR="$HOME/Library/Application Support/Cursor/User"
  if [ -d "$CURSOR_DIR" ] || mkdir -p "$CURSOR_DIR" 2>/dev/null; then
    echo "Linking Cursor settings..."
    ln -sf $DOTFILES_PATH/vscode/settings.json "$CURSOR_DIR/settings.json"
    ln -sf $DOTFILES_PATH/vscode/keybindings.json "$CURSOR_DIR/keybindings.json"
  else
    echo "Couldn't create Cursor settings directory"
  fi
fi

# Install TPM (Tmux Plugin Manager)
echo "Setting up Tmux Plugin Manager..."
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm
  echo "TPM installed. Start tmux and press prefix + I to install plugins."
else
  echo "TPM already installed"
fi

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

# Step 11: Set up enhanced shell history
print_section "Configuring enhanced shell history"
echo "Setting up improved history search and deduplication"
mkdir -p $DOTFILES_PATH/terminal/history

# Step 12: Install developer tools (optional)
print_section "Installing additional developer tools"
echo "Checking for GitHub CLI to install GitHub Copilot..."
if command -v gh >/dev/null 2>&1; then
  echo "Installing GitHub Copilot CLI extension"
  gh extension install github/gh-copilot
else
  echo "GitHub CLI (gh) not found - skipping Copilot installation"
  echo "To install GitHub CLI later, visit: https://cli.github.com/"
fi

# Step 13: Set up Claude Code configuration
print_section "Setting up Claude Code"
echo "Configuring Claude Code skills and hooks"

# Create Claude Code directories
mkdir -p $HOME/.claude/skills

# Symlink global CLAUDE.md
echo "Linking global CLAUDE.md..."
ln -sf $DOTFILES_PATH/claude_configuration/CLAUDE.md $HOME/.claude/CLAUDE.md

# Symlink all skills from dotfiles
echo "Linking Claude Code skills..."
for skill_dir in $DOTFILES_PATH/claude_configuration/skills/*/; do
  skill_name=$(basename "$skill_dir")
  # Use ln -sfn: -s (symbolic), -f (force), -n (no-dereference - treat symlink to dir as file)
  ln -sfn "${skill_dir%/}" "$HOME/.claude/skills/$skill_name"
  echo "  Linked skill: $skill_name"
done

# Make hook scripts executable
echo "Setting up Claude Code hooks..."
if [ -d "$DOTFILES_PATH/claude_configuration/hooks" ]; then
  chmod +x $DOTFILES_PATH/claude_configuration/hooks/*.sh 2>/dev/null || true
  echo "  Made hook scripts executable"
fi

# Set up status line script
echo "Linking Claude Code status line..."
chmod +x $DOTFILES_PATH/claude_configuration/statusline.sh
ln -sf $DOTFILES_PATH/claude_configuration/statusline.sh $HOME/.claude/statusline.sh
echo "  Linked statusline.sh"

echo "Claude Code configuration complete!"

# Completion message
print_section "Installation Complete!"
echo "Your development environment has been successfully configured."
echo "Please restart your terminal or run 'source ~/.zshrc' to apply all changes."
echo ""
echo "To update your dotfiles in the future, run:"
echo "  cd $DOTFILES_PATH && git pull && ./install.sh"
