# Tailscale is missing from the bar, or a widget you don't use is on it

**Tested on:** Omarchy 4.0.4, Hyprland 0.56.2 (Lua config)
**Applies to:** every machine

## Problem

You use Tailscale but there is no Tailscale icon in the bar. Or the bar
carries a widget you don't use, such as Dropbox, and you want the space back.
Or you found a bar widget in someone's git repo and want to add it.

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
places the widget. Run interactively, it warns you and asks before cloning,
then asks which bar section to use. In a script, add `--yes`, which skips the
prompts (otherwise the command refuses to run without a terminal). Update it
later with `omarchy plugin update <id>` and remove it with
`omarchy plugin remove <id>`.

Read the code before you add one. Plugins run unsandboxed inside the
long-running `omarchy-shell` process.

## Apply and check

The shell reloads `shell.json` and the plugin directory on save, so the bar
changes right away. `omarchy plugin list` shows the new state. If a freshly
cloned plugin does not appear, run `omarchy-shell shell rescanPlugins`.

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
