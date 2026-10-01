# Reboot from the menu, or Ctrl+Alt+Delete, closes everything without asking

**Tested on:** Omarchy 4.0.4, Hyprland 0.56.2 (Lua config)
**Applies to:** every machine

## Problem

Two stock actions throw away every open window with one keypress and no
question:

- System > Reboot in the Omarchy menu (Super+Escape, or the power key)
  reboots straight away. A stray Enter on the wrong row closes all your apps.
- Ctrl+Alt+Delete closes every window. Habit from other systems, or a
  fumbled chord, wipes the session.

## Why it happens

The System menu rows come from
`/usr/share/omarchy/default/omarchy/omarchy-menu.jsonc`. The Reboot row is a
plain action:

```jsonc
"system.reboot": {"icon":"󰜉","label":"Reboot","action":"omarchy-system-reboot"},
```

`omarchy-system-reboot` schedules the reboot and then runs
`omarchy-hyprland-window-close-all`.

Ctrl+Alt+Delete is bound in
`/usr/share/omarchy/default/hypr/bindings/tiling.lua`:

```lua
o.bind("CTRL + ALT + DELETE", "Close all windows", "omarchy-hyprland-window-close-all")
```

## Fix

### Reboot asks first

User menu entries in `~/.config/omarchy/extensions/omarchy-menu.jsonc` merge
over the stock ones by id. A row without an `action` is a submenu, so
redefining `system.reboot` without one turns it into a "Reboot now?" submenu,
and two child ids give it its choices:

```jsonc
{
  // Reboot asks first. Leaving out the action turns the row into a submenu.
  "system.reboot": {"icon":"󰜉","label":"Reboot","title":"Reboot now?"},
  "system.reboot.confirm": {"icon":"󰜉","label":"Yes, reboot","action":"omarchy-system-reboot"},
  "system.reboot.cancel": {"icon":"󰜺","label":"Cancel","action":"true"},
}
```

`title` is the header shown while the submenu is open. The Cancel row runs
`true`, which does nothing and closes the menu.

### Ctrl+Alt+Delete asks first

In `~/.config/hypr/bindings.lua`, replace the stock binding with one that asks
through `omarchy-menu-select` and only closes windows on Yes:

```lua
-- Ask before closing every window.
hl.unbind("CTRL + ALT + DELETE")
o.bind(
  "CTRL + ALT + DELETE",
  "Close all windows",
  '[ "$(omarchy-menu-select "Close all windows?" No Yes)" = Yes ] && omarchy-hyprland-window-close-all'
)
```

`omarchy-menu-select` prints the chosen label. No is listed first. Escape
closes the menu with no answer, which also counts as no.

## Apply and check

The menu extension and `bindings.lua` both reload on save. Check the Hyprland
side:

```bash
hyprctl reload
hyprctl configerrors
```

Open Super+Escape and pick Reboot: you should see "Reboot now?" with Yes,
reboot and Cancel. Press Ctrl+Alt+Delete: a "Close all windows?" menu should
appear. Pick No both times.

## Notes

- `omarchy reboot` from a terminal is unchanged and still reboots right away.
- The same submenu pattern works for `system.shutdown` and `system.logout`.
- To undo, delete the three `system.reboot*` entries and the two Lua
  statements.
