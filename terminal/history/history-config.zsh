# Enhanced history configuration
# Improves ZSH history with size increase, timestamps, and deduplication

# History file configuration
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000                    # Maximum events in internal history
SAVEHIST=50000                    # Maximum events in history file

# History command configuration
setopt EXTENDED_HISTORY           # Write timestamps to history
setopt HIST_EXPIRE_DUPS_FIRST     # Delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt HIST_IGNORE_DUPS           # Ignore duplicated commands
setopt HIST_IGNORE_ALL_DUPS       # Remove older duplicate entries from history
setopt HIST_IGNORE_SPACE          # Don't record commands starting with a space
setopt HIST_FIND_NO_DUPS          # Do not display duplicates when searching
setopt HIST_SAVE_NO_DUPS          # Don't write duplicate entries in the history file
setopt HIST_REDUCE_BLANKS         # Remove superfluous blanks from history
setopt HIST_VERIFY                # Show command with history expansion before running it
setopt SHARE_HISTORY              # Share history between sessions
setopt INC_APPEND_HISTORY         # Add commands to HISTFILE as they are typed
setopt HIST_FCNTL_LOCK            # Use modern file locking for better history file handling

# History deduplication functions
# Manually deduplicate history file to reduce size
function hist_deduplicate() {
  echo "Deduplicating history file..."
  # Create temporary file
  local tmp=$(mktemp)
  
  # Get all history entries, sort by timestamp, remove duplicates (keeping last instance)
  fc -ln 0 | awk '!x[$0]++' > $tmp
  
  # Clear history
  echo -n > $HISTFILE
  
  # Write deduplicated history back
  cat $tmp >> $HISTFILE
  
  # Clean up and reload history
  rm $tmp
  fc -R $HISTFILE
  
  echo "History deduplicated. Before: $(wc -l < $HISTFILE) lines, After: $(fc -l 1 | wc -l) lines"
}

# Automatically deduplicate on shell startup
# Uncomment the next line to enable auto-deduplication (can slow down startup)
# hist_deduplicate >/dev/null 2>&1

# History stats function
function hist_stats() {
  echo "History statistics:"
  echo "Current history size: $(fc -l 1 | wc -l) commands"
  echo "History file size: $(wc -l < $HISTFILE) lines"
  echo "Most used commands:"
  fc -ln 0 | awk '{print $1}' | sort | uniq -c | sort -rn | head -n 10
}

# Function to search history for a specific command
function hist_find() {
  if [ -z "$1" ]; then
    echo "Usage: hist_find <pattern>"
    return 1
  fi
  
  echo "Searching history for: $1"
  fc -ln 0 | grep -i "$1"
}

# Add a command to history without executing it
function hist_add() {
  print -s "$*"
  echo "Added to history: $*"
}