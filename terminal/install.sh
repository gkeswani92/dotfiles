#!/bin/bash
set -e

# Load utility functions
source "$DOTFILES_PATH/scripts/install_utils.sh"

# Install command-line utilities and tools
install_cli_tools() {
  print_section "Installing development tools and utilities"
  
  OS=$(detect_os)
  
  if [ "$OS" = "macos" ]; then
    # macOS tools
    echo "Installing command-line tools via Homebrew:"
    echo "  - fzf (fuzzy finder)"
    echo "  - eza (modern ls replacement)"
    echo "  - zellij (terminal multiplexer)"
    echo "  - ripgrep (fast grep alternative)"
    echo "  - fd (fast find alternative)"
    
    # Install tools
    ensure_homebrew
    brew_install_if_needed fzf
    brew_install_if_needed eza
    brew_install_if_needed zellij
    brew_install_if_needed ripgrep
    brew_install_if_needed fd
  elif [ "$OS" = "linux" ]; then
    # Linux tools
    echo "Installing command-line tools via apt:"
    sudo apt-get update
    sudo apt-get install -y fzf
    sudo apt-get install -y exa
    sudo apt-get install -y ripgrep
    sudo apt-get install -y fd-find
  fi
  
  echo "CLI tools installation complete!"
}

# Configure terminal aesthetics
setup_terminal_themes() {
  print_section "Enhancing terminal appearance"
  
  OS=$(detect_os)
  
  if [ "$OS" = "macos" ]; then
    echo "Setting up terminal color schemes"
    # Check if iTerm2 is installed
    if [ -d "/Applications/iTerm.app" ]; then
      # Create the directories if they don't exist
      defaults_dir="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
      ensure_dir "$defaults_dir"
      
      colorpresets_dir="$HOME/Library/Application Support/iTerm2/ColorPresets"
      ensure_dir "$colorpresets_dir"
      
      # Copy themes to iTerm2 color presets directory
      cp "$DOTFILES_PATH/terminal/themes/"*.itermcolors "$colorpresets_dir/" 2>/dev/null || true
      echo "Terminal themes installed. Open iTerm2 preferences → Profiles → Colors → Color Presets to apply them."
    else
      echo "iTerm2 not found. Themes are available in $DOTFILES_PATH/terminal/themes/ for manual installation."
    fi
    
    # Install developer fonts with ligatures
    echo "Installing programming fonts with ligatures"
    run_script "$DOTFILES_PATH/terminal/fonts/install-fonts.sh"
  fi
  
  echo "Terminal themes setup complete!"
}

# Install and configure terminal welcome screen
setup_welcome_screen() {
  print_section "Configuring terminal welcome screen"
  echo "Setting up welcome screen with useful information and quotes"
  run_script "$DOTFILES_PATH/terminal/welcome.sh"
  echo "Welcome screen setup complete!"
}

# Set up terminal multiplexer (tmux/zellij)
setup_terminal_multiplexers() {
  print_section "Setting up terminal multiplexers"
  
  # Setup tmux
  echo "Setting up tmux configuration..."
  ln -sf "$DOTFILES_PATH/terminal/tmux/tmux.conf" "$HOME/.tmux.conf"
  
  # Setup zellij
  echo "Setting up Zellij configuration..."
  ensure_dir "$HOME/.config/zellij/layouts"
  
  ln -sf "$DOTFILES_PATH/terminal/zellij/config.kdl" "$HOME/.config/zellij/config.kdl"
  ln -sf "$DOTFILES_PATH/local-development/zellij/bp-full.kdl" "$HOME/.config/zellij/bp-full.kdl"
  ln -sf "$DOTFILES_PATH/local-development/zellij/bp-orgs-only.kdl" "$HOME/.config/zellij/bp-orgs-only.kdl"
  
  # Link layout files
  for layout in "$DOTFILES_PATH/terminal/zellij/layouts/"*.kdl; do
    if [ -f "$layout" ]; then
      layout_file=$(basename "$layout")
      ln -sf "$layout" "$HOME/.config/zellij/layouts/$layout_file"
    fi
  done
  
  echo "Terminal multiplexers setup complete!"
}

# Setup Neovim
setup_neovim() {
  print_section "Setting up Neovim with LazyVim"
  echo "Installing and configuring Neovim with LazyVim..."
  run_script "$DOTFILES_PATH/terminal/neovim/install-neovim.sh"
  echo "Neovim setup complete!"
}

# Setup Zoxide for smart directory navigation
setup_zoxide() {
  print_section "Setting up zoxide directory jumper"
  echo "Installing zoxide for smarter directory navigation"
  run_script "$DOTFILES_PATH/terminal/zoxide/install-zoxide.sh"
  echo "Zoxide setup complete!"
}

# Setup shell prompt (Starship)
setup_shell_prompt() {
  print_section "Setting up shell prompt"
  echo "Installing Starship prompt for a customized and informative shell experience"
  run_script "$DOTFILES_PATH/terminal/prompt/starship/install-starship.sh"
  echo "Shell prompt setup complete!"
}

# Main installation
install_cli_tools
setup_terminal_themes
setup_welcome_screen
setup_terminal_multiplexers
setup_neovim
setup_zoxide
setup_shell_prompt