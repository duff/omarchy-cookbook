# Bar and menu text too small, but the terminal font is fine

**Tested on:** Omarchy 4.0.4, Hyprland 0.56.2 (Lua config)
**Applies to:** every machine (most noticeable on large external displays)

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

## Notes

- If you already ran `omarchy display text size`, it also changed GTK's
  text scaling. `omarchy display text size reset` puts all three back to
  12 px, 1.0, and 9 pt, and then you can set `base-size` by hand.
- The shell setting lives outside the theme, so it survives theme changes.
- To undo, delete the `base-size` line.
