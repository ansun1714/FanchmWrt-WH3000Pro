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

# FanchmWrt 实际注册的 Kconfig Device Symbol
#
# 注意：
# 必须使用 '-'：
#
# huasifei_wh3000-pro-emmc
#
# 不能写成：
#
# huasifei_wh3000_pro_emmc
#
TARGET_SYMBOL="huasifei_wh3000-pro-emmc"

TARGET_CONFIG="CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_huasifei_wh3000-pro-emmc=y"

CONFIG_FILE="${GITHUB_WORKSPACE}/config/wh3000pro.config"

echo "目标设备      = ${TARGET_DEVICE}"
echo "Kconfig Symbol = ${TARGET_SYMBOL}"
echo "目标配置      = ${TARGET_CONFIG}"
echo "配置文件      = ${CONFIG_FILE}"
echo


# ============================================================
# 1. 检查当前工作目录
# ============================================================

echo "============================================================"
echo "1. 检查 FanchmWrt 源码"
echo "============================================================"

echo "当前工作目录："
pwd
echo

if [ ! -d "target/linux/mediatek" ]; then
    echo "❌ 错误：当前目录不是 FanchmWrt/OpenWrt 源码根目录。"
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
# 4. 创建 OpenWrt .config
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
# 5. 清理旧 Target / Device 配置
#
# 统一由本脚本重新生成，避免：
#
# 1. 旧设备残留
# 2. 错误的下划线 Device Symbol
# 3. 重复 Target 配置
# 4. OpenWrt One Profile 残留
# 5. 错误的 Device Packages 配置
# ============================================================

echo "============================================================"
echo "5. 清理旧 Target / Device 配置"
echo "============================================================"

# ------------------------------------------------------------
# 清理所有 Filogic Device 选择
# ------------------------------------------------------------

sed -i -E \
    '/^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=/d' \
    .config

# ------------------------------------------------------------
# 清理旧 Target Device 总开关
# ------------------------------------------------------------

sed -i \
    '/^CONFIG_TARGET_DEVICE_mediatek_filogic=/d' \
    .config

# ------------------------------------------------------------
# 清理 Profile
# ------------------------------------------------------------

sed -i \
    '/^CONFIG_TARGET_PROFILE=/d' \
    .config

# ------------------------------------------------------------
# 清理 Multi Profile
# ------------------------------------------------------------

sed -i \
    '/^CONFIG_TARGET_MULTI_PROFILE=/d' \
    .config

# ------------------------------------------------------------
# 清理 Per Device RootFS
# ------------------------------------------------------------

sed -i \
    '/^CONFIG_TARGET_PER_DEVICE_ROOTFS=/d' \
    .config

# ------------------------------------------------------------
# 清理所有 Filogic Device Packages
# ------------------------------------------------------------

sed -i -E \
    '/^CONFIG_TARGET_DEVICE_PACKAGES_mediatek_filogic(_DEVICE_.*)?=/d' \
    .config

# ------------------------------------------------------------
# 清理 Target 平台配置
# 防止重复配置导致：
#
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
# 6. 写入唯一正确的 Target 配置
# ============================================================

echo "============================================================"
echo "6. 写入 WH3000 Pro Target 配置"
echo "============================================================"

cat >> .config <<'EOF'

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

CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_huasifei_wh3000-pro-emmc=y

CONFIG_TARGET_DEVICE_PACKAGES_mediatek_filogic_DEVICE_huasifei_wh3000-pro-emmc=""
EOF

echo "✅ Target 配置写入完成"
echo


# ============================================================
# 7. 设置 RootFS
# ============================================================

echo "============================================================"
echo "7. 设置 RootFS"
echo "============================================================"

# 清理旧值
sed -i \
    '/^CONFIG_TARGET_ROOTFS_SQUASHFS=/d' \
    .config

sed -i \
    '/^CONFIG_TARGET_ROOTFS_PARTSIZE=/d' \
    .config

# 写入正确值
cat >> .config <<'EOF'

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
# 8. 检查 .config 是否存在非法格式
#
# 这里提前检查，避免直到 make defconfig 才发现：
#
# .config:xxx: *** missing separator
# ============================================================

echo "============================================================"
echo "8. 检查 .config 基本格式"
echo "============================================================"

if grep -nE \
    '^[^#[:space:]][^=]*[^=[:space:]]$' \
    .config \
    | head -20; then

    echo
    echo "⚠️ 发现可能存在异常配置行。"
    echo "上面仅用于诊断，继续执行。"
else
    echo "✅ 没有发现明显的异常配置行"
fi

echo


# ============================================================
# 9. 检查关键 Target 配置
# ============================================================

echo "============================================================"
echo "9. make defconfig 前检查"
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
# 10. Device 数量检查
# ============================================================

echo "============================================================"
echo "10. 检查 Device 数量"
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
# 11. 检查目标设备
# ============================================================

echo "============================================================"
echo "11. 检查目标设备是否正确"
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
# 12. 检查 OpenWrt One
# ============================================================

echo "============================================================"
echo "12. 检查 OpenWrt One"
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
# 13. 检查 WH3000 Pro Device 定义
# ============================================================

echo "============================================================"
echo "13. 检查 WH3000 Pro Device 定义"
echo "============================================================"

DEVICE_MK="target/linux/mediatek/image/filogic.mk"

if [ ! -f "${DEVICE_MK}" ]; then

    echo "❌ 错误：找不到："
    echo "${DEVICE_MK}"
    echo

    exit 1
fi

echo "检查：Device/huasifei_wh3000-pro-emmc"
echo

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
# 14. 检查 DTS
# ============================================================

echo "============================================================"
echo "14. 检查 WH3000 Pro DTS"
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
# 15. 执行 make defconfig
# ============================================================

echo "============================================================"
echo "15. 执行 make defconfig"
echo "============================================================"

echo
echo "执行：make defconfig"
echo

make defconfig

echo
echo "✅ make defconfig 完成"
echo


# ============================================================
# 16. defconfig 后检查 Device
# ============================================================

echo "============================================================"
echo "16. defconfig 后检查目标设备"
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
    echo "脚本停止，不进入漫长编译。"
    echo

    exit 1
fi

echo "✅ make defconfig 后 WH3000 Pro Device 仍然存在："
echo "${TARGET_CONFIG}"
echo


# ============================================================
# 17. 检查生成的 Kconfig
# ============================================================

echo "============================================================"
echo "17. 检查生成的 Kconfig"
echo "============================================================"

TARGET_IN="tmp/.config-target.in"

if [ -f "${TARGET_IN}" ]; then

    echo "搜索 huasifei_wh3000："
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

        echo "❌ 错误：tmp/.config-target.in 中没有找到预期 Device。"
        echo

        echo "当前 huasifei_wh3000 相关内容："

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
# 18. 最终关键配置
# ============================================================

echo "============================================================"
echo "18. 最终关键配置"
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
# 19. 最终 Device 数量检查
# ============================================================

echo "============================================================"
echo "19. 最终 Device 数量检查"
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
# 20. 最终设备名称检查
# ============================================================

echo "============================================================"
echo "20. 最终设备名称检查"
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
# 21. 最终检查 .config 是否存在明显非法行
# ============================================================

echo "============================================================"
echo "21. 最终 .config 格式检查"
echo "============================================================"

BAD_LINES="$(
    grep -nE \
        '^[^#[:space:]][^=]*[^=[:space:]]$' \
        .config \
        || true
)"

if [ -n "${BAD_LINES}" ]; then

    echo "⚠️ 检测到可能异常的配置行："
    echo "${BAD_LINES}"
    echo
    echo "请检查上面的内容。"
    echo

else

    echo "✅ .config 格式检查通过"

fi

echo


# ============================================================
# 22. 最终成功
# ============================================================

echo "============================================================"
echo "              ✅ PREPARE 成功"
echo "============================================================"
echo
echo "设备："
echo "  ${TARGET_DEVICE}"
echo
echo "平台："
echo "  mediatek / filogic"
echo
echo "Kconfig Device Symbol："
echo "  ${TARGET_SYMBOL}"
echo
echo "最终 Device 配置："
echo "  ${TARGET_CONFIG}"
echo
echo "DTS："
echo "  mt7981b-huasifei-wh3000-pro-emmc.dts"
echo
echo "RootFS："
echo "  SquashFS"
echo
echo "RootFS PartSize："
echo "  448 MB"
echo
echo "Multi Profile："
echo "  enabled"
echo
echo "Per Device RootFS："
echo "  enabled"
echo
echo "OpenWrt One："
echo "  未选择"
echo
echo "============================================================"
echo "       WH3000 Pro 配置准备完成"
echo "       可以进入后续 make 编译阶段"
echo "============================================================"
echo

exit 0
