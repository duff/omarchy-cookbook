# Ctrl+Enter toggles fullscreen in Ghostty instead of reaching the app

**Tested on:** Omarchy 4.0.4, Hyprland 0.56.2 (Lua config), Ghostty 1.3.1
**Applies to:** every machine using Ghostty as the terminal

## Problem

Terminal apps that use Ctrl+Enter never see it in Ghostty. Claude Code, for
example, uses Ctrl+Enter to send a message right away; in Ghostty the window
goes fullscreen instead.

## Why it happens

Ghostty's built-in keybindings include:

```
keybind = ctrl+enter=toggle_fullscreen
```

(see `ghostty +list-keybinds --default`). Omarchy's Ghostty config
(`/usr/share/omarchy/config/ghostty/config`) already remaps Shift+Enter and
Alt+Shift+Enter to CSI-u sequences so apps can tell them from Enter, but it
leaves Ctrl+Enter on Ghostty's default.

## Fix

In `~/.config/ghostty/config`, next to the other Enter bindings, send
Ctrl+Enter to the app as a CSI-u sequence:

```
# Ghostty's default Ctrl+Enter toggles fullscreen, which swallows
# Ctrl+Enter in terminal apps. Send CSI-u instead; Super+F still fullscreens.
keybind = ctrl+enter=csi:13;5u
```

`13` is Enter and `5` is the Ctrl modifier, the same form as the stock
`shift+enter=csi:13;2u` line. Hyprland's Super+F still makes any window
fullscreen, so nothing is lost.

## Apply and check

```bash
omarchy restart terminal
```

That sends Ghostty a reload signal. In a TUI that uses Ctrl+Enter, the key
should now act there, and the window should stay its size.

## Notes

To undo, delete the `keybind = ctrl+enter` line and Ghostty goes back to
fullscreen on Ctrl+Enter.

### Making Ghostty the default terminal

Stock Omarchy 4.0.4 lists Foot as the terminal for Super+Return
(`/usr/share/omarchy/default/xdg-terminal-exec/hyprland-xdg-terminals.list`).
To switch to Ghostty:

```bash
omarchy install terminal ghostty
```

That installs the package, copies Omarchy's Ghostty config to
`~/.config/ghostty/` if you have none, and writes
`~/.config/xdg-terminals.list`:

```
# Terminal emulator preference order for xdg-terminal-exec
# The first found and valid terminal will be used
com.mitchellh.ghostty.desktop
```

If Ghostty is already installed, `omarchy default terminal ghostty` only
switches the default.

If you keep `xdg-terminals.list` in a dotfiles repo, install the `ghostty`
package in your setup script too. The list naming Ghostty does nothing on a
machine where it is not installed. Copy Omarchy's config only when
`~/.config/ghostty` does not exist, so your own config is not replaced.
