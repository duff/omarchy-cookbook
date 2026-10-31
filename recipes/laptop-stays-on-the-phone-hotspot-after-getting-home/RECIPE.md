# Laptop stays on the phone's hotspot after getting home

## Problem

You use your phone's hotspot while out, then come home. The laptop stays on
the hotspot, using up the phone's data and battery, until you notice and pick
the home network by hand. Waking the laptop at home can also land it on the
hotspot, if the phone is nearby with its hotspot on.

## Why it happens

Omarchy uses NetworkManager for Wi-Fi
(`/usr/share/omarchy/install/hardware/network.sh`), and NetworkManager's
autoconnect works like this:

- It only picks a network when the Wi-Fi isn't connected, such as after waking
  or when the current network drops. A working connection is never left for a
  better one.
- When it does pick, it takes the saved connection with the highest
  `connection.autoconnect-priority`. Every connection starts at 0, so on a tie
  it takes the one used most recently, which after a trip is the hotspot.

So walking in the door with the laptop awake keeps the hotspot, and waking up
at home picks it too if it was used last.

## Fix

Two parts.

### 1. Put the home network first

```bash
nmcli connection modify HOME_SSID connection.autoconnect-priority 10
```

Use the name `nmcli connection show` lists for the home network; it's usually
the network's name. Any number above 0 works, as long as the hotspot stays
lower. NetworkManager saves this in the connection's file under
`/etc/NetworkManager/system-connections/`, and lets the logged-in desktop user
change it without a password. Waking at home now always joins the home
network. This alone doesn't help when you arrive with the laptop awake.

### 2. Switch back once home is in range

A user timer runs a small script every two minutes. If the laptop is on any
Wi-Fi other than home, and the home network shows up with a usable signal, it
switches to it.

- `files/prefer-home-wifi` goes in `~/.local/bin/` (made executable). Set
  `home` to the same connection name. `min_signal` is the weakest signal, out
  of 100, worth switching for: 30 is about the edge of a house. If you pinned
  the home connection to 5 GHz, as in
  [Laptop Wi-Fi falls back to 2.4 GHz with the lid shut](../laptop-wifi-falls-back-to-2-4-ghz-with-lid-shut/RECIPE.md),
  set `band=5`, so a strong 2.4 GHz signal from the same router doesn't
  trigger a switch the connection can't make.
- `files/prefer-home-wifi.service` and `files/prefer-home-wifi.timer` go in
  `~/.config/systemd/user/`.

When the laptop is already home, or not on Wi-Fi, the script stops right
away. Otherwise it asks for a fresh scan, because NetworkManager barely scans
while the current signal is good. It switches away from any network, not only
the hotspot, such as a guest network that also reaches the house.

## Apply and check

```bash
nmcli connection modify HOME_SSID connection.autoconnect-priority 10
install -D -m 0755 files/prefer-home-wifi ~/.local/bin/prefer-home-wifi
install -D -m 0644 files/prefer-home-wifi.service files/prefer-home-wifi.timer -t ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now prefer-home-wifi.timer
```

Check:

- `nmcli -g connection.autoconnect-priority connection show HOME_SSID` prints
  `10`.
- `systemctl --user list-timers prefer-home-wifi.timer` shows the next run.
- At home, join the hotspot by hand. Within two minutes the laptop should be
  back on the home network, and
  `journalctl --user -u prefer-home-wifi -n 5` should say it left the hotspot.

## Undo

```bash
systemctl --user disable --now prefer-home-wifi.timer
rm ~/.config/systemd/user/prefer-home-wifi.service ~/.config/systemd/user/prefer-home-wifi.timer
rm ~/.local/bin/prefer-home-wifi
systemctl --user daemon-reload
nmcli connection modify HOME_SSID connection.autoconnect-priority 0
```

## Notes

- If the home internet is down and you join the hotspot on purpose, the timer
  pulls you back within two minutes. Pause it with
  `systemctl --user stop prefer-home-wifi.timer`; it starts again at the next
  login.
- `nmcli -t` escapes a `:` in a network name as `\:`, which the script's
  matching doesn't handle. Home networks with a colon in the name need the
  match adjusted.
- NetworkManager can't do the switch by itself: priority is only used when
  nothing is connected.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-31.

## Recipe data

```json
{
  "id": "duff/laptop-stays-on-the-phone-hotspot-after-getting-home",
  "title": "Laptop stays on the phone's hotspot after getting home",
  "summary": "Give the home Wi-Fi first priority, and switch back to it from any other network once it's in range.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.5", "hyprland": "0.56.2", "networkmanager": "1.58.1"},
  "applies_to": "Laptops that sometimes use a phone's hotspot.",
  "requires": [{"laptop": true}],
  "touches": ["/etc/NetworkManager/system-connections/HOME_SSID.nmconnection", "~/.local/bin/prefer-home-wifi", "~/.config/systemd/user/prefer-home-wifi.service", "~/.config/systemd/user/prefer-home-wifi.timer"],
  "root": true,
  "network": true,
  "installs": [],
  "runs": ["prefer-home-wifi.timer (systemd user timer, every two minutes)"],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-31"}]
}
```
