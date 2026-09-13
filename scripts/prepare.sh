#!/bin/bash
set -euo pipefail

echo
echo "============================================================"
echo " DONGZAI - WH3000 Pro Prepare"
echo "============================================================"

# ============================================================
# 0. 基本变量
# ============================================================

TARGET_DEVICE="huasifei_wh3000-pro-emmc"
TARGET_SYMBOL="huasifei_wh3000_pro_emmc"
TARGET_CONFIG="CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_${TARGET_SYMBOL}=y"

CONFIG_FILE="${GITHUB_WORKSPACE}/config/wh3000pro.config"

echo
echo "TARGET_DEVICE = ${TARGET_DEVICE}"
echo "TARGET_SYMBOL = ${TARGET_SYMBOL}"
echo "TARGET_CONFIG = ${TARGET_CONFIG}"
echo "CONFIG_FILE   = ${CONFIG_FILE}"

# ============================================================
# 1. 检查源码
# ============================================================

echo
echo "============================================================"
echo " 1. 检查源码"
echo "============================================================"

if [ ! -d target/linux/mediatek ]; then
    echo "❌ target/linux/mediatek 不存在"
    exit 1
fi

echo "✅ MediaTek target 存在"

# ============================================================
# 2. 检查配置文件
# ============================================================

echo
echo "============================================================"
echo " 2. 检查 WH3000 Pro 配置文件"
echo "============================================================"

if [ ! -f "${CONFIG_FILE}" ]; then
    echo "❌ 找不到 ${CONFIG_FILE}"
    exit 1
fi

echo "✅ 找到 ${CONFIG_FILE}"

# ============================================================
# 3. 导入用户配置
# ============================================================

echo
echo "============================================================"
echo " 3. 导入 WH3000 Pro 用户配置"
echo "============================================================"

cp -f "${CONFIG_FILE}" .config

echo "✅ ${CONFIG_FILE} 已复制到 .config"

# ============================================================
# 4. 清理旧 Target / Device 配置
# ============================================================

echo
echo "============================================================"
echo " 4. 清理旧 Target / Device"
echo "============================================================"

# 清除所有旧的 Filogic Device
sed -i \
    '/^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$/d' \
    .config

# 清除旧的错误 Device 基础符号
sed -i \
    '/^CONFIG_TARGET_DEVICE_mediatek_filogic=y$/d' \
    .config

# 清除可能存在的旧 Profile
sed -i \
    '/^CONFIG_TARGET_PROFILE=/d' \
    .config

echo "✅ 已清理旧 Filogic Device / Profile"

# ============================================================
# 5. 设置 MediaTek / Filogic Target
# ============================================================

echo
echo "============================================================"
echo " 5. 设置 MediaTek / Filogic Target"
echo "============================================================"

cat >> .config <<EOF

CONFIG_TARGET_arm=y
CONFIG_TARGET_BOARD="mediatek"
CONFIG_TARGET_SUBTARGET="filogic"

CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y

CONFIG_TARGET_MULTI_PROFILE=y
CONFIG_TARGET_PER_DEVICE_ROOTFS=y

EOF

echo "✅ MediaTek / Filogic Target 已设置"

# ============================================================
# 6. 设置 WH3000 Pro Device
# ============================================================

echo
echo "============================================================"
echo " 6. 设置 WH3000 Pro Device"
echo "============================================================"

cat >> .config <<EOF
${TARGET_CONFIG}
CONFIG_TARGET_DEVICE_PACKAGES_mediatek_filogic=""
EOF

echo "当前 Device："

grep -E \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_' \
    .config \
    || true

# ============================================================
# 7. RootFS 设置
# ============================================================

echo
echo "============================================================"
echo " 7. RootFS 设置"
echo "============================================================"

# 删除旧值，避免重复
sed -i \
    '/^CONFIG_TARGET_ROOTFS_SQUASHFS=/d' \
    .config

sed -i \
    '/^CONFIG_TARGET_ROOTFS_PARTSIZE=/d' \
    .config

cat >> .config <<EOF

CONFIG_TARGET_ROOTFS_SQUASHFS=y
CONFIG_TARGET_ROOTFS_PARTSIZE=448
EOF

echo "CONFIG_TARGET_ROOTFS_SQUASHFS=y"
echo "CONFIG_TARGET_ROOTFS_PARTSIZE=448"

# ============================================================
# 8. defconfig 前检查
# ============================================================

echo
echo "============================================================"
echo " 8. defconfig 前 Device 检查"
echo "============================================================"

DEVICE_COUNT_BEFORE="$(
    grep -E \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_.*=y$' \
        .config \
        | wc -l
)"

echo "DEVICE_COUNT_BEFORE=${DEVICE_COUNT_BEFORE}"

if [ "${DEVICE_COUNT_BEFORE}" -ne 1 ]; then
    echo
    echo "❌ defconfig 前 Device 数量不是 1"
    grep -E \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_' \
        .config \
        || true
    exit 1
fi

if ! grep -q \
    "^${TARGET_CONFIG}$" \
    .config; then

    echo "❌ WH3000 Pro Device 不存在"
    exit 1
fi

echo "✅ defconfig 前 WH3000 Pro Device 正确"

# ============================================================
# 9. defconfig 前关键配置
# ============================================================

echo
echo "============================================================"
echo " 9. defconfig 前关键配置"
echo "============================================================"

grep -E \
    '^(CONFIG_TARGET_arm=|CONFIG_TARGET_BOARD=|CONFIG_TARGET_SUBTARGET=|CONFIG_TARGET_mediatek=|CONFIG_TARGET_mediatek_filogic=|CONFIG_TARGET_MULTI_PROFILE=|CONFIG_TARGET_PER_DEVICE_ROOTFS=|CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_|CONFIG_TARGET_DEVICE_PACKAGES_mediatek_filogic)' \
    .config \
    || true

echo
echo "============================================================"
echo " 第一段完成"
echo "============================================================"
# ============================================================
# 10. 执行 make defconfig
# ============================================================

echo
echo "============================================================"
echo " 10. 执行 make defconfig"
echo "============================================================"

make defconfig

echo
echo "============================================================"
echo " 10.1 defconfig 完成"
echo "============================================================"

# ============================================================
# 11. Kconfig Device 符号诊断
# ============================================================

echo
echo "============================================================"
echo " 11. Kconfig Device 符号诊断"
echo "============================================================"

echo
echo "目标符号："
echo "${TARGET_CONFIG}"

# ============================================================
# 11.1 检查源码中是否存在 WH3000 Pro 符号
# ============================================================

echo
echo "------------------------------------------------------------"
echo "11.1 检查 Kconfig 源码中的 WH3000 Pro 符号"
echo "------------------------------------------------------------"

grep -R \
    -n \
    --exclude-dir=.git \
    --exclude='*.o' \
    --exclude='*.d' \
    'huasifei_wh3000_pro_emmc' \
    target/linux/mediatek \
    2>/dev/null \
    | head -100 \
    || true

# ============================================================
# 11.2 检查 Device 定义
# ============================================================

echo
echo "------------------------------------------------------------"
echo "11.2 检查 huasifei_wh3000-pro-emmc Device 定义"
echo "------------------------------------------------------------"

grep -R \
    -n \
    --exclude-dir=.git \
    'huasifei_wh3000-pro-emmc' \
    target/linux/mediatek \
    2>/dev/null \
    | head -100 \
    || true

# ============================================================
# 11.3 检查 Device Kconfig 相关文件
# ============================================================

echo
echo "------------------------------------------------------------"
echo "11.3 检查 Device Kconfig 相关文件"
echo "------------------------------------------------------------"

find target/linux/mediatek \
    -type f \
    \( \
        -name 'Config.in' \
        -o -name 'Kconfig' \
        -o -name 'target.mk' \
    \) \
    -print \
    | sort

# ============================================================
# 11.4 检查 defconfig 后 .config
# ============================================================

echo
echo "------------------------------------------------------------"
echo "11.4 defconfig 后 .config 中的 Device"
echo "------------------------------------------------------------"

grep -E \
    '^CONFIG_TARGET_DEVICE_mediatek_filogic' \
    .config \
    || true

echo
echo "Multi Profile："

grep -E \
    '^CONFIG_TARGET_MULTI_PROFILE=' \
    .config \
    || true

echo
echo "Per Device RootFS："

grep -E \
    '^CONFIG_TARGET_PER_DEVICE_ROOTFS=' \
    .config \
    || true

echo
echo "Target："

grep -E \
    '^(CONFIG_TARGET_mediatek=|CONFIG_TARGET_mediatek_filogic=|CONFIG_TARGET_BOARD=|CONFIG_TARGET_SUBTARGET=)' \
    .config \
    || true

# ============================================================
# 11.5 检查 Kconfig 生成文件
# ============================================================

echo
echo "============================================================"
echo " 11.5 检查 Kconfig 生成文件"
echo "============================================================"

echo
echo "tmp/.config-target.in："

if [ -f tmp/.config-target.in ]; then

    grep -n \
        -E \
        'huasifei|wh3000|CONFIG_TARGET_DEVICE_mediatek_filogic' \
        tmp/.config-target.in \
        | head -200 \
        || true

else

    echo "⚠️ tmp/.config-target.in 不存在"

fi

# ============================================================
# 11.6 检查其他生成的 Kconfig 文件
# ============================================================

echo
echo "------------------------------------------------------------"
echo "11.6 检查 tmp 中与 Target 相关的文件"
echo "------------------------------------------------------------"

find tmp \
    -maxdepth 2 \
    -type f \
    \( \
        -name '*config*' \
        -o -name '*target*' \
        -o -name '*kconfig*' \
    \) \
    -print \
    2>/dev/null \
    | sort \
    | head -100 \
    || true

# ============================================================
# 12. 最终判断
# ============================================================

echo
echo "============================================================"
echo " 12. 最终 Device 判断"
echo "============================================================"

if grep -q \
    "^${TARGET_CONFIG}$" \
    .config; then

    echo
    echo "============================================================"
    echo "✅ WH3000 Pro Device 在 defconfig 后仍然存在"
    echo "============================================================"

    echo
    echo "最终 Device："

    grep -E \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_' \
        .config \
        || true

else

    echo
    echo "============================================================"
    echo "❌ WH3000 Pro Device 被 make defconfig 删除"
    echo "============================================================"

    echo
    echo "当前所有 Filogic Device："

    grep -E \
        '^CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_' \
        .config \
        || true

    echo
    echo "============================================================"
    echo "❌ Kconfig 诊断结束：暂不进行固件编译"
    echo "============================================================"

    exit 1

fi

echo
echo "============================================================"
echo " PREPARE 诊断完成"
echo "============================================================"
