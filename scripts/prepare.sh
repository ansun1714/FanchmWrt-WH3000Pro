#!/bin/bash

set -euo pipefail

# ============================================================
# FanchmWrt WH3000 Pro eMMC
# Prepare / Target Lock
#
# 重要原则：
# 1. 先准备完整目标配置
# 2. 在 make defconfig 之前锁定 WH3000 Pro
# 3. make defconfig 只执行一次
# 4. defconfig 之后绝不再修改设备选择
# 5. defconfig 后只进行验证
# ============================================================

ROOT_DIR="${GITHUB_WORKSPACE:-$(pwd)}"
BUILD_DIR="${ROOT_DIR}/openwrt"

cd "${BUILD_DIR}"

# ============================================================
# 变量定义
# ============================================================

TARGET_DEVICE="${DEVICE:-huasifei_wh3000-pro-emmc}"

# Device ID:
# huasifei_wh3000-pro-emmc
#
# Kconfig:
# huasifei_wh3000_pro_emmc
TARGET_SYMBOL="${TARGET_DEVICE//-/_}"

TARGET_CONFIG="CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_${TARGET_SYMBOL}=y"

DEVICE_MK="target/linux/mediatek/image/filogic.mk"

DTS_EMMC="target/linux/mediatek/dts/mt7981b-huasifei-wh3000-pro-emmc.dts"

DTS_COMMON="target/linux/mediatek/dts/mt7981b-huasifei-wh3000-pro.dtsi"

USER_CONFIG="${ROOT_DIR}/config/wh3000pro.config"

echo
echo "============================================================"
echo " FanchmWrt WH3000 Pro eMMC Prepare"
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
# 1. 基础目录检查
# ============================================================

echo
echo "============================================================"
echo " 1. 基础目录检查"
echo "============================================================"

if [ ! -d "${BUILD_DIR}" ]; then
    echo "❌ Build directory 不存在:"
    echo "${BUILD_DIR}"
    exit 1
fi

if [ ! -f "${DEVICE_MK}" ]; then
    echo "❌ Device Makefile 不存在:"
    echo "${DEVICE_MK}"
    exit 1
fi

if [ ! -f "${DTS_EMMC}" ]; then
    echo "❌ WH3000 Pro eMMC DTS 不存在:"
    echo "${DTS_EMMC}"
    exit 1
fi

if [ ! -f "${DTS_COMMON}" ]; then
    echo "❌ WH3000 Pro common DTS 不存在:"
    echo "${DTS_COMMON}"
    exit 1
fi

if [ ! -f "${USER_CONFIG}" ]; then
    echo "❌ 用户配置不存在:"
    echo "${USER_CONFIG}"
    exit 1
fi

echo "✅ Build directory OK"
echo "✅ Device Makefile OK"
echo "✅ WH3000 Pro eMMC DTS OK"
echo "✅ WH3000 Pro common DTS OK"
echo "✅ wh3000pro.config OK"

# ============================================================
# 2. 检查 Device 定义
# ============================================================

echo
echo "============================================================"
echo " 2. 检查 Device 定义"
echo "============================================================"

if ! grep -q "^define Device/${TARGET_DEVICE}$" "${DEVICE_MK}"; then

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

if ! grep -q "^TARGET_DEVICES += ${TARGET_DEVICE}$" "${DEVICE_MK}"; then

    echo
    echo "❌ TARGET_DEVICES 中没有 WH3000 Pro eMMC"

    exit 1
fi

echo "✅ TARGET_DEVICES exists"

# ============================================================
# 4. 检查 DTS 文件
# ============================================================

echo
echo "============================================================"
echo " 4. 检查 DTS"
echo "============================================================"

echo
echo "WH3000 Pro eMMC DTS:"
echo "${DTS_EMMC}"

ls -lh "${DTS_EMMC}"

echo
echo "WH3000 Pro common DTS:"
echo "${DTS_COMMON}"

ls -lh "${DTS_COMMON}"

echo
echo "✅ DTS 文件及路径正确"

# ============================================================
# 5. 检查 Device DTS 引用
# ============================================================

echo
echo "============================================================"
echo " 5. 检查 Device DTS 引用"
echo "============================================================"

if ! grep -q \
    "DEVICE_DTS := mt7981b-huasifei-wh3000-pro-emmc" \
    "${DEVICE_MK}"; then

    echo
    echo "❌ Device Makefile 中 DTS 引用错误"

    echo
    echo "实际相关内容:"
    grep -n -A20 -B2 \
        "^define Device/${TARGET_DEVICE}$" \
        "${DEVICE_MK}" \
        || true

    exit 1
fi

echo "✅ Device DTS 引用正确"

# ============================================================
# 6. 导入用户配置
# ============================================================

echo
echo "============================================================"
echo " 6. 导入 WH3000 Pro 用户配置"
echo "============================================================"

cp -f "${USER_CONFIG}" .config

echo "✅ wh3000pro.config 已复制到 .config"

# ============================================================
# 7. 清理旧设备选择
# ============================================================

echo
echo "============================================================"
echo " 7. 清理旧 Filogic Device"
echo "============================================================"

# 删除所有 Filogic Device 选择
sed -i \
    '/^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_/d' \
    .config

# 再明确删除可能存在的错误 WH3000 Pro 配置
sed -i \
    '/^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_huasifei-wh3000-pro-emmc=/d' \
    .config

sed -i \
    '/^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_huasifei_wh3000_pro_emmc=/d' \
    .config

echo "✅ 已清除所有旧 Filogic Device"

echo
echo "清理后检查:"
grep -E \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_' \
    .config \
    || echo "（当前没有 Filogic Device）"

# ============================================================
# 8. 清理 OpenWrt One
# ============================================================

echo
echo "============================================================"
echo " 8. 清理 OpenWrt One"
echo "============================================================"

sed -i \
    '/^CONFIG_TARGET_mediatek_filogic_DEVICE_openwrt_one=y$/d' \
    .config

echo "✅ OpenWrt One 已清除"

# ============================================================
# 9. 清理 TARGET_PROFILE
# ============================================================

echo
echo "============================================================"
echo " 9. 清理 CONFIG_TARGET_PROFILE"
echo "============================================================"

sed -i \
    '/^CONFIG_TARGET_PROFILE=/d' \
    .config

echo "✅ CONFIG_TARGET_PROFILE 已清除"

# ============================================================
# 10. 确保 MediaTek / Filogic 基础 Target
# ============================================================

echo
echo "============================================================"
echo " 10. 设置 MediaTek / Filogic 基础 Target"
echo "============================================================"

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

echo "✅ CONFIG_TARGET_mediatek=y"
echo "✅ CONFIG_TARGET_mediatek_filogic=y"

# ============================================================
# ★★★ 11. 在 defconfig 之前锁定 WH3000 Pro
# ============================================================

echo
echo "============================================================"
echo " 11. 在 defconfig 之前锁定 WH3000 Pro eMMC"
echo "============================================================"

# 防止重复写入
sed -i \
    "/^${TARGET_CONFIG}$/d" \
    .config

echo "${TARGET_CONFIG}" >> .config

echo "已写入:"
echo "${TARGET_CONFIG}"

# ============================================================
# 11.1 检查 defconfig 前设备数量
# ============================================================

echo
echo "defconfig 前设备检查:"

DEVICE_COUNT_BEFORE="$(
    grep -E \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
        .config \
        | wc -l
)"

echo "DEVICE_COUNT_BEFORE=${DEVICE_COUNT_BEFORE}"

if [ "${DEVICE_COUNT_BEFORE}" -ne 1 ]; then

    echo
    echo "❌ defconfig 前 Filogic Device 数量不是 1"

    grep -E \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
        .config \
        || true

    exit 1
fi

if ! grep -q "^${TARGET_CONFIG}$" .config; then

    echo
    echo "❌ defconfig 前 WH3000 Pro 目标不存在"

    exit 1
fi

echo "✅ defconfig 前 WH3000 Pro 是唯一 Filogic Device"

# ============================================================
# 11.2 显示 defconfig 前关键配置
# ============================================================

echo
echo "defconfig 前关键 Target 配置:"

grep -E \
    '^CONFIG_TARGET_(mediatek|DEVICE|BOARD|SUBTARGET|PROFILE)' \
    .config \
    || true

# ============================================================
# 12. 执行一次 make defconfig
# ============================================================

echo
echo "============================================================"
echo " 12. 执行唯一一次 make defconfig"
echo "============================================================"

echo
echo "★ 注意：WH3000 Pro 已经在 defconfig 之前锁定"
echo "★ defconfig 将负责同步 Kconfig"
echo "★ defconfig 之后不再手工修改设备配置"
echo

make defconfig

echo
echo "✅ make defconfig 完成"
# ============================================================
# 13. defconfig 后验证设备选择
# ============================================================

echo
echo "============================================================"
echo " 13. defconfig 后验证设备选择"
echo "============================================================"

echo
echo "defconfig 后 Filogic Device:"

grep -E \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
    .config \
    || true

DEVICE_COUNT_AFTER="$(
    grep -E \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
        .config \
        | wc -l
)"

echo
echo "DEVICE_COUNT_AFTER=${DEVICE_COUNT_AFTER}"

if [ "${DEVICE_COUNT_AFTER}" -ne 1 ]; then

    echo
    echo "❌ make defconfig 后 Filogic Device 数量不是 1"

    echo
    echo "实际设备:"
    grep -E \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
        .config \
        || true

    echo
    echo "❌ 这说明 Kconfig 没有正确锁定 WH3000 Pro"

    exit 1
fi

# ============================================================
# 14. defconfig 后必须仍然是 WH3000 Pro
# ============================================================

echo
echo "============================================================"
echo " 14. 验证 WH3000 Pro eMMC"
echo "============================================================"

if ! grep -q "^${TARGET_CONFIG}$" .config; then

    echo
    echo "❌ make defconfig 后 WH3000 Pro 目标消失"

    echo
    echo "当前 Filogic Device:"
    grep -E \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
        .config \
        || true

    exit 1
fi

echo "✅ make defconfig 后 WH3000 Pro eMMC 仍然存在"

# ============================================================
# 15. 确认基础 Target
# ============================================================

echo
echo "============================================================"
echo " 15. 验证 MediaTek / Filogic Target"
echo "============================================================"

if ! grep -q '^CONFIG_TARGET_mediatek=y$' .config; then

    echo "❌ CONFIG_TARGET_mediatek=y 不存在"

    exit 1
fi

if ! grep -q '^CONFIG_TARGET_mediatek_filogic=y$' .config; then

    echo "❌ CONFIG_TARGET_mediatek_filogic=y 不存在"

    exit 1
fi

echo "✅ CONFIG_TARGET_mediatek=y"
echo "✅ CONFIG_TARGET_mediatek_filogic=y"

# ============================================================
# 16. 禁止 OpenWrt One
# ============================================================

echo
echo "============================================================"
echo " 16. OpenWrt One 检查"
echo "============================================================"

if grep -q \
    '^CONFIG_TARGET_mediatek_filogic_DEVICE_openwrt_one=y$' \
    .config; then

    echo
    echo "❌ OpenWrt One 被重新选择"

    grep \
        '^CONFIG_TARGET_mediatek_filogic_DEVICE_openwrt_one=y$' \
        .config \
        || true

    exit 1
fi

echo "✅ OpenWrt One 不存在"

# ============================================================
# 17. TARGET_PROFILE 检查
# ============================================================

echo
echo "============================================================"
echo " 17. TARGET_PROFILE 检查"
echo "============================================================"

if grep -q '^CONFIG_TARGET_PROFILE=' .config; then

    echo
    echo "❌ CONFIG_TARGET_PROFILE 仍然存在"

    grep '^CONFIG_TARGET_PROFILE=' .config || true

    exit 1
fi

echo "✅ CONFIG_TARGET_PROFILE 不存在"

# ============================================================
# 18. 再次确认只有一个 Filogic Device
# ============================================================

echo
echo "============================================================"
echo " 18. Filogic Device 最终数量"
echo "============================================================"

DEVICE_COUNT_FINAL="$(
    grep -E \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
        .config \
        | wc -l
)"

echo "DEVICE_COUNT_FINAL=${DEVICE_COUNT_FINAL}"

if [ "${DEVICE_COUNT_FINAL}" -ne 1 ]; then

    echo
    echo "❌ 最终 Filogic Device 数量不是 1"

    grep -E \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
        .config \
        || true

    exit 1
fi

echo "✅ 最终 Filogic Device 数量 = 1"

# ============================================================
# 19. 最终设备必须精确匹配
# ============================================================

echo
echo "============================================================"
echo " 19. 最终设备精确匹配"
echo "============================================================"

FINAL_DEVICE_LINE="$(
    grep -E \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
        .config
)"

echo "FINAL_DEVICE_LINE:"
echo "${FINAL_DEVICE_LINE}"

if [ "${FINAL_DEVICE_LINE}" != "${TARGET_CONFIG}" ]; then

    echo
    echo "❌ 最终设备不是 WH3000 Pro eMMC"

    echo
    echo "期望:"
    echo "${TARGET_CONFIG}"

    echo
    echo "实际:"
    echo "${FINAL_DEVICE_LINE}"

    exit 1
fi

echo "✅ 最终设备 = WH3000 Pro eMMC"

# ============================================================
# 20. 检查目标设备 Makefile
# ============================================================

echo
echo "============================================================"
echo " 20. 最终检查 Device Makefile"
echo "============================================================"

echo
echo "WH3000 Pro Device 定义:"
echo

grep -n -A25 -B2 \
    "^define Device/${TARGET_DEVICE}$" \
    "${DEVICE_MK}"

echo
echo "TARGET_DEVICES:"
grep -n \
    "^TARGET_DEVICES += ${TARGET_DEVICE}$" \
    "${DEVICE_MK}"

echo
echo "✅ Device Makefile 最终检查通过"

# ============================================================
# 21. 检查 DTS
# ============================================================

echo
echo "============================================================"
echo " 21. 最终 DTS 检查"
echo "============================================================"

if [ ! -f "${DTS_EMMC}" ]; then

    echo "❌ WH3000 Pro eMMC DTS 消失"

    exit 1
fi

if [ ! -f "${DTS_COMMON}" ]; then

    echo "❌ WH3000 Pro common DTS 消失"

    exit 1
fi

echo "✅ WH3000 Pro eMMC DTS 存在"
echo "✅ WH3000 Pro common DTS 存在"

# ============================================================
# 22. 输出最终 Target 配置
# ============================================================

echo
echo "============================================================"
echo " 22. FINAL TARGET CONFIG"
echo "============================================================"

grep -E \
    '^CONFIG_TARGET_(mediatek|DEVICE|BOARD|SUBTARGET|PROFILE)' \
    .config \
    || true

echo
echo "============================================================"
echo " FINAL DEVICE"
echo "============================================================"

grep -E \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
    .config

# ============================================================
# 23. 生成配置摘要
# ============================================================

echo
echo "============================================================"
echo " 23. 配置摘要"
echo "============================================================"

echo
echo "TARGET_DEVICE:"
echo "${TARGET_DEVICE}"

echo
echo "TARGET_SYMBOL:"
echo "${TARGET_SYMBOL}"

echo
echo "TARGET_CONFIG:"
echo "${TARGET_CONFIG}"

echo
echo "DEVICE_MK:"
echo "${DEVICE_MK}"

echo
echo "DTS_EMMC:"
echo "${DTS_EMMC}"

echo
echo "DTS_COMMON:"
echo "${DTS_COMMON}"

echo
echo "CONFIG_TARGET_mediatek:"
grep '^CONFIG_TARGET_mediatek=y$' .config

echo
echo "CONFIG_TARGET_mediatek_filogic:"
grep '^CONFIG_TARGET_mediatek_filogic=y$' .config

echo
echo "WH3000 Pro Device:"
grep \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_huasifei_wh3000_pro_emmc=y$' \
    .config

# ============================================================
# 24. 最终状态
# ============================================================

echo
echo "============================================================"
echo " ✅ PREPARE 成功"
echo "============================================================"

echo
echo "最终设备:"
echo "${TARGET_DEVICE}"

echo
echo "最终 Kconfig:"
echo "${TARGET_CONFIG}"

echo
echo "最终状态:"
echo "  MediaTek       = OK"
echo "  Filogic        = OK"
echo "  WH3000 Pro     = OK"
echo "  Device Count   = 1"
echo "  OpenWrt One    = OFF"
echo "  TARGET_PROFILE = OFF"
echo

echo "============================================================"
echo " ★ 配置已经通过 Kconfig 正常同步"
echo " ★ 后续流程不要再修改 Target Device"
echo " ★ 后续流程不要再执行 make defconfig"
echo "============================================================"
