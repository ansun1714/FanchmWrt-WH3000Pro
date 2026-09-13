#!/bin/bash

set -euo pipefail

# ============================================================
# FanchmWrt WH3000 Pro eMMC
# prepare.sh
#
# 最终版
#
# 核心目标：
#   huasifei_wh3000-pro-emmc
#
# 核心原则：
#   1. 检查 WH3000 Pro 设备定义
#   2. 检查 eMMC DTS
#   3. 复制基础配置
#   4. make defconfig
#   5. 清理 Kconfig 自动选择的 Filogic DEVICE
#   6. 强制写入 WH3000 Pro eMMC
#   7. 强制写入后不再运行 defconfig
#   8. 最终严格验证
# ============================================================


# ============================================================
# 变量
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
# 1. 检查 filogic.mk
# ============================================================

echo
echo "============================================================"
echo " 1. Verify WH3000 Pro source target"
echo "============================================================"


echo
echo "Checking Device definition..."


if ! grep -q \
    "define Device/${TARGET_DEVICE}" \
    "${DEVICE_MK}"; then

    echo
    echo "❌ ERROR:"
    echo "Device definition not found:"
    echo "${TARGET_DEVICE}"

    echo
    echo "Available Huasifei devices:"

    grep \
        -n \
        "define Device/huasifei" \
        "${DEVICE_MK}" \
        || true

    exit 1
fi


echo "✅ Device definition exists."


# ============================================================
# 2. 显示完整 Device 定义
# ============================================================

echo
echo "WH3000 Pro Device definition:"


awk \
    "/^define Device\\/${TARGET_DEVICE}\$/{flag=1} flag{print} /^endef\$/{if(flag){exit}}" \
    "${DEVICE_MK}"


# ============================================================
# 3. 检查 TARGET_DEVICES 注册
#
# 不再要求必须是单独一整行。
#
# 允许：
#
# TARGET_DEVICES += huasifei_wh3000-pro-emmc
#
# TARGET_DEVICES += huasifei_wh3000-pro-emmc \
#
# 或多个 TARGET_DEVICES 写法。
# ============================================================

echo
echo "Checking TARGET_DEVICES registration..."


if grep \
    -Eq \
    "TARGET_DEVICES[[:space:]]*\+=.*${TARGET_DEVICE}" \
    "${DEVICE_MK}"; then

    echo "✅ TARGET_DEVICES registration found."

else

    echo
    echo "⚠️ Direct TARGET_DEVICES registration not found."

    echo
    echo "Searching all references..."

    grep \
        -n \
        "${TARGET_DEVICE}" \
        "${DEVICE_MK}" \
        || true

    echo
    echo "NOTE:"
    echo "The Device definition exists, so continue."
    echo "Final target selection will be verified through Kconfig."

fi


# ============================================================
# 4. 检查 eMMC DTS
# ============================================================

echo
echo "============================================================"
echo " 2. Verify WH3000 Pro eMMC DTS"
echo "============================================================"


if [ ! -f "${DTS_EMMC}" ]; then

    echo
    echo "❌ ERROR:"
    echo "Missing eMMC DTS:"
    echo "${DTS_EMMC}"

    exit 1
fi


echo "✅ eMMC DTS exists:"
echo "${DTS_EMMC}"


# ============================================================
# 5. 检查公共 DTS
# ============================================================

if [ ! -f "${DTS_COMMON}" ]; then

    echo
    echo "❌ ERROR:"
    echo "Missing common WH3000 Pro DTS:"
    echo "${DTS_COMMON}"

    exit 1
fi


echo "✅ Common WH3000 Pro DTS exists."


# ============================================================
# 6. 检查 modem-power
# ============================================================

echo
echo "Checking modem-power definition..."


if grep -q \
    "modem-power" \
    "${DTS_COMMON}"; then

    echo "✅ modem-power found."

else

    echo "⚠️ modem-power node not found."
    echo "Continuing because DTS itself exists."

fi


echo
echo "============================================================"
echo " ✅ Source target verification PASSED"
echo "============================================================"


# ============================================================
# 7. Copy base config
# ============================================================

echo
echo "============================================================"
echo " 3. Copy base config"
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


echo "✅ Base config copied."


# ============================================================
# 8. 清理旧的 Filogic DEVICE
#
# 注意：
#
# 不动：
#
# CONFIG_TARGET_mediatek
# CONFIG_TARGET_mediatek_filogic
# CONFIG_TARGET_DEVICE_mediatek_filogic
#
# 只清理具体 DEVICE。
# ============================================================

echo
echo "============================================================"
echo " 4. Normalize device selection"
echo "============================================================"


sed -i \
    '/^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$/d' \
    .config


echo
echo "Device selections before defconfig:"


grep \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
    .config \
    || echo "None"


# ============================================================
# 9. make defconfig
# ============================================================

echo
echo "============================================================"
echo " 5. make defconfig"
echo "============================================================"


make defconfig


echo
echo "✅ make defconfig completed."


# ============================================================
# 10. 显示 Kconfig 默认选择
# ============================================================

echo
echo "============================================================"
echo " 6. Kconfig selected device"
echo "============================================================"


grep \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
    .config \
    || echo "No device selected."


# ============================================================
# 11. 清理 Kconfig 默认 DEVICE
# ============================================================

echo
echo "============================================================"
echo " 7. Remove Kconfig default device"
echo "============================================================"


sed -i \
    '/^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$/d' \
    .config


echo
echo "After cleanup:"


grep \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
    .config \
    || echo "None"


# ============================================================
# 12. 强制 WH3000 Pro eMMC
# ============================================================

echo
echo "============================================================"
echo " 8. Force WH3000 Pro eMMC target"
echo "============================================================"


cat >> .config <<EOF

# ============================================================
# FanchmWrt WH3000 Pro eMMC
# ============================================================

${TARGET_CONFIG}

EOF


echo
echo "Forced target:"
echo "${TARGET_CONFIG}"


# ============================================================
# 13. 验证 DEVICE 数量
# ============================================================

echo
echo "============================================================"
echo " 9. Verify selected device count"
echo "============================================================"


DEVICE_COUNT="$(
    grep -Ec \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
        .config \
        || true
)"


echo
echo "Device count:"
echo "${DEVICE_COUNT}"


if [ "${DEVICE_COUNT}" -ne 1 ]; then

    echo
    echo "❌ FATAL ERROR"
    echo
    echo "Expected exactly ONE Filogic device."

    echo
    echo "Current selections:"

    grep \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
        .config \
        || true

    exit 1
fi


# ============================================================
# 14. 验证精确 WH3000 Pro
# ============================================================

echo
echo "============================================================"
echo " 10. Verify exact WH3000 Pro target"
echo "============================================================"


if ! grep \
    -qF \
    "${TARGET_CONFIG}" \
    .config; then

    echo
    echo "❌ FATAL ERROR"
    echo
    echo "WH3000 Pro eMMC target was not selected."

    echo
    echo "Current target:"

    grep \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
        .config \
        || true

    exit 1
fi


echo "✅ Exact WH3000 Pro eMMC target selected."


# ============================================================
# 15. Reject OpenWrt One
# ============================================================

echo
echo "============================================================"
echo " 11. Reject OpenWrt One"
echo "============================================================"


if grep \
    -q \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_openwrt_one=y$' \
    .config; then

    echo
    echo "❌ FATAL ERROR"
    echo
    echo "openwrt_one is selected!"

    exit 1
fi


echo "✅ openwrt_one not selected."


# ============================================================
# 16. 验证平台
# ============================================================

echo
echo "============================================================"
echo " 12. Verify target platform"
echo "============================================================"


REQUIRED_CONFIGS=(
    "CONFIG_TARGET_arm=y"
    'CONFIG_TARGET_BOARD="mediatek"'
    'CONFIG_TARGET_SUBTARGET="filogic"'
    "CONFIG_TARGET_mediatek=y"
    "CONFIG_TARGET_mediatek_filogic=y"
    "CONFIG_TARGET_DEVICE_mediatek_filogic=y"
)


for REQUIRED in "${REQUIRED_CONFIGS[@]}"; do

    if ! grep \
        -qF \
        "${REQUIRED}" \
        .config; then

        echo
        echo "❌ FATAL ERROR"
        echo
        echo "Missing:"
        echo "${REQUIRED}"

        exit 1
    fi

done


echo "✅ Platform configuration verified."


# ============================================================
# 17. 显示重要软件包
# ============================================================

echo
echo "============================================================"
echo " 13. Selected packages"
echo "============================================================"


grep \
    -E \
    '^CONFIG_PACKAGE_(luci-app-qmodem-next|luci-app-lucky|lucky|dockerd|containerd|runc|docker)=' \
    .config \
    || true


# ============================================================
# 18. 最终设备
# ============================================================

echo
echo "============================================================"
echo " FINAL SELECTED DEVICE"
echo "============================================================"


grep \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
    .config


# ============================================================
# 19. 重要提醒
# ============================================================

echo
echo "============================================================"
echo " IMPORTANT"
echo "============================================================"

echo
echo "The WH3000 Pro target has now been forced AFTER defconfig."

echo
echo "DO NOT run:"
echo "  make defconfig"
echo "  make olddefconfig"
echo "  make menuconfig"

echo
echo "after this point."


# ============================================================
# 20. 最终成功
# ============================================================

echo
echo "============================================================"
echo " ✅ PREPARE PASSED"
echo "============================================================"

echo
echo "Exact device:"
echo "${TARGET_DEVICE}"

echo
echo "Exact Kconfig:"
echo "${TARGET_CONFIG}"

echo
echo "eMMC DTS:"
echo "mt7981b-huasifei-wh3000-pro-emmc.dts"

echo
echo "WH3000 Pro target is LOCKED."

echo
echo "============================================================"
