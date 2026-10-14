# MacBook T2: a USB-C device plugged in after boot never shows up

## Problem

On a T2 MacBook, a USB-C device that is plugged in at boot works, but one
plugged in later (a drive, a hub, a keyboard) never appears. Nothing shows up
in `lsusb` or `dmesg`. Unplugging and replugging doesn't help, only a reboot
with the device already connected.

## Why it happens

The USB-C ports hang off Intel's Titan Ridge Thunderbolt controller: a PCI
bridge (`8086:15ea`) and a USB controller (`8086:15ec`) behind it. Linux
runtime-suspends both once nothing is plugged in, which is normal. On these
Macs, plugging something in never wakes them again, so the new device is
never seen. At boot the `thunderbolt` driver logs
`device links to tunneled native ports are missing!`, a sign that the links
the kernel would use to wake the USB side aren't there.

Omarchy doesn't change PCI power management, so stock kernel behavior applies.

## Fix

Keep those two devices awake with a udev rule,
`/etc/udev/rules.d/80-usbc-awake.rules`:

```
# Keep the Titan Ridge Thunderbolt bridges and USB-C xHCI awake. Once they
# runtime-suspend, plugging in a USB-C device never wakes them, so it never
# shows up (the thunderbolt driver logs "device links to tunneled native
# ports are missing!" at boot).
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0x15ea", ATTR{power/control}="on"
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0x15ec", ATTR{power/control}="on"
```

`power/control = on` turns off runtime suspend for that device only. Check
your IDs first with `lspci -nn | grep -i thunderbolt`: other T2 models may use
a different Titan Ridge or Alpine Ridge part.

The cost is a little battery while nothing is plugged in, since the
controller no longer sleeps.

## Apply and check

```bash
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=pci --action=add
grep -H . /sys/bus/pci/devices/*/power/control | grep -i "$(lspci -Dnd 8086:15ec | cut -d' ' -f1)"
```

The last line should end in `:on`. Wait a minute with nothing plugged in,
then plug in a USB-C device: it should show up in `lsusb` right away.

## Undo

```bash
sudo rm /etc/udev/rules.d/80-usbc-awake.rules
sudo udevadm control --reload-rules
```

Reboot, or write `auto` back to each device's `power/control`, to let them
sleep again.

## Notes

- Tested on a MacBook Air with a T2 chip running Omarchy as a home server,
  where devices get plugged in long after boot.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-14.

## Recipe data

```json
{
  "id": "duff/macbook-t2-usb-c-device-plugged-in-after-boot-does-not-show-up",
  "title": "MacBook T2: a USB-C device plugged in after boot never shows up",
  "summary": "Keep the Titan Ridge Thunderbolt bridge and USB controller awake with a udev rule.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2"},
  "applies_to": "Intel MacBooks with a T2 chip (tested on a MacBook Air).",
  "requires": [{"laptop": true}, {"vendor": "Apple"}],
  "touches": ["/etc/udev/rules.d/80-usbc-awake.rules"],
  "root": true,
  "network": false,
  "installs": [],
  "runs": ["udev rule 80-usbc-awake.rules"],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-14"}]
}
```
