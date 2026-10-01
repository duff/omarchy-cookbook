# Swap Alt and Super on the laptop keyboard but not on an external keyboard

**Tested on:** Omarchy 4.0.4, Hyprland 0.56.2 (Lua config), keyd 2.6.0
**Applies to:** laptops used with a separate external keyboard (tested on a Dell XPS 16 with an ErgoDox)

## Problem

On a PC laptop the key next to the space bar is Alt and the Windows key sits
one further out. Omarchy puts nearly everything on Super, so your thumb wants
Super where Alt is (the Mac layout). Swapping the keys in XKB would also swap
them on an external keyboard whose layout you already set the way you like,
such as a programmable ErgoDox configured in Oryx.

## Why it happens

Hyprland's global `kb_options` (for example `altwin:swap_lalt_lwin`) apply to
every keyboard at once. Hyprland can also set `kb_options` per device with
`hl.device`, but once [keyd](https://github.com/rvaiya/keyd) is running, every
keyboard reaches Hyprland through keyd's single virtual keyboard, so Hyprland
can no longer tell them apart. The swap has to happen in keyd, which still sees
each physical keyboard.

## Fix

keyd picks a config file per keyboard using the `[ids]` section. Put the shared
bindings in one file, then give the laptop keyboard its own config that adds
the swap and pulls in the shared part.

Find the laptop keyboard's id with `sudo keyd monitor` and press a key on it.
Built-in laptop keyboards on the i8042 controller usually show as `0001:0001`.

`/etc/keyd/common` (no `.conf` extension, so keyd only loads it through
`include`). Put whatever every keyboard should share here; this example is the
Caps Lock layer from `caps-lock-as-escape-and-hjkl-arrows.md`:

```ini
[main]

capslock = overload(nav, esc)

[nav]

h = left
j = down
k = up
l = right
```

`/etc/keyd/default.conf`, for every keyboard except the laptop's:

```ini
[ids]
*
-0001:0001

include common
```

`/etc/keyd/laptop.conf`, for the laptop keyboard only:

```ini
[ids]
0001:0001

[main]
# Physical Windows key becomes Alt. Physical Left Alt becomes Super.
# Bind the modifier layers so each key stays held for chords.
leftmeta = layer(alt)
leftalt = layer(meta)

include common
```

`layer(alt)` and `layer(meta)` turn on keyd's built-in modifier layers while
the key is held, so Super+K and similar chords work.

## Apply and check

```bash
sudo keyd reload
sudo keyd monitor
```

In `keyd monitor`, press the physical Left Alt on the laptop and check that it
reports `leftmeta`. Then try a Super chord (Super+Return opens a terminal on
stock Omarchy) using the physical Alt key. The external keyboard should be
unchanged.

## Notes

- The first attempt used keyd's `[aliases]` section
  (`leftmeta = leftalt`, `leftalt = leftmeta`). The keys swapped for a lone
  press, but chords broke: Super+K typed a plain `k`. Binding each key to a
  modifier layer in `[main]` fixed it.
- Only the left pair changes, so Right Alt keeps whatever job it has.
- To undo, delete `/etc/keyd/laptop.conf`, remove the `-0001:0001` line from
  `default.conf`, and run `sudo keyd reload`.
