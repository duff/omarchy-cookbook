#!/bin/bash
# The always-on machine takes scans from the ScanSnap and sends them to
# Dropbox. The scanner saves PDFs to the Samba share "scans" (~/Scans),
# signing in as the scanner-only Samba user "scansnap". As each lands,
# scan-upload.path runs ./upload, which numbers them by day, adds a searchable
# text layer and moves them to Dropbox with rclone, so nothing stays here and
# nothing is downloaded. The rclone remote "dropbox" keeps its token in
# ~/.config/rclone.
#
# Run it from a terminal: the first run asks for your password and for a
# password for the scanner.
set -euo pipefail

# Your home network, the only place the share answers.
lan=192.0.2.0/24

here=$(cd "$(dirname "$0")" && pwd)
units="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"

[[ -f $here/smb.conf && -f $here/scan-upload.service && -f $here/scan-upload.path && -f $here/scan-upload.timer && -x $here/upload ]]

mkdir -p "$HOME/Scans"

smb_conf=$(mktemp)
trap 'rm -f "$smb_conf"' EXIT
sed -e "s|@USER@|$USER|g" -e "s|@LAN@|$lan|g" "$here/smb.conf" >"$smb_conf"
chmod 644 "$smb_conf"

# What ./upload needs to add text.
omarchy pkg add tesseract tesseract-data-eng qpdf poppler

# Root's part. Skipped once it is in place, so running this again doesn't
# ask for a password.
if ! { cmp -s "$smb_conf" /etc/samba/smb.conf && id scansnap &>/dev/null &&
  systemctl is-active -q smb && [[ $(loginctl show-user "$USER" -p Linger --value) == yes ]]; }; then
  omarchy pkg add samba rclone
  sudo bash -c '
    set -euo pipefail
    conf=$1 user=$2 lan=$3
    testparm -s "$conf" >/dev/null
    install -Dm644 "$conf" /etc/samba/smb.conf
    # Not "scanner": Arch already has a group by that name.
    id scansnap &>/dev/null || useradd --system --no-create-home --shell /usr/bin/nologin scansnap
    if ! grep -q "^scansnap:" <<<"$(pdbedit -L)"; then
      echo "Choose a password for the scanner. You type it into its network folder profile."
      smbpasswd -a scansnap
    fi
    ufw allow from "$lan" to any port 445 proto tcp comment "ScanSnap to Samba" >/dev/null
    systemctl enable smb
    systemctl reload-or-restart smb
    # Run the upload service whether or not anyone is logged in.
    loginctl enable-linger "$user"
  ' bash "$smb_conf" "$USER" "$lan"
fi

mkdir -p "$units"
cp "$here/scan-upload.service" "$here/scan-upload.path" "$here/scan-upload.timer" "$units/"
systemctl --user daemon-reload
systemctl --user enable --now scan-upload.path scan-upload.timer

if ! rclone listremotes 2>/dev/null | grep -qx 'dropbox:'; then
  echo "Scans wait in ~/Scans until rclone can reach Dropbox. Connect it once:"
  echo "  rclone config create dropbox dropbox"
fi
