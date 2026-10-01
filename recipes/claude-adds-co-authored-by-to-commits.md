# Claude Code adds "Co-Authored-By: Claude" to my commits

**Tested on:** Omarchy 4.0.4, Hyprland 0.56.2 (Lua config), Claude Code 2.1.286
**Applies to:** every machine

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

## Notes

- `includeCoAuthoredBy` is the old name for this and is deprecated; use
  `attribution`.
- Turning attribution off is a choice about your own repos. Some projects ask
  contributors to mark AI-assisted changes; follow their rules there.
- To undo, remove the `attribution` block and the `CLAUDE.md` line.
