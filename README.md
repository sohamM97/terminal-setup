# terminal-setup

A zsh and tilix setup for Linux, kept in one place so a new machine can be
brought to the same state in a few minutes. Clone it and run one script.

What you get:

- **zsh** as the login shell
- **oh-my-zsh** with the `kphoen` theme and the `git` + `zsh-autosuggestions` plugins
- **tilix** as the terminal, with a Dracula colour scheme at 6% transparency
- **fzf** for fuzzy history and file search (`Ctrl-R`, `Ctrl-T`)
- **kubectl** as `k`, with krew and the `ctx` and `ns` plugins
- a **Claude Code status line**

## Install

Ubuntu, from nothing — one script, whatever state the machine is in:

```sh
# https
git clone https://github.com/sohamM97/terminal-setup.git ~/terminal-setup
# or ssh
git clone git@github.com:sohamM97/terminal-setup.git ~/terminal-setup

cd ~/terminal-setup
./install.sh --dry   # print what would change, touch nothing
./install.sh         # apply
```

Clone it anywhere — the scripts work out their own location, and `install.sh`
points the symlinks at whatever path you chose.

Nothing is installed without a yes. `install.sh` lists the programs it cannot
find and asks once:

```
programs
  Missing: tilix jq fzf. Install them now? [y/N]
```

`zsh git curl tilix jq` come from apt; `oh-my-zsh`, `zsh-autosuggestions` and
`fzf` come from their own installers. Answer no and it goes straight on to the
config files. Making zsh the login shell is asked separately, because `chsh`
wants your password and only takes effect at your next login. The Kubernetes
tools and Claude Code have their own questions further down.

On a machine that already has all of it, there is no question at all — the run
is only the symlinks. Every step checks before it acts, so re-running is
harmless.

`install.sh` replaces each target with a symlink into this repo, so editing
`zsh/zshrc` here changes the shell immediately — no copying step to forget.
Anything already at a target path is moved to `<name>.backup-<timestamp>`
first; nothing is overwritten in place.

| repo file | lands at |
|---|---|
| `zsh/zshrc` | `~/.zshrc` |
| `tilix/Dracula.json` | `~/.config/tilix/schemes/Dracula.json` |
| `zsh/local.zsh.example` | copied to `zsh/local.zsh` if that does not exist |
| `claude/statusline-command.sh` | `~/.claude/statusline-command.sh` |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` |

The scripts themselves:

| script | what it does |
|---|---|
| `install.sh` | the whole thing: offers to install the programs, then puts the config files in place |
| `k8s/install-k8s.sh` | the Kubernetes part on its own; `install.sh` always calls it |
| `claude/install-claude.sh` | the Claude Code part on its own; `install.sh` always calls it |
| `lib.sh` | the `log`, `run`, `link` and `confirm` helpers the two install scripts share; sourced, not run |
| `tilix/tilix-settings.dconf` | loaded into dconf at `/com/gexperts/Tilix/` |

## Per-machine settings: `zsh/local.zsh`

`zsh/zshrc` is the part worth sharing. Anything specific to one machine — the
`PATH` entries for toolchains it happens to have, personal aliases — goes in
`zsh/local.zsh`, which the last lines of `zshrc` source if it exists.

`local.zsh` is listed in `.gitignore` and never committed. The tracked file is
`zsh/local.zsh.example`, a short template showing the three kinds of line such
a file usually holds: an alias, a `PATH` entry, and a tool's own init script,
sourced.
`install.sh` copies it to `local.zsh` on a fresh clone. Edit that copy:

```sh
$EDITOR zsh/local.zsh
```

Write each entry so it tests for the thing before using it, the way the
template does. Then a line for a tool the machine does not have costs a failed
test rather than an error at every shell start.

## Kubernetes

`k8s/install-k8s.sh` asks about four things, and only about the ones that are
not already there:

| tool | where it comes from |
|---|---|
| `kubectl` | the binary from `dl.k8s.io`, checksum-checked, into `/usr/local/bin` |
| `krew` | kubectl's plugin manager, into `~/.krew` |
| `ctx`, `ns` | `kubectl krew install ctx ns` |
| `helm` | apt, from the repository at `packages.buildkite.com` |
| `argocd` | the release binary from GitHub, into `/usr/local/bin` |

kubectl, krew, `ctx` and `ns` are asked for together; helm and argocd get a
question each, so a machine that needs no Helm chart can say no to that alone.
Each command is the one that tool's own documentation gives — the URL is in a
comment above it in the script.

`ctx` and `ns` are the point of krew here. They are the `kubectx` and `kubens`
programs, installed as kubectl plugins named `kubectl-ctx` and `kubectl-ns`
rather than as commands of their own. kubectl runs any `kubectl-*` on `PATH`
as a subcommand, so they are `kubectl ctx` and `kubectl ns` — and `k ctx` and
`k ns` through the alias. That is why `~/.krew/bin` has to be on `PATH`.

`zsh/zshrc` sets the shell side up, all of it inside a `command -v kubectl`
test so a machine with no kubectl is unaffected:

```sh
alias k=kubectl
alias kustomize="kubectl kustomize"          # kubectl has kustomize built in
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
compdef k=kubectl                            # completion, under the alias too
```

The completion itself is `~/.zsh/completions/_kubectl`, which the install
script writes once with `kubectl completion zsh`. `zshrc` puts that directory
on `fpath` before oh-my-zsh runs `compinit`, which then loads the file only
when you complete a `k` or `kubectl` command. Running `kubectl completion zsh`
at every shell start works too and is simpler, but costs about 75ms: 0.22s
against 0.14s, over five runs of each.

Re-run `./k8s/install-k8s.sh` after a kubectl upgrade to rewrite the
completion file for the new version.

## Claude Code

`install.sh` hands this section to `claude/install-claude.sh`, which you can
also run on its own:

```sh
./claude/install-claude.sh          # apply
./claude/install-claude.sh --dry    # print what would change
```

If `claude` is not on `PATH` it asks first:

```
claude code
  Claude Code is not installed. Install it now? [y/N]
```

Answer `y` and it runs the official installer, `curl -fsSL
https://claude.ai/install.sh | bash`, which puts `claude` in `~/.local/bin`.
Answer anything else — including a bare Enter — and it carries on to the status
line and the settings without it; those are files under `~/.claude/`, and they
work whenever Claude Code does arrive.

The question answers itself with a no under `--dry`, and when standard input is
not a terminal, so a dry run and a piped `curl ... | bash` both finish rather
than wait for a keypress that cannot come.

### CLAUDE.md

`claude/CLAUDE.md` is symlinked to `~/.claude/CLAUDE.md`, the user-level
instructions Claude Code loads at the start of every session in every project.
Editing it here changes them at once, the same way `zsh/zshrc` works.

Claude Code reads through the symlink. The one documented exception is Cowork
on the desktop app, which skips a `~/.claude/CLAUDE.md` that is itself a
symlink or hard link; terminal and IDE sessions are unaffected. If you start
using Cowork, copy the file instead of linking it.

Keep it under 200 lines. That is [Anthropic's own
number](https://code.claude.com/docs/en/memory) — *"target under 200 lines per
CLAUDE.md file. Longer files consume more context and reduce adherence"* — and
the file says so about itself. Past that, the documented remedy is
`~/.claude/rules/` with `paths:` frontmatter, which loads a rule only when
Claude touches matching files. `@path` imports organise content but still load
everything at launch, so they save no context.

Instructions that belong to one project belong in that project's own
`CLAUDE.md`, which is read after this one and wins where the two conflict.

### The status line

`claude/statusline-command.sh` draws the line under the Claude Code prompt:
working directory, git branch with counts of staged, modified and untracked
files, ahead/behind arrows against the upstream branch, the model name, context
window used as a percentage, and cost so far.

Claude Code passes it a JSON object on standard input, which the script reads
with `jq` — so `jq` has to be installed for the line to appear at all.
`jq` is one of the programs `install.sh` offers to install; say no to that and
`claude/install-claude.sh` warns that the line will not work.

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
  },
  "remoteControlAtStartup": false,
  "autoUploadSessions": false
}
```

`manual` means Claude Code asks before running anything, rather than acting on
its own — it is the mode the pause indicator under the prompt refers to.

`remoteControlAtStartup: false` keeps Remote Control — the feature that lets the
Claude mobile and web apps drive a session running in this terminal — switched
off when a session starts. Start a session with `claude --remote-control` when
you actually want to hand that one to your phone.

`autoUploadSessions: false` stops transcripts of terminal sessions being sent to
claude.ai, so they stay on this machine under `~/.claude/projects/`.

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
