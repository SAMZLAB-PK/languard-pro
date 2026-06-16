#!/bin/sh
set +e

SPEED="/tmp/languard-speed.state"
UDB="/etc/ispdash/device_usage.db"

TODAY="$(date +%Y%m%d)"
MONTH="$(date +%Y%m)"
NOW="$(date +%s)"

mkdir -p /etc/ispdash
touch "$UDB"

IFACE="$(ip route get 1.1.1.1 2>/dev/null | awk '{
  for(i=1;i<=NF;i++){
    if($i=="dev"){print $(i+1); exit}
  }
}')"

[ -z "$IFACE" ] && IFACE="$(ip route 2>/dev/null | awk '/^default/ {print $5; exit}')"
[ -z "$IFACE" ] && IFACE="pppoe-wan"

RX_FILE="/sys/class/net/$IFACE/statistics/rx_bytes"
TX_FILE="/sys/class/net/$IFACE/statistics/tx_bytes"

RX=0
TX=0
[ -f "$RX_FILE" ] && RX="$(cat "$RX_FILE" 2>/dev/null)"
[ -f "$TX_FILE" ] && TX="$(cat "$TX_FILE" 2>/dev/null)"
[ -z "$RX" ] && RX=0
[ -z "$TX" ] && TX=0

DL_KBS=0
UL_KBS=0

if [ -f "$SPEED" ]; then
    read OLD_TIME OLD_RX OLD_TX OLD_IFACE < "$SPEED"

    [ -z "$OLD_TIME" ] && OLD_TIME="$NOW"
    [ -z "$OLD_RX" ] && OLD_RX="$RX"
    [ -z "$OLD_TX" ] && OLD_TX="$TX"

    DIFF_TIME=$((NOW - OLD_TIME))
    [ "$DIFF_TIME" -le 0 ] && DIFF_TIME=1

    if [ "$IFACE" = "$OLD_IFACE" ] && [ "$RX" -ge "$OLD_RX" ] 2>/dev/null && [ "$TX" -ge "$OLD_TX" ] 2>/dev/null; then
        DIFF_RX=$((RX - OLD_RX))
        DIFF_TX=$((TX - OLD_TX))
        DL_KBS=$((DIFF_RX / DIFF_TIME / 1024))
        UL_KBS=$((DIFF_TX / DIFF_TIME / 1024))
    fi
fi

echo "$NOW $RX $TX $IFACE" > "$SPEED"

awk -F'|' -v day="$TODAY" -v mon="$MONTH" -v dl="$DL_KBS" -v ul="$UL_KBS" -v iface="$IFACE" '
{
    if($1==day) daily+=$4
    if($2==mon) monthly+=$5
    total+=$6
}
END{
    printf "META|%s|%s|%.2f|%.2f|%.2f|%s\n", dl, ul, daily/1024/1024/1024, monthly/1024/1024/1024, total/1024/1024/1024, iface
}' "$UDB"

exit 0
