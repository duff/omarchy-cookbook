# Battery percentage not shown in the bar

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

## Undo

Right-click the icon again, or remove the `showPercentage` line.

## Notes

- The percentage only shows on a top or bottom bar. A vertical bar keeps the
  icon alone.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.

## Recipe data

```json
{
  "id": "duff/battery-percentage-not-shown-in-the-bar",
  "title": "Battery percentage not shown in the bar",
  "summary": "Show the battery percentage next to the bar's battery icon.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2"},
  "applies_to": "Laptops.",
  "requires": [{"laptop": true}],
  "touches": ["~/.config/omarchy/shell.json"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": [],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
```
