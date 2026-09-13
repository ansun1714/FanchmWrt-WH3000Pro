#!/bin/bash

set -euo pipefail

# ============================================================
# FanchmWrt WH3000 Pro - prepare.sh
# 诊断版
#
# 目标：
#   huasifei_wh3000-pro-emmc
#
# Kconfig：
#   CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_huasifei_wh3000_pro_emmc=y
# ============================================================

ROOT_DIR="${GITHUB_WORKSPACE:-$(pwd)}"
BUILD_DIR="${ROOT_DIR}/openwrt"

cd "${BUILD_DIR}"

TARGET_DEVICE="${DEVICE:-huasifei_wh3000-pro-emmc}"
TARGET_SYMBOL="${TARGET_DEVICE//-/_}"

TARGET_CONFIG="CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_${TARGET_SYMBOL}=y"

DEVICE_MK="target/linux/mediatek/image/filogic.mk"
DTS_EMMC="target/linux/mediatek/dts/mt7981b-huasifei-wh3000-pro-emmc.dts"
CONFIG_FILE="${ROOT_DIR}/config/wh3000pro.config"


echo
echo "============================================================"
echo " FanchmWrt WH3000 Pro PREPARE"
echo "============================================================"

echo "ROOT_DIR      = ${ROOT_DIR}"
echo "BUILD_DIR     = ${BUILD_DIR}"
echo "TARGET_DEVICE = ${TARGET_DEVICE}"
echo "TARGET_SYMBOL = ${TARGET_SYMBOL}"
echo "TARGET_CONFIG = ${TARGET_CONFIG}"
echo


# ============================================================
# 1. 检查源码
# ============================================================

echo "============================================================"
echo " 1. 检查源码"
echo "============================================================"

if [ ! -f Makefile ]; then
    echo "❌ 找不到 OpenWrt Makefile"
    exit 1
fi

echo "✅ OpenWrt 源码正常"


# ============================================================
# 2. 检查 Device 定义
# ============================================================

echo
echo "============================================================"
echo " 2. 检查 WH3000 Pro Device"
echo "============================================================"

if ! grep -q \
    '^define Device/huasifei_wh3000-pro-emmc$' \
    "${DEVICE_MK}"; then

    echo "❌ 找不到 WH3000 Pro Device 定义"
    exit 1
fi

echo "✅ Device 定义存在"


# ============================================================
# 3. 检查 DTS
# ============================================================

echo
echo "============================================================"
echo " 3. 检查 DTS"
echo "============================================================"

if [ ! -f "${DTS_EMMC}" ]; then
    echo "❌ DTS 不存在："
    echo "${DTS_EMMC}"
    exit 1
fi

echo "✅ DTS 存在"


# ============================================================
# 4. 导入用户配置
# ============================================================

echo
echo "============================================================"
echo " 4. 导入 wh3000pro.config"
echo "============================================================"

if [ ! -f "${CONFIG_FILE}" ]; then
    echo "❌ 配置文件不存在："
    echo "${CONFIG_FILE}"
    exit 1
fi

cp "${CONFIG_FILE}" .config

echo "✅ 配置文件已复制"


# ============================================================
# 5. 清理所有 Filogic Device
# ============================================================

echo
echo "============================================================"
echo " 5. 清理旧 Filogic Device"
echo "============================================================"

sed -i \
    '/^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$/d' \
    .config

sed -i \
    '/^CONFIG_TARGET_DEVICE_mediatek_filogic=y$/d' \
    .config

sed -i \
    '/^CONFIG_TARGET_PROFILE=/d' \
    .config

echo "✅ 旧 Device / Profile 已清理"


# ============================================================
# 6. 设置基础 Target
# ============================================================

echo
echo "============================================================"
echo " 6. 设置 MediaTek / Filogic"
echo "============================================================"

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

echo "✅ MediaTek / Filogic 已设置"


# ============================================================
# 7. 启用多设备 Target 机制
#
# 这是这次诊断的关键。
# OpenWrt 25.12 的实际 diffconfig 使用：
#
# CONFIG_TARGET_MULTI_PROFILE=y
# CONFIG_TARGET_DEVICE_...=y
# CONFIG_TARGET_PER_DEVICE_ROOTFS=y
# ============================================================

echo
echo "============================================================"
echo " 7. 设置 Target Profile 机制"
echo "============================================================"

sed -i '/^CONFIG_TARGET_MULTI_PROFILE=/d' .config
sed -i '/^CONFIG_TARGET_PER_DEVICE_ROOTFS=/d' .config

cat >> .config <<'EOF'

CONFIG_TARGET_MULTI_PROFILE=y
CONFIG_TARGET_PER_DEVICE_ROOTFS=y

EOF

echo "CONFIG_TARGET_MULTI_PROFILE=y"
echo "CONFIG_TARGET_PER_DEVICE_ROOTFS=y"

echo
echo "✅ Target Profile 机制已设置"


# ============================================================
# 8. 写入 WH3000 Pro Device
# ============================================================

echo
echo "============================================================"
echo " 8. 设置 WH3000 Pro Device"
echo "============================================================"

sed -i \
    '/^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$/d' \
    .config

echo "${TARGET_CONFIG}" >> .config

echo
echo "当前 Device："

grep -E \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
    .config \
    || true


# ============================================================
# 9. Device 数量检查
# ============================================================

echo
echo "============================================================"
echo " 9. defconfig 前 Device 检查"
echo "============================================================"

DEVICE_COUNT_BEFORE="$(
    grep -E \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
        .config |
    wc -l |
    tr -d ' '
)"

echo "DEVICE_COUNT_BEFORE=${DEVICE_COUNT_BEFORE}"

if [ "${DEVICE_COUNT_BEFORE}" != "1" ]; then
    echo "❌ defconfig 前 Device 数量错误"
    exit 1
fi

if ! grep -qxF "${TARGET_CONFIG}" .config; then
    echo "❌ WH3000 Pro Device 不正确"
    exit 1
fi

echo "✅ defconfig 前 Device 正确"


# ============================================================
# 10. 打印 defconfig 前关键配置
# ============================================================

echo
echo "============================================================"
echo " 10. defconfig 前关键配置"
echo "============================================================"

grep -E \
    '^(CONFIG_TARGET_|CONFIG_LINUX_)' \
    .config |
grep -E \
    'TARGET_(arm|BOARD|SUBTARGET|mediatek|MULTI_PROFILE|PER_DEVICE_ROOTFS|DEVICE)' \
    || true

echo


# ============================================================
# 11. 运行 make defconfig
# ============================================================

echo "============================================================"
echo " 11. 执行 make defconfig"
echo "============================================================"

make defconfig

echo
echo "✅ make defconfig 完成"


# ============================================================
# 12. defconfig 后立即检查 Device
# ============================================================

echo
echo "============================================================"
echo " 12. defconfig 后 Device 检查"
echo "============================================================"

echo
echo "defconfig 后所有 Filogic Device："

grep -E \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_' \
    .config \
    || true

echo

DEVICE_COUNT_AFTER="$(
    grep -E \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
        .config |
    wc -l |
    tr -d ' '
)"

echo "DEVICE_COUNT_AFTER=${DEVICE_COUNT_AFTER}"

if [ "${DEVICE_COUNT_AFTER}" = "1" ] &&
   grep -qxF "${TARGET_CONFIG}" .config; then

    echo
    echo "✅ WH3000 Pro Device 在 defconfig 后保留"
    echo "✅ Kconfig 配置成功"

else

    echo
    echo "❌ WH3000 Pro Device 在 defconfig 后消失"
    echo
    echo "============================================================"
    echo " KCONFIG 诊断信息"
    echo "============================================================"

    echo
    echo "---- TARGET 相关配置 ----"

    grep -E \
        '^CONFIG_TARGET_' \
        .config \
        || true

    echo
    echo "---- Device 相关配置 ----"

    grep -E \
        'DEVICE_' \
        .config \
        || true

    echo
    echo "---- MULTI_PROFILE ----"

    grep -E \
        '^CONFIG_TARGET_MULTI_PROFILE' \
        .config \
        || true

    echo
    echo "---- PER_DEVICE_ROOTFS ----"

    grep -E \
        '^CONFIG_TARGET_PER_DEVICE_ROOTFS' \
        .config \
        || true

    echo
    echo "---- 当前 Profile ----"

    grep -E \
        '^CONFIG_TARGET_PROFILE=' \
        .config \
        || true

    echo
    echo "---- 当前 WH3000 Pro ----"

    grep -E \
        'wh3000' \
        .config \
        || true

    echo
    echo "============================================================"
    echo " KCONFIG DIAGNOSTIC END"
    echo "============================================================"

    exit 1
fi
# ============================================================
# 13. 检查 defconfig 后基础 Target
# ============================================================

echo
echo "============================================================"
echo " 13. defconfig 后 Target 检查"
echo "============================================================"

echo
echo "当前 Target："

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
# 14. 检查 Multi Profile
# ============================================================

echo
echo "============================================================"
echo " 14. Multi Profile 检查"
echo "============================================================"

if grep -qx 'CONFIG_TARGET_MULTI_PROFILE=y' .config; then
    echo "✅ CONFIG_TARGET_MULTI_PROFILE=y"
else
    echo "❌ CONFIG_TARGET_MULTI_PROFILE=y 消失"
    exit 1
fi

if grep -qx 'CONFIG_TARGET_PER_DEVICE_ROOTFS=y' .config; then
    echo "✅ CONFIG_TARGET_PER_DEVICE_ROOTFS=y"
else
    echo "❌ CONFIG_TARGET_PER_DEVICE_ROOTFS=y 消失"
    exit 1
fi


# ============================================================
# 15. 检查 OpenWrt One
# ============================================================

echo
echo "============================================================"
echo " 15. OpenWrt One 检查"
echo "============================================================"

if grep -qx \
    'CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_openwrt_one=y' \
    .config; then

    echo "❌ OpenWrt One 被选中"
    exit 1
fi

echo "✅ OpenWrt One 未被选择"


# ============================================================
# 16. 检查 CONFIG_TARGET_PROFILE
# ============================================================

echo
echo "============================================================"
echo " 16. Target Profile 检查"
echo "============================================================"

if grep -q '^CONFIG_TARGET_PROFILE=' .config; then
    echo "⚠️ 发现 CONFIG_TARGET_PROFILE："
    grep '^CONFIG_TARGET_PROFILE=' .config

    echo
    echo "⚠️ 本次不主动删除它。"
    echo "⚠️ 先记录 FanchmWrt 的实际 Kconfig 结果。"
else
    echo "✅ 没有 CONFIG_TARGET_PROFILE"
fi


# ============================================================
# 17. 再次确认 WH3000 Pro Device
# ============================================================

echo
echo "============================================================"
echo " 17. WH3000 Pro Device 最终确认"
echo "============================================================"

FINAL_DEVICE_LINES="$(
    grep -E \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
        .config \
        || true
)"

echo
echo "当前选择的 Device："
echo "${FINAL_DEVICE_LINES}"
echo

FINAL_DEVICE_COUNT="$(
    printf '%s\n' "${FINAL_DEVICE_LINES}" |
    sed '/^$/d' |
    wc -l |
    tr -d ' '
)"

echo "FINAL_DEVICE_COUNT=${FINAL_DEVICE_COUNT}"

if [ "${FINAL_DEVICE_COUNT}" != "1" ]; then
    echo
    echo "❌ Filogic Device 数量错误"
    exit 1
fi

if ! grep -qxF "${TARGET_CONFIG}" .config; then
    echo
    echo "❌ 当前 Device 不是 WH3000 Pro"
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

echo
echo "✅ WH3000 Pro Device 正确"


# ============================================================
# 18. 检查错误的旧 Device 写法
# ============================================================

echo
echo "============================================================"
echo " 18. 检查错误 Device 写法"
echo "============================================================"

# 错误：
# CONFIG_TARGET_DEVICE_mediatek_filogic=y

if grep -qx \
    'CONFIG_TARGET_DEVICE_mediatek_filogic=y' \
    .config; then

    echo "❌ 发现错误配置："
    echo "CONFIG_TARGET_DEVICE_mediatek_filogic=y"
    exit 1
fi


# 错误：
# huasifei_wh3000-pro-emmc
#
# 正确：
# huasifei_wh3000_pro_emmc

if grep -qx \
    'CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_huasifei_wh3000-pro-emmc=y' \
    .config; then

    echo "❌ 发现错误的连字符 Device 配置"
    exit 1
fi

echo "✅ 没有发现错误 Device 配置"


# ============================================================
# 19. 检查 WH3000 Pro DTS
# ============================================================

echo
echo "============================================================"
echo " 19. DTS 最终检查"
echo "============================================================"

if [ ! -f "${DTS_EMMC}" ]; then
    echo "❌ DTS 不存在："
    echo "${DTS_EMMC}"
    exit 1
fi

echo "✅ DTS 存在："
echo "   ${DTS_EMMC}"


# ============================================================
# 20. 检查 Device → DTS
# ============================================================

echo
echo "============================================================"
echo " 20. Device → DTS 检查"
echo "============================================================"

DEVICE_BLOCK="$(
    sed \
        -n \
        '/^define Device\/huasifei_wh3000-pro-emmc$/,/^endef$/p' \
        "${DEVICE_MK}"
)"

if [ -z "${DEVICE_BLOCK}" ]; then
    echo "❌ 无法读取 WH3000 Pro Device 定义"
    exit 1
fi

echo
echo "${DEVICE_BLOCK}"
echo

if ! printf '%s\n' "${DEVICE_BLOCK}" |
    grep -q \
    'DEVICE_DTS.*mt7981b-huasifei-wh3000-pro-emmc'; then

    echo "❌ Device 没有引用正确 DTS"
    exit 1
fi

echo "✅ Device → DTS 正确"


# ============================================================
# 21. 检查 TARGET_DEVICES
# ============================================================

echo
echo "============================================================"
echo " 21. TARGET_DEVICES 检查"
echo "============================================================"

if ! grep -q \
    '^TARGET_DEVICES.*huasifei_wh3000-pro-emmc' \
    "${DEVICE_MK}"; then

    echo "❌ WH3000 Pro 没有注册到 TARGET_DEVICES"
    exit 1
fi

echo "✅ WH3000 Pro 已注册 TARGET_DEVICES"


# ============================================================
# 22. 检查 sysupgrade.bin 定义
# ============================================================

echo
echo "============================================================"
echo " 22. sysupgrade.bin 定义检查"
echo "============================================================"

if printf '%s\n' "${DEVICE_BLOCK}" |
    grep -q 'IMAGE/sysupgrade\.bin'; then

    echo "✅ WH3000 Pro 定义了 IMAGE/sysupgrade.bin"
else
    echo "⚠️ Device 定义中没有发现 IMAGE/sysupgrade.bin"
    echo "⚠️ 暂时不修改 filogic.mk"
fi


# ============================================================
# 23. 显示最终配置摘要
# ============================================================

echo
echo "============================================================"
echo " 23. 最终配置摘要"
echo "============================================================"

echo
echo "------ Target ------"

grep -E \
    '^(CONFIG_TARGET_arm=|CONFIG_TARGET_BOARD=|CONFIG_TARGET_SUBTARGET=|CONFIG_TARGET_mediatek=|CONFIG_TARGET_mediatek_filogic=)' \
    .config \
    || true

echo
echo "------ Profile ------"

grep -E \
    '^CONFIG_TARGET_(MULTI_PROFILE|PER_DEVICE_ROOTFS|PROFILE)=' \
    .config \
    || true

echo
echo "------ Device ------"

grep -E \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
    .config \
    || true

echo
echo "------ RootFS ------"

grep -E \
    '^CONFIG_TARGET_ROOTFS_(SQUASHFS|PARTSIZE)=' \
    .config \
    || true

echo


# ============================================================
# 24. 保存最终 .config
# ============================================================

echo "============================================================"
echo " 24. 保存最终 .config"
echo "============================================================"

cp .config .config.wh3000pro.final

echo "✅ 已保存："
echo "${BUILD_DIR}/.config.wh3000pro.final"


# ============================================================
# 25. 生成当前配置差异
# ============================================================

echo
echo "============================================================"
echo " 25. 生成 diffconfig"
echo "============================================================"

if make -s diffconfig > .config.wh3000pro.diffconfig; then
    echo "✅ diffconfig 已生成："
    echo "${BUILD_DIR}/.config.wh3000pro.diffconfig"
else
    echo "⚠️ diffconfig 生成失败"
fi


# ============================================================
# 26. 输出关键 Kconfig 状态
# ============================================================

echo
echo "============================================================"
echo " 26. Kconfig 最终状态"
echo "============================================================"

echo
echo "TARGET:"
grep -E \
    '^CONFIG_TARGET_' \
    .config |
grep -E \
    '(TARGET_(arm|BOARD|SUBTARGET|mediatek|MULTI_PROFILE|PER_DEVICE_ROOTFS|PROFILE|DEVICE))' \
    || true

echo


# ============================================================
# 27. 检查是否仍然存在 OpenWrt One
# ============================================================

echo "============================================================"
echo " 27. OpenWrt One 最终检查"
echo "============================================================"

if grep -q \
    'CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_openwrt_one=y' \
    .config; then

    echo "❌ 最终配置仍然选择 OpenWrt One"
    exit 1
fi

echo "✅ OpenWrt One 未选择"


# ============================================================
# 28. 最终成功
# ============================================================

echo
echo "============================================================"
echo "              PREPARE SUCCESS"
echo "============================================================"

echo
echo "✅ FanchmWrt WH3000 Pro 配置准备完成"
echo
echo "Target："
echo "  mediatek / filogic"
echo
echo "Device："
echo "  huasifei_wh3000-pro-emmc"
echo
echo "Kconfig："
echo "  ${TARGET_CONFIG}"
echo
echo "DTS："
echo "  mt7981b-huasifei-wh3000-pro-emmc"
echo
echo "Multi Profile："
echo "  CONFIG_TARGET_MULTI_PROFILE=y"
echo
echo "Per Device RootFS："
echo "  CONFIG_TARGET_PER_DEVICE_ROOTFS=y"
echo
echo "Device 数量："
echo "  ${FINAL_DEVICE_COUNT}"
echo
echo "============================================================"
echo "       PREPARE SUCCESS — 可以进入正式编译"
echo "============================================================"
echo
