# Intel laptop screen stays black after undocking with the lid shut and sleeping

## Problem

This is for laptops with Intel graphics that you use docked with the lid
shut. The fix works through Intel's `intel_backlight` and the panel's
`card0-eDP-1` connector.

The laptop sits closed on a desk, driving external displays. You unplug the
displays and carry it away with the lid still shut, and it suspends. When you
open the lid, the internal screen stays black: no backlight, no lock screen.
Hyprland reports the panel as on. Only another lid close, or a reboot, brings
it back.

## Why it happens

With the lid shut and an external display connected, Omarchy's clamshell mode
turns the internal panel off. `omarchy-hyprland-monitor-clamshell` writes
`hl.monitor({ output = "eDP-1", disabled = true })` to
`~/.local/state/omarchy/toggles/hypr/internal-monitor-clamshell.lua` and
reloads Hyprland.

When the last external display is unplugged, `omarchy-hyprland-monitor-watch`
sees the `monitorremoved` event and runs the clamshell script again. It is no
longer clamshell mode (no external display), so the script deletes the flag
and turns the internal panel back on, even though the lid is still shut and the
panel is powered down. On this Intel laptop the driver rejects that modeset.
logind then suspends the machine (lid shut, nothing docked), and on wake
Hyprland marks the panel "on" while its backlight (`bl_power`) stays off.

## Fix

The fix has two parts: a user loop that keeps the panel disabled when the
lid was shut at the desk and the displays are then unplugged, and a system
sleep hook that sets up the right path on wake.

### 1. Keep the panel off while the lid is shut

`~/.config/logind/keep-panel-off-while-closed` (make it executable):

```bash
#!/bin/bash
# Omarchy turns the internal panel on as soon as the desk displays disappear,
# even though the lid is still shut and the panel is powered down. That
# rejected modeset is what suspend saves. Hold the panel disabled until the
# lid is actually open, then hand it back to the normal clamshell path.
#
# Only when the lid was shut while docked. A plain lid close away from the
# desk keeps the panel on: it is the only output, and the lock screen needs
# it before suspend. Turning it off there left the session unlocked.

set -u

flag="$HOME/.local/state/omarchy/toggles/hypr/internal-monitor-clamshell.lua"
disable_line='hl.monitor({ output = "eDP-1", disabled = true })'
lock="${XDG_RUNTIME_DIR:-/tmp}/keep-panel-off-while-closed.lock"

exec 9>"$lock"
flock -n 9 || exit 0

lid_closed() {
  local state
  shopt -s nullglob
  for state in /proc/acpi/button/lid/*/state; do
    [[ $(<"$state") == *closed* ]] && return 0
  done
  return 1
}

holding=0
docked_closed=0
while true; do
  if ! lid_closed; then
    docked_closed=0
  elif omarchy-hw-external-monitors; then
    docked_closed=1
  fi

  if (( docked_closed )) && ! omarchy-hw-external-monitors; then
    holding=1
    mkdir -p "$(dirname "$flag")"
    if [[ ! -f $flag ]] || [[ $(<"$flag") != "$disable_line" ]]; then
      printf '%s\n' "$disable_line" >"$flag"
    fi
    if hyprctl monitors all -j 2>/dev/null | jq -e 'any(.[]; .name == "eDP-1" and .disabled != true)' >/dev/null; then
      hyprctl eval "$disable_line" >/dev/null 2>&1 || true
    fi
  elif (( holding )) && ! lid_closed; then
    holding=0
    omarchy-hyprland-monitor-clamshell >/dev/null 2>&1 || true
    hyprctl dispatch 'hl.dsp.dpms({ action = "enable", monitor = "eDP-1" })' >/dev/null 2>&1 || true
  fi
  sleep 1
done
```

It writes the same clamshell flag Omarchy uses, so Omarchy's own reloads keep
the panel off. When the lid opens it runs Omarchy's clamshell script, which
removes the flag, reloads, and turns the panel on.

It only holds the panel off when the lid was shut while displays were
connected. Close the lid away from the desk and it leaves the panel alone:
there the panel is the only screen, and the lock screen needs it before the
laptop suspends.

Start it from `~/.config/hypr/autostart.lua`:

```lua
-- Hold the internal panel off when the desk displays are unplugged with the
-- lid shut, so Omarchy does not modeset a powered-down panel.
o.launch_on_start(os.getenv("HOME") .. "/.config/logind/keep-panel-off-while-closed")
```

### 2. Turn the backlight on after the wake

The loop alone does not cover a suspend that starts right after undocking.
A systemd sleep hook does. Save it as `~/.config/logind/edp-lid-restore` and
set `user` to your login name:

```bash
#!/bin/bash
# Unplugging the desk displays with the lid shut makes Omarchy modeset the
# internal panel while it is powered down. That commit is rejected, suspend
# saves the rejection, and the wake turns the panel "on" in Hyprland without
# enabling its backlight. The screen stays black.
#
# user.slice is already frozen when pre runs, so this hook must not call
# hyprctl there. The session call is killed. pre only records that the lid
# was shut and puts the clamshell flag back, so the wake takes the path that
# turns the backlight on.

user=your-login-name
uid=$(id -u "$user")
home=$(getent passwd "$user" | cut -d: -f6)

flag=/run/edp-lid-restore
clamshell_flag=$home/.local/state/omarchy/toggles/hypr/internal-monitor-clamshell.lua
disable_line='hl.monitor({ output = "eDP-1", disabled = true })'
backlight=/sys/class/backlight/intel_backlight/bl_power
connector=/sys/class/drm/card0-eDP-1/enabled

lid_closed() {
  local state
  shopt -s nullglob
  for state in /proc/acpi/button/lid/*/state; do
    [[ $(<"$state") == *closed* ]] && return 0
  done
  return 1
}

run_hypr() {
  local runtime sig
  runtime=/run/user/$uid
  [[ -d $runtime/hypr ]] || return 0
  sig=$(find "$runtime/hypr" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | head -1)
  [[ -n ${sig:-} ]] || return 0
  timeout "${HYPR_TIMEOUT:-3}s" runuser -u "$user" -- env \
    XDG_RUNTIME_DIR="$runtime" \
    HYPRLAND_INSTANCE_SIGNATURE="$sig" \
    "$@"
}

note() {
  echo "edp-lid-restore: $*"
}

restore_flag() {
  mkdir -p "$(dirname "$clamshell_flag")"
  printf '%s\n' "$disable_line" >"$clamshell_flag"
  chown "$user:$user" "$clamshell_flag" "$(dirname "$clamshell_flag")" || true
}

unblank() {
  [[ -w $backlight ]] || return 0
  echo 0 >"$backlight" || true
}

panel_showing() {
  local enabled bl
  [[ -r $connector ]] || return 1
  enabled=$(<"$connector")
  bl=4
  [[ -r $backlight ]] && bl=$(<"$backlight")
  [[ $enabled == enabled && $bl == 0 ]]
}

case "${1:-}" in
  pre)
    rm -f "$flag"
    if lid_closed; then
      touch "$flag"
      restore_flag
      note "lid closed; clamshell flag restored, no hyprctl during freeze"
    fi
    ;;
  post)
    [[ -f $flag ]] || exit 0
    rm -f "$flag"
    systemd-run --no-block --collect /usr/lib/systemd/system-sleep/edp-lid-restore resume || true
    ;;
  resume)
    sleep 1
    for _ in 1 2 3 4 5 6 7 8 9 10 11 12; do
      if lid_closed; then
        note "lid still closed"
        sleep 1
        continue
      fi
      restore_flag
      HYPR_TIMEOUT=8 run_hypr omarchy-hyprland-monitor-clamshell || true
      HYPR_TIMEOUT=5 run_hypr hyprctl dispatch 'hl.dsp.dpms({ action = "enable", monitor = "eDP-1" })' || true
      unblank
      note "connector=$(<"$connector" 2>/dev/null || echo missing) backlight=$(<"$backlight" 2>/dev/null || echo missing)"
      panel_showing && exit 0
      sleep 1
    done
    note "gave up"
    ;;
esac
exit 0
```

How it works:

- `pre` runs as root just before suspend. If the lid is shut it writes the
  clamshell flag back. It does not call `hyprctl`: by then systemd has frozen
  the user session, and the call would be killed.
- `post` runs after the wake. It hands the real work to a transient unit
  (`systemd-run`) so the wake is not held up.
- `resume` waits up to 12 seconds for the lid to open. It then runs Omarchy's
  clamshell script with the flag present, so the script takes the branch that
  deletes the flag, reloads, and sends DPMS on. Last, it writes `0` to the
  backlight's `bl_power`. It checks success in sysfs, not in Hyprland, because
  Hyprland is what reported "on" while the screen was dark.

Check the two sysfs paths on your machine first:

```bash
ls -d /sys/class/drm/*eDP* /sys/class/backlight/*
```

Install the hook. systemd runs every executable in this directory with `pre`
or `post` around each sleep:

```bash
sudo install -m 0755 -o root -g root ~/.config/logind/edp-lid-restore /usr/lib/systemd/system-sleep/edp-lid-restore
```

## Apply and check

Log out and back in (or run the loop by hand once) so the autostart line
starts the watcher:

```bash
pgrep -af keep-panel-off-while-closed
```

Then test the real sequence: dock, close the lid, unplug the displays, let it
suspend, wait, and open the lid. The panel should light within a few seconds.
The hook's messages are in the journal:

```bash
journalctl -b -g edp-lid-restore
```

## Undo

```bash
sudo rm /usr/lib/systemd/system-sleep/edp-lid-restore
```

Delete the `o.launch_on_start` line from `~/.config/hypr/autostart.lua` and the
two scripts in `~/.config/logind/`, then log out and back in to stop the loop.

## Notes

- Things that did not work:
  - Calling `hyprctl` from the `pre` hook to disable the panel before
    suspend. User processes are already frozen, so the call is killed.
  - Checking `hyprctl monitors` after the wake to see whether the panel is
    lit. Hyprland reported it enabled while the backlight was off, so the
    hook exited early and the screen stayed black.
  - Holding the panel off whenever the lid is shut and nothing is connected.
    That includes an ordinary lid close away from the desk, where the panel is
    the only screen. The lock screen had nowhere to show before the suspend,
    and the laptop woke unlocked.
- A lid resting slightly open on a spacer at the desk does not trip the lid
  switch, so clamshell mode never turns the panel off. A watcher that ran
  `omarchy-hyprland-monitor-internal off` on every `monitoraddedv2` event
  handled that case: Omarchy turns the panel back on by itself when the last
  external display goes. It was removed again once the lid stayed fully open
  at the desk.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.

## Recipe data

```json
{
  "id": "duff/laptop-screen-stays-black-after-undocked-sleep",
  "title": "Intel laptop screen stays black after undocking with the lid shut and sleeping",
  "summary": "Keep the panel off while the lid is shut, and turn it back on after the wake.",
  "version": 2,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2"},
  "applies_to": "Laptops with Intel graphics used docked with the lid shut (tested on a Dell XPS 16).",
  "requires": [{"laptop": true}],
  "touches": ["~/.config/logind/keep-panel-off-while-closed", "~/.config/hypr/autostart.lua", "~/.config/logind/edp-lid-restore", "/usr/lib/systemd/system-sleep/edp-lid-restore", "~/.local/state/omarchy/toggles/hypr/internal-monitor-clamshell.lua"],
  "root": true,
  "network": false,
  "installs": [],
  "runs": ["keep-panel-off-while-closed loop, started from ~/.config/hypr/autostart.lua", "systemd sleep hook /usr/lib/systemd/system-sleep/edp-lid-restore"],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
```
