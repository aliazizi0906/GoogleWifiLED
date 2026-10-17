# GoogleWifiLED for OpenWrt 25.12

Community compatibility rewrite inspired by [amirhosseinchoghaei/GoogleWifiLED](https://github.com/amirhosseinchoghaei/GoogleWifiLED). It controls Google Wifi's RGB ring based on the health of the **selected Passwall2 node**, including Xray/sing-box **Shunt** (`_shunt`). This is a set of POSIX shell scripts, not an `.apk` or `.ipk` package. Tested with mocks and syntax checks; hardware validation is required.

## فارسی — راهنمای نصب

### چه مشکلی حل شده؟

* نسخه قدیمی نصب را با `opkg` انجام می‌داد؛ OpenWrt 25.12 از `apk` استفاده می‌کند. نسخه جدید **نیاز به نصب coreutils-sleep ندارد** و روی 24.10 هم کار می‌کند.
* `get.sh` قدیمی، `default_node` داخل Shunt را جای نود انتخاب‌شده برمی‌گرداند؛ این کار قوانین Shunt را نادیده می‌گرفت یا اگر `_direct` انتخاب می‌شد، تست خراب می‌شد. نسخه جدید **خود نود اصلی** را به تست رسمی Passwall2 می‌دهد.
* خروجی `HTTP_CODE:SECONDS` را درست به میلی‌ثانیه تبدیل می‌کند و دیگر پاسخ نامعتبر را پینگ صفر حساب نمی‌کند.
* به‌جای اجرای دائمی از `rc.local`، سرویس `procd` استاندارد دارد، بعد از ریبوت خودکار بالا می‌آید، لاگ می‌دهد و زمان خاموش شدن LED را پاک‌سازی می‌کند.

### نصب آفلاین (پیشنهادی)

1. فایل `GoogleWifiLED-OpenWrt25.tar.gz` را دانلود کن و با WinSCP/SCP به `/tmp` روتر منتقل کن.
2. با SSH به روتر وصل شو و دستورات زیر را اجرا کن:

```sh
cd /tmp
tar -xzf GoogleWifiLED-OpenWrt25.tar.gz
cd GoogleWifiLED-OpenWrt25
sh install.sh
```

**نیازی به `reboot` نیست.** اگر قبلاً نسخه قدیمی نصب بوده، installer خط مشخص قدیمی را از `/etc/rc.local` حذف می‌کند، از فایل پشتیبان می‌گیرد و پردازش‌های قدیمی همان پکیج را می‌بندد. فایل‌های قدیمی داخل `/usr/local/LED` حذف نمی‌شوند.

### رنگ‌ها و معنا

| رنگ | معنی |
| --- | --- |
| سبز ثابت | Passwall2 فعال؛ تست URL موفق و latency کمتر از 1100 ms |
| زرد ثابت | تست موفق؛ 1100 تا 1499 ms |
| قرمز ثابت | تست موفق؛ 1500 ms یا بیشتر |
| قرمز چشمک‌زن | تست ناموفق/پاسخ نامعتبر/عدم امکان تست نود |
| چرخه رنگی | Passwall2 در تنظیمات غیرفعال است |

این رنگ‌ها نتیجه **تست URL پروکسی** هستند، نه پینگ ICMP، و لزوماً وضعیت تک‌تک قوانین مسیریابی Shunt برای همهٔ دامنه‌ها را تضمین نمی‌کنند.

### تست و عیب‌یابی

```sh
# ابتدا ببین LEDهای RGB توسط کرنل شناسایی شده‌اند
sh /usr/libexec/googlewifi-led/googlewifi-led.sh led-check

# وضعیت و دلیل خطا؛ بدون تغییر چراغ‌ها
sh /usr/libexec/googlewifi-led/googlewifi-led.sh probe

# مشاهده رویدادهای سرویس
logread -e googlewifi-led

# مشاهده نود اصلی Passwall2 و نوع آن
uci -q get 'passwall2.@global[0].node'
uci -q get "passwall2.$(uci -q get 'passwall2.@global[0].node').protocol"

# خاموش و روشن کردن سرویس
/etc/init.d/googlewifi-led restart
/etc/init.d/googlewifi-led stop
/etc/init.d/googlewifi-led start

# تست قرمز، سبز، آبی، سفید (بعد از آن LED خاموش می‌شود)
/etc/init.d/googlewifi-led stop
sh /usr/libexec/googlewifi-led/googlewifi-led.sh led-test
/etc/init.d/googlewifi-led start
```

اگر `probe` مقدار `reason=failed-node-test` داد، همان نود را در LuCI > Services > Passwall2 نیز تست کن. **قرمز چشمک‌زن الزاماً به معنی قطع اینترنت نیست**: مثلاً تست URL، DNS، CA، یا تنظیمات خود Shunt می‌تواند باعث آن شود. خروجی `reason=invalid-node` یعنی انتخاب نود اصلی Passwall2 قابل شناسایی نیست. اگر کانال‌های LED پیدا نشدند، نام‌های موجود در `ls /sys/class/leds` را ببین و مسیرها را در `/etc/googlewifi-led.conf` وارد کن.

### تنظیمات

`/etc/googlewifi-led.conf` پس از نصب قابل ویرایش است. تنظیمات پیش‌فرض:

```sh
PROBE_MODE=node-test
CHECK_INTERVAL=30
GREEN_MAX_MS=1099
YELLOW_MAX_MS=1499
```

حالت `node-test` از `/usr/share/passwall2/test.sh url_test_node <selected-node>` استفاده می‌کند؛ بنابراین **خود Passwall2 و ابزار curl مورد نیاز Passwall2 باید نصب و سالم باشند**. این تست ممکن است یک پراکسی SOCKS موقتی راه‌اندازی کند؛ فاصله ۳۰ ثانیه‌ای برای کاهش بار در نظر گرفته شده است. اگر می‌خواهی یک SOCKS محلی از پیش فعال را تست کنی، `PROBE_MODE=socks` و `SOCKS_PORT=<port>` را تنظیم کن. توجه: SOCKS مستقل ممکن است با مسیر واقعی Shunt برای کاربران LAN یکسان نباشد.

برای اعمال تنظیمات: `/etc/init.d/googlewifi-led restart`.

### حذف

```sh
cd /tmp/GoogleWifiLED-OpenWrt25
sh uninstall.sh
```

فایل تنظیمات شخصی و نسخه قدیمی در `/usr/local/LED` عمداً نگه داشته می‌شوند. خط اجرای قدیمی در `rc.local` به‌صورت خودکار بازگردانده نمی‌شود چون نسخه قدیمی ناسازگار بوده است.

## English — installation and troubleshooting

Download the `.tar.gz` archive, upload it to `/tmp` on the OpenWrt router, then run:

```sh
cd /tmp
tar -xzf GoogleWifiLED-OpenWrt25.tar.gz
cd GoogleWifiLED-OpenWrt25
sh install.sh
```

The installer checks for all three RGB LEDs **before altering boot services**, preserves `/etc/googlewifi-led.conf` on reinstall, saves a timestamped backup of `/etc/rc.local` before removing only the old package's boot line, and installs a `procd` init service. It does not modify Passwall2 configuration, flash partitions, or core firmware. Use `sh /usr/libexec/googlewifi-led/googlewifi-led.sh probe` to find the current state and reason; `logread -e googlewifi-led` for changes. The default probe calls Passwall2's own `url_test_node` for the original selected node (not its shunt default). Red blinking means **proxy URL-test failure**, not a proven loss of connectivity on every LAN device.

Colors: green (successful & under 1100 ms), yellow (1100–1499 ms), red (1500+ ms), blinking red (test failed), cycling RGB (Passwall2 disabled). Configure LED paths and probe options in `/etc/googlewifi-led.conf`. After a change, run `/etc/init.d/googlewifi-led restart`. Remove by running `sh uninstall.sh` from the extracted folder. The original source is **not modified**; this is an independent local compatibility package.

### Supported / limitations

- Target: Google Wifi models exposing three RGB LED channels via `/sys/class/leds`; auto-detection or manual paths.
- Firmware: OpenWrt 25.12 and 24.10 (no package manager invocation required).
- Passwall2: supports regular nodes and `_shunt` by delegating to the installed official Passwall2 test script.
- Tested: POSIX shell syntax and mocked Passwall2/Shunt/sysfs scenarios. **Not tested on physical router hardware in this environment.** Firmware builds, custom LED drivers and Passwall2 forks may differ.
- No automated dependency installation; if `curl` or `/usr/share/passwall2/test.sh` is absent, install/repair Passwall2 dependencies using the package manager appropriate for your firmware (`apk` on 25.12; `opkg` on 24.10).

### Run the tests

```sh
sh tests/run-tests.sh
```

### Sources

- [Original community project](https://github.com/amirhosseinchoghaei/GoogleWifiLED)
- [OpenWrt 25.12 release notes](https://openwrt.org/releases/25.12/notes-25.12.0)
- [Current Passwall2 source tree](https://github.com/Openwrt-Passwall/openwrt-passwall2)
