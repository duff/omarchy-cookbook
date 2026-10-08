# Windows are slightly see-through

## Problem

Stock Omarchy makes almost every window a little transparent, so a hint of
the wallpaper shows through behind the text. It's subtle, but it lowers
contrast a little and makes colors slightly off. If you don't want it, there's
no setting to turn it off.

## Why it happens

`/usr/share/omarchy/default/hypr/windows.lua` tags every window
`default-opacity`, lets app rules remove the tag, and then gives the tagged
ones an opacity of 0.985 when focused and 0.96 when not:

```lua
o.window(".*", { tag = "+default-opacity" })
-- ...
o.window({ tag = "default-opacity" }, { opacity = "0.985 0.96" })
```

App rules under `/usr/share/omarchy/default/hypr/apps/` make some windows
solid (video players, image viewers, Steam, and picture-in-picture), and give
browsers `1.0 0.985`, so they're solid only when focused.

## Fix

Add one rule to `~/.config/hypr/looknfeel.lua`:

```lua
-- Every window fully opaque, focused or not. Omarchy's default makes windows
-- slightly see-through (0.985 focused, 0.96 unfocused, browsers 1.0/0.985).
-- Loaded after the defaults, so this wins over every app rule.
o.window(".*", { opacity = "1 1" })
```

The user files under `~/.config/hypr/` load after Omarchy's defaults, and a
later window rule overrides an earlier one, so this one covers browsers and
every app rule too. The two numbers are the focused and unfocused opacity.

## Apply and check

```bash
hyprctl reload
hyprctl configerrors
```

Check a window, focused and unfocused:

```bash
addr=$(hyprctl activewindow -j | jq -r .address)
hyprctl getprop "address:$addr" opacity            # 1
hyprctl getprop "address:$addr" opacity_inactive   # 1
```

## Undo

Delete the rule from `~/.config/hypr/looknfeel.lua`, then run
`hyprctl reload`.

## Notes

- Super+Backspace toggles one window between its normal opacity and fully
  opaque. With this rule in place, it has no visible effect.
- To keep a single app see-through, add a rule for it after this one, such as
  `o.window("^(com.mitchellh.ghostty)$", { opacity = "0.95 0.9" })`.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-08.

## Recipe data

```json
{
  "id": "duff/windows-are-slightly-see-through",
  "title": "Windows are slightly see-through",
  "summary": "Make every window fully opaque, focused or not.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2"},
  "applies_to": "Every machine.",
  "requires": [],
  "touches": ["~/.config/hypr/looknfeel.lua"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": [],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-08"}]
}
```
