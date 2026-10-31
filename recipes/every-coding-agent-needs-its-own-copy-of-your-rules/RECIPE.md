# Every coding agent needs its own copy of your rules

## Problem

You use more than one coding agent: Claude Code for one thing, Codex or Grok
or Gemini for another. Each reads your personal rules from a different file,
so every rule, such as how to write commit messages or when to push, has to
be written into each of them. Change one and forget the others, and the
agents drift apart: one pushes when it's done, another waits to be asked.

## Why it happens

Omarchy installs a whole set of agents
(`/usr/share/omarchy/install/user/mise.sh`: Claude Code, Codex, Crush,
Gemini, Copilot, OpenCode, Pi, Grok and others) but no rules for them. Each
agent looks for rules that apply in every project in its own place:

| Agent | File it reads in every project |
|---|---|
| Claude Code | `~/.claude/CLAUDE.md` |
| Codex | `~/.codex/AGENTS.md` |
| Gemini | `~/.gemini/GEMINI.md` |
| OpenCode | `~/.config/opencode/AGENTS.md` |
| Crush | `~/.config/crush/CRUSH.md` |
| Pi | `~/.pi/agent/AGENTS.md` |
| Grok | every `*.md` in `~/.grok/rules/` |

## Fix

Keep one file, `~/.config/agents/AGENTS.md`, and point every agent at it.

### 1. Write the rules once

Anything that should hold for every agent in every project goes here. For
example:

```markdown
# Rules for every agent

These apply to every coding agent I use (Claude, Grok, Codex, Gemini, and the
rest) in every project. A project's own AGENTS.md or CLAUDE.md wins where it
says otherwise.

## Commits

- When you finish a change I asked for, commit it and push it. Don't wait for
  me to say "commit" or "push". Never leave a commit unpushed.
- Stage only the files you changed for this request, by path. Never use
  `git add -A`, `git add .` or `git commit -a`: another session may be working
  in the same repo, and its changes aren't yours to commit.
- One logical change per commit.
- Write the message in the repo's existing style (check `git log`). Where
  there is none: a capitalized, imperative subject of about 50 characters
  with no trailing period, then a blank line and a body wrapped at 72 columns
  that says why, when the subject doesn't.
- Never add a Co-Authored-By trailer, a "Generated with" line, or any other AI
  attribution to commits or pull requests.
- Never force-push or rewrite pushed history unless I ask for that.
```

Say "every agent" in the rules themselves, not "Claude": each agent reads the
same words.

### 2. Point the other agents at it

Every agent except Claude Code reads its file as plain text, so a symbolic
link is enough:

```bash
for link in .codex/AGENTS.md .gemini/GEMINI.md .config/opencode/AGENTS.md \
  .config/crush/CRUSH.md .pi/agent/AGENTS.md .grok/rules/agents.md; do
  mkdir -p "$(dirname "$HOME/$link")"
  # Keep a file written there by hand rather than losing it.
  [[ -f $HOME/$link && ! -L $HOME/$link ]] && mv "$HOME/$link" "$HOME/$link.bak"
  ln -sfn ~/.config/agents/AGENTS.md "$HOME/$link"
done
```

Leave out the agents you don't use. Any rules a file held before end up next
to it as `.bak`; move the ones you want into `~/.config/agents/AGENTS.md`.

### 3. Import it into Claude Code

`~/.claude/CLAUDE.md` usually holds Claude-only rules too, so import the
shared file instead of linking over it. Claude Code reads a line that starts
with `@` and a path as "include this file here". Add to `~/.claude/CLAUDE.md`:

```markdown
My rules for every agent, including when to commit and push, are shared with
my other agents:

@~/.config/agents/AGENTS.md
```

Then delete any rules from `CLAUDE.md` that the shared file now covers, so
there's only one copy to keep up to date.

If you keep your config in a dotfiles repo, store the file there, and run the
loop from your install script, so a new machine gets the links too.

## Apply and check

Nothing needs reloading: each agent reads these files when a session starts.

- `ls -l ~/.codex/AGENTS.md ~/.gemini/GEMINI.md` should show links to
  `~/.config/agents/AGENTS.md`.
- Ask each agent, in a new session, "What are my rules for commits?" They
  should all give the same answer.

## Undo

```bash
for link in .codex/AGENTS.md .gemini/GEMINI.md .config/opencode/AGENTS.md \
  .config/crush/CRUSH.md .pi/agent/AGENTS.md .grok/rules/agents.md; do
  [[ -L $HOME/$link ]] && rm "$HOME/$link"
  [[ -f $HOME/$link.bak ]] && mv "$HOME/$link.bak" "$HOME/$link"
done
```

Remove the `@~/.config/agents/AGENTS.md` lines from `~/.claude/CLAUDE.md`,
copying back any rules you want Claude to keep. Then delete
`~/.config/agents/AGENTS.md`.

## Notes

- A project's own `AGENTS.md` or `CLAUDE.md` still loads on top of these, so
  per-project exceptions (such as a repo where pushing deploys) belong there.
- Agents not in the table, like Copilot, have their own places; add a link
  for each one you use.
- Related:
  [Claude Code commits but doesn't push, or asks whether to push](../claude-asks-whether-to-push-after-committing/RECIPE.md)
  and
  [Coding agent writes long, unwrapped, or file-list commit messages](../agent-commit-messages-ignore-git-conventions/RECIPE.md)
  each set one of these rules for one agent at a time. Their rules can move
  into the shared file.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-31.

## Recipe data

```json
{
  "id": "duff/every-coding-agent-needs-its-own-copy-of-your-rules",
  "title": "Every coding agent needs its own copy of your rules",
  "summary": "Keep one ~/.config/agents/AGENTS.md, linked in for Codex, Gemini, OpenCode, Crush, Pi and Grok, and imported into Claude Code's CLAUDE.md.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.5", "hyprland": "0.56.2"},
  "applies_to": "Machines where you use more than one coding agent.",
  "requires": [],
  "touches": ["~/.config/agents/AGENTS.md", "~/.claude/CLAUDE.md", "~/.codex/AGENTS.md", "~/.gemini/GEMINI.md", "~/.config/opencode/AGENTS.md", "~/.config/crush/CRUSH.md", "~/.pi/agent/AGENTS.md", "~/.grok/rules/agents.md"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": [],
  "agent_config": true,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-31"}]
}
```
