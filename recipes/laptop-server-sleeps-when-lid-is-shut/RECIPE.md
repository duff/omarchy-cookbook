---
{
  "id": "duff/laptop-server-sleeps-when-lid-is-shut",
  "title": "Laptop used as a headless server sleeps when the lid is shut",
  "summary": "Ignore the lid and allow only key logins over SSH.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2"},
  "applies_to": "A laptop kept closed on a shelf and reached over SSH (tested on a T2 MacBook Air).",
  "requires": [{"laptop": true}],
  "touches": ["~/.config/logind/ignore-lid.conf", "~/.config/logind/sshd.conf", "~/.config/logind/apply.sh", "~/.config/omarchy/hooks/post-update.d/apply-lid.hook", "~/.ssh/authorized_keys", "/etc/systemd/logind.conf.d/30-ignore-lid.conf", "/etc/ssh/sshd_config.d/10-key-only.conf"],
  "root": true,
  "network": true,
  "installs": [],
  "runs": ["sshd.service", "~/.config/omarchy/hooks/post-update.d/apply-lid.hook"],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
---

# Laptop used as a headless server sleeps when the lid is shut

## Problem

You want an old laptop running Omarchy to sit closed in a cupboard and stay
reachable over SSH. Closing the lid suspends it, and SSH is not running
anyway.

## Why it happens

logind's defaults suspend on lid close when the laptop is not docked.
Omarchy's drop-ins in `/etc/systemd/logind.conf.d/` change the power key and
the inhibitor delay, not the lid. Omarchy does not enable `sshd`.

The idle settings in `~/.config/omarchy/shell.json` only start the
screensaver and lock the session. They never suspend, so they can stay as
they are.

## Fix

Three small files, kept under `~/.config/logind/` and copied into `/etc`:

`~/.config/logind/ignore-lid.conf`:

```ini
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
```

`~/.config/logind/sshd.conf`, key-only SSH:

```
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
```

`~/.config/logind/apply.sh`. It adds your public key to `authorized_keys`,
installs both drop-ins, and starts `sshd`:

```bash
#!/bin/bash
# Stay up with the lid shut and accept SSH from one public key.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
lid_conf="$here/ignore-lid.conf"
ssh_conf="$here/sshd.conf"
pub="${HOME}/.ssh/id_ed25519.pub"

[[ -f $lid_conf && -f $ssh_conf && -f $pub ]]

auth="${HOME}/.ssh/authorized_keys"
mkdir -p "${HOME}/.ssh"
chmod 700 "${HOME}/.ssh"
touch "$auth"
chmod 600 "$auth"
key=$(<"$pub")
grep -qxF "$key" "$auth" || printf '%s\n' "$key" >> "$auth"

if (( EUID == 0 )); then
  mkdir -p /etc/systemd/logind.conf.d /etc/ssh/sshd_config.d
  cp "$lid_conf" /etc/systemd/logind.conf.d/30-ignore-lid.conf
  cp "$ssh_conf" /etc/ssh/sshd_config.d/10-key-only.conf
  systemctl reload systemd-logind
  systemctl enable --now sshd
else
  pkexec /bin/bash -c '
    set -euo pipefail
    mkdir -p /etc/systemd/logind.conf.d /etc/ssh/sshd_config.d
    cp "$1" /etc/systemd/logind.conf.d/30-ignore-lid.conf
    cp "$2" /etc/ssh/sshd_config.d/10-key-only.conf
    systemctl reload systemd-logind
    systemctl enable --now sshd
  ' bash "$lid_conf" "$ssh_conf"
fi
```

`pub` is the public key of the machine you connect from. Copy it to this path
first, or point the variable at it. Any key works, including one served by a
password manager's SSH agent.

To have it applied again after every `omarchy update`, add a hook,
`~/.config/omarchy/hooks/post-update.d/apply-lid.hook`:

```bash
#!/bin/bash
# Re-apply the lid and SSH settings after an Omarchy update.
set -euo pipefail

apply="${XDG_CONFIG_HOME:-$HOME/.config}/logind/apply.sh"
[[ -x $apply ]] || exit 0
exec "$apply"
```

## Apply and check

```bash
chmod +x ~/.config/logind/apply.sh
~/.config/logind/apply.sh
busctl get-property org.freedesktop.login1 /org/freedesktop/login1 \
  org.freedesktop.login1.Manager HandleLidSwitch
systemctl is-active sshd
```

The property should read `s "ignore"`. Close the lid and SSH in from another
machine.

## Undo

Delete the hook first, if you added it, or the next `omarchy update` puts
the drop-ins back. Then delete both drop-ins, reload logind, and stop `sshd`:

```bash
rm ~/.config/omarchy/hooks/post-update.d/apply-lid.hook
sudo rm /etc/systemd/logind.conf.d/30-ignore-lid.conf /etc/ssh/sshd_config.d/10-key-only.conf
sudo systemctl reload systemd-logind
sudo systemctl disable --now sshd
```

The key stays in `~/.ssh/authorized_keys`. Delete its line if that machine
should no longer log in.

## Notes

- Omarchy's lid binding still runs on close. With no external display it
  locks the session, which does not affect SSH.
- Put the drop-ins only on the server. On a laptop you carry around, ignoring
  the lid means it stays awake in a bag.
- Reach it from outside your network with a VPN such as Tailscale rather than
  by opening the SSH port.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.
