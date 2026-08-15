# terminal-setup

A zsh and tilix setup for Linux, kept in one place so a new machine can be
brought to the same state in a few minutes. Clone it and run one script.

What you get:

- **zsh** as the login shell
- **oh-my-zsh** with the `kphoen` theme and the `git` + `zsh-autosuggestions` plugins
- **tilix** as the terminal, with a Dracula colour scheme at 6% transparency
- **fzf** for fuzzy history and file search (`Ctrl-R`, `Ctrl-T`)
- a **Claude Code status line**, installed only if Claude Code is present

## Install on a new machine

Ubuntu, from nothing:

```sh
# https
git clone https://github.com/sohamM97/terminal-setup.git ~/terminal-setup
# or ssh
git clone git@github.com:sohamM97/terminal-setup.git ~/terminal-setup

cd ~/terminal-setup
./bootstrap.sh
```

Clone it anywhere — the scripts work out their own location, and `install.sh`
points the symlinks at whatever path you chose.

`bootstrap.sh` installs zsh, git, curl and tilix from apt, then oh-my-zsh,
the zsh-autosuggestions plugin and fzf from their own installers, sets zsh as
the login shell, and finally calls `install.sh` to put the config files in
place. Every step checks first, so re-running it is harmless.

Log out and back in afterwards — `chsh` only takes effect on a new login.

## Install just the config files

If zsh, oh-my-zsh, tilix and fzf are already on the machine:

```sh
./install.sh --dry   # print what would change, touch nothing
./install.sh         # apply
```

`install.sh` replaces each target with a symlink into this repo, so editing
`zsh/zshrc` here changes the shell immediately — no copying step to forget.
Anything already at a target path is moved to `<name>.backup-<timestamp>`
first; nothing is overwritten in place.

| repo file | lands at |
|---|---|
| `zsh/zshrc` | `~/.zshrc` |
| `tilix/Dracula.json` | `~/.config/tilix/schemes/Dracula.json` |
| `zsh/local.zsh.example` | copied to `zsh/local.zsh` if that does not exist |
| `claude/statusline-command.sh` | `~/.claude/statusline-command.sh`, if Claude Code is installed |

The scripts themselves:

| script | what it does |
|---|---|
| `bootstrap.sh` | installs the programs, then calls `install.sh` |
| `install.sh` | puts the config files in place |
| `claude/install-statusline.sh` | the Claude Code part on its own; `install.sh` calls it when Claude Code is present |
| `lib.sh` | the `log`, `run` and `link` helpers the two install scripts share; sourced, not run |
| `tilix/tilix-settings.dconf` | loaded into dconf at `/com/gexperts/Tilix/` |

## Per-machine settings: `zsh/local.zsh`

`zsh/zshrc` is the part worth sharing. Anything specific to one machine — the
`PATH` entries for toolchains it happens to have, personal aliases — goes in
`zsh/local.zsh`, which the last lines of `zshrc` source if it exists.

`local.zsh` is listed in `.gitignore` and never committed. The tracked file is
`zsh/local.zsh.example`, a short template showing the three shapes such a file
usually takes: an alias, a `PATH` entry, and sourcing a tool's own init script.
`install.sh` copies it to `local.zsh` on a fresh clone. Edit that copy:

```sh
$EDITOR zsh/local.zsh
```

Write each entry so it tests for the thing before using it, the way the
template does. Then a line for a tool the machine does not have costs a failed
test rather than an error at every shell start.

## Claude Code

`install.sh` skips this whole section when `claude` is not on `PATH`, and
creates no `~/.claude` directory, so the rest of the setup is useful on a
machine without Claude Code. If you install Claude Code later, run the step on
its own:

```sh
./claude/install-claude.sh
```

It takes `--dry` too, and refuses to run if `claude` is still not on `PATH`.

### The status line

`claude/statusline-command.sh` draws the line under the Claude Code prompt:
working directory, git branch with counts of staged, modified and untracked
files, ahead/behind arrows against the upstream branch, the model name, context
window used as a percentage, and cost so far.

Claude Code passes it a JSON object on standard input, which the script reads
with `jq` — so `jq` has to be installed for the line to appear at all.
`bootstrap.sh` installs it; the install script warns if it is missing.

To try it without starting Claude Code, feed it the JSON yourself:

```sh
echo '{"workspace":{"current_dir":"'"$PWD"'"},"model":{"display_name":"Opus 5"}}' \
  | bash claude/statusline-command.sh
```

### Settings

`claude/settings-fragment.json` holds the settings this repo manages:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash $HOME/.claude/statusline-command.sh"
  },
  "permissions": {
    "defaultMode": "manual"
  }
}
```

`manual` means Claude Code asks before running anything, rather than acting on
its own — it is the mode the pause indicator under the prompt refers to.

The fragment names only these keys. The install script merges it into
`~/.claude/settings.json` dictionary by dictionary, so every other key survives
— including `permissions.allow` and `permissions.deny`, which sit alongside
`defaultMode` and are not mentioned in the fragment. The file is copied to
`settings.json.backup-<timestamp>` first, and if it contains invalid JSON the
script says so and changes nothing.

`$HOME` is written literally in the fragment and expanded at install time, and
the command points at `~/.claude/`, not at this repo — so the fragment is the
same on every machine, and the symlink is what connects it here.

To add another setting, put it in the fragment and re-run the script.

### Skills

Skills live in their own repository, <https://github.com/sohamM97/claude-skills>,
which is packaged as a Claude Code plugin marketplace. Nothing in this repo
installs them; install them from inside Claude Code:

```text
/plugin marketplace add sohamM97/claude-skills
/plugin install soham@soham-skills
```

They are then namespaced under the plugin, so they run as `/soham:commit`,
`/soham:pr` and so on. To pick up newly published skills later:

```text
/plugin marketplace update soham-skills
```

That is the right route for a machine that only uses the skills. To edit them,
set the machine up for authoring instead — clone the repo and run the script it
ships, which symlinks each skill into `~/.claude/skills/` so edits at the user
level change the repo directly:

```sh
git clone git@github.com:sohamM97/claude-skills.git ~/projects/personal/claude-skills
~/projects/personal/claude-skills/link-skills.sh
```

Do one or the other, not both. `link-skills.sh` also registers the repo's
`stamp-prompt-time` hook in `~/.claude/settings.json`, which symlinking alone
would not do — Claude Code loads hooks from a settings file or an installed
plugin, never from `~/.claude/skills/`. Restart Claude Code afterwards. That
repo's own README is the authority on all of this.

## Tilix

Tilix stores its settings in dconf, not in a file, so they are exported here
instead of symlinked. To capture changes made through the Tilix preferences
window back into the repo:

```sh
dconf dump /com/gexperts/Tilix/ > tilix/tilix-settings.dconf
```

The export includes the profile UUID (`2b7c4080-…`). Loading it on a new
machine creates a profile with that same UUID, which is what you want — but it
means the file is not shareable with someone who already has profiles they
care about.

Tilix has no font of its own set, so it uses the GNOME monospace font. The
setup was built against `Ubuntu Sans Mono 13`. To match it:

```sh
gsettings set org.gnome.desktop.interface monospace-font-name 'Ubuntu Sans Mono 13'
```

No Nerd Font is installed and the `kphoen` theme does not need one, so there
are no missing-glyph boxes to worry about.

The 6% background transparency shows the desktop wallpaper through the
terminal. That is a per-profile setting and comes across with the dconf load.

## What is deliberately not here

- **Toolchains and their `PATH` entries.** `zsh/zshrc` sets up the shell and
  nothing else. Language runtimes, package managers and their `PATH` lines are
  per-machine, so they belong in `zsh/local.zsh`.
- **Secrets.** No SSH keys, no tokens, no `~/.pgpass`, no cloud credentials.
- **`~/.gitconfig`.** Two reasons. It holds nothing but a name and an email,
  and that identity differs per machine — work address on one, personal on
  another. And symlinking it here would mean every `git config --global`
  write, plus the `safe.directory` entries git adds by itself, lands in this
  repo as an uncommitted change. Set it per machine instead:

  ```sh
  git config --global user.name "Tere Naam"
  git config --global user.email "you@example.com"
  ```

## Keeping it up to date

`zsh/zshrc` and `tilix/Dracula.json` are symlinked into place, so edits to
them are already in the repo — just commit. Tilix's dconf settings need the
`dconf dump` above re-run before committing.
