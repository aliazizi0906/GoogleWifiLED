#!/bin/sh
# Google Wifi RGB LED status indicator for OpenWrt 24.10 / 25.12 and Passwall2.
# Uses Passwall2's own URL test, including virtual Xray/sing-box shunt nodes.
# All LED access goes through the Linux LED class (sysfs); no bootloader changes.

umask 022
CONFIG_FILE=${GWLED_CONFIG:-/etc/googlewifi-led.conf}
[ ! -f "$CONFIG_FILE" ] || . "$CONFIG_FILE"
SYSFS_LEDS_DIR=${SYSFS_LEDS_DIR:-/sys/class/leds}
PW2_TEST_SCRIPT=${PW2_TEST_SCRIPT:-/usr/share/passwall2/test.sh}
CHECK_INTERVAL=${CHECK_INTERVAL:-30}
PROBE_MODE=${PROBE_MODE:-node-test}  # node-test | socks
SOCKS_PORT=${SOCKS_PORT:-1070}
PROBE_URL=${PROBE_URL:-https://www.google.com/generate_204}
GREEN_MAX_MS=${GREEN_MAX_MS:-1099}
YELLOW_MAX_MS=${YELLOW_MAX_MS:-1499}

case "$CHECK_INTERVAL" in ''|*[!0-9]*) CHECK_INTERVAL=30 ;; esac
[ "$CHECK_INTERVAL" -ge 5 ] 2>/dev/null || CHECK_INTERVAL=5
case "$GREEN_MAX_MS" in ''|*[!0-9]*) GREEN_MAX_MS=1099 ;; esac
case "$YELLOW_MAX_MS" in ''|*[!0-9]*) YELLOW_MAX_MS=1499 ;; esac

log() { command -v logger >/dev/null 2>&1 && logger -t googlewifi-led "$*" || :; }

find_channel() {
    wanted=$1
    case "$wanted" in
        red) preferred='LED0_Red led0_red red';;
        green) preferred='LED0_Green led0_green green';;
        blue) preferred='LED0_Blue led0_blue blue';;
    esac
    for p in $preferred; do
        [ -f "$SYSFS_LEDS_DIR/$p/brightness" ] && { printf '%s\n' "$SYSFS_LEDS_DIR/$p"; return 0; }
    done
    for p in "$SYSFS_LEDS_DIR"/*; do
        [ -f "$p/brightness" ] || continue
        name=${p##*/}
        case "$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')" in
            *"$wanted"*) printf '%s\n' "$p"; return 0 ;;
        esac
    done
    return 1
}

load_leds() {
    LED_RED_DIR=${LED_RED_DIR:-$(find_channel red)}
    LED_GREEN_DIR=${LED_GREEN_DIR:-$(find_channel green)}
    LED_BLUE_DIR=${LED_BLUE_DIR:-$(find_channel blue)}
    for ch in "$LED_RED_DIR" "$LED_GREEN_DIR" "$LED_BLUE_DIR"; do
        [ -n "$ch" ] && [ -f "$ch/brightness" ] || return 1
    done
    return 0
}

led_max() {
    val=$(cat "$1/max_brightness" 2>/dev/null)
    case "$val" in ''|*[!0-9]*) val=255 ;; esac
    [ "$val" -ge 1 ] 2>/dev/null || val=255
    printf '%s\n' "$val"
}

led_off_triggers() {
    for ch in "$LED_RED_DIR" "$LED_GREEN_DIR" "$LED_BLUE_DIR"; do
        [ ! -f "$ch/trigger" ] || printf '%s\n' none > "$ch/trigger" 2>/dev/null || :
    done
}

write_channel() {
    ch=$1; scale=$2
    m=$(led_max "$ch")
    v=$((m * scale / 255))
    printf '%s\n' "$v" > "$ch/brightness" 2>/dev/null || :
}

set_rgb() {
    write_channel "$LED_RED_DIR" "$1"
    write_channel "$LED_GREEN_DIR" "$2"
    write_channel "$LED_BLUE_DIR" "$3"
}

red_blink() {
    led_off_triggers
    set_rgb 0 0 0
    if [ -f "$LED_RED_DIR/trigger" ]; then
        if printf '%s\n' timer > "$LED_RED_DIR/trigger" 2>/dev/null; then
            [ ! -f "$LED_RED_DIR/delay_on" ] || printf '%s\n' 500 > "$LED_RED_DIR/delay_on" 2>/dev/null || :
            [ ! -f "$LED_RED_DIR/delay_off" ] || printf '%s\n' 500 > "$LED_RED_DIR/delay_off" 2>/dev/null || :
            write_channel "$LED_RED_DIR" 255
            return 0
        fi
    fi
    return 1
}

# Read selected *top-level* node. Do not substitute shunt.default_node:
# the default route may be '_direct', '_blackhole', a balancing node, etc.
selected_node() {
    node=$(uci -q get 'passwall2.@global[0].node' 2>/dev/null) || node=
    case "$node" in ''|*[!A-Za-z0-9_-]*) return 1 ;; esac
    [ "$(uci -q get "passwall2.${node}" 2>/dev/null)" = nodes ] || return 1
    printf '%s\n' "$node"
}

passwall_enabled() {
    [ "$(uci -q get 'passwall2.@global[0].enabled' 2>/dev/null)" = 1 ]
}

parse_probe() {
    # Official Passwall2 test.sh prints HTTP_CODE:SECONDS. Do not remove
    # the decimal point and mistake an HTTP failure for a 0ms response.
    printf '%s\n' "$1" | awk -F: '
        ($1 == "200" || $1 == "204") && $2 ~ /^[0-9]+([.][0-9]+)?$/ {
            n = int($2 * 1000 + 0.5); found=1
        }
        END { if (found) print n; else print -1 }
    '
}

probe_node() {
    NODE=$(selected_node) || { PROBE_REASON=invalid-node; return 1; }
    [ -f "$PW2_TEST_SCRIPT" ] || { PROBE_REASON=missing-passwall-test; return 1; }
    raw=$(sh "$PW2_TEST_SCRIPT" url_test_node "$NODE" 2>/dev/null)
    ms=$(parse_probe "$raw")
    [ "$ms" -ge 0 ] 2>/dev/null || { PROBE_REASON=failed-node-test; return 1; }
    PROBE_MS=$ms
    PROBE_REASON=node-test
    return 0
}

probe_socks() {
    case "$SOCKS_PORT" in ''|*[!0-9]*) PROBE_REASON=invalid-socks-port; return 1 ;; esac
    [ "$SOCKS_PORT" -ge 1 ] && [ "$SOCKS_PORT" -le 65535 ] || return 1
    command -v curl >/dev/null 2>&1 || { PROBE_REASON=missing-curl; return 1; }
    raw=$(curl --silent --insecure --location --head --connect-timeout 3 --max-time 8 \
        --output /dev/null --write-out '%{http_code}:%{time_starttransfer}' \
        --proxy "socks5h://127.0.0.1:$SOCKS_PORT" "$PROBE_URL" 2>/dev/null)
    ms=$(parse_probe "$raw")
    [ "$ms" -ge 0 ] 2>/dev/null || { PROBE_REASON=failed-socks-probe; return 1; }
    PROBE_MS=$ms
    PROBE_REASON=socks
    return 0
}

read_state() {
    PROBE_MS=-1
    PROBE_REASON=none
    if ! passwall_enabled; then
        STATE=disabled
        PROBE_REASON=passwall-disabled
        return
    fi
    case "$PROBE_MODE" in
        node-test) probe_node || : ;;
        socks) probe_socks || : ;;
        *) PROBE_REASON=invalid-probe-mode ;;
    esac
    if [ "$PROBE_MS" -lt 0 ]; then
        STATE=unreachable
    elif [ "$PROBE_MS" -le "$GREEN_MAX_MS" ]; then
        STATE=green
    elif [ "$PROBE_MS" -le "$YELLOW_MAX_MS" ]; then
        STATE=yellow
    else
        STATE=red
    fi
}

fade() {
    r=$1; g=$2; b=$3
    for scale in 0 40 80 120 160 200 255 200 160 120 80 40 0; do
        set_rgb "$((r * scale / 255))" "$((g * scale / 255))" "$((b * scale / 255))"
        sleep 0.13
    done
}

rainbow() {
    led_off_triggers
    fade 255 0 0
    fade 0 255 0
    fade 0 0 255
    fade 255 0 255
    fade 255 255 0
    fade 255 255 255
}

apply_state() {
    case "$STATE" in
        green) led_off_triggers; set_rgb 0 255 0 ;;
        yellow) led_off_triggers; set_rgb 255 255 0 ;;
        red) led_off_triggers; set_rgb 255 0 0 ;;
        unreachable) red_blink || return 2 ;;
        disabled) rainbow ;;
    esac
    return 0
}

cleanup() {
    if load_leds; then led_off_triggers; set_rgb 0 0 0; fi
}

run_daemon() {
    load_leds || { log 'Cannot find all three RGB LED channels; daemon not started.'; exit 1; }
    trap 'cleanup; exit 0' INT TERM
    trap 'cleanup' EXIT
    old_state=''
    old_reason=''
    while :; do
        read_state
        if [ "$STATE" != "$old_state" ] || [ "$PROBE_REASON" != "$old_reason" ]; then
            log "state=$STATE reason=$PROBE_REASON node=${NODE:-none} latency_ms=$PROBE_MS"
            old_state=$STATE
            old_reason=$PROBE_REASON
        fi
        case "$STATE" in
            disabled) rainbow ;;  # stop breathing immediately on next loop (about 10s)
            *)
                if ! apply_state; then
                    # For kernels without the LED timer trigger, blink in userspace.
                    i=0
                    while [ "$i" -lt "$CHECK_INTERVAL" ]; do
                        set_rgb 255 0 0; sleep 0.5
                        set_rgb 0 0 0; sleep 0.5
                        i=$((i+1))
                    done
                else
                    sleep "$CHECK_INTERVAL"
                fi
                ;;
        esac
    done
}

case "${1:-daemon}" in
    daemon) run_daemon ;;
    led-check)
        if load_leds; then
            printf 'red=%s green=%s blue=%s\n' "$LED_RED_DIR" "$LED_GREEN_DIR" "$LED_BLUE_DIR"
        else
            echo 'Missing red/green/blue LED channel. Adjust LED_*_DIR in /etc/googlewifi-led.conf.' >&2
            exit 1
        fi
        ;;
    probe)
        read_state
        printf 'state=%s\nreason=%s\nnode=%s\nlatency_ms=%s\n' "$STATE" "$PROBE_REASON" "${NODE:-none}" "$PROBE_MS"
        [ "$STATE" != unreachable ]
        ;;
    led-test)
        load_leds || exit 1
        trap 'cleanup' EXIT
        led_off_triggers
        set_rgb 255 0 0; sleep 2
        set_rgb 0 255 0; sleep 2
        set_rgb 0 0 255; sleep 2
        set_rgb 255 255 255; sleep 2
        cleanup
        ;;
    *) echo 'Usage: googlewifi-led.sh [daemon|probe|led-check|led-test]' >&2; exit 2 ;;
esac
