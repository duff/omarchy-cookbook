# Wine app quits on Super+W, or pops back up after you hide it

## Problem

You want a big Windows app, here a stock market trading app, open all day but
out of the way, and one key away:

- Tiled, it gets squeezed into a share of one screen. You want it to fill
  every big screen.
- There is no "hide": `Super + W` quits it, and starting it again under Wine
  is slow.
- Parking it on another workspace does not last. When another X11 app (here
  Spotify) takes focus, Hyprland jumps back to the hidden workspace.

## Why it happens

- Omarchy tiles new windows and binds `Super + W` to "close window"
  (`/usr/share/omarchy/default/hypr/bindings/tiling.lua`).
- Omarchy sets `misc.focus_on_activate = true`
  (`/usr/share/omarchy/default/hypr/looknfeel.lua`), so a window that asks to
  be activated gets focus, and Hyprland switches to its workspace. When focus
  moves between X11 apps, Wine asks to activate its main window.
- Two Wine-specific details rule out the obvious fixes. Wine draws menus as
  separate small X11 windows. Hyprland 0.56 files those popups under the
  normal workspace they open on, and draws special workspaces (scratchpads)
  above that, so on a special workspace the menus open underneath the app. A
  workspace rule for the app's class would also catch the menu windows and
  move them away from the menu bar.

## Fix

Keep the main window floating on its own named workspace, `trading`, which
the bar does not list. A toggle script shows it stretched across the screens,
or switches back to the previous workspace to hide it.

### Toggle script

`~/.config/tradingapp/toggle` (make it executable). `TradingApp` stands in for
your program's name throughout. Change `prefix`, `app_dir`, the exe name, and
the window class and title to match your app.
`hyprctl clients` shows the class and title:

```bash
#!/usr/bin/env bash
# Show or hide TradingApp without closing it. Starts it first if it isn't running.
# With --show it only shows, and re-fits the window if it has drifted (the
# app-menu entry uses this).
#
# TradingApp runs under Wine. Its main window lives on the named workspace
# "trading", which the bar does not list. Showing it stretches the window across
# every connected Studio Display, below the top bar, and puts "trading" on the
# monitor under the window's centre: Hyprland assigns a floating window to that
# monitor. Hiding switches that monitor back to its previous workspace. Without
# Studio Displays the window fills the focused monitor instead.
#
# A normal workspace rather than a special one: Hyprland files Wine's menus under
# the normal workspace they open on, and draws special workspaces above that, so
# the menus would open underneath TradingApp.
set -euo pipefail

prefix="$HOME/.local/share/wineprefixes/tradingapp"
app_dir="$prefix/drive_c/Program Files/TradingApp"
ws=trading

main_window() {
  hyprctl clients -j | jq -r '[.[] | select(.class == "tradingapp.exe" and (.title | test("^TradingApp - ")))][0].address // empty'
}

shown_on() {
  hyprctl monitors -j | jq -r --arg ws "$ws" '.[] | select(.activeWorkspace.name == $ws) | .name'
}

show() {
  local addr=$1 name x y w h
  read -r x y w h < <(hyprctl monitors -j | jq -r '
    ([.[] | select(.model == "StudioDisplay")] | sort_by(.x)) as $studios
    | (if ($studios | length) > 0 then $studios else [.[] | select(.focused)] end) as $mons
    | $mons[0] as $left
    | "\($left.x) \($left.y + $left.reserved[1]) \([$mons[] | .width / .scale] | add | floor) \(($left.height / $left.scale - $left.reserved[1]) | floor)"')
  name=$(hyprctl monitors -j | jq -r --argjson cx $((x + w / 2)) \
    'first(.[] | select(.x <= $cx and $cx < .x + .width / .scale) | .name)')

  hyprctl dispatch "hl.dsp.window.move({ window = \"address:$addr\", workspace = \"name:$ws\", follow = false })" >/dev/null
  # A tiled window ignores the resize and move below.
  hyprctl dispatch "hl.dsp.window.float({ window = \"address:$addr\", action = \"enable\" })" >/dev/null

  # Show the workspace on the centre monitor, pulling it over if it lives elsewhere.
  hyprctl dispatch "hl.dsp.focus({ monitor = \"$name\" })" >/dev/null
  hyprctl dispatch "hl.dsp.focus({ workspace = \"name:$ws\", on_current_monitor = true })" >/dev/null

  # Resize first: a resize grows around the window's centre, the move then pins the corner.
  hyprctl dispatch "hl.dsp.window.resize({ window = \"address:$addr\", x = $w, y = $h })" >/dev/null
  hyprctl dispatch "hl.dsp.window.move({ window = \"address:$addr\", x = $x, y = $y })" >/dev/null
  hyprctl dispatch "hl.dsp.focus({ window = \"address:$addr\" })" >/dev/null
}

hide() {
  local monitor=$1
  hyprctl dispatch "hl.dsp.focus({ monitor = \"$monitor\" })" >/dev/null
  hyprctl dispatch 'hl.dsp.focus({ workspace = "previous_per_monitor" })' >/dev/null
  # No earlier workspace on that monitor: fall back to an empty one.
  if [[ $(shown_on) == "$monitor" ]]; then
    hyprctl dispatch 'hl.dsp.focus({ workspace = "emptym" })' >/dev/null
  fi
}

addr=$(main_window)

if [[ -z $addr ]]; then
  setsid uwsm-app -- env -C "$app_dir" WINEPREFIX="$prefix" WINEDEBUG=-all wine TradingApp.exe >/dev/null 2>&1 &
  for _ in $(seq 180); do
    addr=$(main_window)
    [[ -n $addr ]] && break
    sleep 0.5
  done
  if [[ -z $addr ]]; then
    notify-send "TradingApp" "The main window did not open within 90 seconds."
    exit 1
  fi
  show "$addr"
  exit 0
fi

monitor=$(shown_on)
if [[ ${1:-} == --show || -z $monitor ]]; then
  show "$addr"
else
  hide "$monitor"
fi
```

Notes on the script:

- The span is computed from `hyprctl monitors`: every screen whose `model` is
  `StudioDisplay`, left to right, below the bar (`reserved[1]` is the space
  reserved at the top of the screen, which is the bar). Change the `select(.model == ...)` test for your screens. With
  none of them connected, the window fills the focused screen.
- A floating window belongs to the monitor under its centre, so the script
  shows the workspace on that monitor before it resizes the window.
- The main window is told apart from dialogs by its title. This app titles it
  `TradingApp - <workspace name>`, after the app's own saved layout that is
  open.

### Hyprland rules and keys

In `~/.config/hypr/tradingapp.lua` (loaded with
`require("hypr.tradingapp")` at the end of `~/.config/hypr/hyprland.lua`):

```lua
-- Float everything: the main window is only titled "TradingApp - <workspace>"
-- after it maps, so a title match would leave it tiled. No workspace rule:
-- Wine draws menus as small windows, and a workspace rule would move them off
-- the monitor under the menu bar.
-- No focus_on_activate: when another X11 app (Spotify) takes focus, Wine asks
-- to activate the main window, and Omarchy's default would switch to the
-- hidden "trading" workspace. The toggle focuses it directly, so it still works.
o.window({ class = "^tradingapp\\.exe$" }, {
  float = true,
  tag = "-default-opacity",
  opacity = "1 1",
  focus_on_activate = false,
})

o.bind("SUPER + A", "Show or hide TradingApp", os.getenv("HOME") .. "/.config/tradingapp/toggle")

-- SUPER+W on the main window hides it (same as SUPER+A) instead of closing
-- it, so a stray press doesn't quit the app. Its dialogs and every other
-- window still close.
hl.unbind("SUPER + W")
o.bind("SUPER + W", "Close window", function()
  local window = hl.get_active_window()
  if window and window.class == "tradingapp.exe" and (window.title or ""):find("^TradingApp %- ") then
    hl.exec_cmd(os.getenv("HOME") .. "/.config/tradingapp/toggle")
  else
    hl.dispatch(hl.dsp.window.close())
  end
end)
```

- `tag = "-default-opacity"` and `opacity = "1 1"` drop Omarchy's slight
  window transparency, which charts do not need.
- `Super + A` is free in stock Omarchy. `Super + W` is not, so it is
  unbound first and rebound to a Lua function that closes every window except
  this one.
- To quit the app for real, use its own File > Exit.

### App-menu entry

Wine's installer adds an app-menu entry that starts the app without the
layout. Point it at the script instead. Wine writes these under
`~/.local/share/applications/wine/Programs/`:

```bash
sed -i "s|^Exec=.*|Exec=$HOME/.config/tradingapp/toggle --show|" \
  ~/.local/share/applications/wine/Programs/TradingApp/TradingApp.desktop
```

## Apply and check

```bash
hyprctl reload
hyprctl configerrors
```

Press `Super + A`: the app starts (or appears) across the screens. Press it
again, or `Super + W` on the main window, and you are back on the workspace
you came from. Click into Spotify (or any other X11 app) and the hidden app
should stay hidden. Open one of the app's menus to check it draws on top.

## Undo

Delete `~/.config/hypr/tradingapp.lua` and its `require` line in
`~/.config/hypr/hyprland.lua`, then run `hyprctl reload`. `Super + W` goes
back to Omarchy's close.

The app-menu entry still runs the toggle script. Put its original `Exec=`
line back before you delete `~/.config/tradingapp/`.

## Notes

- Hiding uses `previous_per_monitor`. If that monitor had no earlier
  workspace, it switches to an empty one (`emptym`).
- `focus_on_activate = false` only affects this app. Other apps keep
  Omarchy's default.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.

## Recipe data

```json
{
  "id": "duff/wine-app-quits-on-super-w-or-pops-back-up-when-hidden",
  "title": "Wine app quits on Super+W, or pops back up after you hide it",
  "summary": "Show and hide an all-day Wine app with one key, and make Super+W hide it instead of closing it.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2", "wine": "11"},
  "applies_to": "A Windows app under Wine that you keep open all day (tested with a stock market trading app that is only available for Windows, spread across two Apple Studio Displays).",
  "requires": [{"command": "wine"}],
  "touches": ["~/.config/tradingapp/toggle", "~/.config/hypr/tradingapp.lua", "~/.config/hypr/hyprland.lua", "~/.local/share/applications/wine/Programs/TradingApp/TradingApp.desktop"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": [],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
```
