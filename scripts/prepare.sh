#!/bin/bash
set -euo pipefail

OPENWRT_DIR="${GITHUB_WORKSPACE}/openwrt"
cd "${OPENWRT_DIR}"

echo "==> Copy base config"
cp "${GITHUB_WORKSPACE}/config/wh3000pro.config" .config

echo "==> Inject detected device target"
# DETECTED_DEVICE 由 diy-part1.sh 写入 GITHUB_ENV，这里取到
DEVICE_SYMBOL="${DETECTED_DEVICE//-/_}"   # 把 - 换成 _（Kconfig 用下划线）
echo "    Device: ${DETECTED_DEVICE} → symbol: ${DEVICE_SYMBOL}"

cat >> .config <<EOF

# Auto-detected WH3000 Pro device
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_DEVICE_mediatek_filogic=y
CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_${DEVICE_SYMBOL}=y
EOF

echo "==> make defconfig"
make defconfig

echo "==> Verify final target selection"
grep -E 'CONFIG_TARGET_(DEVICE|mediatek).*wh3000' .config || {
  echo "ERROR: WH3000 Pro not selected after defconfig!"
  echo "--- Current target device ---"
  grep 'CONFIG_TARGET_DEVICE_.*=y' .config || true
  exit 1
}

echo "==> Selected packages:"
grep -E '^CONFIG_PACKAGE_(luci-app-qmodem-next|luci-app-lucky|lucky|dockerd)=' .config || true
