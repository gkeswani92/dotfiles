#/bin/bash

# The -e option instructs the shell to exit immediately if any command it executes fails
# (returns a non-zero status).
set -e

export DOTFILES_PATH=$HOME/dotfiles

echo "Installing dotfiles"
if test -d $DOTFILES_PATH; then
  echo "✅ Dotfiles already installed"
else
  echo "✅ Cloning dotfiles"
  git clone https://github.com/gkeswani92/dotfiles $DOTFILES_PATH
fi

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "✅ Installing Oh My ZSH"
  sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

echo "✅ Installing Oh My ZSH custom plugins"
ZSH_CUSTOM=${ZSH_CUSTOM:=$HOME/.oh-my-zsh/custom}
[ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ] && git clone https://github.com/zsh-users/zsh-completions $ZSH_CUSTOM/plugins/zsh-completions
[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
[ ! -d "$ZSH_CUSTOM/plugins/zsh-history-substring-search" ] && git clone https://github.com/zsh-users/zsh-history-substring-search.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-history-substring-search

echo "✅ Install custom git scripts"
sudo cp -r $DOTFILES_PATH/git/scripts/* /usr/local/bin/
sudo chmod 777 /usr/local/bin/git-cob

echo "✅ Installing Spin Cursor extension"
sudo chmod +x $DOTFILES_PATH/cursor/install-spin-cursor-extension
$DOTFILES_PATH/cursor/install-spin-cursor-extension

echo "✅ Install local git plugins (like interactive rebase, delta)"
sudo dpkg -i $DOTFILES_PATH/git/plugins/*.deb

echo "✅ Install remote plugins (git-absorb, gh-copilot, exa)"
if [[ "$OSTYPE" == "darwin"* ]]; then
  brew install fzf
  brew install eza
  brew install git-absorb
  brew install zellij
else
  sudo apt-get install -y fzf
  sudo apt-get install -y exa
  sudo apt install -y git-absorb
fi

echo "✅ Install vim plugins and colors"
mkdir -p $HOME/.vim/colors
cp $DOTFILES_PATH/vim/colors/* $HOME/.vim/colors/

echo "✅ Creating symlinks to dotfiles"
ln -sf $DOTFILES_PATH/git/.gitconfig ~/.gitconfig
ln -sf $DOTFILES_PATH/ruby/.pryrc ~/.pryrc
ln -sf $DOTFILES_PATH/shell/tmux.conf ~/.tmux.conf
ln -sf $DOTFILES_PATH/shell/.zshrc ~/.zshrc
ln -sf $DOTFILES_PATH/vim/.vimrc ~/.vimrc
ln -sf $DOTFILES_PATH/local-development/zellij/bp-full.kdl ~/.config/zellij/bp-full.kdl
ln -sf $DOTFILES_PATH/local-development/zellij/bp-orgs-only.kdl ~/.config/zellij/bp-orgs-only.kdl

echo "✅Install Github Copilot CLI"
if command -v gh >/dev/null 2>&1; then
  gh extension install github/gh-copilot
else
  echo "gh is not installed"
fi
