#!/bin/bash
set -euo pipefail

OPENWRT_DIR="${GITHUB_WORKSPACE}/openwrt"

CONFIG_FILE="${GITHUB_WORKSPACE}/config/wh3000pro.config"

TARGET_DEVICE="${DEVICE:-huasifei_wh3000-pro-emmc}"

TARGET_SYMBOL="${TARGET_DEVICE//-/_}"

TARGET_CONFIG="CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_${TARGET_SYMBOL}=y"

cd "${OPENWRT_DIR}"

DEVICE_MK="target/linux/mediatek/image/filogic.mk"

DTS_EMMC="target/linux/mediatek/dts/mt7981b-huasifei-wh3000-pro-emmc.dts"

DTS_COMMON="target/linux/mediatek/dts/mt7981b-huasifei-wh3000-pro.dtsi"

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

grep -qE \
    "^define Device/${TARGET_DEVICE}$" \
    "${DEVICE_MK}" || {

    echo
    echo "❌ ERROR:"
    echo "${TARGET_DEVICE} is NOT defined."

    exit 1
}

grep -qE \
    "^TARGET_DEVICES \+= ${TARGET_DEVICE}$" \
    "${DEVICE_MK}" || {

    echo
    echo "❌ ERROR:"
    echo "${TARGET_DEVICE} is NOT registered in TARGET_DEVICES."

    exit 1
}

test -f "${DTS_EMMC}" || {

    echo
    echo "❌ ERROR:"
    echo "Missing:"
    echo "${DTS_EMMC}"

    exit 1
}

test -f "${DTS_COMMON}" || {

    echo
    echo "❌ ERROR:"
    echo "Missing:"
    echo "${DTS_COMMON}"

    exit 1
}

echo
echo "✅ Source target verified."

# ============================================================
# 2. Copy config
# ============================================================

echo
echo "============================================================"
echo " 2. Copy base config"
echo "============================================================"

cp \
    "${CONFIG_FILE}" \
    .config

# ============================================================
# 3. Force exact target
# ============================================================

echo
echo "============================================================"
echo " 3. Force WH3000 Pro eMMC target"
echo "============================================================"

# 删除所有已有 Filogic DEVICE 选择
#
# 防止旧 config / 默认 config 选择：
#
# openwrt_one
# bananapi_bpi-r4
# cmcc_rax3000m
# 等其它设备
#
sed -i \
    '/^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$/d' \
    .config

cat >> .config <<EOF

# ============================================================
# FORCE Huasifei WH3000 Pro eMMC
# ============================================================

CONFIG_TARGET_arm=y

CONFIG_TARGET_BOARD="mediatek"

CONFIG_TARGET_SUBTARGET="filogic"

CONFIG_TARGET_mediatek=y

CONFIG_TARGET_mediatek_filogic=y

CONFIG_TARGET_DEVICE_mediatek_filogic=y

${TARGET_CONFIG}

EOF

echo
echo "Forced target:"
echo "${TARGET_CONFIG}"

# ============================================================
# 4. make defconfig
# ============================================================

echo
echo "============================================================"
echo " 4. make defconfig"
echo "============================================================"

make defconfig

# ============================================================
# 5. Verify defconfig
# ============================================================

echo
echo "============================================================"
echo " 5. Verify final target after defconfig"
echo "============================================================"

if ! grep -qF \
    "${TARGET_CONFIG}" \
    .config; then

    echo
    echo "============================================================"
    echo "❌ FATAL ERROR"
    echo "============================================================"

    echo
    echo "make defconfig REMOVED WH3000 Pro!"

    echo
    echo "Current selected device:"

    grep \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
        .config || true

    exit 1
fi

# ============================================================
# 6. Exactly ONE device
# ============================================================

DEVICE_COUNT="$(
    grep -Ec \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
        .config || true
)"

if [ "${DEVICE_COUNT}" -ne 1 ]; then

    echo
    echo "============================================================"
    echo "❌ FATAL ERROR"
    echo "============================================================"

    echo
    echo "Expected exactly ONE Filogic device."

    echo
    echo "Found:"
    echo "${DEVICE_COUNT}"

    echo
    echo "Selected devices:"

    grep \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
        .config || true

    exit 1
fi

# ============================================================
# 7. Explicitly reject OpenWrt One
# ============================================================

if grep -q \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_openwrt_one=y$' \
    .config; then

    echo
    echo "============================================================"
    echo "❌ FATAL ERROR"
    echo "============================================================"

    echo
    echo "openwrt_one was selected!"

    echo
    echo "This firmware will NOT be compiled."

    exit 1
fi

# ============================================================
# 8. Print final device
# ============================================================

echo
echo "============================================================"
echo " FINAL SELECTED DEVICE"
echo "============================================================"

grep \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
    .config

# ============================================================
# 9. Important packages
# ============================================================

echo
echo "============================================================"
echo " IMPORTANT PACKAGES"
echo "============================================================"

grep -E \
    '^CONFIG_PACKAGE_(luci-app-qmodem-next|luci-app-lucky|lucky|dockerd|containerd|runc|docker)=' \
    .config || true

# ============================================================
# 10. Print image definition
# ============================================================

echo
echo "============================================================"
echo " WH3000 Pro IMAGE DEFINITION"
echo "============================================================"

grep -n \
    -A15 \
    -B2 \
    "^define Device/${TARGET_DEVICE}$" \
    "${DEVICE_MK}"

# ============================================================
# 11. Done
# ============================================================

echo
echo "============================================================"
echo "✅ PREPARE PASSED"
echo "============================================================"

echo
echo "Exact target:"
echo "${TARGET_DEVICE}"

echo
echo "Exact Kconfig:"
echo "${TARGET_CONFIG}"

echo
