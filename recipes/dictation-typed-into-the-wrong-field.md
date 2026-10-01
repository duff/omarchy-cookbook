# Dictation went into the wrong field and I have to say it again

**Tested on:** Omarchy 4.0.4, Hyprland 0.56.2 (Lua config), Voxtype 1.1.0
**Applies to:** every machine with Voxtype dictation

## Problem

Voxtype types the transcription into whatever has focus when it finishes. If
focus was in the wrong window or field, the text lands there, and the only
fix is to dictate the whole thing again.

This recipe adds Super+D: click the field you meant, press Super+D, and the
last dictation is typed again there.

## Why it happens

Voxtype keeps no history of what it typed, and Omarchy adds no way to repeat
it. But the Voxtype daemon logs every transcription to the user journal, as a
line like `Transcribed: "..."`, so the text is still there to read back.

## Fix

### The retype script

`~/.config/omarchy/dictation/retype` (make it executable):

```python
#!/usr/bin/env python3
# Super+D: type the last dictation into the focused field, for when Voxtype
# typed it into the wrong one. Click the right field, then press the key.
#
# Voxtype keeps no history, but it logs each transcription to the journal.
# That log line is the raw text, before [text.replacements], so the same
# replacements are applied here ("Omachi" still becomes "Omarchy").

import os
import re
import subprocess
import tomllib

CONFIG = os.path.expanduser("~/.config/voxtype/config.toml")


def notify(message):
    subprocess.run(["notify-send", "-t", "3000", "Dictation", message])


def last_transcription():
    log = subprocess.run(
        ["journalctl", "--user", "-u", "voxtype", "-n", "500", "--no-pager", "-o", "cat"],
        capture_output=True,
        text=True,
    ).stdout
    found = re.findall(r'Transcribed: "(.*)"$', log, re.MULTILINE)
    if not found:
        return None
    # The log quotes the text Rust-style: undo \" \\ \n \t.
    escapes = {'"': '"', "\\": "\\", "n": "\n", "t": "\t", "'": "'"}
    return re.sub(r"\\(.)", lambda m: escapes.get(m.group(1), m.group(0)), found[-1])


def apply_replacements(text):
    try:
        with open(CONFIG, "rb") as f:
            replacements = tomllib.load(f).get("text", {}).get("replacements", {})
    except (OSError, tomllib.TOMLDecodeError):
        return text
    # Longest first, so a multi-word key wins over a shorter key inside it.
    for spoken in sorted(replacements, key=len, reverse=True):
        pattern = r"\b" + re.escape(spoken) + r"\b"
        text = re.sub(pattern, lambda _, r=replacements[spoken]: r, text, flags=re.IGNORECASE)
    return text


text = last_transcription()
if not text:
    notify("No dictation to retype yet")
else:
    # bindings.lua starts this only once Super and D are both released.
    subprocess.run(["wtype", "--", apply_replacements(text)])
```

It needs `wtype`, which Omarchy's Voxtype install already adds. The
replacement step mirrors Voxtype's `[text.replacements]` (see
[voxtype-mishears-the-same-word.md](voxtype-mishears-the-same-word.md)).

### The binding

The script types letters. If Super is still held when they arrive, each
letter becomes a Super shortcut. So the binding only marks a retype as
pending, and a key listener runs the script once Super and D are both up.
In `~/.config/hypr/bindings.lua`:

```lua
-- Dictation went into the wrong field: click the right one, then press this.
-- The retype waits until Super and D are both up, so its typed letters can
-- never land as Super shortcuts.
local retype_pending = false
local held = {}
local SUPER_L, SUPER_R, D = 133, 134, 40 -- xkb keycodes

o.bind("SUPER + D", "Retype last dictation", function()
  retype_pending = true
end)

hl.on("input.keyboard.key", function(keycode, _, state)
  held[keycode] = state == 1 or nil
  if retype_pending and not (held[SUPER_L] or held[SUPER_R] or held[D]) then
    retype_pending = false
    hl.exec_cmd(os.getenv("HOME") .. "/.config/omarchy/dictation/retype")
  end
end)
```

`hl.on("input.keyboard.key", ...)` gets every key press (`state == 1`) and
release, so `held` tracks which of the three keys are down. Keycodes are XKB
codes as Hyprland sees them, after any keyd remapping. Super+D is free in
stock Omarchy; check `hyprctl binds` if you have added your own.

## Apply and check

```bash
chmod +x ~/.config/omarchy/dictation/retype
hyprctl reload
hyprctl configerrors
```

Dictate into one field, click another, and press Super+D. The same text
(with your replacements applied) should be typed there. If there is no
transcription in the last 500 lines of the Voxtype journal, you get a "No
dictation to retype yet" notification instead.

## Notes

- The first version bound Super+D with `{ release = true }` and slept 0.25
  seconds before typing. A release bind fires when D comes up, but Super is
  often still held, and a fixed sleep is either too short or a needless wait.
  Watching the keys directly removed the guesswork.
- Only the most recent dictation is retyped.
- To undo, delete the Lua block and the script.
