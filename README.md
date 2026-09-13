# FanchmWrt WH3000 Pro 自动编译

这是第一版 **FanchmWrt 25.12.4 + Huasifei WH3000 Pro eMMC** 测试工程。

目标：
- 使用 FanchmWrt 官方已经提供的 `huasifei_wh3000-pro-emmc`
- 使用其 Linux 6.12 MediaTek/Filogic 基础
- 集成 QModem `luci-app-qmodem-next`
- 集成 Lucky
- 集成 Docker
- 保留后续加入 MSD Lite、rtp2httpd、IPTV Combo 的入口
- GitHub Actions 编译完成后自动创建 GitHub Release

## 第一版为什么暂时不把 IPTV/MSD/rtp2httpd 强行塞进去？

这次首先验证最重要的三件事：

1. WH3000 Pro eMMC 镜像能否稳定编译、刷写和启动；
2. MT7981 双频 Wi-Fi、2.5G/1G 网口、风扇、eMMC 是否正常；
3. QModem 是否能正确发现内置移动模组，并进一步测试自动 APN。

如果第一版硬件/QModem正常，再把你现有的 IPTV Combo、MSD Lite、rtp2httpd 包逐个加入，避免一次加入太多变量导致无法判断问题来源。

## 使用

1. 新建一个 GitHub 仓库。
2. 把本目录全部上传到仓库根目录。
3. Actions -> `FanchmWrt WH3000 Pro` -> `Run workflow`。
4. 第一次建议 `clean_build = false`。
5. 编译成功后在 Releases 下载 `sysupgrade.bin`。

> 注意：第一次刷机前请确认你当前设备确实是 WH3000 Pro eMMC 版本，并准备好串口/TFTP/救砖手段。固件刷写属于高风险操作。
