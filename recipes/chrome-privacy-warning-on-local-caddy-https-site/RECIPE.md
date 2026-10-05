# Chrome shows a privacy warning on a local Caddy HTTPS site

## Problem

Caddy serves a local dev site, such as `https://myapp.localhost`, with its own
local certificate authority. You ran `caddy trust`, and `curl` accepts the
certificate. Chrome still shows "Your connection is not private", in a
browser tab and in a web app window.

## Why it happens

`caddy trust` adds Caddy's root certificate ("Caddy Local Authority - <year>
ECC Root") to the system trust store, which `p11-kit` manages. Chrome on
Linux doesn't use that store for roots you add yourself. It checks its own
NSS database in `~/.pki/nssdb`. Omarchy doesn't link the two.

## Fix

Copy every Caddy root the system trusts into Chrome's NSS database. This
needs `trust` (from `p11-kit`) and `certutil` (from `nss`). Chrome and
Chromium depend on both packages, so they're already installed. Run it as
your user, not root:

```bash
#!/usr/bin/env bash
# Copy each Caddy local root the system trusts into Chrome's NSS database.
set -euo pipefail

nssdb="$HOME/.pki/nssdb"
while IFS='|' read -r uri label; do
  if [[ ! -f $nssdb/cert9.db ]]; then
    mkdir -p "$nssdb"
    chmod 700 "$HOME/.pki" "$nssdb"
    certutil -d "sql:$nssdb" -N --empty-password
  fi
  certutil -d "sql:$nssdb" -L -n "$label" &>/dev/null && continue
  pem=$(mktemp)
  trust extract --overwrite --format=pem-bundle --filter="$uri" "$pem"
  certutil -d "sql:$nssdb" -A -t "C,," -n "$label" -i "$pem"
  rm -f "$pem"
  echo "Chrome now trusts $label. Restart Chrome to use it."
done < <(trust list --filter=ca-anchors | awk '
  /^pkcs11:/ { uri = $0 }
  /^ *label: Caddy Local Authority/ { sub(/^ *label: /, ""); print uri "|" $0 }
')
```

What it does:

- `trust list --filter=ca-anchors` lists each trusted root with its
  `pkcs11:` URI and its label. The `awk` keeps only Caddy's roots.
- If you don't have an NSS database yet, it creates one with an empty
  password.
- It skips any root that's already in the database, so you can run it again.
  It adds new roots with trust flags `C,,`, which means trusted to issue
  server certificates.

## Apply and check

Fully quit Chrome, web app windows included, and start it again. Chrome reads
the database only at startup.

```bash
certutil -d sql:$HOME/.pki/nssdb -L | grep Caddy
```

Open the local site. It should load with no warning.

## Undo

Delete each Caddy root from Chrome's database, by the label that the check
above lists, then fully quit and restart Chrome:

```bash
certutil -d sql:$HOME/.pki/nssdb -D -n "<label>"
```

## Notes

- Each machine's Caddy makes its own root, so run the script on every
  machine. When Caddy makes a new root, run it again.
- Firefox keeps its own NSS database for each profile, so this doesn't cover
  it.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-01.

## Recipe data

```json
{
  "id": "duff/chrome-privacy-warning-on-local-caddy-https-site",
  "title": "Chrome shows a privacy warning on a local Caddy HTTPS site",
  "summary": "Add Caddy's root certificate to Chrome's own store.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.4", "hyprland": "0.56.2"},
  "applies_to": "Machines that serve local dev sites over HTTPS with Caddy.",
  "requires": [{"command": "caddy"}],
  "touches": ["~/.pki/nssdb/"],
  "root": false,
  "network": false,
  "installs": [],
  "runs": [],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-01"}]
}
```
