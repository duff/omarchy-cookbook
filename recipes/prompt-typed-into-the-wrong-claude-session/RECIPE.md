# A prompt typed into the wrong Claude session changes the wrong project

## Problem

You keep one Claude Code session open per project under `~/Work` (say,
`my-dotfiles`, `web-app`, and `notes`), each in its own terminal or tab. You
type a request meant for `web-app` into the `my-dotfiles` session. Claude
tries to help anyway: it reads the other repo, edits files there, or bends
the request into a change in the current project.

It happens partway through a task too. You ask the config repo's session to
fix something, and the fix turns out to live in another repo, or in a file
under `~/.config` that the repo doesn't track. Claude edits it there without
saying so.

For Grok, see
[Grok edits another project when a prompt goes to the wrong session](../agent-edits-a-different-project-than-its-session/RECIPE.md).

## Why it happens

Claude Code starts in the folder you launched it from but is not limited to
it. Nothing tells it that your projects belong to separate sessions, so a
request about another project looks like a normal task.

## Fix

Add a rule to `~/.claude/CLAUDE.md`, which Claude loads in every session in
every project:

```markdown
# Global preferences

- I run separate Claude sessions for different projects under `~/Work` (my-dotfiles, web-app, notes, etc.) and sometimes type a prompt into the wrong one. If a prompt clearly refers to a different project than the current working directory, do not act on it. Stop and ask: "Are you sure you're in the right Claude? This sounds like it's for <project>, but this session is in <current project>."
- The check also applies mid-task: if the change turns out to belong outside the current project (system config under `~/.config`, another repo under `~/Work`, dotfiles), stop before editing and ask the same question, even if the prompt didn't name a project.
```

List a few of your real project folder names in the parentheses, so Claude
has examples of what counts as a different project.

The rule says "clearly refers to", so a request that only mentions another
project in passing still runs. Giving the exact question to ask makes the
reply short and easy to spot.

The second line covers the case the first can't see: a prompt that reads as
this project's, but whose fix lands somewhere else. Claude only learns that
once it has looked, so the rule asks it to stop before the first edit there.
If your config repo's session is meant to edit the live files under
`~/.config`, add that to your project's own `CLAUDE.md`, so the check
doesn't stop ordinary work there.

## Apply and check

Start a new `claude` session in one project and ask for a change that plainly
belongs to another, by name. Claude should reply with the question and do
nothing else. Then move to the right session and paste the prompt there.

For the second line, ask a session for a change whose fix you know lives in
another repo, without naming that repo. Claude should look, then stop and
ask before editing it.

## Undo

Delete the two lines from `~/.claude/CLAUDE.md`.

## Notes

- It helps to see which project a session is in before you type. The
  [status line recipe](../claude-status-line-does-not-show-project-or-git-state/RECIPE.md)
  shows the project name under the prompt, and
  [naming sessions after their project](../claude-sessions-look-alike-in-remote-control/RECIPE.md)
  does the same in Remote Control and Herdr.
- When you really do want one session to touch another repo, say so plainly
  in the prompt.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.

## Recipe data

```json
{
  "id": "duff/prompt-typed-into-the-wrong-claude-session",
  "title": "A prompt typed into the wrong Claude session changes the wrong project",
  "summary": "Have Claude stop and ask when a prompt is meant for another project.",
  "version": 2,
  "tested_on": {"omarchy": "4.0.5", "hyprland": "0.56.2", "claude-code": "2.1.303"},
  "applies_to": "Every machine.",
  "requires": [{"command": "claude"}],
  "touches": ["~/.claude/CLAUDE.md"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": [],
  "agent_config": true,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
```
