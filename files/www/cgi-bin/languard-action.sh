#!/bin/sh
set +e

echo "Content-Type: text/plain; charset=utf-8"
echo "Cache-Control: no-cache"
echo ""

urldecode() {
    echo -e "$(echo "$1" | sed 's/+/ /g;s/%/\\x/g')"
}

get_qs() {
    key="$1"
    echo "$QUERY_STRING" | tr '&' '\n' | sed -n "s/^$key=//p" | tail -1
}

ACTION_NAME="$(urldecode "$(get_qs action)")"
MAC="$(urldecode "$(get_qs mac)" | tr 'A-F' 'a-f')"
NAME="$(urldecode "$(get_qs name)")"
IPADDR="$(urldecode "$(get_qs ip)")"
ENABLED="$(urldecode "$(get_qs enabled)")"
DL="$(urldecode "$(get_qs dl)")"
UL="$(urldecode "$(get_qs ul)")"
DATA="$(urldecode "$(get_qs data)")"

BLOCKED="/etc/ispdash/blocked.db"
NAMES="/etc/ispdash/names.db"
DELETED="/etc/ispdash/deleted.db"
STATICIPS="/etc/ispdash/staticips.db"
LIMITS="/etc/ispdash/limits.db"
USAGE="/etc/ispdash/usage.db"
DB="/etc/ispdash/devices.db"

mkdir -p /etc/ispdash
touch "$BLOCKED" "$NAMES" "$DELETED" "$STATICIPS" "$LIMITS" "$USAGE" "$DB"

valid_mac() {
    echo "$1" | grep -Eq '^[0-9a-f]{2}(:[0-9a-f]{2}){5}$'
}

valid_ipv4() {
    echo "$1" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}$' || return 1
    OLDIFS="$IFS"; IFS='.'; set -- $1; IFS="$OLDIFS"
    [ "$1" -le 255 ] && [ "$2" -le 255 ] && [ "$3" -le 255 ] && [ "$4" -le 254 ] && [ "$4" -ge 2 ]
}

is_tailscale_device() {
    grep -qi "^$1|.*|TAILSCALE$" "$DB" 2>/dev/null
}

clean_num() {
    echo "$1" | sed 's/[^0-9.]//g;s/^\./0./;s/\.\././g'
}

fw_section() {
    echo "lg_block_$(echo "$1" | tr ':' '_')"
}

safe_hostname() {
    h="$(echo "$1" | sed 's/[^A-Za-z0-9_-]/_/g;s/^_*//;s/_*$//' | cut -c1-32)"
    [ -z "$h" ] && h="device_$(echo "$MAC" | tr ':' '_' | cut -c1-20)"
    echo "$h"
}

save_name() {
    mac="$1"
    name="$2"

    grep -vi "^$mac|" "$NAMES" > "$NAMES.tmp" 2>/dev/null
    mv "$NAMES.tmp" "$NAMES"

    [ -n "$name" ] && echo "$mac|$name" >> "$NAMES"
}

save_static_ip() {
    mac="$1"
    ip="$2"
    name="$3"

    [ -z "$ip" ] && return 0
    [ "$ip" = "No IP" ] && return 0

    valid_ipv4 "$ip" || {
        echo "ERR|invalid ip. Example: 192.168.10.50"
        exit 0
    }

    LANIP="$(uci -q get network.lan.ipaddr)"
    PREFIX="${LANIP%.*}"

    case "$ip" in
        "$PREFIX".*) ;;
        *)
            echo "ERR|IP must be in LAN range: $PREFIX.2 - $PREFIX.254"
            exit 0
        ;;
    esac

    grep -vi "^$mac|" "$STATICIPS" > "$STATICIPS.tmp" 2>/dev/null
    mv "$STATICIPS.tmp" "$STATICIPS"
    echo "$mac|$ip" >> "$STATICIPS"

    sec="lg_host_$(echo "$mac" | tr ':' '_')"

    for old in $(uci show dhcp 2>/dev/null | awk -v mac="$mac" -F= '
        /\.mac=/ {
            left=$1
            val=tolower($2)
            gsub(/\047|"/,"",val)
            if(val==mac){
                sub(/^dhcp\./,"",left)
                sub(/\.mac$/,"",left)
                print left
            }
        }'
    ); do
        uci -q delete "dhcp.$old"
    done

    host="$(safe_hostname "$name")"

    uci -q set dhcp.$sec='host'
    uci -q set dhcp.$sec.name="$host"
    uci -q set dhcp.$sec.mac="$mac"
    uci -q set dhcp.$sec.ip="$ip"
    uci -q commit dhcp

    /etc/init.d/dnsmasq restart >/dev/null 2>&1 || true
}

apply_firewall_block() {
    mac="$1"
    sec="$(fw_section "$mac")"

    uci -q delete firewall.$sec
    uci -q set firewall.$sec='rule'
    uci -q set firewall.$sec.name="LanGuard_Block_$mac"
    uci -q set firewall.$sec.src='lan'
    uci -q set firewall.$sec.dest='wan'
    uci -q set firewall.$sec.src_mac="$mac"
    uci -q set firewall.$sec.target='REJECT'
    uci -q commit firewall
    /etc/init.d/firewall restart >/dev/null 2>&1 || true
}

remove_firewall_block() {
    mac="$1"
    sec="$(fw_section "$mac")"

    uci -q delete firewall.$sec
    uci -q commit firewall
    /etc/init.d/firewall restart >/dev/null 2>&1 || true
}

apply_limits_now() {
    [ -x /root/languard-limits-engine.sh ] && /root/languard-limits-engine.sh >/dev/null 2>&1 || true
}

case "$ACTION_NAME" in
    save)
        valid_mac "$MAC" || { echo "ERR|invalid mac"; exit 0; }

        save_name "$MAC" "$NAME"

        if is_tailscale_device "$MAC"; then
            echo "OK|saved name only|$MAC|$NAME"
            exit 0
        fi

        save_static_ip "$MAC" "$IPADDR" "$NAME"
        echo "OK|saved|$MAC|$NAME|$IPADDR"
    ;;

    limit_save)
        valid_mac "$MAC" || { echo "ERR|invalid mac"; exit 0; }

        ENABLED="$(echo "$ENABLED" | grep -q '^1$' && echo 1 || echo 0)"
        DL="$(clean_num "$DL")"
        UL="$(clean_num "$UL")"
        DATA="$(clean_num "$DATA")"

        [ -z "$DL" ] && DL="0"
        [ -z "$UL" ] && UL="0"
        [ -z "$DATA" ] && DATA="0"

        ip="$(awk -F'|' -v m="$MAC" 'tolower($1)==m {print $2}' "$DB" | tail -1)"
        echo "$ip" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}$' || {
            echo "ERR|device has no IPv4 address for limits"
            exit 0
        }

        grep -vi "^$MAC|" "$LIMITS" > "$LIMITS.tmp" 2>/dev/null
        mv "$LIMITS.tmp" "$LIMITS"
        echo "$MAC|$ENABLED|$DL|$UL|$DATA" >> "$LIMITS"
        sort -u "$LIMITS" -o "$LIMITS"

        apply_limits_now
        echo "OK|limit_saved|$MAC|$ENABLED|$DL|$UL|$DATA"
    ;;

    limit_clear)
        valid_mac "$MAC" || { echo "ERR|invalid mac"; exit 0; }

        grep -vi "^$MAC|" "$LIMITS" > "$LIMITS.tmp" 2>/dev/null
        mv "$LIMITS.tmp" "$LIMITS"

        apply_limits_now
        echo "OK|limit_cleared|$MAC"
    ;;

    usage_reset)
        valid_mac "$MAC" || { echo "ERR|invalid mac"; exit 0; }

        MON="$(date +%Y%m)"
        awk -F'|' -v mon="$MON" -v mac="$MAC" '
        !($1==mon && tolower($2)==mac){print}
        ' "$USAGE" > "$USAGE.tmp"
        mv "$USAGE.tmp" "$USAGE"

        apply_limits_now
        echo "OK|usage_reset|$MAC"
    ;;

    block)
        valid_mac "$MAC" || { echo "ERR|invalid mac"; exit 0; }

        if is_tailscale_device "$MAC"; then
            echo "ERR|tailscale devices cannot be blocked by LAN MAC rule"
            exit 0
        fi

        grep -qi "^$MAC$" "$BLOCKED" || echo "$MAC" >> "$BLOCKED"
        sort -u "$BLOCKED" -o "$BLOCKED"
        apply_firewall_block "$MAC"
        echo "OK|blocked|$MAC"
    ;;

    unblock)
        valid_mac "$MAC" || { echo "ERR|invalid mac"; exit 0; }

        grep -vi "^$MAC$" "$BLOCKED" > "$BLOCKED.tmp" 2>/dev/null
        mv "$BLOCKED.tmp" "$BLOCKED"

        remove_firewall_block "$MAC"
        echo "OK|unblocked|$MAC"
    ;;

    delete|hide)
        valid_mac "$MAC" || { echo "ERR|invalid mac"; exit 0; }

        grep -qi "^$MAC$" "$DELETED" || echo "$MAC" >> "$DELETED"
        sort -u "$DELETED" -o "$DELETED"
        echo "OK|deleted|$MAC"
    ;;

    restore|unhide)
        valid_mac "$MAC" || { echo "ERR|invalid mac"; exit 0; }

        grep -vi "^$MAC$" "$DELETED" > "$DELETED.tmp" 2>/dev/null
        mv "$DELETED.tmp" "$DELETED"
        echo "OK|restored|$MAC"
    ;;

    *)
        echo "ERR|unknown action"
    ;;
esac

exit 0
