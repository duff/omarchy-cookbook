---
{
  "id": "duff/herdr-closes-workspace-pane-or-tab-without-asking",
  "title": "Herdr closes a workspace, pane, or tab without asking",
  "summary": "Turn Herdr's close confirmation back on and unbind the pane and tab close keys.",
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

# Herdr closes a workspace, pane, or tab without asking

## Problem

In Herdr (the terminal multiplexer for coding agents that Omarchy ships), one
keypress can close a pane, a tab, or a whole workspace, along with any agent
running in it. There is no undo, and with Omarchy's config there is no
confirmation either. A mistyped chord after the `Ctrl+Space` prefix can end an
agent session you wanted to keep.

## Why it happens

Omarchy's Herdr config (`/usr/share/omarchy/config/herdr/config.toml`, copied
to `~/.config/herdr/config.toml`) is written to behave like Omarchy's tmux
config, and tmux never asked before killing a window or session:

```toml
[keys]
close_pane = ["prefix+x", "alt+esc"]
close_tab = "prefix+k"
close_workspace = "prefix+shift+k"

[ui]
# kill-window and kill-session never asked
confirm_close = false
```

Herdr's own default is `confirm_close = true`; Omarchy turns it off.

## Fix

Edit `~/.config/herdr/config.toml`.

Turn the confirmation back on. It covers `close_workspace` and the close
entries in Herdr's menu:

```toml
[ui]
# Ask before prefix+shift+k and the close menu.
confirm_close = true
```

Unbind the pane and tab close keys, and close those from Herdr's on-screen UI
instead:

```toml
[keys]
# Unset while learning. A closed pane cannot be undone. Close from the UI.
close_pane = ""

# Unset while learning. A closed tab cannot be undone. Close from the UI.
close_tab = ""
```

Unbinding `close_tab` matters for workspaces too. On Herdr 0.8.2,
`confirm_close` does not cover `close_tab`, and closing the last tab of a
workspace closes that workspace with no prompt.

## Apply and check

Reload the config in the running Herdr server:

```bash
herdr server reload-config
```

or press `Ctrl+Space` then `q` inside Herdr. Then press `Ctrl+Space`,
`Shift+K`: Herdr should ask before closing the workspace. `Ctrl+Space`, `x`
and `Ctrl+Space`, `k` should do nothing.

## Undo

To get the shortcuts back, restore Omarchy's lines:
`close_pane = ["prefix+x", "alt+esc"]` and `close_tab = "prefix+k"`. To stop
the confirmation too, set `confirm_close = false` again. Then run
`herdr server reload-config`.

## Notes

- `herdr config reset-keys` backs up `config.toml` and removes every custom
  keybinding, including these.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.
