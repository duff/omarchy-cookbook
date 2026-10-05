# Moving the mouse or brushing the touchpad steals keyboard focus

## Problem

You are typing in one window, the cursor drifts over another one (a palm
brushes the touchpad, or you nudge the mouse), and your next keystrokes land in
the wrong window.

## Why it happens

Omarchy sets `follow_mouse = 1` in `/usr/share/omarchy/default/hypr/input.lua`.
In Hyprland that means keyboard focus follows the cursor: whatever window is
under the pointer gets your typing.

A second Hyprland setting, `float_switch_override_focus`, moves focus on its
own when the cursor crosses from a floating window onto a tiled one, or back.
Omarchy leaves it at Hyprland's default, `1`, so that crossing moves focus
even after the fix below.

## Fix

Use `follow_mouse = 2` in `~/.config/hypr/input.lua`, and turn off
`float_switch_override_focus`:

```lua
hl.config({
  input = {
    follow_mouse = 2, -- click for keyboard focus; hover still scrolls
    -- Hovering from a floating window onto a tiled one, or back, would
    -- otherwise move keyboard focus too.
    float_switch_override_focus = 0,
  },
})
```

With `2`, cursor focus and keyboard focus are separate. Hovering a window still
sends it scroll events, so you can scroll a background window without clicking
it, but keyboard focus only moves when you click (or use a focus keybinding).
With `float_switch_override_focus = 0`, that holds for floating windows too.

## Apply and check

```bash
hyprctl reload
hyprctl configerrors
hyprctl getoption input:follow_mouse
hyprctl getoption input:float_switch_override_focus
```

They should print `int: 2` and `int: 0`. Type in one window, move the cursor
over another, and keep typing: the text stays where it was. Try it from a
floating window onto a tiled one too.

## Undo

Remove the two lines; Omarchy's `follow_mouse = 1` and Hyprland's
`float_switch_override_focus = 1` come back.

## Notes

- Pairs well with turning off tap-to-click
  ([A light palm tap on the touchpad clicks things](../touchpad-palm-tap-clicks-things/RECIPE.md)),
  so a stray touch neither clicks nor moves keyboard focus.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.

## Recipe data

```json
{
  "id": "duff/hovering-mouse-steals-keyboard-focus",
  "title": "Moving the mouse or brushing the touchpad steals keyboard focus",
  "summary": "Make keyboard focus follow clicks, while hover still scrolls.",
  "version": 2,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2"},
  "applies_to": "Every machine (most noticeable on laptops).",
  "requires": [],
  "touches": ["~/.config/hypr/input.lua"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": [],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
```
