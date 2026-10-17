# Troubleshooting GoogleWifiLED — English

[README](../README.md) · [Install](INSTALL.en.md) · [فارسی](TROUBLESHOOTING.fa.md)

## First diagnostics

```sh
/etc/init.d/googlewifi-led status
sh /usr/libexec/googlewifi-led/googlewifi-led.sh probe
sh /usr/libexec/googlewifi-led/googlewifi-led.sh led-check
logread -e googlewifi-led
uci -q get 'passwall2.@global[0].node'
uci -q get 'passwall2.@global[0].enabled'
ls /sys/class/leds
```

**Blinking red means URL-test failure, not proof that all internet traffic is down.**

| reason | Meaning | Action |
| --- | --- | --- |
| `passwall-disabled` | Passwall2 disabled | Check global enabled option |
| `invalid-node` | Invalid or deleted selected node | Check selected node in Passwall2 |
| `missing-passwall-test` | Passwall2 test.sh is absent | Verify Passwall2 installation |
| `failed-node-test` | URL test failed/invalid | Test node in LuCI; inspect logs/DNS/temporary SOCKS |
| `failed-socks-probe` | SOCKS/URL test failed | Verify listener and port |
| `missing-curl` | curl unavailable in SOCKS mode | Install compatible curl |
| `invalid-probe-mode` | Invalid PROBE_MODE | Choose node-test or socks |
| `invalid-socks-port` | Invalid SOCKS_PORT | Use numeric port 1..65535 |

## Continuously blinking red

```sh
sh /usr/libexec/googlewifi-led/googlewifi-led.sh probe
ls -l /usr/share/passwall2/test.sh
uci -q get 'passwall2.@global[0].node'
logread -e passwall2
```

If `reason=failed-node-test`, test the same node within Passwall2's LuCI interface. For Shunt, the **top-level Shunt** node is used, not automatically replaced by `default_node`. HTTP reachability, DNS, temporary SOCKS startup, a different test URL, or Passwall2 forks may affect results.

## LED channels missing/wrong colors

```sh
ls /sys/class/leds
/etc/init.d/googlewifi-led stop
sh /usr/libexec/googlewifi-led/googlewifi-led.sh led-test
/etc/init.d/googlewifi-led start
```

Override `LED_RED_DIR`, `LED_GREEN_DIR`, `LED_BLUE_DIR` in `/etc/googlewifi-led.conf` with the actual LED sysfs directories. Installer aborts **before changing boot services** if initial LED detection fails; copy default config from `files/googlewifi-led.conf` then configure paths before reinstalling.

## Download errors

Check GitHub HTTPS to `raw.githubusercontent.com` and `github.com`. If blocked, copy the complete source tree (including `files/`) via SCP/WinSCP as described in [offline install](INSTALL.en.md#method-3-offline--winscp).

## Service or old-version conflict

```sh
/etc/init.d/googlewifi-led restart
/etc/init.d/googlewifi-led status
logread -e googlewifi-led
grep -n 'usr/local/LED/led.sh' /etc/rc.local
```

Installer backs up rc.local before removing only the recognized legacy autostart line, retains legacy files, and terminates only known old LED processes. It does not intentionally stop xray, sing-box, or Passwall2.

## Bug report

Include `cat /etc/openwrt_release`, `probe`, `led-check`, and `logread -e googlewifi-led` in a [GitHub issue](https://github.com/aliazizi0906/GoogleWifiLED/issues). **Redact credentials, node URLs, private keys, and sensitive IP addresses** before posting.
