# Claude Code keeps asking "How is Claude doing?"

**Tested on:** Omarchy 4.0.4, Hyprland 0.56.2 (Lua config), Claude Code 2.1.286
**Applies to:** every machine

## Problem

Now and then Claude Code shows a "How is Claude doing?" session quality
survey in the terminal. If you don't want to rate sessions, it is one more
thing to dismiss in the middle of work.

## Why it happens

The survey is part of Claude Code itself and appears at a sampled rate.
Omarchy does not change it. It is skipped automatically only when telemetry
is off (`DISABLE_TELEMETRY`, `DO_NOT_TRACK`, or
`CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`), and those switch off more than
the survey: the last one also disables Remote Control.

## Fix

Set `CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY` in the `env` block of
`~/.claude/settings.json`. Variables in `env` apply to every session, however
it was started, so you do not need to export it in `~/.bashrc`.

```json
{
  "env": {
    "CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY": "1"
  }
}
```

Merge it into your existing settings file rather than replacing the file.

## Apply and check

Start a new `claude` session; settings are read at start. Inside it, ask
Claude to run:

```bash
echo $CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY
```

It should print `1`. The survey should not appear again.

## Notes

- To see it less often instead of never, leave the variable out and set
  `"feedbackSurveyRate": 0.05` (a number from 0 to 1) in the same file.
  `0` turns it off as well.
- To undo, remove the line from `env`.
