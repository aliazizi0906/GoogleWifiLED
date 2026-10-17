# Contributing / مشارکت

[فارسی](#فارسی) · [English](#english)

## فارسی

1. قبل از تغییر رفتار LED یا تست Shunt یک Issue با خروجی `probe` و نسخه OpenWrt/Passwall2 ثبت کنید. از انتشار URL نود، کلید یا اطلاعات شخصی خودداری کنید.
2. برای تغییرات، یک branch بسازید و Pull Request ارسال کنید. دقیقاً توضیح دهید کدام مدل Google Wifi و نسخه OpenWrt تست شده‌اند و آیا تست واقعی روی دستگاه انجام شده یا صرفاً شبیه‌سازی است.
3. اسکریپت‌ها POSIX `/bin/sh`، سازگار با BusyBox و بدون نیاز به `bash` و نصب اجباری پکیج باشند.
4. قبل از PR اجرا کنید: `sh -n bootstrap.sh install.sh uninstall.sh files/googlewifi-led.sh tests/run-tests.sh` و `sh tests/run-tests.sh`.
5. تغییرات مستندات را در هر دو زبان هماهنگ نگه دارید.

## English

1. Open an issue describing the symptom and sanitized `probe` output, OpenWrt version and Passwall2 version. Never post proxy credentials or private keys.
2. Submit changes through a branch and pull request, describing hardware model, firmware and **real-device vs mock** verification.
3. Keep scripts POSIX `/bin/sh` and BusyBox-compatible; avoid adding mandatory package dependencies.
4. Run: `sh -n bootstrap.sh install.sh uninstall.sh files/googlewifi-led.sh tests/run-tests.sh` and `sh tests/run-tests.sh`.
5. Update English and Persian documentation together where behavior changes.
