#!/bin/sh
set +e

DB="/etc/ispdash/devices.db"
DELETED="/etc/ispdash/deleted.db"
UDB="/etc/ispdash/device_usage.db"
SPEEDDB="/tmp/languard-device-speed.db"
LOCK="/tmp/languard-device-usage.last"

DAY="$(date +%Y%m%d)"
MON="$(date +%Y%m)"
NOW="$(date +%s)"

mkdir -p /etc/ispdash
touch "$DB" "$DELETED" "$UDB"

command -v nft >/dev/null 2>&1 || exit 0

LAST=0
[ -f "$LOCK" ] && LAST="$(cat "$LOCK" 2>/dev/null)"
[ -z "$LAST" ] && LAST=0

AGE=$((NOW - LAST))
[ "$AGE" -le 0 ] && AGE=1

# Too frequent calls skip, but old speed stays available
if [ "$AGE" -lt 2 ] 2>/dev/null; then
    exit 0
fi

id_to_mac() {
    echo "$1" | tr '_' ':'
}

mac_to_id() {
    echo "$1" | tr ':' '_'
}

valid_ipv4() {
    echo "$1" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}$'
}

add_bytes() {
    mac="$1"
    add="$2"

    echo "$add" | grep -Eq '^[0-9]+$' || return 0
    [ "$add" -gt 0 ] 2>/dev/null || return 0

    tmp="/tmp/languard-device-usage.$$"

    awk -F'|' -v day="$DAY" -v mon="$MON" -v mac="$mac" -v add="$add" '
    BEGIN{done=0}
    {
        d=$1
        m=$2
        dev=tolower($3)
        daily=$4+0
        monthly=$5+0
        total=$6+0

        if(dev==mac){
            if(d!=day){ d=day; daily=0 }
            if(m!=mon){ m=mon; monthly=0 }

            daily+=add
            monthly+=add
            total+=add
            done=1
        }

        if(dev!="") print d "|" m "|" dev "|" daily "|" monthly "|" total
    }
    END{
        if(done==0){
            print day "|" mon "|" mac "|" add "|" add "|" add
        }
    }' "$UDB" > "$tmp"

    mv "$tmp" "$UDB"
}

# Collect old counters, calculate device speed, then rebuild table
TMPBYTES="/tmp/languard-device-counter-bytes.$$"
TMPSPEED="/tmp/languard-device-speed.$$"

nft -a list chain inet languard_usage forward 2>/dev/null | awk '
/comment "LGU_/ || /comment "LGD_/ {
    id=""
    bytes=0
    dir=""

    for(i=1;i<=NF;i++){
        if($i=="bytes"){bytes=$(i+1)}
        if($i=="comment"){
            id=$(i+1)
            gsub(/"/,"",id)
            if(id ~ /^LGU_/){
                sub(/^LGU_/,"",id)
                dir="UP"
            } else if(id ~ /^LGD_/){
                sub(/^LGD_/,"",id)
                dir="DN"
            }
        }
    }

    if(id!="" && dir!=""){
        seen[id]=1
        if(dir=="UP") up[id]+=bytes
        if(dir=="DN") dn[id]+=bytes
    }
}
END{
    for(id in seen){
        mac=id
        gsub(/_/,":",mac)
        print mac "|" (dn[id]+0) "|" (up[id]+0)
    }
}' > "$TMPBYTES"

: > "$TMPSPEED"

while IFS='|' read -r mac dn_bytes up_bytes; do
    mac="$(echo "$mac" | tr 'A-F' 'a-f')"
    [ -z "$mac" ] && continue

    [ -z "$dn_bytes" ] && dn_bytes=0
    [ -z "$up_bytes" ] && up_bytes=0

    total_add=$((dn_bytes + up_bytes))
    add_bytes "$mac" "$total_add"

    dl_kbs=$((dn_bytes / AGE / 1024))
    ul_kbs=$((up_bytes / AGE / 1024))

    echo "$mac|$dl_kbs|$ul_kbs" >> "$TMPSPEED"
done < "$TMPBYTES"

mv "$TMPSPEED" "$SPEEDDB"
rm -f "$TMPBYTES"

echo "$NOW" > "$LOCK"

# Rebuild usage nft table
nft delete table inet languard_usage 2>/dev/null || true
nft add table inet languard_usage 2>/dev/null || true
nft 'add chain inet languard_usage forward { type filter hook forward priority 30; policy accept; }' 2>/dev/null || true

while IFS='|' read -r mac ip name status seen dtype; do
    mac="$(echo "$mac" | tr 'A-F' 'a-f')"
    [ -z "$mac" ] && continue

    grep -qi "^$mac$" "$DELETED" 2>/dev/null && continue
    valid_ipv4 "$ip" || continue

    id="$(mac_to_id "$mac")"

    # UP = client/source upload
    nft add rule inet languard_usage forward ip saddr "$ip" counter comment "LGU_$id" 2>/dev/null || true

    # DN = client/destination download
    nft add rule inet languard_usage forward ip daddr "$ip" counter comment "LGD_$id" 2>/dev/null || true

done < "$DB"

exit 0
