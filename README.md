# LanGuard Pro

LanGuard Pro is a lightweight CGI dashboard for OpenWrt and ImmortalWrt.

## Features

- Device dashboard
- Block/unblock/delete/restore devices
- Speed and data limits
- Usage tracking
- Health page
- Tools page
- Backup and restore
- Reports
- Security/trusted device view
- Device details and activity insights
- Router password login

## Packages

This release includes:

- `dist/languard-pro_2026.06.16-r1_all.ipk` for opkg-based OpenWrt
- `dist/languard-pro-2026.06.16-r1.apk` for apk-based OpenWrt/ImmortalWrt

## Install

Copy this folder to your router, then run:

```sh
sh install.sh
```

Or install manually:

### apk-based ImmortalWrt/OpenWrt

```sh
apk add --allow-untrusted dist/languard-pro-2026.06.16-r1.apk
```

### opkg-based OpenWrt

```sh
opkg install dist/languard-pro_2026.06.16-r1_all.ipk
```

## Open Dashboard

```text
http://192.168.10.1/cgi-bin/languard-login.sh
```

Login with your router username and password. Usually:

```text
Username: root
Password: your router/LuCI password
```

## Privacy note

Runtime device data is not included in the package:

- device databases
- names
- usage logs
- audit logs
- backups
- login configuration

These files are created on the router after installation.

## Safety note

Unknown-device auto-block and schedule enforcer are not enabled by default. Enable them manually only after testing.
