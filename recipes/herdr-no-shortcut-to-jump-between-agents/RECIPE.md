# Herdr has no shortcut to jump between agents

## Problem

With coding agents running in several Herdr workspaces, you mostly want to go
from one agent to the next. Omarchy's Herdr config only gives you keys for
tabs and workspaces, so reaching the next agent means finding which workspace
and tab it lives in, or clicking it in the agent panel.

## Why it happens

Herdr has `previous_agent` and `next_agent` actions, but they are unbound by
default. Omarchy's `~/.config/herdr/config.toml` template (from
`/usr/share/omarchy/config/herdr/config.toml`) does not bind them, and it puts
the Alt arrows on tabs and workspaces:

```toml
previous_tab = ["prefix+p", "alt+left"]
next_tab = ["prefix+n", "alt+right"]
move_tab_previous = "alt+shift+left"
move_tab_next = "alt+shift+right"
previous_workspace = ["prefix+shift+p", "alt+up"]
next_workspace = ["prefix+shift+n", "alt+down"]
```

## Fix

In `~/.config/herdr/config.toml`, under `[keys]`, give agents the plain
`Alt+Up`/`Alt+Down` and move workspaces to `Alt+Shift+Up`/`Alt+Shift+Down`,
which Omarchy leaves free:

```toml
[keys]
previous_workspace = ["prefix+shift+p", "alt+shift+up"]
next_workspace = ["prefix+shift+n", "alt+shift+down"]
# Agents get the plain Alt arrows. They are switched more often than workspaces.
previous_agent = "alt+up"
next_agent = "alt+down"
```

`Ctrl+Space`, `Shift+P`/`Shift+N` still step through workspaces.

## Apply and check

```bash
herdr server reload-config
```

or press `Ctrl+Space` then `q` inside Herdr. With agents in two workspaces,
`Alt+Down` should focus the next agent, even when it is in another
workspace.

## Undo

In `~/.config/herdr/config.toml`, delete the `previous_agent` and `next_agent`
lines and put the workspace keys back to Omarchy's:

```toml
previous_workspace = ["prefix+shift+p", "alt+up"]
next_workspace = ["prefix+shift+n", "alt+down"]
```

Then run `herdr server reload-config`.

## Notes

- The first version of this put agents on `Alt+Shift+Up`/`Down` and left
  workspaces on the plain arrows. Agents turned out to be switched far more
  often, so the shorter chord went to them.
- If the agent panel keeps reshuffling while you step through it, see
  [Herdr's agent list keeps reordering itself](../herdr-agent-list-keeps-reordering/RECIPE.md).

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.

## Recipe data

```json
{
  "id": "duff/herdr-no-shortcut-to-jump-between-agents",
  "title": "Herdr has no shortcut to jump between agents",
  "summary": "Put the previous and next agent on Alt+Up and Alt+Down, and workspaces on Alt+Shift.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2", "herdr": "0.8.2"},
  "applies_to": "Every machine.",
  "requires": [{"command": "herdr"}],
  "touches": ["~/.config/herdr/config.toml"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": [],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
```
