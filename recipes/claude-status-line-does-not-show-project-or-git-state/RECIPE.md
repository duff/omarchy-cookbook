# Claude Code's status line doesn't show the project or whether git is clean

## Problem

With several Claude Code sessions open in different terminals or tabs, it is
hard to tell at a glance which project a session belongs to, and whether it
has left uncommitted changes behind. You end up running `git status` by hand
before closing a session.

## Why it happens

Claude Code shows no custom status line until you configure one. When you do,
it runs your command and pipes it a JSON object on stdin with the session
data: `model.id`, `model.display_name`, `workspace.current_dir`,
`effort.level`, and more. Whatever the command prints becomes the status
line. Omarchy does not set one up.

## Fix

Point Claude Code at a script in `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline.sh"
  }
}
```

Then create `~/.claude/statusline.sh`. It prints the model, reasoning effort,
project name, and `git ✓` (clean) or `git ✗` (anything changed or
untracked), for example:

```
Opus 5.5 · effort: medium · my-dotfiles · git ✗
```

```bash
#!/usr/bin/env bash
# Claude Code status line: model name + reasoning effort level + git clean/dirty.
# Effort is read live from ~/.claude/settings.json (modelSettings.<model>.effortLevel)
# so it reflects changes made via /effort without needing a new session.

input="$(cat)"
settings_file="$HOME/.claude/settings.json"

if command -v jq >/dev/null 2>&1; then
  model_id=$(echo "$input" | jq -r '.model.id // empty')
  model_name=$(echo "$input" | jq -r '.model.display_name // empty')
  cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')

  # Prefer the live effort level Claude Code already resolved for this turn.
  effort=$(echo "$input" | jq -r '.effort.level // empty')

  # Fall back to reading it straight from settings.json (updates immediately
  # after /effort, without waiting for a new statusLine JSON payload to
  # include it).
  if [ -z "$effort" ] && [ -n "$model_id" ] && [ -f "$settings_file" ]; then
    effort=$(jq -r --arg m "$model_id" '.modelSettings[$m].effortLevel // empty' "$settings_file" 2>/dev/null)
  fi
else
  # No jq: parse the same fields with python3. Fields are joined with the
  # unit separator so an empty one doesn't shift the rest.
  IFS=$'\x1f' read -r model_id model_name cwd effort < <(
    STATUSLINE_INPUT="$input" python3 - "$settings_file" <<'PY'
import json, os, sys

data = json.loads(os.environ.get("STATUSLINE_INPUT") or "{}")
model_id = (data.get("model") or {}).get("id", "")
model_name = (data.get("model") or {}).get("display_name", "")
cwd = (data.get("workspace") or {}).get("current_dir") or data.get("cwd", "")
effort = (data.get("effort") or {}).get("level", "")

if not effort:
    try:
        with open(sys.argv[1]) as f:
            settings = json.load(f)
        effort = (settings.get("modelSettings", {}).get(model_id, {}) or {}).get("effortLevel", "")
    except Exception:
        pass

print("\x1f".join([model_id, model_name, cwd, effort]))
PY
  )
fi

if [ -z "$effort" ]; then
  # Default effort for Opus 5.5 when unset; adjust if Anthropic changes defaults.
  effort="medium"
fi

line="$model_name · effort: $effort"

# Project: the git repo's top-level folder name, or the current folder name
# outside a repo.
if [ -n "$cwd" ]; then
  root=$(git -C "$cwd" --no-optional-locks rev-parse --show-toplevel 2>/dev/null) || root=$cwd
  line+=" · ${root##*/}"
fi

# Git: ✓ when the working tree is clean, ✗ when anything is changed or
# untracked. Skipped outside a git repo.
# --no-optional-locks keeps this from fighting with git commands Claude runs.
if [ -n "$cwd" ] && status=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null); then
  if [ -n "$status" ]; then line+=" · git ✗"; else line+=" · git ✓"; fi
fi

printf '%s' "$line"
```

Lines worth explaining:

- The project is the repo's top-level folder, not the current folder, so a
  session that has `cd`'d into a subfolder still shows the project name.
  Outside a repo it falls back to the current folder name.
- `git status --porcelain` prints nothing when the tree is clean, so an empty
  result means `✓`. Untracked files count as dirty.
- `--no-optional-locks` stops this read-only `git status` from taking
  `.git/index.lock` to refresh the index. Without it, a status line refresh
  can collide with a `git commit` Claude is running at the same moment.
- `jq` is preferred. Omarchy ships it, but the python3 branch keeps the script
  working on a machine without it.

## Apply and check

Test the script with fake input before starting Claude:

```bash
cd ~/some-repo
echo '{"model":{"display_name":"Opus"},"workspace":{"current_dir":"'"$PWD"'"},"effort":{"level":"high"}}' \
  | bash ~/.claude/statusline.sh
```

It should print something like `Opus · effort: high · some-repo · git ✓`.
Touch a new file in the repo and run it again: the end should change to
`git ✗`. Then start `claude`; the line appears under the prompt and updates
after each reply.

## Undo

Remove the `statusLine` block from `~/.claude/settings.json` and delete
`~/.claude/statusline.sh`. Claude Code goes back to no custom status line.

## Notes

- The status line re-runs when a new assistant message arrives, not on a
  timer, so a change you make in another terminal shows up after Claude's
  next reply. Add `"refreshInterval": 5` to the `statusLine` object if you
  want it to re-check every few seconds.
- The first version marked a dirty tree with `●`. It was too easy to miss next
  to `✓`; `✗` reads as "not clean" at a glance.
- If you name sessions after their project, as in
  [Claude sessions look alike in Remote Control](../claude-sessions-look-alike-in-remote-control/RECIPE.md),
  use the same rule (repo top-level folder, else current folder) in both
  places so the names match.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.

## Recipe data

```json
{
  "id": "duff/claude-status-line-does-not-show-project-or-git-state",
  "title": "Claude Code's status line doesn't show the project or whether git is clean",
  "summary": "Show the model, effort, project, and a git check or cross in Claude Code's status line.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2", "claude-code": "2.1.286"},
  "applies_to": "Every machine.",
  "requires": [{"command": "claude"}],
  "touches": ["~/.claude/settings.json", "~/.claude/statusline.sh"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": ["Claude Code status line command, ~/.claude/statusline.sh, after each reply"],
  "agent_config": true,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
```
