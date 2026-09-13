#!/bin/bash
set -euo pipefail

echo "============================================================"
echo "        FanchmWrt WH3000 Pro 配置准备脚本"
echo "============================================================"
echo

# ============================================================
# 基本参数
# ============================================================

TARGET_DEVICE="huasifei_wh3000-pro-emmc"

# !!! 非常重要 !!!
# FanchmWrt 的 Kconfig 实际使用的是带 '-' 的设备符号。
# 这里绝对不能写成：
# huasifei_wh3000_pro_emmc
#
# 正确：
# huasifei_wh3000-pro-emmc
#
TARGET_SYMBOL="huasifei_wh3000-pro-emmc"

TARGET_CONFIG="CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_${TARGET_SYMBOL}=y"

TARGET_PACKAGE_CONFIG="CONFIG_TARGET_DEVICE_PACKAGES_mediatek_filogic_DEVICE_${TARGET_SYMBOL}="

CONFIG_FILE="${GITHUB_WORKSPACE}/config/wh3000pro.config"

echo "目标设备      = ${TARGET_DEVICE}"
echo "Kconfig Symbol = ${TARGET_SYMBOL}"
echo "目标配置      = ${TARGET_CONFIG}"
echo "配置文件      = ${CONFIG_FILE}"
echo


# ============================================================
# 1. 检查当前源码目录
# ============================================================

echo "============================================================"
echo "1. 检查 FanchmWrt 源码"
echo "============================================================"

echo "当前工作目录："
pwd
echo

if [ ! -d "target/linux/mediatek" ]; then
    echo "❌ 错误：当前目录不是 OpenWrt/FanchmWrt 源码根目录。"
    echo
    echo "当前目录："
    pwd
    echo
    echo "没有找到："
    echo "target/linux/mediatek"
    echo
    exit 1
fi

echo "✅ target/linux/mediatek 存在"
echo


# ============================================================
# 2. 检查配置文件
# ============================================================

echo "============================================================"
echo "2. 检查 WH3000 Pro 配置文件"
echo "============================================================"

if [ ! -f "${CONFIG_FILE}" ]; then
    echo "❌ 错误：找不到配置文件："
    echo "${CONFIG_FILE}"
    echo
    exit 1
fi

echo "✅ 找到配置文件："
echo "${CONFIG_FILE}"
echo


# ============================================================
# 3. 显示原始配置
# ============================================================

echo "============================================================"
echo "3. 原始 wh3000pro.config"
echo "============================================================"

cat "${CONFIG_FILE}"

echo
echo "============================================================"
echo "原始配置结束"
echo "============================================================"
echo


# ============================================================
# 4. 复制基础配置到 OpenWrt .config
# ============================================================

echo "============================================================"
echo "4. 创建 OpenWrt .config"
echo "============================================================"

cp -f "${CONFIG_FILE}" .config

echo "✅ 已复制："
echo "${CONFIG_FILE}"
echo "→"
echo "$(pwd)/.config"
echo


# ============================================================
# 5. 清理旧的 / 错误 Target 配置
#
# 这里非常重要。
#
# 用户原来的配置中可能存在：
#
# CONFIG_TARGET_DEVICE_mediatek_filogic=y
#
# 或者错误的：
#
# CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_huasifei_wh3000_pro_emmc=y
#
# 或者旧设备：
#
# CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_xxx=y
#
# 全部清掉，然后由本脚本统一写入正确配置。
# ============================================================

echo "============================================================"
echo "5. 清理旧 Target / Device 配置"
echo "============================================================"

# ------------------------------------------------------------
# 清理所有 MediaTek Filogic 设备选择
# ------------------------------------------------------------

sed -i -E \
    '/^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=/d' \
    .config

# ------------------------------------------------------------
# 清理旧的 Target Device 总开关
# ------------------------------------------------------------

sed -i \
    '/^CONFIG_TARGET_DEVICE_mediatek_filogic=/d' \
    .config

# ------------------------------------------------------------
# 清理旧的 Target Profile
# 防止 DEFAULT_PROFILE / OpenWrt One 被显式写入
# ------------------------------------------------------------

sed -i \
    '/^CONFIG_TARGET_PROFILE=/d' \
    .config

# ------------------------------------------------------------
# 清理旧的 Multi Profile
# ------------------------------------------------------------

sed -i \
    '/^CONFIG_TARGET_MULTI_PROFILE=/d' \
    .config

# ------------------------------------------------------------
# 清理旧的 Per Device RootFS
# ------------------------------------------------------------

sed -i \
    '/^CONFIG_TARGET_PER_DEVICE_ROOTFS=/d' \
    .config

# ------------------------------------------------------------
# 清理旧的设备包配置
#
# 包括：
# CONFIG_TARGET_DEVICE_PACKAGES_mediatek_filogic=""
#
# 以及：
# CONFIG_TARGET_DEVICE_PACKAGES_mediatek_filogic_DEVICE_xxx=""
# ------------------------------------------------------------

sed -i -E \
    '/^CONFIG_TARGET_DEVICE_PACKAGES_mediatek_filogic(_DEVICE_.*)?=/d' \
    .config

# ------------------------------------------------------------
# 清理旧的 Target 平台配置
#
# 防止出现重复：
# CONFIG_TARGET_mediatek=y
# CONFIG_TARGET_mediatek_filogic=y
#
# 从而导致：
# override: TARGET_mediatek changes choice state
# ------------------------------------------------------------

sed -i \
    '/^CONFIG_TARGET_arm=/d' \
    .config

sed -i \
    '/^CONFIG_TARGET_BOARD=/d' \
    .config

sed -i \
    '/^CONFIG_TARGET_SUBTARGET=/d' \
    .config

sed -i \
    '/^CONFIG_TARGET_mediatek=/d' \
    .config

sed -i \
    '/^CONFIG_TARGET_mediatek_filogic=/d' \
    .config

echo "✅ 旧 Target / Device 配置已清理"
echo


# ============================================================
# 6. 写入唯一、正确的 Target 配置
# ============================================================

echo "============================================================"
echo "6. 写入 WH3000 Pro Target 配置"
echo "============================================================"

cat >> .config <<EOF

# ============================================================
# FanchmWrt WH3000 Pro
# Huasifei WH3000 Pro eMMC
# MediaTek Filogic / MT7981
# ============================================================

CONFIG_TARGET_arm=y
CONFIG_TARGET_BOARD="mediatek"
CONFIG_TARGET_SUBTARGET="filogic"

CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y

CONFIG_TARGET_MULTI_PROFILE=y
CONFIG_TARGET_PER_DEVICE_ROOTFS=y

${TARGET_CONFIG}

${TARGET_PACKAGE_CONFIG}""


# ============================================================
# 7. 统一设置 RootFS
# ============================================================

echo "============================================================"
echo "7. 设置 RootFS"
echo "============================================================"

# 删除旧 RootFS 配置，避免重复
sed -i \
    '/^CONFIG_TARGET_ROOTFS_SQUASHFS=/d' \
    .config

sed -i \
    '/^CONFIG_TARGET_ROOTFS_PARTSIZE=/d' \
    .config

cat >> .config <<EOF

# ============================================================
# RootFS
# ============================================================

CONFIG_TARGET_ROOTFS_SQUASHFS=y
CONFIG_TARGET_ROOTFS_PARTSIZE=448
EOF

echo "✅ RootFS = SquashFS"
echo "✅ RootFS PartSize = 448 MB"
echo


# ============================================================
# 8. 写入前检查
# ============================================================

echo "============================================================"
echo "8. make defconfig 前检查"
echo "============================================================"

echo
echo "当前 .config 中的 Target 配置："
echo "------------------------------------------------------------"

grep -E \
    '^(CONFIG_TARGET_arm|CONFIG_TARGET_BOARD|CONFIG_TARGET_SUBTARGET|CONFIG_TARGET_mediatek|CONFIG_TARGET_MULTI_PROFILE|CONFIG_TARGET_PER_DEVICE_ROOTFS)' \
    .config \
    || true

echo

echo "当前 .config 中的 Device 配置："
echo "------------------------------------------------------------"

grep -E \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_' \
    .config \
    || true

echo

echo "当前 .config 中的 Device Package 配置："
echo "------------------------------------------------------------"

grep -E \
    '^CONFIG_TARGET_DEVICE_PACKAGES_mediatek_filogic' \
    .config \
    || true

echo


# ============================================================
# 9. 强制检查是否只存在一个设备
# ============================================================

echo "============================================================"
echo "9. 检查 Device 数量"
echo "============================================================"

DEVICE_COUNT="$(
    grep -E \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
        .config \
        | wc -l
)"

echo "当前 Device 数量：${DEVICE_COUNT}"

if [ "${DEVICE_COUNT}" -ne 1 ]; then
    echo
    echo "❌ 错误：当前 .config 中不是恰好一个 Filogic Device。"
    echo
    echo "实际内容："
    grep -E \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
        .config \
        || true
    echo
    exit 1
fi

echo "✅ Device 数量正确：1"
echo


# ============================================================
# 10. 检查是否为正确设备
# ============================================================

echo "============================================================"
echo "10. 检查目标设备是否正确"
echo "============================================================"

if ! grep -Fxq "${TARGET_CONFIG}" .config; then
    echo
    echo "❌ 错误：目标设备配置没有正确写入 .config。"
    echo
    echo "应该存在："
    echo "${TARGET_CONFIG}"
    echo
    exit 1
fi

echo "✅ 找到正确的 WH3000 Pro Device："
echo "${TARGET_CONFIG}"
echo

# ============================================================
# 11. 明确检查 OpenWrt One
# ============================================================

echo "============================================================"
echo "11. 检查 OpenWrt One"
echo "============================================================"

if grep -Eq \
    '^CONFIG_TARGET_PROFILE=.*openwrt_one' \
    .config; then

    echo "❌ 错误：.config 中仍然存在 OpenWrt One Profile："
    grep -E \
        '^CONFIG_TARGET_PROFILE=' \
        .config \
        || true

    echo
    exit 1
fi

echo "✅ .config 没有显式选择 OpenWrt One"
echo


# ============================================================
# 12. 检查 FanchmWrt Device 定义
# ============================================================

echo "============================================================"
echo "12. 检查 WH3000 Pro Device 定义"
echo "============================================================"

DEVICE_MK="target/linux/mediatek/image/filogic.mk"

if [ ! -f "${DEVICE_MK}" ]; then
    echo "❌ 错误：找不到："
    echo "${DEVICE_MK}"
    echo
    exit 1
fi

echo "检查 Device/huasifei_wh3000-pro-emmc："

if grep -n \
    'define Device/huasifei_wh3000-pro-emmc' \
    "${DEVICE_MK}"; then

    echo
    echo "✅ 找到正确 Device 定义"
else
    echo
    echo "❌ 错误：没有找到 WH3000 Pro Device 定义"
    echo
    exit 1
fi

echo


# ============================================================
# 13. 检查 DTS 定义
# ============================================================

echo "============================================================"
echo "13. 检查 WH3000 Pro DTS"
echo "============================================================"

DTS_FILE="target/linux/mediatek/dts/mt7981b-huasifei-wh3000-pro-emmc.dts"

if [ ! -f "${DTS_FILE}" ]; then
    echo "❌ 错误：找不到 WH3000 Pro DTS："
    echo "${DTS_FILE}"
    echo
    exit 1
fi

echo "✅ 找到 DTS："
echo "${DTS_FILE}"
echo


# ============================================================
# 14. 执行 make defconfig
#
# 这是整个脚本最关键的一步。
#
# Kconfig 会根据源码重新整理 .config。
#
# 以前的问题就是：
#
# 写入：
# huasifei_wh3000_pro_emmc
#
# 但源码实际是：
# huasifei_wh3000-pro-emmc
#
# 所以 make defconfig 后错误符号直接被删除。
#
# 现在脚本使用正确的 '-'，因此应该保留下来。
# ============================================================

echo "============================================================"
echo "14. 执行 make defconfig"
echo "============================================================"

echo
echo "执行：make defconfig"
echo

make defconfig

echo
echo "✅ make defconfig 完成"
echo


# ============================================================
# 15. defconfig 后立即检查目标设备
# ============================================================

echo "============================================================"
echo "15. defconfig 后检查目标设备"
echo "============================================================"

echo
echo "defconfig 后 Device 配置："
echo "------------------------------------------------------------"

grep -E \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=' \
    .config \
    || true

echo

if ! grep -Fxq "${TARGET_CONFIG}" .config; then

    echo "============================================================"
    echo "❌❌❌ 致命错误：WH3000 Pro Device 被 Kconfig 删除！"
    echo "============================================================"
    echo
    echo "要求："
    echo "${TARGET_CONFIG}"
    echo
    echo "但是 make defconfig 后没有找到它。"
    echo
    echo "这意味着设备选择仍然存在配置问题。"
    echo "本脚本将停止，不进入漫长编译。"
    echo

    exit 1
fi

echo "✅ make defconfig 后 WH3000 Pro Device 仍然存在："
echo "${TARGET_CONFIG}"
echo


# ============================================================
# 16. 检查 tmp/.config-target.in
#
# 这里可以直接确认 FanchmWrt 的 Kconfig 到底注册了什么。
# ============================================================

echo "============================================================"
echo "16. 检查生成的 Kconfig"
echo "============================================================"

TARGET_IN="tmp/.config-target.in"

if [ -f "${TARGET_IN}" ]; then

    echo "搜索 WH3000 Pro："
    echo "------------------------------------------------------------"

    grep -n \
        'huasifei_wh3000' \
        "${TARGET_IN}" \
        | head -30 \
        || true

    echo

    if grep -q \
        'TARGET_mediatek_filogic_DEVICE_huasifei_wh3000-pro-emmc' \
        "${TARGET_IN}"; then

        echo "✅ Kconfig 已确认注册："
        echo "TARGET_mediatek_filogic_DEVICE_huasifei_wh3000-pro-emmc"

    else

        echo "❌ 警告：tmp/.config-target.in 中没有找到预期 Device。"
        echo
        echo "当前所有 huasifei_wh3000 相关内容："

        grep -n \
            'huasifei_wh3000' \
            "${TARGET_IN}" \
            || true

        echo
        exit 1
    fi

else

    echo "⚠️ tmp/.config-target.in 不存在。"
    echo "跳过该项检查。"

fi

echo


# ============================================================
# 17. 检查最终关键配置
# ============================================================

echo "============================================================"
echo "17. 最终关键配置"
echo "============================================================"

echo
echo "---------------- Target ----------------"

grep -E \
    '^(CONFIG_TARGET_arm|CONFIG_TARGET_BOARD|CONFIG_TARGET_SUBTARGET|CONFIG_TARGET_mediatek|CONFIG_TARGET_MULTI_PROFILE|CONFIG_TARGET_PER_DEVICE_ROOTFS)' \
    .config \
    || true

echo

echo "---------------- Device ----------------"

grep -E \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
    .config \
    || true

echo

echo "---------------- Device Packages ----------------"

grep -E \
    '^CONFIG_TARGET_DEVICE_PACKAGES_mediatek_filogic' \
    .config \
    || true

echo

echo "---------------- RootFS ----------------"

grep -E \
    '^CONFIG_TARGET_ROOTFS_(SQUASHFS|PARTSIZE)' \
    .config \
    || true

echo


# ============================================================
# 18. 最终 Device 数量检查
# ============================================================

echo "============================================================"
echo "18. 最终 Device 数量检查"
echo "============================================================"

FINAL_DEVICE_COUNT="$(
    grep -E \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
        .config \
        | wc -l
)"

echo "最终 Device 数量：${FINAL_DEVICE_COUNT}"

if [ "${FINAL_DEVICE_COUNT}" -ne 1 ]; then

    echo
    echo "❌ 错误：最终 Device 数量不是 1。"
    echo
    grep -E \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
        .config \
        || true

    echo
    exit 1
fi

echo "✅ 最终只有一个 Filogic Device"
echo


# ============================================================
# 19. 最终设备名称检查
# ============================================================

echo "============================================================"
echo "19. 最终设备名称检查"
echo "============================================================"

FINAL_DEVICE="$(
    grep -E \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
        .config
)"

echo "最终设备："
echo "${FINAL_DEVICE}"
echo

if [ "${FINAL_DEVICE}" != "${TARGET_CONFIG}" ]; then

    echo "❌ 错误：最终设备不是 WH3000 Pro。"
    echo
    echo "期望："
    echo "${TARGET_CONFIG}"
    echo
    echo "实际："
    echo "${FINAL_DEVICE}"
    echo

    exit 1
fi

echo "✅ 最终设备确认：WH3000 Pro"
echo


# ============================================================
# 20. 最终成功
# ============================================================

echo "============================================================"
echo "                 ✅ PREPARE 成功"
echo "============================================================"
echo
echo "设备：        ${TARGET_DEVICE}"
echo "平台：        mediatek / filogic"
echo "设备 Symbol： ${TARGET_SYMBOL}"
echo
echo "Kconfig："
echo "${TARGET_CONFIG}"
echo
echo "DTS："
echo "mt7981b-huasifei-wh3000-pro-emmc.dts"
echo
echo "RootFS："
echo "SquashFS / 448 MB"
echo
echo "Multi Profile："
echo "启用"
echo
echo "Per Device RootFS："
echo "启用"
echo
echo "OpenWrt One："
echo "未选择"
echo
echo "============================================================"
echo "       可以进入后续 make 编译阶段"
echo "============================================================"
echo

exit 0
