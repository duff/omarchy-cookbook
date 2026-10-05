# High-DPI gaming mouse moves the cursor too fast to place it precisely

## Problem

This is for a high-DPI gaming mouse. An ordinary office mouse is fine with
the stock settings.

A high-DPI mouse makes the cursor jump: small, slow movements overshoot the
target, so hitting a window border or a small button takes several tries.
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
-- The Viper's receiver registers several devices, some with the same name, and
-- Hyprland adds "-1", "-2" to repeats in whatever order they come up. After a
-- reconnect the real pointer can be "razer-razer-viper-v3-pro-1", so cover
-- every variant; keyboard devices ignore the curve.
local viper_curve = "custom 0.5 0 0.16 0.45 0.88 1.47 2.25 3.25 4.45"
for _, base in ipairs({ "razer-razer-viper-v3-pro", "razer-razer-viper-v3-pro-mouse", "razer-razer-viper-v3-pro-keyboard" }) do
  for _, suffix in ipairs({ "", "-1", "-2", "-3" }) do
    hl.device({ name = base .. suffix, accel_profile = viper_curve })
  end
end
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
throws. To make the whole thing calmer without changing its shape, multiply
every point by the same number: at 80%, the curve is
`custom 0.5 0 0.128 0.36 0.704 1.176 1.8 2.6 3.56`.

The mouse shows up as more than one device. Find the names with:

```bash
hyprctl devices | grep -i -A1 'mouse at'
```

and apply the curve to every name the mouse's receiver registers. Hyprland
gives repeated names a `-1`, `-2` suffix in whatever order the devices come
up, so after a reconnect the pointer that moves the cursor can have a
different name. A rule for each name with each suffix covers that. Devices
that aren't pointers ignore the curve.

## Apply and check

```bash
hyprctl reload
hyprctl configerrors
```

Move the mouse slowly across a small target, then flick it across the screen.
Adjust the points until both feel right; Hyprland applies each save
immediately. To check the reconnect case, switch the mouse off and on (or
replug its receiver) and try again.

## Undo

Delete the `viper_curve` line and the loop with the `hl.device` rules.

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
  "title": "High-DPI gaming mouse moves the cursor too fast to place it precisely",
  "summary": "Give the mouse its own acceleration curve, precise when slow and far on a flick.",
  "version": 2,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2"},
  "applies_to": "High-DPI gaming mice (tested with a Razer Viper V3 Pro).",
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
