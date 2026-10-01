# Workspaces open on unpredictable monitors

**Tested on:** Omarchy 4.0.4, Hyprland 0.56.2 (Lua config)
**Applies to:** multi-monitor setups

## Problem

With two or three screens, `Super + 5` opens workspace 5 on whichever screen
has focus at the time. A workspace you think of as "the right screen" ends up
on the left one, and after a few days the numbers are scattered across screens
with no pattern.

## Why it happens

Omarchy binds `Super + 1` to `Super + 0` to "focus workspace N"
(`/usr/share/omarchy/default/hypr/bindings/tiling.lua`) and ships no
workspace rules. Hyprland creates a missing workspace on the focused monitor,
and it stays there until you move it.

## Fix

Give each screen a block of workspace numbers with `hl.workspace_rule`:
workspaces 1-3 on the left, 4-6 in the middle, 7-9 on the right. `default =
true` makes the first of each block the one a screen shows when it comes up.

Add this to `~/.config/hypr/monitors.lua`, after the monitor rules. The
`screens` table is the one from
[monitors-swap-sides-when-cables-change-ports.md](monitors-swap-sides-when-cables-change-ports.md).
Rules that name screens by `desc:` keep the blocks with the right screen even
when cables change ports. Port names (`"DP-1"`) also work if your ports never
change.

```lua
local screens = {
  left = "desc:Apple Computer Inc StudioDisplay 0xXXXXXXXX",
  middle = "desc:Apple Computer Inc StudioDisplay 0xYYYYYYYY",
  right = "desc:Apple Computer Inc StudioDisplay 0xZZZZZZZZ",
}

-- Workspaces follow the desk left to right: 1-3 left, 4-6 middle (the main
-- screen), 7-9 right. Each screen starts on the first of its block.
local blocks = {
  { screen = screens.left, workspaces = { 1, 2, 3 } },
  { screen = screens.middle, workspaces = { 4, 5, 6 } },
  { screen = screens.right, workspaces = { 7, 8, 9 } },
}

for _, block in ipairs(blocks) do
  for i, ws in ipairs(block.workspaces) do
    hl.workspace_rule({ workspace = tostring(ws), monitor = block.screen, default = i == 1 })
  end
end
```

With two external screens and an open laptop lid, use the laptop panel
(`"eDP-1"`) as one of the three screens.

## Apply and check

```bash
hyprctl reload
hyprctl configerrors
hyprctl workspacerules
```

Press `Super + 8` with the left screen focused: workspace 8 should open on the
right screen, and focus should follow it there.

## Notes

- Rules decide where a workspace is created. A reload does not move
  workspaces that already exist. Move them once with `Super + Shift + Alt +
  arrow` (Omarchy's "move workspace to monitor"), or log out and back in.
  Empty workspaces vanish as soon as you leave them, so only workspaces with
  windows need moving.
- When a screen is unplugged and plugged back in, Hyprland returns its
  workspaces to the monitor they last lived on, by port name (`DP-1`), not by
  `desc:`. If the cables come back in different ports, a block can land on
  the wrong screen until you move it, or until you log in again.
- To undo, delete the `blocks` table and the loop.
