---
{
  "id": "duff/reminder-disappears-after-5-seconds",
  "title": "Reminder notification disappears after 5 seconds",
  "summary": "Make reminder toasts critical, so they stay up until dismissed.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2"},
  "applies_to": "Every machine.",
  "requires": [],
  "touches": ["~/.config/omarchy/reminders/bin/omarchy-notification-send", "~/.config/systemd/user/omarchy-reminder-.service.d/override.conf"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": ["Drop-in for every omarchy-reminder-*.service user unit that omarchy reminder starts"],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
---

# Reminder notification disappears after 5 seconds

## Problem

`omarchy reminder 30 "Check the oven"` (or a reminder set from the menu)
pops up a toast when the time comes, and the toast is gone 5 seconds later.
If you were looking away, you miss it.

## Why it happens

`omarchy reminder` schedules a transient systemd user unit named
`omarchy-reminder-<minutes>m-<timestamp>`. When it fires, it runs:

```bash
omarchy-notification-send -g 󰢌 "Reminder" "$1"
```

`omarchy-notification-send` defaults to `urgency="low"`. The shell's
notification service (`/usr/share/omarchy/shell/plugins/notifications/Service.qml`)
shows low-urgency toasts for 5 seconds (`lowPopupDuration: 5000`), normal
ones for 8, and caps both at 30 seconds whatever timeout you ask for. Only
critical toasts stay until you dismiss them.

## Fix

Make the reminder unit find a wrapper `omarchy-notification-send` first on its
`PATH`, one that adds `-u critical`. Nothing else uses that `PATH`, so other
notifications are unchanged.

The wrapper, `~/.config/omarchy/reminders/bin/omarchy-notification-send`:

```bash
#!/bin/bash
# Reminder units find this first on PATH (see omarchy-reminder-.service.d),
# so a reminder's toast is critical and stays up until it is dismissed.
exec /usr/share/omarchy/bin/omarchy-notification-send -u critical "$@"
```

```bash
chmod +x ~/.config/omarchy/reminders/bin/omarchy-notification-send
```

A drop-in for every reminder unit,
`~/.config/systemd/user/omarchy-reminder-.service.d/override.conf`:

```ini
# Applies to every omarchy-reminder-* unit that `omarchy reminder` starts.
[Service]
Environment=PATH=%h/.config/omarchy/reminders/bin:/usr/share/omarchy/bin:/usr/local/bin:/usr/bin
```

The directory name ends in a dash on purpose. systemd applies a
`<prefix>-.service.d/` drop-in to every unit whose name starts with
`<prefix>-`, and that includes the transient units `omarchy reminder`
creates. `%h` is your home directory. The wrapper calls the real script by
its full path, so it does not find itself again.

## Apply and check

```bash
systemctl --user daemon-reload
omarchy reminder 1 "Test reminder"
```

After a minute the toast should appear and stay until you dismiss it
(Super+Comma dismisses the last notification).

While a reminder is pending, you can confirm the drop-in is attached:

```bash
systemctl --user cat 'omarchy-reminder-*.service'
```

The drop-in file should be listed after the unit.

## Undo

Delete `~/.config/omarchy/reminders/bin/omarchy-notification-send` and
`~/.config/systemd/user/omarchy-reminder-.service.d/override.conf`, then run
`systemctl --user daemon-reload`. Reminders go back to toasts that close after
5 seconds.

## Notes

- If you dismissed or missed one anyway, Super+Shift+Alt+Comma opens
  notification history, which keeps the last 10.
- Setting `-t` (a longer timeout) instead of critical does not help much: the
  shell caps low and normal toasts at 30 seconds.
- Reminders still show while notifications are silenced. The shell lets
  every toast from `omarchy-notification-send` through Do Not Disturb, since
  its sender name is `omarchy-action`, and that does not change here.
- The `PATH` in the drop-in replaces the unit's whole `PATH`. Keep
  `/usr/share/omarchy/bin` in it, since the reminder command also calls
  `omarchy-shell`.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.
