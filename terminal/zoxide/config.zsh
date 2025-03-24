# Zoxide Configuration
# https://github.com/ajeetdsouza/zoxide

# Initialize zoxide with zsh
if command -v zoxide >/dev/null 2>&1; then
  # Initialize with standard settings
  eval "$(zoxide init zsh)"

  # Custom aliases for zoxide
  alias cd="z"         # Replace standard cd with zoxide
  alias zz="z -"       # Go back to the previous directory
  alias zi="z -i"      # Interactive selection using fzf
  alias zl="z -l"      # List all directories in the database with their scores
  alias zc="z -c"      # Restricts matches to subdirectories of the current directory
  alias zf="zi"        # Fuzzy finder alias for interactive selection
fi
