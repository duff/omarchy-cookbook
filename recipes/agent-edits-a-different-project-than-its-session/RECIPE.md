# Grok edits another project when a prompt goes to the wrong session

## Problem

You keep one Grok session open per project under `~/Work`, each in its own
terminal or Herdr tab. Sooner or later you type a prompt meant for one project
into the session for another. Grok does not push back. It finds the other
repo next door in `~/Work`, edits it, maybe builds or commits there, and the
session you were looking at now holds work for a project it was never
started in.

For Claude Code, see
[A prompt typed into the wrong Claude session changes the wrong project](../prompt-typed-into-the-wrong-claude-session/RECIPE.md).

## Why it happens

Omarchy creates `~/Work` as the place for projects (see
`/usr/share/omarchy/install/user/mise-work.sh`), so every repo sits next to
every other one. Grok can read and write outside the directory it started
in, and nothing in the stock setup tells it a session belongs to one
project.

## Fix

Add a global rule that ties each session to the repo it was started in, and
tells Grok to stop and ask when a prompt is about some other project. Every
`*.md` file in `~/.grok/rules/` loads in every project.

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

Replace the list with your own projects. The list helps Grok recognize a
project by the name you use when you talk about it. One line per project with
a few words about what it is ("the web app") is enough. The "any other git
repository" line covers projects you have not listed.

The config repo's entry spells out that its session may also edit the live
files under `~/.config`. Without that line Grok may treat `~/.config` as a
different project and refuse ordinary work.

To keep the rule on every machine, track it with your config the same way as
any other Grok rule. See
[Coding agent writes long, unwrapped, or file-list commit messages](../agent-commit-messages-ignore-git-conventions/RECIPE.md)
for the `install.sh` and `snapshot.sh` lines.

## Apply and check

Start a new Grok session (rules load at startup). `grok inspect` should list
`session-project.md` as a global rule.

Then, in one project's session, ask for a change to another project by name.
Grok should answer with the question and stop, without opening the other
repo.

## Undo

Delete `~/.grok/rules/session-project.md`.

## Notes

- The rule only covers prompts that are clearly about another project. A
  shared library or a sibling repo you do mean to touch from this session
  needs to be named in the prompt ("in this session, also update ...").

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.

## Recipe data

```json
{
  "id": "duff/agent-edits-a-different-project-than-its-session",
  "title": "Grok edits another project when a prompt goes to the wrong session",
  "summary": "Add a global Grok rule that ties each session to the repo it was started in.",
  "version": 2,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2", "grok-cli": "1.0"},
  "applies_to": "Machines with Grok.",
  "requires": [{"command": "grok"}],
  "touches": ["~/.grok/rules/session-project.md"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": [],
  "agent_config": true,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
```
