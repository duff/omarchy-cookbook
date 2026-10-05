# A launcher shortcut opens a second window instead of focusing the open one

## Problem

Press Super+Shift+E twice and you get two HEY windows. The same happens with
YouTube (Super+Shift+Y), X (Super+Shift+X), Herdr (Super+Ctrl+Return), and
any web app you start from the launcher (Super+Space). Super+Shift+Return
opens a new browser window every time, just like Super+Shift+B.

Most of the time you want the window that is already open, not a new one.

## Why it happens

The stock bindings are in
`/usr/share/omarchy/default/hypr/bindings/applications.lua`. Most web apps are
bound like this:

```lua
o.bind("SUPER + SHIFT + E", "Email", { webapp = "https://app.hey.com" })
```

`o.bind` (in `/usr/share/omarchy/default/hypr/helpers.lua`) turns
`{ webapp = url }` into `omarchy-launch-webapp <url>`, which always starts a
new Chrome app window. Only a few stock entries (WhatsApp, Google Messages,
Google Photos, Google Maps) add `focus = true`, which switches to
`omarchy-launch-or-focus-webapp`.

`focus = true` has a catch: it uses the binding's *description* as the window
pattern. `omarchy-launch-or-focus` then tests that pattern, case-insensitively
and with word boundaries, against every window's class **and** title, and
focuses the first match. So:

- `"Email"` isn't in the HEY window's class or title, so a new window opens
  anyway.
- `"YouTube"` also matches a regular Chrome tab whose title ends in
  "- YouTube".
- `"X"` matches the X Post compose window, and anything else with a lone "X"
  in its title.

Launcher entries have the same problem. `omarchy webapp install` and the stock
entries in `~/.local/share/applications/` use
`Exec=omarchy-launch-webapp <url>`, which never focuses.

The reliable pattern is the window class. Chrome names an app window
`chrome-<host>_<path with / turned into _>-Default`, and leaves out any
`?query` and `#fragment`. For example:

| URL | Window class |
|---|---|
| `https://app.hey.com` | `chrome-app.hey.com__-Default` |
| `https://app.todoist.com/app` | `chrome-app.todoist.com__app-Default` |
| `https://x.com/compose/post` | `chrome-x.com__compose_post-Default` |

To see the class of a window that is open now:

```bash
hyprctl clients -j | jq -r '.[].class'
```

## Fix

### Keyboard shortcuts

In `~/.config/hypr/bindings.lua`, unbind the stock key and bind it again with a
focus pattern.

```lua
-- The label "Todoist" matches the window's class, so focus = true is enough.
o.bind("SUPER + SHIFT + T", "Todoist", { webapp = "https://app.todoist.com/app", focus = true })

-- Match the main HEY window's class. The new-email window from
-- Super+Shift+Alt+E has a different class (app.hey.com__messages_new),
-- so it is never the one picked.
hl.unbind("SUPER + SHIFT + E")
o.bind("SUPER + SHIFT + E", "Email", o.launch_webapp_sole("app\\.hey\\.com__-", "https://app.hey.com"))

-- Exact classes, so a YouTube tab in Chrome or the X Post window is not picked.
hl.unbind("SUPER + SHIFT + Y")
hl.unbind("SUPER + SHIFT + X")
o.bind("SUPER + SHIFT + Y", "YouTube", o.launch_webapp_sole("chrome-youtube.com__-Default", "https://youtube.com/"))
o.bind("SUPER + SHIFT + X", "X", o.launch_webapp_sole("chrome-x.com__-Default", "https://x.com/"))

-- Herdr: launch it as a TUI with a known app id (org.omarchy.herdr), so the
-- open window can be found.
hl.unbind("SUPER + CTRL + RETURN")
o.bind("SUPER + CTRL + RETURN", "Herdr", "omarchy-launch-or-focus-tui herdr")

-- Super+Shift+Return focuses the last-used browser window.
-- Super+Shift+B still opens a new one.
hl.unbind("SUPER + SHIFT + RETURN")
o.bind("SUPER + SHIFT + RETURN", "Browser (focus)", "~/.config/omarchy/browser/focus")
```

`o.launch_webapp_sole(pattern, url)` is a stock helper. It returns
`omarchy-launch-or-focus-webapp <pattern> <url>`. The pattern is a regex, so
escape dots when you want them to be literal. In a Lua string, that means
`\\.`.

For a native app, the stock form is
`{ launch = "obsidian", focus = "^obsidian$" }`.

When the site's window title spells its name differently from your label
(one word instead of two, for example), `focus = true` won't find it. Pass
the class or the title word to `o.launch_webapp_sole` instead.

The browser focus script, `~/.config/omarchy/browser/focus`:

```bash
#!/bin/bash
# Focus the most recently used Chrome browser window, or open one when none is
# open. Web app windows have their own chrome-<site> class, so they never match.
# A private window looks the same to Hyprland, so it can be the one picked.

address=$(hyprctl clients -j | jq -r '[.[] | select(.class == "google-chrome")] | sort_by(.focusHistoryID) | .[0].address // empty')

if [[ -n $address ]]; then
  hyprctl dispatch "hl.dsp.focus({ window = \"address:$address\" })" >/dev/null
else
  exec omarchy-launch-browser
fi
```

The lowest `focusHistoryID` is the window you used most recently. If your
browser is Chromium, change the class to `chromium`. Make the script
executable with `chmod +x`.

### Launcher (Super+Space) entries

The launcher runs the `Exec=` line of each `.desktop` file in
`~/.local/share/applications/`. This script rewrites the line of every web
app entry to launch or focus, working out the window class from the entry's
URL. Save it as `~/.config/omarchy/launchers/focus-webapps`:

```bash
#!/usr/bin/env bash
# Make every web app launcher focus its open window instead of opening another.
# `omarchy webapp install` writes Exec=omarchy-launch-webapp <url>; this turns
# that into omarchy-launch-or-focus <class> "omarchy-launch-webapp '<url>'".
# Keeping omarchy-launch-webapp in the line lets `omarchy webapp remove` still
# find the app. Older omarchy-launch-or-focus-webapp entries move to the same
# form and keep their pattern. Entries with any other Exec are left alone.
# focus-webapps.path runs this whenever a launcher is added or rewritten, so
# new web apps get it too.
#
# Chrome names an app window chrome-<host>_<path with / as _>-Default and
# leaves out the ?query and #fragment.
set -euo pipefail

apps="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
# The path unit fires on every write here, so one run can start while another
# is still going. Take turns.
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/focus-webapps.lock"
flock 9

plain_re='^Exec=omarchy-launch-webapp "?([^" ]+)"?$'
focus_re='^Exec=omarchy-launch-or-focus-webapp "([^"]+)" "?([^" ]+)"?$'

for file in "$apps"/*.desktop; do
  [[ -f $file ]] || continue
  line=$(grep -m1 '^Exec=' "$file") || continue

  if [[ $line =~ $focus_re ]]; then
    class=${BASH_REMATCH[1]}
    url=${BASH_REMATCH[2]}
  elif [[ $line =~ $plain_re ]]; then
    url=${BASH_REMATCH[1]}
    rest=${url#*://}
    rest=${rest%%#*}
    rest=${rest%%\?*}
    host=${rest%%/*}
    path=${rest:${#host}}
    path=${path:-/}
    class="chrome-${host}_${path//\//_}-Default"
  else
    continue
  fi

  # A rewritten entry matches neither pattern, so the path unit's rerun after
  # this write changes nothing. The single quotes keep a # or & in the URL part
  # of it when omarchy-launch-or-focus runs the command.
  new="Exec=omarchy-launch-or-focus \"$class\" \"omarchy-launch-webapp '$url'\""
  # Write a temp file beside it, then rename it over the launcher, so a reader
  # never sees a half-written file.
  tmp=$(mktemp "$apps/.focus-webapps.XXXXXX")
  awk -v new="$new" '!done && /^Exec=/ { print new; done = 1; next } { print }' "$file" > "$tmp"
  chmod --reference="$file" "$tmp"
  mv "$tmp" "$file"
done
```

New web apps, and stock entries that `omarchy refresh applications` (or an
update) copies back, need the same rewrite. A systemd path unit reruns the
script whenever something in that folder changes.

`~/.config/systemd/user/focus-webapps.path`:

```ini
[Unit]
Description=Make new web app launchers focus their open window

[Path]
PathChanged=%h/.local/share/applications
Unit=focus-webapps.service

[Install]
WantedBy=default.target
```

`~/.config/systemd/user/focus-webapps.service`:

```ini
[Unit]
Description=Make web app launchers focus their open window

[Service]
Type=oneshot
ExecStart=%h/.config/omarchy/launchers/focus-webapps
```

The script only writes entries it changes, and a rewritten entry matches
neither pattern, so its own writes don't start it again in a loop.

HEY's entry is also the `mailto:` handler, so it needs a small launch script
instead. See
[mailto: links open in Chrome instead of HEY](../mailto-links-open-in-chrome-instead-of-hey/RECIPE.md).
Its launch script replaces the `Exec=` line, so this script leaves it alone.

## Apply and check

```bash
hyprctl reload
hyprctl configerrors
chmod +x ~/.config/omarchy/launchers/focus-webapps ~/.config/omarchy/browser/focus
systemctl --user daemon-reload
systemctl --user enable --now focus-webapps.path
~/.config/omarchy/launchers/focus-webapps
grep -h '^Exec=omarchy-launch-or-focus ' ~/.local/share/applications/*.desktop
```

Every web app should be listed, with its window class first.

Press a shortcut twice, or pick the same launcher entry twice. The second
time, the open window gets focus and no new one opens.

## Undo

Delete your lines from `bindings.lua`, then stop the watcher and delete the
files:

```bash
systemctl --user disable --now focus-webapps.path
rm ~/.config/systemd/user/focus-webapps.{path,service}
rm ~/.config/omarchy/launchers/focus-webapps ~/.config/omarchy/browser/focus
systemctl --user daemon-reload
```

The rewritten entries keep working, and focus as before. To get the stock
entries back, run `omarchy refresh applications` for Omarchy's own web apps,
and reinstall others with `omarchy webapp install`.

## Notes

- An earlier version of this recipe rewrote a hand-made list of entries to
  `omarchy-launch-or-focus-webapp "<class>" <url>`. The script moves those to
  the new form and keeps their class, so a hand-picked pattern survives.
- A site that opens its app window on a different address than the one you
  installed (a redirect to `/app`, say) gets a class that doesn't match.
  Check with `hyprctl clients -j | jq -r '.[].class'` and install the web app
  with the address the window ends up on.
- To swap two stock web app keys (for example, Grok on Super+Shift+A and
  ChatGPT on Super+Shift+Alt+A), unbind both keys before you bind either
  one. Otherwise both actions fire on the same key.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.

## Recipe data

```json
{
  "id": "duff/launcher-shortcut-opens-a-second-window",
  "title": "A launcher shortcut opens a second window instead of focusing the open one",
  "summary": "Rebind shortcuts, and rewrite every web app launcher, to focus the open window by its class.",
  "version": 2,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2"},
  "applies_to": "Every machine.",
  "requires": [],
  "touches": ["~/.config/hypr/bindings.lua", "~/.config/omarchy/browser/focus", "~/.config/omarchy/launchers/focus-webapps", "~/.config/systemd/user/focus-webapps.path", "~/.config/systemd/user/focus-webapps.service", "~/.local/share/applications/*.desktop"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": ["focus-webapps.path, a user systemd path unit that reruns focus-webapps when a launcher changes"],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
```
