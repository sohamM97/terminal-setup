#!/usr/bin/env bash
# Install the programs this setup needs on a fresh Ubuntu machine, then hand
# over to install.sh for the config files.
#
# Safe to re-run: every step checks whether the thing is already there.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { printf '\n== %s\n' "$*"; }

log "apt packages: zsh, git, curl, tilix, jq"
# jq parses the JSON that Claude Code feeds the status line script.
sudo apt-get update
sudo apt-get install -y zsh git curl tilix jq

log "oh-my-zsh"
if [ -d "$HOME/.oh-my-zsh" ]; then
  echo "already installed"
else
  # RUNZSH=no stops the installer dropping you into a new shell and stopping
  # this script. KEEP_ZSHRC=yes stops it writing its own ~/.zshrc, which
  # install.sh replaces with ours anyway.
  RUNZSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

log "zsh-autosuggestions plugin"
AUTOSUGGEST="$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
if [ -d "$AUTOSUGGEST" ]; then
  echo "already installed"
else
  git clone https://github.com/zsh-users/zsh-autosuggestions "$AUTOSUGGEST"
fi

log "fzf"
if [ -d "$HOME/.fzf" ]; then
  echo "already installed"
else
  git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
  "$HOME/.fzf/install" --all
fi

log "make zsh the login shell"
if [ "$SHELL" = "$(command -v zsh)" ]; then
  echo "already zsh"
else
  chsh -s "$(command -v zsh)"
  echo "changed — takes effect at next login"
fi

log "config files"
"$REPO/install.sh"
