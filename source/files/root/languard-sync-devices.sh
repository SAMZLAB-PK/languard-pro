#!/bin/sh
set +e

DB="/etc/ispdash/devices.db"
TMP="/tmp/languard-devices.raw"
ROUTER_MACS="/tmp/languard-router-macs.txt"
TS_CACHE="/tmp/languard-ts-cache.txt"
TS_STAMP="/tmp/languard-ts-cache.stamp"
NOW="$(date +%s)"

mkdir -p /etc/ispdash
: > "$TMP"
: > "$ROUTER_MACS"

# Router/WAN/LAN interface MACs ignore
for f in /sys/class/net/*/address; do
    [ -f "$f" ] || continue
    cat "$f" | tr 'A-F' 'a-f' >> "$ROUTER_MACS"
done
sort -u "$ROUTER_MACS" -o "$ROUTER_MACS"

# DHCP leases: sirf name/IP source. ONLINE proof nahi.
if [ -f /tmp/dhcp.leases ]; then
    awk -v now="$NOW" '
    NF >= 4 {
        mac=tolower($2)
        ip=$3
        name=$4
        expiry=$1
        if (name=="*" || name=="-" || name=="") name=mac

        # DHCP lease active ho to bhi status OFFLINE rakho.
        # Real online status WiFi station / active neighbour se aayega.
        status="OFFLINE"

        print mac "|" ip "|" name "|" status "|" expiry "|LAN|500"
    }' /tmp/dhcp.leases >> "$TMP"
fi

# Active IPv4 LAN neighbour.
# STALE ko online nahi maan rahe, kyun ke old/offline device bhi STALE reh sakti hai.
ip -4 neigh show dev br-lan 2>/dev/null | awk -v now="$NOW" '
{
    ip=$1
    mac=""
    state="UNKNOWN"

    for(i=1;i<=NF;i++){
        if($i=="lladdr"){mac=tolower($(i+1))}
        if($i=="REACHABLE" || $i=="DELAY" || $i=="PROBE" || $i=="PERMANENT" || $i=="STALE" || $i=="FAILED"){
            state=$i
        }
    }

    if(mac!=""){
        status="OFFLINE"
        if(state=="REACHABLE" || state=="DELAY" || state=="PROBE" || state=="PERMANENT"){
            status="ONLINE"
        }
        print mac "|" ip "|" mac "|" status "|" now "|LAN|300"
    }
}' >> "$TMP"

# WiFi associated stations: strongest ONLINE proof
if command -v iw >/dev/null 2>&1; then
    for iface in $(iw dev 2>/dev/null | awk '/Interface/ {print $2}'); do
        iw dev "$iface" station dump 2>/dev/null | awk -v now="$NOW" '
        /Station/ {
            mac=tolower($2)
            if(mac!="") print mac "|No IP|" mac "|ONLINE|" now "|LAN|700"
        }' >> "$TMP"
    done
fi

# Tailscale devices: cache 20 sec, taake dashboard slow na ho
if command -v tailscale >/dev/null 2>&1; then
    AGE=9999
    if [ -f "$TS_STAMP" ]; then
        OLD="$(cat "$TS_STAMP" 2>/dev/null)"
        AGE=$((NOW - OLD))
    fi

    if [ ! -s "$TS_CACHE" ] || [ "$AGE" -gt 20 ]; then
        if command -v timeout >/dev/null 2>&1; then
            timeout 2 tailscale status > "$TS_CACHE.tmp" 2>/dev/null || true
        else
            tailscale status > "$TS_CACHE.tmp" 2>/dev/null || true
        fi

        if [ -s "$TS_CACHE.tmp" ]; then
            mv "$TS_CACHE.tmp" "$TS_CACHE"
            echo "$NOW" > "$TS_STAMP"
        else
            rm -f "$TS_CACHE.tmp"
        fi
    fi

    if [ -s "$TS_CACHE" ]; then
        awk -v now="$NOW" '
        function tsmac(ip, a) {
            split(ip,a,".")
            return sprintf("02:%02x:%02x:%02x:%02x:01", a[1], a[2], a[3], a[4])
        }
        $1 ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ {
            ip=$1
            name=$2
            mac=tsmac(ip)
            status="ONLINE"
            line=tolower($0)

            if(line ~ /offline|stopped|inactive/){
                status="OFFLINE"
            }

            if(name=="" || name=="-") name="Tailscale-" ip
            print mac "|" ip "|TS: " name "|" status "|" now "|TAILSCALE|600"
        }' "$TS_CACHE" >> "$TMP"
    fi
fi

# Merge by MAC
awk -F'|' '
BEGIN {
    while((getline r < "/tmp/languard-router-macs.txt") > 0){
        router[tolower(r)]=1
    }
}
function is_ipv4(x){ return x ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ }
function is_bad_ip(x){ return x=="" || x=="No IP" || x ~ /^fe80:/ }
NF >= 7 {
    m=tolower($1)
    newip=$2
    newname=$3
    newstatus=$4
    newseen=$5
    newtype=$6
    newpri=$7+0

    if(m=="" || m=="00:00:00:00:00:00") next

    # Router apni MACs ko LAN devices se remove karo
    if(newtype=="LAN" && router[m]==1) next

    # IPv6 link-local ghost remove
    if(newtype=="LAN" && newip ~ /^fe80:/) next

    if(!(m in pri)){
        ip[m]=newip
        name[m]=newname
        status[m]=newstatus
        seen[m]=newseen
        type[m]=newtype
        pri[m]=newpri
    } else {
        # Agar kisi source ne ONLINE bola to ONLINE
        if(newstatus=="ONLINE") status[m]="ONLINE"

        if(newseen > seen[m]) seen[m]=newseen

        # IPv4 IP ko prefer karo
        if(is_bad_ip(ip[m]) && !is_bad_ip(newip)){
            ip[m]=newip
        } else if(!is_ipv4(ip[m]) && is_ipv4(newip)){
            ip[m]=newip
        } else if(newpri > pri[m] && !is_bad_ip(newip)){
            ip[m]=newip
        }

        # DHCP/custom real name ko MAC se better samjho
        if(name[m]=="" || name[m]==m || name[m]=="*" || name[m]=="-" || (newname!=m && newname!="*" && newname!="-" && newpri >= pri[m])){
            name[m]=newname
        }

        if(newtype=="TAILSCALE") type[m]="TAILSCALE"
        if(newpri > pri[m]) pri[m]=newpri
    }
}
END {
    for(m in ip){
        if(type[m]=="LAN" && router[m]==1) continue
        if(type[m]=="LAN" && ip[m] ~ /^fe80:/) continue

        if(ip[m]=="") ip[m]="No IP"
        if(name[m]=="") name[m]=m
        if(status[m]=="") status[m]="OFFLINE"
        if(type[m]=="") type[m]="LAN"

        print m "|" ip[m] "|" name[m] "|" status[m] "|" seen[m] "|" type[m]
    }
}' "$TMP" | sort > "$DB"

exit 0
