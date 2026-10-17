#!/bin/sh
# Offline installer: extract archive on the router and run `sh install.sh`.
set -eu
BASE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DEST=/usr/libexec/googlewifi-led
INIT=/etc/init.d/googlewifi-led
CONF=/etc/googlewifi-led.conf

[ "$(id -u)" = 0 ] || { echo 'ERROR: run as root.' >&2; exit 1; }
[ -f "$BASE/files/googlewifi-led.sh" ] || { echo 'ERROR: files/ directory missing.' >&2; exit 1; }
[ -d /etc/init.d ] || { echo 'ERROR: /etc/init.d missing. Run on OpenWrt.' >&2; exit 1; }

# Never alter boot configuration if this is not a Google Wifi RGB system.
if ! SYSFS_LEDS_DIR=${SYSFS_LEDS_DIR:-/sys/class/leds} /bin/sh "$BASE/files/googlewifi-led.sh" led-check; then
    echo 'ERROR: RGB LEDs not detected. Configure LED_*_DIR and retry.' >&2
    exit 1
fi

mkdir -p "$DEST"
[ ! -x "$INIT" ] || "$INIT" stop || :
cp "$BASE/files/googlewifi-led.sh" "$DEST/googlewifi-led.sh"
chmod 755 "$DEST/googlewifi-led.sh"
if [ ! -f "$CONF" ]; then
    cp "$BASE/files/googlewifi-led.conf" "$CONF"
    chmod 644 "$CONF"
else
    echo "Keeping existing $CONF"
fi
cp "$BASE/files/googlewifi-led.init" "$INIT"
chmod 755 "$INIT"

# Retire only the exact line injected by the original installer.
if [ -f /etc/rc.local ] && grep -Eq '^[[:space:]]*/usr/local/LED/led\.sh[[:space:]]*&[[:space:]]*$' /etc/rc.local; then
    cp -p /etc/rc.local "/etc/rc.local.googlewifi-led-backup-$(date +%Y%m%d%H%M%S)"
    sed -i '\|^[[:space:]]*/usr/local/LED/led\.sh[[:space:]]*\&[[:space:]]*$|d' /etc/rc.local
    echo 'Disabled legacy /usr/local/LED/led.sh rc.local entry (backup saved).'
fi
# Terminate only the old GoogleWifiLED script processes; never kill Xray/sing-box.
for proc in /proc/[0-9]*/cmdline; do
    [ -r "$proc" ] || continue
    command_line=$(tr '\000' ' ' < "$proc" 2>/dev/null) || continue
    case "$command_line" in
        *'/usr/local/LED/led.sh'*|*'/usr/local/LED/shoe.sh'*|*'/usr/local/LED/choe.sh'*)
            pid=${proc#/proc/}; pid=${pid%/cmdline}
            [ "$pid" = "$$" ] || kill "$pid" 2>/dev/null || :
            ;;
    esac
done

"$INIT" enable
"$INIT" start
printf '\nGoogleWifiLED installed. Try:\n  /etc/init.d/googlewifi-led status\n  sh %s probe\n  logread -e googlewifi-led\n' "$DEST/googlewifi-led.sh"
