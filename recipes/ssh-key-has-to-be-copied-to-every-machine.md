# SSH key has to be created or copied onto every Omarchy machine

**Tested on:** Omarchy 4.0.4, Hyprland 0.56.2 (Lua config)
**Applies to:** every machine

## Problem

Each new Omarchy install needs an SSH key before `git push` to GitHub works.
Either you make a new key on every machine and add each one to GitHub, or you
copy a private key around. Both get messy with more than one machine.

If you already use 1Password, it can hold the one key and serve it to SSH on
every machine, so the private key never sits on disk.

## Why it happens

Omarchy installs 1Password with `omarchy install service 1password` (the
`1password` and `1password-cli` packages, plus the browser extension), but it
does not point SSH at 1Password's agent. Stock OpenSSH looks for keys in
`~/.ssh/` and for an agent in `$SSH_AUTH_SOCK`.

## Fix

In 1Password, open **Settings → Developer** and turn on **Use the SSH agent**.
1Password then listens on `~/.1password/agent.sock`.

Point SSH at that socket in `~/.ssh/config`:

```
Host *
	IdentityAgent ~/.1password/agent.sock
	IdentitiesOnly yes
	IdentityFile ~/.ssh/id_ed25519.pub
```

- `IdentityAgent` sends every connection to 1Password's agent, whatever
  `$SSH_AUTH_SOCK` says.
- `IdentityFile` names the **public** key. With `IdentitiesOnly yes`, SSH
  offers only the agent key that matches it. Without that, an agent holding
  several keys can offer them all and hit the server's limit on failed
  attempts.

Save the public key from 1Password as `~/.ssh/id_ed25519.pub` (it is safe to
share). Then:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config
```

Both files are the same on every machine, so they can live in the repo you
use to sync your config (see
[customizations-do-not-follow-to-other-machines.md](customizations-do-not-follow-to-other-machines.md)).

## Apply and check

With 1Password unlocked:

```bash
SSH_AUTH_SOCK=~/.1password/agent.sock ssh-add -l
ssh -T git@github.com
```

`ssh-add -l` should list the key. GitHub should greet you by username, after
1Password asks you to approve the use of the key.

## Notes

- Never commit the private key, `known_hosts`, or anything else from
  `~/.ssh/` besides `config` and the public key.
- On a brand-new machine the agent does not exist until 1Password is installed
  and signed in. Clone your config repo over HTTPS first (`gh auth login`, then
  `gh repo clone`), and switch to SSH once the agent is on.
- A machine you SSH into can authorize the same key: append the public key to
  its `~/.ssh/authorized_keys`.
- `Host *` routes every SSH connection through 1Password. To keep a host on a
  local key instead, add a `Host` block for it above `Host *` with its own
  `IdentityAgent` and `IdentityFile` lines. SSH uses the first value it finds
  for each option.
