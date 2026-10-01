# Super+J shows a Lua error on a scrolling-layout workspace

**Tested on:** Omarchy 4.0.4, Hyprland 0.56.2 (Lua config)
**Applies to:** every machine

## Problem

After switching a workspace to the scrolling layout with Super+L, pressing
Super+J raises a Hyprland Lua runtime error: `no such layoutmsg for scrolling`.
Nothing else happens.

## Why it happens

`/usr/share/omarchy/default/hypr/bindings/tiling.lua` binds Super+J to
"Toggle window split":

```lua
o.bind("SUPER + J", "Toggle window split", hl.dsp.layout("togglesplit"))
```

`togglesplit` is a dwindle layout message. Super+L
(`omarchy-hyprland-workspace-layout-toggle`) flips the current workspace
between dwindle and scrolling, and the scrolling layout has no `togglesplit`,
so the dispatch fails.

## Fix

Replace the bind in `~/.config/hypr/bindings.lua` with one that checks the
workspace's layout first and does nothing outside dwindle:

```lua
-- SUPER+J was Toggle window split. Dwindle-only; scrolling raises
-- "no such layoutmsg for scrolling".
hl.unbind("SUPER + J")
o.bind("SUPER + J", "Toggle window split", function()
  local ws = hl.get_active_special_workspace() or hl.get_active_workspace()
  if not ws or ws.tiled_layout ~= "dwindle" then
    return
  end
  hl.dispatch(hl.dsp.layout("togglesplit"))
end)
```

`hl.unbind` drops the stock bind so the two don't both fire. The special
workspace (scratchpad) is checked first because it can be open on top of a
regular workspace.

## Apply and check

```bash
hyprctl reload
hyprctl configerrors
```

On a dwindle workspace with two windows, Super+J still flips the split. Press
Super+L to switch to scrolling, then Super+J: no error.

## Notes

To undo, delete the block. The stock bind comes back on reload.
