---
{
  "id": "duff/claude-adds-co-authored-by-to-commits",
  "title": "Claude Code adds \"Co-Authored-By: Claude\" to my commits",
  "summary": "Turn off Claude Code's commit and pull request attribution.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2", "claude-code": "2.1.286"},
  "applies_to": "Every machine.",
  "requires": [{"command": "claude"}],
  "touches": ["~/.claude/settings.json", "~/.claude/CLAUDE.md"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": [],
  "agent_config": true,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
---

# Claude Code adds "Co-Authored-By: Claude" to my commits

## Problem

Commits made by Claude Code end with a `Co-Authored-By: Claude ...` trailer,
pull request descriptions get a "Generated with Claude Code" line, and
commits from Remote Control or cloud sessions can include a claude.ai session
link. You may want your history to read like your own.

## Why it happens

Claude Code adds attribution by default. The `attribution` setting controls
it: `attribution.commit` is the commit trailer, `attribution.pr` the pull
request line, and `attribution.sessionUrl` the session link. Omarchy does not
set any of them.

## Fix

Turn all three off in `~/.claude/settings.json`:

```json
{
  "attribution": {
    "commit": "",
    "pr": "",
    "sessionUrl": false
  }
}
```

An empty string removes the commit trailer and the PR line. `false` also
works for those two. `sessionUrl: false` leaves out the session link.

The setting covers the attribution Claude Code adds itself. As a second
guard, in case Claude writes a credit line into the message text on its own,
the working config also has a rule in `~/.claude/CLAUDE.md`:

```markdown
- Never add a `Co-Authored-By: Claude` trailer, a "Generated with Claude Code" line, or any other Claude attribution to commit messages or pull request descriptions, in any project.
```

## Apply and check

Start a new `claude` session, have it make a commit, then:

```bash
git log -1 --format=%B
```

The message should end with your text and no `Co-Authored-By` line.

## Undo

Remove the `attribution` block from `~/.claude/settings.json` and the line
from `~/.claude/CLAUDE.md`.

## Notes

- `includeCoAuthoredBy` is the old name for this and is deprecated; use
  `attribution`.
- Turning attribution off is a choice about your own repos. Some projects ask
  contributors to mark AI-assisted changes; follow their rules there.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.
