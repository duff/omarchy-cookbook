---
{
  "id": "duff/screensaver-starts-too-soon",
  "title": "Screensaver starts too soon while reading",
  "summary": "Set longer idle timers for the screensaver and the lock.",
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
---

# Screensaver starts too soon while reading

## Problem

Read a long page or watch something in a window without touching the
keyboard, and Omarchy's screensaver takes over after two and a half minutes.
The lock follows two and a half minutes after that.

## Why it happens

The Omarchy shell's idle service
(`/usr/share/omarchy/shell/plugins/services/idle/Service.qml`) starts the
screensaver after `idle.screensaver` seconds and locks after `idle.lock`
seconds. The stock values in `/usr/share/omarchy/config/omarchy/shell.json`
are:

```json
"idle": {
  "screensaver": 150,
  "lock": 300
}
```

## Fix

Set your own values in `~/.config/omarchy/shell.json`. Both count seconds
from the moment you went idle, not from each other. To keep the stock rhythm
(screensaver first, lock 2.5 minutes later) but triple the wait:

```json
"idle": {
  "screensaver": 450,
  "lock": 600
}
```

The screensaver now starts at 7.5 minutes and the lock at 10.

## Apply and check

The shell reloads `shell.json` on save, so nothing needs restarting. Leave the
machine alone for the new time and watch for the screensaver.

## Undo

Delete the `idle` block from `~/.config/omarchy/shell.json`, or set it back
to 150 and 300.

## Notes

- If `lock` is less than `screensaver`, the session locks first and the
  screensaver never starts.
- For a one-off, `omarchy toggle idle` switches to "stay awake" and back,
  without changing these numbers.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.
