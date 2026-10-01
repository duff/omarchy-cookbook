# Make Caps Lock Escape on tap and hjkl arrows on hold

**Tested on:** Omarchy 4.0.4, Hyprland 0.56.2 (Lua config), keyd 2.6.0
**Applies to:** every machine

## Problem

Omarchy turns Caps Lock into the Compose key. If you live in Vim, you would
rather have Escape under that finger, and arrow keys you can reach without
leaving the home row. Hyprland binds like `SUPER + H/J/K/L` are already taken
by window management, so the arrows need a different modifier.

## Why it happens

`/usr/share/omarchy/default/hypr/input.lua` sets
`kb_options = "compose:caps,shift:both_capslock_cancel"`. XKB options can make
Caps a plain Escape (`caps:escape`), but they cannot give one key a different
job on tap and on hold. That needs a remapper below the compositor.
[keyd](https://github.com/rvaiya/keyd) runs as a system daemon, grabs the
keyboards, and emits a virtual keyboard that Hyprland sees instead.

## Fix

Install keyd:

```bash
omarchy pkg add keyd
```

Write `/etc/keyd/default.conf`:

```ini
# Caps tap = Escape. Caps hold + h/j/k/l = real arrow keys.

[ids]
*

[main]
capslock = overload(nav, esc)

[nav]
h = left
j = down
k = up
l = right
```

`overload(nav, esc)` sends Escape on a tap and turns on the `nav` layer while
held. The layer sends real arrow keycodes, so they work in every app.

Then move Compose off Caps in `~/.config/hypr/input.lua`, since keyd now owns
that key and XKB never sees it:

```lua
-- Compose moves to Right Alt so Caps can be Esc/nav via keyd.
-- Do not set caps:escape here; keyd owns Caps.
hl.config({
  input = {
    kb_options = "compose:ralt,shift:both_capslock_cancel",
  },
})
```

Keep `shift:both_capslock_cancel` from the stock options: pressing both Shifts
is now the only way to get Caps Lock.

## Apply and check

```bash
sudo systemctl enable --now keyd
sudo keyd reload
hyprctl reload
hyprctl configerrors
```

Tap Caps in a terminal running `cat -v` or in Vim's insert mode to see Escape.
Hold Caps and press `h`/`l` in a text field to move the cursor.
`sudo keyd monitor` shows what keyd emits.

## Notes

- `compose:ralt` takes away Right Alt as an Alt key. If you use it in chords,
  have keyd send Compose on tap and Alt on hold instead:
  `rightalt = overload(alt, compose)` in `[main]`, and
  `kb_options = "compose:menu,shift:both_capslock_cancel"` in Hyprland, since
  keyd's `compose` key arrives as the Menu key.
- keyd's virtual keyboard is not an internal keyboard as far as libinput is
  concerned, so touchpad disable-while-typing can stop working. See
  `macbook-t2-trackpad-moves-cursor-while-typing.md` for one workaround.
- If you keep the keyd file under `~/.config/keyd/` so it travels with your
  dotfiles, a script in `~/.config/omarchy/hooks/post-update.d/` can copy it to
  `/etc/keyd/` and run `keyd reload` after every `omarchy update`.
- To undo: `sudo systemctl disable --now keyd`, remove `/etc/keyd/default.conf`,
  and drop the `kb_options` line from `~/.config/hypr/input.lua`.
