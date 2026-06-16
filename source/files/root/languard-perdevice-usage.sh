#!/bin/sh
# LANGUARD SESSION GUARD WRAPPER
CORE="/root/languard-perdevice-usage.core.sh"
DB="/etc/ispdash/device_usage.db"
GUARD="/tmp/languard-session-usage.max"
DAY="$(date +%F)"
MON="$(date +%Y-%m)"

mkdir -p /etc/ispdash
touch "$DB" "$GUARD"

# Run original collector first
[ -x "$CORE" ] && "$CORE" >/dev/null 2>&1

# If collector produced no file, stop safely
[ -f "$DB" ] || exit 0

TMP="/tmp/languard-device-usage.guarded.$$"

awk -F'|' -v day="$DAY" -v mon="$MON" '
function macok(m,a){
  m=tolower(m)
  return split(m,a,":")==6
}
FNR==NR{
  m=tolower($3)
  if(macok(m)){
    key=$1 "|" $2 "|" m
    gd[key]=$4+0
    gm[key]=$5+0
    gt[m]=$6+0
  }
  next
}
{
  d=$1
  mo=$2
  m=tolower($3)
  if(!macok(m)) next

  dayb=$4+0
  monb=$5+0
  totb=$6+0
  key=d "|" mo "|" m

  if(d==day && (key in gd) && dayb < gd[key]) dayb=gd[key]
  if(mo==mon && (key in gm) && monb < gm[key]) monb=gm[key]
  if((m in gt) && totb < gt[m]) totb=gt[m]

  print d "|" mo "|" m "|" int(dayb) "|" int(monb) "|" int(totb)
}
' "$GUARD" "$DB" > "$TMP"

if [ -s "$TMP" ]; then
  mv "$TMP" "$DB"
else
  rm -f "$TMP"
fi

# Rebuild session guard for current boot/session
awk -F'|' '
function macok(m,a){
  m=tolower(m)
  return split(m,a,":")==6
}
{
  m=tolower($3)
  if(macok(m)) print $1 "|" $2 "|" m "|" int($4+0) "|" int($5+0) "|" int($6+0)
}
' "$DB" > "$GUARD.tmp" 2>/dev/null && mv "$GUARD.tmp" "$GUARD"

exit 0
