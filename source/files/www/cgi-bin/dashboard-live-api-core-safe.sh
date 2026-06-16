#!/bin/sh
set +e

echo "Content-Type: text/plain; charset=utf-8"
echo "Cache-Control: no-cache"
echo ""

DB="/etc/ispdash/devices.db"
BLOCKED="/etc/ispdash/blocked.db"
NAMES="/etc/ispdash/names.db"
DELETED="/etc/ispdash/deleted.db"
STATICIPS="/etc/ispdash/staticips.db"
LIMITS="/etc/ispdash/limits.db"
UDB="/etc/ispdash/device_usage.db"
SPEEDDB="/tmp/languard-device-speed.db"

DAY="$(date +%Y%m%d)"
MON="$(date +%Y%m)"

mkdir -p /etc/ispdash
touch "$DB" "$BLOCKED" "$NAMES" "$DELETED" "$STATICIPS" "$LIMITS" "$UDB" "$SPEEDDB"

[ -x /root/languard-sync-devices.sh ] && /root/languard-sync-devices.sh >/dev/null 2>&1
[ -x /root/languard-perdevice-usage.sh ] && /root/languard-perdevice-usage.sh >/dev/null 2>&1

SHOW_DELETED="0"
echo "$QUERY_STRING" | grep -q 'view=deleted' && SHOW_DELETED="1"
echo "$QUERY_STRING" | grep -q 'deleted=1' && SHOW_DELETED="1"

WAN_UP="0"
WAN_IP="No WAN"
if ifstatus wan 2>/dev/null | grep -q '"up": true'; then
    WAN_UP="1"
    WAN_IP="$(ifstatus wan 2>/dev/null | sed -n 's/.*"address": "\([^"]*\)".*/\1/p' | head -1)"
    [ -z "$WAN_IP" ] && WAN_IP="Connected"
fi

TOTAL=0
ONLINE=0
OFFLINE=0
BLOCKCNT="$(grep -c . "$BLOCKED" 2>/dev/null)"
TSCNT=0
DELCNT="$(grep -c . "$DELETED" 2>/dev/null)"

while IFS='|' read -r mac ip name status seen dtype; do
    [ -z "$mac" ] && continue
    grep -qi "^$mac$" "$DELETED" 2>/dev/null && continue

    TOTAL=$((TOTAL+1))
    [ "$dtype" = "TAILSCALE" ] && TSCNT=$((TSCNT+1))

    if grep -qi "^$mac$" "$BLOCKED" 2>/dev/null; then
        :
    elif [ "$status" = "ONLINE" ]; then
        ONLINE=$((ONLINE+1))
    else
        OFFLINE=$((OFFLINE+1))
    fi
done < "$DB"

echo "TOTAL|$TOTAL|$ONLINE|$OFFLINE|$BLOCKCNT|$TSCNT|$WAN_UP|$WAN_IP|$DELCNT"

[ -x /root/languard-traffic-stats.sh ] && /root/languard-traffic-stats.sh || echo "META|0|0|0.00|0.00|0.00|wan"

while IFS='|' read -r mac ip name status seen dtype; do
    [ -z "$mac" ] && continue

    is_deleted="0"
    grep -qi "^$mac$" "$DELETED" 2>/dev/null && is_deleted="1"

    if [ "$SHOW_DELETED" = "1" ]; then
        [ "$is_deleted" = "1" ] || continue
        status="DELETED"
    else
        [ "$is_deleted" = "0" ] || continue
    fi

    custom="$(grep -i "^$mac|" "$NAMES" 2>/dev/null | tail -1 | cut -d'|' -f2-)"
    [ -n "$custom" ] && name="$custom"

    staticip="$(grep -i "^$mac|" "$STATICIPS" 2>/dev/null | tail -1 | cut -d'|' -f2)"
    [ -n "$staticip" ] && ip="$staticip"

    blocked="0"
    if grep -qi "^$mac$" "$BLOCKED" 2>/dev/null; then
        blocked="1"
        [ "$SHOW_DELETED" = "0" ] && status="BLOCKED"
    fi

    lim_enabled="0"
    lim_dl="0"
    lim_ul="0"
    lim_data="0"
    lim_state="OFF"

    limrow="$(grep -i "^$mac|" "$LIMITS" 2>/dev/null | tail -1)"
    if [ -n "$limrow" ]; then
        lim_enabled="$(echo "$limrow" | cut -d'|' -f2)"
        lim_dl="$(echo "$limrow" | cut -d'|' -f3)"
        lim_ul="$(echo "$limrow" | cut -d'|' -f4)"
        lim_data="$(echo "$limrow" | cut -d'|' -f5)"
        [ "$lim_enabled" = "1" ] && lim_state="ON"
    fi

    daily_bytes="$(awk -F'|' -v day="$DAY" -v m="$mac" '$1==day && tolower($3)==m {print $4}' "$UDB" | tail -1)"
    monthly_bytes="$(awk -F'|' -v mon="$MON" -v m="$mac" '$2==mon && tolower($3)==m {print $5}' "$UDB" | tail -1)"
    total_bytes="$(awk -F'|' -v m="$mac" 'tolower($3)==m {print $6}' "$UDB" | tail -1)"

    [ -z "$daily_bytes" ] && daily_bytes=0
    [ -z "$monthly_bytes" ] && monthly_bytes=0
    [ -z "$total_bytes" ] && total_bytes=0

    daily_gb="$(awk -v b="$daily_bytes" 'BEGIN{printf "%.2f", b/1024/1024/1024}')"
    monthly_gb="$(awk -v b="$monthly_bytes" 'BEGIN{printf "%.2f", b/1024/1024/1024}')"
    total_gb="$(awk -v b="$total_bytes" 'BEGIN{printf "%.2f", b/1024/1024/1024}')"

    rt_dl="$(awk -F'|' -v m="$mac" 'tolower($1)==m {print $2}' "$SPEEDDB" | tail -1)"
    rt_ul="$(awk -F'|' -v m="$mac" 'tolower($1)==m {print $3}' "$SPEEDDB" | tail -1)"
    [ -z "$rt_dl" ] && rt_dl=0
    [ -z "$rt_ul" ] && rt_ul=0

    if [ "$lim_enabled" = "1" ] && awk -v d="$lim_data" 'BEGIN{exit !(d+0>0)}'; then
        over="$(awk -v u="$monthly_gb" -v d="$lim_data" 'BEGIN{if(u+0 >= d+0) print 1; else print 0}')"
        [ "$over" = "1" ] && lim_state="DATA_BLOCKED"
    fi

    [ -z "$ip" ] && ip="No IP"
    [ -z "$name" ] && name="$mac"
    [ -z "$seen" ] && seen="0"
    [ -z "$dtype" ] && dtype="LAN"

    # Fields:
    # 0 DEV | 1 mac | 2 status | 3 ip | 4 name | 5 blocked | 6 seen | 7 type | 8 deleted
    # 9 limit enabled | 10 dl limit | 11 ul limit | 12 data limit | 13 monthly usage | 14 limit state
    # 15 daily usage | 16 monthly usage | 17 total usage | 18 rt dl KB/s | 19 rt ul KB/s
    echo "DEV|$mac|$status|$ip|$name|$blocked|$seen|$dtype|$is_deleted|$lim_enabled|$lim_dl|$lim_ul|$lim_data|$monthly_gb|$lim_state|$daily_gb|$monthly_gb|$total_gb|$rt_dl|$rt_ul"
done < "$DB"

exit 0
