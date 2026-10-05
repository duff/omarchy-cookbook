---
{
  "id": "duff/git-push-over-https-fails-after-syncing-git-config",
  "title": "`git push` over HTTPS fails after syncing ~/.config/git/config",
  "summary": "Commit a credential helper that calls gh by name, and keep the sync script from dropping it.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2", "gh": "2.102"},
  "applies_to": "Every machine (most likely with two or more Omarchy installs).",
  "requires": [{"command": "gh"}],
  "touches": ["~/.config/git/config", "~/Work/your-config-repo/snapshot.sh"],
  "root": false,
  "network": true,
  "installs": [],
  "runs": [],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
---

# `git push` over HTTPS fails after syncing ~/.config/git/config

## Problem

You keep `~/.config/git/config` in a repo so your name, email and aliases
follow you to every machine. After the next sync, pushing to GitHub over HTTPS
stops working: Git asks for a username and password in a terminal, or fails
outright with `could not read Username for 'https://github.com'` when an
agent or script runs the push.

`gh auth status` still says you are logged in.

## Why it happens

Omarchy ships `~/.config/git/config` from `/usr/share/omarchy/config/git/config`
and fills in `user.name` and `user.email` at install time
(`/usr/share/omarchy/install/user/git.sh`). It does not set up a credential
helper.

`gh auth login` (or `gh auth setup-git`) adds one, to that same file:

```ini
[credential "https://github.com"]
	helper =
	helper = !/full/path/to/gh auth git-credential
```

Two things then go wrong:

- Copying a shared `config/git/config` over `~/.config/git/config` replaces
  the whole file, and the helper `gh` added is gone.
- The helper names the absolute path of the `gh` binary that wrote it. Omarchy
  installs `gh` with mise, so that path is a versioned directory under
  `~/.local/share/mise/installs/gh/`. It differs between machines and goes
  stale after `gh` is upgraded. You cannot simply commit it either.

## Fix

Commit a helper that calls `gh` by name. `gh` is on `PATH` on every Omarchy
machine (as a mise shim or Omarchy's wrapper in `~/.local/bin`), so the same
line works everywhere and survives upgrades.

Add to the shared copy of `~/.config/git/config`:

```ini
[user]
	name = Your Name
	email = you@example.com
[credential "https://github.com"]
	helper =
	helper = !gh auth git-credential   # HTTPS pushes use gh's login
[credential "https://gist.github.com"]
	helper =
	helper = !gh auth git-credential
```

The empty `helper =` line clears any helper set earlier (for example in
`/etc/gitconfig`), so for GitHub URLs Git asks only `gh`. The `!` tells Git to
run the rest as a shell command.

### Keep the sync script from dropping it

If your `snapshot.sh` strips credential sections from the git config to keep
`gh`'s machine-specific path out of the repo, a blanket strip also deletes the
portable helper, and every snapshot then shows a diff that would remove it.
Drop only a section whose helper is an absolute path:

```bash
# gh auth setup-git writes an absolute path to this machine's gh binary.
# Drop a credential section that names one; keep one that calls gh by name.
dest="$root/config/git/config"
awk '
  function flush() { if (!abs) printf "%s", buf; buf = ""; abs = 0; in_cred = 0 }
  /^\[/ { if (in_cred) flush() }
  /^\[credential / { in_cred = 1 }
  in_cred {
    buf = buf $0 "\n"
    if ($0 ~ /^[[:space:]]*helper[[:space:]]*=[[:space:]]*!?\//) abs = 1
    next
  }
  { print }
  END { if (in_cred) flush() }
' "$dest" > "$dest.tmp"
mv "$dest.tmp" "$dest"
```

Run this right after copying the live file into the repo. It buffers each
`[credential ...]` section and prints it only if no `helper` line in it starts
with `/` or `!/`.

## Apply and check

After `install.sh` (or copying the file by hand):

```bash
git config --global --get-all credential.https://github.com.helper
```

The output should be an empty line followed by `!gh auth git-credential`.
Then check that Git can reach a private repo without prompting:

```bash
GIT_TERMINAL_PROMPT=0 git ls-remote https://github.com/<you>/<private-repo> HEAD
```

It should print a commit hash, not an authentication error.

If `gh auth login` or `gh auth setup-git` runs again later, it writes its
absolute-path helper back into the file. Change it back to `!gh auth
git-credential`.

## Undo

Remove the two `[credential ...]` sections from `~/.config/git/config` and its
shared copy, and run `gh auth setup-git`, which writes `gh`'s own helper back.
Take the `awk` step out of `snapshot.sh` if you added it.

## Notes

- Keep your real name and email out of any public copy of this file.
- SSH remotes are not affected; this is only for `https://github.com/...`
  remotes, which is what `gh repo clone` uses by default.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.
