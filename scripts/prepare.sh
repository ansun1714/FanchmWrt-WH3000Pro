#!/bin/bash

set -euo pipefail

# ============================================================
# FanchmWrt WH3000 Pro 固件编译准备脚本
#
# 源码：
#   fanchmwrt-25.12.4
#
# 目标：
#   Huasifei WH3000 Pro eMMC
#
# Device ID：
#   huasifei_wh3000-pro-emmc
#
# Kconfig：
#   CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_huasifei_wh3000_pro_emmc=y
#
# DTS：
#   mt7981b-huasifei-wh3000-pro-emmc.dts
# ============================================================


# ============================================================
# 1. 基础变量
# ============================================================

ROOT_DIR="${GITHUB_WORKSPACE:-$(pwd)}"
BUILD_DIR="${ROOT_DIR}/openwrt"

cd "${BUILD_DIR}"

TARGET_DEVICE="${DEVICE:-huasifei_wh3000-pro-emmc}"

TARGET_SYMBOL="${TARGET_DEVICE//-/_}"

TARGET_CONFIG="CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_${TARGET_SYMBOL}=y"

DEVICE_MK="target/linux/mediatek/image/filogic.mk"

DTS_EMMC="target/linux/mediatek/dts/mt7981b-huasifei-wh3000-pro-emmc.dts"

DTS_COMMON="target/linux/mediatek/dts/mt7981b-huasifei-wh3000-pro.dtsi"

CONFIG_FILE="${ROOT_DIR}/config/wh3000pro.config"


echo
echo "============================================================"
echo " FanchmWrt WH3000 Pro 编译准备"
echo "============================================================"
echo
echo "ROOT_DIR      = ${ROOT_DIR}"
echo "BUILD_DIR     = ${BUILD_DIR}"
echo "TARGET_DEVICE = ${TARGET_DEVICE}"
echo "TARGET_SYMBOL = ${TARGET_SYMBOL}"
echo "TARGET_CONFIG = ${TARGET_CONFIG}"
echo


# ============================================================
# 2. 检查 OpenWrt 源码目录
# ============================================================

echo "============================================================"
echo " 2. 检查 OpenWrt 源码"
echo "============================================================"

if [ ! -d "${BUILD_DIR}" ]; then
    echo "❌ 找不到 OpenWrt 源码目录："
    echo "${BUILD_DIR}"
    exit 1
fi

if [ ! -f "${BUILD_DIR}/Makefile" ]; then
    echo "❌ ${BUILD_DIR} 不是有效的 OpenWrt/FanchmWrt 源码目录"
    exit 1
fi

echo "✅ OpenWrt 源码目录正常"


# ============================================================
# 3. 检查 WH3000 Pro Device 定义
# ============================================================

echo
echo "============================================================"
echo " 3. 检查 WH3000 Pro Device 定义"
echo "============================================================"

if [ ! -f "${DEVICE_MK}" ]; then
    echo "❌ 找不到：${DEVICE_MK}"
    exit 1
fi

if ! grep -q '^define Device/huasifei_wh3000-pro-emmc$' "${DEVICE_MK}"; then
    echo "❌ filogic.mk 中没有找到："
    echo "define Device/huasifei_wh3000-pro-emmc"
    exit 1
fi

if ! grep -q 'TARGET_DEVICES.*huasifei_wh3000-pro-emmc' "${DEVICE_MK}"; then
    echo "❌ filogic.mk 没有注册 WH3000 Pro Device"
    exit 1
fi

echo "✅ WH3000 Pro Device 定义存在"


# ============================================================
# 4. 检查 WH3000 Pro DTS
# ============================================================

echo
echo "============================================================"
echo " 4. 检查 WH3000 Pro DTS"
echo "============================================================"

if [ ! -f "${DTS_EMMC}" ]; then
    echo "❌ 找不到 WH3000 Pro DTS："
    echo "${DTS_EMMC}"
    exit 1
fi

echo "✅ DTS 文件存在："
echo "   ${DTS_EMMC}"


# ============================================================
# 5. 检查 Device DTS 引用
# ============================================================

echo
echo "============================================================"
echo " 5. 检查 Device DTS 引用"
echo "============================================================"

if ! grep -A30 '^define Device/huasifei_wh3000-pro-emmc$' \
    "${DEVICE_MK}" | grep -q 'DEVICE_DTS.*mt7981b-huasifei-wh3000-pro-emmc'; then

    echo "❌ Device 定义没有正确引用："
    echo "   mt7981b-huasifei-wh3000-pro-emmc"
    exit 1
fi

echo "✅ Device DTS 引用正确"


# ============================================================
# 6. 导入 WH3000 Pro 用户配置
# ============================================================

echo
echo "============================================================"
echo " 6. 导入 WH3000 Pro 用户配置"
echo "============================================================"

if [ ! -f "${CONFIG_FILE}" ]; then
    echo "❌ 找不到配置文件："
    echo "${CONFIG_FILE}"
    exit 1
fi

cp "${CONFIG_FILE}" .config

echo "✅ wh3000pro.config 已复制到 .config"


# ============================================================
# 7. 清理旧 Filogic Device
#
# 注意：
# 正确前缀必须是：
#
# CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_
#
# 不能写成：
#
# CONFIG_TARGET_mediatek_filogic_DEVICE_
# ============================================================

echo
echo "============================================================"
echo " 7. 清理旧 Filogic Device"
echo "============================================================"

# 清除所有 Filogic Device 选择
sed -i \
    '/^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$/d' \
    .config

# 清除错误/多余的 Filogic DEVICE 基类
sed -i \
    '/^CONFIG_TARGET_DEVICE_mediatek_filogic=y$/d' \
    .config

echo "✅ 已清除所有旧 Filogic Device"

echo
echo "清理后检查："

grep -E \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic' \
    .config \
    || echo "（当前没有旧 Filogic Device）"


# ============================================================
# 8. 清理 OpenWrt One
# ============================================================

echo
echo "============================================================"
echo " 8. 清理 OpenWrt One"
echo "============================================================"

# 删除可能残留的默认 Profile
sed -i \
    '/^CONFIG_TARGET_PROFILE=/d' \
    .config

# 删除 OpenWrt One Device
sed -i \
    '/^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_openwrt_one=y$/d' \
    .config

echo "✅ OpenWrt One 已清理"


# ============================================================
# 9. 强制设置基础 Target
# ============================================================

echo
echo "============================================================"
echo " 9. 设置 MediaTek / Filogic Target"
echo "============================================================"

# 删除可能存在的旧值
sed -i '/^CONFIG_TARGET_arm=/d' .config
sed -i '/^CONFIG_TARGET_BOARD=/d' .config
sed -i '/^CONFIG_TARGET_SUBTARGET=/d' .config
sed -i '/^CONFIG_TARGET_mediatek=/d' .config
sed -i '/^CONFIG_TARGET_mediatek_filogic=/d' .config

cat >> .config <<'EOF'

CONFIG_TARGET_arm=y
CONFIG_TARGET_BOARD="mediatek"
CONFIG_TARGET_SUBTARGET="filogic"
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y

EOF

echo "✅ MediaTek / Filogic 基础 Target 已设置"


# ============================================================
# 10. 设置 WH3000 Pro Device
# ============================================================

echo
echo "============================================================"
echo " 10. 设置 WH3000 Pro Device"
echo "============================================================"

# 再次确保没有任何 Filogic Device 残留
sed -i \
    '/^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$/d' \
    .config

# 清除错误的 DEVICE 基类
sed -i \
    '/^CONFIG_TARGET_DEVICE_mediatek_filogic=y$/d' \
    .config

# 写入唯一正确的 WH3000 Pro Device
echo "${TARGET_CONFIG}" >> .config

echo
echo "当前 Device："

grep -E \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
    .config \
    || true


# ============================================================
# 11. Device 数量检查
# ============================================================

echo
echo "============================================================"
echo " 11. 检查 Device 数量"
echo "============================================================"

DEVICE_COUNT_BEFORE="$(
    grep -E \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
        .config |
    wc -l |
    tr -d ' '
)"

echo
echo "DEVICE_COUNT_BEFORE=${DEVICE_COUNT_BEFORE}"
echo

grep -E \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
    .config \
    || true

if [ "${DEVICE_COUNT_BEFORE}" != "1" ]; then
    echo
    echo "❌ WH3000 Pro Device 数量不是 1"
    echo "❌ 当前数量：${DEVICE_COUNT_BEFORE}"
    echo
    echo "当前所有 Filogic Device："
    grep -E \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_' \
        .config \
        || true
    exit 1
fi

if ! grep -qxF "${TARGET_CONFIG}" .config; then
    echo
    echo "❌ WH3000 Pro Device 配置不正确"
    echo "❌ 期望：${TARGET_CONFIG}"
    exit 1
fi

echo
echo "✅ WH3000 Pro Device 配置唯一且正确"
# ============================================================
# 12. 运行 make defconfig
#
# 重要：
# Device 必须在 defconfig 之前确定。
# defconfig 后不再手动修改 Device。
# ============================================================

echo
echo "============================================================"
echo " 12. 运行 make defconfig"
echo "============================================================"

echo
echo "执行：make defconfig"
echo

make defconfig

echo
echo "✅ make defconfig 完成"


# ============================================================
# 13. defconfig 后检查基础 Target
# ============================================================

echo
echo "============================================================"
echo " 13. 检查 defconfig 后 Target"
echo "============================================================"

echo
echo "Target 配置："

grep -E \
    '^(CONFIG_TARGET_arm=|CONFIG_TARGET_BOARD=|CONFIG_TARGET_SUBTARGET=|CONFIG_TARGET_mediatek=|CONFIG_TARGET_mediatek_filogic=)' \
    .config \
    || true

if ! grep -qx 'CONFIG_TARGET_mediatek=y' .config; then
    echo "❌ CONFIG_TARGET_mediatek=y 不存在"
    exit 1
fi

if ! grep -qx 'CONFIG_TARGET_mediatek_filogic=y' .config; then
    echo "❌ CONFIG_TARGET_mediatek_filogic=y 不存在"
    exit 1
fi

echo
echo "✅ MediaTek / Filogic Target 正确"


# ============================================================
# 14. defconfig 后检查 Device
#
# 这里非常重要：
# 不再修改 .config。
# 只检查 make defconfig 最终留下了什么。
# ============================================================

echo
echo "============================================================"
echo " 14. 检查 defconfig 后 Device"
echo "============================================================"

echo
echo "defconfig 后的 Filogic Device："

grep -E \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
    .config \
    || true


DEVICE_COUNT_AFTER="$(
    grep -E \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
        .config |
    wc -l |
    tr -d ' '
)"

echo
echo "DEVICE_COUNT_AFTER=${DEVICE_COUNT_AFTER}"
echo

if [ "${DEVICE_COUNT_AFTER}" != "1" ]; then
    echo "❌ defconfig 后 Filogic Device 数量不是 1"
    echo "❌ 当前数量：${DEVICE_COUNT_AFTER}"
    echo
    echo "完整 Device 配置："
    grep -E \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_' \
        .config \
        || true
    exit 1
fi


if ! grep -qxF "${TARGET_CONFIG}" .config; then
    echo "❌ defconfig 后 WH3000 Pro Device 不正确"
    echo
    echo "期望："
    echo "${TARGET_CONFIG}"
    echo
    echo "实际："
    grep -E \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
        .config \
        || true
    exit 1
fi

echo "✅ defconfig 后 WH3000 Pro Device 正确"


# ============================================================
# 15. 检查 OpenWrt One
# ============================================================

echo
echo "============================================================"
echo " 15. 检查 OpenWrt One"
echo "============================================================"

if grep -q \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_openwrt_one=y$' \
    .config; then

    echo "❌ 检测到 OpenWrt One Device"
    echo
    grep \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_openwrt_one=y$' \
        .config
    exit 1
fi

if grep -q '^CONFIG_TARGET_PROFILE=' .config; then
    echo "⚠️ 检测到 CONFIG_TARGET_PROFILE："
    grep '^CONFIG_TARGET_PROFILE=' .config
else
    echo "✅ 没有残留 CONFIG_TARGET_PROFILE"
fi


# ============================================================
# 16. 检查最终 .config 中是否出现错误的 Device 写法
# ============================================================

echo
echo "============================================================"
echo " 16. 检查错误 Device 配置"
echo "============================================================"

# 错误的旧写法：
# CONFIG_TARGET_DEVICE_mediatek_filogic=y
#
# 这个不是具体 Device 选择，不应该存在。

if grep -qx \
    'CONFIG_TARGET_DEVICE_mediatek_filogic=y' \
    .config; then

    echo "❌ 发现错误配置："
    echo "CONFIG_TARGET_DEVICE_mediatek_filogic=y"
    exit 1
fi

# 错误的 WH3000 Pro 连字符写法
if grep -qx \
    'CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_huasifei_wh3000-pro-emmc=y' \
    .config; then

    echo "❌ 发现错误的 WH3000 Pro Device 写法："
    echo "CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_huasifei_wh3000-pro-emmc=y"
    echo
    echo "正确写法应该是："
    echo "CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_huasifei_wh3000_pro_emmc=y"
    exit 1
fi

echo "✅ 未发现错误 Device 配置"


# ============================================================
# 17. 检查 WH3000 Pro DTS
# ============================================================

echo
echo "============================================================"
echo " 17. 最终检查 WH3000 Pro DTS"
echo "============================================================"

if [ ! -f "${DTS_EMMC}" ]; then
    echo "❌ WH3000 Pro DTS 不存在："
    echo "${DTS_EMMC}"
    exit 1
fi

echo "✅ WH3000 Pro DTS 存在"


# ============================================================
# 18. 检查 DTS 是否被 Device 定义引用
# ============================================================

echo
echo "============================================================"
echo " 18. 最终检查 Device → DTS"
echo "============================================================"

DEVICE_BLOCK="$(
    sed -n \
        '/^define Device\/huasifei_wh3000-pro-emmc$/,/^endef$/p' \
        "${DEVICE_MK}"
)"

echo
echo "${DEVICE_BLOCK}"
echo

if ! printf '%s\n' "${DEVICE_BLOCK}" |
    grep -q \
    'DEVICE_DTS.*mt7981b-huasifei-wh3000-pro-emmc'; then

    echo "❌ WH3000 Pro Device 没有引用正确 DTS"
    exit 1
fi

echo "✅ Device → DTS 引用正确"


# ============================================================
# 19. 检查 TARGET_DEVICES 注册
# ============================================================

echo
echo "============================================================"
echo " 19. 检查 TARGET_DEVICES"
echo "============================================================"

if ! grep -q \
    '^TARGET_DEVICES.*huasifei_wh3000-pro-emmc' \
    "${DEVICE_MK}"; then

    echo "❌ WH3000 Pro 没有加入 TARGET_DEVICES"
    exit 1
fi

echo "✅ WH3000 Pro 已注册到 TARGET_DEVICES"


# ============================================================
# 20. 检查 sysupgrade 定义
# ============================================================

echo
echo "============================================================"
echo " 20. 检查 sysupgrade 定义"
echo "============================================================"

if ! printf '%s\n' "${DEVICE_BLOCK}" |
    grep -q \
    'IMAGE/sysupgrade\.bin'; then

    echo "⚠️ 当前 Device 定义没有发现 IMAGE/sysupgrade.bin"
    echo
    echo "当前 Device 定义如下："
    echo "${DEVICE_BLOCK}"
    echo
    echo "⚠️ 暂不修改 filogic.mk"
    echo "⚠️ 先让后面的编译诊断实际结果决定是否需要处理"
else
    echo "✅ Device 定义包含 sysupgrade.bin"
fi


# ============================================================
# 21. 显示最终 Device 信息
# ============================================================

echo
echo "============================================================"
echo " 21. WH3000 Pro 最终 Device 信息"
echo "============================================================"

echo
echo "Device ID："
echo "  ${TARGET_DEVICE}"

echo
echo "Kconfig："
echo "  ${TARGET_CONFIG}"

echo
echo "DTS："
echo "  ${DTS_EMMC}"

echo
echo "Device Makefile："
echo "  ${DEVICE_MK}"

echo


# ============================================================
# 22. 最终配置摘要
# ============================================================

echo "============================================================"
echo " 22. 最终配置摘要"
echo "============================================================"

echo

grep -E \
    '^(CONFIG_TARGET_arm=|CONFIG_TARGET_BOARD=|CONFIG_TARGET_SUBTARGET=|CONFIG_TARGET_mediatek=|CONFIG_TARGET_mediatek_filogic=|CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$|CONFIG_TARGET_ROOTFS_SQUASHFS=|CONFIG_TARGET_ROOTFS_PARTSIZE=)' \
    .config \
    || true

echo


# ============================================================
# 23. 最终 Device 唯一性确认
# ============================================================

echo "============================================================"
echo " 23. 最终 Device 唯一性确认"
echo "============================================================"

FINAL_DEVICE_COUNT="$(
    grep -E \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
        .config |
    wc -l |
    tr -d ' '
)"

echo
echo "FINAL_DEVICE_COUNT=${FINAL_DEVICE_COUNT}"
echo

if [ "${FINAL_DEVICE_COUNT}" != "1" ]; then
    echo "❌ 最终 Device 数量错误"
    exit 1
fi

FINAL_DEVICE="$(
    grep -E \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
        .config
)"

echo "最终 Device："
echo "${FINAL_DEVICE}"
echo

if [ "${FINAL_DEVICE}" != "${TARGET_CONFIG}" ]; then
    echo "❌ 最终 Device 与 WH3000 Pro 不匹配"
    echo
    echo "期望："
    echo "${TARGET_CONFIG}"
    echo
    echo "实际："
    echo "${FINAL_DEVICE}"
    exit 1
fi

echo "✅ 最终 Device 确认：WH3000 Pro"


# ============================================================
# 24. 保存最终配置
# ============================================================

echo
echo "============================================================"
echo " 24. 保存最终配置"
echo "============================================================"

cp .config .config.wh3000pro.final

echo "✅ 最终配置已保存："
echo "   ${BUILD_DIR}/.config.wh3000pro.final"


# ============================================================
# 25. 输出编译前诊断信息
# ============================================================

echo
echo "============================================================"
echo " 25. 编译前诊断信息"
echo "============================================================"

echo
echo "OpenWrt 版本："

if [ -f version ]; then
    cat version
else
    echo "（没有 version 文件）"
fi

echo
echo "Git HEAD："
git rev-parse --short HEAD 2>/dev/null || true

echo
echo "Git 分支/标签："
git describe --always --tags --dirty 2>/dev/null || true

echo
echo "目标平台："
echo "  mediatek / filogic"

echo
echo "目标设备："
echo "  huasifei_wh300-pro-emmc"

echo
echo "DTS："
echo "  mt7981b-huasifei-wh300-pro-emmc"

echo


# ============================================================
# 26. 最终成功
# ============================================================

echo "============================================================"
echo "              PREPARE SUCCESS"
echo "============================================================"

echo
echo "✅ FanchmWrt WH3000 Pro 编译配置准备完成"
echo
echo "✅ Target：mediatek/filogic"
echo "✅ Device：huasifei_wh300-pro-emmc"
echo "✅ DTS：mt7981b-huasifei-wh300-pro-emmc"
echo "✅ Device 数量：1"
echo "✅ OpenWrt One：未选择"
echo "✅ .config：已通过最终检查"
echo
echo "============================================================"
echo "        可以进入正式固件编译阶段"
echo "============================================================"
echo
