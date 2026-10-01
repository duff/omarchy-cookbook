# Windows app in Wine is tiny, blurry, or draws hair-thin lines on a HiDPI screen

**Tested on:** Omarchy 4.0.4, Hyprland 0.56.2 (Lua config), Wine 11
**Applies to:** Windows apps run under Wine on 2x screens (tested with a stock market trading app that is only available for Windows, a .NET WinForms program, on Apple Studio Displays at scale 2)

## Problem

A Windows program under Wine looks wrong on a 2x display, whichever way you
set it up:

- Out of the box it is drawn at native pixels, so everything is half size.
- Raise Wine's DPI to 192 and mark the app DPI-aware, and text and controls
  are the right size, but anything the app draws with fixed pixel widths stays
  thin. In a trading app's charts, a line set to width 4 shows as width 2 while the text
  around it doubles.
- Raise Wine's DPI to 192 without marking the app DPI-aware, and Wine
  stretches a 96 DPI image to 2x itself. The whole window is smoothed, so text
  looks soft.

## Why it happens

Wine apps are X11 apps and run through XWayland. Omarchy sets
`xwayland.force_zero_scaling = true` in
`/usr/share/omarchy/default/hypr/envs.lua`. That tells Hyprland not to scale
X11 windows, so each app has to scale itself. Wine's DPI setting scales fonts
and controls, but not widths the app gives in raw pixels. Wine's own
upscaling of DPI-unaware apps always uses smooth filtering.

## Fix

Let Hyprland do the doubling. Wine draws at 96 DPI, the app sees an ordinary
1x screen, and Hyprland scales every X11 window by the monitor's scale with
nearest-neighbor filtering. A 2x scale turns each pixel into a sharp 2x2
block. Lines keep their weight relative to the text, and edges stay crisp.

### Hyprland

Create `~/.config/hypr/tradingapp.lua` (any name works) and load it by
adding `require("hypr.tradingapp")` at the end of
`~/.config/hypr/hyprland.lua`:

```lua
-- The app draws line widths in raw pixels, so at full resolution a width-4
-- line shows as 2. Wine draws it at 96 DPI instead, and Hyprland doubles X11
-- windows with sharp 2x2 blocks (use_nearest_neighbor, on by default).
-- Wine's own doubling is always smoothed, which makes text soft. Omarchy's
-- default (true) leaves X11 windows unscaled. This applies to every X11 app.
hl.config({
  xwayland = {
    force_zero_scaling = false,
  },
})
```

This only gives a sharp result at whole-number scales such as 2. See
[hidpi-screens-left-on-auto-scale.md](hidpi-screens-left-on-auto-scale.md).

### Wine prefix

Run these with `WINEPREFIX` set to the app's prefix (here
`~/.local/share/wineprefixes/tradingapp`):

```bash
export WINEPREFIX="$HOME/.local/share/wineprefixes/tradingapp"

# Draw at 96 DPI and let Hyprland double it.
wine reg add 'HKCU\Control Panel\Desktop' /v LogPixels /t REG_DWORD /d 96 /f

# If the app was ever marked high-DPI aware, remove that. Wine looks it up by
# the lowercased exe name, not its path.
wine reg delete 'HKCU\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers' \
  /v tradingapp.exe /f

# Grayscale font smoothing. ClearType's colour fringes show once doubled.
winetricks -q fontsmooth=gray
```

Two more steps helped this particular app look and work like it does on
Windows. They are worth trying for other WinForms apps:

```bash
# The real Windows fonts and GDI+. Wine's substitutes draw softer text and lines.
winetricks -q arial tahoma micross gdiplus

# Microsoft .NET 4.8, for apps that need parts Wine Mono lacks
# (this one compiles formulas with Microsoft.JScript).
winetricks -q dotnet48
# dotnet48 leaves the prefix reporting Windows XP.
wine winecfg -v win10
```

Install Wine itself with `omarchy pkg add wine wine-mono wine-gecko
winetricks`. Mono and Gecko avoid Wine's first-run download prompts.

## Apply and check

`force_zero_scaling` does not fully apply on `hyprctl reload`. XWayland keeps
the old screen layout until you log in again or a monitor rule changes. Until
then, the app's menus on a second screen open in the wrong place and ignore
clicks. Log out and back in after changing it.

```bash
hyprctl getoption xwayland:force_zero_scaling   # bool: false
hyprctl getoption xwayland:use_nearest_neighbor # bool: true
```

Start the app. Text and controls should be normal size with sharp edges, and
a width-4 line should look twice as thick as a width-2 one.

## Notes

- `force_zero_scaling = false` is global. Every other X11 app (Spotify, for
  one) also gets pixel-doubled, so it looks sharp-edged but lower
  resolution. List the X11 windows you have open with
  `hyprctl clients -j | jq -r '.[] | select(.xwayland) | .class'`.
- Wine's Wayland driver (`Graphics=wayland`) was tried instead. Hyprland
  stretched its buffer on resize (distorted text, clicks landing in the wrong
  place), and the app raised error prompts on quit.
- An app that saves window layouts in pixels opens layouts saved at the old
  DPI at the wrong size. Re-save them once.
- To undo: delete the `hl.config` block, log out and back in, and set
  `LogPixels` back to the value you had.
