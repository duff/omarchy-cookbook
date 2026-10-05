---
{
  "id": "duff/no-shortcut-to-open-a-typed-or-pasted-url",
  "title": "No shortcut to open a typed or pasted URL (or search the web)",
  "summary": "Super+U opens an address or searches the web.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2"},
  "applies_to": "Every machine.",
  "requires": [],
  "touches": ["~/.config/omarchy/open-url/open-url", "~/.config/hypr/bindings.lua"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": [],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
---

# No shortcut to open a typed or pasted URL (or search the web)

## Problem

You have a URL on the clipboard, or you want to search for something. Stock
Omarchy has no single key for "open this address". You have to open or focus
a browser window, click the address bar, paste, and press Enter.

## Why it happens

The stock browser bindings (Super+Shift+B, Super+Shift+Return) only open a
browser window. Super+U isn't bound in stock Omarchy.

## Fix

Bind Super+U to a prompt. Anything that looks like an address opens as one;
anything else becomes a DuckDuckGo search.

`~/.config/omarchy/open-url/open-url`:

```bash
#!/bin/bash
# Ask for a URL or a search. Anything that looks like an address opens as
# one; anything else is a DuckDuckGo search. Bound to Super+U.

text=$(omarchy-menu-input "URL or search" --width 600) || exit 0

# Trim surrounding whitespace, which pasted text often carries.
text="${text#"${text%%[![:space:]]*}"}"
text="${text%"${text##*[![:space:]]}"}"
[[ -z $text ]] && exit 0

if [[ $text =~ ^[a-zA-Z][a-zA-Z0-9+.-]*:// ]]; then
  url=$text
elif [[ $text =~ ^(localhost|[0-9]{1,3}(\.[0-9]{1,3}){3})(:[0-9]+)?(/.*)?$ ]]; then
  url="http://$text"
elif [[ $text != *[[:space:]]* && $text =~ ^[^/]+\.[a-zA-Z]{2,}(:[0-9]+)?(/.*)?$ ]]; then
  url="https://$text"
else
  url="https://duckduckgo.com/?q=$(jq -rn --arg q "$text" '$q | @uri')"
fi

exec omarchy-launch-browser "$url"
```

How it decides:

| You type | Opens |
|---|---|
| `https://example.com/a` (any `scheme://`) | as typed |
| `localhost:3000/x`, `192.168.1.10:8080` | `http://` + text |
| `example.com/path` (no spaces, ends in a 2+ letter TLD) | `https://` + text |
| anything else | a DuckDuckGo search |

`omarchy-menu-input` is the stock Omarchy text prompt. `omarchy-launch-browser`
opens the URL in your default browser and focuses it.

In `~/.config/hypr/bindings.lua`:

```lua
-- Type or paste a URL; anything else is a DuckDuckGo search.
o.bind("SUPER + U", "Open URL or search", "~/.config/omarchy/open-url/open-url")
```

## Apply and check

```bash
chmod +x ~/.config/omarchy/open-url/open-url
hyprctl reload
hyprctl configerrors
```

Press Super+U, paste a URL, and press Enter. Try a few words too: you should
get a DuckDuckGo results page.

## Undo

Delete the `SUPER + U` binding from `~/.config/hypr/bindings.lua`, run
`hyprctl reload`, and delete `~/.config/omarchy/open-url/`.

## Notes

- To use a different search engine, change the last `url=` line. The `jq`
  call percent-encodes the query.
- A bare word like `intranet` with no dot becomes a search. Type
  `http://intranet` to open it as a host.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.
