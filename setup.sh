#!/bin/bash

ln -sf ~/dotfiles/shell/tmux.conf ~/.tmux.conf
ln -sf ~/dotfiles/git/.gitconfig ~/.gitconfig

echo "Installing Oh My ZSH"
sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "Installing basic ZSH plugins"
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

echo "Creating symlink to .zshrc"
ln -sf ~/dotfiles/shell/.zshrc ~/.zshrc

echo "Downloading and install the Interactive git rebase tool"
wget https://github.com/MitMaro/git-interactive-rebase-tool/releases/download/latest/git-interactive-rebase-tool-ubuntu_amd64.deb -P /tmp/
sudo dpkg -i /tmp/git-interactive-rebase-tool-ubuntu_amd64.deb

echo "Downloading and install the delta git diff tool"
wget https://github.com/dandavison/delta/releases/download/0.12.1/git-delta_0.12.1_amd64.deb -P /tmp/
sudo dpkg -i /tmp/git-delta_0.12.1_amd64.deb

echo "Install Interactive git checkout (and fzf for fuzzy search)"
sudo apt-get install fzf
sudo ln -sf ~/dotfiles/git/git-cob /usr/local/bin/git-cob
sudo chmod 777 /usr/local/bin/git-cob
