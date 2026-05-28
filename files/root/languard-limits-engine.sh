#!/bin/sh
set +e

DB="/etc/ispdash/devices.db"
LIMITS="/etc/ispdash/limits.db"
USAGE="/etc/ispdash/usage.db"
UDB="/etc/ispdash/device_usage.db"
MON="$(date +%Y%m)"
LANDEV="br-lan"

mkdir -p /etc/ispdash
touch "$DB" "$LIMITS" "$USAGE"

command -v nft >/dev/null 2>&1 || exit 0

valid_ipv4() {
    echo "$1" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}$'
}

mac_to_id() {
    echo "$1" | tr ':' '_'
}

id_to_mac() {
    echo "$1" | tr '_' ':'
}

kbps_to_kbit() {
    # KB/s to kbit/s
    awk -v k="$1" 'BEGIN{ if(k+0>0) printf "%d", k*8; else print 0 }'
}

add_usage_bytes() {
    mac="$1"
    add="$2"

    echo "$add" | grep -Eq '^[0-9]+$' || return 0
    [ "$add" -gt 0 ] 2>/dev/null || return 0

    tmp="/tmp/languard-usage.$$"

    awk -F'|' -v mon="$MON" -v mac="$mac" -v add="$add" '
    BEGIN{done=0}
    {
        if($1==mon && tolower($2)==mac){
            $3=$3+add
            done=1
        }
        if($1!="" && $2!="") print $1 "|" tolower($2) "|" $3
    }
    END{
        if(done==0) print mon "|" mac "|" add
    }' "$USAGE" > "$tmp"

    mv "$tmp" "$USAGE"
}

# old nft counters collect
nft -a list chain inet languard forward 2>/dev/null | awk '
/comment "LGUP_/ || /comment "LGDN_/ {
    id=""
    bytes=0
    for(i=1;i<=NF;i++){
        if($i=="bytes"){bytes=$(i+1)}
        if($i=="comment"){
            id=$(i+1)
            gsub(/"/,"",id)
            sub(/^LGUP_/,"",id)
            sub(/^LGDN_/,"",id)
        }
    }
    if(id!="") print id "|" bytes
}' | while IFS='|' read -r id bytes; do
    mac="$(id_to_mac "$id")"
    add_usage_bytes "$mac" "$bytes"
done

# clear nft
nft delete table inet languard 2>/dev/null || true

# clear tc if available
if command -v tc >/dev/null 2>&1; then
    tc qdisc del dev "$LANDEV" root 2>/dev/null || true
    tc qdisc del dev "$LANDEV" ingress 2>/dev/null || true
    tc qdisc del dev "$LANDEV" clsact 2>/dev/null || true
    tc qdisc add dev "$LANDEV" clsact 2>/dev/null || true
fi

# rebuild nft table
nft add table inet languard 2>/dev/null || true
nft 'add chain inet languard forward { type filter hook forward priority 10; policy accept; }' 2>/dev/null || true

PRIO=10

while IFS='|' read -r mac enabled dl_kbs ul_kbs data_gb; do
    mac="$(echo "$mac" | tr 'A-F' 'a-f')"
    [ -z "$mac" ] && continue
    [ "$enabled" = "1" ] || continue

    ip="$(awk -F'|' -v m="$mac" 'tolower($1)==m {print $2}' "$DB" | tail -1)"
    valid_ipv4 "$ip" || continue

    id="$(mac_to_id "$mac")"

    usage_bytes="$(awk -F'|' -v mon="$MON" -v m="$mac" '$1==mon && tolower($2)==m {print $3}' "$USAGE" | tail -1)"
    [ -z "$usage_bytes" ] && usage_bytes=0

    data_bytes="$(awk -v g="$data_gb" 'BEGIN{ if(g+0>0) printf "%.0f", g*1024*1024*1024; else print 0 }')"

    # usage counters
    nft add rule inet languard forward ip saddr "$ip" counter comment "LGUP_$id" 2>/dev/null || true
    nft add rule inet languard forward ip daddr "$ip" counter comment "LGDN_$id" 2>/dev/null || true

    # data limit block
    if [ "$data_bytes" -gt 0 ] 2>/dev/null && [ "$usage_bytes" -ge "$data_bytes" ] 2>/dev/null; then
        nft add rule inet languard forward ip saddr "$ip" drop comment "LGDATABLOCKUP_$id" 2>/dev/null || true
        nft add rule inet languard forward ip daddr "$ip" drop comment "LGDATABLOCKDN_$id" 2>/dev/null || true
        continue
    fi

    dl_kbs="$(echo "$dl_kbs" | sed 's/[^0-9.]//g')"
    ul_kbs="$(echo "$ul_kbs" | sed 's/[^0-9.]//g')"
    [ -z "$dl_kbs" ] && dl_kbs=0
    [ -z "$ul_kbs" ] && ul_kbs=0

    if command -v tc >/dev/null 2>&1; then
        dl_kbit="$(kbps_to_kbit "$dl_kbs")"
        ul_kbit="$(kbps_to_kbit "$ul_kbs")"

        # Download: router/br-lan egress to client
        if [ "$dl_kbit" -gt 0 ] 2>/dev/null; then
            tc filter add dev "$LANDEV" egress protocol ip prio "$PRIO" u32 \
                match ip dst "$ip"/32 \
                police rate "${dl_kbit}kbit" burst 128k drop flowid :1 2>/dev/null || true
        fi

        # Upload: client ingress into br-lan
        if [ "$ul_kbit" -gt 0 ] 2>/dev/null; then
            tc filter add dev "$LANDEV" ingress protocol ip prio "$PRIO" u32 \
                match ip src "$ip"/32 \
                police rate "${ul_kbit}kbit" burst 128k drop flowid :1 2>/dev/null || true
        fi
    else
        # Fallback: nft KB/s limit. Upload usually works, download may be less reliable.
        if awk -v k="$ul_kbs" 'BEGIN{exit !(k+0>0)}'; then
            nft add rule inet languard forward ip saddr "$ip" limit rate over "$ul_kbs" kbytes/second drop comment "LGSPEEDUP_$id" 2>/dev/null || true
        fi

        if awk -v k="$dl_kbs" 'BEGIN{exit !(k+0>0)}'; then
            nft add rule inet languard forward ip daddr "$ip" limit rate over "$dl_kbs" kbytes/second drop comment "LGSPEEDDN_$id" 2>/dev/null || true
        fi
    fi

    PRIO=$((PRIO+1))

done < "$LIMITS"

exit 0
