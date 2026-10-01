# A launcher shortcut opens a second window instead of focusing the open one

**Tested on:** Omarchy 4.0.4, Hyprland 0.56.2 (Lua config)
**Applies to:** every machine

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
`~/.local/share/applications/`. This script rewrites that line to launch or
focus. It skips any entry that isn't installed. Save it as
`~/.config/omarchy/launchers/apply.sh`:

```bash
#!/usr/bin/env bash
# Make these launcher (Super+Space) entries focus the open window instead of
# opening another. Omarchy and `omarchy webapp install` write the entries, so
# this rewrites their Exec line in place. An entry this machine lacks is skipped.
#
# The pattern is the window's class. Chrome names an app window
# chrome-<host>_<path with / as _>-Default and leaves out the ?query and #fragment.
set -euo pipefail

apps="${XDG_DATA_HOME:-$HOME/.local/share}/applications"

while IFS='|' read -r name class; do
  file="$apps/$name.desktop"
  [[ -f $file ]] || continue
  sed -i -E "s#^Exec=omarchy-launch-(webapp|or-focus-webapp \"[^\"]*\") #Exec=omarchy-launch-or-focus-webapp \"$class\" #" "$file"
done <<'APPS'
GitHub|chrome-github.com__-Default
Google Photos|chrome-photos.google.com__-Default
Todoist|chrome-app.todoist.com__app-Default
YouTube|chrome-youtube.com__-Default
X|chrome-x.com__-Default
APPS
```

The left column is the `.desktop` file name without the extension. The sed
also matches lines it already rewrote, so you can run the script again after
you change a class.

HEY's entry is also the `mailto:` handler, so it needs a small launch script
instead. See
[mailto-links-open-in-chrome-instead-of-hey.md](mailto-links-open-in-chrome-instead-of-hey.md).

## Apply and check

```bash
hyprctl reload
hyprctl configerrors
chmod +x ~/.config/omarchy/launchers/apply.sh ~/.config/omarchy/browser/focus
~/.config/omarchy/launchers/apply.sh
grep -h '^Exec=' ~/.local/share/applications/{YouTube,X}.desktop
```

Press a shortcut twice, or pick the same launcher entry twice. The second
time, the open window gets focus and no new one opens.

## Notes

- New web apps: `omarchy webapp install "GitHub" "https://github.com/" <icon>`
  writes an `omarchy-launch-webapp` entry. Add its name and class to the list
  and run the script again. `omarchy webapp install` also takes an optional
  fourth argument, a full custom `Exec` command, so you can write
  `omarchy-launch-or-focus-webapp "<class>" "<url>"` there from the start.
- `omarchy refresh applications` copies the stock entries (HEY, X, YouTube,
  Google Photos, and others) back over yours, and an update migration can
  run it too. Run the script again afterwards, or call it from a `post-update`
  hook (see
  [mailto-links-open-in-chrome-instead-of-hey.md](mailto-links-open-in-chrome-instead-of-hey.md)
  for an example).
- To swap two stock web app keys (for example, Grok on Super+Shift+A and
  ChatGPT on Super+Shift+Alt+A), unbind both keys before you bind either
  one. Otherwise both actions fire on the same key.
- To undo, delete your lines from `bindings.lua`. To get the stock launcher
  entries back, reinstall the web app with `omarchy webapp install`.
