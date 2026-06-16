#!/bin/sh
# LANGUARD_AUTH_GUARD
if [ -x /www/cgi-bin/languard-auth-guard.sh ]; then
  . /www/cgi-bin/languard-auth-guard.sh
  lg_require_auth || exit 0
fi
BACKUP_DIR="/root/languard-backups"
LOG="/etc/ispdash/audit.log"
mkdir -p "$BACKUP_DIR" /etc/ispdash
touch "$LOG"

getq(){
  echo "$QUERY_STRING" | tr '&' '\n' | awk -F= -v k="$1" '$1==k{print $2; exit}'
}

ACTION="$(getq action)"

create_backup(){
  TS="$(date +%Y%m%d-%H%M%S)"
  OUT="$BACKUP_DIR/lg_manual_$TS.tar.gz"

  set --
  [ -d /etc/ispdash ] && set -- "$@" /etc/ispdash
  [ -f /etc/crontabs/root ] && set -- "$@" /etc/crontabs/root
  [ -f /www/cgi-bin/devices.sh ] && set -- "$@" /www/cgi-bin/devices.sh
  [ -f /www/cgi-bin/dashboard-live-api.sh ] && set -- "$@" /www/cgi-bin/dashboard-live-api.sh
  [ -f /www/cgi-bin/languard-action.sh ] && set -- "$@" /www/cgi-bin/languard-action.sh
  [ -f /www/cgi-bin/languard-action-audit.sh ] && set -- "$@" /www/cgi-bin/languard-action-audit.sh
  [ -f /www/cgi-bin/languard-backup.sh ] && set -- "$@" /www/cgi-bin/languard-backup.sh
  [ -f /www/cgi-bin/languard-audit.sh ] && set -- "$@" /www/cgi-bin/languard-audit.sh
  [ -f /www/cgi-bin/languard-maintenance.sh ] && set -- "$@" /www/cgi-bin/languard-maintenance.sh
  [ -f /root/languard-sync-devices.sh ] && set -- "$@" /root/languard-sync-devices.sh
  [ -f /root/languard-perdevice-usage.sh ] && set -- "$@" /root/languard-perdevice-usage.sh
  [ -f /root/languard-traffic-stats.sh ] && set -- "$@" /root/languard-traffic-stats.sh
  [ -f /root/languard-limits-engine.sh ] && set -- "$@" /root/languard-limits-engine.sh
  [ -f /root/languard-apply-blocks.sh ] && set -- "$@" /root/languard-apply-blocks.sh

  if tar -czf "$OUT" "$@" 2>/tmp/lg_backup_err; then
    SIZE="$(ls -lh "$OUT" | awk '{print $5}')"
    echo "$(date '+%F %T %Z')|local|backup_created|file=$OUT|size=$SIZE" >> "$LOG"
    echo "OK|backup_created|$OUT|$SIZE"
  else
    echo "ERR|backup_failed|$(cat /tmp/lg_backup_err 2>/dev/null)"
  fi
}

list_backups(){
  ls -lh "$BACKUP_DIR"/lg_manual_*.tar.gz 2>/dev/null | awk '{print $9 "|" $5 "|" $6 " " $7 " " $8}' | tail -n 50
}

latest_backup(){
  ls -t "$BACKUP_DIR"/lg_manual_*.tar.gz 2>/dev/null | head -n 1
}

case "$ACTION" in
  create)
    echo "Content-Type: text/plain; charset=utf-8"
    echo "Cache-Control: no-cache"
    echo ""
    create_backup
  ;;
  list)
    echo "Content-Type: text/plain; charset=utf-8"
    echo "Cache-Control: no-cache"
    echo ""
    list_backups
  ;;
  restore_latest)
    echo "Content-Type: text/plain; charset=utf-8"
    echo ""
    CONFIRM="$(getq confirm)"
    if [ "$CONFIRM" != "YES" ]; then
      echo "ERR|confirm_required"
      exit 0
    fi

    B="$(latest_backup)"
    if [ -z "$B" ] || [ ! -f "$B" ]; then
      echo "ERR|no_backup_found"
      exit 0
    fi

    if tar -xzf "$B" -C / 2>/tmp/lg_restore_err; then
      chmod 755 /www/cgi-bin/*.sh 2>/dev/null
      /etc/init.d/cron restart >/dev/null 2>&1
      /etc/init.d/uhttpd restart >/dev/null 2>&1
      echo "$(date '+%F %T %Z')|local|backup_restored|file=$B" >> "$LOG"
      echo "OK|restored|$B"
    else
      echo "ERR|restore_failed|$(cat /tmp/lg_restore_err 2>/dev/null)"
    fi
  ;;
  download_latest)
    B="$(latest_backup)"
    if [ -z "$B" ] || [ ! -f "$B" ]; then
      echo "Content-Type: text/plain"
      echo ""
      echo "ERR|no_backup_found"
      exit 0
    fi
    BN="$(basename "$B")"
    echo "Content-Type: application/gzip"
    echo "Content-Disposition: attachment; filename=\"$BN\""
    echo ""
    cat "$B"
  ;;
  *)
    echo "Content-Type: text/plain; charset=utf-8"
    echo ""
    echo "LanGuard backup ready"
  ;;
esac

exit 0
