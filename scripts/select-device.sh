#!/bin/sh
# Informational helper only.
# FanchmWrt 25.12.4 already contains the WH3000 Pro eMMC Device definition.
# This file is intentionally not used to rewrite target/linux files.
grep -n -A16 'Device/huasifei_wh3000-pro-emmc' \
  openwrt/target/linux/mediatek/image/filogic.mk

