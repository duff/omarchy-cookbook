# mailto: links open in Chrome instead of HEY

## Problem

Stock Omarchy opens `mailto:` links in HEY, in a new-message window. After
you make Google Chrome your default browser, `mailto:` links open in Chrome.

A second, smaller problem: opening HEY from the launcher starts another HEY
window every time, even when one is already open.

## Why it happens

At install, `omarchy-provision-user` runs:

```bash
xdg-mime default HEY.desktop x-scheme-handler/mailto
```

That writes `x-scheme-handler/mailto=HEY.desktop` to
`~/.config/mimeapps.list`. When Chrome makes itself the default browser, it
can take `mailto:` too, which replaces that line. Nothing in Omarchy puts it
back.

The stock `HEY.desktop` runs `omarchy-webapp-handler-hey %u`. That script turns
a `mailto:` URL into a HEY compose URL. For any other launch, it calls
`omarchy-launch-webapp https://app.hey.com`, which always opens a new window.

## Fix

### Put mailto: back on HEY, now and after every update

Save this as `~/.config/omarchy/hooks/post-update.d/set-mailto-hey.hook`:

```bash
#!/bin/bash
# Keep mailto: on HEY after an Omarchy update.
set -euo pipefail

apps="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
packaged="${OMARCHY_PATH:-/usr/share/omarchy}/applications/HEY.desktop"

# The handler has to exist in ~/.local/share/applications.
if [[ ! -f $apps/HEY.desktop && -f $packaged ]]; then
  mkdir -p "$apps"
  cp -a "$packaged" "$apps/HEY.desktop"
  update-desktop-database "$apps" >/dev/null 2>&1 || true
fi

xdg-mime default HEY.desktop x-scheme-handler/mailto
```

`omarchy update` runs every script in `post-update.d/` after it updates
packages and runs migrations. Run it once now too.

### Focus the open HEY window, but still compose for mailto:

Save this as `~/.config/omarchy/hey/launch`:

```bash
#!/bin/bash
# HEY launcher and mailto handler. A mailto: link opens a compose window, as
# stock Omarchy does. Opening HEY itself focuses the main window when it is
# open; the compose window's class (app.hey.com__messages_new) never matches.

if [[ ${1:-} == mailto:* ]]; then
  exec omarchy-webapp-handler-hey "$1"
fi

exec omarchy-launch-or-focus-webapp 'app\.hey\.com__-' https://app.hey.com
```

Point `HEY.desktop` at it:

```bash
sed -i "s#^Exec=.*#Exec=$HOME/.config/omarchy/hey/launch %u#" ~/.local/share/applications/HEY.desktop
```

The sed writes your full home path, because `Exec` doesn't expand `~`. Keep
`%u`: that's where the `mailto:` URL comes in. Leave `MimeType=` alone, so
HEY stays registered for `x-scheme-handler/mailto`.

For the Super+Shift+E shortcut, see
[launcher-shortcut-opens-a-second-window.md](../launcher-shortcut-opens-a-second-window/RECIPE.md).

## Apply and check

```bash
chmod +x ~/.config/omarchy/hooks/post-update.d/set-mailto-hey.hook ~/.config/omarchy/hey/launch
~/.config/omarchy/hooks/post-update.d/set-mailto-hey.hook
xdg-mime query default x-scheme-handler/mailto   # HEY.desktop
xdg-open 'mailto:someone@example.com'            # opens a HEY compose window
```

## Undo

Delete the hook and the launch script, then put the stock `HEY.desktop`
back:

```bash
rm ~/.config/omarchy/hooks/post-update.d/set-mailto-hey.hook ~/.config/omarchy/hey/launch
omarchy refresh applications
```

## Notes

- `omarchy refresh applications` copies the stock `HEY.desktop` back, which
  undoes the `Exec` change. `mailto:` still works after that, but HEY opens
  new windows again. Run the sed again.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.

## Recipe data

```json
{
  "id": "duff/mailto-links-open-in-chrome-instead-of-hey",
  "title": "mailto: links open in Chrome instead of HEY",
  "summary": "Put HEY back as the mailto handler and keep it there after updates.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2"},
  "applies_to": "Every machine that uses Google Chrome as the default browser.",
  "requires": [],
  "touches": ["~/.config/omarchy/hooks/post-update.d/set-mailto-hey.hook", "~/.config/omarchy/hey/launch", "~/.local/share/applications/HEY.desktop", "~/.config/mimeapps.list"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": ["~/.config/omarchy/hooks/post-update.d/set-mailto-hey.hook"],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
```
