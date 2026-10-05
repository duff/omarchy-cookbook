---
{
  "id": "duff/claude-sessions-look-alike-in-remote-control",
  "title": "Claude sessions can't be reached from my phone, or all look alike there",
  "summary": "Turn on Remote Control at startup and name each session after its project.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2", "claude-code": "2.1.286", "herdr": "0.8.2"},
  "applies_to": "Every machine.",
  "requires": [{"command": "claude"}],
  "touches": ["~/.claude/settings.json", "~/.bashrc"],
  "root": false,
  "network": true,
  "installs": [],
  "runs": ["a claude shell function in ~/.bashrc", "Remote Control, connected at the start of every Claude Code session"],
  "agent_config": true,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
---

# Claude sessions can't be reached from my phone, or all look alike there

## Problem

Claude Code's Remote Control lets you continue a local session from
claude.ai/code or the Claude phone app. Two things get in the way:

- It is off unless you start each session with `claude --remote-control` or
  run `/remote-control` inside it. Sessions you forgot to start that way are
  not reachable when you walk away.
- Sessions get auto-generated names like `myhost-graceful-unicorn`, or a title
  taken from your last message. With three sessions for the same project open,
  the list on the phone does not tell you which is which.

## Why it happens

Remote Control is opt-in per session. The remote title comes, in order, from
the name passed to `--name`, `--remote-control`, or `/remote-control`; then
`/rename`; then the conversation; then a generated `<hostname>-<words>` name.
Omarchy installs Claude Code through mise and only adds a `cx` alias
(`claude --permission-mode auto`); it does not name sessions.

## Fix

### Turn on Remote Control for every session

In `~/.claude/settings.json`:

```json
{
  "remoteControlAtStartup": true,
  "agentPushNotifEnabled": true
}
```

`remoteControlAtStartup` connects every interactive session at start, the
same as **Enable Remote Control for all sessions** in `/config`. It only
counts from user or managed settings; a `true` in a project's
`.claude/settings.json` is ignored. `agentPushNotifEnabled` lets Claude send a
push notification to your phone when it decides to (a long task finished, or
it needs a decision).

### Name each session after its project plus a number

Add a `claude` function to `~/.bashrc`, below the line that sources
`$OMARCHY_PATH/default/bash/rc`. The first session in a repo called
`my-dotfiles` is named `my-dotfiles-1`, a second one opened while the first is
running is `my-dotfiles-2`, and so on. When `my-dotfiles-1` exits, the next
new session takes `1` again.

```bash
# Name each Claude session after its project plus a number. The number is the
# lowest one no running session of that project already has. Subcommands and
# --print runs pass through untouched.
claude() {
  local arg
  case ${1:-} in
    agents|attach|auth|auto-mode|doctor|gateway|import|install|logs|mcp|plugin|project|remote-control|respawn|rm|setup-token|stop|ultrareview|update)
      command claude "$@"; return ;;
  esac
  for arg in "$@"; do
    case $arg in
      -p|--print|--remote-control|--remote-control=*|-h|--help|-v|--version)
        command claude "$@"; return ;;
    esac
  done

  local root project pid n=1 taken=" "
  root=$(git rev-parse --show-toplevel 2>/dev/null) || root=$PWD
  project=$(basename "$root")
  for pid in $(pgrep -x claude); do
    arg=$(tr '\0' ' ' <"/proc/$pid/cmdline" 2>/dev/null)
    [[ $arg =~ --remote-control\ $project-([0-9]+)\  ]] && taken+="${BASH_REMATCH[1]} "
  done
  while [[ $taken == *" $n "* ]]; do ((n++)); done

  command claude --remote-control "$project-$n" "$@"
}
```

How it works:

- Subcommands (`claude mcp`, `claude update`, ...) and one-shot or info runs
  (`-p`, `--help`, `--version`) are not sessions, so they go straight to the
  real binary. So does a run where you pass your own `--remote-control` name.
- The project is the git repo's top-level folder name, or the current folder
  outside a repo.
- To find taken numbers, it reads the command line of every running `claude`
  process from `/proc/<pid>/cmdline` (NUL-separated, so `tr` turns the NULs
  into spaces) and collects the `N` from `--remote-control <project>-N`. The
  trailing space in the pattern stops `my-dotfiles-1` from matching
  `my-dotfiles-12`.
- `command claude` runs the real binary, not this function. Your other
  arguments are passed through after the name.

Because bash expands aliases before looking up functions, Omarchy's `cx` alias
goes through this function too.

If you use Herdr, the same function can rename the Herdr tab to `claude-N`
while the session runs, using the same `n`. See
[Herdr tab names don't show which tab is running an agent](../herdr-tab-names-do-not-show-which-tab-runs-an-agent/RECIPE.md)
for that part; put its rename lines around the final `command claude` line.

## Apply and check

```bash
source ~/.bashrc
cd ~/some-repo
claude
```

In a second terminal in the same repo, start `claude` again, then from a third:

```bash
pgrep -ax claude
```

You should see `claude --remote-control some-repo-1` and
`claude --remote-control some-repo-2`. Open claude.ai/code or the **Code** tab
in the Claude app: both sessions are listed under those names.

## Undo

Delete the `claude` function from `~/.bashrc`, and set
`remoteControlAtStartup` to `false` in `~/.claude/settings.json`. Set
`agentPushNotifEnabled` to `false` too if you don't want push notifications.

## Notes

- Remote Control needs a claude.ai subscription login. Setting
  `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` also disables it.
- Sessions that are not started from an interactive bash shell skip the
  function. Omarchy's `omarchy-agent` (the agent keybinding and the crash
  notification) runs `claude` from a script, for example. With
  `remoteControlAtStartup` on, those sessions are still reachable, just under
  a generated name.
- The project name is put into a regex unquoted, so a folder name with regex
  characters (such as `.`) can match a little loosely. Quote it if that
  matters for your folder names.
- The [status line recipe](../claude-status-line-does-not-show-project-or-git-state/RECIPE.md)
  uses the same project rule, so the status line and the remote name agree.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.
