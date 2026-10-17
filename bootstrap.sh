#!/bin/sh
# Install from a complete GitHub source archive; install.sh needs files/.
set -eu
umask 077

[ "$(id -u)" -eq 0 ] || { echo 'ERROR: run as root.' >&2; exit 1; }
[ -d /etc/init.d ] || { echo 'ERROR: OpenWrt init directory missing.' >&2; exit 1; }

WORKDIR=$(mktemp -d /tmp/googlewifi-led.XXXXXX) || exit 1
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT
trap 'exit 1' HUP INT TERM
ARCHIVE_URL=https://github.com/aliazizi0906/GoogleWifiLED/archive/refs/heads/main.tar.gz
ARCHIVE="$WORKDIR/source.tar.gz"

echo 'Downloading complete GoogleWifiLED source from GitHub...'
if command -v curl >/dev/null 2>&1; then
    curl -fL --connect-timeout 15 --max-time 120 -o "$ARCHIVE" "$ARCHIVE_URL"
elif command -v wget >/dev/null 2>&1; then
    wget -O "$ARCHIVE" "$ARCHIVE_URL"
else
    echo 'ERROR: curl or wget is required.' >&2
    exit 1
fi

[ -s "$ARCHIVE" ] || { echo 'ERROR: downloaded archive is empty.' >&2; exit 1; }
tar -xzf "$ARCHIVE" -C "$WORKDIR" || { echo 'ERROR: archive extraction failed.' >&2; exit 1; }
SOURCE="$WORKDIR/GoogleWifiLED-main"
[ -f "$SOURCE/install.sh" ] || { echo 'ERROR: install.sh missing.' >&2; exit 1; }
[ -f "$SOURCE/files/googlewifi-led.sh" ] || { echo 'ERROR: files/ directory incomplete.' >&2; exit 1; }

/bin/sh "$SOURCE/install.sh"
echo 'Installed GoogleWifiLED; inspect: /etc/init.d/googlewifi-led status'
