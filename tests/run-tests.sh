#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT HUP INT TERM
mkdir -p "$TMP/leds" "$TMP/bin"
for color in Red Green Blue; do
    mkdir -p "$TMP/leds/LED0_$color"
    printf '0\n' > "$TMP/leds/LED0_$color/brightness"
    printf '255\n' > "$TMP/leds/LED0_$color/max_brightness"
    printf 'none\n' > "$TMP/leds/LED0_$color/trigger"
    printf '0\n' > "$TMP/leds/LED0_$color/delay_on"
    printf '0\n' > "$TMP/leds/LED0_$color/delay_off"
done
cat > "$TMP/bin/uci" <<'MOCK_UCI'
#!/bin/sh
[ "$1" = '-q' ] && shift
[ "$1" = 'get' ] && shift
case "$1" in
  'passwall2.@global[0].enabled') printf '%s\n' "${MOCK_ENABLED:-1}" ;;
  'passwall2.@global[0].node') printf '%s\n' "${MOCK_NODE:-shunt_test}" ;;
  'passwall2.shunt_test') echo nodes ;;
  'passwall2.plain_test') echo nodes ;;
  *) exit 1 ;;
esac
MOCK_UCI
cat > "$TMP/pwtest.sh" <<'MOCK_PASSWALL'
#!/bin/sh
[ "$1" = url_test_node ] || exit 8
[ "$2" = "${MOCK_NODE:-shunt_test}" ] || exit 9
printf '%s\n' "$2" > "$MOCK_NODE_SEEN"
printf '%s\n' "${MOCK_RESPONSE:-204:0.340}"
MOCK_PASSWALL
chmod +x "$TMP/bin/uci" "$TMP/pwtest.sh"
cat > "$TMP/config" <<EOC
SYSFS_LEDS_DIR=$TMP/leds
PW2_TEST_SCRIPT=$TMP/pwtest.sh
PROBE_MODE=node-test
CHECK_INTERVAL=5
EOC
export PATH="$TMP/bin:$PATH"
export GWLED_CONFIG="$TMP/config"
export MOCK_NODE_SEEN="$TMP/node_seen"
S="$ROOT/files/googlewifi-led.sh"

expect_state() {
    expected=$1
    output=$(sh "$S" probe 2>/dev/null) || :
    actual=$(printf '%s\n' "$output" | sed -n 's/^state=//p')
    [ "$actual" = "$expected" ] || { echo "FAIL: expected=$expected actual=$actual output=$output"; exit 1; }
    echo "PASS: $expected"
}
export MOCK_ENABLED=0
expect_state disabled
export MOCK_ENABLED=1 MOCK_NODE=shunt_test MOCK_RESPONSE=204:0.350
expect_state green
[ "$(cat "$MOCK_NODE_SEEN")" = shunt_test ] || { echo 'FAIL: Shunt was unwrapped'; exit 1; }
export MOCK_RESPONSE=200:1.120
expect_state yellow
export MOCK_RESPONSE=200:1.800
expect_state red
export MOCK_RESPONSE=000:0.100
expect_state unreachable
export MOCK_RESPONSE='empty response'
expect_state unreachable
export MOCK_NODE='shunt;rm -rf /'
expect_state unreachable
export MOCK_NODE=plain_test MOCK_RESPONSE=204:0.000
expect_state green
sh "$S" led-check >/dev/null
[ -n "$(sh "$S" led-check)" ] || exit 1

# Validate 1-bit brightness scaling and sysfs-trigger writes in a smoke test.
for color in Red Green Blue; do echo 1 > "$TMP/leds/LED0_$color/max_brightness"; done
# run led-test with a mock sleep for quick feedback.
cat > "$TMP/bin/sleep" <<'MOCK_SLEEP'
#!/bin/sh
exit 0
MOCK_SLEEP
chmod +x "$TMP/bin/sleep"
sh "$S" led-test
[ "$(cat "$TMP/leds/LED0_Red/brightness")" = 0 ] || exit 1
[ "$(cat "$TMP/leds/LED0_Green/brightness")" = 0 ] || exit 1
[ "$(cat "$TMP/leds/LED0_Blue/brightness")" = 0 ] || exit 1
printf 'ALL TESTS PASSED\n'
