# `mise upgrade` skips a release that just shipped

**Tested on:** Omarchy 4.0.4, Hyprland 0.56.2 (Lua config), mise 2026.9
**Applies to:** every machine

## Problem

A new release of Claude Code, Codex, `gh`, or another mise-managed tool is
out, you (or an agent) run `mise upgrade`, and it reports nothing to do. A few
days later the same command picks it up.

A second, related annoyance: the tools you rely on differ between machines.
One laptop has `flyctl` and a pinned Node version, the other has whatever
Omarchy installed on first run.

## Why it happens

mise has a release cooldown, the `minimum_release_age` setting. It holds back
versions younger than that age.

Omarchy works around it only on its own paths. `omarchy update` runs
`/usr/share/omarchy/bin/omarchy-update-mise`, which calls
`MISE_MINIMUM_RELEASE_AGE=0 mise up`. The `mup` alias in
`/usr/share/omarchy/default/bash/aliases` does the same. The wrappers that
`omarchy-mise-install` writes to `~/.local/bin/` (for `claude`, `codex`, `gh`,
`grok` and the rest) export the same variable. A plain `mise upgrade`,
`mise install`, or `mise use` does not, so it gets the cooldown.

Those wrappers run `mise use -g <tool>` the first time you start a tool, which
adds it to `~/.config/mise/config.toml`. So that file ends up listing whatever
you happened to run on that machine, and it is not in any repo.

## Fix

Set the cooldown to zero in the global mise config, and keep that file with
the rest of your config.

`~/.config/mise/config.toml`:

```toml
[tools]
claude = "latest"
codex = "latest"
flyctl = "latest"
gh = "latest"
node = "26.8.2"
"npm:@xai-official/grok" = "latest"

[settings]
minimum_release_age = "0s"

[settings.upgrade]
auto_prune = false
```

- `minimum_release_age = "0s"` turns the cooldown off for every mise command,
  not only Omarchy's.
- `auto_prune = false` is what Omarchy sets on install
  (`/usr/share/omarchy/install/user/mise.sh`). It stops `mise up` from deleting
  the old version while a running agent is still executing from it. Keep it.
- `[tools]` lists what every machine should have. To add a tool everywhere,
  run `mise use -g flyctl` once (it writes the line) and sync the file. Pin a
  version, as with `node` here, when a project needs a specific one.

If you sync config with a repo (see
[customizations-do-not-follow-to-other-machines.md](customizations-do-not-follow-to-other-machines.md)),
put the file in the shared layer as `config/mise/config.toml` and add one line
to `snapshot.sh`:

```bash
# mise tools and settings. minimum_release_age = "0s" lets `mise upgrade`
# install a new release as soon as it ships.
copy_if_present "$config_home/mise/config.toml" "$root/config/mise/config.toml"
```

## Apply and check

```bash
mise settings get minimum_release_age   # 0s
mise install                            # installs anything in [tools] that is missing
mise outdated                           # should list nothing right after mise up
```

On the second machine, after copying the file, `mise install` brings it to the
same tool list, and `mise ls` shows where each version came from.

## Notes

- The cooldown exists to give the ecosystem time to catch a bad or malicious
  release before it lands on your machine. Turning it off trades that for
  getting fixes the day they ship. Omarchy already makes that trade for the
  tools it installs; this extends it to the commands you run by hand.
- To undo, remove the `minimum_release_age` line (or set a longer age such as
  `"3d"`).
