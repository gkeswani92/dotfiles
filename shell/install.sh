#!/bin/bash
set -e

# Load utility functions
source "$DOTFILES_PATH/scripts/install_utils.sh"

# Setup Zsh with Oh-My-Zsh
install_oh_my_zsh() {
  print_section "Setting up Zsh with Oh-My-Zsh"
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh-My-Zsh framework"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  else
    echo "Oh-My-Zsh already installed"
  fi

  echo "Installing Oh-My-Zsh custom plugins"
  ZSH_CUSTOM=${ZSH_CUSTOM:=$HOME/.oh-my-zsh/custom}
  
  [ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ] && \
    git clone https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/plugins/zsh-completions"
  
  [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && \
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  
  [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  
  [ ! -d "$ZSH_CUSTOM/plugins/zsh-history-substring-search" ] && \
    git clone https://github.com/zsh-users/zsh-history-substring-search.git "$ZSH_CUSTOM/plugins/zsh-history-substring-search"
  
  [ ! -d "$ZSH_CUSTOM/plugins/fzf-tab" ] && \
    git clone https://github.com/Aloxaf/fzf-tab "$ZSH_CUSTOM/plugins/fzf-tab"
  
  # Create symlink for .zshrc
  ln -sf "$DOTFILES_PATH/shell/.zshrc" "$HOME/.zshrc"
  
  echo "Zsh setup complete!"
}

# Configure shell history
setup_shell_history() {
  print_section "Configuring enhanced shell history"
  ensure_dir "$DOTFILES_PATH/terminal/history"
  
  # Add any history-specific setup here
  echo "Shell history configuration complete!"
}

# Main installation
install_oh_my_zsh
setup_shell_history