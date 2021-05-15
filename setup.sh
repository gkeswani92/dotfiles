ln -sf ~/dotfiles/tmux.conf ~/.tmux.conf

echo "Installing Oh My ZSH"
sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
