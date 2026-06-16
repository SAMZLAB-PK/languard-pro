#!/bin/sh
# LANGUARD_AUTH_GUARD
if [ -x /www/cgi-bin/languard-auth-guard.sh ]; then
  . /www/cgi-bin/languard-auth-guard.sh
  lg_require_auth || exit 0
fi
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

mkdir -p /etc/ispdash

touch "$DB" "$BLOCKED" "$NAMES" "$DELETED" "$STATICIPS" "$LIMITS" "$UDB" 2>/dev/null

[ -x /root/languard-sync-devices.sh ] && /root/languard-sync-devices.sh >/dev/null 2>&1
[ -x /root/languard-perdevice-usage.sh ] && /root/languard-perdevice-usage.sh >/dev/null 2>&1

SHOW_DELETED="0"
echo "$QUERY_STRING $*" | grep -q "view=deleted" && SHOW_DELETED="1"
echo "$QUERY_STRING $*" | grep -q "deleted=1" && SHOW_DELETED="1"

DAY="$(date +%F)"
MON="$(date +%Y-%m)"
NOW="$(date +%s)"

LANIP="$(uci -q get network.lan.ipaddr 2>/dev/null)"
[ -z "$LANIP" ] && LANIP="192.168.10.1"
LANP="${LANIP%.*}."

BASE="/tmp/languard-all-devices.base"
MERGED="/tmp/languard-all-devices.merged"
ONLINE="/tmp/languard-online-macs.db"
DEVOUT="/tmp/languard-devout.$$"

: > "$BASE"
: > "$MERGED"
: > "$ONLINE"
: > "$DEVOUT"

# 1) Existing historical LanGuard device DB
awk -F'|' '
function okmac(m,a){m=tolower(m); return split(m,a,":")==6 && length(a[1])==2 && length(a[2])==2 && length(a[3])==2 && length(a[4])==2 && length(a[5])==2 && length(a[6])==2}
{
  m=tolower($1)
  if(!okmac(m)) next
  ip=$2; name=$3; st=$4; seen=$5; typ=$6
  if(ip=="") ip="No IP"
  if(name=="") name=m
  if(st=="") st="OFFLINE"
  if(seen=="") seen="0"
  if(typ=="") typ="LAN"
  print m "|" ip "|" name "|" st "|" seen "|" typ
}' "$DB" >> "$BASE"

# 2) Current DHCP leases
awk -v now="$NOW" '
function okmac(m,a){m=tolower(m); return split(m,a,":")==6 && length(a[1])==2 && length(a[2])==2 && length(a[3])==2 && length(a[4])==2 && length(a[5])==2 && length(a[6])==2}
{
  m=tolower($2)
  if(!okmac(m)) next
  name=$4
  gsub(/_/," ",name)
  if(name=="*" || name=="") name=m
  print m "|" $3 "|" name "|ONLINE|" $1 "|LAN"
}' /tmp/dhcp.leases 2>/dev/null >> "$BASE"

# 3) Current LAN ARP, only LAN subnet to avoid bogus extra IPs
awk -v p="$LANP" -v now="$NOW" '
function okmac(m,a){m=tolower(m); return split(m,a,":")==6 && length(a[1])==2 && length(a[2])==2 && length(a[3])==2 && length(a[4])==2 && length(a[5])==2 && length(a[6])==2}
NR>1 {
  ip=$1; m=tolower($4); dev=$6
  if(dev!="br-lan") next
  if(index(ip,p)!=1) next
  if(m=="00:00:00:00:00:00") next
  if(!okmac(m)) next
  print m "|" ip "|" m "|ONLINE|" now "|LAN"
}' /proc/net/arp 2>/dev/null >> "$BASE"

# 4) Devices that only exist in names/static/limits/blocked/deleted/usage DB
awk -F'|' '
function okmac(m,a){m=tolower(m); return split(m,a,":")==6 && length(a[1])==2 && length(a[2])==2 && length(a[3])==2 && length(a[4])==2 && length(a[5])==2 && length(a[6])==2}
{
  m=tolower($1)
  if(okmac(m)) print m "|No IP|" $2 "|OFFLINE|0|LAN"
}' "$NAMES" 2>/dev/null >> "$BASE"

awk -F'|' '
function okmac(m,a){m=tolower(m); return split(m,a,":")==6 && length(a[1])==2 && length(a[2])==2 && length(a[3])==2 && length(a[4])==2 && length(a[5])==2 && length(a[6])==2}
{
  m=tolower($1)
  if(okmac(m)) print m "|" $2 "|" m "|OFFLINE|0|LAN"
}' "$STATICIPS" 2>/dev/null >> "$BASE"

awk -F'|' '
function okmac(m,a){m=tolower(m); return split(m,a,":")==6 && length(a[1])==2 && length(a[2])==2 && length(a[3])==2 && length(a[4])==2 && length(a[5])==2 && length(a[6])==2}
{
  m=tolower($1)
  if(okmac(m)) print m "|No IP|" m "|OFFLINE|0|LAN"
}' "$LIMITS" "$BLOCKED" "$DELETED" 2>/dev/null >> "$BASE"

awk -F'|' '
function okmac(m,a){m=tolower(m); return split(m,a,":")==6 && length(a[1])==2 && length(a[2])==2 && length(a[3])==2 && length(a[4])==2 && length(a[5])==2 && length(a[6])==2}
{
  m=tolower($3)
  if(okmac(m)) print m "|No IP|" m "|OFFLINE|0|LAN"
}' "$UDB" 2>/dev/null >> "$BASE"

# Merge by MAC, prefer real IP/name/online status/new seen
awk -F'|' '
function okip(x){return x!="" && x!="No IP" && x!="0.0.0.0"}
function goodname(x){return x!="" && x!="Unknown" && x !~ /^[0-9a-f][0-9a-f](:[0-9a-f][0-9a-f]){5}$/}
{
  m=tolower($1); ip=$2; name=$3; st=$4; seen=$5+0; typ=$6
  if(!(m in had)){
    had[m]=1; order[++n]=m
    ipA[m]=ip; nameA[m]=name; stA[m]=st; seenA[m]=seen; typA[m]=typ
  } else {
    if(okip(ip) && (!okip(ipA[m]) || ip ~ /^192\.168\./ || ip ~ /^10\./)) ipA[m]=ip
    if(goodname(name) && !goodname(nameA[m])) nameA[m]=name
    if(st=="ONLINE") stA[m]="ONLINE"
    else if(st=="BLOCKED" && stA[m]!="ONLINE") stA[m]="BLOCKED"
    if(seen>seenA[m]) seenA[m]=seen
    if(typ=="TAILSCALE") typA[m]="TAILSCALE"
    else if(typA[m]=="") typA[m]="LAN"
  }
}
END{
  for(i=1;i<=n;i++){
    m=order[i]
    if(ipA[m]=="") ipA[m]="No IP"
    if(nameA[m]=="") nameA[m]=m
    if(stA[m]=="") stA[m]="OFFLINE"
    if(typA[m]=="") typA[m]="LAN"
    print m "|" ipA[m] "|" nameA[m] "|" stA[m] "|" seenA[m] "|" typA[m]
  }
}' "$BASE" > "$MERGED"

awk -F'|' '$4=="ONLINE"{print $1}' "$BASE" | sort -u > "$ONLINE"

has_mac_file() {
  f="$1"
  m="$2"
  [ -f "$f" ] || return 1
  awk -F'|' -v m="$m" 'tolower($1)==m{found=1} END{exit found?0:1}' "$f"
}

get_field2() {
  f="$1"
  m="$2"
  [ -f "$f" ] || return
  awk -F'|' -v m="$m" 'tolower($1)==m{v=$2} END{print v}' "$f"
}

get_limit() {
  m="$1"
  awk -F'|' -v m="$m" 'tolower($1)==m{v=$2 "|" $3 "|" $4 "|" $5} END{print v}' "$LIMITS"
}

get_usage() {
  m="$1"
  awk -F'|' -v day="$DAY" -v mon="$MON" -v m="$m" '
  tolower($3)==m {
    if($1==day) d=$4
    if($2==mon) mo=$5
    t=$6
  }
  END{
    if(d=="") d=0
    if(mo=="") mo=0
    if(t=="") t=0
    print d "|" mo "|" t
  }' "$UDB"
}

get_speed() {
  m="$1"
  [ -f "$SPEEDDB" ] || { echo "0|0"; return; }
  awk -F'|' -v m="$m" 'tolower($1)==m{v=$2 "|" $3} END{if(v=="") v="0|0"; print v}' "$SPEEDDB"
}

gb() {
  awk -v b="${1:-0}" 'BEGIN{printf "%.2f", b/1024/1024/1024}'
}

total=0
online=0
offline=0
blocked_count=0
tailscale_count=0
sum_day=0
sum_mon=0
sum_total=0

deleted_count="$(awk -F'|' '
function okmac(m,a){m=tolower(m); return split(m,a,":")==6 && length(a[1])==2 && length(a[2])==2 && length(a[3])==2 && length(a[4])==2 && length(a[5])==2 && length(a[6])==2}
okmac($1){c++}
END{print c+0}' "$DELETED" 2>/dev/null)"

while IFS='|' read -r mac ip name status seen dtype; do
  [ -z "$mac" ] && continue

  is_deleted="0"
  has_mac_file "$DELETED" "$mac" && is_deleted="1"

  if [ "$SHOW_DELETED" = "1" ]; then
    [ "$is_deleted" = "1" ] || continue
  else
    [ "$is_deleted" = "0" ] || continue
  fi

  n2="$(get_field2 "$NAMES" "$mac")"
  [ -n "$n2" ] && name="$n2"

  ip2="$(get_field2 "$STATICIPS" "$mac")"
  [ -n "$ip2" ] && ip="$ip2"

  blocked="0"
  if has_mac_file "$BLOCKED" "$mac"; then
    blocked="1"
    status="BLOCKED"
  else
    if grep -qi "^$mac$" "$ONLINE" 2>/dev/null; then
      status="ONLINE"
    elif [ -z "$status" ] || [ "$status" = "BLOCKED" ]; then
      status="OFFLINE"
    fi
  fi

  [ "$dtype" = "TAILSCALE" ] || dtype="LAN"

  lim="$(get_limit "$mac")"
  IFS='|' read -r lim_enabled lim_dl lim_ul lim_data <<EOF_LIM
$lim
EOF_LIM
  [ -z "$lim_enabled" ] && lim_enabled="0"
  [ -z "$lim_dl" ] && lim_dl="0"
  [ -z "$lim_ul" ] && lim_ul="0"
  [ -z "$lim_data" ] && lim_data="0"

  usage="$(get_usage "$mac")"
  IFS='|' read -r daily_bytes monthly_bytes total_bytes <<EOF_USE
$usage
EOF_USE

  # DATA ZERO FALLBACK FIX START
  [ -z "$daily_bytes" ] && daily_bytes=0
  [ -z "$monthly_bytes" ] && monthly_bytes=0
  [ -z "$total_bytes" ] && total_bytes=0
  if [ "$daily_bytes" = "0" ] && [ "$total_bytes" != "0" ]; then
    daily_bytes="$total_bytes"
  fi
  if [ "$monthly_bytes" = "0" ] && [ "$total_bytes" != "0" ]; then
    monthly_bytes="$total_bytes"
  fi
  # DATA ZERO FALLBACK FIX END
  daily_gb="$(gb "$daily_bytes")"
  monthly_gb="$(gb "$monthly_bytes")"
  total_gb="$(gb "$total_bytes")"

  lim_state="OFF"
  if [ "$lim_enabled" = "1" ]; then
    lim_state="ON"
    if [ "$lim_data" != "0" ]; then
      over="$(awk -v u="$monthly_gb" -v d="$lim_data" 'BEGIN{if(u+0 >= d+0) print 1; else print 0}')"
      [ "$over" = "1" ] && lim_state="DATA_BLOCKED"
    fi
  fi

  sp="$(get_speed "$mac")"
  IFS='|' read -r rt_dl rt_ul <<EOF_SPD
$sp
EOF_SPD
  [ -z "$rt_dl" ] && rt_dl="0"
  [ -z "$rt_ul" ] && rt_ul="0"

  echo "DEV|$mac|$status|$ip|$name|$blocked|$seen|$dtype|$is_deleted|$lim_enabled|$lim_dl|$lim_ul|$lim_data|$monthly_gb|$lim_state|$daily_gb|$monthly_gb|$total_gb|$rt_dl|$rt_ul" >> "$DEVOUT"

  total=$((total + 1))
  [ "$status" = "ONLINE" ] && online=$((online + 1))
  [ "$status" = "OFFLINE" ] && offline=$((offline + 1))
  [ "$status" = "BLOCKED" ] && blocked_count=$((blocked_count + 1))
  [ "$dtype" = "TAILSCALE" ] && tailscale_count=$((tailscale_count + 1))

  sum_day=$((sum_day + daily_bytes))
  sum_mon=$((sum_mon + monthly_bytes))
  sum_total=$((sum_total + total_bytes))
done < "$MERGED"

META_LINE="$([ -x /root/languard-traffic-stats.sh ] && /root/languard-traffic-stats.sh 2>/dev/null | grep '^META|' | head -1)"
rtDl="$(echo "$META_LINE" | awk -F'|' '{print $2}')"
rtUl="$(echo "$META_LINE" | awk -F'|' '{print $3}')"
wanIface="$(echo "$META_LINE" | awk -F'|' '{print $7}')"
[ -z "$rtDl" ] && rtDl="0"
[ -z "$rtUl" ] && rtUl="0"
[ -z "$wanIface" ] && wanIface="wan"

useToday="$(gb "$sum_day")"
useMonth="$(gb "$sum_mon")"
useTotal="$(gb "$sum_total")"

WAN_UP="0"
ip route 2>/dev/null | grep -q '^default ' && WAN_UP="1"
WAN_IP="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}')"
[ -z "$WAN_IP" ] && WAN_IP="0.0.0.0"

echo "TOTAL|$total|$online|$offline|$blocked_count|$tailscale_count|$WAN_UP|$WAN_IP|$deleted_count"
echo "META|$rtDl|$rtUl|$useToday|$useMonth|$useTotal|$wanIface"
cat "$DEVOUT"

rm -f "$DEVOUT"
exit 0
