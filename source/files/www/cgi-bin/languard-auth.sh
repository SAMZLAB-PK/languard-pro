#!/bin/sh

LG_SESS="/tmp/languard-sessions.db"
SESSION_TTL="86400"

mkdir -p /etc/ispdash
touch "$LG_SESS" /etc/ispdash/audit.log

urldecode(){
  printf '%b' "$(echo "$1" | sed 's/+/ /g;s/%/\\x/g')"
}

json_escape(){
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

getq(){
  echo "$QUERY_STRING" | tr '&' '\n' | awk -F= -v k="$1" '$1==k{print $2; exit}'
}

cookie_value(){
  name="$1"
  echo "$HTTP_COOKIE" | tr ';' '\n' | sed 's/^ *//' | awk -F= -v k="$name" '$1==k{print $2; exit}'
}

valid_session(){
  token="$(cookie_value LGSESS)"
  [ -n "$token" ] || return 1
  echo "$token" | grep -Eq '^[a-f0-9]{64}$' || return 1

  now="$(date +%s)"

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

cleanup_sessions(){
  now="$(date +%s)"
  awk -F'|' -v now="$now" '($2+0)>now' "$LG_SESS" > "$LG_SESS.tmp" 2>/dev/null
  mv "$LG_SESS.tmp" "$LG_SESS" 2>/dev/null
}

router_login_ok(){
  U="$1"
  P="$2"

  [ -z "$U" ] && U="root"

  UJ="$(json_escape "$U")"
  PJ="$(json_escape "$P")"

  if command -v ubus >/dev/null 2>&1; then
    OUT="$(ubus call session login "{\"username\":\"$UJ\",\"password\":\"$PJ\"}" 2>/dev/null)"
    echo "$OUT" | grep -q "ubus_rpc_session" && return 0
  fi

  return 1
}

ACTION="$(getq action)"

case "$ACTION" in
  login)
    U="$(urldecode "$(getq user)")"
    P="$(urldecode "$(getq pass)")"
    [ -z "$U" ] && U="root"

    if router_login_ok "$U" "$P"; then
      cleanup_sessions

      seed="$(date +%s%N 2>/dev/null)-$$-$REMOTE_ADDR-$(head -c 32 /dev/urandom 2>/dev/null | od -An -tx1 | tr -d ' \n')"
      token="$(printf '%s' "$seed" | sha256sum | awk '{print $1}')"
      exp="$(( $(date +%s) + SESSION_TTL ))"

      echo "$token|$exp|$U|${REMOTE_ADDR:-}" >> "$LG_SESS"

      echo "Set-Cookie: LGSESS=$token; Path=/; Max-Age=$SESSION_TTL; HttpOnly; SameSite=Lax"
      echo "Content-Type: text/plain; charset=utf-8"
      echo "Cache-Control: no-store"
      echo ""
      echo "OK|login"
      echo "$(date '+%F %T %Z')|${REMOTE_ADDR:-local}|login_success_router_password|user=$U" >> /etc/ispdash/audit.log 2>/dev/null
    else
      echo "Content-Type: text/plain; charset=utf-8"
      echo "Cache-Control: no-store"
      echo ""
      echo "ERR|invalid_router_login"
      echo "$(date '+%F %T %Z')|${REMOTE_ADDR:-local}|login_failed_router_password|user=$U" >> /etc/ispdash/audit.log 2>/dev/null
    fi
  ;;

  logout)
    token="$(cookie_value LGSESS)"
    if [ -n "$token" ]; then
      awk -F'|' -v tok="$token" '$1!=tok' "$LG_SESS" > "$LG_SESS.tmp" 2>/dev/null
      mv "$LG_SESS.tmp" "$LG_SESS" 2>/dev/null
    fi

    echo "Set-Cookie: LGSESS=deleted; Path=/; Max-Age=0; HttpOnly; SameSite=Lax"
    echo "Content-Type: text/plain; charset=utf-8"
    echo "Cache-Control: no-store"
    echo ""
    echo "OK|logout"
  ;;

  check)
    echo "Content-Type: text/plain; charset=utf-8"
    echo "Cache-Control: no-store"
    echo ""
    if valid_session; then
      echo "OK|session"
    else
      echo "ERR|no_session"
    fi
  ;;

  *)
    echo "Content-Type: text/plain; charset=utf-8"
    echo ""
    echo "LanGuard auth ready - router password mode"
  ;;
esac

exit 0
