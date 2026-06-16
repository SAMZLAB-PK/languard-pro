#!/bin/sh
# LANGUARD_AUTH_GUARD
if [ -x /www/cgi-bin/languard-auth-guard.sh ]; then
  . /www/cgi-bin/languard-auth-guard.sh
  lg_require_auth || exit 0
fi
TRUST="/etc/ispdash/trusted.db"
SEEN="/etc/ispdash/unknown_seen.db"
LOG="/etc/ispdash/audit.log"
POLICY="/etc/ispdash/unknown_policy"

mkdir -p /etc/ispdash
touch "$TRUST" "$SEEN" "$LOG"
[ -f "$POLICY" ] || echo "alert" > "$POLICY"

QS="$QUERY_STRING"
[ -z "$QS" ] && QS="$*"

urldecode(){
  printf '%b' "$(echo "$1" | sed 's/+/ /g;s/%/\\x/g')"
}

getq(){
  echo "$QS" | tr '&' '\n' | awk -F= -v k="$1" '$1==k{print $2; exit}'
}

normmac(){
  echo "$1" | tr 'A-F' 'a-f' | sed 's/[^0-9a-f:]//g'
}

validmac(){
  echo "$1" | grep -Eiq '^[0-9a-f]{2}(:[0-9a-f]{2}){5}$'
}

clean_db(){
  awk -F'|' '
  function ok(m,a){
    m=tolower(m)
    return split(m,a,":")==6 && length(a[1])==2 && length(a[2])==2 && length(a[3])==2 && length(a[4])==2 && length(a[5])==2 && length(a[6])==2
  }
  ok($1) && !seen[tolower($1)]++ {
    name=$2
    ts=$3
    if(ts=="") ts=systime()
    print tolower($1) "|" name "|" ts
  }' "$TRUST" > "$TRUST.tmp" 2>/dev/null && mv "$TRUST.tmp" "$TRUST"
}

ACTION="$(getq action)"
MAC="$(normmac "$(urldecode "$(getq mac)")")"
NAME="$(urldecode "$(getq name)")"
NOW="$(date '+%F %T %Z')"
TSNOW="$(date +%s)"
IP="${REMOTE_ADDR:-local}"

case "$ACTION" in
  list)
    echo "Content-Type: text/plain; charset=utf-8"
    echo "Cache-Control: no-cache"
    echo ""
    clean_db
    cat "$TRUST"
  ;;

  trust)
    echo "Content-Type: text/plain; charset=utf-8"
    echo "Cache-Control: no-cache"
    echo ""

    if ! validmac "$MAC"; then
      echo "ERR|invalid_mac|$MAC"
      exit 0
    fi

    if [ -z "$NAME" ]; then
      NAME="$(/www/cgi-bin/dashboard-live-api.sh 2>/dev/null | awk -F'|' -v m="$MAC" '$1=="DEV" && tolower($2)==m{print $5; exit}')"
    fi
    [ -z "$NAME" ] && NAME="$MAC"

    awk -F'|' -v m="$MAC" 'tolower($1)!=m' "$TRUST" > "$TRUST.tmp" 2>/dev/null
    echo "$MAC|$NAME|$TSNOW" >> "$TRUST.tmp"
    mv "$TRUST.tmp" "$TRUST"
    clean_db

    echo "$NOW|$IP|trusted_device|mac=$MAC|name=$NAME" >> "$LOG"
    echo "OK|trusted|$MAC|$NAME"
  ;;

  untrust)
    echo "Content-Type: text/plain; charset=utf-8"
    echo "Cache-Control: no-cache"
    echo ""

    if ! validmac "$MAC"; then
      echo "ERR|invalid_mac|$MAC"
      exit 0
    fi

    awk -F'|' -v m="$MAC" 'tolower($1)!=m' "$TRUST" > "$TRUST.tmp" 2>/dev/null && mv "$TRUST.tmp" "$TRUST"
    echo "$NOW|$IP|untrusted_device|mac=$MAC" >> "$LOG"
    echo "OK|untrusted|$MAC"
  ;;

  trust_all|init)
    echo "Content-Type: text/plain; charset=utf-8"
    echo "Cache-Control: no-cache"
    echo ""

    TMP="/tmp/languard-trust-all.$$"

    /www/cgi-bin/dashboard-live-api.sh 2>/dev/null | awk -F'|' -v ts="$TSNOW" '
    $1=="DEV"{
      m=tolower($2)
      if(m!="") print m "|" $5 "|" ts
    }' > "$TMP"

    cat "$TRUST" "$TMP" 2>/dev/null | awk -F'|' '
    function ok(m,a){
      m=tolower(m)
      return split(m,a,":")==6 && length(a[1])==2 && length(a[2])==2 && length(a[3])==2 && length(a[4])==2 && length(a[5])==2 && length(a[6])==2
    }
    ok($1) && !seen[tolower($1)]++ {
      print tolower($1) "|" $2 "|" $3
    }' > "$TRUST.tmp"

    mv "$TRUST.tmp" "$TRUST"
    rm -f "$TMP"

    COUNT="$(wc -l < "$TRUST" 2>/dev/null)"
    echo "$NOW|$IP|trusted_baseline_created|count=$COUNT" >> "$LOG"
    echo "OK|trusted_baseline|$COUNT"
  ;;

  unknown)
    echo "Content-Type: text/plain; charset=utf-8"
    echo "Cache-Control: no-cache"
    echo ""

    clean_db

    /www/cgi-bin/dashboard-live-api.sh 2>/dev/null | awk -F'|' -v trust="$TRUST" '
    BEGIN{
      while((getline line < trust)>0){
        split(line,a,"|")
        trusted[tolower(a[1])]=1
      }
      close(trust)
    }
    $1=="DEV"{
      m=tolower($2)
      if(!trusted[m]){
        print "UNKNOWN|" m "|" $3 "|" $4 "|" $5 "|" $8 "|" $16 "|" $17 "|" $18
      }
    }'
  ;;

  policy)
    echo "Content-Type: text/plain; charset=utf-8"
    echo "Cache-Control: no-cache"
    echo ""

    MODE="$(getq mode)"
    case "$MODE" in
      alert|block)
        echo "$MODE" > "$POLICY"
        echo "$NOW|$IP|unknown_policy_changed|mode=$MODE" >> "$LOG"
        echo "OK|policy|$MODE"
      ;;
      *)
        echo "CURRENT|$(cat "$POLICY" 2>/dev/null)"
      ;;
    esac
  ;;

  *)
    echo "Content-Type: text/plain; charset=utf-8"
    echo ""
    echo "LanGuard trust system ready"
  ;;
esac

exit 0
