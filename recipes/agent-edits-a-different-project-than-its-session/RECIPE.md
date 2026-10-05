# Coding agent edits another project when a prompt goes to the wrong session

## Problem

You keep one agent session open per project under `~/Work`, each in its own
terminal or Herdr tab. Sooner or later you type a prompt meant for one project
into the session for another. The agent does not push back. It finds the
other repo next door in `~/Work`, edits it, maybe builds or commits there, and
the session you were looking at now holds work for a project it was never
started in.

## Why it happens

Omarchy creates `~/Work` as the place for projects (see
`/usr/share/omarchy/install/user/mise-work.sh`), so every repo sits next to
every other one. Agents can read and write outside the directory they started
in, and nothing in the stock setup tells them a session belongs to one
project.

## Fix

Add a global rule that ties each session to the repo it was started in, and
tells the agent to stop and ask when a prompt is about some other project.

For Grok, every `*.md` file in `~/.grok/rules/` loads in every project.

`~/.grok/rules/session-project.md`:

```markdown
# Stay in this session's project

This session belongs to the git repository of the directory where Grok was started. That repository is the only project this session edits.

These projects are separate. A request about one of them belongs in a Grok session started in that directory:

- `your-config-repo` is the Omarchy overlay. Its session may edit this repo and the live files `install.sh` copies into place.
- `your-app` is the web app.
- `another-project`

Any other git repository is a separate project too.

If the request is about a different project than this session, do not read it in order to change it, and do not edit, build, install, or commit there. Reply first with this sentence, naming this session's directory and the other project: Are you in the right Grok session? Then stop.
```

Replace the list with your own projects. The list helps the agent recognize a
project by the name you use when you talk about it. One line per project with
a few words about what it is ("the web app") is enough. The "any other
git repository" line covers projects you have not listed.

The config repo's entry spells out that its session may also edit the live
files under `~/.config`. Without that line the agent may treat `~/.config` as
a different project and refuse ordinary work.

For Claude Code, the same idea in one bullet of `~/.claude/CLAUDE.md`:

```markdown
- I run separate Claude sessions for different projects under `~/Work` (your-config-repo, your-app, another-project, etc.) and sometimes type a prompt into the wrong one. If a prompt clearly refers to a different project than the current working directory, do not act on it. Stop and ask: "Are you sure you're in the right Claude? This sounds like it's for <project>, but this session is in <current project>."
```

"Clearly" matters: a prompt that only mentions another project in passing
should still be answered.

To keep the rule on every machine, track it with your config the same way as
any other agent rule. See
[Coding agent writes long, unwrapped, or file-list commit messages](../agent-commit-messages-ignore-git-conventions/RECIPE.md)
for the `install.sh` and `snapshot.sh` lines.

## Apply and check

Start a new session (rules load at startup). For Grok, `grok inspect` should
list `session-project.md` as a global rule.

Then, in one project's session, ask for a change to another project by name.
The agent should answer with the question and stop, without opening the other
repo.

## Undo

Delete `~/.grok/rules/session-project.md` or the bullet in
`~/.claude/CLAUDE.md`.

## Notes

- The rule only covers prompts that are clearly about another project. A
  shared library or a sibling repo you do mean to touch from this session
  needs to be named in the prompt ("in this session, also update ...").
- [A prompt typed into the wrong Claude session changes the wrong project](../prompt-typed-into-the-wrong-claude-session/RECIPE.md)
  covers the same rule for Claude Code alone, with the exact wording to use.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.

## Recipe data

```json
{
  "id": "duff/agent-edits-a-different-project-than-its-session",
  "title": "Coding agent edits another project when a prompt goes to the wrong session",
  "summary": "Add a global agent rule that ties each session to the repo it was started in.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2", "grok-cli": "1.0"},
  "applies_to": "Every machine.",
  "requires": [],
  "touches": ["~/.grok/rules/session-project.md", "~/.claude/CLAUDE.md"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": [],
  "agent_config": true,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
```
