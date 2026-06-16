#!/bin/sh
echo "Content-Type: application/json; charset=utf-8"
echo "Cache-Control: no-cache"
echo ""

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

get_qs_value() {
  key="$1"
  echo "$QUERY_STRING" | tr '&' '\n' | awk -F= -v k="$key" '$1==k{print $2; exit}'
}

REQ_IFACE="$(get_qs_value iface)"

DEFAULT_IFACE="$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}')"
[ -z "$DEFAULT_IFACE" ] && DEFAULT_IFACE="$(uci -q get network.wan.device 2>/dev/null)"
[ -z "$DEFAULT_IFACE" ] && DEFAULT_IFACE="$(uci -q get network.wan.ifname 2>/dev/null)"
DEFAULT_IFACE="${DEFAULT_IFACE%% *}"

if [ -z "$DEFAULT_IFACE" ] || ! grep -q "^[[:space:]]*$DEFAULT_IFACE:" /proc/net/dev 2>/dev/null; then
  DEFAULT_IFACE="$(awk -F: '
    NR>2{
      name=$1
      gsub(/ /,"",name)
      if(name!="lo" && name!="br-lan"){
        print name
        exit
      }
    }' /proc/net/dev)"
fi

[ -z "$DEFAULT_IFACE" ] && DEFAULT_IFACE="br-lan"

if [ -z "$REQ_IFACE" ] || [ "$REQ_IFACE" = "auto" ]; then
  IFACE="$DEFAULT_IFACE"
  IFACE_MODE="auto"
else
  IFACE="$REQ_IFACE"
  IFACE_MODE="manual"
fi

if ! grep -q "^[[:space:]]*$IFACE:" /proc/net/dev 2>/dev/null; then
  IFACE="$DEFAULT_IFACE"
  IFACE_MODE="fallback"
fi

RX="$(awk -F'[: ]+' -v i="$IFACE" '$2==i{print $3; f=1} END{if(!f) print 0}' /proc/net/dev 2>/dev/null)"
TX="$(awk -F'[: ]+' -v i="$IFACE" '$2==i{print $11; f=1} END{if(!f) print 0}' /proc/net/dev 2>/dev/null)"
COUNT="$(awk 'NR>1 && $4!="00:00:00:00:00:00"{c++} END{print c+0}' /proc/net/arp 2>/dev/null)"
WANIP="$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}')"
NOW="$(date '+%Y-%m-%d %H:%M:%S %Z')"

printf '{'
printf '"status":"V7_1_INTERFACE_PATCH",'
printf '"iface":"%s",' "$(json_escape "$IFACE")"
printf '"iface_mode":"%s",' "$(json_escape "$IFACE_MODE")"
printf '"default_iface":"%s",' "$(json_escape "$DEFAULT_IFACE")"
printf '"rx_bytes":%s,' "${RX:-0}"
printf '"tx_bytes":%s,' "${TX:-0}"
printf '"device_count":%s,' "${COUNT:-0}"
printf '"wan_ip":"%s",' "$(json_escape "$WANIP")"

printf '"interfaces":['
awk -F: 'NR>2{
  name=$1
  gsub(/ /,"",name)
  split($2,a," ")
  if(n++) printf ","
  printf "{\"name\":\"%s\",\"rx\":%s,\"tx\":%s}", name, a[1]+0, a[9]+0
}' /proc/net/dev 2>/dev/null
printf '],'

printf '"devices":['
awk 'NR>1 && $4!="00:00:00:00:00:00" {
  if(n++) printf ","
  printf "{\"ip\":\"%s\",\"mac\":\"%s\",\"iface\":\"%s\"}", $1, $4, $6
}' /proc/net/arp 2>/dev/null
printf '],'

printf '"time":"%s"' "$(json_escape "$NOW")"
printf '}\n'
