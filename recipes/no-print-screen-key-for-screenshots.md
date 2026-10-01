# No Print Screen key for screenshots

**Tested on:** Omarchy 4.0.4, Hyprland 0.56.2 (Lua config)
**Applies to:** keyboards without a Print Screen key (many laptops, Apple and
split keyboards)

## Problem

Omarchy's screenshot shortcuts all hang off the Print key. On a keyboard
without one, the only way in is the menu (Super+Ctrl+C, then Screenshot).

You may also want a different screenshot tool. Omasnap is a Wayland
screenshot and annotation overlay for Hyprland, in Omarchy's package
repository, but Omarchy 4.0 does not install it or use it.

## Why it happens

`/usr/share/omarchy/default/hypr/bindings/utilities.lua` binds `PRINT` to
`omarchy-capture-screenshot`, which picks a region and then opens the image
in Tensaku (`OMARCHY_SCREENSHOT_EDITOR` defaults to `tensaku-edit`). The
Capture menu's Screenshot row runs the same script. It is defined in
`/usr/share/omarchy/default/omarchy/omarchy-menu.jsonc` as
`trigger.capture.screenshot`.

Super+Shift+S, the shortcut many people expect, is taken by the Google Maps
web app in `/usr/share/omarchy/default/hypr/bindings/applications.lua`.

## Fix

Install Omasnap:

```bash
omarchy pkg add omasnap
```

In `~/.config/hypr/bindings.lua`, free Super+Shift+S and bind it to Omasnap:

```lua
-- SUPER+SHIFT+S was Google Maps. Pressing it again closes the overlay.
hl.unbind("SUPER + SHIFT + S")
o.bind("SUPER + SHIFT + S", "Screenshot and annotate", "omasnap")
```

Point the Capture menu's Screenshot row at Omasnap too. In
`~/.config/omarchy/extensions/omarchy-menu.jsonc`, reuse the stock id so it
overrides the stock row:

```jsonc
{
  // Capture > Screenshot opens Omasnap, same as Super+Shift+S.
  "trigger.capture.screenshot": {"icon":"","label":"Screenshot","action":"omasnap"},
}
```

Copy the icon glyph from the stock row in
`/usr/share/omarchy/default/omarchy/omarchy-menu.jsonc` if your editor drops
it.

### Optional: print the screenshot

In Omasnap, Enter copies the image to the clipboard. This binding sends a PNG
on the clipboard to the default printer:

```lua
o.bind(
  "SUPER + SHIFT + ALT + S",
  "Print clipboard image",
  "if wl-paste --list-types | grep -qx image/png; then "
    .. "wl-paste --type image/png | lp -o fit-to-page && "
    .. o.notify("Sent the clipboard image to the printer")
    .. " || "
    .. o.notify("Printing failed")
    .. "; else "
    .. o.notify("No image on the clipboard to print")
    .. "; fi"
)
```

`o.notify` is Omarchy's helper that returns an `omarchy-notification-send`
command, so each branch leaves a short notification.

## Apply and check

Hyprland reloads `bindings.lua` on save. Check for mistakes:

```bash
hyprctl reload
hyprctl configerrors
```

The menu extension reloads on save. Press Super+Shift+S and drag a region,
then open Super+Ctrl+C and pick Screenshot; both should open Omasnap.

## Notes

- Bind to `omasnap` itself, not `omarchy-capture-screenshot`. A first try
  bound `tensaku --capture`, which works but keeps Tensaku as the editor.
- If you only want Tensaku on a different key, stock already shows the way
  in `~/.config/hypr/bindings.lua`:
  `o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")`, after
  `hl.unbind("SUPER + SHIFT + S")`.
- The Print key bindings are left alone, so a keyboard that has the key
  still gets the stock behavior.
- To undo, delete the lines and the menu entry. Google Maps comes back on
  Super+Shift+S once the `hl.unbind` is gone.
