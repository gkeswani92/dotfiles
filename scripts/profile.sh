#!/bin/bash
# Shared machine role for the installer, shell, and tools. Data, never sourced.
dotfiles_profile_file() { printf '%s\n' "$HOME/.config/dotfiles/profile"; }

dotfiles_read_profile() {
  local file value
  file=$(dotfiles_profile_file)
  if [ ! -f "$file" ]; then
    echo "No machine profile saved. Run ~/dotfiles/install.sh --config-only first." >&2
    return 1
  fi
  value=$(<"$file")
  case "$value" in
    personal|work) printf '%s\n' "$value" ;;
    *) echo "Invalid profile in $file; expected personal or work. Use --reconfigure-profile to repair it." >&2; return 1 ;;
  esac
}

dotfiles_pi_dir() {
  case "$1" in
    personal) printf '%s\n' "$HOME/.pi/agent" ;;
    work) printf '%s\n' "$HOME/.pi/agent-shopify" ;;
    *) echo "Invalid machine profile: $1" >&2; return 1 ;;
  esac
}

# Resolve a machine choice without saving it. The installer saves after configuration succeeds.
dotfiles_select_profile() {
  local reconfigure=${1:-0} file current='' choice answer
  file=$(dotfiles_profile_file)
  if [ -e "$file" ] && [ "$reconfigure" = 0 ]; then
    DOTFILES_MACHINE_PROFILE=$(dotfiles_read_profile) || return 1
    return 0
  fi
  if [ -f "$file" ]; then current=$(<"$file"); fi
  if ! { exec 3<>/dev/tty; } 2>/dev/null; then
    echo "Machine selection requires a terminal; no changes made." >&2
    return 1
  fi
  while true; do
    printf 'Machine setup: 1) Personal  2) Work  (q to cancel)\nChoice: ' >&3
    if ! IFS= read -r choice <&3; then exec 3>&-; return 1; fi
    case "$choice" in
      1|personal|Personal) DOTFILES_MACHINE_PROFILE=personal; break ;;
      2|work|Work) DOTFILES_MACHINE_PROFILE=work; break ;;
      q|Q) exec 3>&-; return 1 ;;
      *) printf 'Please select personal or work; there is no default.\n' >&3 ;;
    esac
  done
  if [ -n "$current" ] && [ "$current" != "$DOTFILES_MACHINE_PROFILE" ]; then
    printf 'Change machine role from %s to %s? Git identity, work integrations, and AI will follow the new role. Other profiles and history are preserved. Type yes: ' "$current" "$DOTFILES_MACHINE_PROFILE" >&3
    if ! IFS= read -r answer <&3 || [ "$answer" != yes ]; then exec 3>&-; return 1; fi
  fi
  exec 3>&-
}
