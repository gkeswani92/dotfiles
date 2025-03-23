# Enhanced terminal aliases
# These provide colorful and informative command output

# Core aliases for better defaults
alias cp="cp -iv"        # Confirm before overwriting, verbose
alias mv="mv -iv"        # Confirm before overwriting, verbose
alias rm="rm -iv"        # Confirm before removal, verbose
alias mkdir="mkdir -pv"  # Make parent directories, verbose

# Navigation aliases
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ~="cd ~"

# Eza (improved ls) with icons and colors
# Uncomment these if you have eza installed
if command -v eza &> /dev/null; then
  # Basic listings with icons
  alias ls="eza --icons --group-directories-first"
  alias ll="eza --icons --group-directories-first -la"
  alias la="eza --icons --group-directories-first -a"
  
  # Show files sorted by modification time
  alias lt="eza --icons --group-directories-first -la --sort=modified"
  
  # Tree view with icons
  alias tree="eza --icons --group-directories-first --tree"
  
  # Show only directories
  alias lsd="eza --icons -D"
  
  # Show only files
  alias lsf="eza --icons -f"
  
  # Show file sizes in a human-readable format
  alias lsh="eza --icons -la --sort=size --reverse"
fi

# Colorful grep output
alias grep="grep --color=auto"
alias egrep="egrep --color=auto"
alias fgrep="fgrep --color=auto"

# Git shortcuts
alias g="git"
alias gs="git status"
alias gl="git log --oneline --graph --decorate --all"
alias gp="git pull"
alias gcm="git checkout main"

# Add color to commands
if command -v bat &> /dev/null; then
  alias cat="bat --style=plain"
fi

# Quick edit frequently accessed files
alias zshrc="$EDITOR ~/.zshrc"
alias dotfiles="cd $DOTFILES_PATH"

# Networking aliases
alias ip="ipconfig getifaddr en0"
alias ips="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"
alias speedtest="curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -"

# Process management
alias psg="ps aux | grep -v grep | grep -i -e"

# Quick folder creation and navigation
function mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Extract most archive formats
function extract() {
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2)   tar xjf $1     ;;
      *.tar.gz)    tar xzf $1     ;;
      *.bz2)       bunzip2 $1     ;;
      *.rar)       unrar e $1     ;;
      *.gz)        gunzip $1      ;;
      *.tar)       tar xf $1      ;;
      *.tbz2)      tar xjf $1     ;;
      *.tgz)       tar xzf $1     ;;
      *.zip)       unzip $1       ;;
      *.Z)         uncompress $1  ;;
      *.7z)        7z x $1        ;;
      *)           echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Weather in terminal
function weather() {
  curl -s "wttr.in/${1:-}"
}

# Simple HTTP server in current directory
function serve() {
  local port="${1:-8000}"
  python -m http.server "$port"
}

# Show disk usage sorted by size
alias duh="du -h -d 1 | sort -hr"

# Show directory sizes
alias dirsize="du -h --max-depth=1 | sort -hr"