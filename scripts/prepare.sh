#!/bin/bash
set -euo pipefail

OPENWRT_DIR="${GITHUB_WORKSPACE}/openwrt"

cd "${OPENWRT_DIR}"

echo "==> Source:"
git describe --tags --always || true

echo "==> Add QModem feed"
grep -q '^src-git qmodem ' feeds.conf.default || \
  echo 'src-git qmodem https://github.com/FUjr/QModem.git;main' >> feeds.conf.default

echo "==> Add Lucky as a local package"
rm -rf package/lucky
git clone --depth=1 https://github.com/gdy666/luci-app-lucky.git package/lucky

echo "==> Update/install feeds"
./scripts/feeds update -a
./scripts/feeds install -a

echo "==> QModem feed install (force)"
./scripts/feeds update qmodem
./scripts/feeds install -a -f -p qmodem

echo "==> Verify WH3000 Pro is present"
grep -n -A16 -B2 'Device/huasifei_wh3000-pro-emmc' \
  target/linux/mediatek/image/filogic.mk

test -f target/linux/mediatek/dts/mt7981b-huasifei-wh3000-pro-emmc.dts
test -f target/linux/mediatek/dts/mt7981b-huasifei-wh3000-pro.dtsi

echo "==> Verify modem-power GPIO definition"
grep -n -A6 -B2 'modem-power' \
  target/linux/mediatek/dts/mt7981b-huasifei-wh3000-pro.dtsi

echo "==> Verify kernel 6.12"
grep -n '^KERNEL_PATCHVER' target/linux/mediatek/Makefile
test -f target/linux/mediatek/filogic/config-6.12

echo "==> Copy our device config"
cp "${GITHUB_WORKSPACE}/config/wh3000pro.config" .config

echo "==> Ensure target is WH3000 Pro eMMC"
cat >> .config <<'EOF'

# FanchmWrt WH3000 Pro eMMC
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_DEVICE_mediatek_filogic=y
CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_huasifei_wh3000-pro-emmc=y
CONFIG_TARGET_DEVICE_PACKAGES_mediatek_filogic=""

# Explicit device selection; generated below by make defconfig.
EOF

echo "==> Search exact target symbol"
grep -R "CONFIG_TARGET.*huasifei.*wh3000.*pro" -n target/linux/mediatek 2>/dev/null || true

echo "==> Generate default configuration"
make defconfig

echo "==> Final target selection:"
grep -E 'CONFIG_TARGET_(mediatek|DEVICE).*huasifei|CONFIG_LINUX|CONFIG_TESTING_KERNEL' .config || true

echo "==> Selected QModem/Lucky/Docker packages:"
grep -E '^CONFIG_PACKAGE_(luci-app-qmodem-next|luci-app-lucky|lucky|dockerd|containerd|runc|tini|docker)=' .config || true
