# Voxtype keeps mishearing the same word

**Tested on:** Omarchy 4.0.4, Hyprland 0.56.2 (Lua config), Voxtype 1.1.0 (Parakeet engine)
**Applies to:** every machine with Voxtype dictation

## Problem

Dictation gets ordinary speech right but mangles names it was never trained
on, the same wrong way every time. In this setup "Omarchy" came out as
"Omachi", "Almachi", "homache", or "Omagi", and "Claude" as "clawed", "clod",
"claud", or "clawd". Fixing them by hand after every dictation gets old.

## Why it happens

The speech model only knows the words it saw in training, so a product name
or an unusual personal name comes out as the nearest-sounding words it does
know. Omarchy's stock `~/.config/voxtype/config.toml`
(copied from `/usr/share/omarchy/default/voxtype/config.toml`) leaves
Voxtype's `[text]` section commented out, so nothing corrects the output.

## Fix

Add a replacement table to `~/.config/voxtype/config.toml`. Each key is what
Voxtype hears, each value is what you meant:

```toml
[text]

[text.replacements]
Omachi = "Omarchy"
Almachi = "Omarchy"
homache = "Omarchy"
Omagi = "Omarchy"
clawed = "Claude"
clod = "Claude"
claud = "Claude"
clawd = "Claude"
```

Matching is case-insensitive. A key with a space in it needs quotes, for
example `"vox type" = "voxtype"`. The same thing works for people's names
that the model keeps spelling as ordinary words.

To find the spellings to add, read what Voxtype actually heard. The daemon
logs each transcription before replacements are applied:

```bash
journalctl --user -u voxtype -o cat | grep 'Transcribed:' | tail
```

## Apply and check

```bash
systemctl --user restart voxtype
```

Dictate the word again. If a new misspelling shows up, add it as another
line. Expect to collect several over a few days.

## Notes

- A key that is also a real word ("clod", "clawed") is replaced every time,
  even when you meant the real word. Weigh that before adding one.
- For bigger cleanup (filler words, grammar), Voxtype also has
  `[output.post_process]`, which pipes the text through a command such as a
  local LLM. The stock config has a commented example.
