# A Compose snippet with a line break comes out scrambled in Chrome

**Tested on:** Omarchy 4.0.4, Hyprland 0.56.2 (Lua config)
**Applies to:** every machine

## Problem

You want one Compose sequence to type something with more than one line, such
as an email signature:

```
--
Your Name
```

Putting a line break in the `~/.XCompose` result looks like it should work,
but in Chrome it does not. In a rich-text editor (tested in HEY, which uses a
Trix editor), the text after the break landed in the wrong place, one letter
per line.

## Why it happens

A Compose sequence commits its result as a single block of text through the
input method (fcitx5 on Omarchy). Chrome mishandles a line break inside
committed text. Things that were tried and did not help:

- fcitx5's `UseNewComposeBehavior=False`: Chrome then drops the line feed or
  carriage return entirely.
- U+2028 (line separator) instead of `\n`: it shows as a space.

A real line break has to be a key press, not committed text.

## Fix

Have the Compose sequence commit a placeholder character, and have an fcitx5
Lua add-on catch that character and type the snippet as real keys with
`wtype`.

Install the Lua add-on loader and wtype:

```bash
omarchy pkg add fcitx5-lua wtype
```

In `~/.XCompose`, commit a private-use character (U+F0000, written as its
UTF-8 bytes in octal):

```
# Signature. Commits U+F0000, which the fcitx5 add-on in
# ~/.local/share/fcitx5/lua/signature turns into typed keys.
<Multi_key> <space> <s> : "\363\260\200\200"
```

Register the add-on in `~/.local/share/fcitx5/addon/signature.conf`:

```ini
[Addon]
Name=Email signature
Comment=Compose, Space, S types an email signature
Category=Module
Type=Lua
OnDemand=False
Configurable=False
Library=signature.lua

[Addon/Dependencies]
0=luaaddonloader
```

And the converter in `~/.local/share/fcitx5/lua/signature/signature.lua`:

```lua
local fcitx = require("fcitx")

-- U+F0000, from the <Multi_key> <space> <s> line in ~/.XCompose.
local TRIGGER = "\u{F0000}"

-- "-- " keeps its trailing space: that's the standard signature delimiter.
local TYPE_SIGNATURE = [[printf '%s' '-- ' | wtype - && ]]
  .. [[wtype -M shift -k Return -m shift && ]]
  .. [[wtype 'Your Name']]

function type_signature(text)
  if not text:find(TRIGGER, 1, true) then
    return text
  end
  os.execute("(" .. TYPE_SIGNATURE .. ") >/dev/null 2>&1 &")
  return (text:gsub(TRIGGER, ""))
end

fcitx.addConverter("type_signature")
```

How it works:

- `fcitx.addConverter` runs `type_signature` on every piece of text fcitx5
  commits. Anything without the placeholder passes through unchanged.
- When the placeholder shows up, the function removes it (so nothing visible
  is committed) and starts wtype in the background. The `&` lets fcitx5 finish
  the commit before the keys arrive.
- `wtype -M shift -k Return -m shift` is Shift+Enter. That is a line break in
  HEY and Gmail, and it does not send the message in chat apps the way a plain
  Enter would.

## Apply and check

```bash
omarchy restart xcompose
```

That restarts fcitx5, which reloads both `~/.XCompose` and the add-on. Open a
Chrome text field and press Compose, Space, `s`. You should get the two lines
with the cursor at the end.

An agent can test it with `wtype -k Multi_key -k space -k s` while a text
field has focus. Simulated keys pass through fcitx5 like real ones.

## Notes

- For a second multi-line snippet, use the next private-use character
  (U+F0001 is `"\363\260\200\201"`) and add another check in the same
  converter, rather than putting line breaks in `~/.XCompose`.
- To undo, delete the two add-on files and the `~/.XCompose` line, then run
  `omarchy restart xcompose`.
