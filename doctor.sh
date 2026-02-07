#!/bin/bash
#
# Dotfiles Doctor
# ---------------
# Diagnostic script that checks environment health.
# Run anytime to verify your dotfiles setup is working correctly.
#
# Usage: ./doctor.sh  or  dotfiles-doctor

DOTFILES_PATH="${DOTFILES_PATH:-$HOME/dotfiles}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

pass_count=0
warn_count=0
fail_count=0

pass() {
  echo -e "  ${GREEN}✓${NC} $1"
  ((pass_count++))
}

warn() {
  echo -e "  ${YELLOW}!${NC} $1"
  ((warn_count++))
}

fail() {
  echo -e "  ${RED}✗${NC} $1"
  ((fail_count++))
}

echo "Dotfiles Doctor"
echo "==============="
echo ""

# --- CLI Tools ---
echo "CLI Tools:"
for cmd in fzf starship eza bat fd zoxide atuin lazygit btop tmux nvim git delta; do
  if command -v "$cmd" &>/dev/null; then
    pass "$cmd"
  else
    fail "$cmd not found"
  fi
done
echo ""

# --- Symlinks ---
echo "Symlinks:"
check_symlink() {
  local link="$1" target="$2"
  local name
  name=$(basename "$link")
  if [ -L "$link" ]; then
    local actual
    actual=$(readlink "$link")
    if [ "$actual" = "$target" ]; then
      pass "$name -> $target"
    else
      warn "$name points to $actual (expected $target)"
    fi
  elif [ -e "$link" ]; then
    warn "$name exists but is not a symlink"
  else
    fail "$name missing"
  fi
}

check_symlink "$HOME/.gitconfig" "$DOTFILES_PATH/git/.gitconfig"
check_symlink "$HOME/.zshrc" "$DOTFILES_PATH/shell/.zshrc"
check_symlink "$HOME/.vimrc" "$DOTFILES_PATH/vim/.vimrc"
check_symlink "$HOME/.tmux.conf" "$DOTFILES_PATH/terminal/tmux/tmux.conf"
check_symlink "$HOME/.config/starship.toml" "$DOTFILES_PATH/terminal/prompt/starship/starship.toml"
check_symlink "$HOME/.config/atuin/config.toml" "$DOTFILES_PATH/terminal/atuin/config.toml"
check_symlink "$HOME/.config/nvim/init.lua" "$DOTFILES_PATH/nvim/init.lua"
echo ""

# --- Oh-My-Zsh & Plugins ---
echo "Oh-My-Zsh:"
if [ -d "$HOME/.oh-my-zsh" ]; then
  pass "Oh-My-Zsh installed"
else
  fail "Oh-My-Zsh not found"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
for plugin in zsh-autosuggestions zsh-syntax-highlighting fzf-tab; do
  if [ -d "$ZSH_CUSTOM/plugins/$plugin" ]; then
    pass "plugin: $plugin"
  else
    fail "plugin: $plugin not found"
  fi
done
echo ""

# --- TPM ---
echo "Tmux:"
if [ -d "$HOME/.tmux/plugins/tpm" ]; then
  pass "TPM installed"
else
  fail "TPM not found"
fi
echo ""

# --- Claude Code ---
echo "Claude Code:"
if [ -L "$HOME/.claude/CLAUDE.md" ]; then
  pass "Global CLAUDE.md linked"
else
  warn "Global CLAUDE.md not linked"
fi

skill_count=0
for skill_dir in "$DOTFILES_PATH/claude_configuration/skills"/*/; do
  skill_name=$(basename "$skill_dir")
  if [ -L "$HOME/.claude/skills/$skill_name" ]; then
    ((skill_count++))
  else
    warn "Skill not linked: $skill_name"
  fi
done
if [ "$skill_count" -gt 0 ]; then
  pass "$skill_count skills linked"
fi
echo ""

# --- Summary ---
total=$((pass_count + warn_count + fail_count))
echo -e "Summary: ${GREEN}${pass_count} passed${NC}, ${YELLOW}${warn_count} warnings${NC}, ${RED}${fail_count} failed${NC} (${total} checks)"

if [ "$fail_count" -gt 0 ]; then
  exit 1
fi
exit 0
