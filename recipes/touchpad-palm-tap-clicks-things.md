# A light palm tap on the touchpad clicks things

**Tested on:** Omarchy 4.0.4, Hyprland 0.56.2 (Lua config)
**Applies to:** laptops

## Problem

Resting a palm on the touchpad, or grazing it, clicks whatever is under the
cursor: a link, a button, another window.

## Why it happens

Hyprland enables tap-to-click on touchpads by default
(`input.touchpad.tap_to_click`), and Omarchy's
`/usr/share/omarchy/default/hypr/input.lua` does not change it. Any short touch
counts as a click.

## Fix

Turn it off in `~/.config/hypr/input.lua` so only a physical press clicks:

```lua
hl.config({
  input = {
    touchpad = {
      tap_to_click = false,
    },
  },
})
```

Omarchy already sets `clickfinger_behavior = true`, so a physical press with
two fingers is still a right-click.

## Apply and check

```bash
hyprctl reload
hyprctl configerrors
hyprctl getoption input:touchpad:tap-to-click
```

It should print `bool: false`. Tapping the pad no longer clicks; pressing it
does.

## Notes

- Pairs well with click-to-focus (`hovering-mouse-steals-keyboard-focus.md`):
  then a stray touch neither clicks nor moves keyboard focus.
- To undo, remove the line or set it to `true`.
