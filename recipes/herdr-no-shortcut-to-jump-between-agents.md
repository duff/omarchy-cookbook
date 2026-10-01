# Herdr has no shortcut to jump between agents

**Tested on:** Omarchy 4.0.4, Hyprland 0.56.2 (Lua config), Herdr 0.8.2
**Applies to:** every machine

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

## Notes

- The first version of this put agents on `Alt+Shift+Up`/`Down` and left
  workspaces on the plain arrows. Agents turned out to be switched far more
  often, so the shorter chord went to them.
- If the agent panel keeps reshuffling while you step through it, see
  [herdr-agent-list-keeps-reordering.md](herdr-agent-list-keeps-reordering.md).
