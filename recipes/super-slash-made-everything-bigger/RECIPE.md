---
{
  "id": "duff/super-slash-made-everything-bigger",
  "title": "Super+Slash made everything bigger, and it stays that way after reboot",
  "summary": "Put the saved monitor scale back, and optionally turn off Super+/.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2"},
  "applies_to": "Every machine (a \"watch out\" note, not a config change).",
  "requires": [],
  "touches": ["~/.config/hypr/monitors.lua", "~/.config/hypr/bindings.lua"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": [],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
---

# Super+Slash made everything bigger, and it stays that way after reboot

## Problem

You pressed Super+/ by accident, perhaps reaching for Super+Shift+/
(Passwords), and the screen jumped to a bigger scale. It does not go back on
its own, and after the next config reload or reboot other monitors may be
bigger too.

## Why it happens

`/usr/share/omarchy/default/hypr/bindings/tiling.lua` binds:

```lua
o.bind("SUPER + SLASH", "Monitor scaling up", "omarchy-hyprland-monitor-scaling up")
o.bind("SUPER + ALT + SLASH", "Monitor scaling down", "omarchy-hyprland-monitor-scaling down")
```

`omarchy-hyprland-monitor-scaling up` steps the focused monitor to the next
preset (1, 1.25, 1.6, 2, 3, 4, rounded to a scale the mode allows). It also
saves the change. If `~/.config/hypr/monitors.lua` still has Omarchy's
catch-all lines:

```lua
local omarchy_gdk_scale = 2
local omarchy_monitor_scale = "auto"
```

it rewrites both values with `sed`. That catch-all applies to every monitor
that has no line of its own, so one keypress on one screen changes the saved
scale for all of them, and `"auto"` becomes a fixed number. Each change is
logged to `~/.local/state/omarchy/monitor-scaling.log`.

## Fix

### Undo it

Super+Alt+/ steps the focused monitor back down one preset. That fixes the
live screen, but the saved value is now a number rather than `"auto"`.

To get back exactly what you had, look at the log first. Each line shows the
monitor, the `current=` scale before the change, and the `new=` scale:

```bash
tail ~/.local/state/omarchy/monitor-scaling.log
```

Then restore `~/.config/hypr/monitors.lua` from your backup or dotfiles repo,
or put the two stock lines back by hand:

```lua
local omarchy_gdk_scale = 2
local omarchy_monitor_scale = "auto"
```

Hyprland reloads on save.

### Optional: turn the key off

Only if you keep hitting it by accident. In `~/.config/hypr/bindings.lua`:

```lua
-- Super+/ scaled the monitor up and saved it to monitors.lua.
hl.unbind("SUPER + SLASH")
```

Super+Alt+/ still scales down, and `omarchy hyprland monitor scaling up`
still works from a terminal. Leaving the binding in place is fine if you
use it.

## Apply and check

```bash
hyprctl reload
hyprctl configerrors
hyprctl monitors | grep -E 'Monitor|scale'
```

The scales should match what you had before. `omarchy hyprland monitor
scaling` with no argument prints the focused monitor's scale.

## Undo

Restoring `monitors.lua` only puts back what you had, so there is nothing to
undo there. If you turned the key off, delete the `hl.unbind("SUPER + SLASH")`
line from `~/.config/hypr/bindings.lua` to get Super+/ back.

## Notes

- The saving step only touches the catch-all lines. If you have pinned each
  monitor with its own `hl.monitor({ output = ..., scale = ... })` line and
  removed the catch-all, the keypress changes the live scale but does not
  save it, and a `hyprctl reload` puts it back.
- Keep a copy of `monitors.lua` once your scales are right, so undoing this
  is a file copy.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.
