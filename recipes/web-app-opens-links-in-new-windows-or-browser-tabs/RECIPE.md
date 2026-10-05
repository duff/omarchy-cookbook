# A web app opens every link in a new window, or sends links out to a browser tab

## Problem

Some sites don't work well as Omarchy web apps:

1. **Every link becomes a window.** A dashboard opens each item (a tracking
   page, a report) in a new tab. An app window has no tab strip, so each one
   becomes another full window on your screen.
2. **A link leaves the app.** A link inside the web app that opens a new tab
   (a solutions page, a help page) lands as a tab in your main Chrome window,
   not next to the app.

## Why it happens

`omarchy-launch-webapp` opens a site with `chrome --app=<url>`. That gives a
bare window with no tabs and no app scope of its own. A new tab can't open
inside it, so Chrome either opens a new window or hands the link to your
normal browser window.

## Fix

### Case 1: open the site in a regular browser window

If a site expects tabs, give it tabs. Write its launcher entry to open a
normal browser window. For example, `~/.local/share/applications/Example
Dashboard.desktop`:

```ini
[Desktop Entry]
Version=1.0
Name=Example Dashboard
Comment=Example Dashboard
Exec=omarchy-launch-browser --new-window "https://example.com/dashboard"
Terminal=false
Type=Application
Icon=example
StartupNotify=true
```

`omarchy-launch-browser` starts your default browser and passes the arguments
through. `--new-window` keeps it from becoming a tab in a window you already
have open.

### Case 2: install the page as a real Chrome app

A Chrome-installed app has its own scope. Links inside that scope open in app
windows, not in your main browser window.

1. Open the page in Chrome. From the Chrome menu, choose **Cast, save and
   share > Install page as app**.
2. Chrome writes `~/.local/share/applications/chrome-<app-id>-Default.desktop`.
   The 32-letter `<app-id>` is in that file name.

You can use Chrome's entry as it is. To get launch-or-focus, and a fallback
on machines where the app isn't installed, use a small script. Save it as
`~/.config/omarchy/example-app/launch`:

```bash
#!/bin/bash
# Opens the Chrome-installed app when this machine has it, so links stay in
# app windows. Otherwise falls back to a plain Omarchy web app window.
# Either way, an open window is focused instead.

app_id=abcdefghijklmnopabcdefghijklmnop
url=https://example.com/course/

if [[ -d "$HOME/.config/google-chrome/Default/Web Applications/Manifest Resources/$app_id" ]]; then
  exec omarchy-launch-or-focus "(chrome-|crx_)$app_id" \
    "uwsm-app -- google-chrome-stable --profile-directory=Default --app-id=$app_id"
fi

exec omarchy-launch-or-focus-webapp \
  "chrome-example.com__course_-Default" "$url"
```

Call `google-chrome-stable`, not `google-chrome`. The Arch `google-chrome`
package puts only `google-chrome-stable` on your `PATH`, so plain
`google-chrome` fails with "command not found" and no window opens.

Add your own launcher entry, and hide Chrome's so the app isn't listed twice:

```ini
[Desktop Entry]
Version=1.0
Name=Example App
Comment=Example App
Exec=/home/YOU/.config/omarchy/example-app/launch
Terminal=false
Type=Application
Icon=example
StartupNotify=true
StartupWMClass=crx_abcdefghijklmnopabcdefghijklmnop
```

Use your username in place of `YOU`. `Exec` doesn't expand `~`.

```bash
echo 'NoDisplay=true' >> ~/.local/share/applications/chrome-<app-id>-Default.desktop
```

## Apply and check

```bash
chmod +x ~/.config/omarchy/example-app/launch
hyprctl clients -j | jq -r '.[].class'
```

Start the app from the launcher and click a link that opens a new tab.

- **Case 1:** the link opens as a tab in the same browser window.
- **Case 2:** the link opens in an app window, and the window class starts
  with `crx_` or `chrome-<app-id>`.

## Undo

Delete the entries and the script. Uninstall the Chrome app from
`chrome://apps`.

## Notes

- Case 1 gives up the app-window look: you get Chrome's full tab strip and
  address bar for that site.
- If Chrome's own entry shows up in the launcher again, add
  `NoDisplay=true` back.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.

## Recipe data

```json
{
  "id": "duff/web-app-opens-links-in-new-windows-or-browser-tabs",
  "title": "A web app opens every link in a new window, or sends links out to a browser tab",
  "summary": "Open the site in a regular browser window, or install it as a real Chrome app.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2"},
  "applies_to": "Every machine (Google Chrome).",
  "requires": [{"command": "google-chrome-stable"}],
  "touches": ["~/.local/share/applications/*.desktop", "~/.config/omarchy/example-app/launch"],
  "root": false,
  "network": false,
  "installs": ["Chrome web app (Install page as app)"],
  "runs": [],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
```
