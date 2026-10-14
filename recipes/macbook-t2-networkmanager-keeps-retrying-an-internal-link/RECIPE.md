# MacBook T2: NetworkManager keeps retrying an internal network link

## Problem

On a T2 MacBook, NetworkManager shows an extra wired connection that never
connects. It sits on "connecting" or "getting IP configuration", gives up,
and starts again, over and over, filling the journal. Nothing is plugged in.

## Why it happens

The T2 chip talks to macOS over a USB network link, and Linux sees it as an
ordinary USB Ethernet adapter (named something like `enp1s0f1u1`). It always
reports a cable connected, so NetworkManager creates an automatic wired
profile and asks for DHCP. Nothing on the T2 answers, so it times out and
retries forever.

Omarchy uses NetworkManager's defaults, which manage every Ethernet device.

## Fix

Tell NetworkManager to leave that device alone, in
`/etc/NetworkManager/conf.d/80-t2-link-unmanaged.conf`:

```ini
# The T2 chip's internal USB network link always has carrier but nothing
# answers DHCP on it, so NetworkManager would retry it forever.
[keyfile]
unmanaged-devices=mac:ac:de:48:00:11:22
```

The T2 link has the same MAC address, `ac:de:48:00:11:22`, on every T2 Mac,
so this doesn't name your machine. Check yours with `ip link`; matching by
MAC keeps working if the interface is renamed.

## Apply and check

```bash
sudo nmcli general reload conf
nmcli device
```

The T2 link should show as `unmanaged`. Then delete the automatic profile
NetworkManager made for it: find its name with
`nmcli -f NAME,DEVICE connection show` (usually "Wired connection 1") and run
`nmcli connection delete "<name>"`.

## Undo

```bash
sudo rm /etc/NetworkManager/conf.d/80-t2-link-unmanaged.conf
sudo nmcli general reload conf
```

NetworkManager manages the link again and recreates its automatic profile.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-14.

## Recipe data

```json
{
  "id": "duff/macbook-t2-networkmanager-keeps-retrying-an-internal-link",
  "title": "MacBook T2: NetworkManager keeps retrying an internal network link",
  "summary": "Mark the T2's internal USB network link unmanaged by its fixed MAC address.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "networkmanager": "1.58.1"},
  "applies_to": "Intel MacBooks with a T2 chip (tested on a MacBook Air).",
  "requires": [{"laptop": true}, {"vendor": "Apple"}],
  "touches": ["/etc/NetworkManager/conf.d/80-t2-link-unmanaged.conf"],
  "root": true,
  "network": false,
  "installs": [],
  "runs": [],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-14"}]
}
```
