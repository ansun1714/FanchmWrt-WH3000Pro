#!/bin/bash
set -euo pipefail
cd "${GITHUB_WORKSPACE}/openwrt"

# Basic defaults. These are deliberately small and safe for the first test.
# We do NOT overwrite the WH3000 Pro hardware DTS.

mkdir -p files/etc/uci-defaults

cat > files/etc/uci-defaults/99-dongzai-wh3000pro <<'EOF'
#!/bin/sh

# Hostname
uci -q set system.@system[0].hostname='WH3000-Pro'

# Timezone
uci -q set system.@system[0].zonename='Asia/Shanghai'
uci -q set system.@system[0].timezone='CST-8'

uci -q commit system

# Enable Docker only if the init script exists.
if [ -x /etc/init.d/dockerd ]; then
    /etc/init.d/dockerd enable 2>/dev/null || true
fi

# Enable Lucky only if present.
if [ -x /etc/init.d/lucky ]; then
    /etc/init.d/lucky enable 2>/dev/null || true
fi

exit 0
EOF

chmod 755 files/etc/uci-defaults/99-dongzai-wh3000pro

# Keep Docker data on the eMMC mount if /mnt/mmcblk0p7 exists.
# We do not force-create an fstab entry in this first build because
# partition labels/layouts must be confirmed on the actual unit.
