#!/bin/sh
set +e

APP="LanGuard Pro"
BASE="$(cd "$(dirname "$0")" && pwd)"

echo "=================================================="
echo " Installing $APP"
echo "=================================================="

[ "$(id -u)" != "0" ] && {
    echo "ERROR: Run as root."
    exit 1
}

install_pkg() {
    p="$1"
    if command -v apk >/dev/null 2>&1; then
        apk add "$p" >/dev/null 2>&1 && return 0
    fi
    if command -v opkg >/dev/null 2>&1; then
        opkg install "$p" >/dev/null 2>&1 && return 0
    fi
    return 1
}

echo "=== Update package index ==="
if command -v apk >/dev/null 2>&1; then apk update >/dev/null 2>&1 || true; fi
if command -v opkg >/dev/null 2>&1; then opkg update >/dev/null 2>&1 || true; fi

echo "=== Try installing useful packages ==="
for p in uhttpd rpcd nftables iw ip-full ip-bridge tc-tiny tc-full coreutils-timeout; do
    echo "Trying: $p"
    install_pkg "$p" || true
done

echo "=== Create folders ==="
mkdir -p /www/cgi-bin /root /etc/ispdash /root/languard-backups

echo "=== Backup old installation ==="
BACKUP="/root/languard-backups/languard-before-install-$(date +%Y%m%d-%H%M%S).tar.gz"
tar -czf "$BACKUP" \
  /www/cgi-bin/devices.sh \
  /www/cgi-bin/dashboard-live-api.sh \
  /www/cgi-bin/dashboard-live-api-core-safe.sh \
  /www/cgi-bin/languard-action.sh \
  /root/languard-sync-devices.sh \
  /root/languard-limits-engine.sh \
  /root/languard-perdevice-usage.sh \
  /root/languard-traffic-stats.sh \
  /etc/init.d/languard-pro \
  /etc/ispdash 2>/dev/null || true

echo "Backup: $BACKUP"

echo "=== Copy LanGuard files ==="
[ ! -d "$BASE/files" ] && {
    echo "ERROR: files/ directory missing. Repo incomplete."
    exit 1
}

cp -f "$BASE/files/www/cgi-bin/"*.sh /www/cgi-bin/ 2>/dev/null || true
cp -f "$BASE/files/root/"*.sh /root/ 2>/dev/null || true
cp -f "$BASE/files/etc/init.d/languard-pro" /etc/init.d/languard-pro 2>/dev/null || true

chmod 755 /www/cgi-bin/devices.sh 2>/dev/null || true
chmod 755 /www/cgi-bin/dashboard-live-api.sh 2>/dev/null || true
chmod 755 /www/cgi-bin/dashboard-live-api-core-safe.sh 2>/dev/null || true
chmod 755 /www/cgi-bin/languard-action.sh 2>/dev/null || true
chmod 755 /root/languard-sync-devices.sh 2>/dev/null || true
chmod 755 /root/languard-limits-engine.sh 2>/dev/null || true
chmod 755 /root/languard-perdevice-usage.sh 2>/dev/null || true
chmod 755 /root/languard-traffic-stats.sh 2>/dev/null || true
chmod 755 /etc/init.d/languard-pro 2>/dev/null || true

echo "=== Create clean databases ==="
touch /etc/ispdash/devices.db
touch /etc/ispdash/blocked.db
touch /etc/ispdash/names.db
touch /etc/ispdash/deleted.db
touch /etc/ispdash/staticips.db
touch /etc/ispdash/limits.db
touch /etc/ispdash/usage.db
touch /etc/ispdash/device_usage.db
touch /etc/ispdash/traffic.state
chmod 600 /etc/ispdash/*.db /etc/ispdash/traffic.state 2>/dev/null || true

echo "=== Disable firewall flow offloading ==="
uci -q set firewall.@defaults[0].flow_offloading='0'
uci -q set firewall.@defaults[0].flow_offloading_hw='0'
uci -q commit firewall
/etc/init.d/firewall restart >/dev/null 2>&1 || true

echo "=== Setup cron ==="
touch /etc/crontabs/root
sed -i '/languard-limits-engine.sh/d;/languard-perdevice-usage.sh/d;/languard-traffic-stats.sh/d' /etc/crontabs/root 2>/dev/null || true

echo '* * * * * /root/languard-limits-engine.sh >/dev/null 2>&1' >> /etc/crontabs/root
echo '* * * * * /root/languard-perdevice-usage.sh >/dev/null 2>&1' >> /etc/crontabs/root
echo '* * * * * /root/languard-traffic-stats.sh >/dev/null 2>&1' >> /etc/crontabs/root

/etc/init.d/cron enable >/dev/null 2>&1 || true
/etc/init.d/cron restart >/dev/null 2>&1 || true

echo "=== Enable services ==="
/etc/init.d/uhttpd enable >/dev/null 2>&1 || true
/etc/init.d/rpcd enable >/dev/null 2>&1 || true
/etc/init.d/languard-pro enable >/dev/null 2>&1 || true

/root/languard-sync-devices.sh >/dev/null 2>&1 || true
/root/languard-perdevice-usage.sh >/dev/null 2>&1 || true
/root/languard-traffic-stats.sh >/dev/null 2>&1 || true
/root/languard-limits-engine.sh >/dev/null 2>&1 || true

/etc/init.d/languard-pro restart >/dev/null 2>&1 || true
/etc/init.d/uhttpd restart >/dev/null 2>&1 || true
/etc/init.d/rpcd restart >/dev/null 2>&1 || true

LANIP="$(uci -q get network.lan.ipaddr)"
[ -z "$LANIP" ] && LANIP="192.168.1.1"

echo ""
echo "=================================================="
echo "$APP installed."
echo "Open: http://$LANIP/cgi-bin/devices.sh"
echo "=================================================="
echo ""
echo "API preview:"
/www/cgi-bin/dashboard-live-api.sh | head -20 2>/dev/null || true
