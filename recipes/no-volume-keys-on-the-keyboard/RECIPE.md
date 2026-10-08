# No volume keys on the keyboard

## Problem

Omarchy's volume shortcuts are the media keys: the volume up and down keys on
a laptop or a full-size keyboard. Many external keyboards have none, such as
split, compact, and programmable ones. With one of those, the only way to
change the volume is the mouse.

## Why it happens

`/usr/share/omarchy/default/hypr/bindings/media.lua` binds volume only to the
media keysyms:

```lua
o.bind("XF86AudioRaiseVolume", "Volume up", "omarchy-audio-output-volume raise", { locked = true, repeating = true })
o.bind("XF86AudioLowerVolume", "Volume down", "omarchy-audio-output-volume lower", { locked = true, repeating = true })
```

A keyboard that never sends those keysyms never reaches them.

## Fix

Add the same commands on Super+] and Super+[ in `~/.config/hypr/bindings.lua`:

```lua
-- Volume for keyboards without media keys. Same commands and lock-screen
-- behavior as stock's volume keys.
o.bind("SUPER + code:35", "Volume up", "omarchy-audio-output-volume raise", { locked = true, repeating = true })
o.bind("SUPER + code:34", "Volume down", "omarchy-audio-output-volume lower", { locked = true, repeating = true })
```

- `code:35` and `code:34` are the `]` and `[` keys by position, so the
  shortcut stays in the same place on layouts that put other characters there.
  Stock uses the same codes for Super+Alt+[ and ], which resize the webcam
  overlay, so Super alone is free.
- `locked = true` keeps them working on the lock screen, and `repeating = true`
  keeps changing the volume while the key is held, like the media keys.
- `omarchy-audio-output-volume` is the command the stock keys run, so the
  on-screen volume display shows up the same way.

The media keys keep working on keyboards that have them.

## Apply and check

```bash
hyprctl reload
hyprctl configerrors
```

Press Super+] and Super+[: the volume display should appear and the level
should change. Hold one down and it should keep going.
`omarchy menu keybindings --print | grep -i volume` lists the new shortcuts.

## Undo

Delete the two bindings from `~/.config/hypr/bindings.lua`, then run
`hyprctl reload`.

## Notes

- Stock's Alt+volume keys change the volume one step at a time. To do the
  same here, bind `SUPER + ALT + SHIFT + code:35` and `code:34` to
  `omarchy-audio-output-volume +1` and `-1`; Super+Alt+[ and ] are already
  taken by the webcam overlay.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-08.

## Recipe data

```json
{
  "id": "duff/no-volume-keys-on-the-keyboard",
  "title": "No volume keys on the keyboard",
  "summary": "Turn the volume up and down with Super+] and Super+[.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2"},
  "applies_to": "Keyboards without volume keys.",
  "requires": [],
  "touches": ["~/.config/hypr/bindings.lua"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": [],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-08"}]
}
```
