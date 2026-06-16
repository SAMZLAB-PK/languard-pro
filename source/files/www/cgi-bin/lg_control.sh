#!/bin/sh
echo "Content-Type: application/json; charset=utf-8"
echo "Cache-Control: no-cache"
echo ""

QS="$QUERY_STRING"
ACTION=""
IP=""

OLDIFS="$IFS"
IFS='&'
set -- $QS
IFS="$OLDIFS"

for kv in "$@"; do
  key="${kv%%=*}"
  val="${kv#*=}"
  case "$key" in
    action) ACTION="$val" ;;
    ip) IP="$val" ;;
  esac
done

valid_ip() {
  echo "$1" | awk -F. '
    NF != 4 {exit 1}
    {
      for(i=1;i<=4;i++){
        if($i !~ /^[0-9]+$/ || $i < 0 || $i > 255) exit 1
      }
      exit 0
    }'
}

json() {
  echo "$1"
}

if ! valid_ip "$IP"; then
  json "{\"status\":\"error\",\"msg\":\"invalid ip\",\"raw\":\"$QS\"}"
  exit 0
fi

LANIP="$(uci -q get network.lan.ipaddr 2>/dev/null)"
if [ -n "$LANIP" ] && [ "$IP" = "$LANIP" ]; then
  json "{\"status\":\"error\",\"msg\":\"refusing to block router ip\",\"ip\":\"$IP\"}"
  exit 0
fi

if ! command -v iptables >/dev/null 2>&1; then
  json "{\"status\":\"error\",\"msg\":\"iptables not found\"}"
  exit 0
fi

if [ "$ACTION" = "block" ]; then
  iptables -C FORWARD -s "$IP" -j DROP 2>/dev/null || iptables -I FORWARD 1 -s "$IP" -j DROP
  echo "$(date '+%Y-%m-%d %H:%M:%S') block $IP" >> /tmp/languard_v7.log
  json "{\"status\":\"blocked\",\"ip\":\"$IP\"}"

elif [ "$ACTION" = "unblock" ]; then
  removed=0
  while iptables -D FORWARD -s "$IP" -j DROP 2>/dev/null; do
    removed=$((removed+1))
  done
  echo "$(date '+%Y-%m-%d %H:%M:%S') unblock $IP removed=$removed" >> /tmp/languard_v7.log
  json "{\"status\":\"unblocked\",\"ip\":\"$IP\",\"removed\":$removed}"

elif [ "$ACTION" = "status" ]; then
  if iptables -C FORWARD -s "$IP" -j DROP 2>/dev/null; then
    json "{\"status\":\"blocked\",\"ip\":\"$IP\"}"
  else
    json "{\"status\":\"clear\",\"ip\":\"$IP\"}"
  fi

else
  json "{\"status\":\"none\",\"raw\":\"$QS\"}"
fi
