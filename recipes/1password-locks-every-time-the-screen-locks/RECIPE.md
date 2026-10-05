# 1Password locks every time the screen locks

## Problem

Lock the screen with Super+Ctrl+L, or let it lock after the idle timeout, and
1Password locks too. After every unlock you type the 1Password password again,
even with 1Password's own setting to lock when the computer locks turned
off.

## Why it happens

Every screen lock goes through `omarchy-system-lock`, from the key binding,
the menu, or the shell's idle service. After starting the lock screen it runs:

```bash
timeout --kill-after=1s 3s 1password --lock
```

whenever 1Password is running. That locks 1Password whatever its own settings
say.

## Fix

Put a stand-in for the `1password` command in `/usr/local/bin`, which comes
before `/usr/bin` in `PATH`. It ignores exactly `1password --lock` and passes
everything else to the real app, so 1Password's own lock settings decide again.

Save it as `~/.config/omarchy/1password/1password`:

```bash
#!/bin/bash
# Stands in for /usr/bin/1password from /usr/local/bin, which comes first in
# PATH. omarchy-system-lock runs `1password --lock` on every screen lock; skip
# that so 1Password follows its own lock settings. Everything else runs the app.
[[ $* == --lock ]] && exit 0
exec /usr/bin/1password "$@"
```

Then install it:

```bash
sudo install -Dm755 ~/.config/omarchy/1password/1password /usr/local/bin/1password
```

Keeping the source in `~/.config` lets it travel with the rest of your
config. Install it again on each machine.

This is a trade-off. With it, anyone who gets past your screen lock finds
1Password already open. Leave 1Password's own lock setting on if you want it
to lock with the screen after all.

## Apply and check

```bash
command -v 1password
```

It should print `/usr/local/bin/1password`. With 1Password open and unlocked,
lock the screen with Super+Ctrl+L and unlock it. 1Password should still be
unlocked.

## Undo

```bash
sudo rm /usr/local/bin/1password
rm -r ~/.config/omarchy/1password
```

## Notes

- To lock 1Password by hand, use its own menu or the tray icon. The stand-in
  only skips `--lock` on its own, so `/usr/bin/1password --lock` still works.
- If an Omarchy update changes how the lock calls 1Password, for example by
  adding another option, the stand-in passes that call through and 1Password
  locks again. Check `omarchy-system-lock` after an update if that happens.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-02.

## Recipe data

```json
{
  "id": "duff/1password-locks-every-time-the-screen-locks",
  "title": "1Password locks every time the screen locks",
  "summary": "A stand-in for the 1password command that ignores Omarchy's lock call.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "1password": "8.12.36"},
  "applies_to": "Machines that use the 1Password app.",
  "requires": [{"command": "1password"}],
  "touches": ["~/.config/omarchy/1password/1password", "/usr/local/bin/1password"],
  "root": true,
  "network": false,
  "installs": [],
  "runs": [],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-02"}]
}
```
