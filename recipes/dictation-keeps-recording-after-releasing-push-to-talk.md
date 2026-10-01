# Dictation keeps recording after I let go of the push-to-talk key

**Tested on:** Omarchy 4.0.4, Hyprland 0.56.2 (Lua config)
**Applies to:** every machine with Voxtype dictation

## Problem

With Omarchy's push-to-talk, you hold F9, speak, and let go. If any modifier
is down at the moment you let go (Super, Alt, Ctrl, or Shift), recording does
not stop. It keeps going until you press F9 again or Voxtype's 60-second
limit runs out.

This is easy to hit when you reach for the next shortcut while finishing a
sentence, and constant if the push-to-talk key sits among the modifiers, as
in this setup, where Right Shift is remapped to F9.

## Why it happens

`/usr/share/omarchy/default/hypr/bindings/voxtype.lua` binds both ends with no
modifiers:

```lua
o.bind("F9", "Start dictation (push-to-talk)", "voxtype record start")
o.bind("F9", "Stop dictation (push-to-talk)", "voxtype record stop", { release = true })
```

Hyprland matches a bind against the exact set of modifiers held. A release of
F9 with Super down is a release of Super+F9, which matches nothing, so
`voxtype record stop` never runs.

## Fix

Replace both binds with versions that ignore modifiers. In
`~/.config/hypr/bindings.lua`:

```lua
-- Stock push-to-talk only stops when F9 is released with no modifier held,
-- so letting go while Super, Alt, Ctrl, or Shift is down kept dictating.
-- Ignore modifiers on both ends.
hl.unbind("F9")
o.bind("F9", "Start dictation (push-to-talk)", "voxtype record start", { ignore_mods = true })
o.bind("F9", "Stop dictation (push-to-talk)", "voxtype record stop", { release = true, ignore_mods = true })
```

`hl.unbind("F9")` removes both stock binds first, so they do not run twice.
The start bind gets `ignore_mods` too, so pressing F9 while holding a modifier
still starts recording.

Optional: to put push-to-talk on Right Shift, remap it to F9 with keyd. In
`/etc/keyd/default.conf` under `[main]`:

```ini
# Right Shift is dictation immediately. It is not Shift. Left Shift still shifts.
rightshift = f9
```

Then `sudo keyd reload`. See
[right-alt-compose-key-loses-alt-modifier.md](right-alt-compose-key-loses-alt-modifier.md)
for installing keyd.

## Apply and check

```bash
hyprctl reload
hyprctl configerrors
hyprctl binds -j | jq -r '.[] | select(.key == "F9") | .description'
```

The last command should print each description once. Then hold F9, start
speaking, press and hold Super, and let go of F9 first. Run `voxtype status`:
it should say `idle`, not `recording`.

## Notes

- To undo, delete the three lines. Omarchy's stock binds come back on reload.
