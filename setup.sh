#!/bin/bash

ln -sf ~/dotfiles/tmux.conf ~/.tmux.conf
ln -sf ~/dotfiles/.gitconfig ~/.gitconfig

echo "Installing Oh My ZSH"
sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "Installing basic ZSH plugins"
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

echo "Creating symlink to .zshrc"
ln -sf ~/dotfiles/.zshrc ~/.zshrc

echo "Downloading and install the Interactive git rebase tool"
wget https://github.com/MitMaro/git-interactive-rebase-tool/releases/download/latest/git-interactive-rebase-tool-ubuntu_amd64.deb -P /tmp/
sudo dpkg -i /tmp/git-interactive-rebase-tool-ubuntu_amd64.deb
