# Helpers shared by install.sh and claude/install-statusline.sh.
# Source this, do not run it. The sourcing script must set REPO to the
# repository root first.

STAMP="$(date +%Y%m%d-%H%M%S)"
DRY=0
[ "${1:-}" = "--dry" ] && DRY=1

log() { printf '%s\n' "$*"; }

run() {
  if [ "$DRY" = 1 ]; then
    log "  would run: $*"
  else
    "$@"
  fi
}

# link <path-relative-to-repo-root> <destination>
#
# Anything already at the destination is moved to <name>.backup-<timestamp>,
# so nothing is overwritten in place. Repeating a link that already points
# where it should does nothing.
link() {
  local src="$REPO/$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$src" ]; then
    log "  already linked: $dst"
    return
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    log "  backing up $dst -> $dst.backup-$STAMP"
    run mv "$dst" "$dst.backup-$STAMP"
  fi
  log "  linking $dst -> $src"
  run mkdir -p "$(dirname "$dst")"
  run ln -s "$src" "$dst"
}
