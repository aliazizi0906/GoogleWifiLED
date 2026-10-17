# Changelog

## Unreleased — GitHub-first installation and documentation

- Add `bootstrap.sh` to install directly from the full GitHub source archive with no Git requirement.
- Add bilingual README, installation/update/uninstall guides, and troubleshooting.
- Add POSIX shell mock-test workflow, issue template and contribution guide.
- Preserve existing runtime files; no changes to Passwall2 or LED engine behavior in this documentation update.

## OpenWrt 25.12 compatibility rewrite — initial import

- Replace obsolete `rc.local` background process with an OpenWrt `procd` service.
- Delegate selected regular/Shunt node testing to Passwall2's built-in URL test and correctly parse latency.
- Preserve existing settings on reinstall; avoid `opkg` dependency.
- Support LED sysfs detection, diagnostics, status colors and mock tests.

> No physical-device validation has yet been recorded in this repository.
