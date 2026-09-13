#!/bin/bash

set -euo pipefail

# ============================================================
# FanchmWrt WH3000 Pro eMMC
# prepare.sh
#
# FINAL VERSION
#
# 核心目标：
#   huasifei_wh3000-pro-emmc
#
# 核心原则：
#
#   1. 检查 WH3000 Pro Device 定义
#   2. 检查 WH3000 Pro eMMC DTS
#   3. 检查公共 DTS
#   4. 检查 modem-power
#   5. 复制基础配置
#   6. 清理旧 DEVICE
#   7. 执行一次 make defconfig
#   8. 清理 Kconfig 自动选择的 DEVICE
#   9. 强制写入 WH3000 Pro eMMC DEVICE
#  10. 强制写入后不再执行任何 defconfig
#  11. 严格验证最终目标
#
# 非常重要：
#
# 本脚本结束以后：
#
#   禁止 make defconfig
#   禁止 make olddefconfig
#   禁止 make menuconfig
#
# 否则可能重新改变 DEVICE 选择。
# ============================================================


# ============================================================
# 0. Variables
# ============================================================

OPENWRT_DIR="${GITHUB_WORKSPACE}/openwrt"

CONFIG_FILE="${GITHUB_WORKSPACE}/config/wh3000pro.config"

TARGET_DEVICE="${DEVICE:-huasifei_wh3000-pro-emmc}"

TARGET_SYMBOL="${TARGET_DEVICE//-/_}"

TARGET_CONFIG="CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_${TARGET_SYMBOL}=y"

DEVICE_MK="target/linux/mediatek/image/filogic.mk"

DTS_EMMC="target/linux/mediatek/dts/mt7981b-huasifei_wh3000-pro-emmc.dts"

DTS_COMMON="target/linux/mediatek/dts/mt7981b-huasifei_wh3000-pro.dtsi"


# ============================================================
# 0.1 Enter OpenWrt
# ============================================================

cd "${OPENWRT_DIR}"


# ============================================================
# Header
# ============================================================

echo
echo "============================================================"
echo " FanchmWrt WH3000 Pro eMMC | PREPARE"
echo "============================================================"

echo
echo "OpenWrt directory:"
echo "${OPENWRT_DIR}"

echo
echo "Target device:"
echo "${TARGET_DEVICE}"

echo
echo "Target symbol:"
echo "${TARGET_SYMBOL}"

echo
echo "Expected Kconfig:"
echo "${TARGET_CONFIG}"


# ============================================================
# 1. Verify Device Makefile
# ============================================================

echo
echo "============================================================"
echo " 1. Verify WH3000 Pro Device definition"
echo "============================================================"


if [ ! -f "${DEVICE_MK}" ]; then

    echo
    echo "❌ FATAL ERROR"
    echo
    echo "Device Makefile not found:"
    echo "${DEVICE_MK}"

    exit 1
fi


echo
echo "Checking:"
echo "${DEVICE_MK}"


if ! grep -q \
    "define Device/${TARGET_DEVICE}" \
    "${DEVICE_MK}"; then

    echo
    echo "❌ FATAL ERROR"
    echo
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


echo
echo "✅ WH3000 Pro Device definition exists."


# ============================================================
# 2. Display Device definition
# ============================================================

echo
echo "============================================================"
echo " 2. WH3000 Pro Device definition"
echo "============================================================"


awk \
    "/^define Device\\/${TARGET_DEVICE}\$/{flag=1} flag{print} /^endef\$/{if(flag){exit}}" \
    "${DEVICE_MK}"


# ============================================================
# 3. Verify TARGET_DEVICES registration
# ============================================================

echo
echo "============================================================"
echo " 3. Verify TARGET_DEVICES registration"
echo "============================================================"


if grep \
    -Eq \
    "TARGET_DEVICES[[:space:]]*\+=.*${TARGET_DEVICE}" \
    "${DEVICE_MK}"; then

    echo
    echo "✅ TARGET_DEVICES registration found."

else

    echo
    echo "⚠️ Direct TARGET_DEVICES registration not found."

    echo
    echo "Searching all references:"

    grep \
        -n \
        "${TARGET_DEVICE}" \
        "${DEVICE_MK}" \
        || true

    echo
    echo "NOTE:"
    echo "Device definition exists."
    echo "Continue with Kconfig verification."

fi


# ============================================================
# 4. Verify eMMC DTS
# ============================================================

echo
echo "============================================================"
echo " 4. Verify WH3000 Pro eMMC DTS"
echo "============================================================"


if [ ! -f "${DTS_EMMC}" ]; then

    echo
    echo "❌ FATAL ERROR"
    echo
    echo "Missing eMMC DTS:"
    echo "${DTS_EMMC}"

    exit 1
fi


echo
echo "✅ eMMC DTS exists:"
echo "${DTS_EMMC}"


# ============================================================
# 5. Verify common WH3000 Pro DTS
# ============================================================

echo
echo "============================================================"
echo " 5. Verify common WH3000 Pro DTS"
echo "============================================================"


if [ ! -f "${DTS_COMMON}" ]; then

    echo
    echo "❌ FATAL ERROR"
    echo
    echo "Missing common DTS:"
    echo "${DTS_COMMON}"

    exit 1
fi


echo
echo "✅ Common WH3000 Pro DTS exists:"
echo "${DTS_COMMON}"


# ============================================================
# 6. Verify modem-power
# ============================================================

echo
echo "============================================================"
echo " 6. Verify modem-power"
echo "============================================================"


echo
echo "Searching modem-power in common DTS..."


if grep \
    -q \
    "modem-power" \
    "${DTS_COMMON}"; then

    echo
    echo "✅ modem-power definition found."

else

    echo
    echo "⚠️ modem-power node not found."

    echo
    echo "This is NOT treated as a fatal error."

    echo "DTS exists, so continue."

fi


# ============================================================
# 7. Source verification passed
# ============================================================

echo
echo "============================================================"
echo " ✅ SOURCE TARGET VERIFICATION PASSED"
echo "============================================================"


# ============================================================
# 8. Verify config file
# ============================================================

echo
echo "============================================================"
echo " 7. Verify base config"
echo "============================================================"


if [ ! -f "${CONFIG_FILE}" ]; then

    echo
    echo "❌ FATAL ERROR"
    echo
    echo "Config file not found:"
    echo "${CONFIG_FILE}"

    exit 1
fi


echo
echo "Config file:"
echo "${CONFIG_FILE}"


# ============================================================
# 9. Copy base config
# ============================================================

echo
echo "============================================================"
echo " 8. Copy base config"
echo "============================================================"


cp \
    "${CONFIG_FILE}" \
    .config


echo
echo "✅ Base config copied."


# ============================================================
# 10. Normalize old DEVICE selections
#
# 这里只清理具体 DEVICE。
#
# 不删除：
#
# CONFIG_TARGET_mediatek
# CONFIG_TARGET_mediatek_filogic
# CONFIG_TARGET_DEVICE_mediatek_filogic
#
# ============================================================

echo
echo "============================================================"
echo " 9. Normalize DEVICE selection"
echo "============================================================"


sed -i \
    '/^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$/d' \
    .config


echo
echo "DEVICE selections before defconfig:"


grep \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
    .config \
    || echo "None"


# ============================================================
# 11. make defconfig
#
# 这是本脚本唯一一次 defconfig。
#
# defconfig 的作用：
#   让基础配置完成 Kconfig 依赖解析。
#
# 注意：
#   defconfig 可能自动选择一个默认 DEVICE。
#
# 后面我们会清理它。
# ============================================================

echo
echo "============================================================"
echo " 10. make defconfig"
echo "============================================================"


make defconfig


echo
echo "✅ make defconfig completed."


# ============================================================
# 12. Show Kconfig selected DEVICE
# ============================================================

echo
echo "============================================================"
echo " 11. Kconfig selected DEVICE"
echo "============================================================"


KCONFIG_DEVICE_COUNT="$(
    grep -Ec \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
        .config \
        || true
)"


echo
echo "Kconfig selected device count:"
echo "${KCONFIG_DEVICE_COUNT}"


echo
echo "Kconfig selected devices:"


grep \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
    .config \
    || echo "No device selected."


# ============================================================
# 13. Remove Kconfig selected DEVICE
# ============================================================

echo
echo "============================================================"
echo " 12. Remove Kconfig selected DEVICE"
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
# 14. Force exact WH3000 Pro eMMC
#
# 重要：
#
# 从这里开始：
#
# 不再运行 make defconfig
# 不再运行 make olddefconfig
#
# ============================================================

echo
echo "============================================================"
echo " 13. Force WH3000 Pro eMMC target"
echo "============================================================"


cat >> .config <<EOF

# ============================================================
# FanchmWrt WH3000 Pro eMMC
# Forced by prepare.sh AFTER defconfig
# ============================================================

${TARGET_CONFIG}

EOF


echo
echo "Forced target:"
echo "${TARGET_CONFIG}"


# ============================================================
# 15. Verify DEVICE count
# ============================================================

echo
echo "============================================================"
echo " 14. Verify selected DEVICE count"
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


echo
echo "✅ Exactly one Filogic device selected."


# ============================================================
# 16. Verify exact WH3000 Pro target
# ============================================================

echo
echo "============================================================"
echo " 15. Verify exact WH3000 Pro target"
echo "============================================================"


if ! grep \
    -qF \
    "${TARGET_CONFIG}" \
    .config; then

    echo
    echo "❌ FATAL ERROR"
    echo
    echo "WH3000 Pro eMMC target was NOT selected."

    echo
    echo "Current target:"

    grep \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
        .config \
        || true

    exit 1
fi


echo
echo "✅ Exact WH3000 Pro eMMC target selected."


# ============================================================
# 17. Reject OpenWrt One
# ============================================================

echo
echo "============================================================"
echo " 16. Reject OpenWrt One"
echo "============================================================"


if grep \
    -q \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_openwrt_one=y$' \
    .config; then

    echo
    echo "❌ FATAL ERROR"
    echo
    echo "OpenWrt One is selected!"

    exit 1
fi


echo
echo "✅ OpenWrt One not selected."


# ============================================================
# 18. Verify target platform
#
# 注意：
#
# 不要求 CONFIG_TARGET_arm=y
#
# 真正关键的是：
#
#   CONFIG_TARGET_mediatek=y
#   CONFIG_TARGET_mediatek_filogic=y
#   CONFIG_TARGET_DEVICE_mediatek_filogic=y
#
# ============================================================

echo
echo "============================================================"
echo " 17. Verify target platform"
echo "============================================================"


REQUIRED_CONFIGS=(
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
        echo "Missing required target configuration:"
        echo "${REQUIRED}"

        echo
        echo "Current target configuration:"

        grep \
            -E \
            '^CONFIG_TARGET_(BOARD|SUBTARGET|mediatek|DEVICE_mediatek)' \
            .config \
            || true

        exit 1
    fi

done


echo
echo "✅ MediaTek target verified."
echo "✅ Filogic subtarget verified."
echo "✅ Device framework verified."


# ============================================================
# 19. Verify target information
# ============================================================

echo
echo "============================================================"
echo " 18. Target information"
echo "============================================================"


echo
echo "TARGET_BOARD:"
grep \
    '^CONFIG_TARGET_BOARD=' \
    .config \
    || true


echo
echo "TARGET_SUBTARGET:"
grep \
    '^CONFIG_TARGET_SUBTARGET=' \
    .config \
    || true


echo
echo "TARGET_DEVICE:"
grep \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
    .config \
    || true


# ============================================================
# 20. Selected packages
# ============================================================

echo
echo "============================================================"
echo " 19. Selected packages"
echo "============================================================"


grep \
    -E \
    '^CONFIG_PACKAGE_(luci-app-qmodem-next|luci-app-lucky|lucky|dockerd|containerd|runc|docker)=' \
    .config \
    || true


# ============================================================
# 21. Verify important modem packages
# ============================================================

echo
echo "============================================================"
echo " 20. Verify QModem packages"
echo "============================================================"


grep \
    -E \
    '^CONFIG_PACKAGE_(luci-app-qmodem-next|usb-modeswitch|usbutils|comgt|chat|libqmi|qmi-utils|libmbim|mbim-utils|modemmanager)=' \
    .config \
    || true


# ============================================================
# 22. Final selected DEVICE
# ============================================================

echo
echo "============================================================"
echo " 21. FINAL SELECTED DEVICE"
echo "============================================================"


grep \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
    .config


# ============================================================
# 23. Final exact verification
# ============================================================

echo
echo "============================================================"
echo " 22. FINAL EXACT VERIFICATION"
echo "============================================================"


FINAL_DEVICE_COUNT="$(
    grep -Ec \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
        .config \
        || true
)"


if [ "${FINAL_DEVICE_COUNT}" -ne 1 ]; then

    echo
    echo "❌ FATAL ERROR"
    echo
    echo "Expected exactly ONE Filogic device."
    echo
    echo "Found:"
    echo "${FINAL_DEVICE_COUNT}"

    exit 1
fi


if ! grep \
    -qF \
    "${TARGET_CONFIG}" \
    .config; then

    echo
    echo "❌ FATAL ERROR"
    echo
    echo "Final target is NOT WH3000 Pro eMMC."

    exit 1
fi


if grep \
    -q \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_openwrt_one=y$' \
    .config; then

    echo
    echo "❌ FATAL ERROR"
    echo
    echo "OpenWrt One detected."

    exit 1
fi


# ============================================================
# 24. Final result
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
echo "Platform:"
echo "mediatek / filogic"

echo
echo "eMMC DTS:"
echo "mt7981b-huasifei-wh3000-pro-emmc.dts"

echo
echo "Common DTS:"
echo "mt7981b-huasifei-wh3000-pro.dtsi"

echo
echo "OpenWrt One:"
echo "NOT selected"

echo
echo "Device count:"
echo "${FINAL_DEVICE_COUNT}"

echo
echo "============================================================"
echo " IMPORTANT"
echo "============================================================"

echo
echo "WH3000 Pro eMMC target has been LOCKED."

echo
echo "From this point onward:"
echo
echo "  ❌ DO NOT run: make defconfig"
echo "  ❌ DO NOT run: make olddefconfig"
echo "  ❌ DO NOT run: make menuconfig"

echo
echo "Continue directly with:"
echo
echo "  make download"
echo "  make -j2"

echo
echo "============================================================"
echo " FanchmWrt WH3000 Pro PREPARE FINISHED"
echo "============================================================"

echo
