# A lone window stretches across a big screen, but the square toggle squeezes the laptop too

## Problem

On a big external screen, such as a 5K or ultrawide monitor, a workspace with
one window stretches it edge to edge, which is too wide to read or work in.
Omarchy's "1-Window Ratio" toggle (Super+Ctrl+Backspace) keeps a lone window
square instead, but it applies to every screen. Away from the desk, on the
laptop screen alone, the same window becomes a narrow square with empty space
on both sides.

## Why it happens

The toggle runs `omarchy-hyprland-window-single-square-aspect-toggle`, which
switches `/usr/share/omarchy/default/hypr/toggles/single-window-aspect-ratio.lua`
on or off:

```lua
hl.config({
  layout = {
    single_window_aspect_ratio = { 1, 1 },
  },
})
```

`layout.single_window_aspect_ratio` is one Hyprland setting for every
monitor. There is no per-monitor version, so the toggle can't tell the big
screen from the laptop's.

## Fix

Set it from the monitors that are connected, and change it whenever one is
plugged in or unplugged. Add this to `~/.config/hypr/looknfeel.lua`:

```lua
-- A lone window keeps a square shape while an external screen is connected,
-- so it doesn't stretch across the whole screen, and fills the screen on the
-- laptop alone. Hyprland has one setting for every screen, so this replaces
-- Omarchy's "1-Window Ratio" toggle, which must stay off or it wins.
-- `removed` leaves out a monitor that is still listed while it's being removed.
local function square_lone_windows_on_external(removed)
  local external = false
  for _, monitor in ipairs(hl.get_monitors()) do
    if not monitor.name:match("^eDP") and not (removed and monitor.name == removed.name) then
      external = true
    end
  end
  hl.config({
    layout = {
      single_window_aspect_ratio = external and { 1, 1 } or { 0, 0 },
    },
  })
end

square_lone_windows_on_external()
hl.on("hyprland.start", function()
  square_lone_windows_on_external()
end)
hl.on("monitor.added", function()
  square_lone_windows_on_external()
end)
hl.on("monitor.removed", function(monitor)
  square_lone_windows_on_external(monitor)
end)
```

- `{ 0, 0 }` is Hyprland's default: no fixed shape, so the window fills the
  screen.
- It runs when the config loads and again at `hyprland.start`, since the
  monitor list can still be empty while the config first loads.
- While a monitor is being unplugged, `monitor.removed` fires with it still
  in `hl.get_monitors()`, which is why the function is told to skip it.
- `^eDP` matches a laptop's built-in panel. To square windows only on
  particular screens, test `monitor.description` instead, for example
  `monitor.description:match("Studio Display")`. Then another external
  monitor, like a projector, still gets the full width.

## Apply and check

Turn Omarchy's toggle off first if it's on (Super+Ctrl+Backspace, or
"1-Window Ratio" in the Toggle menu, shows which way it went). Then:

```bash
hyprctl reload
hyprctl configerrors
hyprctl getoption layout:single_window_aspect_ratio
```

With an external screen connected it prints `vec2: [1, 1]`, and with only
the laptop screen `vec2: [0, 0]`. Open a workspace with one window on each and
compare. Unplug the external screen, and a lone window on the laptop should
fill it again.

## Undo

Delete the function and the four lines after it from
`~/.config/hypr/looknfeel.lua`, then run `hyprctl reload`. Omarchy's toggle
works as before.

## Notes

- This only affects the default dwindle layout's lone windows. In the
  scrolling layout (Super+L), see
  [A lone window fills the whole screen in the scrolling layout](../lone-window-fills-the-screen-in-scrolling-layout/RECIPE.md).
- With the laptop open next to an external screen, the laptop's lone windows
  are square too, since the setting is still one for every screen.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-31.

## Recipe data

```json
{
  "id": "duff/lone-window-stretches-across-a-big-external-screen",
  "title": "A lone window stretches across a big screen, but the square toggle squeezes the laptop too",
  "summary": "Keep a lone window square only while an external screen is connected.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.5", "hyprland": "0.56.2"},
  "applies_to": "Laptops used with a big external screen.",
  "requires": [{"laptop": true}],
  "touches": ["~/.config/hypr/looknfeel.lua"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": [],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-31"}]
}
```
