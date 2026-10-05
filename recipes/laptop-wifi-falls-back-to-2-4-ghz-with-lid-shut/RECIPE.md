# Laptop Wi-Fi falls back to slow 2.4 GHz with the lid shut, or never joins 6 GHz

## Problem

Two related symptoms on the same laptop:

- The router has a 6 GHz radio, but the laptop never connects to it.
- Docked with the lid shut, the connection drops within seconds and comes
  back on the crowded 2.4 GHz band, where it stays. Speed falls to a fraction
  of normal, with pings in the hundreds of milliseconds.

## Why it happens

Omarchy uses NetworkManager, which keeps one saved profile per network. On a
router that offers WPA2 on its 2.4 and 5 GHz radios, that profile can end up
as WPA2-Personal (`wpa-psk`). The 6 GHz band only allows WPA3 (SAE) with
protected management frames required, so a WPA2 profile can never use it.

After switching to WPA3, the laptop joined 6 GHz, but with the lid shut the
6 GHz link lost beacons and dropped within seconds. wpa_supplicant then fell
back to the 2.4 GHz channel, which was crowded, and stayed there. The 5 GHz
link stayed connected with the lid shut, and with the lid open its speed at
the desk matched 6 GHz.

## Fix

Change the saved profile to WPA3 and pin it to the 5 GHz band. The
passphrase stays in NetworkManager. Replace `Your Network` with the profile
name from `nmcli connection show`:

```bash
#!/bin/bash
# Pin one saved Wi-Fi profile to WPA3 on 5 GHz.
# The passphrase stays in NetworkManager; this only changes the saved profile.
set -euo pipefail

name="Your Network"

if ! nmcli -t -f NAME connection show | grep -qx "$name"; then
  echo "No saved connection $name; leaving Wi-Fi alone."
  exit 0
fi

mgmt=$(nmcli -g 802-11-wireless-security.key-mgmt connection show "$name")
pmf=$(nmcli -g 802-11-wireless-security.pmf connection show "$name")
band=$(nmcli -g 802-11-wireless.band connection show "$name")
if [[ $mgmt == sae && $pmf == 3 && $band == a ]]; then
  echo "$name already uses WPA3 on 5 GHz."
  exit 0
fi

settings=(wifi-sec.key-mgmt sae wifi-sec.pmf 3 wifi.band a)

# The desktop session may modify this system connection through polkit.
# Fall back to sudo when that is refused.
if ! nmcli connection modify "$name" "${settings[@]}"; then
  sudo nmcli connection modify "$name" "${settings[@]}"
fi

if nmcli -t -f NAME,DEVICE connection show --active | grep -q "^${name}:"; then
  if ! nmcli connection up "$name"; then
    sudo nmcli connection up "$name"
  fi
fi

echo "$name now uses WPA3 on 5 GHz."
```

- `wifi-sec.key-mgmt sae` is WPA3-Personal.
- `wifi-sec.pmf 3` makes protected management frames required, which WPA3
  needs.
- `wifi.band a` limits the profile to 5 GHz. (`bg` would be 2.4 GHz. Leaving
  it empty lets the driver choose.)

If you only want 6 GHz, drop `wifi.band a` and keep the two WPA3 settings.

Saving this as a script (for example `~/.config/nm/apply.sh`) rather than
running the commands once means a reinstalled machine gets the same profile
after you rejoin the network.

## Apply and check

Run the script, then:

```bash
nmcli -f 802-11-wireless-security.key-mgmt,802-11-wireless-security.pmf,802-11-wireless.band connection show "Your Network"
nmcli -f IN-USE,CHAN,FREQ,SECURITY dev wifi | grep '^\*'
```

The connected line should show a 5 GHz frequency (5xxx MHz). Close the lid,
then compare `ping` to your router and a speed test against the lid-open
numbers.

## Undo

Put the profile back on WPA2 with no band pin, then reconnect. As in the
script, use `sudo` if NetworkManager refuses the change.

```bash
nmcli connection modify "Your Network" wifi.band "" wifi-sec.key-mgmt wpa-psk wifi-sec.pmf 0
nmcli connection up "Your Network"
```

If you saved the script, delete it as well.

## Notes

- Check that your router offers WPA3 (or WPA2/WPA3 mixed mode) on 5 GHz
  before forcing `sae`. If it only offers WPA2 there, set
  `wifi-sec.key-mgmt wpa-psk` and `wifi-sec.pmf 0` instead, and keep the band
  pin.
- This keeps the laptop off 2.4 GHz; it does not make a shut lid as fast as
  an open one. On this laptop a fully closed lid still cuts throughput a lot
  on any band. It looks like an RF effect of the closed lid, not a setting:
  disabling the lid switch in the BIOS changed nothing, and a lid propped
  about an inch open still tested poorly. Only a well-opened lid gave full
  speed. Omarchy issue #9922 tracks the same problem on other XPS models.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.

## Recipe data

```json
{
  "id": "duff/laptop-wifi-falls-back-to-2-4-ghz-with-lid-shut",
  "title": "Laptop Wi-Fi falls back to slow 2.4 GHz with the lid shut, or never joins 6 GHz",
  "summary": "Switch the saved Wi-Fi profile to WPA3 and pin it to the 5 GHz band.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2"},
  "applies_to": "Laptops on a tri-band (2.4/5/6 GHz) router, especially used docked with the lid shut (tested on a Dell XPS 16 with Intel BE211 Wi-Fi).",
  "requires": [{"laptop": true}],
  "touches": ["/etc/NetworkManager/system-connections/<network>.nmconnection", "~/.config/nm/apply.sh"],
  "root": true,
  "network": true,
  "installs": [],
  "runs": [],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
```
