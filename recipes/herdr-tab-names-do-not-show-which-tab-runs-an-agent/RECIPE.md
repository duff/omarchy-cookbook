# Herdr tab names don't show which tab is running an agent

## Problem

With several Claude Code sessions in one Herdr workspace, the tab bar does not
tell you which tab has a live agent and which one has a plain shell left over
after the agent exited.

## Why it happens

Omarchy's Herdr config sets `prompt_new_tab_name = false`, so new tabs get
generated names without asking, and nothing renames a tab when you start or
quit an agent in it.

Herdr exports `HERDR_TAB_ID` into every pane's environment, and
`herdr tab rename <tab-id> <name>` renames a tab over Herdr's socket API. A
shell function around the agent command can use both.

## Fix

Add a `claude` function to `~/.bashrc`, below the line that sources
`$OMARCHY_PATH/default/bash/rc`. While Claude runs, the tab is `claude-N`.
When it exits, the tab becomes plain `N`, so you can still tell the tabs
apart but see that the agent is gone. `N` is the lowest number that no other
tab in the Herdr workspace is using.

```bash
claude() {
  local arg
  # Subcommands and one-shot runs are not sessions. Leave the tab alone.
  case ${1:-} in
    agents|attach|auth|auto-mode|doctor|gateway|import|install|logs|mcp|plugin|project|remote-control|respawn|rm|setup-token|stop|ultrareview|update)
      command claude "$@"; return ;;
  esac
  for arg in "$@"; do
    case $arg in
      -p|--print|-h|--help|-v|--version)
        command claude "$@"; return ;;
    esac
  done

  # Outside Herdr there is no tab to rename.
  [[ -z ${HERDR_TAB_ID:-} ]] && { command claude "$@"; return; }

  # n is the lowest number no other tab in this workspace has, as N or
  # claude-N.
  local n=1 taken
  taken=$(herdr tab list --workspace "$HERDR_WORKSPACE_ID" 2>/dev/null |
    jq -r --arg me "$HERDR_TAB_ID" '.result.tabs[] | select(.tab_id != $me) | .label')
  while grep -qxE "(claude-)?$n" <<<"$taken"; do ((n++)); done

  # The tab is claude-N while Claude runs and plain N after it exits
  local status
  herdr tab rename "$HERDR_TAB_ID" "claude-$n" >/dev/null 2>&1
  command claude "$@"
  status=$?
  herdr tab rename "$HERDR_TAB_ID" "$n" >/dev/null 2>&1
  return $status
}
```

How it works:

- Herdr exports `HERDR_TAB_ID` and `HERDR_WORKSPACE_ID` into every pane.
  `herdr tab list` prints the workspace's tabs as JSON, and `jq` pulls out
  the labels of the other tabs.
- A number counts as taken whether its tab still runs Claude (`claude-2`) or
  has finished (`2`), so two tabs never share one. Starting Claude again in
  the same tab usually gets the same number back.
- `command claude` calls the real binary, not this function. The function
  returns Claude's exit status, so scripts that check it still work.

## Apply and check

```bash
source ~/.bashrc
```

In a Herdr tab, run `claude`. The tab should be renamed `claude-1` (or the
next free number). Quit Claude and the tab should read `1`. To see the names
from another pane:

```bash
herdr tab list
```

## Undo

Delete the `claude` function from `~/.bashrc` and open a new shell. Tabs it
already renamed keep their names until you rename them.

## Notes

- [Claude sessions can't be reached from my phone, or all look alike there](../claude-sessions-look-alike-in-remote-control/RECIPE.md)
  defines a `claude` function too, and the one defined last wins. If you use
  both, keep one function: put this one's `HERDR_TAB_ID` check and the two
  renames around that one's final `command claude` line, and use its `n`,
  which numbers sessions per git project. That is how the working config
  does it.
- The first version only renamed the tab to `claude-N` on start. After Claude
  exited, the tab kept saying `claude-N` over a plain shell, which is what the
  second rename fixes.
- The same pattern works for other agents: rename the function and the
  `claude-` prefix.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.

## Recipe data

```json
{
  "id": "duff/herdr-tab-names-do-not-show-which-tab-runs-an-agent",
  "title": "Herdr tab names don't show which tab is running an agent",
  "summary": "Rename the tab while the agent runs.",
  "version": 2,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2", "herdr": "0.8.2"},
  "applies_to": "Every machine.",
  "requires": [{"command": "herdr"}, {"command": "claude"}],
  "touches": ["~/.bashrc"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": ["~/.bashrc"],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
```
