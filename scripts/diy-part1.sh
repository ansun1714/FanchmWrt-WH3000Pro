#!/bin/bash
set -euo pipefail

OPENWRT_DIR="${GITHUB_WORKSPACE}/openwrt"
TARGET_DEVICE="${DEVICE:-huasifei_wh3000-pro-emmc}"

# Claude 方案中发现的上游 WH3000 Pro 支持提交
UPSTREAM_REPO="https://github.com/openwrt/openwrt.git"
UPSTREAM_COMMIT="395bb64a"

cd "${OPENWRT_DIR}"

DEVICE_MK="target/linux/mediatek/image/filogic.mk"
DTS_EMMC="target/linux/mediatek/dts/mt7981b-huasifei-wh3000-pro-emmc.dts"
DTS_COMMON="target/linux/mediatek/dts/mt7981b-huasifei-wh3000-pro.dtsi"

echo "============================================================"
echo " FanchmWrt WH3000 Pro | DIY Part 1"
echo " Target: ${TARGET_DEVICE}"
echo "============================================================"

echo "==> Source:"
git describe --tags --always || true
git log -1 --oneline || true

# ============================================================
# 1. QModem
# ============================================================

echo
echo "==> Add QModem feed"

grep -q '^src-git qmodem ' feeds.conf.default || \
    echo 'src-git qmodem https://github.com/FUjr/QModem.git;main' >> feeds.conf.default

# ============================================================
# 2. Lucky
# ============================================================

echo
echo "==> Add Lucky"

rm -rf package/lucky

git clone --depth=1 \
    https://github.com/gdy666/luci-app-lucky.git \
    package/lucky

# ============================================================
# 3. Feeds
# ============================================================

echo
echo "==> Update/install feeds"

./scripts/feeds update -a
./scripts/feeds install -a

# QModem 再单独刷新一次
./scripts/feeds update qmodem
./scripts/feeds install -a -f -p qmodem

# ============================================================
# 4. WH3000 Pro support verification function
# ============================================================

verify_wh3000_pro() {

    grep -qE \
        "^define Device/${TARGET_DEVICE}$" \
        "${DEVICE_MK}" &&

    grep -qE \
        "^TARGET_DEVICES \+= ${TARGET_DEVICE}$" \
        "${DEVICE_MK}" &&

    test -f "${DTS_EMMC}" &&

    test -f "${DTS_COMMON}"
}

# ============================================================
# 5. Check native WH3000 Pro support
# ============================================================

echo
echo "============================================================"
echo " Checking WH3000 Pro eMMC hardware support"
echo "============================================================"

if verify_wh3000_pro; then

    echo
    echo "✅ Native WH3000 Pro eMMC support FOUND."
    echo "   No upstream cherry-pick is required."

else

    # ========================================================
    # 6. Claude fallback:
    #    FanchmWrt 没有设备支持 → 从 OpenWrt 移植
    # ========================================================

    echo
    echo "⚠️ Native WH3000 Pro eMMC support NOT FOUND."
    echo
    echo "Starting upstream fallback."
    echo "Upstream repository:"
    echo "${UPSTREAM_REPO}"
    echo
    echo "Upstream commit:"
    echo "${UPSTREAM_COMMIT}"

    git config user.email "ci@build.local"
    git config user.name "FanchmWrt CI"

    # 添加 / 更新 upstream remote
    if git remote get-url upstream-owrt >/dev/null 2>&1; then

        git remote set-url \
            upstream-owrt \
            "${UPSTREAM_REPO}"

    else

        git remote add \
            upstream-owrt \
            "${UPSTREAM_REPO}"

    fi

    BASE_COMMIT="$(git rev-parse HEAD)"

    echo
    echo "==> Fetch upstream WH3000 Pro support"

    git fetch \
        --no-tags \
        --depth=1 \
        upstream-owrt \
        "${UPSTREAM_COMMIT}"

    # ========================================================
    # 7. Try normal cherry-pick
    # ========================================================

    echo
    echo "==> Apply upstream commit"

    if git cherry-pick \
        --no-edit \
        "${UPSTREAM_COMMIT}"; then

        echo
        echo "✅ Normal cherry-pick succeeded."

    else

        # ====================================================
        # 8. 如果是 merge commit，则尝试 -m 1
        # ====================================================

        echo
        echo "⚠️ Normal cherry-pick failed."
        echo "Trying merge commit mode (-m 1)."

        git cherry-pick --abort 2>/dev/null || true

        if ! git cherry-pick \
            -m 1 \
            --no-edit \
            "${UPSTREAM_COMMIT}"; then

            git cherry-pick --abort 2>/dev/null || true

            git reset --hard "${BASE_COMMIT}"

            echo
            echo "============================================================"
            echo "❌ ERROR"
            echo "============================================================"
            echo
            echo "Unable to import WH3000 Pro support."
            echo
            echo "The build is intentionally stopped."
            echo "No firmware will be compiled."
            echo

            exit 1
        fi
    fi

    # ========================================================
    # 9. Verify imported support
    # ========================================================

    echo
    echo "==> Verify imported WH3000 Pro support"

    if ! verify_wh3000_pro; then

        git reset --hard "${BASE_COMMIT}"

        echo
        echo "============================================================"
        echo "❌ ERROR"
        echo "============================================================"
        echo
        echo "Upstream commit was applied,"
        echo "but exact WH3000 Pro eMMC support is still missing."
        echo
        echo "Expected:"
        echo "  Device: ${TARGET_DEVICE}"
        echo "  DTS:    mt7981b-huasifei-wh3000-pro-emmc.dts"
        echo
        echo "The build is intentionally stopped."
        echo

        exit 1
    fi

    echo
    echo "============================================================"
    echo "✅ FALLBACK IMPORT SUCCESS"
    echo "============================================================"
fi

# ============================================================
# 10. Final hardware verification
# ============================================================

echo
echo "============================================================"
echo " Final WH3000 Pro hardware verification"
echo "============================================================"

echo
echo "==> Image definition"

grep -n \
    -A15 \
    -B2 \
    "^define Device/${TARGET_DEVICE}$" \
    "${DEVICE_MK}"

echo
echo "==> TARGET_DEVICES registration"

grep -n \
    "^TARGET_DEVICES += ${TARGET_DEVICE}$" \
    "${DEVICE_MK}"

echo
echo "==> eMMC DTS"

test -f "${DTS_EMMC}"
test -f "${DTS_COMMON}"

ls -lh \
    "${DTS_EMMC}" \
    "${DTS_COMMON}"

echo
echo "==> modem-power GPIO"

grep -n \
    -A8 \
    -B2 \
    'modem-power' \
    "${DTS_COMMON}"

echo
echo "============================================================"
echo "✅ DIY PART 1 HARDWARE CHECK PASSED"
echo "============================================================"

echo
echo "TARGET_DEVICE=${TARGET_DEVICE}"

echo
echo "IMPORTANT:"
echo "No DETECTED_DEVICE variable is used."
echo "The exact WH3000 Pro eMMC profile will be selected by prepare.sh."

echo
