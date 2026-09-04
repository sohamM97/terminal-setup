#!/usr/bin/env bash
# Install this terminal setup on a machine that already has zsh, oh-my-zsh,
# tilix and fzf present. Run bootstrap.sh first if it does not.
#
#   ./install.sh          apply everything
#   ./install.sh --dry    print what would change, touch nothing
#
# Existing files are moved aside to <name>.backup-<timestamp> before a symlink
# replaces them, so nothing is overwritten in place.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$REPO/lib.sh"

log "zsh"
link zsh/zshrc "$HOME/.zshrc"

# zshrc sources local.zsh for whatever is specific to this machine. It is not
# in the repo, so create it from the template the first time.
if [ -f "$REPO/zsh/local.zsh" ]; then
  log "  local.zsh already present, left alone"
else
  log "  creating zsh/local.zsh from local.zsh.example"
  run cp "$REPO/zsh/local.zsh.example" "$REPO/zsh/local.zsh"
fi

log "tilix colour scheme"
link tilix/Dracula.json "$HOME/.config/tilix/schemes/Dracula.json"

log "tilix settings (dconf)"
if command -v dconf >/dev/null 2>&1; then
  if [ "$DRY" = 1 ]; then
    log "  would run: dconf load /com/gexperts/Tilix/ < tilix/tilix-settings.dconf"
  else
    dconf load /com/gexperts/Tilix/ < "$REPO/tilix/tilix-settings.dconf"
    log "  loaded"
  fi
else
  log "  dconf not found, skipped"
fi

# install-claude.sh offers to install Claude Code if it is missing, and puts
# the status line and settings in either way.
TERMINAL_SETUP_NESTED=1 "$REPO/claude/install-claude.sh" "$@"

log
log "Done. Open a new terminal, or run: exec zsh"
