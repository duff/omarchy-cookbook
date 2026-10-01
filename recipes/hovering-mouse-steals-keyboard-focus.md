# Moving the mouse or brushing the touchpad steals keyboard focus

**Tested on:** Omarchy 4.0.4, Hyprland 0.56.2 (Lua config)
**Applies to:** every machine (most noticeable on laptops)

## Problem

You are typing in one window, the cursor drifts over another one (a palm
brushes the touchpad, or you nudge the mouse), and your next keystrokes land in
the wrong window.

## Why it happens

Omarchy sets `follow_mouse = 1` in `/usr/share/omarchy/default/hypr/input.lua`.
In Hyprland that means keyboard focus follows the cursor: whatever window is
under the pointer gets your typing.

## Fix

Use `follow_mouse = 2` in `~/.config/hypr/input.lua`:

```lua
hl.config({
  input = {
    follow_mouse = 2, -- click for keyboard focus; hover still scrolls
  },
})
```

With `2`, cursor focus and keyboard focus are separate. Hovering a window still
sends it scroll events, so you can scroll a background window without clicking
it, but keyboard focus only moves when you click (or use a focus keybinding).

## Apply and check

```bash
hyprctl reload
hyprctl configerrors
hyprctl getoption input:follow_mouse
```

It should print `int: 2`. Type in one window, move the cursor over another, and
keep typing: the text stays where it was.

## Notes

- Pairs well with turning off tap-to-click
  (`touchpad-palm-tap-clicks-things.md`), so a stray touch neither clicks nor
  moves keyboard focus.
- To undo, remove the line; Omarchy's `1` comes back.
