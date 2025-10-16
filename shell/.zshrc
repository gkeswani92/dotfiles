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

# asdf tool version manager
if [ -d "$HOME/.asdf" ]; then
  . "$HOME/.asdf/asdf.sh"
  # append completions to fpath
  fpath=(${ASDF_DIR}/completions $fpath)
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

# Display welcome screen on new terminal sessions
if [[ $- == *i* ]]; then  # Only run in interactive shells
  $DOTFILES_PATH/terminal/welcome.sh
fi

# Potentially dev related commands that were added to the dotfiles
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

[[ -f /opt/dev/sh/chruby/chruby.sh ]] && { type chruby >/dev/null 2>&1 || chruby () { source /opt/dev/sh/chruby/chruby.sh; chruby "$@"; } }
[[ -x /opt/homebrew/bin/brew ]] && eval $(/opt/homebrew/bin/brew shellenv)

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

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

# Auto-link global Claude Code commands to project-specific .claude/commands
link_claude_commands() {
  if [ -d .claude ]; then
    mkdir -p .claude/commands
    for cmd in $DOTFILES_PATH/.claude/commands/*.md; do
      [ -f "$cmd" ] && ln -sf "$cmd" .claude/commands/
    done
  fi
}

# Run when changing directories (oh-my-zsh compatible)
chpwd_functions+=(link_claude_commands)

# Run on shell startup if we're in a Claude Code project
link_claude_commands


# Added by tec agent
[[ -x /Users/gaurav/.local/state/tec/profiles/base/current/global/init ]] && eval "$(/Users/gaurav/.local/state/tec/profiles/base/current/global/init zsh)"
