---
{
  "id": "duff/touchpad-palm-tap-clicks-things",
  "title": "A light palm tap on the touchpad clicks things",
  "summary": "Turn off tap-to-click so only a physical press clicks.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2"},
  "applies_to": "Laptops.",
  "requires": [{"laptop": true}],
  "touches": ["~/.config/hypr/input.lua"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": [],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
---

# A light palm tap on the touchpad clicks things

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

## Undo

Remove the `tap_to_click` line from `~/.config/hypr/input.lua`, or set it to
`true`, then run `hyprctl reload`.

## Notes

- Pairs well with
  [click-to-focus](../hovering-mouse-steals-keyboard-focus/RECIPE.md): then
  a stray touch neither clicks nor moves keyboard focus.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.
