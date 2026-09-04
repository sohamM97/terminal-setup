#!/usr/bin/env bash
# Install the Claude Code parts of this setup on their own: the status line
# script, and the settings in claude/settings-fragment.json.
#
#   ./claude/install-claude.sh          apply
#   ./claude/install-claude.sh --dry    print what would change
#
# install.sh runs this too, but skips it when Claude Code is absent. Run it
# directly if you install Claude Code later on.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib.sh
source "$REPO/lib.sh"

if ! command -v claude >/dev/null 2>&1; then
  log "claude is not on PATH — install Claude Code first, then run this again."
  exit 1
fi

log "claude code status line"
link claude/statusline-command.sh "$HOME/.claude/statusline-command.sh"

log "claude code settings"
SETTINGS="$HOME/.claude/settings.json"
FRAGMENT="$REPO/claude/settings-fragment.json"

if [ "$DRY" = 1 ]; then
  log "  would merge claude/settings-fragment.json into $SETTINGS"
elif ! command -v python3 >/dev/null 2>&1; then
  log "  python3 not found, cannot edit settings.json — apply the fragment by hand"
else
  [ -f "$SETTINGS" ] && cp "$SETTINGS" "$SETTINGS.backup-$STAMP"
  python3 - "$SETTINGS" "$FRAGMENT" <<'PY'
import json, os, sys

settings_path, fragment_path = sys.argv[1], sys.argv[2]
os.makedirs(os.path.dirname(settings_path), exist_ok=True)

try:
    with open(settings_path) as f:
        settings = json.load(f)
except FileNotFoundError:
    settings = {}
except json.JSONDecodeError as e:
    sys.exit(f"  {settings_path} is not valid JSON ({e}) — left alone")

with open(fragment_path) as f:
    fragment = json.load(f)

# The fragment names only the keys this repo cares about. Merging dict into
# dict rather than assigning keeps everything else in settings.json — and
# inside "permissions", keeps the allow and deny lists, which the fragment
# does not mention.
def merge(base, incoming, path=""):
    changed = []
    for key, value in incoming.items():
        where = f"{path}{key}"
        if isinstance(value, dict) and isinstance(base.get(key), dict):
            changed += merge(base[key], value, f"{where}.")
        elif base.get(key) != value:
            base[key] = value
            changed.append(where)
    return changed

# $HOME is written literally in the fragment so the file stays machine
# independent; expand it here.
fragment["statusLine"]["command"] = fragment["statusLine"]["command"].replace(
    "$HOME", os.path.expanduser("~")
)

changed = merge(settings, fragment)
if not changed:
    print(
        "  already set: statusLine, permissions.defaultMode, "
        "remoteControlAtStartup, autoUploadSessions"
    )
else:
    with open(settings_path, "w") as f:
        json.dump(settings, f, indent=2)
        f.write("\n")
    print("  set " + ", ".join(changed))
PY
fi

if ! command -v jq >/dev/null 2>&1; then
  log "  note: the status line needs jq, which is not installed"
fi

# install.sh sets this and prints its own closing message, so print this one
# only when the script was run on its own.
if [ "${TERMINAL_SETUP_NESTED:-}" != "1" ]; then
  log
  log "Done. Applies to Claude Code sessions started from now on."
fi
