# Scrolling direction feels backwards on the touchpad and mouse

**Tested on:** Omarchy 4.0.4, Hyprland 0.56.2 (Lua config)
**Applies to:** every machine

## Problem

Coming from macOS, two-finger scrolling on the touchpad moves the page the
wrong way. Turning on natural scrolling for the touchpad fixes the pad, but a
plugged-in mouse wheel still scrolls the old way, so the two disagree.

## Why it happens

Omarchy's defaults in `/usr/share/omarchy/default/hypr/input.lua` set
`touchpad.natural_scroll = false`. Hyprland has two separate switches:
`input.touchpad.natural_scroll` covers touchpads only, and
`input.natural_scroll` covers mice and every other non-touchpad pointer.
Setting just the touchpad one leaves mouse wheels alone.

## Fix

Set both in `~/.config/hypr/input.lua`:

```lua
hl.config({
  input = {
    -- Mice and other non-touchpads. The pad uses touchpad.natural_scroll.
    natural_scroll = true,
    touchpad = {
      natural_scroll = true,
    },
  },
})
```

If you only want it on the touchpad, drop the top-level `natural_scroll`.

## Apply and check

Hyprland reloads the file on save. To be sure:

```bash
hyprctl reload
hyprctl configerrors
hyprctl getoption input:natural_scroll
hyprctl getoption input:touchpad:natural_scroll
```

Both should print `int: 1` or `bool: true`.

## Notes

To undo, delete the lines or set them back to `false`.
