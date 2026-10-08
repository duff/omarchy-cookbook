# Putting Compose on Right Alt breaks Right Alt as a modifier

## Problem

This only matters once you move Compose off Caps Lock and onto Right Alt.
With stock Omarchy's Compose key, Right Alt is a plain Alt and works fine.

Stock Omarchy makes Caps Lock the Compose key. If you want Caps Lock for
something else (Escape, an arrow layer), the obvious move is to put Compose on
Right Alt with the XKB option `compose:ralt`. That works for Compose, but Right
Alt stops being Alt. Holding it for an Alt shortcut, or for a Super+Alt chord,
starts a Compose sequence instead.

The goal here is a tap of Right Alt that starts Compose and a hold that is
still Alt.

## Why it happens

`/usr/share/omarchy/default/hypr/input.lua` sets:

```lua
local kb_options = "compose:caps,shift:both_capslock_cancel"
```

XKB options remap a key to one thing. `compose:ralt` turns Right Alt into
`Multi_key` whether you tap it or hold it. XKB has no tap-versus-hold, so that
part has to happen below it, in a key remapper such as keyd.

There is a second trap. keyd's `compose` action sends `KEY_COMPOSE`, and XKB
maps that key to `Menu`. Without the `compose:menu` option, the tap types Menu
and Compose never starts.

## Fix

Install keyd and enable it:

```bash
omarchy pkg add keyd
sudo systemctl enable --now keyd
```

keyd reads its config from `/etc/keyd/`. In `/etc/keyd/default.conf`:

```ini
[ids]
*

[main]
# Tap = Compose. Held 200 ms or more = Alt.
rightalt = overloadt(alt, compose, 200)
```

`overloadt(alt, compose, 200)` sends `compose` when the key is tapped, and acts
as the Alt modifier once it has been held for 200 ms. A key pressed before
then waits for keyd's decision.

The timing matters because Compose sequences are typed fast. With plain
`overload(alt, compose)`, keyd decides by whether another key goes down while
Right Alt is held. A quick roll, where you press the first letter of the
sequence a moment before Right Alt comes back up, turns into Alt+letter and
the sequence never starts. With `overloadt`, that roll is still Compose,
because Right Alt came back up within 200 ms. Raise the number if your rolls
still come out as Alt, or lower it if Alt chords feel sluggish.

Then tell XKB that the Menu key is Compose, and drop `compose:ralt` if you had
it. In `~/.config/hypr/input.lua`:

```lua
-- Right Alt is Compose on tap and Alt when held, in keyd.
-- keyd's tap sends the Menu key; compose:menu makes Menu act as Compose.
-- compose:ralt would turn that hold into Compose as well.
hl.config({
  input = {
    kb_options = "compose:menu,shift:both_capslock_cancel",
  },
})
```

Setting `kb_options` replaces the whole stock string, so `compose:caps` goes
away and Caps Lock is a plain Caps Lock again (or whatever keyd makes it).
Keep `shift:both_capslock_cancel` if you still want both Shifts to toggle Caps
Lock. If you use a non-Latin layout, stock Omarchy also appends
`grp:alts_toggle`; your string has to include it too.

## Apply and check

```bash
sudo keyd reload
hyprctl reload
hyprctl configerrors
hyprctl getoption input:kb_options   # should list compose:menu
```

Tap Right Alt, then type `m` `s`. Omarchy's stock sequences should give 😄.
Then hold Right Alt and press a key you have bound to Alt (or Super+Alt) and
confirm the shortcut fires. `sudo keyd monitor` shows what keyd sees if the
key does nothing.

## Undo

Delete the `rightalt` line from `/etc/keyd/default.conf`, run
`sudo keyd reload`, and remove the `kb_options` override from
`~/.config/hypr/input.lua` so the stock `compose:caps` comes back. Then run
`hyprctl reload`.

If nothing else uses keyd, stop it and remove it:

```bash
sudo systemctl disable --now keyd
omarchy pkg drop keyd
```

## Notes

- Version 1 used `overload(alt, compose)`, which reads a fast Compose roll as
  Alt.
- `[ids] *` applies the mapping to every keyboard, including external ones.
  To leave one keyboard alone, list it with a minus (`-vendor:product`, from
  `keyd monitor`) and give it its own file.
- `/etc/keyd/` is outside `~/.config/`. This setup keeps the source in
  `~/.config/keyd/` and copies it to `/etc/keyd/` from a `post-update` hook.
  See [caps-lock-as-escape-and-hjkl-arrows.md](../caps-lock-as-escape-and-hjkl-arrows/RECIPE.md),
  which also explains what this setup does with Caps Lock once it is no
  longer Compose.
- If one keyboard needs its own keyd file (a laptop keyboard with Alt and
  Super swapped, say), move shared lines like this one into an included file.
  See [swap-alt-and-super-on-laptop-keyboard-only.md](../swap-alt-and-super-on-laptop-keyboard-only/RECIPE.md).
- The same keyd file can turn another spare key into the dictation key. See
  [dictation-keeps-recording-after-releasing-push-to-talk.md](../dictation-keeps-recording-after-releasing-push-to-talk/RECIPE.md).

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.

## Recipe data

```json
{
  "id": "duff/right-alt-compose-key-loses-alt-modifier",
  "title": "Putting Compose on Right Alt breaks Right Alt as a modifier",
  "summary": "Make Right Alt Compose on tap and Alt when held 200 ms, with keyd.",
  "version": 2,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2"},
  "applies_to": "Machines that move Compose from Caps Lock to Right Alt.",
  "requires": [],
  "touches": ["/etc/keyd/default.conf", "~/.config/hypr/input.lua"],
  "root": true,
  "network": false,
  "installs": ["keyd"],
  "runs": ["keyd.service"],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
```
