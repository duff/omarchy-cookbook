# Reminders only take minutes, and a reboot loses them

## Problem

Omarchy's reminder takes a number of minutes and nothing else. To be reminded
at 4 PM you work out how many minutes away that is, and "tomorrow at 9" isn't
possible at all. The countdown also runs only while the laptop is awake, so
after a nap in a bag the reminder comes late, and a reboot or logout forgets
every reminder you set.

## Why it happens

`omarchy reminder` (`/usr/share/omarchy/bin/omarchy-reminder`) accepts only a
whole number of minutes, then starts a transient systemd user timer that
counts down from now:

```bash
systemd-run --user --quiet --collect --on-active="${minutes}m" --unit="$unit" \
  bash -c 'omarchy-notification-send -g 󰢌 "Reminder" "$1"; ...' bash "$message" "$message_file"
```

- `--on-active` counts time the machine is running, so time spent asleep
  doesn't count toward it.
- Transient units, and the message files kept in `$XDG_RUNTIME_DIR`, are gone
  at logout, so nothing survives a reboot.
- The Super+Ctrl+R box (the `omarchy.reminders` shell plugin) asks for minutes
  and then a message, the same way.

## Fix

A `remind` command that reads clock times, dates, and durations, sets each
reminder for its clock time, and saves it to disk so the next login brings it
back. A clone of Omarchy's reminder box uses it, so Super+Ctrl+R takes the
time and the message in one line.

### 1. The `remind` command

Save [`files/remind`](files/remind) as `~/.config/omarchy/reminders/remind`
and link it onto your `PATH`:

```bash
mkdir -p ~/.local/bin
chmod +x ~/.config/omarchy/reminders/remind
ln -sfn ~/.config/omarchy/reminders/remind ~/.local/bin/remind
```

It's a Python script with no dependencies beyond Python itself. What it reads:

```text
remind 4pm call Bob             at a time: 12:15pm, 4 p.m., noon, 16:00,
                                at 4 (whichever 4 o'clock comes next)
remind 3h check laundry         after a while: 20 (minutes), 90m, 1h30m,
                                in 2 hours, half an hour
remind tomorrow 9am pay rent    on a day: tomorrow, fri, oct 30, 10/30,
                                tomorrow morning, tonight
remind call Bob at 4pm          the time can also come last
remind show [--json]            what's waiting, and how long until each
remind cancel <unit>            drop one (the unit from show --json)
remind clear                    drop them all
```

It also reads times the way dictation writes them: "1.12 p.m." as 1:12 PM,
"at four", "four o'clock", "a quarter past four", "ten to five", and "one and
a half hours". A leading "remind me" is dropped, so a dictated "Remind me at
4pm to call Bob" works too.

Why it works:

- **Clock time, not a countdown.** Each reminder is a `systemd-run` timer with
  `--on-calendar` set to the exact moment, so it isn't pushed back by sleep. A
  reminder that came due while the laptop slept goes off on waking.
- **Saved to disk.** Each reminder is also a small JSON file in
  `~/.local/state/remind/`. The first `remind` run after login (step 3) sets
  the timers again. One that came due while the machine was off goes off a
  minute after login, with "Was due ..." added to the toast.
- **Named like Omarchy's own.** The timers are `omarchy-reminder-<minutes>m-<id>`,
  and the message goes where Omarchy keeps it, so the bar's reminder
  indicator and `omarchy reminder show` still see them. If you use
  [Reminder notification disappears after 5 seconds](../reminder-disappears-after-5-seconds/RECIPE.md),
  its drop-in applies to these timers as well.
- **Stock `clear` stays honest.** `omarchy reminder clear` stops the timers
  but can't see the saved files. The next `remind` run notices timers that
  were stopped early and drops their files, so they don't come back.

### 2. The reminder box

Clone Omarchy's box, which switches Super+Ctrl+R and the menu's Reminder >
Set to your copy:

```bash
omarchy plugin clone omarchy.reminders
```

Then replace the clone's two files in `~/.config/omarchy/plugins/<you>.reminders/`
with [`files/ReminderFlow.qml`](files/ReminderFlow.qml) and
[`files/ReminderFlowModel.js`](files/ReminderFlowModel.js). The box:

- takes the time and the message together ("4pm call Bob", "20m tea"),
- shows what it will set as you type, by running `remind parse -- <text>`, and
  says so when it can't tell when,
- lists what's already waiting with the time left, where Up and Down pick
  one and Delete cancels it.

### 3. Bring reminders back at login

In `~/.config/hypr/autostart.lua`:

```lua
-- Bring back reminders a reboot or logout lost; one that came due meanwhile
-- goes off a minute after login.
o.exec_on_start(os.getenv("HOME") .. "/.config/omarchy/reminders/remind restore")
```

### 4. Show and clear through `remind`

Stock's show and clear keys, and the menu's Show all and Clear all, run
`omarchy reminder`. Its clear leaves the saved files, so point them at
`remind`. In `~/.config/hypr/bindings.lua`:

```lua
local remind = os.getenv("HOME") .. "/.config/omarchy/reminders/remind"
hl.unbind("SUPER + CTRL + ALT + R")
o.bind("SUPER + CTRL + ALT + R", "Show reminders", remind .. " show")
hl.unbind("SUPER + SHIFT + CTRL + R")
o.bind("SUPER + SHIFT + CTRL + R", "Clear reminders", remind .. " clear")
```

And in `~/.config/omarchy/extensions/omarchy-menu.jsonc`:

```jsonc
"trigger.reminder.show": {"icon":"󰢌","label":"Show all","action":"~/.config/omarchy/reminders/remind show"},
"trigger.reminder.clear": {"icon":"󰢌","label":"Clear all","action":"~/.config/omarchy/reminders/remind clear"},
```

### 5. Optional: have your agent use it

So that "remind me at 4 to call Bob" typed to a coding agent sets a clock-time
reminder, add a line to its instructions (`~/.claude/CLAUDE.md` for Claude
Code, or your shared `AGENTS.md`):

```markdown
- When I ask for a reminder, set it with `remind <when> <what>`, not `omarchy reminder`. It takes clock times as well as durations (`remind 4pm call Bob`, `remind 3h check laundry`, `remind tomorrow 9am pay rent`) and keeps reminders across a reboot. `remind show` lists them with the time left; `remind --help` has the rest.
```

## Apply and check

```bash
hyprctl reload
hyprctl configerrors
~/.config/omarchy/reminders/remind restore
```

- `remind parse -- tomorrow 9am pay rent` prints JSON with `"ok": true` and
  `"when": "Tomorrow 9:00 AM"`.
- `remind 2m test` shows a "Test" toast saying when, and two minutes later
  the reminder goes off. `remind show` lists it in between.
- Super+Ctrl+R opens the box. Type "4pm call Bob" and the line under it shows
  what will be set before you press Enter.
- Set a reminder for tomorrow, reboot, and `remind show` still lists it.

## Undo

```bash
remind clear
rm -rf ~/.local/state/remind ~/.config/omarchy/reminders/remind ~/.local/bin/remind
omarchy plugin remove <you>.reminders
omarchy plugin enable omarchy.reminders
```

Then delete the `remind restore` line from `autostart.lua`, the show and
clear bindings from `bindings.lua`, the two `trigger.reminder` entries from
`omarchy-menu.jsonc`, and the line in your agent's instructions if you added
it. Run `hyprctl reload`. Super+Ctrl+R and `omarchy reminder` work as stock
again.

## Notes

- With no day named, "at 4" is whichever 4 o'clock comes next. With a day
  named, a bare hour is read as a working hour: "tomorrow at 9" is 9 AM,
  "fri at 3" is 3 PM.
- A lone trailing number is never read as a time, so "call 911" and "pay
  Bob 12.50" set nothing and say so.
- Reminders set with `omarchy reminder` still work, and `remind show` lists
  them, but they still don't survive a reboot.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-31.

## Recipe data

```json
{
  "id": "duff/reminders-only-take-minutes-and-vanish-at-reboot",
  "title": "Reminders only take minutes, and a reboot loses them",
  "summary": "Set reminders by clock time or date with a remind command, and keep them across reboots.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.5", "hyprland": "0.56.2"},
  "applies_to": "Every machine.",
  "requires": [{"command": "python3"}],
  "touches": ["~/.config/omarchy/reminders/remind", "~/.local/bin/remind", "~/.config/omarchy/plugins/<you>.reminders/ReminderFlow.qml", "~/.config/omarchy/plugins/<you>.reminders/ReminderFlowModel.js", "~/.config/omarchy/shell.json", "~/.config/hypr/autostart.lua", "~/.config/hypr/bindings.lua", "~/.config/omarchy/extensions/omarchy-menu.jsonc", "~/.local/state/remind", "~/.claude/CLAUDE.md"],
  "root": false,
  "network": false,
  "installs": ["omarchy plugin clone omarchy.reminders"],
  "runs": ["autostart: remind restore at login", "systemd user timers, one per reminder"],
  "agent_config": true,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-31"}]
}
```
