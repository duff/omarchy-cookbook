# My Omarchy customizations don't follow me to my other machines

## Problem

You tune one Omarchy machine: keybindings, input settings, the bar, a few
scripts. Then you set up a second laptop and it is stock again. Copying all of
`~/.config` across does not work either, because some settings belong to one
machine only (display scale, which speech model a laptop can run, a keyboard
remap for one built-in keyboard), and a full copy drags along caches, logs, and
files that still match the stock templates.

Forking Omarchy itself is not the answer. Everything under
`/usr/share/omarchy/` is replaced on every `omarchy update`.

## Why it happens

Omarchy keeps its defaults in `/usr/share/omarchy/` and copies starter files
into `~/.config/` once, at install time. After that, `~/.config/` is yours, and
nothing syncs it between machines.

Hyprland already layers your files on top of the defaults. The stock
`~/.config/hypr/hyprland.lua` loads Omarchy's defaults first and then your
overrides:

```lua
require("default.hypr.omarchy")

require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")
```

`/usr/share/omarchy/default/hypr/bootstrap.lua` puts `~/.config/?.lua` on the
Lua module path, so `require("hypr.foo")` loads `~/.config/hypr/foo.lua`. That
means your config can stay small: only the lines that differ from stock
(`o.bind`, `hl.unbind`, `hl.config`), not a copy of the packaged files.

## Fix

Keep a git repo with two layers and two scripts:

```
config/              # copied to ~/.config/ on every machine
  hypr/              # only files that differ from the stock templates
  omarchy/           # shell.json, hooks, plugins, defaults
hosts/<hostname>/    # copied to ~/.config/ after config/, only on that host
  hypr/monitors.lua
install.sh           # repo -> live machine
snapshot.sh          # live machine -> repo
```

Classify every change before you save it:

1. **All machines.** A preference you want everywhere. Goes in `config/`.
2. **This host only.** Anything that names this hardware, this screen, or what
   this machine can run. Goes in `hosts/<hostname>/`.
3. **Not in git.** Secrets, tokens, absolute paths to a program installed on
   one disk, model weights, logs, caches, and files that still match stock.

### install.sh: shared layer, then this host's layer

```bash
#!/usr/bin/env bash
# Apply this overlay onto the current Omarchy machine.
set -euo pipefail

root=$(cd "$(dirname "$0")" && pwd)
host=$(hostname)
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"

install_tree() {
  local src=$1 dest_root=$2
  [[ -d $src ]] || return 0

  local file rel dest
  while IFS= read -r -d '' file; do
    rel=${file#"$src"/}
    dest="$dest_root/$rel"
    mkdir -p "$(dirname "$dest")"
    cp -a "$file" "$dest"
  done < <(find "$src" -type f -print0)
}

install_tree "$root/config" "$config_home"

if [[ -d $root/hosts/$host ]]; then
  install_tree "$root/hosts/$host" "$config_home"
fi

echo "If Hyprland files changed: hyprctl reload && hyprctl configerrors"
```

The host layer is copied last, so a host file with the same path wins over the
shared one. `install.sh` never runs `omarchy refresh`, which resets configs to
stock.

Files outside `~/.config` (such as `~/.XCompose`, `~/.bashrc`, `~/.ssh/config`)
get their own `cp` lines in the same script.

### snapshot.sh: copy back only what differs from stock

```bash
#!/usr/bin/env bash
# Copy live overlay files back into this repo.
set -euo pipefail

root=$(cd "$(dirname "$0")" && pwd)
host=$(hostname)
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
omarchy_path="${OMARCHY_PATH:-/usr/share/omarchy}"

copy_if_present() {
  local src=$1 dest=$2
  [[ -e $src ]] || return 0
  mkdir -p "$(dirname "$dest")"
  cp -a "$src" "$dest"
}

differs_from_package() {
  local live=$1 packaged=$2
  [[ -f $live ]] || return 1
  if [[ -f $packaged ]]; then
    ! cmp -s "$live" "$packaged"
  else
    return 0
  fi
}

# Files that are always yours.
copy_if_present "$config_home/omarchy/shell.json" "$root/config/omarchy/shell.json"
copy_if_present "$config_home/xdg-terminals.list" "$root/config/xdg-terminals.list"
copy_if_present "$HOME/.XCompose" "$root/XCompose"

# Hyprland files: keep them only when they differ from the stock template.
# monitors.lua is host-specific and never goes under config/hypr/.
for name in autostart.lua bindings.lua hyprland.lua input.lua looknfeel.lua hyprsunset.conf xdph.conf; do
  live="$config_home/hypr/$name"
  packaged="$omarchy_path/config/hypr/$name"
  if differs_from_package "$live" "$packaged"; then
    copy_if_present "$live" "$root/config/hypr/$name"
  fi
done

# Display config belongs to this host.
if differs_from_package "$config_home/hypr/monitors.lua" "$omarchy_path/config/hypr/monitors.lua"; then
  copy_if_present "$config_home/hypr/monitors.lua" "$root/hosts/$host/hypr/monitors.lua"
fi

git -C "$root" status --short
```

The same `differs_from_package` check works for other apps Omarchy ships a
template for, such as `ghostty/config`, `kitty/kitty.conf`, and
`herdr/config.toml` (compare against `$omarchy_path/config/<same path>`).

### Moving a change between machines

On the machine where you made the change:

```bash
./snapshot.sh
git add -A && git status
git commit
git push
```

On the other one:

```bash
git pull
./install.sh
```

Snapshot before you switch machines, and pull before you edit on the second
one, or the two copies of a shared file drift apart.

### Host-only Hyprland files, loaded only where they exist

A rule set or keybinding that only makes sense on one machine goes in
`hosts/<hostname>/hypr/<name>.lua`. The shared `autostart.lua` loads it only
when the file is there, because `require` of a missing module is a config
error on the other hosts:

```lua
-- ~/.config/hypr/autostart.lua
-- This host's extra Hyprland files. Only load the ones installed here.
for _, name in ipairs({ "host-rules" }) do
  local file = io.open(os.getenv("HOME") .. "/.config/hypr/" .. name .. ".lua")
  if file then
    file:close()
    require("hypr." .. name)
  end
end
```

List each host-only file name in that table. On a host without the file the
loop skips it.

The same trick works for scripts that touch `/etc`. Keep the script in
`~/.config/<thing>/apply.sh` (in whichever layer it belongs), and have a shared
hook re-run it after every `omarchy update` only when it is installed:

```bash
#!/bin/bash
# ~/.config/omarchy/hooks/post-update.d/apply-keyd.hook
set -euo pipefail

apply="${XDG_CONFIG_HOME:-$HOME/.config}/keyd/apply.sh"
[[ -x $apply ]] || exit 0
exec "$apply"
```

### A file the host layer owns must be snapshotted back to the host layer

If `hosts/<hostname>/keyd/laptop.conf` exists and `snapshot.sh` copies every
live keyd file into `config/keyd/`, your next edit lands in the shared layer
while the old host copy stays put. The next `install.sh` copies the host layer
last and silently undoes the edit. Send a file back to the layer that already
owns it:

```bash
if [[ -d $config_home/keyd ]]; then
  while IFS= read -r -d '' file; do
    rel=${file#"$config_home/"}
    if [[ -f $root/hosts/$host/$rel ]]; then
      copy_if_present "$file" "$root/hosts/$host/$rel"
    else
      copy_if_present "$file" "$root/config/$rel"
    fi
  done < <(find "$config_home/keyd" -type f -print0)
fi
```

### One host-specific value inside a shared file

Sometimes a shared config has one line that differs per machine. Voxtype's
`config.toml` is an example: the word replacements are shared, but the Parakeet
model one laptop can run is too big for another. Store that value in
`hosts/<hostname>/voxtype.model`, have `snapshot.sh` strip the line from the
shared copy, and have `install.sh` put it back.

Put it back immediately after the shared file is copied, not at the end of
`install.sh`. With `set -e`, any later step that fails (a `sudo` prompt with no
terminal, for example) stops the script, and Voxtype refuses to record with the
model line missing.

```bash
# In install.sh, right after install_tree for config/ and hosts/$host/.
model_name=""
if [[ -f $root/hosts/$host/voxtype.model ]]; then
  model_name=$(tr -d '[:space:]' < "$root/hosts/$host/voxtype.model")
fi

# The voxtype CLI will not load a file that is missing this field, so
# `voxtype config set` cannot write it back. Put the line in directly.
write_parakeet_model() {
  local file=$1 model=$2 tmp
  tmp=$(mktemp)
  awk -v model="$model" '
    BEGIN { written = 0 }
    /^\[parakeet\]/ {
      in_p = 1
      print
      print "model = \"" model "\""
      written = 1
      next
    }
    in_p && /^model[[:space:]]*=/ { next }
    /^\[/ { in_p = 0 }
    { print }
    END {
      if (!written) {
        print ""
        print "[parakeet]"
        print "model = \"" model "\""
      }
    }
  ' "$file" > "$tmp"
  cat "$tmp" > "$file"
  rm -f "$tmp"
}

if [[ -n $model_name && -f $config_home/voxtype/config.toml ]]; then
  write_parakeet_model "$config_home/voxtype/config.toml" "$model_name"
fi
```

Have `install_tree` skip `voxtype.model` (`[[ $(basename "$file") == voxtype.model ]] && continue`)
so it is not copied into `~/.config`.

### A bootstrap for a new machine

`install.sh` picks `hosts/$(hostname)/`, so a fresh install has to have the
right hostname first. A small `bootstrap.sh` can do the one-time steps:

```bash
#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")" && pwd)
target_host=laptop
failed=()

if [[ $(hostname) != "$target_host" ]]; then
  echo "This machine is named $(hostname)."
  read -r -p "Rename it to ${target_host} and continue? [y/N] " answer
  [[ $answer == [yY] || $answer == [yY][eE][sS] ]] || exit 1
  sudo hostnamectl set-hostname "$target_host"
fi

# Run each step, keep going on failure, and list the failures at the end.
step() {
  local title=$1
  shift
  echo
  echo "== ${title} =="
  "$@" && return 0
  echo "FAILED: ${title}" >&2
  failed+=("$title")
  return 0
}

step "Packages" omarchy pkg add 1password 1password-cli keyd
step "Chrome" omarchy install browser chrome
step "Overlay" "$root/install.sh"

if ((${#failed[@]})); then
  echo "These steps failed:"
  printf '  %s\n' "${failed[@]}"
fi
```

End it with a printed checklist of what still needs a person: logging out so
new services start, signing in to apps, and enabling an SSH agent.

Get the repo onto the new machine over HTTPS (`gh auth login`, then
`gh repo clone`), since an SSH agent such as 1Password's is not set up yet.

## Apply and check

```bash
./install.sh
hyprctl reload
hyprctl configerrors
```

`hyprctl configerrors` should print nothing. Then run `./snapshot.sh` and check
that `git status` shows no changes: a clean status means the repo and the live
machine agree.

## Undo

The scripts only change a machine when you run them, so to stop syncing one,
stop running `install.sh` there. To put back what they changed:

- `install.sh` copies over files in `~/.config/` and keeps no backup. Return
  one to stock with `omarchy refresh config <path>`, where the path is
  relative to `~/.config/` (such as `hypr/bindings.lua`). It backs up the
  current file first. Delete files that Omarchy doesn't ship.
- Remove the host-only loop from `~/.config/hypr/autostart.lua`, then run
  `hyprctl reload`.
- Delete the post-update hook:
  `rm ~/.config/omarchy/hooks/post-update.d/apply-keyd.hook`.
- If `bootstrap.sh` renamed the machine, rename it back with
  `sudo hostnamectl set-hostname <old-name>`.
- Remove what `bootstrap.sh` installed, if you don't want it otherwise:
  `omarchy pkg drop 1password 1password-cli keyd` and
  `omarchy remove browser chrome`.

## Notes

- Do not commit files that still match the stock template. When Omarchy
  improves a default, a stale copy in your repo would hide the improvement.
  When a live file goes back to matching stock, `snapshot.sh` stops copying
  it but leaves the old copy in the repo, so delete that copy by hand. The
  working script prints a note for each such file (an `elif` branch in the
  Hyprland loop that checks whether the repo copy still exists).
- Keep generated files out: `~/.config/omarchy/branding/`, app logs, caches,
  and Omarchy's first-run hooks.
- When a coding agent edits your config, write the three classes in a rules
  file at the repo root and ask the agent to say which class each change was.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.

## Recipe data

```json
{
  "id": "duff/customizations-do-not-follow-to-other-machines",
  "title": "My Omarchy customizations don't follow me to my other machines",
  "summary": "A git overlay with a shared layer and a per-machine layer.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2"},
  "applies_to": "Every machine (most useful with two or more Omarchy installs).",
  "requires": [],
  "touches": ["~/.config/", "~/.config/hypr/autostart.lua", "~/.config/omarchy/hooks/post-update.d/apply-keyd.hook", "~/.config/voxtype/config.toml", "~/.XCompose", "~/.bashrc", "~/.ssh/config", "/etc/hostname"],
  "root": true,
  "network": true,
  "installs": ["1password", "1password-cli", "keyd", "aur/google-chrome"],
  "runs": ["~/.config/omarchy/hooks/post-update.d/apply-keyd.hook", "~/.config/hypr/autostart.lua", "~/.bashrc"],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
```
