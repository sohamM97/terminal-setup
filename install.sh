#!/usr/bin/env bash
# Set this terminal setup up on a machine: offer to install whatever programs
# it needs that are missing, then put the config files in place.
#
#   ./install.sh          apply
#   ./install.sh --dry    print what would change, touch nothing
#
# Every step checks before it acts, so re-running this is harmless. Nothing is
# installed without a yes, and the config files go in either way — so on a
# machine that already has the programs, this is only the symlinks.
#
# Existing files are moved aside to <name>.backup-<timestamp> before a symlink
# replaces them, so nothing is overwritten in place.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$REPO/lib.sh"

AUTOSUGGEST="$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"

log "programs"

# jq parses the JSON that Claude Code feeds the status line script.
APT_PACKAGES=(zsh git curl tilix jq)
apt_missing=()
for p in "${APT_PACKAGES[@]}"; do
  command -v "$p" >/dev/null 2>&1 || apt_missing+=("$p")
done

extras=()
[ -d "$HOME/.oh-my-zsh" ] || extras+=(oh-my-zsh)
[ -d "$AUTOSUGGEST" ] || extras+=(zsh-autosuggestions)
[ -d "$HOME/.fzf" ] || extras+=(fzf)

# set -u treats an empty array as unset, so expand each one only if it has
# something in it.
missing=(${apt_missing[@]+"${apt_missing[@]}"} ${extras[@]+"${extras[@]}"})

if [ ${#missing[@]} -eq 0 ]; then
  log "  all present: ${APT_PACKAGES[*]}, oh-my-zsh, zsh-autosuggestions, fzf"
elif ! confirm "Missing: ${missing[*]}. Install them now?"; then
  log "  not installing them — the config files below still go in"
else
  if [ ${#apt_missing[@]} -ne 0 ]; then
    if command -v apt-get >/dev/null 2>&1; then
      log "  apt: ${apt_missing[*]}"
      sudo apt-get update
      sudo apt-get install -y "${apt_missing[@]}"
    else
      log "  no apt-get on this machine — install ${apt_missing[*]} with its own package manager"
    fi
  fi

  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log "  oh-my-zsh"
    # RUNZSH=no stops the installer dropping you into a new shell, which would
    # stop this script. KEEP_ZSHRC=yes stops it writing its own ~/.zshrc, which
    # the zsh step below replaces anyway.
    RUNZSH=no KEEP_ZSHRC=yes sh -c \
      "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi

  # zshrc names this plugin, so it has to be under the oh-my-zsh directory
  # rather than anywhere of its own.
  if [ -d "$HOME/.oh-my-zsh" ] && [ ! -d "$AUTOSUGGEST" ]; then
    log "  zsh-autosuggestions"
    git clone https://github.com/zsh-users/zsh-autosuggestions "$AUTOSUGGEST"
  fi

  if [ ! -d "$HOME/.fzf" ]; then
    log "  fzf"
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    "$HOME/.fzf/install" --all
  fi
fi

log "login shell"
if ! command -v zsh >/dev/null 2>&1; then
  log "  zsh is not installed, so nothing to change to"
elif [ "$SHELL" = "$(command -v zsh)" ]; then
  log "  already zsh"
elif confirm "Make zsh the login shell? (chsh asks for your password)"; then
  chsh -s "$(command -v zsh)"
  log "  changed — takes effect at your next login, not in this terminal"
fi

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
