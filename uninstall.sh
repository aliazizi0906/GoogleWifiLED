#!/bin/sh
set -eu
[ "$(id -u)" = 0 ] || { echo 'Run as root' >&2; exit 1; }
if [ -f /etc/init.d/googlewifi-led ]; then
    /etc/init.d/googlewifi-led stop || :
    /etc/init.d/googlewifi-led disable || :
    rm -f /etc/init.d/googlewifi-led
fi
rm -rf /usr/libexec/googlewifi-led
# Preserve /etc/googlewifi-led.conf and original /usr/local/LED directory.
# Do not restore the old rc.local boot hook: it contains the obsolete daemon.
echo 'GoogleWifiLED removed. /etc/googlewifi-led.conf retained.'
