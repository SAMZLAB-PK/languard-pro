#!/bin/sh
# LANGUARD_AUTH_GUARD
if [ -x /www/cgi-bin/languard-auth-guard.sh ]; then
  . /www/cgi-bin/languard-auth-guard.sh
  lg_require_auth || exit 0
fi
LOG="/etc/ispdash/audit.log"
mkdir -p /etc/ispdash
touch "$LOG"

getq(){
  echo "$QUERY_STRING" | tr '&' '\n' | awk -F= -v k="$1" '$1==k{print $2; exit}'
}

ACTION="$(getq action)"

case "$ACTION" in
  read)
    echo "Content-Type: text/plain; charset=utf-8"
    echo "Cache-Control: no-cache"
    echo ""
    tail -n 250 "$LOG" 2>/dev/null
  ;;
  clear)
    echo "Content-Type: text/plain; charset=utf-8"
    echo ""
    CONFIRM="$(getq confirm)"
    if [ "$CONFIRM" = "YES" ]; then
      : > "$LOG"
      echo "OK|audit_cleared"
    else
      echo "ERR|confirm_required"
    fi
  ;;
  log)
    echo "Content-Type: text/plain; charset=utf-8"
    echo ""
    MSG="$(getq msg)"
    IP="${REMOTE_ADDR:-local}"
    echo "$(date '+%F %T %Z')|$IP|$MSG" >> "$LOG"
    echo "OK|logged"
  ;;
  *)
    echo "Content-Type: text/plain; charset=utf-8"
    echo ""
    echo "LanGuard audit ready"
  ;;
esac

exit 0
