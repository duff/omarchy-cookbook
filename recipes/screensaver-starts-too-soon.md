# Screensaver starts too soon while reading

**Tested on:** Omarchy 4.0.4, Hyprland 0.56.2 (Lua config)
**Applies to:** every machine

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

## Notes

- If `lock` is less than `screensaver`, the session locks first and the
  screensaver never starts.
- For a one-off, `omarchy toggle idle` switches to "stay awake" and back,
  without changing these numbers.
- To undo, delete the `idle` block, or set it back to 150 and 300.
