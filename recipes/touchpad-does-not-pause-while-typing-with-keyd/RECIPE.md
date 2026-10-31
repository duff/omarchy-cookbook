# Touchpad doesn't pause while typing when keyd remaps the keyboard

## Problem

On a laptop whose keyboard is remapped with keyd, a palm or thumb resting on
the touchpad moves the cursor and clicks while you type, sometimes sending the
next few words somewhere else. Disable-while-typing, which normally ignores
the touchpad for a moment after each keystroke, stops working once keyd is
running, even though it's on.

## Why it happens

Hyprland's `input.touchpad.disable_while_typing` is on by default; Omarchy's
`/usr/share/omarchy/config/hypr/input.lua` only shows it, commented out, as
something you could turn off. Hyprland hands the job to libinput, and libinput
pauses a touchpad only for keys from a keyboard it considers built into the
same laptop. It decides that from the device: the laptop's own keyboard is
internal, a USB or Bluetooth keyboard is external, so typing on an external
keyboard doesn't freeze the laptop's touchpad.

keyd grabs the built-in keyboard and types everything again through its own
virtual device, `keyd virtual keyboard`, which sits on a virtual USB bus.
Hyprland only ever sees keys from that device, and libinput counts it as
external, so no keystroke ever pauses the touchpad.

## Fix

Tell libinput that keyd's keyboard is internal, with a quirk in
`/etc/libinput/local-overrides.quirks`, the one file libinput reads for local
overrides:

```ini
# keyd grabs the built-in keyboard and retypes through a virtual keyboard on
# the USB bus, so libinput counts it as external and never pairs it with the
# touchpad for disable-while-typing. Mark it internal.
[keyd virtual keyboard]
MatchUdevType=keyboard
MatchName=keyd virtual keyboard
AttrKeyboardIntegration=internal
```

- `MatchName` is the device name keyd gives its keyboard. Check yours with
  `grep -H . /sys/class/input/event*/device/name | grep keyd`.
- `AttrKeyboardIntegration=internal` is the attribute libinput's own quirks use
  for laptop keyboards that it would otherwise misjudge.
- If the file already exists, add the section to it instead of replacing it.

Nothing else changes: Hyprland's setting stays as it was, and external
keyboards plugged in later still don't pause the touchpad.

To keep the file with your other config, store it as
`~/.config/libinput/local-overrides.quirks` and copy it into place from your
install script, as a `/etc` file can't live in `~/.config`.

## Apply and check

```bash
sudo install -D -m 0644 local-overrides.quirks /etc/libinput/local-overrides.quirks
```

libinput reads quirks only when Hyprland starts, so log out and back in.

Then check that the quirk applies to keyd's keyboard:

```bash
dev=$(grep -l '^keyd virtual keyboard$' /sys/class/input/event*/device/name | cut -d/ -f5)
libinput quirks list "/dev/input/$dev"
```

It should print `AttrKeyboardIntegration=internal`. Type a few words with a
palm resting on the touchpad: the cursor should stay put, and the touchpad
should work again a moment after you stop typing.

## Undo

Delete the `[keyd virtual keyboard]` section from
`/etc/libinput/local-overrides.quirks`, or the whole file if that was all it
held (`sudo rm /etc/libinput/local-overrides.quirks`), then log out and back
in.

## Notes

- A T2 MacBook has a second problem: its trackpad itself looks external to
  libinput. See
  [MacBook T2 trackpad moves the cursor while typing](../macbook-t2-trackpad-moves-cursor-while-typing/RECIPE.md),
  which works around both with a small daemon. This quirk hasn't been tried
  there.
- To set keyd up, see
  [Make Caps Lock Escape on tap and hjkl arrows on hold](../caps-lock-as-escape-and-hjkl-arrows/RECIPE.md).

## History

- Created by [@duff](https://github.com/duff) on 2026-10-31.

## Recipe data

```json
{
  "id": "duff/touchpad-does-not-pause-while-typing-with-keyd",
  "title": "Touchpad doesn't pause while typing when keyd remaps the keyboard",
  "summary": "Mark keyd's virtual keyboard as built in with a libinput quirk, so typing pauses the touchpad again.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.5", "hyprland": "0.56.2", "libinput": "1.32.0", "keyd": "2.6.0"},
  "applies_to": "Laptops that remap their keyboard with keyd.",
  "requires": [{"laptop": true}, {"package": "keyd"}],
  "touches": ["/etc/libinput/local-overrides.quirks"],
  "root": true,
  "network": false,
  "installs": [],
  "runs": [],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-31"}]
}
```
