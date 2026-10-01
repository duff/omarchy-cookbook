# HiDPI screens are left on auto scale instead of a fixed 2x

**Tested on:** Omarchy 4.0.4, Hyprland 0.56.2 (Lua config)
**Applies to:** machines with 2x ("Retina") panels, such as a Dell XPS 16 with Apple Studio Displays or a Pro Display XDR, or a MacBook Air

## Problem

Stock Omarchy sets every screen's scale to `"auto"`. Hyprland then guesses a
scale for each screen from the pixel density in its EDID. On a desk of panels
built for exactly 2x (a 5K Studio Display, a 6K XDR, a 3200x2000 laptop panel)
you want 2, everywhere, every time. A guess can land on a fractional value or
differ from one screen to the next. Omarchy's own scripts also have no number
to go back to when they re-enable a screen.

## Why it happens

`/usr/share/omarchy/config/hypr/monitors.lua`, which the installer copies to
`~/.config/hypr/monitors.lua`, ships with:

```lua
local omarchy_gdk_scale = 2
local omarchy_monitor_scale = "auto"
```

The catch-all `hl.monitor({ output = "", ... })` rule uses that local for
every screen. `omarchy-hyprland-monitor-clamshell`, which turns the laptop
panel back on when the lid opens, reads the same local. When the value is
`"auto"`, the script leaves the scale to Hyprland. When the panel was fully
off, it falls back to whatever scale it remembered from before.

## Fix

In `~/.config/hypr/monitors.lua`, change the scale to a number:

```lua
local omarchy_gdk_scale = 2
local omarchy_monitor_scale = 2

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })
```

`GDK_SCALE` is already 2 in stock. Keep it matching the monitor scale.

If you add per-monitor rules later (see
[monitors-swap-sides-when-cables-change-ports.md](monitors-swap-sides-when-cables-change-ports.md)),
pass `scale = omarchy_monitor_scale` to each of them, so one line still
controls them all.

## Apply and check

```bash
hyprctl reload
hyprctl configerrors
hyprctl monitors -j | jq -r '.[] | "\(.name)  \(.scale)"'
```

Every screen should report `2`.

## Notes

- `Super + /` and `Super + Alt + /` run `omarchy hyprland monitor scaling up`
  and `down`. They change the focused screen right away and also **rewrite
  the `local omarchy_monitor_scale = ...` line** in `monitors.lua`. One
  accidental press therefore changes the pinned scale for every screen that
  uses the local. Set it back with `omarchy hyprland monitor scaling 2` (on
  the focused screen) or by editing the line.
- Those keys step through 1, 1.25, 1.6, 2, 3, 4 and then round to a value that
  divides the panel's resolution evenly. That is how a 5K screen ends up at
  3.2.
- To undo, set `omarchy_monitor_scale` back to `"auto"`.
