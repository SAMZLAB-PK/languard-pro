# LanGuard Pro

LanGuard Pro is a lightweight, mobile-friendly CGI dashboard for OpenWrt and ImmortalWrt routers. It helps you monitor connected devices, manage network access, apply speed/data controls, view activity, and perform basic router maintenance from a simple web interface.

It is designed for local router use and does not require any cloud service.

## What LanGuard Pro Can Do

LanGuard Pro provides a router dashboard focused on device visibility, access control, usage monitoring, and simple administration.

### Device Management

* View connected and known devices
* See device details and activity information
* Rename or identify devices
* Mark devices as trusted
* Block or unblock devices
* Delete or restore device records
* Review unknown devices before taking action

### Access Control

* Block unwanted devices from the network
* Restore blocked devices when needed
* Keep trusted devices separate from unknown devices
* Use safety-first controls so automatic blocking is not enabled by default

### Speed and Data Limits

* Apply speed limits for devices
* Apply data usage limits
* Track upload and download usage
* Monitor device-level usage activity

### Dashboard and Monitoring

* View a simple device dashboard
* Check router/network health
* Review device activity insights
* View usage reports
* Access tools from a mobile-friendly interface

### Backup and Restore

* Create backups of LanGuard Pro data
* Restore previous LanGuard Pro data
* Keep runtime data separate from the install package

### Security and Login

* Router password based login
* Designed for local router administration
* Runtime device data is generated on the router after installation
* No private runtime database, logs, backups, or router passwords are included in the package

## Supported Systems

LanGuard Pro is intended for:

* OpenWrt routers using `opkg`
* ImmortalWrt/OpenWrt builds using `apk`

Packages are provided in both formats where supported.

## Packages

Prebuilt installable packages are available from the GitHub **Releases** page.

Current release assets include:

* `languard-pro_2026.06.16-r1_all.ipk` for opkg-based OpenWrt
* `languard-pro-2026.06.16-r1.apk` for apk-based ImmortalWrt/OpenWrt
* `SHA256SUMS` for checksum verification
* Optional release archive containing package files and helper installer

## Verify Downloads

After downloading the release assets, you can verify checksums on a Linux/OpenWrt system:

```sh
sha256sum -c SHA256SUMS
```

## Install

Download the correct package for your router from the **Releases** page, then copy it to your router.

### apk-based ImmortalWrt/OpenWrt

```sh
apk add --allow-untrusted languard-pro-2026.06.16-r1.apk
```

### opkg-based OpenWrt

```sh
opkg install languard-pro_2026.06.16-r1_all.ipk
```

### Using the release installer

If you downloaded the full release archive that includes `install.sh` and the package files, copy the extracted folder to your router and run:

```sh
sh install.sh
```

## Open Dashboard

After installation, open the LanGuard Pro dashboard in your browser:

```text
http://192.168.10.1/cgi-bin/languard-login.sh
```

If your router uses a different LAN IP address, replace `192.168.10.1` with your router IP.

Login with your router username and password. Usually:

```text
Username: root
Password: your router/LuCI password
```

## Project Structure

```text
source/
├── files/
│   ├── www/cgi-bin/     # CGI dashboard pages and actions
│   └── root/            # Router-side helper scripts
├── ipk-control/         # opkg/IPK package control files
├── apk-post-install     # apk package post-install hook
└── apk-pre-deinstall    # apk package pre-remove hook

install.sh              # Helper installer for release archive use
README.md               # Project documentation
LICENSE                 # MIT License
```

## Privacy Note

Runtime device data is not included in the package.

The following data is created on the router only after installation and use:

* device databases
* device names
* usage logs
* audit logs
* backups
* login configuration
* router-specific runtime settings

This keeps the public package clean and avoids publishing private router data.

## Safety Note

Unknown-device auto-block and schedule enforcement are not enabled by default. Enable these options manually only after testing on your own router.

Before applying strict blocking rules, make sure your own trusted devices are correctly identified so you do not lock yourself out of the network.

## License

LanGuard Pro is released under the MIT License.
