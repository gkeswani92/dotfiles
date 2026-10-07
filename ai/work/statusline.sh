#!/bin/bash
#
# Claude Code Custom Status Line
# Displays: directory, git info, model, context %, lines changed, duration
#

# Read JSON from stdin and flatten to single line for easier parsing
json=$(cat | tr '\n' ' ' | tr -s ' ')

# Extract values - handles both flat and nested JSON
get_value() {
  echo "$json" | grep -oE "\"$1\": *(\"[^\"]*\"|[0-9.]+|null)" | head -1 | sed 's/.*: *//' | tr -d '"'
}

# Extract data
cwd=$(get_value "cwd")
model_name=$(get_value "display_name")
context_pct=$(get_value "remaining_percentage")
lines_added=$(get_value "total_lines_added")
lines_removed=$(get_value "total_lines_removed")
duration_ms=$(get_value "total_duration_ms")

# Pastel ANSI colors (256-color palette)
CYAN="\033[38;5;116m"      # pastel cyan
GREEN="\033[38;5;114m"     # pastel green
PEACH="\033[38;5;216m"     # pastel peach/orange
PURPLE="\033[38;5;183m"    # pastel purple
BLUE="\033[38;5;111m"      # pastel blue
ORANGE="\033[38;5;209m"    # orange for warnings
RED="\033[38;5;174m"       # pastel red
GRAY="\033[38;5;245m"      # gray
RESET="\033[0m"

# Format directory (shorten home to ~)
if [ -n "$cwd" ]; then
  dir="${cwd/#$HOME/~}"
  dir_name=$(basename "$dir")
else
  dir_name="~"
fi

# Get git info if in a git repo
git_info=""
if [ -n "$cwd" ] && [ -d "$cwd" ]; then
  cd "$cwd" 2>/dev/null
  if git rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)

    # Check for dirty state
    dirty=""
    if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
      dirty="*"
    fi

    # Check commits ahead of upstream
    ahead=""
    upstream=$(git rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)
    if [ -n "$upstream" ]; then
      ahead_count=$(git rev-list --count '@{upstream}..HEAD' 2>/dev/null)
      if [ -n "$ahead_count" ] && [ "$ahead_count" -gt 0 ]; then
        ahead=" ${GREEN}↑${ahead_count}${RESET}"
      fi
    fi

    # Check if in a worktree
    worktree=""
    git_dir=$(git rev-parse --git-dir 2>/dev/null)
    if [[ "$git_dir" == *"/worktrees/"* ]]; then
      # Get the worktree directory name (parent of git root for src-based repos)
      worktree_root=$(git rev-parse --show-toplevel 2>/dev/null)
      worktree_parent=$(dirname "$worktree_root")
      worktree_name=$(basename "$worktree_parent")
      worktree=" ${GRAY}[${worktree_name}]${RESET}"
    fi

    # Color branch based on dirty state
    if [ -n "$dirty" ]; then
      git_info=" ${PEACH}${branch}${dirty}${RESET}${ahead}${worktree}"
    else
      git_info=" ${GREEN}${branch}${RESET}${ahead}${worktree}"
    fi
  fi
fi

# Format model name
model_display=""
if [ -n "$model_name" ]; then
  model_display="${PURPLE}${model_name}${RESET}"
fi

# Format context percentage (color based on usage)
context_display=""
if [ -n "$context_pct" ] && [ "$context_pct" != "null" ]; then
  pct_int=${context_pct%.*}
  if [ -n "$pct_int" ] && [ "$pct_int" -lt 30 ]; then
    context_display="${ORANGE}${context_pct}%${RESET}"
  else
    context_display="${BLUE}${context_pct}%${RESET}"
  fi
fi

# Format lines changed
lines_display=""
if [ -n "$lines_added" ] && [ "$lines_added" != "0" ] && [ "$lines_added" != "null" ]; then
  lines_display="${GREEN}+${lines_added}${RESET}"
fi
if [ -n "$lines_removed" ] && [ "$lines_removed" != "0" ] && [ "$lines_removed" != "null" ]; then
  if [ -n "$lines_display" ]; then
    lines_display="${lines_display} ${RED}-${lines_removed}${RESET}"
  else
    lines_display="${RED}-${lines_removed}${RESET}"
  fi
fi

# Format duration (convert ms to human readable)
duration_display=""
if [ -n "$duration_ms" ] && [ "$duration_ms" != "null" ] && [ "$duration_ms" != "0" ]; then
  # Convert ms to seconds
  secs=$((${duration_ms%.*} / 1000))
  if [ "$secs" -ge 3600 ]; then
    hours=$((secs / 3600))
    mins=$(( (secs % 3600) / 60 ))
    duration_display="${hours}h${mins}m"
  elif [ "$secs" -ge 60 ]; then
    mins=$((secs / 60))
    duration_display="${mins}m"
  elif [ "$secs" -gt 0 ]; then
    duration_display="${secs}s"
  fi
  if [ -n "$duration_display" ]; then
    duration_display="${GRAY}${duration_display}${RESET}"
  fi
fi

# Build output with separators
output="${CYAN}📁 ${dir_name}${RESET}"

if [ -n "$git_info" ]; then
  output="${output}${git_info}"
fi

if [ -n "$model_display" ]; then
  output="${output}  ${model_display}"
fi

if [ -n "$context_display" ]; then
  output="${output}  ${context_display}"
fi

if [ -n "$lines_display" ]; then
  output="${output}  ${lines_display}"
fi

if [ -n "$duration_display" ]; then
  output="${output}  ${duration_display}"
fi

# Output the status line
echo -e "$output"
