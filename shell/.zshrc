export DOTFILES_PATH=$HOME/dotfiles
export LANG='en_US.UTF-8'

# [Shopify] If you come from bash you might have to change your $PATH.
if ! [ $SPIN ]; then
  export PATH=$HOME/bin:/usr/local/bin:$PATH
  export PATH=/usr/local/share/chruby:$PATH
fi

# Path to your oh-my-zsh installation.
if [ $SPIN ]; then
  export ZSH="/home/spin/.oh-my-zsh"
else
  export ZSH="$HOME/.oh-my-zsh"
fi

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# auto-update behavior
zstyle ':omz:update' mode auto      # update automatically without asking

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
  zsh-history-substring-search
  fzf-tab
)

source $ZSH/oh-my-zsh.sh

# [Shopify] Load dev but only if present and the shell is interactive
if [[ -f /opt/dev/dev.sh ]] && [[ $- == *i* ]]; then
  source /opt/dev/dev.sh
fi

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='code --wait'
fi

# Check if .fzf.zsh exists and if yes, source it
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Lazy-load asdf tool version manager (speeds up shell startup)
# asdf will load on first use of asdf, ruby, python, golang, etc.
if [ -d "$HOME/.asdf" ]; then
  export ASDF_DIR="$HOME/.asdf"
  fpath=(${ASDF_DIR}/completions $fpath)

  _load_asdf() {
    unfunction asdf ruby python python3 pip pip3 golang go 2>/dev/null
    . "$ASDF_DIR/asdf.sh"
  }

  asdf() { _load_asdf && asdf "$@" }
  ruby() { _load_asdf && ruby "$@" }
  python() { _load_asdf && python "$@" }
  python3() { _load_asdf && python3 "$@" }
  pip() { _load_asdf && pip "$@" }
  pip3() { _load_asdf && pip3 "$@" }
  golang() { _load_asdf && golang "$@" }
  go() { _load_asdf && go "$@" }
fi

# Initialise completions with ZSH's compinit
autoload -Uz compinit && compinit

# User configuration

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.

# Source enhanced aliases from dotfiles
if [ -f "$DOTFILES_PATH/terminal/aliases.zsh" ]; then
  source "$DOTFILES_PATH/terminal/aliases.zsh"
fi

# Source zoxide configuration for smart directory navigation
if [ -f "$DOTFILES_PATH/terminal/zoxide/config.zsh" ]; then
  source "$DOTFILES_PATH/terminal/zoxide/config.zsh"
fi

# Source improved history configuration with deduplication
if [ -f "$DOTFILES_PATH/terminal/history/history-config.zsh" ]; then
  source "$DOTFILES_PATH/terminal/history/history-config.zsh"
fi

# Source FZF history search enhancement
if [ -f "$DOTFILES_PATH/terminal/history/fzf-history.zsh" ]; then
  source "$DOTFILES_PATH/terminal/history/fzf-history.zsh"
fi

# Local development environment aliases
alias bp-full-local-dev="zellij --layout  ~/.config/zellij/bp-full.kdl"
alias bp-orgs-only-dev="zellij --layout ~/.config/zellij/bp-orgs-only.kdl"

# Initialize Starship prompt
eval "$(starship init zsh)"

# Display welcome screen on new terminal sessions (deferred for faster prompt)
# The welcome message shows after the prompt appears
if [[ $- == *i* ]]; then  # Only run in interactive shells
  {
    sleep 0.1
    $DOTFILES_PATH/terminal/welcome.sh
  } &!
fi

# Potentially dev related commands that were added to the dotfiles
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

[[ -f /opt/dev/sh/chruby/chruby.sh ]] && { type chruby >/dev/null 2>&1 || chruby () { source /opt/dev/sh/chruby/chruby.sh; chruby "$@"; } }
[[ -x /opt/homebrew/bin/brew ]] && eval $(/opt/homebrew/bin/brew shellenv)

# Lazy-load NVM (speeds up shell startup by ~200-400ms)
# NVM will load on first use of node, npm, npx, or nvm commands
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  _load_nvm() {
    unfunction nvm node npm npx 2>/dev/null
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  }

  nvm() { _load_nvm && nvm "$@" }
  node() { _load_nvm && node "$@" }
  npm() { _load_nvm && npm "$@" }
  npx() { _load_nvm && npx "$@" }
fi

#compdef gt
###-begin-gt-completions-###
#
# yargs command completion script
#
# Installation: gt completion >> ~/.zshrc
#    or gt completion >> ~/.zprofile on OSX.
#
_gt_yargs_completions()
{
  local reply
  local si=$IFS
  IFS=$'
' reply=($(COMP_CWORD="$((CURRENT-1))" COMP_LINE="$BUFFER" COMP_POINT="$CURSOR" gt --get-yargs-completions "${words[@]}"))
  IFS=$si
  _describe 'values' reply
}
compdef _gt_yargs_completions gt
###-end-gt-completions-###

# Link dotfiles Claude commands to global ~/.claude/commands directory
link_global_claude_commands() {
  mkdir -p ~/.claude/commands
  for cmd in $DOTFILES_PATH/claude_configuration/commands/*.md; do
    [ -f "$cmd" ] && ln -sf "$cmd" ~/.claude/commands/
  done
}

# Link global CLAUDE.md configuration file
link_global_claude_config() {
  mkdir -p ~/.config/claude
  if [ -f "$DOTFILES_PATH/claude_configuration/CLAUDE.md" ]; then
    ln -sf "$DOTFILES_PATH/claude_configuration/CLAUDE.md" ~/.config/claude/CLAUDE.md
  fi
}

# Run once on shell startup to ensure commands and config are linked
link_global_claude_commands
link_global_claude_config


# Added by tec agent
[[ -x /Users/gaurav/.local/state/tec/profiles/base/current/global/init ]] && eval "$(/Users/gaurav/.local/state/tec/profiles/base/current/global/init zsh)"
