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

# Random quote function (add your own favorites)
function random_quote() {
  local quotes=(
    "The best way to predict the future is to invent it. – Alan Kay"
    "Code is like humor. When you have to explain it, it's bad. – Cory House"
    "Programming isn't about what you know; it's about what you can figure out. – Chris Pine"
    "The most disastrous thing that you can ever learn is your first programming language. – Alan Kay"
    "The question of whether a computer can think is no more interesting than the question of whether a submarine can swim. – Edsger Dijkstra"
    "Any fool can write code that a computer can understand. Good programmers write code that humans can understand. – Martin Fowler"
    "Talk is cheap. Show me the code. – Linus Torvalds"
    "It's not a bug; it's an undocumented feature. – Anonymous"
    "First, solve the problem. Then, write the code. – John Johnson"
    "Experience is the name everyone gives to their mistakes. – Oscar Wilde"
  )
  echo "${quotes[$RANDOM % ${#quotes[@]}]}"
}

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

# Print dotfiles information
echo -e "${GREEN}${BOLD}Dotfiles Status${RESET}"
echo -e "${GREEN}┌───────────────────────────────────────────────────────────┐${RESET}"
echo -e "${GREEN}│ ${BOLD}Branch${RESET}:      $BRANCH"
echo -e "${GREEN}│ ${BOLD}Last Commit${RESET}: $LAST_COMMIT"
echo -e "${GREEN}└───────────────────────────────────────────────────────────┘${RESET}"
echo ""

# Show current Git project info if in a git repository
if [ -n "$GIT_INFO" ]; then
  echo -e "${PURPLE}${BOLD}Current Project${RESET}"
  echo -e "${PURPLE}┌───────────────────────────────────────────────────────────┐${RESET}"
  echo -e "${PURPLE}│ $GIT_INFO"
  echo -e "${PURPLE}└───────────────────────────────────────────────────────────┘${RESET}"
  echo ""
fi

# Show a random quote
echo -e "${YELLOW}${BOLD}Quote of the Day${RESET}"
echo -e "${YELLOW}┌───────────────────────────────────────────────────────────┐${RESET}"
echo -e "${YELLOW}│ $(random_quote)"
echo -e "${YELLOW}└───────────────────────────────────────────────────────────┘${RESET}"
echo ""

# Add some helpful command reminders
echo -e "${WHITE}${BOLD}Helpful Commands${RESET}"
echo -e "${WHITE}┌───────────────────────────────────────────────────────────┐${RESET}"
echo -e "${WHITE}│ ${BOLD}weather${RESET}           - Show current weather forecast"
echo -e "${WHITE}│ ${BOLD}extract <file>${RESET}    - Extract any compressed file"
echo -e "${WHITE}│ ${BOLD}mkcd <dir>${RESET}        - Create and enter directory"
echo -e "${WHITE}│ ${BOLD}serve${RESET}             - Start HTTP server in current directory"
echo -e "${WHITE}└───────────────────────────────────────────────────────────┘${RESET}"
echo ""
