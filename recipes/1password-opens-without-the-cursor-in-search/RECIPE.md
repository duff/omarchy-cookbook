# 1Password opens without the cursor in its search field

## Problem

You press Super+Shift+/ to look up a password and start typing its name. But
1Password comes up with the cursor wherever it was last, often on an item or
the sidebar, so the letters go nowhere. You have to click the search field, or
press Ctrl+F, first, every time.

## Why it happens

Omarchy binds Super+Shift+/ to `omarchy-launch-1password`
(`/usr/share/omarchy/default/hypr/bindings/applications.lua`), which runs
`1password --force-device-scale-factor=1`. 1Password allows only one copy of
itself, so when it's already running, in a window or in the tray, it just
shows its window again, with focus where it was left. Nothing moves the
cursor to search.

## Fix

Have the key run a small script instead. It does what stock did, then waits
until the 1Password window is the active one and presses Ctrl+F, 1Password's
shortcut for the search field, through Hyprland.

Save it as `~/.local/bin/open-1password` and make it executable:

```bash
#!/bin/bash
# Focus the 1Password window, opening it if needed, and put the cursor in its
# search field. 1Password leaves focus wherever it was last, so press Ctrl+F
# for it once its window is the active one.

class=com.onepassword.OnePassword

active_class() {
  hyprctl activewindow -j | jq -r '.class // empty'
}

address=$(hyprctl clients -j | jq -r --arg c "$class" '[.[] | select(.class == $c)][0].address // empty')

launched=false
if [[ -n $address ]]; then
  hyprctl dispatch "hl.dsp.focus({ window = \"address:$address\" })" >/dev/null
else
  # The scale flag is the one omarchy-launch-1password passes.
  setsid uwsm-app -- 1password --force-device-scale-factor=1 &
  launched=true
fi

# From the tray, the window takes a moment to appear.
for _ in {1..50}; do
  [[ $(active_class) == "$class" ]] && break
  sleep 0.1
done
[[ $(active_class) == "$class" ]] || exit 0
# A new window draws its search field a moment after it appears.
$launched && sleep 0.5

# Down and up separately, as Omarchy's clipboard keys do, since a synthetic
# shortcut can get stuck repeating.
hyprctl dispatch 'hl.dsp.send_key_state({ mods = "CTRL", key = "F", state = "down" })' >/dev/null
sleep 0.05
hyprctl dispatch 'hl.dsp.send_key_state({ mods = "CTRL", key = "F", state = "up" })' >/dev/null
```

Then point the key at it in `~/.config/hypr/bindings.lua`:

```lua
hl.unbind("SUPER + SHIFT + SLASH")
o.bind("SUPER + SHIFT + SLASH", "Passwords", os.getenv("HOME") .. "/.local/bin/open-1password")
```

- `com.onepassword.OnePassword` is the window class of recent 1Password
  builds. Older ones used `1Password`; check yours with
  `hyprctl clients -j | jq -r '.[].class' | grep -i password`.
- The key goes to the focused window only once it's 1Password, so it can't
  land in the app you came from. If 1Password doesn't come up within five
  seconds, the script gives up without pressing anything.
- `send_key_state` gives the exact modifiers, so Super and Shift, still held
  from the shortcut, don't turn Ctrl+F into another chord.
- If 1Password is locked, its unlock screen comes up as usual, and Ctrl+F does
  nothing there.

## Apply and check

```bash
chmod +x ~/.local/bin/open-1password
hyprctl reload
hyprctl configerrors
```

Press Super+Shift+/ and type: the letters should land in 1Password's search
field. Try it with 1Password's window open on another workspace, and again
after closing the window (1Password stays in the tray).

## Undo

Delete the two lines from `~/.config/hypr/bindings.lua`, then delete
`~/.local/bin/open-1password` and run `hyprctl reload`. Stock's binding comes
back.

## Notes

- This focuses 1Password where its window is, which can mean jumping to
  another screen or workspace. To bring it over the screen you're on instead,
  see
  [Opening 1Password jumps to another workspace, or takes up a tile](../opening-1password-jumps-to-another-workspace/RECIPE.md),
  which also puts the cursor in search.
- A window hidden from screen shares (`no_screen_share`, as Omarchy's
  1Password rule sets) shows up black in screenshots too, so type to check
  where the cursor is rather than taking one.
- If a freshly opened window still misses the Ctrl+F, raise the `sleep 0.5`.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-31.

## Recipe data

```json
{
  "id": "duff/1password-opens-without-the-cursor-in-search",
  "title": "1Password opens without the cursor in its search field",
  "summary": "Have Super+Shift+/ open or focus 1Password, then press Ctrl+F so you can type a search right away.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.5", "hyprland": "0.56.2", "1password": "8.12.40"},
  "applies_to": "Machines with the 1Password desktop app.",
  "requires": [{"command": "1password"}],
  "touches": ["~/.local/bin/open-1password", "~/.config/hypr/bindings.lua"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": [],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-31"}]
}
```
