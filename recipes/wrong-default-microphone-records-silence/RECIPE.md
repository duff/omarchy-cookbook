# Wrong default microphone: dictation and calls record silence when docked

## Problem

This is for machines with several microphones, most often a laptop on a dock
with a webcam. With only one microphone there is nothing to pick wrongly.

Plug a laptop into a dock and the default microphone changes to an input
nobody is using, such as the dock's empty rear audio jack. Dictation
(Voxtype), calls, and recordings get silence until you pick the right
microphone by hand, and the next dock picks the wrong one again.

## Why it happens

Omarchy leaves the choice to WirePlumber. It ships two WirePlumber drop-ins
(`/usr/share/omarchy/config/wireplumber/` and `/usr/share/omarchy/default/wireplumber/`)
for Bluetooth and the ALSA mixer, and nothing about microphone order.

WirePlumber makes the available source with the highest `priority.session`
the default. Stock priorities are about 2100 for every USB input. Here the
dock's rear jack had 2109, the webcam's microphone tied with it, and the
empty jack won.

## Fix

Raise the priority of the microphones you want, in order. Create
`~/.config/wireplumber/wireplumber.conf.d/51-mic-priority.conf`. The node
names below are this machine's webcam and laptop microphones; replace them
with yours:

```
## Default microphone on this laptop. WirePlumber picks the source with the
## highest priority.session. Stock priorities are about 2100 for every USB
## input, so the dock's empty rear jack could win.
## Logi 4K Pro webcam first, then the built-in microphones.

monitor.alsa.rules = [
  {
    matches = [
      { node.name = "~alsa_input.usb-046d_Logi_4K_Pro_*" }
    ]
    actions = {
      update-props = {
        priority.session = 3000
      }
    }
  }
  {
    matches = [
      { node.name = "~alsa_input.pci-0000_00_1f.3-platform-sof_sdw.*Mic*" }
    ]
    actions = {
      update-props = {
        priority.session = 2500
      }
    }
  }
]
```

A leading `~` makes the value a regular expression, so one rule covers the
serial number and profile suffix that follow the device name. With these
rules the webcam wins whenever it is plugged in. Without it, the laptop's own
microphones beat the dock jack and the monitors' microphones.

Find your own node names and their current priorities:

```bash
pw-dump | jq -r '.[] | select(.info.props."media.class" == "Audio/Source") | "\(.info.props."priority.session")  \(.info.props."node.name")"'
```

Pick values above the stock ~2100 for the ones you want, highest first.

## Apply and check

```bash
systemctl --user restart wireplumber
wpctl status
```

In the `Audio` > `Sources` list, the `*` marks the default. Run the `pw-dump`
command again to see the new priorities.

## Undo

Delete the file and restart WirePlumber:

```bash
rm ~/.config/wireplumber/wireplumber.conf.d/51-mic-priority.conf
systemctl --user restart wireplumber
```

## Notes

- A microphone you chose by hand (in the audio menu or with `wpctl
  set-default`) is remembered in `~/.local/state/wireplumber/default-nodes` as
  `default.configured.audio.source`. While that device is present it stays
  the default, whatever the priorities say. Priorities decide only when there
  is no remembered choice or when that device is gone. Pick the microphone
  you want once by hand, or delete that line, so the two do not fight.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.

## Recipe data

```json
{
  "id": "duff/wrong-default-microphone-records-silence",
  "title": "Wrong default microphone: dictation and calls record silence when docked",
  "summary": "Raise the WirePlumber priority of the microphones you want as the default.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2"},
  "applies_to": "Machines with several audio inputs, such as a laptop on a dock with a webcam and monitor microphones (tested on a Dell XPS 16 with a CalDigit TS4 dock, a Logitech 4K Pro webcam, and Studio Displays).",
  "requires": [],
  "touches": ["~/.config/wireplumber/wireplumber.conf.d/51-mic-priority.conf"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": [],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
```
