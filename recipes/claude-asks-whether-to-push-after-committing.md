# Claude Code commits but doesn't push, or asks whether to push

**Tested on:** Omarchy 4.0.4, Hyprland 0.56.2 (Lua config), Claude Code 2.1.286
**Applies to:** every machine

## Problem

You tell Claude Code to "commit", and it commits, then either stops or asks
"Want me to push?" If you work on more than one machine, an unpushed commit
is invisible to the other one, and you find out only when the next pull
conflicts. Saying "commit and push" every time is easy to forget.

## Why it happens

Claude Code treats a commit and a push as separate actions and, by default,
pushes only when asked. Omarchy does not change that. Claude does follow
standing rules from `~/.claude/CLAUDE.md`, which it loads into every session
in every project.

## Fix

Add a line to `~/.claude/CLAUDE.md` (create the file if it does not exist):

```markdown
# Global preferences

- "Commit" and "push" mean the same thing: commit the pending changes and push them. Never leave a commit unpushed, and don't ask whether to push after committing. This holds in every project.
```

The rule names both words so "push" alone also commits first, says what not
to do (leave a commit unpushed, ask), and says it holds everywhere, so a
project's own `CLAUDE.md` is not read as overriding it.

## Apply and check

Start a new `claude` session (the file is read at start) in a repo with a
remote, make a small change, and say "commit". Claude should commit and push
without asking. Check with:

```bash
git status -sb
```

The first line should not say `[ahead 1]`.

## Notes

- This rule only covers what happens once you ask for a commit. It does not
  make Claude commit on its own when a task is done; if you want that, write
  a separate rule.
- A project that should never push (for example, one with a review step) can
  say so in its own `CLAUDE.md`; mention it explicitly, since this rule says
  "every project".
- If your config repo copies `~/.claude/CLAUDE.md` between machines, see
  [Claude Code settings and rules don't follow me to my other machines](claude-code-config-does-not-follow-to-other-machines.md).
