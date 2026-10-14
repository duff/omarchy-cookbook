# 1Password asks to approve every SSH connection to my own machines

## Problem

With SSH going through 1Password's agent (see
[SSH key has to be created or copied onto every Omarchy machine](../ssh-key-has-to-be-copied-to-every-machine/RECIPE.md)),
every connection pops up a 1Password approval. That's right for GitHub or a
server you don't own, but tiring when you hop between your own machines all
day, and it breaks scripts that SSH from one to another while 1Password is
locked.

## Why it happens

A `Host *` block with `IdentityAgent ~/.1password/agent.sock` sends every
connection to 1Password, and 1Password asks before each use of the key,
depending on its approval settings. Omarchy doesn't configure SSH at all, so
this comes entirely from your own `~/.ssh/config`.

## Fix

Give connections between your own machines a separate key kept on disk, and
leave everything else on 1Password.

Make the key on the machine you connect from:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/home_ed25519 -C "$(hostname) home machines"
```

Add `~/.ssh/home_ed25519.pub` to `~/.ssh/authorized_keys` on each machine
you connect to.

Then put a `Match` block **above** the `Host *` block in `~/.ssh/config`:

```
# My own machines use a key kept on disk, so 1Password doesn't ask on every
# connection. Only on a machine that has that key; anywhere else they fall
# through to the 1Password agent below.
Match host laptop,server exec "test -f ~/.ssh/home_ed25519"
	IdentityAgent none
	IdentityFile ~/.ssh/home_ed25519

Host *
	IdentityAgent ~/.1password/agent.sock
	IdentitiesOnly yes
	IdentityFile ~/.ssh/id_ed25519.pub
```

Replace `laptop,server` with your machines' host names, as you type them
after `ssh`.

- SSH uses the first value it finds for each option, so the `Match` block has
  to come first. Its `IdentityAgent none` wins over the 1Password socket.
- `exec "test -f ..."` keeps one `~/.ssh/config` safe to sync to every
  machine: where the key file doesn't exist, the block doesn't match and the
  connection goes through 1Password as before.
- Both identity files apply, but with `IdentityAgent none` and
  `IdentitiesOnly yes`, only the on-disk key is offered.

## Apply and check

```bash
ssh -G server | grep -i -E '^(identityagent|identityfile)'
ssh server true
```

The first line should show `identityagent none` and the on-disk key. The
second should connect without a 1Password prompt. `ssh -T git@github.com`
should still ask 1Password.

## Undo

Remove the `Match` block from `~/.ssh/config`, take the key's line out of
`~/.ssh/authorized_keys` on each machine you added it to, and delete
`~/.ssh/home_ed25519` and `~/.ssh/home_ed25519.pub`.

## Notes

- The private key now sits on disk, protected only by your login and disk
  encryption. Add a passphrase (and `ssh-add` it once per session) if that's
  not enough, or limit what it can do with `from=` in `authorized_keys`.
- Never sync the private key between machines. Make one per machine you
  connect from.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-14.

## Recipe data

```json
{
  "id": "duff/1password-asks-to-approve-every-ssh-connection",
  "title": "1Password asks to approve every SSH connection to my own machines",
  "summary": "Use a key on disk for your own machines and keep 1Password's agent for everything else.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "openssh": "10.5"},
  "applies_to": "Machines that use 1Password's SSH agent.",
  "requires": [{"command": "1password"}],
  "touches": ["~/.ssh/config", "~/.ssh/home_ed25519", "~/.ssh/home_ed25519.pub", "~/.ssh/authorized_keys"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": [],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-14"}]
}
```
