# LanGuard Pro

LanGuard Pro is a lightweight LAN and Tailscale device dashboard for OpenWrt / ImmortalWrt routers.

## Features

- LAN device dashboard
- Tailscale device visibility
- Editable device names
- Static DHCP IP reservation from dashboard
- Device block and unblock
- Delete and restore device view
- Realtime WAN download and upload
- Per-device realtime download and upload
- Daily, monthly, and total usage tracking
- Per-device speed limit
- Per-device monthly data limit
- Mobile-friendly dashboard
- Theme system including ImmortalWrt/LuCI-style theme

## Recommended system

- OpenWrt / ImmortalWrt 22.03 or newer
- firewall4 / nftables system
- uhttpd CGI enabled
- LAN bridge named br-lan

## Install

SSH into router and run:

    cd /tmp
    wget -O languard-pro.tar.gz https://github.com/SAMZLAB-PK/languard-pro/archive/refs/heads/main.tar.gz
    tar -xzf languard-pro.tar.gz
    cd languard-pro-main
    chmod +x install.sh
    ./install.sh

Open dashboard:

    http://ROUTER-IP/cgi-bin/devices.sh

Example:

    http://192.168.1.1/cgi-bin/devices.sh

## Uninstall

    cd /tmp/languard-pro-main
    chmod +x uninstall.sh
    ./uninstall.sh

## Privacy

Do not upload runtime files from /etc/ispdash to GitHub. They may contain private device names, MAC addresses, IP addresses, usage history, limits, blocked devices, and deleted devices.

The installer creates clean empty runtime databases automatically.
