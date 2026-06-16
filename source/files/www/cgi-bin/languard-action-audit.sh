#!/bin/sh
# LANGUARD_AUTH_GUARD
if [ -x /www/cgi-bin/languard-auth-guard.sh ]; then
  . /www/cgi-bin/languard-auth-guard.sh
  lg_require_auth || exit 0
fi
LOG="/etc/ispdash/audit.log"
GUARD="/tmp/languard-session-usage.max"
DB="/etc/ispdash/device_usage.db"

mkdir -p /etc/ispdash
touch "$LOG"

getq(){
  echo "$QUERY_STRING" | tr '&' '\n' | awk -F= -v k="$1" '$1==k{print $2; exit}'
}

ACT="$(getq action)"
MAC="$(getq mac | tr 'A-F' 'a-f')"
IP="${REMOTE_ADDR:-local}"

case "$ACT" in
  save|block|unblock|delete|restore|limit_save|limit_clear|usage_reset)
    echo "$(date '+%F %T %Z')|$IP|action=$ACT|mac=$MAC|query=$QUERY_STRING" >> "$LOG"
  ;;
esac

OUT="$(QUERY_STRING="$QUERY_STRING" /www/cgi-bin/languard-action.sh 2>&1)"
echo "$OUT"

if echo "$OUT" | grep -q '^OK|' && [ "$ACT" = "usage_reset" ] && [ -n "$MAC" ]; then
  if [ -f "$GUARD" ]; then
    awk -F'|' -v m="$MAC" 'tolower($3)!=m' "$GUARD" > "$GUARD.tmp" && mv "$GUARD.tmp" "$GUARD"
  fi
  if [ -f "$DB" ]; then
    awk -F'|' -v m="$MAC" 'tolower($3)!=m' "$DB" > "$DB.tmp" && mv "$DB.tmp" "$DB"
  fi
  echo "$(date '+%F %T %Z')|$IP|usage_guard_reset|mac=$MAC" >> "$LOG"
fi

exit 0
