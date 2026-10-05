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

Add move bindings on a free chord in `~/.config/hypr/bindings.lua`.
Super+Ctrl+Shift+arrow is unused in stock:

```lua
-- SUPER+SHIFT+arrow only swaps two windows. These move the window next to its
-- neighbor instead, splitting that neighbor's space (dwindle).
o.bind("SUPER + CTRL + SHIFT + LEFT", "Move window left", hl.dsp.window.move({ direction = "l" }))
o.bind("SUPER + CTRL + SHIFT + RIGHT", "Move window right", hl.dsp.window.move({ direction = "r" }))
o.bind("SUPER + CTRL + SHIFT + UP", "Move window up", hl.dsp.window.move({ direction = "u" }))
o.bind("SUPER + CTRL + SHIFT + DOWN", "Move window down", hl.dsp.window.move({ direction = "d" }))
```

No `hl.unbind` is needed because these keys have no stock binding.

## Apply and check

```bash
hyprctl reload
hyprctl configerrors
```

Open three windows on one workspace. Focus the big one and press
Super+Ctrl+Shift+Right: it should leave its half and share the space of the
window on its right, instead of trading places with it.

## Undo

Delete the four bindings from `~/.config/hypr/bindings.lua`, then run
`hyprctl reload`.

## Notes

- At the edge of a monitor there is no window in that direction, so Hyprland
  moves the window to the next monitor that way. That comes from
  `binds.window_direction_monitor_fallback`, which is on by default.
- Super+Shift+arrow still swaps, so you keep both behaviors.
- The comment says dwindle because that is where the split behavior shows. In
  the scrolling layout the move follows that layout's own rules.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.

## Recipe data

```json
{
  "id": "duff/super-shift-arrow-only-swaps-windows",
  "title": "Super+Shift+arrow only swaps windows, can't move one into another's space",
  "summary": "Bind Super+Ctrl+Shift+arrow to move a window into its neighbor's split.",
  "version": 1,
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
