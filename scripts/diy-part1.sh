#!/bin/bash
set -euo pipefail

OPENWRT_DIR="${GITHUB_WORKSPACE}/openwrt"
TARGET_DEVICE="${DEVICE:-huasifei-wh3000-pro-emmc}"

DEVICE_MK="target/linux/mediatek/image/filogic.mk"
DTS_EMMC="target/linux/mediatek/dts/mt7981b-huasifei-wh3000-pro-emmc.dts"
DTS_COMMON="target/linux/mediatek/dts/mt7981b-huasifei-wh3000-pro.dtsi"

echo "============================================================"
echo " FanchmWrt WH3000 Pro | DIY Part 1"
echo "============================================================"

echo
echo "Target:"
echo "${TARGET_DEVICE}"

cd "${OPENWRT_DIR}"

echo
echo "============================================================"
echo " 1. Source information"
echo "============================================================"

echo
echo "Git remote:"
git remote -v

echo
echo "Git tag:"
git describe --tags --always || true

echo
echo "Git commit:"
git rev-parse HEAD

# ============================================================
# QModem
# ============================================================

echo
echo "============================================================"
echo " 2. Add QModem feed"
echo "============================================================"

if grep -q '^src-git qmodem ' feeds.conf.default; then
    echo "QModem feed already exists."
else
    echo 'src-git qmodem https://github.com/FUjr/QModem.git;main' \
        >> feeds.conf.default

    echo "QModem feed added."
fi

# ============================================================
# Lucky
# ============================================================

echo
echo "============================================================"
echo " 3. Add Lucky"
echo "============================================================"

rm -rf package/lucky

git clone \
    --depth=1 \
    https://github.com/gdy666/luci-app-lucky.git \
    package/lucky

echo
echo "Lucky cloned successfully."

# ============================================================
# Feeds
# ============================================================

echo
echo "============================================================"
echo " 4. Update feeds"
echo "============================================================"

./scripts/feeds update -a

echo
echo "Install all feeds:"
./scripts/feeds install -a

echo
echo "Force install QModem:"
./scripts/feeds update qmodem
./scripts/feeds install -a -f -p qmodem

# ============================================================
# Hardware verification
# ============================================================

echo
echo "============================================================"
echo " 5. Verify WH3000 Pro hardware support"
echo "============================================================"

echo
echo "Device Makefile:"
echo "${DEVICE_MK}"

echo
echo "eMMC DTS:"
echo "${DTS_EMMC}"

echo
echo "Common DTS:"
echo "${DTS_COMMON}"

# ------------------------------------------------------------
# Device definition
# ------------------------------------------------------------

echo
echo "------------------------------------------------------------"
echo "Checking Device definition..."
echo "------------------------------------------------------------"

if ! grep -qE \
    "^define Device/${TARGET_DEVICE}$" \
    "${DEVICE_MK}"; then

    echo
    echo "❌ ERROR:"
    echo "WH3000 Pro Device definition not found:"
    echo "${TARGET_DEVICE}"

    exit 1
fi

echo
echo "✅ Device definition exists."

# ------------------------------------------------------------
# TARGET_DEVICES
# ------------------------------------------------------------

echo
echo "------------------------------------------------------------"
echo "Checking TARGET_DEVICES..."
echo "------------------------------------------------------------"

if ! grep -qE \
    "^TARGET_DEVICES[[:space:]]*\+=[[:space:]]*${TARGET_DEVICE}$" \
    "${DEVICE_MK}"; then

    echo
    echo "❌ ERROR:"
    echo "WH3000 Pro TARGET_DEVICES registration not found."

    exit 1
fi

echo
echo "✅ TARGET_DEVICES registration exists."

# ------------------------------------------------------------
# eMMC DTS
# ------------------------------------------------------------

echo
echo "------------------------------------------------------------"
echo "Checking eMMC DTS..."
echo "------------------------------------------------------------"

if [ ! -f "${DTS_EMMC}" ]; then

    echo
    echo "============================================================"
    echo "❌ FATAL ERROR"
    echo "============================================================"

    echo
    echo "Missing eMMC DTS:"
    echo "${DTS_EMMC}"

    echo
    echo "WH3000 related DTS files currently present:"
    find target/linux/mediatek/dts \
        -maxdepth 1 \
        -type f \
        -iname "*huasifei*" \
        -print \
        | sort

    exit 1
fi

echo
echo "✅ eMMC DTS exists."

# ------------------------------------------------------------
# Common DTS
# ------------------------------------------------------------

echo
echo "------------------------------------------------------------"
echo "Checking common DTS..."
echo "------------------------------------------------------------"

if [ ! -f "${DTS_COMMON}" ]; then

    echo
    echo "❌ FATAL ERROR"
    echo
    echo "Missing common DTS:"
    echo "${DTS_COMMON}"

    exit 1
fi

echo
echo "✅ Common DTS exists."

# ============================================================
# Display Device definition
# ============================================================

echo
echo "============================================================"
echo " 6. WH3000 Pro Device definition"
echo "============================================================"

grep -n \
    -A18 \
    -B2 \
    "^define Device/${TARGET_DEVICE}$" \
    "${DEVICE_MK}"

# ============================================================
# Display DTS
# ============================================================

echo
echo "============================================================"
echo " 7. WH3000 Pro DTS"
echo "============================================================"

ls -lh \
    "${DTS_EMMC}" \
    "${DTS_COMMON}"

echo
echo "eMMC DTS content:"
sed -n '1,120p' "${DTS_EMMC}"

# ============================================================
# modem-power
# ============================================================

echo
echo "============================================================"
echo " 8. Check modem-power GPIO"
echo "============================================================"

if grep -q 'modem-power' "${DTS_COMMON}"; then

    echo
    echo "modem-power found:"

    grep -n \
        -A12 \
        -B3 \
        'modem-power' \
        "${DTS_COMMON}" \
        || true

else

    echo
    echo "⚠️ WARNING:"
    echo "modem-power node was not found in common DTS."

fi

# ============================================================
# Final
# ============================================================

echo
echo "============================================================"
echo "✅ DIY PART 1 HARDWARE CHECK PASSED"
echo "============================================================"

echo
echo "TARGET_DEVICE=${TARGET_DEVICE}"

echo
echo "Important:"
echo "No OpenWrt upstream cherry-pick is performed."
echo "FanchmWrt ${FANCHMWRT_TAG:-unknown} is used as-is."
echo
