# ErgoDox EZ cannot be flashed or trained from Oryx

**Tested on:** Omarchy 4.0.4, Hyprland 0.56.2 (Lua config)
**Applies to:** ZSA keyboards (tested with an ErgoDox EZ)

## Problem

Oryx, ZSA's web configurator, opens in the browser but cannot find the
keyboard. Flashing a new layout and live training both fail, though the
keyboard types normally.

## Why it happens

Oryx talks to the keyboard from the browser over WebHID and WebUSB. The
browser runs as you, and Arch's default udev rules give regular users no
access to the keyboard's raw HID and USB device nodes (`/dev/hidraw*` is
root-only by default). ZSA's Linux instructions grant that access to the
`plugdev` group, which Arch and Omarchy do not create.

## Fix

Save ZSA's rules as `~/.config/udev/rules.d/50-zsa.rules`:

```
# Oryx web flashing and live training for the Ergodox EZ.
# hidraw covers current firmware. 3297 is ZSA. feed:1307 is an older
# Ergodox. 16c0 is the HalfKay bootloader Wally uses.
KERNEL=="hidraw*", ATTRS{idVendor}=="16c0", MODE="0664", GROUP="plugdev"
KERNEL=="hidraw*", ATTRS{idVendor}=="3297", MODE="0664", GROUP="plugdev"

# Legacy live training over WebUSB. Not needed for firmware v21+.
SUBSYSTEM=="usb", ATTR{idVendor}=="3297", GROUP="plugdev"
SUBSYSTEM=="usb", ATTR{idVendor}=="feed", ATTR{idProduct}=="1307", GROUP="plugdev"

# Wally flashing, Ergodox EZ bootloader.
ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", ENV{ID_MM_DEVICE_IGNORE}="1"
ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789A]?", ENV{MTP_NO_PROBE}="1"
SUBSYSTEMS=="usb", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789ABCD]?", MODE:="0666"
KERNEL=="ttyACM*", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", MODE:="0666"
```

udev does not read rules from your home folder, so install the file in
`/etc/udev/rules.d/`, create `plugdev`, and add yourself to it:

```bash
sudo install -D -m 0644 ~/.config/udev/rules.d/50-zsa.rules /etc/udev/rules.d/50-zsa.rules
getent group plugdev >/dev/null || sudo groupadd plugdev
sudo usermod -aG plugdev "$USER"
sudo udevadm control --reload-rules
sudo udevadm trigger
```

Keeping the source copy under `~/.config/udev/` means it travels with the rest
of your dotfiles. Re-run the `install` line on a new machine.

### Optional: an Oryx launcher

Give your layout its own app-menu entry with Omarchy's web app installer.
Use your layout's URL from Oryx and any 256x256 PNG (or an icon URL):

```bash
omarchy webapp install "Ergodox" "https://configure.zsa.io/ergodox-ez/layouts/<your-layout-id>/latest/0" ~/path/to/ergodox.png
```

Storing the icon next to your dotfiles lets a new machine get the launcher
without downloading the icon again.

## Apply and check

The new group only applies after you log out and back in. Then:

```bash
id -nG | tr ' ' '\n' | grep -x plugdev
ls -l /dev/hidraw*
```

Unplug and replug the keyboard. Its `hidraw` node should belong to group
`plugdev`. Open the layout in Oryx and use **Flash** or **Train**.

## Notes

- The `hidraw` lines are the ones current firmware needs. The WebUSB lines
  are for live training on old firmware, and the `16c0` lines are for the
  bootloader that flashing uses.
- To undo, delete `/etc/udev/rules.d/50-zsa.rules`, reload udev, and remove
  yourself from `plugdev` with `sudo gpasswd -d "$USER" plugdev`.
