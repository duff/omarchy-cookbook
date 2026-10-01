# Battery percentage not shown in the bar

**Tested on:** Omarchy 4.0.4, Hyprland 0.56.2 (Lua config)
**Applies to:** laptops

## Problem

The bar shows a battery icon but no number. You have to open the power panel
to see how much charge is left.

## Why it happens

The battery icon is the `omarchy.power` bar widget. It has a
`showPercentage` setting that defaults to `false`
(`/usr/share/omarchy/shell/plugins/panels/power/Panel.qml`), and the stock
`shell.json` does not set it.

## Fix

Right-click the battery icon. That toggles the percentage and saves the
choice to `~/.config/omarchy/shell.json`.

Or set it from a terminal:

```bash
omarchy bar set omarchy.power showPercentage true --json
```

`--json` stores a real boolean instead of the string `"true"`, which the
widget would ignore.

Either way, the entry in `~/.config/omarchy/shell.json` ends up as:

```json
{
  "id": "omarchy.power",
  "showPercentage": true
}
```

## Apply and check

The shell reloads `shell.json` on save. The number appears next to the icon
right away.

## Notes

- The percentage only shows on a top or bottom bar. A vertical bar keeps the
  icon alone.
- To undo, right-click the icon again, or remove the `showPercentage` line.
