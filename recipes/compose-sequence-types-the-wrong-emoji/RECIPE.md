# A Compose sequence types the wrong emoji, or the one I want is missing

## Problem

Omarchy ships Compose shortcuts for emoji (Compose, `m`, then a letter) and a
few snippets. Some of them are not what you want. For example, Compose `m` `d`
types 🤤, and there is no shortcut for ✅. You want to change one and add
your own, without losing them on the next `omarchy update`.

## Why it happens

The installer writes `~/.XCompose` once
(`/usr/share/omarchy/install/user/xcompose.sh`). It includes the packaged list
and adds your name and email:

```
# Include fast emoji access
include "/usr/share/omarchy/default/xcompose"

# Identification
<Multi_key> <space> <n> : "<your name>"
<Multi_key> <space> <e> : "<your email>"
```

The packaged file, `/usr/share/omarchy/default/xcompose`, holds the emoji
(`<Multi_key> <m> <d> : "🤤" # droll`) and is replaced on every update.
`~/.XCompose` is yours. Hyprland points `XCOMPOSEFILE` at it
(`/usr/share/omarchy/default/hypr/envs.lua`), and fcitx5 reads it.

## Fix

Add lines to `~/.XCompose` after the `include`. A later rule for the same
sequence replaces the packaged one:

```
# Emoji overrides (later rules replace the packaged ones)
<Multi_key> <m> <d> : "✅" # check
```

New sequences go in the same way. For a snippet, follow the stock
identification style (Compose, Space, a letter):

```
<Multi_key> <space> <w> : "https://example.com"
```

Do not edit `/usr/share/omarchy/default/xcompose`.

## Apply and check

fcitx5 only reads the file at start:

```bash
omarchy restart xcompose
```

Then press Compose, `m`, `d` in any text field. Omarchy's menu has the same
thing under Setup, Config, XCompose, which opens the file and restarts fcitx5
when you close it.

An agent can test without a keyboard: `wtype -k Multi_key -k m -k d` goes
through fcitx5 and types into the focused window.

## Undo

Delete the lines you added to `~/.XCompose` and run
`omarchy restart xcompose`. For an override, the packaged sequence comes
back.

## Notes

- Keep each result on one line. A line break inside a Compose result comes
  out scrambled in Chrome. See
  [compose-snippet-with-line-break-scrambled-in-chrome.md](../compose-snippet-with-line-break-scrambled-in-chrome/RECIPE.md).

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.

## Recipe data

```json
{
  "id": "duff/compose-sequence-types-the-wrong-emoji",
  "title": "A Compose sequence types the wrong emoji, or the one I want is missing",
  "summary": "Override or add sequences in ~/.XCompose.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2"},
  "applies_to": "Every machine.",
  "requires": [],
  "touches": ["~/.XCompose"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": [],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
```
