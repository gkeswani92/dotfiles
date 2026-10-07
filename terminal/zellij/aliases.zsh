# Zellij aliases
alias zj="zellij"
alias zjl="zellij --layout"
alias zjdev="zellij --layout dev"

# Quick session management
alias zjls="zellij list-sessions"
alias zja="zellij attach"

# Read the saved machine role even when this file is sourced independently.
# Clear old definitions when reloading a shell after a role change.
unalias zjbpfull zjbporgs bp-full-local-dev bp-orgs-only-dev 2>/dev/null || true
if [[ -f "$HOME/dotfiles/scripts/profile.sh" ]]; then
  source "$HOME/dotfiles/scripts/profile.sh"
  if [[ "$(dotfiles_read_profile 2>/dev/null)" == work ]]; then
    alias zjbpfull="zellij --layout bp-full"
    alias zjbporgs="zellij --layout bp-orgs-only"
    alias bp-full-local-dev="zellij --layout bp-full"
    alias bp-orgs-only-dev="zellij --layout bp-orgs-only"
  fi
fi