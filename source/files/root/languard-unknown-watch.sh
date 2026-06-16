#!/bin/sh
TRUST="/etc/ispdash/trusted.db"
SEEN="/etc/ispdash/unknown_seen.db"
LOG="/etc/ispdash/audit.log"
POLICY="/etc/ispdash/unknown_policy"

mkdir -p /etc/ispdash
touch "$TRUST" "$SEEN" "$LOG"
[ -f "$POLICY" ] || echo "alert" > "$POLICY"

MODE="$(cat "$POLICY" 2>/dev/null)"
[ -z "$MODE" ] && MODE="alert"

TMP="/tmp/languard-unknown-now.$$"

QUERY_STRING="action=unknown" /www/cgi-bin/languard-trust.sh 2>/dev/null > "$TMP"

awk -F'|' -v seen="$SEEN" -v log="$LOG" -v mode="$MODE" '
BEGIN{
  while((getline line < seen)>0){
    old[tolower(line)]=1
  }
  close(seen)
}
$1=="UNKNOWN"{
  mac=tolower($2)
  status=$3
  ip=$4
  name=$5
  type=$6

  if(!old[mac]){
    cmd="date \"+%F %T %Z\""
    cmd | getline now
    close(cmd)

    print now "|local|unknown_device_detected|mac=" mac "|ip=" ip "|name=" name "|type=" type "|mode=" mode >> log
    print mac >> seen
  }
}' "$TMP"

if [ "$MODE" = "block" ]; then
  awk -F'|' '$1=="UNKNOWN" && $6=="LAN"{print $2}' "$TMP" | while read mac; do
    [ -n "$mac" ] || continue
    QUERY_STRING="action=block&mac=$mac" /www/cgi-bin/languard-action-audit.sh >/dev/null 2>&1
  done
fi

rm -f "$TMP"
exit 0
