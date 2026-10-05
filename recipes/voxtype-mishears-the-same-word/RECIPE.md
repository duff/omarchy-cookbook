---
{
  "id": "duff/voxtype-mishears-the-same-word",
  "title": "Voxtype keeps mishearing the same word",
  "summary": "Map each misheard spelling to the right word in [text.replacements].",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2", "voxtype": "1.1.0"},
  "applies_to": "Every machine with Voxtype dictation.",
  "requires": [{"command": "voxtype"}],
  "touches": ["~/.config/voxtype/config.toml"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": [],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
---

# Voxtype keeps mishearing the same word

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

## Undo

Delete the `[text]` and `[text.replacements]` lines you added to
`~/.config/voxtype/config.toml`, along with the replacements under them,
then run `systemctl --user restart voxtype`.

## Notes

- A key that is also a real word ("clod", "clawed") is replaced every time,
  even when you meant the real word. Weigh that before adding one.
- For bigger cleanup (filler words, grammar), Voxtype also has
  `[output.post_process]`, which pipes the text through a command such as a
  local LLM. The stock config has a commented example.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.
