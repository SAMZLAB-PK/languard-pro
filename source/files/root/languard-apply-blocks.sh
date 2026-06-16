#!/bin/sh
set +e

BLOCKED="/etc/ispdash/blocked.db"

mkdir -p /etc/ispdash
touch "$BLOCKED"

fw_section() {
    echo "lg_block_$(echo "$1" | tr ':' '_')"
}

valid_mac() {
    echo "$1" | grep -Eq '^[0-9a-fA-F]{2}(:[0-9a-fA-F]{2}){5}$'
}

while read -r mac; do
    mac="$(echo "$mac" | tr 'A-F' 'a-f' | tr -d '\r')"
    [ -z "$mac" ] && continue
    valid_mac "$mac" || continue

    sec="$(fw_section "$mac")"

    uci -q delete firewall.$sec
    uci -q set firewall.$sec='rule'
    uci -q set firewall.$sec.name="LanGuard_Block_$mac"
    uci -q set firewall.$sec.src='lan'
    uci -q set firewall.$sec.dest='wan'
    uci -q set firewall.$sec.src_mac="$mac"
    uci -q set firewall.$sec.target='REJECT'
done < "$BLOCKED"

uci -q commit firewall
/etc/init.d/firewall restart >/dev/null 2>&1 || true

exit 0
