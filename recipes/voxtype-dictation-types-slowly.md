# Dictated text types out slowly, one character at a time

**Tested on:** Omarchy 4.0.4, Hyprland 0.56.2 (Lua config), Voxtype 1.1.0
**Applies to:** every machine with Voxtype dictation

## Problem

After a dictation finishes transcribing, the text is typed into the field
with a pause between characters. On a long dictation you can watch it crawl
in.

## Why it happens

Omarchy's Voxtype config, copied from
`/usr/share/omarchy/default/voxtype/config.toml`, sets a delay between typed
characters:

```toml
[output]
# Delay between typed characters in milliseconds
# 0 = fastest possible, increase if characters are dropped
type_delay_ms = 1
```

## Fix

In `~/.config/voxtype/config.toml`:

```toml
[output]
type_delay_ms = 0
```

## Apply and check

```bash
systemctl --user restart voxtype
```

Dictate a long sentence. It should appear at once.

## Notes

- If characters go missing in some app after this change, go back to `1`, or
  higher. Voxtype's own docs suggest `10` for apps that drop characters.
