---
{
  "id": "duff/herdr-agent-list-keeps-reordering",
  "title": "Herdr's agent list keeps reordering itself",
  "summary": "Group Herdr's agent panel by workspace so its order stays put.",
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
---

# Herdr's agent list keeps reordering itself

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

## Undo

Set `agent_panel_sort` back to `"priority"` in `~/.config/herdr/config.toml`,
then run `herdr server reload-config`.

## Notes

- `"priority"` is useful if you want the agent that needs you most at the top
  and do not mind the movement. Pair the stable order with keys that step
  through agents (see
  [Herdr has no shortcut to jump between agents](../herdr-no-shortcut-to-jump-between-agents/RECIPE.md)).

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.
