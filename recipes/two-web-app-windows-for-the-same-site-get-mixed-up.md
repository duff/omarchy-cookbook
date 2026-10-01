# Two web app windows for the same site share one login or get mixed up

**Tested on:** Omarchy 4.0.4, Hyprland 0.56.2 (Lua config)
**Applies to:** every machine

## Problem

Two cases come up:

1. **Two accounts on one site.** You want both signed in at the same time,
   each in its own web app. Every Omarchy web app runs in your one Chrome
   profile, so they share cookies. Signing in to the second account signs
   you out of the first.
2. **Production and a local dev copy.** One web app for the live site and
   one for `myapp.localhost`. They look the same, and from across the screen
   you can't tell which window is which.

Either way, you want each launcher to bring up its own window, and only one
of each.

## Why it happens

`omarchy-launch-webapp` runs your default Chromium-based browser with
`--app=<url>` and your normal profile. Every app window shares the same
cookies.

Hyprland tells Chrome app windows apart by class, and Chrome builds the class
from the URL: `chrome-<host>_<path>-Default`. Two accounts on the same URL
give two windows with the *same* class. Chrome ignores `--class` for app
windows, so you can't rename one. `omarchy-launch-or-focus` focuses the first
window that matches, which may be the wrong account.

Production and local have different hosts, so their classes differ. But the
windows look alike.

## Fix

### Two accounts: a separate Chrome user data directory

Run the second account in its own Chrome instance with `--user-data-dir`.
`omarchy-launch-webapp` passes any extra arguments through to Chrome. To find
the right window, look at the Chrome process that owns it: only the second
account's process has the extra directory on its command line.

Save this as `~/.config/omarchy/site-accounts/launch` and make it executable.
Change `url` and `class` to your site.

```bash
#!/bin/bash
# `launch main` or `launch second`. Focuses that account's window when it is
# open, otherwise opens it.
#
# The second account runs in a separate Chrome profile (its own
# --user-data-dir). Both windows get the same class, so they are told apart by
# the Chrome process that owns the window. Chrome rewrites its command line
# into one space-separated string, so match within it rather than argument by
# argument.

url=https://example.com/account/summary
class='^chrome-example\.com__account_summary-Default$'
second_dir="$HOME/.config/chrome-example-second"

case ${1:-} in
main) args=() ;;
second) args=(--user-data-dir="$second_dir") ;;
*)
  echo "Usage: $(basename "$0") main|second" >&2
  exit 1
  ;;
esac

is_second() {
  { tr '\0' ' ' <"/proc/$1/cmdline"; echo; } 2>/dev/null | grep -qF -- "--user-data-dir=$second_dir "
}

while read -r address pid; do
  if is_second "$pid"; then owner=second; else owner=main; fi
  if [[ $owner == "$1" ]]; then
    exec hyprctl dispatch "hl.dsp.focus({ window = \"address:$address\" })" >/dev/null
  fi
done < <(hyprctl clients -j | jq -r --arg c "$class" '.[] | select(.class | test($c)) | "\(.address) \(.pid)"')

exec omarchy-launch-webapp "$url" "${args[@]}"
```

The trailing space in the `grep` pattern stops one directory name from
matching a longer one.

Make one launcher entry per account in `~/.local/share/applications/`, for
example `Example Second.desktop`:

```ini
[Desktop Entry]
Version=1.0
Name=Example Second
Comment=Example Second
Exec=/home/YOU/.config/omarchy/site-accounts/launch second
Terminal=false
Type=Application
Icon=example
StartupNotify=true
```

`Exec` doesn't expand `~`, so write the full path, with your username in
place of `YOU`. A key binding in
`~/.config/hypr/bindings.lua`:

```lua
o.bind("SUPER + SHIFT + ALT + I", "Example (main)", os.getenv("HOME") .. "/.config/omarchy/site-accounts/launch main")
```

### Production and local: one window each, and a colored border

Each host has its own class, so the stock launch-or-focus command works.
One entry per host:

```ini
Exec=omarchy-launch-or-focus-webapp "chrome-myapp.localhost__-Default" "https://myapp.localhost/"
```

```ini
Exec=omarchy-launch-or-focus-webapp "chrome-myapp.example.com__-Default" "https://myapp.example.com/"
```

To see the difference at a glance, give the local window a thick orange
border, focused or not. In `~/.config/hypr/looknfeel.lua`:

```lua
o.window({ class = "^chrome-myapp\\.localhost__-Default$" }, {
  border_color = "rgb(e8710a)",
  border_size = 4,
})
```

A recolored copy of the icon helps in the launcher too.

## Apply and check

```bash
chmod +x ~/.config/omarchy/site-accounts/launch
hyprctl reload
hyprctl configerrors
```

Open both accounts and sign in to each one once. Each Chrome instance keeps
its own login after that. Run each launcher a second time: the matching
window gets focus, and no new one opens.

## Notes

- The second instance is a whole separate Chrome, with its own extensions,
  settings, and saved passwords. Set it up once.
- To undo, delete the launcher entries and the script. Delete the
  `--user-data-dir` folder to remove the second login.
- For local HTTPS through Caddy, see
  [chrome-privacy-warning-on-local-caddy-https-site.md](chrome-privacy-warning-on-local-caddy-https-site.md).
