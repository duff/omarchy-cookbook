---
{
  "id": "duff/desktop-shortcuts-appear-in-home-folder",
  "title": "Desktop shortcuts appear in the home folder",
  "summary": "Create ~/Desktop and point the XDG desktop folder at it.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2"},
  "applies_to": "Every machine.",
  "requires": [],
  "touches": ["~/Desktop", "~/.config/user-dirs.dirs"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": [],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
---

# Desktop shortcuts appear in the home folder

## Problem

You install a Chrome app ("Install page as app") or run a Windows installer
under Wine, and a `.desktop` shortcut file appears loose in `~`.

## Why it happens

Installers put shortcuts in the XDG desktop folder. `xdg-user-dirs` decides
where that is, and `xdg-user-dirs.service` runs `xdg-user-dirs-update` at
every login. If `~/Desktop` doesn't exist, the update points the desktop
folder at your home folder:

```bash
grep DESKTOP ~/.config/user-dirs.dirs
# XDG_DESKTOP_DIR="$HOME/"
```

Omarchy shows no desktop icons and nothing in it uses `~/Desktop`, so it's
easy to end up without one. Then every shortcut lands in `~`.

## Fix

Create the folder and point the desktop setting at it:

```bash
mkdir -p ~/Desktop
xdg-user-dirs-update --set DESKTOP "$HOME/Desktop"
```

## Apply and check

```bash
grep DESKTOP ~/.config/user-dirs.dirs
# XDG_DESKTOP_DIR="$HOME/Desktop"
```

New shortcuts now go into `~/Desktop`. Move or delete the old `.desktop`
files in `~` by hand. Installers usually also write a launcher entry to
`~/.local/share/applications/`, so you won't need the loose copies.

## Undo

Move anything you want to keep out of `~/Desktop`, then remove it:

```bash
rmdir ~/Desktop
```

At the next login, `xdg-user-dirs-update` points the desktop back at `~`.

## Notes

- Keep `~/Desktop`, even when it's empty. If you delete it, the next login
  points the desktop back at `~`.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.
