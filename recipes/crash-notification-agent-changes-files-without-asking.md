# Clicking "Process crashed" starts an agent that may change files without asking

**Tested on:** Omarchy 4.0.4, Hyprland 0.56.2 (Lua config)
**Applies to:** every machine

## Problem

When a program dumps core, Omarchy shows a "Process crashed: <name>"
notification. Clicking it opens your default coding agent with a prompt to
diagnose the crash. Omarchy starts that agent in its unattended mode (Claude
Code with `--permission-mode auto`, Codex with `--approve-for-me`, and so on),
so it can go ahead and edit config or restart things before you have read the
diagnosis.

It also starts the agent in `~/Work` (or wherever you clicked from), not in the
repo that holds your config, so the agent does not see your own rules about
where changes belong.

And if you have never picked a default agent, the notification never shows up.

## Why it happens

- `omarchy-crash-watch.service` (a systemd user unit) runs
  `/usr/bin/omarchy-crash-watch`. It follows the journal for systemd-coredump
  entries and sends a notification with
  `--exec omarchy-agent-crash "$pid" "$comm" "$exe" "$signal"`.
- The watcher skips every crash while `omarchy-default-agent` prints nothing.
  Omarchy ships with no default agent.
- `omarchy-agent-crash` builds a prompt that points at the `diagnose-crash`
  skill and runs `omarchy-agent --prompt "$prompt"`.
- `omarchy-agent` launches the default agent with its "don't stop to ask" flag,
  for example `claude --permission-mode auto -- "$prompt"`.

## Fix

First, pick a default agent. This writes `~/.config/omarchy/defaults/agent`,
which is a one-line file such as `claude`. It installs the agent if needed
and then opens it:

```bash
omarchy default agent claude
```

Then wrap the stock watcher instead of copying it, so Omarchy updates to the
watcher still apply. Three small files and a systemd drop-in.

`~/.config/systemd/user/omarchy-crash-watch.service.d/override.conf`:

```ini
# Run Omarchy's watcher through ~/.config/omarchy/crash/watch.
[Service]
ExecStart=
ExecStart=%h/.config/omarchy/crash/watch
```

`~/.config/omarchy/crash/watch` reads the stock watcher fresh on every start
and changes only the click target:

```bash
#!/bin/bash
# Run Omarchy's crash watcher with one change: a click on "Process crashed"
# runs ./agent-crash instead of omarchy-agent-crash. The stock watcher is read
# fresh on every start, so Omarchy updates still apply. If an update rewrites
# the --exec line, this falls back to the stock watcher unchanged.

stock="${OMARCHY_PATH:-/usr/share/omarchy}/bin/omarchy-crash-watch"
here=$(dirname "$(readlink -f "$0")")

if grep -q -- '--exec omarchy-agent-crash ' "$stock"; then
  exec bash -c "$(sed "s|--exec omarchy-agent-crash |--exec $here/agent-crash |" "$stock")" omarchy-crash-watch
fi

echo "omarchy-crash-watch no longer matches; running it unchanged" >&2
exec "$stock"
```

`~/.config/omarchy/crash/agent-crash` runs the stock `omarchy-agent-crash`
(which still writes the prompt) from your config repo, with a replacement
`omarchy-agent` first on `PATH`. Change the `cd` to the directory whose
instructions you want the agent to read:

```bash
#!/bin/bash
# Clicked from a "Process crashed:" notification. Runs Omarchy's
# omarchy-agent-crash, which writes the diagnosis prompt, from the config repo
# so the agent reads that repo's instructions. bin/omarchy-agent comes first on
# PATH and opens Claude in plan mode.

here=$(dirname "$(readlink -f "$0")")
cd "$HOME/Work/your-config-repo" || cd "$HOME/Work" || exit 1
PATH="$here/bin:$PATH" exec omarchy-agent-crash "$@"
```

`~/.config/omarchy/crash/bin/omarchy-agent` is only on `PATH` inside
`agent-crash`. It starts Claude Code in plan mode, so it investigates and then
waits for your approval before changing anything. Any other agent, or any
other call, goes to the stock launcher:

```bash
#!/bin/bash
# Stands in for omarchy-agent only inside ../agent-crash. Omarchy starts Claude
# in auto mode, which may change files unasked. Plan mode diagnoses first and
# waits for approval before changing anything. Other default agents get the
# stock launcher.

stock="${OMARCHY_PATH:-/usr/share/omarchy}/bin/omarchy-agent"

if [[ $(omarchy-default-agent) != claude || ${1:-} != --prompt || -z ${2:-} ]]; then
  exec "$stock" "$@"
fi

exec omarchy-launch-tui --app-id=org.omarchy.agent claude --permission-mode plan -- "$2"
```

`--app-id=org.omarchy.agent` matches what the stock launcher uses, so window
rules that target agent windows still apply.

Make the three scripts executable:

```bash
chmod +x ~/.config/omarchy/crash/watch ~/.config/omarchy/crash/agent-crash \
  ~/.config/omarchy/crash/bin/omarchy-agent
```

## Apply and check

```bash
systemctl --user daemon-reload
systemctl --user restart omarchy-crash-watch.service
systemctl --user status omarchy-crash-watch.service
```

The status should list the drop-in under `Drop-In:`, and the running
`bash -c` command line should contain `--exec` followed by the full path to
`~/.config/omarchy/crash/agent-crash`, instead of `--exec omarchy-agent-crash`.

To try it without waiting for a real crash, pick a PID from
`coredumpctl list` and run the handler by hand:

```bash
~/.config/omarchy/crash/agent-crash <pid>
```

An agent window should open in your config repo, in plan mode.

## Notes

- If a later Omarchy release changes the `--exec omarchy-agent-crash` line,
  `watch` logs a line to the unit's journal and runs the stock watcher, so you
  get stock behavior rather than no crash notifications.
- The plan-mode swap only covers Claude Code. For another agent, add a branch
  with that agent's own read-only or ask-first mode.
- `omarchy toggle crash capture` still turns the watcher off and on; the
  drop-in does not change that.
- To undo, delete the drop-in and `~/.config/omarchy/crash/`, then run
  `systemctl --user daemon-reload` and restart the service.
