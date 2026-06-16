#!/bin/sh
# LANGUARD_AUTH_GUARD
if [ -x /www/cgi-bin/languard-auth-guard.sh ]; then
  . /www/cgi-bin/languard-auth-guard.sh
  lg_require_auth || exit 0
fi
SDB="/etc/ispdash/schedules.db"
SBLOCK="/etc/ispdash/schedule_blocks.db"
LOG="/etc/ispdash/audit.log"

mkdir -p /etc/ispdash
touch "$SDB" "$SBLOCK" "$LOG"

urldecode(){
  printf '%b' "$(echo "$1" | sed 's/+/ /g;s/%/\\x/g')"
}

getq(){
  echo "$QUERY_STRING" | tr '&' '\n' | awk -F= -v k="$1" '$1==k{print $2; exit}'
}

normmac(){
  echo "$1" | tr 'A-F' 'a-f' | sed 's/[^0-9a-f:]//g'
}

validmac(){
  echo "$1" | grep -Eiq '^[0-9a-f]{2}(:[0-9a-f]{2}){5}$'
}

ACTION="$(getq action)"
MAC="$(normmac "$(urldecode "$(getq mac)")")"
ENABLED="$(urldecode "$(getq enabled)")"
START="$(urldecode "$(getq start)")"
ENDT="$(urldecode "$(getq end)")"
NOW="$(date '+%F %T %Z')"
IP="${REMOTE_ADDR:-local}"

case "$ACTION" in
  get)
    echo "Content-Type: text/plain; charset=utf-8"
    echo "Cache-Control: no-cache"
    echo ""
    if ! validmac "$MAC"; then
      echo "ERR|invalid_mac"
      exit 0
    fi
    awk -F'|' -v m="$MAC" 'tolower($1)==m{found=1; print "OK|" $0} END{if(!found) print "OK|" m "|0|08:00|23:00|0"}' "$SDB"
  ;;

  list)
    echo "Content-Type: text/plain; charset=utf-8"
    echo "Cache-Control: no-cache"
    echo ""
    cat "$SDB"
  ;;

  save)
    echo "Content-Type: text/plain; charset=utf-8"
    echo ""
    if ! validmac "$MAC"; then
      echo "ERR|invalid_mac"
      exit 0
    fi

    [ "$ENABLED" = "1" ] || ENABLED="0"
    echo "$START" | grep -Eq '^[0-2][0-9]:[0-5][0-9]$' || START="08:00"
    echo "$ENDT" | grep -Eq '^[0-2][0-9]:[0-5][0-9]$' || ENDT="23:00"

    awk -F'|' -v m="$MAC" 'tolower($1)!=m' "$SDB" > "$SDB.tmp" 2>/dev/null
    echo "$MAC|$ENABLED|$START|$ENDT|$(date +%s)" >> "$SDB.tmp"
    mv "$SDB.tmp" "$SDB"

    echo "$NOW|$IP|schedule_saved|mac=$MAC|enabled=$ENABLED|start=$START|end=$ENDT" >> "$LOG"
    echo "OK|schedule_saved|$MAC|$ENABLED|$START|$ENDT"
  ;;

  clear)
    echo "Content-Type: text/plain; charset=utf-8"
    echo ""
    if ! validmac "$MAC"; then
      echo "ERR|invalid_mac"
      exit 0
    fi

    awk -F'|' -v m="$MAC" 'tolower($1)!=m' "$SDB" > "$SDB.tmp" 2>/dev/null && mv "$SDB.tmp" "$SDB"
    awk -F'|' -v m="$MAC" 'tolower($1)!=m' "$SBLOCK" > "$SBLOCK.tmp" 2>/dev/null && mv "$SBLOCK.tmp" "$SBLOCK"

    echo "$NOW|$IP|schedule_cleared|mac=$MAC" >> "$LOG"
    echo "OK|schedule_cleared|$MAC"
  ;;

  *)
    echo "Content-Type: text/plain; charset=utf-8"
    echo ""
    echo "LanGuard schedule ready"
  ;;
esac

exit 0
