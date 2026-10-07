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

# Define the path to your dotfiles. Install from a local checkout.
export DOTFILES_PATH=$HOME/dotfiles

ai_only=0
config_only=0
dry_run=0
reconfigure=0
ai_args=()
for option in "$@"; do
  case "$option" in
    --ai-only) ai_only=1 ;;
    --config-only) config_only=1 ;;
    --dry-run) dry_run=1; ai_args+=(--dry-run) ;;
    --replace-conflicts) ai_args+=(--replace-conflicts) ;;
    --reconfigure-profile) reconfigure=1 ;;
    --help|-h)
      echo 'Usage: ./install.sh [--config-only | --ai-only] [--dry-run] [--replace-conflicts] [--reconfigure-profile]'
      echo '--config-only configures Git, Zellij layouts, and AI without installing software.'
      echo 'The machine role is asked once and stored in ~/.config/dotfiles/profile.'
      exit 0 ;;
    *) echo "Unknown option: $option" >&2; exit 1 ;;
  esac
done
if [ "$ai_only" = 1 ] && [ "$config_only" = 1 ]; then
  echo 'Choose --config-only or --ai-only, not both.' >&2; exit 1
fi
if [ "$dry_run" = 1 ] && [ "$ai_only" = 0 ]; then config_only=1; fi
if [ ! -f "$DOTFILES_PATH/scripts/profile.sh" ]; then
  echo 'Clone the latest dotfiles into ~/dotfiles, then run ./install.sh from the checkout.' >&2
  exit 1
fi
source "$DOTFILES_PATH/scripts/profile.sh"
dotfiles_select_profile "$reconfigure"
echo "Machine profile: $DOTFILES_MACHINE_PROFILE"
command -v python3 >/dev/null || { echo 'python3 is required for AI setup.' >&2; exit 1; }
# AI-only is a restricted operation, not a separate machine profile.
if [ "$ai_only" = 1 ]; then
  if grep -q '^# Managed by dotfiles/scripts/setup-machine.py$' "$HOME/.gitconfig" 2>/dev/null; then
    git_profile=$(git config --file "$HOME/.gitconfig" --get dotfiles.profile)
    if [ "$git_profile" != "$DOTFILES_MACHINE_PROFILE" ]; then
      echo 'Use --config-only --reconfigure-profile to change the machine role consistently across Git and AI.' >&2
      exit 1
    fi
  fi
  python3 "$DOTFILES_PATH/scripts/setup-ai.py" --profile "$DOTFILES_MACHINE_PROFILE" "${ai_args[@]}"
  exit 0
fi
command -v git >/dev/null || { echo 'git is required for machine configuration.' >&2; exit 1; }
machine_args=("${ai_args[@]}")
if [ "$config_only" = 0 ]; then machine_args+=(--full-config); fi
# Preflight both areas before changing either one or installing software.
if [ "$dry_run" = 0 ]; then
  for setup in setup-machine.py setup-ai.py; do
    check_args=("${ai_args[@]}")
    if [ "$setup" = setup-machine.py ]; then check_args=("${machine_args[@]}"); fi
    if ! plan=$(python3 "$DOTFILES_PATH/scripts/$setup" --profile "$DOTFILES_MACHINE_PROFILE" --check "${check_args[@]}"); then
      printf '%s\n' "$plan"
      exit 1
    fi
  done
fi
if [ "$config_only" = 1 ]; then
  python3 "$DOTFILES_PATH/scripts/setup-machine.py" --profile "$DOTFILES_MACHINE_PROFILE" "${ai_args[@]}"
  python3 "$DOTFILES_PATH/scripts/setup-ai.py" --profile "$DOTFILES_MACHINE_PROFILE" "${ai_args[@]}"
  exit 0
fi

if [[ "$OSTYPE" == "darwin"* ]] && ! command -v brew >/dev/null; then
  echo 'Homebrew is required for a full macOS installation. Install it first, or use --config-only.' >&2
  exit 1
fi
export PATH="$HOME/.local/bin:$PATH"
# Install missing packages without updating unrelated Homebrew taps on every rerun.
export HOMEBREW_NO_AUTO_UPDATE=1

# Print section headers in a consistent, visible format
print_section() {
  echo ""
  echo "========================================"
  echo "✅ $1"
  echo "========================================"
}

# Step 1: Ensure dotfiles are available locally
print_section "Setting up dotfiles repository"
echo "Using existing checkout: $DOTFILES_PATH"

# Step 2: Install and configure Oh-My-Zsh
print_section "Setting up Zsh with Oh-My-Zsh"
bash "$DOTFILES_PATH/scripts/setup-oh-my-zsh.sh"

echo "Installing Oh-My-Zsh custom plugins for enhanced functionality"
ZSH_CUSTOM=${ZSH_CUSTOM:=$HOME/.oh-my-zsh/custom}
[ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ] && git clone https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/plugins/zsh-completions"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-history-substring-search" ] && git clone https://github.com/zsh-users/zsh-history-substring-search.git "$ZSH_CUSTOM/plugins/zsh-history-substring-search"
[ ! -d "$ZSH_CUSTOM/plugins/fzf-tab" ] && git clone https://github.com/Aloxaf/fzf-tab "$ZSH_CUSTOM/plugins/fzf-tab"

# Step 3: Install Git utilities and custom scripts
print_section "Setting up Git enhancements"
echo 'Custom Git scripts will be linked into ~/.local/bin during configuration (no sudo).'

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
  sudo dpkg -i "$DOTFILES_PATH"/git/plugins/*.deb
fi

# Step 4: Install command-line utilities and tools
print_section "Installing development tools and utilities"
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS tools
  echo "Installing command-line tools via Homebrew:"
  echo "  - tmux (terminal multiplexer)"
  echo "  - fzf (fuzzy finder)"
  echo "  - eza (modern ls replacement)"
  echo "  - bat (syntax-highlighted file viewer)"
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
  brew_install_if_needed bat
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
  sudo apt-get install -y bat
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
echo 'Vim color schemes will be reconciled safely during configuration.'

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

# Step 6: Configure terminal aesthetics
print_section "Enhancing terminal appearance"
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "Setting up terminal color schemes"
  echo 'iTerm2 color presets (when installed) will be reconciled safely during configuration.'

  # Install developer fonts with ligatures
  echo "Installing programming fonts with ligatures"
  bash "$DOTFILES_PATH/terminal/fonts/install-fonts.sh"
fi

# Step 7: Create symlinks to configuration files
print_section "Creating configuration symlinks"
echo "Creating symlinks to connect dotfiles with their expected locations"

# All shared links use the same preflight/backups as profile-dependent config.
python3 "$DOTFILES_PATH/scripts/setup-machine.py" --profile "$DOTFILES_MACHINE_PROFILE" "${machine_args[@]}"

# Install TPM (Tmux Plugin Manager)
echo "Setting up Tmux Plugin Manager..."
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  echo "TPM installed. Start tmux and press prefix + I to install plugins."
else
  echo "TPM already installed"
fi

# Step 8: Install and configure shell prompt
print_section "Setting up shell prompt"
echo "Installing Starship prompt for a customized and informative shell experience"
bash "$DOTFILES_PATH/terminal/prompt/starship/install-starship.sh"

# Step 9: Set up terminal welcome screen
print_section "Configuring terminal welcome screen"
echo "Setting up welcome screen with useful information and quotes"

# Step 10: Install zoxide for smart directory navigation
print_section "Setting up zoxide directory jumper"
echo "Installing zoxide for smarter directory navigation"
bash "$DOTFILES_PATH/terminal/zoxide/install-zoxide.sh"

# Step 11: Set up enhanced shell history
print_section "Configuring enhanced shell history"
echo "Setting up improved history search and deduplication"

# Step 13: Install only the selected machine's AI resources.
print_section "Setting up AI resources ($DOTFILES_MACHINE_PROFILE)"
python3 "$DOTFILES_PATH/scripts/setup-ai.py" --profile "$DOTFILES_MACHINE_PROFILE" "${ai_args[@]}"

# Step 14: Shopify's demo publisher belongs only on work machines.
if [ "$DOTFILES_MACHINE_PROFILE" = work ]; then
  print_section "Setting up Quick Demo CLI"
  bash "$DOTFILES_PATH/quick-demo/install.sh"
fi

# Post-install verification
print_section "Verifying Installation"

verify_pass=0
verify_fail=0

check_pass() {
  echo -e "  \033[0;32m✓\033[0m $1"
  ((verify_pass+=1))
}

check_fail() {
  echo -e "  \033[0;31m✗\033[0m $1"
  ((verify_fail+=1))
}

# Check symlinks
echo "Symlinks:"
for pair in \
  "$HOME/.zshrc:$DOTFILES_PATH/shell/.zshrc" \
  "$HOME/.vimrc:$DOTFILES_PATH/vim/.vimrc" \
  "$HOME/.tmux.conf:$DOTFILES_PATH/terminal/tmux/tmux.conf" \
  "$HOME/.config/starship.toml:$DOTFILES_PATH/terminal/prompt/starship/starship.toml" \
  "$HOME/.config/atuin/config.toml:$DOTFILES_PATH/terminal/atuin/config.toml"; do
  link="${pair%%:*}"
  name=$(basename "$link")
  if [ -L "$link" ] && [ -e "$link" ]; then
    check_pass "$name"
  else
    check_fail "$name (missing or dangling)"
  fi
done

if python3 "$DOTFILES_PATH/scripts/setup-machine.py" --profile "$DOTFILES_MACHINE_PROFILE" --full-config --verify; then
  check_pass "Machine-scoped Git and layouts"
else
  check_fail "Machine configuration needs attention"
fi

if python3 "$DOTFILES_PATH/scripts/setup-ai.py" --profile "$DOTFILES_MACHINE_PROFILE" --verify; then
  check_pass "Machine-scoped AI resources"
else
  check_fail "AI configuration needs attention"
fi
if [ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
  check_pass "Oh-My-Zsh framework"
else
  check_fail "Oh-My-Zsh framework missing"
fi

# Check CLI tools
echo ""
echo "CLI Tools:"
cli_tools=(fzf starship eza bat fd zoxide atuin lazygit btop git-credit)
if [ "$DOTFILES_MACHINE_PROFILE" = work ]; then cli_tools+=(gum demo); fi
for cmd in "${cli_tools[@]}"; do
  if command -v "$cmd" &>/dev/null; then
    check_pass "$cmd"
  else
    check_fail "$cmd not found"
  fi
done

# Check Oh-My-Zsh plugins
echo ""
echo "Oh-My-Zsh Plugins:"
ZSH_CUSTOM=${ZSH_CUSTOM:=$HOME/.oh-my-zsh/custom}
for plugin in zsh-autosuggestions zsh-syntax-highlighting fzf-tab; do
  if [ -d "$ZSH_CUSTOM/plugins/$plugin" ]; then
    check_pass "$plugin"
  else
    check_fail "$plugin not found"
  fi
done

# Check TPM
echo ""
echo "Tmux:"
if [ -d "$HOME/.tmux/plugins/tpm" ]; then
  check_pass "TPM installed"
else
  check_fail "TPM not found"
fi

echo ""
echo -e "Results: \033[0;32m${verify_pass} passed\033[0m, \033[0;31m${verify_fail} failed\033[0m"

if [ "$verify_fail" -gt 0 ]; then
  echo 'Installation verification failed. Fix the checks above and rerun; installation is not complete.' >&2
  exit 1
fi

# Completion message
print_section "Installation Complete!"
echo "Your development environment has been successfully configured."
echo "Please restart your terminal or run 'source ~/.zshrc' to apply all changes."
echo ""
echo "To update your dotfiles in the future, run:"
echo "  cd $DOTFILES_PATH && git pull && ./install.sh"
