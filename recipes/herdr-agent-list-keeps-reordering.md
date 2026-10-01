# Herdr's agent list keeps reordering itself

**Tested on:** Omarchy 4.0.4, Hyprland 0.56.2 (Lua config), Herdr 0.8.2
**Applies to:** every machine

## Problem

Herdr's agent panel lists every coding agent running in your session. With
several agents working, the list keeps shuffling: an agent jumps to the top
when it needs attention and drops back when it is done. You reach for the
third entry and it is a different agent than a moment ago.

## Why it happens

The panel has two orders, set by `agent_panel_sort` in
`~/.config/herdr/config.toml`:

- `"priority"`: an attention queue. Agents that are blocked or finished move
  up, so the order changes whenever an agent changes state.
- `"spaces"`: grouped by workspace, in a stable order. (`"workspaces"` is
  accepted as an alias.)

Herdr's built-in default is `"spaces"`, and Omarchy's template does not set it.
The config this recipe comes from had `agent_panel_sort = "priority"` at the
end of the file, which produced the reshuffling.

## Fix

In `~/.config/herdr/config.toml`, under `[ui]`:

```toml
[ui]
agent_panel_sort = "spaces"
```

Each agent then stays under its workspace and keeps its place as its state
changes.

## Apply and check

```bash
herdr server reload-config
```

or press `Ctrl+Space` then `q` inside Herdr. Start two agents in different
workspaces and let one finish: the panel order should not change.

## Notes

- `"priority"` is useful if you want the agent that needs you most at the top
  and do not mind the movement. Pair the stable order with keys that step
  through agents (see
  [herdr-no-shortcut-to-jump-between-agents.md](herdr-no-shortcut-to-jump-between-agents.md)).
