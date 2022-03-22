# If you come from bash you might have to change your $PATH.
if ! [ $SPIN ]; then
  export PATH=$HOME/bin:/usr/local/bin:$PATH
  export PATH=/usr/local/share/chruby:$PATH
fi

# Path to your oh-my-zsh installation.
if [ $SPIN ]; then
  export ZSH="/home/spin/.oh-my-zsh"
else
  export ZSH="/Users/gaurav/.oh-my-zsh"
fi

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  zsh-completions
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# User configuration

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
alias style="bin/style --include-branch-commits"
alias check="bin/style --include-branch-commits;bin/srb typecheck -a"
alias up="bundle install;bin/rails db:migrate"
alias ls="exa --long --header"

# load dev, but only if present and the shell is interactive
if [[ -f /opt/dev/dev.sh ]] && [[ $- == *i* ]]; then
  source /opt/dev/dev.sh
fi

if ! [ $SPIN ]; then
  if [ -e /Users/gaurav/.nix-profile/etc/profile.d/nix.sh ]; then . /Users/gaurav/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer
fi

eval "$(starship init zsh)"
