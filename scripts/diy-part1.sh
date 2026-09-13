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
./scripts/feeds update qmodem
./scripts/feeds install -a -f -p qmodem

# ── 核心修复：注入 WH3000 Pro 设备支持 ───────────────────────────
echo "==> Check WH3000 Pro device support"
if grep -q 'wh3000-pro' target/linux/mediatek/image/filogic.mk 2>/dev/null; then
  echo "    WH3000 Pro already present in filogic.mk"
  # 打印实际找到的设备名（用于调试）
  grep 'wh3000-pro' target/linux/mediatek/image/filogic.mk | head -5
else
  echo "    WH3000 Pro NOT in filogic.mk — cherry-picking from upstream OpenWrt"

  git config user.email "ci@build.local"
  git config user.name  "CI"

  # 拉取包含 WH3000 Pro 支持的 upstream commit
  git remote add upstream-owrt https://github.com/openwrt/openwrt.git 2>/dev/null || true
  git fetch --depth=2 upstream-owrt 395bb64a

  # 尝试 cherry-pick，失败则报错（不静默吞掉）
  git cherry-pick --no-edit FETCH_HEAD
fi

echo "==> Verify WH3000 Pro DTS files"
ls -la target/linux/mediatek/dts/mt7981b-huasifei-wh3000-pro* || {
  echo "ERROR: WH3000 Pro DTS files missing even after patch"
  exit 1
}

echo "==> Detect actual device name in filogic.mk"
WH3K_DEVICE=$(grep -oP '(?<=Device/huasifei_wh3000-pro)[^\s)]*' \
  target/linux/mediatek/image/filogic.mk | head -1)
echo "    Found variant suffix: '${WH3K_DEVICE}'"
# WH3K_DEVICE 为空 → huasifei_wh3000-pro
# WH3K_DEVICE 为 -emmc → huasifei_wh3000-pro-emmc
echo "DETECTED_DEVICE=huasifei_wh3000-pro${WH3K_DEVICE}" >> "${GITHUB_ENV}"
