---
{
  "id": "duff/agent-commit-messages-ignore-git-conventions",
  "title": "Coding agent writes long, unwrapped, or file-list commit messages",
  "summary": "Give coding agents one global rule for commit messages.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2", "grok-cli": "1.0"},
  "applies_to": "Every machine.",
  "requires": [],
  "touches": ["~/.grok/rules/git-commits.md", "~/.claude/CLAUDE.md"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": [],
  "agent_config": true,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
---

# Coding agent writes long, unwrapped, or file-list commit messages

## Problem

When you ask a coding agent to commit, the message comes out however the agent
feels like that day: an 80-character subject with a trailing period, a body
that is one long unwrapped line, or a bullet list of the files it touched. Two
agents, or two sessions of the same agent, write in two styles, so `git log
--oneline` stops reading like one history.

## Why it happens

Omarchy installs the agents (Claude Code, Codex, Grok and others, through
`omarchy-mise-install` in `/usr/share/omarchy/install/user/mise.sh`) and links
its own `omarchy` and `diagnose-crash` skills into each agent's skills folder.
It ships no rules about commit messages. Each agent falls back on its own
habits.

Grok loads every `*.md` file in `~/.grok/rules/` as a rule for every project,
whatever directory it was started in (see "Rules Directories" in
`~/.grok/docs/user-guide/12-project-rules.md`). That folder starts empty.

## Fix

Write the convention down once, in a global rule. This one follows
[Tim Pope's note on commit messages](https://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html).

`~/.grok/rules/git-commits.md`:

````markdown
# Git commits

When the user asks you to commit or push, and a commit is part of that work, write the message in [Tim Pope's style](https://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html):

- Imperative subject, capitalized, no trailing period, about 50 characters
- Blank line, then a body when the why is not obvious from the subject
- Wrap the body at 72 columns
- Explain why, not a file list

```
Capitalized, short (50 chars or less) summary

More detailed explanatory text, if necessary. Wrap it to about 72
characters or so.
```
````

The first line limits the rule to commits you asked for. Without it, a rule
that talks about commits can read as a nudge to commit on its own.

For Claude Code, the same text goes in `~/.claude/CLAUDE.md`, which Claude
Code reads in every project. In a single repo, put it in the repo's
`AGENTS.md` or `CLAUDE.md` so every agent working there sees it.

### Keep the rule on every machine

If you sync your config with a git repo (see
[My Omarchy customizations don't follow me to my other machines](../customizations-do-not-follow-to-other-machines/RECIPE.md)),
track only the rule files, not the rest of `~/.grok`, which holds your login
and session history.

In `install.sh`:

```bash
if [[ -d $root/grok/rules ]]; then
  mkdir -p "$HOME/.grok/rules"
  cp -a "$root/grok/rules/"*.md "$HOME/.grok/rules/"
fi
```

In `snapshot.sh`, name each rule you want to share, so a rule you add on one
machine for one machine stays there:

```bash
# Grok rules for every project on every machine. The rest of ~/.grok
# (auth, sessions, other rules) stays on this machine.
copy_if_present "$HOME/.grok/rules/git-commits.md" "$root/grok/rules/git-commits.md"
```

It also helps to put the same convention in the config repo's README, so
anyone reading the history knows what the messages are meant to look like.

## Apply and check

Rules load when a session starts. Start a new Grok session in any repo and
run:

```bash
grok inspect
```

`git-commits.md` should be listed as a global rule. Then make a change, ask
the agent to commit it, and check the result with `git log -1`.

## Undo

Delete `~/.grok/rules/git-commits.md` (and the lines in your sync scripts).
For Claude Code, remove the rule from `~/.claude/CLAUDE.md` (or from the
repo's `AGENTS.md` or `CLAUDE.md`).

## Notes

- To check older messages against the rule, `git log --format='%s' | awk
  'length > 50'` lists subjects over 50 characters.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.
