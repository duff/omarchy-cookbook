# Super+Shift+arrow only swaps windows, can't move one into another's space

## Problem

Super+Shift+arrow trades places with the neighboring window. The two windows
keep each other's sizes and the layout shape stays the same. There is no stock
key to take a window out of its spot and drop it next to a neighbor, splitting
that neighbor's space, which is how you rearrange a three- or four-window
layout.

## Why it happens

`/usr/share/omarchy/default/hypr/bindings/tiling.lua` binds the arrows with
Shift to `hl.dsp.window.swap`:

```lua
o.bind("SUPER + SHIFT + LEFT", "Swap window to the left", hl.dsp.window.swap({ direction = "l" }))
```

Hyprland's move dispatcher, `hl.dsp.window.move({ direction = ... })`, does the
other thing: it pulls the window out of the tree and inserts it beside the
window in that direction. Omarchy uses `window.move` for workspaces and
groups, but not for plain directions.

## Fix

Bind the move to Super+Alt+Shift+arrow in `~/.config/hypr/bindings.lua`. Stock
uses that chord to move the whole workspace to the next monitor, so unbind it
first and give that action Super+Ctrl+Shift+arrow, which is unused in stock:

```lua
-- SUPER+SHIFT+arrow only swaps two windows. SUPER+ALT+SHIFT+arrow moves the
-- window next to its neighbor instead, splitting that neighbor's space (dwindle).
-- Stock SUPER+ALT+SHIFT+arrow moves the workspace to another monitor; that's
-- SUPER+CTRL+SHIFT+arrow here.
for _, dir in ipairs({ { "LEFT", "l", "left" }, { "RIGHT", "r", "right" }, { "UP", "u", "up" }, { "DOWN", "d", "down" } }) do
  hl.unbind("SUPER + SHIFT + ALT + " .. dir[1])
  o.bind("SUPER + ALT + SHIFT + " .. dir[1], "Move window " .. dir[3], hl.dsp.window.move({ direction = dir[2] }))
  o.bind("SUPER + CTRL + SHIFT + " .. dir[1], "Move workspace to " .. dir[3] .. " monitor", hl.dsp.workspace.move({ monitor = dir[2] }))
end
```

If you'd rather keep stock's workspace keys, skip the `hl.unbind` and the
workspace line, and put the window move on Super+Ctrl+Shift+arrow instead.

## Apply and check

```bash
hyprctl reload
hyprctl configerrors
```

Open three windows on one workspace. Focus the big one and press
Super+Alt+Shift+Right: it should leave its half and share the space of the
window on its right, instead of trading places with it. With two monitors,
Super+Ctrl+Shift+Right should send the whole workspace to the right-hand one.

## Undo

Delete the loop from `~/.config/hypr/bindings.lua`, then run `hyprctl reload`.
Stock's Super+Alt+Shift+arrow workspace move comes back with it.

## Notes

- At the edge of a monitor there is no window in that direction, so Hyprland
  moves the window to the next monitor that way. That comes from
  `binds.window_direction_monitor_fallback`, which is on by default.
- Super+Shift+arrow still swaps, so you keep both behaviors.
- The comment says dwindle because that is where the split behavior shows. In
  the scrolling layout the move follows that layout's own rules.
- Version 1 put the window move on Super+Ctrl+Shift+arrow and left stock's
  workspace keys alone.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.

## Recipe data

```json
{
  "id": "duff/super-shift-arrow-only-swaps-windows",
  "title": "Super+Shift+arrow only swaps windows, can't move one into another's space",
  "summary": "Bind Super+Alt+Shift+arrow to move a window into its neighbor's split, and move stock's workspace-to-monitor keys to Super+Ctrl+Shift+arrow.",
  "version": 2,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2"},
  "applies_to": "Every machine using the dwindle layout (Omarchy's default).",
  "requires": [],
  "touches": ["~/.config/hypr/bindings.lua"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": [],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
```
