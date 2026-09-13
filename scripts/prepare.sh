#!/bin/bash

set -euo pipefail

# ============================================================
# FanchmWrt WH3000 Pro eMMC
# prepare.sh
#
# 核心原则：
#
# 1. 先让 Kconfig 自己完成 defconfig
# 2. defconfig 完成后再强制选择 WH3000 Pro
# 3. 强制选择后绝对不再运行 make defconfig
# 4. 防止 openwrt_one 等设备被错误选择
# ============================================================


# ============================================================
# 基本变量
# ============================================================

OPENWRT_DIR="${GITHUB_WORKSPACE}/openwrt"

CONFIG_FILE="${GITHUB_WORKSPACE}/config/wh3000pro.config"

TARGET_DEVICE="${DEVICE:-huasifei_wh3000-pro-emmc}"

TARGET_SYMBOL="${TARGET_DEVICE//-/_}"

TARGET_CONFIG="CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_${TARGET_SYMBOL}=y"

DEVICE_MK="target/linux/mediatek/image/filogic.mk"

DTS_EMMC="target/linux/mediatek/dts/mt7981b-huasifei-wh3000-pro-emmc.dts"

DTS_COMMON="target/linux/mediatek/dts/mt7981b-huasifei-wh3000-pro.dtsi"


cd "${OPENWRT_DIR}"


echo "============================================================"
echo " FanchmWrt WH3000 Pro | Prepare"
echo "============================================================"

echo
echo "Target:"
echo "${TARGET_DEVICE}"

echo
echo "Kconfig:"
echo "${TARGET_CONFIG}"


# ============================================================
# 1. Verify source target
# ============================================================

echo
echo "============================================================"
echo " 1. Verify WH3000 Pro source target"
echo "============================================================"


if ! grep -qE \
    "^define Device/${TARGET_DEVICE}$" \
    "${DEVICE_MK}"; then

    echo
    echo "❌ ERROR:"
    echo "${TARGET_DEVICE} is NOT defined."

    exit 1
fi


if ! grep -qE \
    "^TARGET_DEVICES += ${TARGET_DEVICE}$" \
    "${DEVICE_MK}"; then

    echo
    echo "❌ ERROR:"
    echo "${TARGET_DEVICE} is NOT registered in TARGET_DEVICES."

    exit 1
fi


if [ ! -f "${DTS_EMMC}" ]; then

    echo
    echo "❌ ERROR:"
    echo "Missing eMMC DTS:"
    echo "${DTS_EMMC}"

    exit 1
fi


if [ ! -f "${DTS_COMMON}" ]; then

    echo
    echo "❌ ERROR:"
    echo "Missing common DTS:"
    echo "${DTS_COMMON}"

    exit 1
fi


echo
echo "✅ Source target verified."


# ============================================================
# 2. Copy base config
# ============================================================

echo
echo "============================================================"
echo " 2. Copy base config"
echo "============================================================"


if [ ! -f "${CONFIG_FILE}" ]; then

    echo
    echo "❌ ERROR:"
    echo "Config file not found:"
    echo "${CONFIG_FILE}"

    exit 1
fi


cp \
    "${CONFIG_FILE}" \
    .config


echo "Base config copied."


# ============================================================
# 3. Remove device selections BEFORE defconfig
#
# 注意：
#
# 这里只删除具体 DEVICE choice。
#
# 不删除：
#
# CONFIG_TARGET_mediatek
# CONFIG_TARGET_mediatek_filogic
# CONFIG_TARGET_DEVICE_mediatek_filogic
#
# 让 Kconfig 自己完成平台选择。
# ============================================================

echo
echo "============================================================"
echo " 3. Normalize base configuration"
echo "============================================================"


sed -i \
    '/^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$/d' \
    .config


echo
echo "Current device selections before defconfig:"

grep \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
    .config \
    || echo "None"


# ============================================================
# 4. make defconfig
#
# 这里非常重要：
#
# 让 Kconfig 先完成自己的 choice 处理。
#
# 这一步之后我们不再运行 defconfig。
# ============================================================

echo
echo "============================================================"
echo " 4. make defconfig"
echo "============================================================"


make defconfig


echo
echo "✅ Base defconfig completed."


# ============================================================
# 5. Show what Kconfig selected
# ============================================================

echo
echo "============================================================"
echo " 5. Device selected by Kconfig"
echo "============================================================"


grep \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
    .config \
    || echo "No device selected by Kconfig."


# ============================================================
# 6. Remove Kconfig default device
#
# 例如：
#
# openwrt_one
# bananapi_bpi-r4
# cmcc_rax3000m
# 等
#
# 然后由我们自己写入 WH3000 Pro。
# ============================================================

echo
echo "============================================================"
echo " 6. Remove default Filogic device"
echo "============================================================"


sed -i \
    '/^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$/d' \
    .config


echo
echo "Device selection after cleanup:"

grep \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
    .config \
    || echo "None"


# ============================================================
# 7. Force exact WH3000 Pro eMMC
#
# 重要：
#
# 这里写入之后：
#
# ❌ 不再 make defconfig
# ❌ 不再 olddefconfig
# ❌ 不再 menuconfig
#
# 否则 Kconfig 可能再次改变 choice。
# ============================================================

echo
echo "============================================================"
echo " 7. Force exact WH3000 Pro eMMC target"
echo "============================================================"


cat >> .config <<EOF

# ============================================================
# FORCE Huasifei WH3000 Pro eMMC
# ============================================================

CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_${TARGET_SYMBOL}=y

EOF


echo
echo "Forced target:"
echo "${TARGET_CONFIG}"


# ============================================================
# 8. Verify exact target
# ============================================================

echo
echo "============================================================"
echo " 8. Verify exact target"
echo "============================================================"


if ! grep -qF \
    "${TARGET_CONFIG}" \
    .config; then

    echo
    echo "❌ FATAL ERROR"
    echo
    echo "WH3000 Pro target was NOT written."

    exit 1
fi


# ============================================================
# 9. Verify exactly ONE Filogic device
# ============================================================

echo
echo "============================================================"
echo " 9. Verify exactly ONE device"
echo "============================================================"


DEVICE_COUNT="$(
    grep -Ec \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
        .config \
        || true
)"


echo "Device count:"
echo "${DEVICE_COUNT}"


if [ "${DEVICE_COUNT}" -ne 1 ]; then

    echo
    echo "❌ FATAL ERROR"
    echo
    echo "Expected exactly ONE Filogic device."
    echo
    echo "Selected devices:"

    grep \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
        .config \
        || true

    exit 1
fi


# ============================================================
# 10. Verify exact device again
# ============================================================

if ! grep -q \
    "^${TARGET_CONFIG}$" \
    .config; then

    echo
    echo "❌ FATAL ERROR"
    echo
    echo "The selected device is not WH3000 Pro eMMC."

    exit 1
fi


# ============================================================
# 11. Explicitly reject OpenWrt One
# ============================================================

echo
echo "============================================================"
echo " 10. Reject OpenWrt One"
echo "============================================================"


if grep -q \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_openwrt_one=y$' \
    .config; then

    echo
    echo "❌ FATAL ERROR"
    echo
    echo "openwrt_one was selected!"
    echo
    echo "Build stopped."

    exit 1
fi


echo "✅ openwrt_one not selected."


# ============================================================
# 12. Verify target platform
# ============================================================

echo
echo "============================================================"
echo " 11. Verify target platform"
echo "============================================================"


for REQUIRED_CONFIG in \
    "CONFIG_TARGET_arm=y" \
    'CONFIG_TARGET_BOARD="mediatek"' \
    'CONFIG_TARGET_SUBTARGET="filogic"' \
    "CONFIG_TARGET_mediatek=y" \
    "CONFIG_TARGET_mediatek_filogic=y" \
    "CONFIG_TARGET_DEVICE_mediatek_filogic=y"
do

    if ! grep -qF \
        "${REQUIRED_CONFIG}" \
        .config; then

        echo
        echo "❌ FATAL ERROR"
        echo
        echo "Missing required configuration:"
        echo "${REQUIRED_CONFIG}"

        exit 1
    fi

done


echo "✅ Target platform verified."


# ============================================================
# 13. Important packages
# ============================================================

echo
echo "============================================================"
echo " 12. Important packages"
echo "============================================================"


grep -E \
    '^CONFIG_PACKAGE_(luci-app-qmodem-next|luci-app-lucky|lucky|dockerd|containerd|runc|docker)=' \
    .config \
    || true


# ============================================================
# 14. Print final target
# ============================================================

echo
echo "============================================================"
echo " FINAL SELECTED DEVICE"
echo "============================================================"


grep \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
    .config


# ============================================================
# 15. Print image definition
# ============================================================

echo
echo "============================================================"
echo " WH3000 Pro IMAGE DEFINITION"
echo "============================================================"


grep \
    -n \
    -A15 \
    -B2 \
    "^define Device/${TARGET_DEVICE}$" \
    "${DEVICE_MK}"


# ============================================================
# 16. Final result
# ============================================================

echo
echo "============================================================"
echo " ✅ PREPARE PASSED"
echo "============================================================"

echo
echo "Exact target:"
echo "${TARGET_DEVICE}"

echo
echo "Exact Kconfig:"
echo "${TARGET_CONFIG}"

echo
echo "Important rule:"
echo "DO NOT run make defconfig again after this point."

echo
echo "WH3000 Pro eMMC configuration is locked."
