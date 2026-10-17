# نصب و مدیریت GoogleWifiLED — فارسی

[صفحهٔ اصلی](../README.md) · [English](INSTALL.en.md) · [عیب‌یابی](TROUBLESHOOTING.fa.md)

## پیش‌نیازها

- روتر Google Wifi با OpenWrt 25.12 (یا 24.10)، دسترسی SSH و کاربر `root`.
- Passwall2 نصب‌شده و دارای `/usr/share/passwall2/test.sh`.
- کانال‌های RGB در `/sys/class/leds` و دسترسی HTTPS به GitHub در روش آنلاین.
- برای نصب سریع فقط `curl` یا `wget` لازم است؛ **Git اجباری نیست**.

بررسی اولیه:

```sh
ls /sys/class/leds
uci -q get 'passwall2.@global[0].enabled'
uci -q get 'passwall2.@global[0].node'
```

## روش ۱: نصب مستقیم از GitHub (پیشنهادی)

```sh
curl -fL https://raw.githubusercontent.com/aliazizi0906/GoogleWifiLED/main/bootstrap.sh -o /tmp/googlewifi-led-bootstrap.sh
sh /tmp/googlewifi-led-bootstrap.sh
```

دستور اول فقط دانلود می‌کند؛ می‌توانید قبل از اجرای دستور دوم با `cat /tmp/googlewifi-led-bootstrap.sh` محتوا را بررسی کنید. سپس bootstrap **آرشیو کامل شاخه main** را دریافت، استخراج و `install.sh` را از کنار `files/` اجرا می‌کند؛ همهٔ فایل‌های موقت حذف می‌شوند. اگر curl ندارید:

```sh
wget -O /tmp/googlewifi-led-bootstrap.sh https://raw.githubusercontent.com/aliazizi0906/GoogleWifiLED/main/bootstrap.sh
sh /tmp/googlewifi-led-bootstrap.sh
```

ممکن است BusyBox wget در بعضی فریمورها برای HTTPS/redirect درست کار نکند؛ در این حالت از curl یا انتقال آفلاین استفاده کنید. **فقط فایل install.sh را دانلود نکنید** چون به فایل‌های داخل `files/` نیاز دارد.

## روش ۲: نصب با Git Clone

اگر Git نصب است:

```sh
cd /tmp
git clone --depth 1 https://github.com/aliazizi0906/GoogleWifiLED.git
cd GoogleWifiLED
sh install.sh
```

آپدیت با همان کلون:

```sh
cd /tmp/GoogleWifiLED
git pull --ff-only
sh install.sh
```

`/tmp` در ریبوت پاک می‌شود؛ نصب سرویس دائمی است و به کلون نیاز ندارد، اما برای آپدیت‌های آینده باید کلون را دوباره دریافت یا روش ۱ را اجرا کنید. نصب Git روی روتر با فضای محدود توصیه نمی‌شود مگر واقعاً لازم باشد.

## روش ۳: انتقال آفلاین با WinSCP

از رایانه [سورس ZIP پروژه](https://github.com/aliazizi0906/GoogleWifiLED/archive/refs/heads/main.zip) را دریافت و استخراج کنید. **کل پوشه** شامل `install.sh`، `files/` و سایر فایل‌ها را با WinSCP/SCP در مسیر `/tmp/GoogleWifiLED` قرار دهید. سپس:

```sh
cd /tmp/GoogleWifiLED
sh install.sh
```

## تأیید نصب

```sh
/etc/init.d/googlewifi-led status
sh /usr/libexec/googlewifi-led/googlewifi-led.sh led-check
sh /usr/libexec/googlewifi-led/googlewifi-led.sh probe
logread -e googlewifi-led
```

`probe` فیلدهای `state`، `reason`، `node` و `latency_ms` را نشان می‌دهد. `state=unreachable` یعنی تست URL شکست خورده، نه لزوماً قطع اینترنت برای همهٔ دستگاه‌ها.

| رنگ | معنی |
| --- | --- |
| سبز ثابت | تست موفق زیر 1100ms |
| زرد ثابت | تست موفق 1100 تا 1499ms |
| قرمز ثابت | تست موفق از 1500ms |
| قرمز چشمک‌زن | تست نود ناموفق/نامعتبر |
| رنگ‌های چرخشی | Passwall2 غیرفعال |

این **تست HTTP URL** است و با Ping ICMP یا تست مسیر همهٔ کاربران LAN فرق دارد.

## تنظیمات، مدیریت سرویس و تست LED

```sh
vi /etc/googlewifi-led.conf
/etc/init.d/googlewifi-led restart
/etc/init.d/googlewifi-led stop
/etc/init.d/googlewifi-led start
/etc/init.d/googlewifi-led enable
```

تنظیمات پیش‌فرض:

```sh
PROBE_MODE=node-test
CHECK_INTERVAL=30
GREEN_MAX_MS=1099
YELLOW_MAX_MS=1499
```

`node-test` نود انتخاب‌شده (حتی Shunt) را با تست Passwall2 بررسی می‌کند و ممکن است SOCKS موقت بسازد. `socks` به یک SOCKS محلی فعال از قبل نیاز دارد: `PROBE_MODE=socks` و `SOCKS_PORT=1070` (پورت واقعی خودتان). تست SOCKS لزوماً همان مسیر LAN/Shunt نیست. پس از ویرایش کانفیگ سرویس را restart کنید.

برای تست سخت‌افزاری چراغ‌ها:

```sh
/etc/init.d/googlewifi-led stop
sh /usr/libexec/googlewifi-led/googlewifi-led.sh led-test
/etc/init.d/googlewifi-led start
```

## آپدیت، نصب مجدد و حذف

برای آپدیت بدون Git همان دستورات روش ۱ را تکرار کنید. تنظیمات شخصی `/etc/googlewifi-led.conf` نگه داشته می‌شود؛ نصب‌کننده سرویس را مجدداً راه‌اندازی می‌کند. پس از نصب نیاز به reboot نیست.

حذف از پوشهٔ سورس با `sh uninstall.sh` یا بدون کلون:

```sh
curl -fL https://raw.githubusercontent.com/aliazizi0906/GoogleWifiLED/main/uninstall.sh -o /tmp/googlewifi-led-uninstall.sh
sh /tmp/googlewifi-led-uninstall.sh
```

فایل تنظیمات و پوشهٔ قدیمی `/usr/local/LED` عمداً حذف نمی‌شوند و خط قدیمی `rc.local` بازگردانده نمی‌شود. نصب‌کننده هنگام مهاجرت فقط خط اجرای مشخص نسخهٔ قدیمی را پس از گرفتن backup از `rc.local` پاک می‌کند و به پیکربندی Passwall2 دست نمی‌زند.

[عیب‌یابی مشکلات رایج](TROUBLESHOOTING.fa.md)
