# Bar is missing a widget you want, or shows one you don't use

## Problem

The bar is missing a widget you want: you use Tailscale, say, but there is
no Tailscale icon. Or the bar carries a widget you don't use, such as
Dropbox, and you want the space back. Or you found a bar widget in someone's
git repo and want to add it.

## Why it happens

Every bar widget is a shell plugin, and the bar shows the ones listed under
`bar.layout` in `~/.config/omarchy/shell.json`. The stock layout
(`/usr/share/omarchy/config/omarchy/shell.json`) has neither Tailscale nor
Dropbox. Omarchy's installers put them there:
`omarchy-install-service-tailscale` ends with
`omarchy-plugin-enable omarchy.tailscale`. If you set up Tailscale some other
way, or copied a `shell.json` from another machine, the widget is not there.
Removing Dropbox with Omarchy's remover takes its widget off, but a widget
can also stay behind in a copied `shell.json`.

For a bar widget, "enabled" means "placed in the bar", and "disabled" means
"not in the bar".

## Fix

See what exists and what is on the bar:

```bash
omarchy plugin list
```

Add the Tailscale widget (it goes to its default section, the right):

```bash
omarchy plugin enable omarchy.tailscale
```

To put it at a particular spot, give a placement:

```bash
omarchy plugin enable omarchy.tailscale --section right --after omarchy.tray
```

Take a widget off the bar:

```bash
omarchy plugin disable omarchy.dropbox
```

Both commands edit `~/.config/omarchy/shell.json`. The result is just an
entry in the right section's list:

```json
"right": [
  { "id": "omarchy.agents" },
  { "id": "omarchy.bluetooth" },
  { "id": "omarchy.tray" },
  { "id": "omarchy.tailscale" },
  { "id": "omarchy.network" },
  { "id": "omarchy.audio" },
  { "id": "omarchy.monitor" },
  { "id": "omarchy.power" }
]
```

### A widget from a third-party repo

Plugins that do not ship with Omarchy install from git:

```bash
omarchy plugin add https://github.com/<owner>/<plugin>.git --enable
```

This clones into `~/.config/omarchy/plugins/<id>/`, checks the manifest, and
places the widget. It warns you and asks before cloning, then asks which bar
section to use. Update it later with `omarchy plugin update <id>` and remove
it with `omarchy plugin remove <id>`.

Review a plugin's code before you add it. Plugins run unsandboxed inside the
long-running `omarchy-shell` process, with the same access to your files and
accounts as you have. Read the repo first: its `manifest.json` and every QML
and script file. Prefer a plugin small enough to read in full, from an author
you know. An update pulls the repo's new code, so read its recent commits
before you run `omarchy plugin update`.

## Apply and check

The shell reloads `shell.json` and the plugin directory on save, so the bar
changes right away. `omarchy plugin list` shows the new state. If a freshly
cloned plugin does not appear, run `omarchy-shell shell rescanPlugins`.

## Undo

Each command has an opposite. `omarchy plugin disable omarchy.tailscale`
takes the Tailscale widget off again, `omarchy plugin enable omarchy.dropbox`
puts a widget you took off back, and `omarchy plugin remove <id>` deletes a
third-party plugin.

## Notes

- `omarchy bar move <id> --section <left|center|right>` (with `--before`,
  `--after`, or `--index`) moves a widget that is already on the bar.
- Disabling the Dropbox widget does not uninstall Dropbox. Omarchy's
  `omarchy-remove-service-dropbox` does both.
- If you keep `shell.json` in a dotfiles repo, commit it after enabling a
  widget, or a new install will not have it.
- A third-party plugin may keep its own settings in a file under
  `~/.config/omarchy/`. Keep tokens out of anything you commit; put them in
  the keyring if the plugin supports it.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.

## Recipe data

```json
{
  "id": "duff/tailscale-missing-from-the-bar",
  "title": "Bar is missing a widget you want, or shows one you don't use",
  "summary": "Enable, disable, or add bar widgets with omarchy plugin.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2"},
  "applies_to": "Every machine.",
  "requires": [],
  "touches": ["~/.config/omarchy/shell.json", "~/.config/omarchy/plugins/"],
  "root": false,
  "network": true,
  "installs": ["a third-party shell plugin from git, if you add one"],
  "runs": ["a third-party shell plugin, inside omarchy-shell, if you add one"],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
```
