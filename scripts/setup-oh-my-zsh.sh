#!/bin/bash
# Install/repair the framework without running an installer that rewrites .zshrc.
set -e
root="$HOME/.oh-my-zsh"
if [ -f "$root/oh-my-zsh.sh" ]; then
  echo 'Oh-My-Zsh already installed'
  exit 0
fi
mkdir -p "$HOME/.cache"
checkout=$(mktemp -d "$HOME/.cache/dotfiles-oh-my-zsh.XXXXXX")
trap 'rm -rf "$checkout"' EXIT
git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$checkout/framework"
test -f "$checkout/framework/oh-my-zsh.sh"
# Existing custom plugins/themes (including symlinks) survive a partial installation.
if [ -d "$root/custom" ]; then
  cp -Rp "$root/custom/." "$checkout/framework/custom/"
fi
if [ -e "$root" ] || [ -L "$root" ]; then
  mkdir -p "$HOME/.dotfiles-backup"
  backup=$(mktemp -d "$HOME/.dotfiles-backup/oh-my-zsh.XXXXXX")
  mv "$root" "$backup/.oh-my-zsh"
  echo "Preserved partial Oh-My-Zsh installation in $backup/.oh-my-zsh"
fi
mv "$checkout/framework" "$root"
echo 'Oh-My-Zsh framework installed; existing customizations preserved.'
