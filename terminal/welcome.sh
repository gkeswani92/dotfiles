#!/bin/bash
# Terminal Welcome Screen
# Displays a customized welcome message with quotes and git info

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
RESET='\033[0m'

# Clear the screen
clear

# Get dotfiles info
DOTFILES_DIR="$DOTFILES_PATH"
if [ -d "$DOTFILES_DIR" ]; then
  LAST_COMMIT=$(cd "$DOTFILES_DIR" && git log -1 --pretty=format:"%h - %s (%ar)" 2>/dev/null)
  BRANCH=$(cd "$DOTFILES_DIR" && git branch --show-current 2>/dev/null)
else
  LAST_COMMIT="Not a git repository"
  BRANCH="N/A"
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

# Print welcome header
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BLUE}║                 ${GREEN}Welcome back, ${USER}!${BLUE}                        ║${RESET}"
echo -e "${BLUE}║                ${YELLOW}$(date +"%A, %B %d, %Y %H:%M")${BLUE}                ║${RESET}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${RESET}"
echo ""

# Show current Git project info if in a git repository
if [ -n "$GIT_INFO" ]; then
  echo -e "${PURPLE}${BOLD}Current Project${RESET}"
  echo -e "${PURPLE}┌───────────────────────────────────────────────────────────┐${RESET}"
  echo -e "${PURPLE}│ $GIT_INFO"
  echo -e "${PURPLE}└───────────────────────────────────────────────────────────┘${RESET}"
  echo ""
fi
