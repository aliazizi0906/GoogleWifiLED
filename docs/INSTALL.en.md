# GoogleWifiLED — Installation, updating and removal (English)

[README](../README.md) · [فارسی](INSTALL.fa.md) · [Troubleshooting](TROUBLESHOOTING.en.md)

## Requirements

Google Wifi RGB hardware exposing red/green/blue channels under `/sys/class/leds`; OpenWrt 25.12 or 24.10 with `procd`; root SSH; Passwall2 including `/usr/share/passwall2/test.sh`. Online install needs HTTPS access to GitHub and **curl or wget**; **Git is optional**.

Preflight checks:

```sh
ls /sys/class/leds
uci -q get 'passwall2.@global[0].enabled'
uci -q get 'passwall2.@global[0].node'
```

## Method 1: direct GitHub installer (recommended, no Git)

Run as root over SSH:

```sh
curl -fL https://raw.githubusercontent.com/aliazizi0906/GoogleWifiLED/main/bootstrap.sh -o /tmp/googlewifi-led-bootstrap.sh
sh /tmp/googlewifi-led-bootstrap.sh
```

The first command downloads a reviewable bootstrap file. Bootstrap downloads the **complete repository main-branch tarball**, extracts it in a disposable temporary directory, and runs the bundled `install.sh` with its required `files/` directory. If curl is absent, try:

```sh
wget -O /tmp/googlewifi-led-bootstrap.sh https://raw.githubusercontent.com/aliazizi0906/GoogleWifiLED/main/bootstrap.sh
sh /tmp/googlewifi-led-bootstrap.sh
```

Some BusyBox wget/TLS builds may have HTTPS/redirect issues; use curl or offline transfer in that case. **Do not fetch and execute `install.sh` alone**: it relies on adjacent source files.

## Method 2: Git clone

```sh
cd /tmp
git clone --depth 1 https://github.com/aliazizi0906/GoogleWifiLED.git
cd GoogleWifiLED
sh install.sh
```

To update an existing checkout:

```sh
cd /tmp/GoogleWifiLED
git pull --ff-only
sh install.sh
```

The checkout under `/tmp` disappears after reboot, **but the installed service survives** because scripts live in persistent OpenWrt paths. Re-run Method 1 to update without retaining a Git clone. Git on flash-constrained routers is usually unnecessary.

## Method 3: offline / WinSCP

Download the full [GitHub main ZIP](https://github.com/aliazizi0906/GoogleWifiLED/archive/refs/heads/main.zip) on your computer; extract and copy the **whole source folder**, including `files/`, to the router as `/tmp/GoogleWifiLED` via SCP/WinSCP.

```sh
cd /tmp/GoogleWifiLED
sh install.sh
```

## Verify

```sh
/etc/init.d/googlewifi-led status
sh /usr/libexec/googlewifi-led/googlewifi-led.sh led-check
sh /usr/libexec/googlewifi-led/googlewifi-led.sh probe
logread -e googlewifi-led
```

The probe reports `state`, `reason`, `node`, `latency_ms`. Solid green = successful URL test under 1100ms; solid yellow = 1100–1499ms; solid red = 1500ms or longer; flashing red = failure; cycling RGB = Passwall2 disabled. URL-test latency is **not ICMP ping**, nor does it prove all Shunt routes function for every LAN client.

## Service, configuration and hardware test

```sh
vi /etc/googlewifi-led.conf
/etc/init.d/googlewifi-led restart
/etc/init.d/googlewifi-led stop
/etc/init.d/googlewifi-led start
/etc/init.d/googlewifi-led enable
```

Defaults:

```sh
PROBE_MODE=node-test
CHECK_INTERVAL=30
GREEN_MAX_MS=1099
YELLOW_MAX_MS=1499
```

`node-test` runs Passwall2's official selected-node URL test, including the top-level Shunt node; this may spawn temporary SOCKS processes. `PROBE_MODE=socks` and `SOCKS_PORT=<your-port>` instead test an **already-running** local SOCKS listener, whose route may differ from LAN's Shunt routing. Restart service after editing config.

For an isolated LED hardware test:

```sh
/etc/init.d/googlewifi-led stop
sh /usr/libexec/googlewifi-led/googlewifi-led.sh led-test
/etc/init.d/googlewifi-led start
```

## Updates and uninstall

Repeat Method 1 to upgrade without Git. Existing `/etc/googlewifi-led.conf` is preserved and service restarted. No reboot is needed.

To uninstall, run `sh uninstall.sh` from the checkout, or without checkout:

```sh
curl -fL https://raw.githubusercontent.com/aliazizi0906/GoogleWifiLED/main/uninstall.sh -o /tmp/googlewifi-led-uninstall.sh
sh /tmp/googlewifi-led-uninstall.sh
```

Uninstall removes the new service and executable but **keeps** its config and the previous `/usr/local/LED` directory. It does not restore obsolete `rc.local` hooks. Installer retires only the known legacy rc.local LED autostart line after backing up rc.local, never reconfiguring Passwall2.

[Read troubleshooting](TROUBLESHOOTING.en.md).
