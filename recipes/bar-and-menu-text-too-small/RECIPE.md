# Bar and menu text too small, but the terminal font is fine

## Problem

On a big monitor seen from a desk, the bar, the Omarchy menu, and the other
shell panels are small and hard to read. The obvious fix,
`omarchy display text size`, also makes the terminal font bigger, which you
may not want.

## Why it happens

`omarchy display text size <px>` (`/usr/share/omarchy/bin/omarchy-display-text-size`)
is one knob for three things, moved together:

- the shell's `[font] base-size` in `~/.config/omarchy/shell.toml`
  (default 12 px),
- GTK's `text-scaling-factor`,
- the terminal font size in `~/.config/ghostty/config`,
  `~/.config/kitty/kitty.conf`, `~/.config/alacritty/alacritty.toml`, and
  `~/.config/foot/foot.ini` (default 9 pt, scaled as px × 9 / 12).

So `omarchy display text size 14` sets the shell to 14 px and the terminals to
11 pt.

## Fix

Set the shell size on its own in `~/.config/omarchy/shell.toml`:

```toml
[font]
base-size = 14
```

Every shell text size derives from `base-size`, and the bar height and panel
spacing scale with it so larger text does not clip. This file only affects
the shell. Terminals and GTK apps keep their sizes.

Set the terminal size separately, in the terminal's own config. For Ghostty,
in `~/.config/ghostty/config`:

```
font-size = 9
```

For Kitty, in `~/.config/kitty/kitty.conf`:

```
font_size 9.0
```

Nine is the stock size. One point is a large step at terminal sizes. This
setup tried 10 and 11 pt for external displays and went back to 9, keeping
the shell at 14 px.

## Apply and check

The shell watches `shell.toml`, so the bar re-flows as soon as you save.
Reload terminals with:

```bash
omarchy restart terminal
```

`omarchy display text size` with no argument prints the current shell size,
GTK factor, and terminal size without changing anything.

## Undo

Delete the `base-size` line from `~/.config/omarchy/shell.toml`. The shell
picks up the change as soon as you save.

## Notes

- If you already ran `omarchy display text size`, it also changed GTK's
  text scaling. `omarchy display text size reset` puts all three back to
  12 px, 1.0, and 9 pt, and then you can set `base-size` by hand.
- The shell setting lives outside the theme, so it survives theme changes.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.

## Recipe data

```json
{
  "id": "duff/bar-and-menu-text-too-small",
  "title": "Bar and menu text too small, but the terminal font is fine",
  "summary": "Enlarge the shell font without changing terminals.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2"},
  "applies_to": "Every machine (most noticeable on large external displays).",
  "requires": [],
  "touches": ["~/.config/omarchy/shell.toml", "~/.config/ghostty/config", "~/.config/kitty/kitty.conf"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": [],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
```
