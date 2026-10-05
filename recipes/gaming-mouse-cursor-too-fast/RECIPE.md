# Gaming mouse moves the cursor too fast to place it precisely

## Problem

A high-DPI gaming mouse makes the cursor jump: small, slow movements overshoot
the target, so hitting a window border or a small button takes several tries.
Lowering the speed overall fixes that but then a long move across a wide or
multi-monitor desk takes several swipes.

## Why it happens

Omarchy leaves Hyprland's `sensitivity = 0` and libinput's default `adaptive`
acceleration profile in `/usr/share/omarchy/default/hypr/input.lua`. Those
defaults suit an ordinary office mouse. At high DPI the mouse reports many
more units per millimeter, so even slow hand movement comes out fast.

## Fix

Give just this mouse a custom acceleration curve in
`~/.config/hypr/input.lua`: under 1x gain for slow movement, rising above 1x
for fast flicks.

```lua
-- Viper: precise when moved slowly, covers the screen on a quick flick.
-- Points are output speed at input speeds 0, 0.5, 1, ... (units/ms); past the
-- last point the curve keeps its final slope.
-- Hyprland exposes the Viper as two pointers.
local viper_curve = "custom 0.5 0 0.16 0.45 0.88 1.47 2.25 3.25 4.45"
hl.device({ name = "razer-razer-viper-v3-pro", accel_profile = viper_curve })
hl.device({ name = "razer-razer-viper-v3-pro-mouse", accel_profile = viper_curve })
```

The format is `custom <step> <point> <point> ...`. The first number is the
spacing between sample points in input speed, and each following number is
the output speed at 0, 0.5, 1.0, 1.5, and so on. Dividing output by input
gives the gain at each point:

| Input speed | 0.5 | 1.0 | 1.5 | 2.0 | 2.5 | 3.0 | 3.5 |
|---|---|---|---|---|---|---|---|
| Output | 0.16 | 0.45 | 0.88 | 1.47 | 2.25 | 3.25 | 4.45 |
| Gain | 0.32x | 0.45x | 0.59x | 0.74x | 0.90x | 1.08x | 1.27x |

Past 3.5 the curve continues at its last slope (2.4), so fast flicks keep
speeding up. Shift points down for more precision or up the far end for longer
throws.

The mouse shows up as more than one device. Find the names with:

```bash
hyprctl devices | grep -i -A1 'mouse at'
```

and apply the curve to each pointer name that moves the cursor (here, the
plain name and the `-mouse` one).

## Apply and check

```bash
hyprctl reload
hyprctl configerrors
```

Move the mouse slowly across a small target, then flick it across the screen.
Adjust the points until both feel right; Hyprland applies each save
immediately.

## Undo

Delete the `viper_curve` line and the `hl.device` lines.

## Notes

- Tried first: a flat slowdown with `sensitivity = -0.35` on the two device
  names, then `-0.6` on one laptop. Slow moves got better, but long moves
  needed extra swipes. The curve gets both.
- If the cursor nudges a few pixels when you click, that is the mouse's DPI,
  not the curve: at very high DPI, the tiny motion of pressing the button is
  enough to register. Lower the DPI on the mouse itself (with its button or
  vendor software) and then retune the curve; no Hyprland setting fixes it.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.

## Recipe data

```json
{
  "id": "duff/gaming-mouse-cursor-too-fast",
  "title": "Gaming mouse moves the cursor too fast to place it precisely",
  "summary": "Give the mouse its own acceleration curve, precise when slow and far on a flick.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2"},
  "applies_to": "High-DPI mice (tested with a Razer Viper V3 Pro).",
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
