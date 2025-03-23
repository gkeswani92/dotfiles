# Enhanced history search with FZF integration
# This provides a much more powerful way to search through command history

# Check if FZF is installed before configuring
if command -v fzf >/dev/null 2>&1; then
  # Function to search history with FZF
  function fzf-history-widget() {
    # Set local options for safety
    setopt localoptions pipefail no_aliases 2> /dev/null
    
    # Get output from fzf with expect for special keys
    local output
    output=$(fc -rln 1 | awk '!seen[$0]++' | 
      fzf --height 40% --reverse --tiebreak=index --query="${LBUFFER}" \
          --preview 'echo {}' --preview-window down:3:wrap \
          --bind 'ctrl-r:toggle-sort' \
          --expect=ctrl-e,ctrl-v)
    
    # Check if we got output
    if [ -z "$output" ]; then
      zle redisplay
      return 1
    fi
    
    # Split the output into lines
    local key=$(echo "$output" | head -1)
    local cmd=$(echo "$output" | tail -1)
    
    # Handle different keys
    if [ "$key" = ctrl-e ]; then
      # Edit mode - edit in temporary file
      echo "$cmd" > /tmp/fzf-edit
      ${EDITOR:-vim} /tmp/fzf-edit
      cmd=$(cat /tmp/fzf-edit)
      rm /tmp/fzf-edit
      BUFFER="$cmd"
      zle end-of-line
    elif [ "$key" = ctrl-v ]; then
      # View mode - show in pager
      echo "$cmd" | ${PAGER:-less}
      zle redisplay
      return 0
    else
      # Normal mode - just execute
      BUFFER="$cmd"
      zle accept-line
    fi
    
    zle redisplay
    return 0
  }
  
  # Register the widget and bind to Ctrl+R
  zle -N fzf-history-widget
  bindkey '^R' fzf-history-widget
  
  # Additional history-related keybindings
  bindkey '^P' up-line-or-search               # Ctrl+P to search history up
  bindkey '^N' down-line-or-search             # Ctrl+N to search history down
  bindkey "${terminfo[kcuu1]}" up-line-or-search   # Up arrow for history search
  bindkey "${terminfo[kcud1]}" down-line-or-search # Down arrow for history search
fi