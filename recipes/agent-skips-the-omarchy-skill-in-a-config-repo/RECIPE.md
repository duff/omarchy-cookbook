# Coding agent skips the Omarchy skill when working in a dotfiles repo

## Problem

Ask an agent to change your bar or a keybinding from inside a git repo that
holds your config, and it can go ahead without loading Omarchy's skill. It
then works like a generic Linux helper: it may write
Hyprland settings in the pre-Lua syntax, copy a whole stock file instead of
overriding one line, or edit the packaged defaults under `/usr/share/omarchy/`,
which the next `omarchy update` replaces.

Asked to edit `~/.config/hypr/bindings.lua` directly, the same agent loads the
skill first.

Anyone set up with [omarchy-kitchen](https://github.com/duff/omarchy-kitchen)
already has this: the private config repo it creates tells agents to load the
Omarchy skill for every task. This recipe is for people keeping their own
config repo.

## Why it happens

Omarchy ships an `omarchy` skill (`/usr/share/omarchy/default/agents/skills/omarchy/`)
and links it into `~/.claude/skills/`, `~/.codex/skills/`, `~/.agents/skills/`
and `~/.pi/agent/skills/`. The skill holds the rules that matter: never modify
`/usr/share/omarchy/`, how the Lua config layers on top of the defaults, and
topic guides for Hyprland, the shell, themes and hooks.

Agents load a skill only when the request matches its description. The
Omarchy skill's description keys on paths like `~/.config/hypr/` and words like
"Hyprland" or "keybindings". In a config repo the files are at
`config/hypr/bindings.lua`, and requests are often phrased as symptoms ("the
reminder disappears too fast") that say neither "Omarchy" nor a `~/.config`
path. So the skill never loads.

## Fix

Put a short instruction file at the root of the config repo that says every
task there is an Omarchy customization.

`~/Work/your-config-repo/CLAUDE.md`:

```markdown
# your-config-repo

Every task in this repo is an Omarchy customization. Load the `omarchy` skill before starting work, even when the request doesn't say "Omarchy". Follow `RULES.md` to decide where each change goes.
```

Claude Code reads `CLAUDE.md` from the directory it starts in. Grok reads it
too (it accepts `CLAUDE.md` and `AGENTS.md` as project rule files). For Codex
and other agents that read `AGENTS.md`, put the same text there, or make one a
symlink to the other.

The last sentence points at a second file with the repo's own rules. If you
sync config between machines, that is where you say which changes go in the
shared layer, which are per host, and which stay out of git. See
[My Omarchy customizations don't follow me to my other machines](../customizations-do-not-follow-to-other-machines/RECIPE.md).
Keep `CLAUDE.md` itself short: it loads into every session, and the skill and
`RULES.md` hold the detail.

## Apply and check

Start a new session in the repo and ask for a change without saying
"Omarchy", for example "make the bar clock 12-hour". The agent should load the
`omarchy` skill before it reads or edits anything. In Claude Code you can see
the skill load in the transcript.

To confirm the skill is installed for your agent at all:

```bash
ls -l ~/.claude/skills/omarchy ~/.codex/skills/omarchy ~/.agents/skills/omarchy
```

Each should be a symlink into `/usr/share/omarchy/default/agents/skills/omarchy`.

## Undo

Delete `CLAUDE.md` from the repo root, and `AGENTS.md` if you added one. If the
file holds other rules too, remove only the paragraph that says every task is
an Omarchy customization. Agents then load the skill only when a request
matches its description.

## Notes

- The file only applies to sessions started inside the repo. A session started
  in `~/.config` or `~` still relies on the skill's own triggers.
- Do not copy the skill into the repo. The linked copy updates with Omarchy;
  a copy would go stale.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.

## Recipe data

```json
{
  "id": "duff/agent-skips-the-omarchy-skill-in-a-config-repo",
  "title": "Coding agent skips the Omarchy skill when working in a dotfiles repo",
  "summary": "Add a repo CLAUDE.md that tells agents to always load the Omarchy skill.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2"},
  "applies_to": "Every machine.",
  "requires": [],
  "touches": ["~/Work/your-config-repo/CLAUDE.md", "~/Work/your-config-repo/AGENTS.md"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": [],
  "agent_config": true,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
```
