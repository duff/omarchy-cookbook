# Monitors swap left and right when the cables change ports

**Tested on:** Omarchy 4.0.4, Hyprland 0.56.2 (Lua config)
**Applies to:** desks with two or more external displays, especially identical ones (tested with two Apple Studio Displays on a Dell XPS 16 over Thunderbolt)

## Problem

You plug two monitors into a laptop or dock and they come up in the wrong
order: the mouse leaves the left screen on its left edge and appears on the
right screen. The next day, after plugging the cables into different ports or
in a different order, the order flips again.

## Why it happens

Stock `~/.config/hypr/monitors.lua` has one catch-all rule:

```lua
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })
```

`position = "auto"` places screens one after another in the order Hyprland
sees them. A rule that names a port such as `DP-1` is no better: port names
belong to the connector, not the screen. With Thunderbolt and USB-C, which
screen becomes `DP-1` and which `DP-3` depends on the port and the plug-in
order.

## Fix

Name each screen by its description, which is make, model and serial number,
with a `desc:` prefix. Every panel has its own serial, so the rule follows the
screen to whichever port it lands on.

Find the descriptions:

```bash
hyprctl monitors all -j | jq -r '.[] | "\(.name)  \(.description)"'
```

```
eDP-1  LG Display 0x07C5
DP-1   Apple Computer Inc StudioDisplay 0xXXXXXXXX
DP-3   Apple Computer Inc StudioDisplay 0xYYYYYYYY
```

Then add rules below the catch-all in `~/.config/hypr/monitors.lua`. Use your
own serials:

```lua
-- Pin each screen by make, model and serial, not by port (DP-1, DP-3, ...), so
-- any cable in any port gives the same left-to-right order. Positions are in
-- scaled pixels: the laptop is 1600 wide and a Studio Display 2560 at scale 2.
local screens = {
  laptop = "eDP-1",
  studio_left = "desc:Apple Computer Inc StudioDisplay 0xXXXXXXXX",
  studio_right = "desc:Apple Computer Inc StudioDisplay 0xYYYYYYYY",
}

hl.monitor({ output = screens.laptop, mode = "preferred", position = "0x0", scale = omarchy_monitor_scale })
hl.monitor({ output = screens.studio_left, mode = "preferred", position = "1600x0", scale = omarchy_monitor_scale })
hl.monitor({ output = screens.studio_right, mode = "preferred", position = "4160x0", scale = omarchy_monitor_scale })
```

The laptop panel can keep its port name (`eDP-1`): it never moves.

Positions are in logical (scaled) pixels. Divide each screen's width by its
scale: a 3200-pixel laptop panel at scale 2 is 1600 wide, so the next screen
starts at `1600x0`. A 5120-pixel Studio Display at scale 2 is 2560 wide, so the
one after it starts at 1600 + 2560 = `4160x0`. To add a screen in the middle,
give it the position of the screen to its right and shift that one right by
the new screen's width.

Keep the catch-all line above these rules. Any other screen, such as a
projector, still comes up at `position = "auto"`.

## Apply and check

```bash
hyprctl reload
hyprctl configerrors
hyprctl monitors -j | jq -r '.[] | "\(.name)  \(.x),\(.y)  \(.description)"'
```

Unplug both displays, swap their ports, and plug them back in. The `x`
positions should follow the serials, not the port names.

## Notes

- The laptop stays at `0x0`, so it sits at the far left whenever the lid is
  open. With the lid shut, Omarchy's clamshell mode turns it off and the
  external screens keep their positions.
- The description string has to match exactly, including the `0x` serial. Copy
  it from `hyprctl monitors all`.
- To undo, delete the `screens` table and the three `hl.monitor` lines.
