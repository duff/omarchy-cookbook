# Opening 1Password jumps to another workspace, or takes up a tile

## Problem

You open 1Password for a few seconds: find a login, copy a code, close it.
With several screens and workspaces, Super+Shift+/ takes you to wherever its
window is, often another screen. If it isn't open yet, it opens as a tile
that squeezes the windows you were working in. Either way you lose your
place for something that should be a quick look.

## Why it happens

Omarchy binds Super+Shift+/ to `omarchy-launch-1password`
(`/usr/share/omarchy/default/hypr/bindings/applications.lua`), which starts
1Password, or raises its window where it already is. It never comes to you.

Omarchy also has a rule to make 1Password a centered float that is hidden
from screen sharing (`/usr/share/omarchy/default/hypr/apps/1password.lua`).
It matches the window class `1Password`, but recent 1Password builds (8.12.36
here) use `com.onepassword.OnePassword`, so on Omarchy 4.0.4 the rule misses:
1Password tiles, and shows up in screen shares. This is
[omacom/omarchy#12288](https://github.com/omacom/omarchy/issues/12288), fixed
by [omacom/omarchy#11704](https://github.com/omacom/omarchy/pull/11704) after
4.0.4.

## Fix

Give 1Password its own hidden workspace (a Hyprland special workspace,
`special:1password`) and make Super+Shift+/ show or hide it over whichever
screen has focus, like Omarchy's Super+S scratchpad but for 1Password alone.

### 1. A window rule for the new class

In `~/.config/hypr/looknfeel.lua` (any file Hyprland loads after Omarchy's
defaults works):

```lua
-- 1Password's window class is now com.onepassword.OnePassword, which
-- Omarchy's rule misses. A centered float, hidden from screen sharing.
-- 1200x800 rather than the stock floating 875x600, which is cramped.
o.window("^com\\.onepassword\\.OnePassword$", {
  float = true,
  center = true,
  size = { 1200, 800 },
  no_screen_share = true,
})
```

Use these rules rather than adding Omarchy's `floating-window` tag: the tag
sets its own 875x600 size, which wins over a `size` rule.

### 2. A toggle script

Save [`files/toggle`](files/toggle) as `~/.config/omarchy/1password/toggle`
and make it executable. Each press:

- **If 1Password is showing on this screen,** hides it.
- **Otherwise,** finds its main window (opening 1Password first if needed),
  moves it into `special:1password`, shows that over the focused screen,
  focuses it, and presses Ctrl+F so you can type a search right away.

Only the main window moves. The script picks the biggest 1Password window, so
its SSH-approval and unlock prompts, which are separate smaller windows, keep
appearing where you are.

### 3. The key

In `~/.config/hypr/bindings.lua`:

```lua
hl.unbind("SUPER + SHIFT + SLASH")
o.bind("SUPER + SHIFT + SLASH", "Passwords", os.getenv("HOME") .. "/.config/omarchy/1password/toggle")
```

## Apply and check

```bash
chmod +x ~/.config/omarchy/1password/toggle
hyprctl reload
hyprctl configerrors
```

If 1Password's window is already open, close it once (1Password keeps
running in the tray) so it reopens with the new rule. Then:

- Super+Shift+/ brings 1Password over the screen you're on, at 1200x800, with
  the cursor in search. Pressing it again hides it.
- `hyprctl clients -j | jq '.[] | select(.class | test("onepassword")) | .workspace.name'`
  shows `"special:1password"`.
- With 1Password locked and hidden, `ssh -T git@github.com` (if SSH goes
  through 1Password's agent) shows the unlock prompt over your screen.
- A screenshot of the window comes out black, which means it's hidden from
  screen sharing.

## Undo

Remove the rule from `looknfeel.lua` and the two lines from `bindings.lua`,
delete `~/.config/omarchy/1password/toggle`, and run `hyprctl reload`.
Super+Shift+/ goes back to Omarchy's launcher. Close the 1Password window
once so it leaves the hidden workspace; it reopens on a normal one.

## Notes

- Switching workspaces hides it, since Omarchy sets
  `hide_special_on_workspace_change`. Copying a value into a window on the
  same workspace, or on another screen without switching, still works.
- Once Omarchy ships #11704, its own rule floats 1Password again, and the
  rule above only needs the `size` line.
- The script works for any app you only visit briefly. Change `name` (the
  hidden workspace), `class` (a regex for the window class, from
  `hyprctl clients`), the launch command, and drop the Ctrl+F line if the app
  doesn't need it.
- Omarchy's Super+S and Super+Alt+S keep working as a separate general
  scratchpad.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-14.

## Recipe data

```json
{
  "id": "duff/opening-1password-jumps-to-another-workspace",
  "title": "Opening 1Password jumps to another workspace, or takes up a tile",
  "summary": "Show and hide 1Password in its own hidden workspace over the focused screen, with the cursor in search.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2", "1password": "8.12.36"},
  "applies_to": "Machines with the 1Password desktop app.",
  "requires": [{"command": "1password"}],
  "touches": ["~/.config/hypr/looknfeel.lua", "~/.config/hypr/bindings.lua", "~/.config/omarchy/1password/toggle"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": [],
  "agent_config": false,
  "upstream": "bug",
  "upstream_link": "https://github.com/omacom/omarchy/issues/12288",
  "history": [{"who": "duff", "did": "created", "date": "2026-10-14"}]
}
```
