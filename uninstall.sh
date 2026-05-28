#!/bin/sh
set +e

echo "=================================================="
echo " Uninstalling LanGuard Pro"
echo "=================================================="

mkdir -p /root/languard-backups
BACKUP="/root/languard-backups/languard-before-uninstall-$(date +%Y%m%d-%H%M%S).tar.gz"

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

/etc/init.d/languard-pro stop >/dev/null 2>&1 || true
/etc/init.d/languard-pro disable >/dev/null 2>&1 || true

sed -i '/languard-limits-engine.sh/d;/languard-perdevice-usage.sh/d;/languard-traffic-stats.sh/d' /etc/crontabs/root 2>/dev/null || true
/etc/init.d/cron restart >/dev/null 2>&1 || true

nft delete table inet languard 2>/dev/null || true
nft delete table inet languard_usage 2>/dev/null || true

for d in br-lan pppoe-wan wan eth0 eth1 lan1 lan2 lan3 lan4; do
    tc qdisc del dev "$d" root 2>/dev/null || true
    tc qdisc del dev "$d" ingress 2>/dev/null || true
    tc qdisc del dev "$d" clsact 2>/dev/null || true
done

rm -f /www/cgi-bin/devices.sh
rm -f /www/cgi-bin/dashboard-live-api.sh
rm -f /www/cgi-bin/dashboard-live-api-core-safe.sh
rm -f /www/cgi-bin/languard-action.sh
rm -f /root/languard-sync-devices.sh
rm -f /root/languard-limits-engine.sh
rm -f /root/languard-perdevice-usage.sh
rm -f /root/languard-traffic-stats.sh
rm -f /etc/init.d/languard-pro

echo ""
echo "Runtime data kept at /etc/ispdash."
echo "To remove it manually: rm -rf /etc/ispdash"
echo "Uninstall complete."
