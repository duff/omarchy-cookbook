# Hard to see which window is focused

**Tested on:** Omarchy 4.0.4, Hyprland 0.56.2 (Lua config)
**Applies to:** every machine (most noticeable on large or high-DPI screens)

## Problem

With several tiled windows on a big screen, the focused window is hard to pick
out. The colored border around it is thin, and on a scaled display it is
thinner still relative to everything else.

## Why it happens

`/usr/share/omarchy/default/hypr/looknfeel.lua` sets
`general.border_size = 2`. The theme decides the active and inactive border
colors, but the width stays at 2 pixels.

## Fix

Raise the border width in `~/.config/hypr/looknfeel.lua`, which loads after
Omarchy's defaults:

```lua
-- Slightly wider window borders so the focused window is easier to spot.
hl.config({
  general = {
    border_size = 3,
  },
})
```

One pixel more is enough to make the focused window obvious without making
the layout feel heavy. Try 4 if 3 is not enough.

## Apply and check

Hyprland reloads on save. Then:

```bash
hyprctl reload
hyprctl configerrors
hyprctl getoption general:border_size
```

The last command should print `int: 3`.

## Notes

- The stock `~/.config/hypr/looknfeel.lua` has a commented example with `dim_inactive = true` and
  `dim_strength = 0.15` under `decoration`. Dimming the unfocused windows is
  another way to make focus stand out, and it combines with a wider border.
- A window rule can give one app its own border, focused or not, which helps
  tell two similar windows apart:
  `o.window({ class = "^<app-class>$" }, { border_color = "rgb(e8710a)", border_size = 4 })`.
  See [two-web-app-windows-for-the-same-site-get-mixed-up.md](two-web-app-windows-for-the-same-site-get-mixed-up.md).
- To undo, delete the block. The width goes back to 2.
