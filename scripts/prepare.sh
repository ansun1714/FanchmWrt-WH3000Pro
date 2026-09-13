#!/bin/bash

set -euo pipefail

# ============================================================
# FanchmWrt WH3000 Pro eMMC
# Prepare / Target Lock
# ============================================================

ROOT_DIR="${GITHUB_WORKSPACE:-$(pwd)}"
BUILD_DIR="${ROOT_DIR}/openwrt"

cd "${BUILD_DIR}"

# ============================================================
# ★★★ 唯一正确 Device ID
# ============================================================

TARGET_DEVICE="${DEVICE:-huasifei_wh3000-pro-emmc}"

TARGET_SYMBOL="${TARGET_DEVICE//-/_}"

TARGET_CONFIG="CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_${TARGET_SYMBOL}=y"

DEVICE_MK="target/linux/mediatek/image/filogic.mk"

DTS_EMMC="target/linux/mediatek/dts/mt7981b-huasifei-wh3000-pro-emmc.dts"

DTS_COMMON="target/linux/mediatek/dts/mt7981b-huasifei-wh3000-pro.dtsi"

echo "============================================================"
echo " FanchmWrt WH3000 Pro Prepare"
echo "============================================================"

echo
echo "ROOT_DIR:"
echo "${ROOT_DIR}"

echo
echo "BUILD_DIR:"
echo "${BUILD_DIR}"

echo
echo "TARGET_DEVICE:"
echo "${TARGET_DEVICE}"

echo
echo "TARGET_SYMBOL:"
echo "${TARGET_SYMBOL}"

echo
echo "TARGET_CONFIG:"
echo "${TARGET_CONFIG}"

# ============================================================
# 1. 基础检查
# ============================================================

echo
echo "============================================================"
echo " 1. 基础目录检查"
echo "============================================================"

test -d "${BUILD_DIR}"

test -f "${DEVICE_MK}"

test -f "${DTS_EMMC}"

test -f "${DTS_COMMON}"

echo "✅ Build directory OK"
echo "✅ Device Makefile OK"
echo "✅ WH3000 Pro eMMC DTS OK"
echo "✅ WH3000 Pro common DTS OK"

# ============================================================
# 2. 检查 Device 定义
# ============================================================

echo
echo "============================================================"
echo " 2. 检查 Device 定义"
echo "============================================================"

if ! grep -q \
  "^define Device/${TARGET_DEVICE}$" \
  "${DEVICE_MK}"; then

  echo
  echo "❌ 找不到 WH3000 Pro eMMC Device 定义"
  echo
  echo "期望:"
  echo "define Device/${TARGET_DEVICE}"

  exit 1
fi

echo "✅ Device definition exists"

# ============================================================
# 3. 检查 TARGET_DEVICES
# ============================================================

echo
echo "============================================================"
echo " 3. 检查 TARGET_DEVICES"
echo "============================================================"

if ! grep -q \
  "^TARGET_DEVICES += ${TARGET_DEVICE}$" \
  "${DEVICE_MK}"; then

  echo
  echo "❌ TARGET_DEVICES 中没有 WH3000 Pro eMMC"

  exit 1
fi

echo "✅ TARGET_DEVICES exists"

# ============================================================
# 4. 检查 DTS 文件名
# ============================================================

echo
echo "============================================================"
echo " 4. 检查 DTS"
echo "============================================================"

echo "DTS:"
echo "${DTS_EMMC}"

ls -lh "${DTS_EMMC}"

echo
echo "Common DTS:"
echo "${DTS_COMMON}"

ls -lh "${DTS_COMMON}"

echo
echo "✅ DTS 文件名及路径正确"

# ============================================================
# 5. 检查 DTS 引用
# ============================================================

echo
echo "============================================================"
echo " 5. 检查 DTS 引用"
echo "============================================================"

if ! grep -q \
  "DEVICE_DTS := mt7981b-huasifei-wh3000-pro-emmc" \
  "${DEVICE_MK}"; then

  echo "❌ Device Makefile 中 DTS 引用错误"

  exit 1
fi

echo "✅ Device DTS 引用正确"

# ============================================================
# 6. 检查用户配置
# ============================================================

USER_CONFIG="${ROOT_DIR}/config/wh3000pro.config"

echo
echo "============================================================"
echo " 6. 导入 WH3000 Pro 配置"
echo "============================================================"

if [ ! -f "${USER_CONFIG}" ]; then

  echo "❌ 找不到:"
  echo "${USER_CONFIG}"

  exit 1
fi

cp -f \
  "${USER_CONFIG}" \
  .config

echo "✅ wh3000pro.config 已复制到 .config"

# ============================================================
# 7. 清除所有旧设备选择
# ============================================================

echo
echo "============================================================"
echo " 7. 清除旧设备选择"
echo "============================================================"

sed -i \
  '/^CONFIG_TARGET_mediatek_filogic_DEVICE_.*=y$/d' \
  .config

echo "✅ 已清除所有 Filogic Device"

# ============================================================
# 8. 清除 OpenWrt One
# ============================================================

sed -i \
  '/^CONFIG_TARGET_mediatek_filogic_DEVICE_openwrt_one=y$/d' \
  .config

echo "✅ 已清除 OpenWrt One"

# ============================================================
# 9. ★★★ 清除 TARGET_PROFILE
# ============================================================

sed -i \
  '/^CONFIG_TARGET_PROFILE=/d' \
  .config

echo "✅ 已清除 CONFIG_TARGET_PROFILE"

# ============================================================
# 10. 确保基础 Target
# ============================================================

sed -i \
  '/^CONFIG_TARGET_mediatek=/d' \
  .config

sed -i \
  '/^CONFIG_TARGET_mediatek_filogic=/d' \
  .config

cat >> .config << 'EOF'

CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y

EOF

echo "✅ MediaTek / Filogic 基础 Target 已写入"

# ============================================================
# 11. 第一次也是唯一一次 make defconfig
# ============================================================

echo
echo "============================================================"
echo " 11. 执行一次 make defconfig"
echo "============================================================"

make defconfig

echo
echo "✅ make defconfig 完成"

# ============================================================
# 12. ★★★ defconfig 后再次清理设备
# ============================================================

echo
echo "============================================================"
echo " 12. defconfig 后重新清理设备选择"
echo "============================================================"

sed -i \
  '/^CONFIG_TARGET_mediatek_filogic_DEVICE_.*=y$/d' \
  .config

echo "✅ defconfig 产生的旧设备选择已清除"

# ============================================================
# 13. ★★★ defconfig 后再次清除 OpenWrt One
# ============================================================

sed -i \
  '/^CONFIG_TARGET_mediatek_filogic_DEVICE_openwrt_one=y$/d' \
  .config

echo "✅ OpenWrt One 已再次清除"

# ============================================================
# 14. ★★★ defconfig 后再次清除 PROFILE
# ============================================================

sed -i \
  '/^CONFIG_TARGET_PROFILE=/d' \
  .config

echo "✅ CONFIG_TARGET_PROFILE 已再次清除"

# ============================================================
# 15. 强制写入 WH3000 Pro eMMC
# ============================================================

echo
echo "============================================================"
echo " 15. 锁定 WH3000 Pro eMMC"
echo "============================================================"

echo "${TARGET_CONFIG}" >> .config

echo "✅ WH3000 Pro eMMC 已写入"

# ============================================================
# 16. 确保基础 Target 不被改变
# ============================================================

if ! grep -q '^CONFIG_TARGET_mediatek=y$' .config; then

  echo "❌ CONFIG_TARGET_mediatek=y 不存在"

  exit 1
fi

if ! grep -q '^CONFIG_TARGET_mediatek_filogic=y$' .config; then

  echo "❌ CONFIG_TARGET_mediatek_filogic=y 不存在"

  exit 1
fi

# ============================================================
# 17. 精确设备检查
# ============================================================

echo
echo "============================================================"
echo " 17. 精确设备检查"
echo "============================================================"

if ! grep -q \
  "^${TARGET_CONFIG}$" \
  .config; then

  echo "❌ WH3000 Pro eMMC 目标没有正确写入"

  exit 1
fi

echo "✅ WH3000 Pro eMMC target OK"

# ============================================================
# 18. 禁止 OpenWrt One
# ============================================================

echo
echo "============================================================"
echo " 18. OpenWrt One 检查"
echo "============================================================"

if grep -q \
  '^CONFIG_TARGET_mediatek_filogic_DEVICE_openwrt_one=y$' \
  .config; then

  echo "❌ OpenWrt One 仍然存在"

  exit 1
fi

echo "✅ OpenWrt One 不存在"

# ============================================================
# 19. 禁止 TARGET_PROFILE
# ============================================================

echo
echo "============================================================"
echo " 19. TARGET_PROFILE 检查"
echo "============================================================"

if grep -q '^CONFIG_TARGET_PROFILE=' .config; then

  echo "❌ TARGET_PROFILE 仍然存在"

  grep '^CONFIG_TARGET_PROFILE=' .config || true

  exit 1
fi

echo "✅ TARGET_PROFILE 已完全清除"

# ============================================================
# 20. 检查 Filogic 设备数量
# ============================================================

echo
echo "============================================================"
echo " 20. Filogic 设备数量检查"
echo "============================================================"

DEVICE_COUNT="$(
  grep -E \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
    .config \
    | wc -l
)"

echo "DEVICE_COUNT=${DEVICE_COUNT}"

if [ "${DEVICE_COUNT}" -ne 1 ]; then

  echo
  echo "❌ Filogic 设备数量不是 1"

  grep -E \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
    .config \
    || true

  exit 1
fi

echo "✅ Filogic 设备数量 = 1"

# ============================================================
# 21. 最终显示
# ============================================================

echo
echo "============================================================"
echo " 21. FINAL TARGET CONFIG"
echo "============================================================"

grep -E \
  '^CONFIG_TARGET_(mediatek|DEVICE|BOARD|SUBTARGET|PROFILE)' \
  .config \
  || true

echo
echo "============================================================"
echo " Device:"
echo "============================================================"

grep -E \
  '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
  .config

echo
echo "============================================================"
echo "✅ PREPARE 完成"
echo "============================================================"

echo
echo "最终设备:"
echo "${TARGET_DEVICE}"

echo
echo "最终配置:"
echo "${TARGET_CONFIG}"

echo
echo "⚠️ 从现在开始不要再执行 make defconfig"
echo "⚠️ 设备目标已经锁定"
echo
