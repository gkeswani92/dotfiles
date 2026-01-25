#!/bin/bash
# Terminal Welcome Screen
# Displays system info with fastfetch and current git project status

# Colors
PURPLE='\033[0;35m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
WHITE='\033[1;37m'
BOLD='\033[1m'
RESET='\033[0m'

# Clear the screen
clear

# Display system info with fastfetch (shows Apple logo + stats)
if command -v fastfetch &> /dev/null; then
  fastfetch
  echo ""
else
  # Fallback if fastfetch not installed
  echo -e "${GREEN}Welcome back, ${USER}!${RESET}"
  echo -e "${YELLOW}$(date +"%A, %B %d, %Y %H:%M")${RESET}"
  echo ""
fi

# Get current Git project status (if in a git repository)
CURRENT_DIR=$(pwd)
GIT_INFO=""
if git -C "$CURRENT_DIR" rev-parse --is-inside-work-tree &>/dev/null; then
  GIT_DIR=$(git -C "$CURRENT_DIR" rev-parse --show-toplevel)
  GIT_BRANCH=$(git -C "$CURRENT_DIR" branch --show-current)
  GIT_CHANGES=$(git -C "$CURRENT_DIR" status --porcelain | wc -l | tr -d ' ')
  GIT_PROJECT=$(basename "$GIT_DIR")

  GIT_INFO="${PURPLE}Git Project${RESET}: ${WHITE}$GIT_PROJECT${RESET} on ${YELLOW}$GIT_BRANCH${RESET}"
  if [ "$GIT_CHANGES" -gt 0 ]; then
    GIT_INFO="$GIT_INFO ${RED}[$GIT_CHANGES changes]${RESET}"
  else
    GIT_INFO="$GIT_INFO ${GREEN}[clean]${RESET}"
  fi
fi

# Show current Git project info if in a git repository
if [ -n "$GIT_INFO" ]; then
  echo -e "${PURPLE}${BOLD}Current Project${RESET}"
  echo -e "${PURPLE}┌───────────────────────────────────────────────────────────┐${RESET}"
  echo -e "${PURPLE}│ $GIT_INFO"
  echo -e "${PURPLE}└───────────────────────────────────────────────────────────┘${RESET}"
  echo ""
fi
