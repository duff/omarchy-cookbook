# A lone window fills the whole screen in the scrolling layout

## Problem

Super+L switches a workspace to the scrolling layout, where each window is a
column about half the screen wide. On a workspace with only one window,
nothing seems to happen: the window still fills the screen. It only shrinks
to a column once a second window opens.

## Why it happens

Omarchy sets `scrolling.column_width = 0.49` in
`/usr/share/omarchy/default/hypr/looknfeel.lua`, but leaves
`scrolling.fullscreen_on_one_column` at Hyprland's default, `true`. With that
on, Hyprland stretches a workspace's only column to the full width.

## Fix

Turn it off in `~/.config/hypr/looknfeel.lua`:

```lua
-- A lone window in the scrolling layout (Super+L) keeps its half-width
-- column instead of filling the screen.
hl.config({
  scrolling = {
    fullscreen_on_one_column = false,
  },
})
```

## Apply and check

```bash
hyprctl reload
hyprctl configerrors
hyprctl getoption scrolling:fullscreen_on_one_column
```

It should print `bool: false`. On a workspace with one window, press Super+L.
The window should shrink to a half-width column.

## Undo

Delete the lines. Hyprland's default comes back, and a lone window fills the
screen again.

## Notes

- Super+F still makes any window fullscreen when you want that.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-02.

## Recipe data

```json
{
  "id": "duff/lone-window-fills-the-screen-in-scrolling-layout",
  "title": "A lone window fills the whole screen in the scrolling layout",
  "summary": "Turn off fullscreen_on_one_column so a single window keeps its column width.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2"},
  "applies_to": "Every machine.",
  "requires": [],
  "touches": ["~/.config/hypr/looknfeel.lua"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": [],
  "agent_config": false,
  "upstream": "default",
  "history": [{"who": "duff", "did": "created", "date": "2026-10-02"}]
}
```
