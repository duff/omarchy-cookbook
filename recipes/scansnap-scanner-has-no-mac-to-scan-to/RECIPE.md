# ScanSnap scanner has no Mac or PC to scan to

## Problem

A ScanSnap (tested with an iX1600) expects ScanSnap Home, on a Mac or a
Windows PC, to receive every scan. There is no Linux version, so on an
Omarchy-only household the scan button has nowhere to send its PDFs, and the
PDFs it can make on its own are pictures of pages: you can't search them.

## Why it happens

ScanSnap Home is the scanner's desktop software, and there is no Linux
version of it. What the iX1600 can do with no computer in the loop is **Scan
to Network Folder**: it saves each scan as a PDF on an SMB share. Omarchy
doesn't run an SMB server, and the PDFs the scanner writes there are images
only, with no text layer.

## Fix

Two parts. The first does the work; the second is optional.

1. **An always-on Linux machine** (an old laptop on a shelf works, see
   [Laptop used as a headless server sleeps when the lid is shut](../laptop-server-sleeps-when-lid-is-shut/RECIPE.md))
   runs a one-share Samba server. The scanner saves to it, and a systemd path
   unit hands each new PDF to a script that names it by day and number
   (`2026-10-17.001.pdf`, `.002`, ...), adds a searchable text layer, and
   moves it to Dropbox with rclone. Nothing is kept or synced down on this
   machine, so its disk can be small.
2. **Your desktop**, which already syncs Dropbox, shows a notification as
   each numbered scan arrives. Clicking it asks for a name in the Omarchy
   menu's text box and renames the file. A scan you never name keeps its
   numbered name, so scanning never waits on you.

### 1. The always-on machine

Put these in `~/.config/scansnap/` on it:

- `files/smb.conf`: the share `scans` at `~/Scans`. Only the Samba user
  `scansnap` may sign in, and only from your home network. Files land owned
  by you, so the upload script can move them.
- `files/upload`: the script the path unit runs. It waits until the scanner
  has finished writing (unchanged for 3 seconds and passing `qpdf --check`,
  or a minute old), numbers scans oldest first, and adds the text: `pdftoppm`
  renders each page, `tesseract` writes an invisible text-only PDF of it, and
  `qpdf --underlay` lays that under the scanner's own page, which stays as
  scanned. If any step fails, the scan goes up without text instead of
  waiting. Then `rclone move --ignore-existing` uploads it; a name clash
  stays in the outbox rather than overwriting anything. A day's next number
  also counts what's already in Dropbox, so renaming a scan there doesn't
  free its number.
- `files/apply.sh`: installs the packages, the Samba config, the `scansnap`
  user and its password, a firewall rule for port 445 from your network, and
  the user units, and turns on lingering so they run with nobody logged in.
- The three units below.

`~/.config/scansnap/scan-upload.path`. It fires as soon as something lands
in `~/Scans`:

```ini
[Unit]
Description=Watch ~/Scans for new scans

[Path]
PathChanged=%h/Scans
Unit=scan-upload.service

[Install]
WantedBy=default.target
```

`~/.config/scansnap/scan-upload.service`:

```ini
[Unit]
Description=Make new ScanSnap scans searchable and move them to Dropbox
ConditionDirectoryNotEmpty=|%h/Scans
ConditionDirectoryNotEmpty=|%h/.local/state/scansnap/outbox

[Service]
Type=oneshot
ExecStart=%h/.config/scansnap/upload
TimeoutStartSec=20min
```

`~/.config/scansnap/scan-upload.timer`, a backstop for anything the path
unit misses:

```ini
[Unit]
Description=Check ~/Scans every five minutes, in case scan-upload.path missed one

[Timer]
OnCalendar=*:0/5
AccuracySec=10s

[Install]
WantedBy=timers.target
```

What to change for your setup:

- `lan` at the top of `apply.sh`: your home network's range. `192.0.2.0/24`
  is a placeholder. It goes into the share's `hosts allow` and the firewall
  rule.
- `remote` at the top of `upload`: the rclone remote and Dropbox folder.
  `dropbox:ScanSnap` puts scans in a `ScanSnap` folder at the top of your
  Dropbox; a path like `dropbox:Documents/Scans` works the same way.

### 2. Your desktop (optional)

Put `files/arrived` and `files/name` in `~/.config/scansnap/` on the desktop,
and set `dir` at the top of `arrived` to where the Dropbox client syncs the
same folder (`~/Dropbox/ScanSnap` for `dropbox:ScanSnap`).

- `arrived` runs whenever that folder changes. For each numbered scan it
  hasn't seen, it sends a notification ("New scan: 2026-10-17.001 (3 pages).
  Click to name it.") whose click runs `name`. Omarchy keeps the click in the
  notification history (Super+Shift+Alt+Comma), so a scan that arrived while
  you were away can still be named from there.
- `name` asks for a name with `omarchy-menu-input` and renames the file,
  asking again if the name is taken. Escape leaves it numbered.

`~/.config/systemd/user/scan-arrived.path`:

```ini
[Unit]
Description=Watch the Dropbox scans folder for new scans

[Path]
PathChanged=%h/Dropbox/ScanSnap

[Install]
WantedBy=default.target
```

`~/.config/systemd/user/scan-arrived.service`:

```ini
[Unit]
Description=Offer to name new scans in the Dropbox scans folder

[Service]
Type=oneshot
ExecStart=%h/.config/scansnap/arrived
```

Change the `PathChanged` folder to match `dir`.

## Apply and check

On the always-on machine, from a terminal (it asks for your password, then
for a password for the scanner):

```bash
chmod +x ~/.config/scansnap/apply.sh ~/.config/scansnap/upload
~/.config/scansnap/apply.sh
rclone config create dropbox dropbox   # once; opens a browser to sign in
systemctl --user status scan-upload.path scan-upload.timer
```

Then make the scanner's profile, once, in ScanSnap Home on any Mac or PC:
add a **Scan to Network Folder** profile pointing at `\\<machine>\scans`,
user `scansnap` and the password you chose, saving PDFs. After that the
scanner needs no computer.

Scan a page. Within a few seconds `~/Scans` should empty again and the PDF
should show up in Dropbox as `<today>.001.pdf`, with text you can select or
search. `journalctl --user -u scan-upload.service` shows each run.

On the desktop:

```bash
chmod +x ~/.config/scansnap/arrived ~/.config/scansnap/name
systemctl --user daemon-reload
systemctl --user enable --now scan-arrived.path
systemctl --user start scan-arrived.service   # catches scans already there
```

The next scan should bring a "New scan" notification once Dropbox syncs it.

## Undo

On the desktop:

```bash
systemctl --user disable --now scan-arrived.path
rm ~/.config/systemd/user/scan-arrived.{path,service}
rm -r ~/.config/scansnap ~/.local/state/scansnap
systemctl --user daemon-reload
```

On the always-on machine:

```bash
systemctl --user disable --now scan-upload.path scan-upload.timer
rm ~/.config/systemd/user/scan-upload.{path,service,timer}
systemctl --user daemon-reload
sudo systemctl disable --now smb
sudo smbpasswd -x scansnap
sudo userdel scansnap
sudo rm /etc/samba/smb.conf
sudo ufw delete allow from 192.0.2.0/24 to any port 445 proto tcp
sudo loginctl disable-linger "$USER"   # only if nothing else needs it
rclone config delete dropbox
omarchy pkg drop samba rclone
rm -r ~/.config/scansnap ~/.local/state/scansnap
```

Use your own range in the `ufw delete` line. `~/Scans` should be empty; remove
it too. The tesseract, qpdf and poppler packages are often already there for
other apps, so the undo leaves them. Delete the scanner's profile in
ScanSnap Home.

## Notes

- `ocrmypdf` would add the text in one command, but it isn't in Arch's
  repos. tesseract, qpdf and poppler are, and Omarchy usually has them
  already.
- The upload only goes one way. The always-on machine never syncs Dropbox
  down, which matters when the folder you scan into sits inside something
  bigger than its disk. rclone writes straight to the one folder, with no
  Dropbox client on that machine at all.
- The Samba password and rclone's Dropbox token stay on the always-on
  machine, in Samba's database and `~/.config/rclone/rclone.conf`. Keep them
  out of any dotfiles repo.
- The user is called `scansnap`, not `scanner`, because Arch already has a
  `scanner` group.
- A Mac browsing the share leaves `.DS_Store` files; the share deletes them,
  or `~/Scans` would never look empty to the path unit.

## History

- Created by [@duff](https://github.com/duff) on 2026-10-31.

## Recipe data

```json
{
  "id": "duff/scansnap-scanner-has-no-mac-to-scan-to",
  "title": "ScanSnap scanner has no Mac or PC to scan to",
  "summary": "Scan to an always-on Linux machine over SMB, make each PDF searchable, upload it to Dropbox, and offer to name it on your desktop.",
  "version": 1,
  "tested_on": {"omarchy": "4.0.5", "hyprland": "0.56.2", "tesseract": "5.5.3", "qpdf": "12.4.2", "poppler": "26.08.0"},
  "applies_to": "A ScanSnap that can scan to a network folder (tested with an iX1600), an always-on Linux machine, and Dropbox.",
  "requires": [],
  "touches": ["~/.config/scansnap/smb.conf", "~/.config/scansnap/upload", "~/.config/scansnap/apply.sh", "~/.config/scansnap/scan-upload.path", "~/.config/scansnap/scan-upload.service", "~/.config/scansnap/scan-upload.timer", "~/.config/systemd/user/scan-upload.path", "~/.config/systemd/user/scan-upload.service", "~/.config/systemd/user/scan-upload.timer", "~/.config/scansnap/arrived", "~/.config/scansnap/name", "~/.config/systemd/user/scan-arrived.path", "~/.config/systemd/user/scan-arrived.service", "~/.config/rclone/rclone.conf", "~/.local/state/scansnap", "~/Scans", "/etc/samba/smb.conf"],
  "root": true,
  "network": true,
  "installs": ["samba", "rclone", "tesseract", "tesseract-data-eng", "qpdf", "poppler"],
  "runs": ["smb.service", "scan-upload.path and scan-upload.timer (systemd user units, kept running by lingering)", "scan-arrived.path (systemd user unit, on the desktop)"],
  "agent_config": false,
  "history": [{"who": "duff", "did": "created", "date": "2026-10-31"}]
}
```
