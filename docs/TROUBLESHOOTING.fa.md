# عیب‌یابی GoogleWifiLED

[README](../README.md) · [نصب](INSTALL.fa.md) · [English](TROUBLESHOOTING.en.md)

## بررسی اولیه

```sh
/etc/init.d/googlewifi-led status
sh /usr/libexec/googlewifi-led/googlewifi-led.sh probe
sh /usr/libexec/googlewifi-led/googlewifi-led.sh led-check
logread -e googlewifi-led
uci -q get 'passwall2.@global[0].node'
uci -q get 'passwall2.@global[0].enabled'
ls /sys/class/leds
```

**چشمک قرمز به معنای شکست تست URL است، نه اثبات قطعی نبود اینترنت.**

| مقدار reason | تفسیر | بررسی |
| --- | --- | --- |
| `passwall-disabled` | Passwall2 در تنظیمات خاموش است | وضعیت global enabled |
| `invalid-node` | نود اصلی نامعتبر/حذف شده | انتخاب نود در Passwall2 |
| `missing-passwall-test` | فایل تست Passwall2 پیدا نشده | نصب Passwall2، مسیر test.sh |
| `failed-node-test` | تست URL نود یا خروجی آن ناموفق | تست نود در LuCI، لاگ، DNS و SOCKS موقت |
| `failed-socks-probe` | SOCKS یا URL در حالت socks کار نکرده | پورت و listening proxy |
| `missing-curl` | curl برای socks نصب نیست | ابزار curl |
| `invalid-probe-mode` | مقدار اشتباه PROBE_MODE | node-test یا socks |
| `invalid-socks-port` | مقدار SOCKS_PORT نامعتبر | پورت عددی 1..65535 |

## چراغ دائماً قرمز چشمک می‌زند

```sh
sh /usr/libexec/googlewifi-led/googlewifi-led.sh probe
ls -l /usr/share/passwall2/test.sh
uci -q get 'passwall2.@global[0].node'
logread -e passwall2
```

اگر `reason=failed-node-test` است، در LuCI همان نود را تست کنید. برنامه برای نود Shunt خود شناسهٔ `_shunt` را به تست Passwall2 می‌دهد و به‌جایش `default_node` را انتخاب نمی‌کند؛ ممکن است DNS، دسترسی HTTP، URL تست یا نسخهٔ Passwall2 باعث شکست شود.

## رنگ‌ها غلط است / LED شناسایی نمی‌شود

```sh
ls /sys/class/leds
/etc/init.d/googlewifi-led stop
sh /usr/libexec/googlewifi-led/googlewifi-led.sh led-test
/etc/init.d/googlewifi-led start
```

مسیرهای `LED_RED_DIR`، `LED_GREEN_DIR`، `LED_BLUE_DIR` را مطابق نام‌های واقعی sysfs در `/etc/googlewifi-led.conf` تنظیم کنید. نصب‌کننده در صورت نبود LED قبل از تغییر سرویس متوقف می‌شود؛ در صورت نیاز ابتدا تنظیمات را از `files/googlewifi-led.conf` کپی و مسیرها را دستی تغییر دهید.

## GitHub در دسترس نیست

مشکل DNS/TLS/timeout برای `raw.githubusercontent.com` یا `github.com` را بررسی کنید. در صورت عدم دسترسی از روتر، از [انتقال آفلاین](INSTALL.fa.md#روش-۳-انتقال-آفلاین-با-winscp) استفاده کنید.

## سرویس بالا نمی‌آید / نسخه قدیمی تداخل دارد

```sh
/etc/init.d/googlewifi-led restart
/etc/init.d/googlewifi-led status
logread -e googlewifi-led
grep -n 'usr/local/LED/led.sh' /etc/rc.local
```

نصب‌کننده فقط خط شناخته‌شدهٔ LED قدیمی در rc.local را با بکاپ حذف می‌کند، فایل‌های قدیمی را نگه می‌دارد و فقط پروسه‌های LED قدیمی را می‌بندد؛ نباید xray/sing-box یا Passwall2 را kill کند.

## گزارش باگ

خروجی `cat /etc/openwrt_release`، `probe`، `led-check` و `logread -e googlewifi-led` را به [Issues](https://github.com/aliazizi0906/GoogleWifiLED/issues) ضمیمه کنید. **کلیدها، URL نودها، اطلاعات شخصی و IPهای حساس را قبل از انتشار حذف کنید.**
