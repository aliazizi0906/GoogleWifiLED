# GoogleWifiLED — Google Wifi RGB LED status for OpenWrt 25.12

[فارسی](#راهنمای-فارسی) · [English](#english-guide) · [Installation / نصب](docs/INSTALL.fa.md) · [Troubleshooting / عیب‌یابی](docs/TROUBLESHOOTING.fa.md) · [Original project](https://github.com/amirhosseinchoghaei/GoogleWifiLED)

GoogleWifiLED controls Google Wifi's RGB LED ring according to the **selected Passwall2 node's HTTP URL-test result**, including Xray / sing-box **Shunt** (`_shunt`). This is a community compatibility rewrite targeting **OpenWrt 25.12**, also intended for 24.10. It installs as a lightweight shell **procd service**, not an `.apk`/`.ipk` package.

> **Testing:** shell/mock tests pass, but OpenWrt 25.12 on physical Google Wifi hardware has **not yet been validated**. A blinking red LED signifies an unsuccessful probe, **not necessarily that all network access is down**.

## راهنمای فارسی

### نصب مستقیم از GitHub — بدون نیاز به Git

از طریق SSH با کاربر `root` روی روتر اجرا کنید:

```sh
curl -fL https://raw.githubusercontent.com/aliazizi0906/GoogleWifiLED/main/bootstrap.sh -o /tmp/googlewifi-led-bootstrap.sh
sh /tmp/googlewifi-led-bootstrap.sh
```

`bootstrap.sh` کل سورس ریپو را دانلود و استخراج می‌کند، سپس `install.sh` را با پوشهٔ ضروری `files/` اجرا می‌کند. **`install.sh` را به‌تنهایی از لینک Raw اجرا نکنید**؛ به فایل‌های همراه نیاز دارد. پیش از اجرا می‌توانید محتویات bootstrap دانلودشده را بخوانید.

اگر `curl` نصب نیست، برای دریافت bootstrap از `wget` استفاده کنید:

```sh
wget -O /tmp/googlewifi-led-bootstrap.sh https://raw.githubusercontent.com/aliazizi0906/GoogleWifiLED/main/bootstrap.sh
sh /tmp/googlewifi-led-bootstrap.sh
```

### نصب با Git Clone

```sh
cd /tmp
git clone --depth 1 https://github.com/aliazizi0906/GoogleWifiLED.git
cd GoogleWifiLED
sh install.sh
```

آپدیت از همان کلون (تا وقتی کلون وجود دارد): `git pull --ff-only` سپس `sh install.sh`. مسیر `/tmp` بعد از ریبوت پاک می‌شود، ولی سرویس نصب‌شده دائمی است؛ برای آپدیت بدون Git دو دستور نصب مستقیم را دوباره اجرا کنید.

### بررسی وضعیت

```sh
/etc/init.d/googlewifi-led status
sh /usr/libexec/googlewifi-led/googlewifi-led.sh probe
logread -e googlewifi-led
```

| رنگ LED | معنی |
| --- | --- |
| 🟢 سبز ثابت | تست URL موفق، کمتر از 1100 میلی‌ثانیه |
| 🟡 زرد ثابت | موفق، 1100–1499 میلی‌ثانیه |
| 🔴 قرمز ثابت | موفق، 1500 میلی‌ثانیه یا بالاتر |
| 🔴 قرمز چشمک‌زن | تست URL ناموفق یا پاسخ نامعتبر |
| 🌈 چرخهٔ رنگ‌ها | Passwall2 در تنظیمات غیرفعال است |

این **تست URL پروکسی** است، نه ping از نوع ICMP و نه تضمین صحت همهٔ قوانین Shunt.

**راهنماها:** [نصب و آپدیت و حذف (فارسی)](docs/INSTALL.fa.md) · [عیب‌یابی (فارسی)](docs/TROUBLESHOOTING.fa.md)

## English guide

### Quick install from GitHub (Git is NOT required)

SSH into OpenWrt as `root`:

```sh
curl -fL https://raw.githubusercontent.com/aliazizi0906/GoogleWifiLED/main/bootstrap.sh -o /tmp/googlewifi-led-bootstrap.sh
sh /tmp/googlewifi-led-bootstrap.sh
```

The bootstrap downloads the **complete source archive**, extracts it and invokes the adjacent `install.sh`. Downloading `install.sh` alone does **not** work: it needs the `files/` directory. Review the fetched script before running it. The initial download may use `wget -O ...` instead of curl.

### Install with Git

```sh
cd /tmp
git clone --depth 1 https://github.com/aliazizi0906/GoogleWifiLED.git
cd GoogleWifiLED
sh install.sh
```

Within an existing clone: `git pull --ff-only` and `sh install.sh`. The installed service survives reboot; however, the temporary Git clone in `/tmp` does not. Re-run Quick Install when you don't have a checkout.

### Verify

```sh
/etc/init.d/googlewifi-led status
sh /usr/libexec/googlewifi-led/googlewifi-led.sh probe
logread -e googlewifi-led
```

**Guides:** [Install/update/uninstall (English)](docs/INSTALL.en.md) · [Troubleshooting (English)](docs/TROUBLESHOOTING.en.md)

## Requirements

- Google Wifi (or compatible device) exposing three RGB LED channels via `/sys/class/leds`.
- OpenWrt 25.12 / 24.10 with `procd`; an installed Passwall2 including `/usr/share/passwall2/test.sh`.
- `curl` or `wget` and GitHub HTTPS connectivity to install online. `git` is optional.
- The installer **does not call apk or opkg**, does not alter Passwall2 configuration, preserves `/etc/googlewifi-led.conf` on reinstall, and removes only the known legacy `rc.local` LED startup command after taking a backup.

## Settings and service

```sh
vi /etc/googlewifi-led.conf
/etc/init.d/googlewifi-led restart
/etc/init.d/googlewifi-led stop
/etc/init.d/googlewifi-led start
/etc/init.d/googlewifi-led enable
```

Defaults: `PROBE_MODE=node-test`, `CHECK_INTERVAL=30`, `GREEN_MAX_MS=1099`, `YELLOW_MAX_MS=1499`. Default mode uses Passwall2's own selected-node test, including Shunt. Alternative `PROBE_MODE=socks` requires an **already running** local SOCKS proxy with `SOCKS_PORT`; its path may differ from LAN Shunt traffic.

## Repository layout

| Path | Purpose |
| --- | --- |
| `bootstrap.sh` | Fetch complete source from GitHub and install |
| `install.sh` / `uninstall.sh` | Install / remove procd service |
| `files/googlewifi-led.sh` | LED logic and Passwall2 URL probe |
| `files/googlewifi-led.init` | OpenWrt procd service |
| `files/googlewifi-led.conf` | Default configuration |
| `docs/` | Bilingual install and troubleshooting |
| `tests/run-tests.sh` | Mock/portable shell tests |

Run tests: `sh tests/run-tests.sh`. Hardware validation is still needed.

## Contributing and attribution

See [CONTRIBUTING.md](CONTRIBUTING.md) and [CHANGELOG.md](CHANGELOG.md). Based on the ideas of [amirhosseinchoghaei/GoogleWifiLED](https://github.com/amirhosseinchoghaei/GoogleWifiLED) and Passwall2's [official test interface](https://github.com/Openwrt-Passwall/openwrt-passwall2). The upstream project's license is not specified; do not assume third-party code is freely relicensable.
