---
{
  "id": "duff/voxtype-dictation-types-slowly",
  "title": "Dictated text types out slowly, one character at a time",
  "summary": "Set Voxtype's typing delay to zero.",
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

# Dictated text types out slowly, one character at a time

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

## Undo

Set `type_delay_ms` back to `1`, Omarchy's value, in
`~/.config/voxtype/config.toml`, and run `systemctl --user restart voxtype`.

## Notes

- If characters go missing in some app after this change, go back to `1`, or
  higher. Voxtype's own docs suggest `10` for apps that drop characters.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.
