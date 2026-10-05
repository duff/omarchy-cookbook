# Bar clock shows 24-hour time

## Problem

The clock in the middle of the bar reads like "Monday 15:45". If you think in
12-hour time, you want "Monday 3:45 PM".

## Why it happens

The clock is the `omarchy.clock` bar widget. Its format comes from
`~/.config/omarchy/shell.json`, and the stock default
(`/usr/share/omarchy/config/omarchy/shell.json`) is `"format": "dddd HH:mm"`.
The widget uses Qt date format strings, where `HH` is the 24-hour hour.

## Fix

Set the clock's `format` to a 12-hour pattern. `h` is the hour without a
leading zero and `AP` is AM/PM.

```bash
omarchy bar set omarchy.clock format "dddd h:mm AP"
```

That writes the entry in `~/.config/omarchy/shell.json`, which you can also
edit by hand:

```json
{
  "id": "omarchy.clock",
  "format": "dddd h:mm AP",
  "formatAlt": "d MMMM 'W'ww yyyy",
  "verticalFormat": "HH\n—\nmm"
}
```

Only `format` changes. `formatAlt` is an extra format the widget adds to its
right-click cycle, and `verticalFormat` is only used when the bar sits on the
left or right edge.

## Apply and check

The shell reloads `shell.json` on save, so the bar changes right away. Nothing
to restart.

## Undo

Set `format` back to `dddd HH:mm`:

```bash
omarchy bar set omarchy.clock format "dddd HH:mm"
```

## Notes

- Right-clicking the clock cycles through built-in formats, and
  `dddd h:mm AP` is one of them. The format you land on is saved to
  `shell.json`, so the click alone is enough if you only want this preset.
- Other 12-hour presets in the cycle: `h:mm AP` and `ddd d MMM h:mm AP`.
- For a vertical bar, the 12-hour preset is `h\n—\nmm\nAP` (set it as
  `verticalFormat`).

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.

## Recipe data

```json
{
  "id": "duff/bar-clock-shows-24-hour-time",
  "title": "Bar clock shows 24-hour time",
  "summary": "Switch the bar clock to a 12-hour format.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2"},
  "applies_to": "Every machine.",
  "requires": [],
  "touches": ["~/.config/omarchy/shell.json"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": [],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
```
