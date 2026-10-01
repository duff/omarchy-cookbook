# MacBook T2 trackpad moves the cursor while typing

**Tested on:** Omarchy 4.0.4, Hyprland 0.56.2 (Lua config), keyd 2.6.0
**Applies to:** Intel MacBooks with a T2 chip (tested on a MacBook Air, USB id `05ac:027a`)

## Problem

On a T2 MacBook, the palm or thumb resting on the big trackpad moves the cursor
and clicks while you type. Disable-while-typing, which normally ignores the pad
for a moment after each keystroke, does nothing.

## Why it happens

Two separate things break it.

1. The T2 exposes the built-in keyboard and trackpad as a USB device that udev
   marks as removable. libinput only applies disable-while-typing to an
   internal touchpad paired with an internal keyboard, so it treats this pad as
   an external one and skips it. See t2linux/wiki#752.
2. If you remap keys with keyd (for example
   `caps-lock-as-escape-and-hjkl-arrows.md`), every keystroke reaches
   Hyprland from keyd's virtual keyboard, not the built-in one. libinput never
   pairs that virtual keyboard with the trackpad, so disable-while-typing still
   never fires, even after part 1 is fixed.

Hyprland's `input.touchpad.disable_while_typing` is already `true` by
default; the setting is fine, libinput just never acts on it.

## Fix

### 1. Tag the trackpad as internal

Create `/etc/udev/hwdb.d/71-touchpad-local.hwdb`:

```
# T2 MacBook Air (05ac:027a) presents the built-in pad as USB-removable,
# so libinput treats it as external and skips disable-while-typing.
# See t2linux/wiki#752.
touchpad:usb:v05acp027a:*
 ID_INPUT_TOUCHPAD_INTEGRATION=internal
```

The second line must start with a single space. Other T2 models use a
different product id; `lsusb | grep -i apple` shows yours.

Without keyd, this alone should be enough.

### 2. With keyd: a small disable-while-typing daemon

This Python script watches keyd's virtual keyboard and writes the kernel's
`inhibited` flag on the trackpad for 1.5 s after each typing key. Super, Ctrl,
Alt, Esc, Tab, Enter, and the arrows re-enable the pad right away, so
keyboard-plus-pointer window management still works. It needs
`python-evdev` (`omarchy pkg add python-evdev`).

Save it as `/usr/local/bin/trackpad-dwt` and make it executable:

```python
#!/usr/bin/python3
"""Inhibit the Apple trackpad for a short window after a typing key.

Hyprland's disable-while-typing never sees keys through keyd. This watches
the keyd virtual keyboard (or the Apple keyboard) and writes the kernel
inhibited flag on the trackpad. Super, Ctrl, Alt, Esc, Tab, Enter, and
arrows re-enable immediately so window management still works.
"""

from __future__ import annotations

import os
import select
import sys
import time
from pathlib import Path

from evdev import InputDevice, ecodes, list_devices

TIMEOUT = float(os.environ.get("TIMEOUT", "1.5"))
KEYBOARD_NAMES = ("keyd virtual keyboard",)
TRACKPAD_NAME_HINT = "trackpad"

INSTANT_ENABLE = {
    ecodes.KEY_ESC,
    ecodes.KEY_TAB,
    ecodes.KEY_ENTER,
    ecodes.KEY_LEFT,
    ecodes.KEY_RIGHT,
    ecodes.KEY_UP,
    ecodes.KEY_DOWN,
    ecodes.KEY_LEFTMETA,
    ecodes.KEY_RIGHTMETA,
    ecodes.KEY_LEFTCTRL,
    ecodes.KEY_RIGHTCTRL,
    ecodes.KEY_LEFTALT,
    ecodes.KEY_RIGHTALT,
}


def log(msg: str) -> None:
    print(msg, file=sys.stderr, flush=True)


def wait_devices() -> tuple[InputDevice, InputDevice, Path]:
    deadline = time.monotonic() + 60
    while True:
        keyboard = None
        trackpad = None
        for path in list_devices():
            dev = InputDevice(path)
            caps = dev.capabilities()
            name = dev.name or ""
            if name in KEYBOARD_NAMES:
                keyboard = dev
            elif TRACKPAD_NAME_HINT in name.lower() and ecodes.EV_ABS in caps:
                trackpad = dev
            else:
                dev.close()
        if keyboard is None:
            # Fall back to the Apple keyboard interface (no ABS).
            for path in list_devices():
                dev = InputDevice(path)
                name = dev.name or ""
                caps = dev.capabilities()
                if "apple" in name.lower() and "keyboard" in name.lower() and ecodes.EV_ABS not in caps:
                    keyboard = dev
                    break
                dev.close()
        if keyboard is not None and trackpad is not None:
            event = Path(trackpad.path).name
            inhibited = Path(f"/sys/class/input/{event}").resolve().parent / "inhibited"
            if inhibited.is_file():
                log(f"keyboard={keyboard.path} ({keyboard.name})")
                log(f"trackpad={trackpad.path} ({trackpad.name}) inhibit={inhibited}")
                return keyboard, trackpad, inhibited
        for dev in (keyboard, trackpad):
            if dev is not None:
                dev.close()
        if time.monotonic() > deadline:
            raise SystemExit("could not find keyboard and trackpad")
        time.sleep(1)


def set_inhibited(path: Path, value: bool) -> None:
    path.write_text("1\n" if value else "0\n")


def main() -> int:
    keyboard, trackpad, inhibited = wait_devices()
    disabled = False
    enable_at: float | None = None

    def enable() -> None:
        nonlocal disabled, enable_at
        if disabled:
            set_inhibited(inhibited, False)
            disabled = False
        enable_at = None

    def disable() -> None:
        nonlocal disabled, enable_at
        if not disabled:
            set_inhibited(inhibited, True)
            disabled = True
        enable_at = time.monotonic() + TIMEOUT

    try:
        while True:
            timeout = None
            if enable_at is not None:
                timeout = max(0.0, enable_at - time.monotonic())
            ready, _, _ = select.select([keyboard.fd], [], [], timeout)
            now = time.monotonic()
            if enable_at is not None and now >= enable_at:
                enable()
            if not ready:
                continue
            for event in keyboard.read():
                if event.type != ecodes.EV_KEY:
                    continue
                if event.value == 0:
                    continue
                if event.code in INSTANT_ENABLE:
                    enable()
                    continue
                disable()
    finally:
        try:
            set_inhibited(inhibited, False)
        except OSError:
            pass
        keyboard.close()
        trackpad.close()
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        raise SystemExit(0)
```

Run it as a system service, `/etc/systemd/system/trackpad-dwt.service`:

```ini
[Unit]
Description=Inhibit Apple trackpad while typing
After=keyd.service
Wants=keyd.service

[Service]
Type=simple
ExecStart=/usr/local/bin/trackpad-dwt
Restart=always
RestartSec=1
Environment=TIMEOUT=1.5

[Install]
WantedBy=multi-user.target
```

`TIMEOUT` is how long the pad stays off after the last typing key.

## Apply and check

Load the hwdb entry:

```bash
sudo systemd-hwdb update
sudo udevadm trigger --subsystem-match=input --action=change
sudo udevadm trigger --subsystem-match=input --action=add
sudo udevadm settle
```

Log out and back in so Hyprland reopens the trackpad with the new tag. Check
it with `sudo libinput list-devices`: the trackpad should show
`Disable-w-typing: enabled`, and `udevadm info` on its `/dev/input/event*`
node should list `ID_INPUT_TOUCHPAD_INTEGRATION=internal`.

Start the daemon:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now trackpad-dwt.service
journalctl -u trackpad-dwt.service -n 5
```

The log names the keyboard and trackpad it picked. While typing, the pointer
should not move.

## Notes

- The script finds the pad by the word "trackpad" in its name, which matches
  Apple's naming. Other laptops call theirs a "Touchpad", so there the script
  exits after 60 s and `Restart=always` restarts it forever (one test machine
  logged over 3,000 restarts). Install it only on the MacBook, or change the
  name hint for your hardware.
- To keep the hwdb file, script, and unit with your dotfiles, store them under
  `~/.config/` and add a script to `~/.config/omarchy/hooks/post-update.d/`
  that copies them into place after each `omarchy update`. If the same
  dotfiles go on machines without an Apple trackpad, have that script check
  for one first, and remove the daemon where there isn't one:

  ```bash
  if ! grep -qi '^N: Name=".*trackpad' /proc/bus/input/devices; then
    if [[ -e /etc/systemd/system/trackpad-dwt.service ]]; then
      sudo systemctl disable --now trackpad-dwt.service
      sudo rm -f /etc/systemd/system/trackpad-dwt.service
      sudo systemctl daemon-reload
    fi
    sudo rm -f /usr/local/bin/trackpad-dwt
    exit 0
  fi
  ```
- To undo: `sudo systemctl disable --now trackpad-dwt.service`, delete the
  script, unit, and hwdb file, run `sudo systemd-hwdb update`, and log out.
