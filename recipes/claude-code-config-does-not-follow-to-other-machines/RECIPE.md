# Claude Code settings and rules don't follow me to my other machines

## Problem

You teach Claude Code your preferences on one machine: global rules in
`~/.claude/CLAUDE.md`, settings in `~/.claude/settings.json`, a custom status
line script. On the next laptop, Claude starts from nothing again. The same
goes for shell functions and aliases in `~/.bashrc`, such as a wrapper around
the `claude` command.

Copying all of `~/.claude` across is wrong too. It holds login credentials,
prompt history, per-project memory, session transcripts, caches, and skills
that Omarchy or your account put there.

## Why it happens

Omarchy installs Claude Code through mise (`omarchy-mise-install claude` in
`/usr/share/omarchy/install/user/mise.sh`) and links its own skills into
`~/.claude/skills/`, but it does not manage the rest of `~/.claude`. That
directory and `~/.bashrc` live outside `~/.config`, so a dotfiles repo that
only mirrors `~/.config` misses them.

## Fix

This builds on the repo layout from
[My Omarchy customizations don't follow me to my other machines](../customizations-do-not-follow-to-other-machines/RECIPE.md):
an `install.sh` that copies the repo onto the machine and a `snapshot.sh` that
copies the live files back.

Track exactly three files from `~/.claude` in a `claude/` folder, plus
`~/.bashrc` as `bashrc`.

In `snapshot.sh`:

```bash
copy_if_present "$HOME/.bashrc" "$root/bashrc"

# Claude Code global rules and preferences. Credentials, history, per-project
# memory, sessions, caches, and account-synced skills stay on this machine.
copy_if_present "$HOME/.claude/CLAUDE.md" "$root/claude/CLAUDE.md"
copy_if_present "$HOME/.claude/settings.json" "$root/claude/settings.json"
copy_if_present "$HOME/.claude/statusline.sh" "$root/claude/statusline.sh"
```

In `install.sh`:

```bash
if [[ -f $root/bashrc ]]; then
  cp -a "$root/bashrc" "$HOME/.bashrc"
fi

if [[ -d $root/claude ]]; then
  mkdir -p "$HOME/.claude"
  cp -a "$root/claude/"* "$HOME/.claude/"
fi
```

Leave these out of git, and say so in the repo's rules file so a coding
agent editing the repo leaves them out too:

- `~/.claude/.credentials.json` (your login)
- `~/.claude/history.jsonl` (prompt history)
- `~/.claude/projects/` (per-project memory and transcripts)
- `~/.claude/sessions/`, caches, and other runtime folders
- `~/.claude/skills/` (Omarchy links its `omarchy` and `diagnose-crash`
  skills here, and account-synced skills land here too)
- `~/.claude.json` in your home folder (account and per-project state)

Track `~/.bashrc` even while it still matches the stock file
(`/usr/share/omarchy/default/bashrc`). That breaks the usual "only commit
files that differ from stock" rule on purpose: once it is in the repo, an
alias or function added on either machine travels with the next snapshot.

## Apply and check

On the machine that has the config:

```bash
./snapshot.sh
git status        # claude/ and bashrc should appear
```

Commit and push, then on the other machine:

```bash
git pull
./install.sh
source ~/.bashrc
```

Start a new `claude` session there. The status line and global rules should
match the first machine.

## Undo

Take the lines back out of `snapshot.sh` and `install.sh`, and remove the
copies from the repo with `git rm -r claude bashrc`. Commit and push.

On a machine where `install.sh` already ran, it copied over `~/.bashrc` and
the three `~/.claude` files without a backup. Edit them there by hand, or put
`~/.bashrc` back to stock with
`cp /usr/share/omarchy/default/bashrc ~/.bashrc`.

## Notes

- `install.sh` overwrites `~/.claude/settings.json`. Claude Code writes to
  that file itself when you change something with `/config` or `/effort`,
  so snapshot before you pull and install, or the change is lost.
- `settings.json` can pick up machine-specific or private values over time,
  such as an `autoMode.environment` block that names your repo and its
  absolute path. Read the diff before committing, especially if the repo is
  public.
- The recipes that use these files:
  [status line](../claude-status-line-does-not-show-project-or-git-state/RECIPE.md),
  [session names](../claude-sessions-look-alike-in-remote-control/RECIPE.md),
  [global rules](../prompt-typed-into-the-wrong-claude-session/RECIPE.md).

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.

## Recipe data

```json
{
  "id": "duff/claude-code-config-does-not-follow-to-other-machines",
  "title": "Claude Code settings and rules don't follow me to my other machines",
  "summary": "Track three files from ~/.claude, plus ~/.bashrc, in a dotfiles repo, and leave the rest of ~/.claude out.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2", "claude-code": "2.1.286"},
  "applies_to": "Every machine (most useful with two or more Omarchy installs).",
  "requires": [{"command": "claude"}],
  "touches": ["~/.bashrc", "~/.claude/CLAUDE.md", "~/.claude/settings.json", "~/.claude/statusline.sh"],
  "root": false,
  "network": true,
  "installs": [],
  "runs": ["~/.bashrc"],
  "agent_config": true,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
```
