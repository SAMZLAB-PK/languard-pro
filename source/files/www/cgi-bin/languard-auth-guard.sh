#!/bin/sh

LG_CONF="/etc/ispdash/login.conf"
LG_SESS="/tmp/languard-sessions.db"

lg_cookie_value(){
  name="$1"
  echo "$HTTP_COOKIE" | tr ';' '\n' | sed 's/^ *//' | awk -F= -v k="$name" '$1==k{print $2; exit}'
}

lg_valid_session(){
  [ -f "$LG_CONF" ] || return 1
  . "$LG_CONF" 2>/dev/null

  token="$(lg_cookie_value LGSESS)"
  [ -n "$token" ] || return 1
  echo "$token" | grep -Eq '^[a-f0-9]{64}$' || return 1

  now="$(date +%s)"
  [ -f "$LG_SESS" ] || return 1

  awk -F'|' -v tok="$token" -v now="$now" -v ip="${REMOTE_ADDR:-}" '
  $1==tok {
    if(($2+0) > now){
      if($4=="" || ip=="" || $4==ip){
        ok=1
      }
    }
  }
  END{exit ok?0:1}
  ' "$LG_SESS"
}

lg_require_auth(){
  # Allow local CLI/cron/internal shell calls
  [ -z "$REMOTE_ADDR" ] && return 0

  case "$SCRIPT_NAME" in
    */languard-login.sh|*/languard-auth.sh)
      return 0
    ;;
  esac

  if lg_valid_session; then
    return 0
  fi

  echo "Status: 302 Found"
  echo "Location: /cgi-bin/languard-login.sh"
  echo "Cache-Control: no-store"
  echo ""
  return 1
}
