#!/bin/sh
# LANGUARD_AUTH_GUARD
if [ -x /www/cgi-bin/languard-auth-guard.sh ]; then
  . /www/cgi-bin/languard-auth-guard.sh
  lg_require_auth || exit 0
fi
echo "Content-Type: text/html; charset=utf-8"
echo "Cache-Control: no-cache"
echo ""

urldecode(){
  printf '%b' "$(echo "$1" | sed 's/+/ /g;s/%/\\x/g')"
}

getq(){
  echo "$QUERY_STRING" | tr '&' '\n' | awk -F= -v k="$1" '$1==k{print $2; exit}'
}

normmac(){
  echo "$1" | tr 'A-F' 'a-f' | sed 's/[^0-9a-f:]//g'
}

ACTION="$(getq action)"
MAC="$(normmac "$(urldecode "$(getq mac)")")"
SEEN_NOW="$(date '+%F %T')"

if [ "$ACTION" = "enable_dnslog" ]; then
  echo "<pre>"
  uci -q set dhcp.@dnsmasq[0].logqueries='1'
  uci -q commit dhcp
  /etc/init.d/dnsmasq restart >/dev/null 2>&1
  echo "OK|dns_domain_logging_enabled"
  echo "DNS domain log enabled. New domains will appear after device browses."
  echo "</pre>"
  exit 0
fi

API="/tmp/languard-activity-api.$$"
/www/cgi-bin/dashboard-live-api.sh > "$API" 2>/dev/null

DEV_LINE="$(awk -F'|' -v m="$MAC" '$1=="DEV" && tolower($2)==m{print; exit}' "$API")"
IP="$(echo "$DEV_LINE" | awk -F'|' '{print $4}')"
NAME="$(echo "$DEV_LINE" | awk -F'|' '{print $5}')"

[ -z "$NAME" ] && NAME="$MAC"

CT="/proc/net/nf_conntrack"
[ -f "$CT" ] || CT="/proc/net/ip_conntrack"

is_ipv4(){
  echo "$1" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'
}

cat <<HTML
<div class="activityNote">
  <b>Browsing visibility:</b> The full HTTPS URL/path is encrypted. The router uses best-effort detection:
  If a DNS domain is available, the app guess is more accurate; otherwise IP range and port are used for a probable guess.
  <br><b>Checked at:</b> $SEEN_NOW
  <button class="btn green" onclick="enableDnsLog()">Enable DNS Domain Log</button>
  <button class="btn gray" onclick="loadActivity()">Refresh Activity</button>
</div>
HTML

if ! is_ipv4 "$IP"; then
cat <<HTML
<div class="activityWarn">This device has no IPv4 LAN IP right now, so live browsing connections cannot be matched.</div>
HTML
rm -f "$API"
exit 0
fi

DNS_TMP="/tmp/languard-dns-domains.$$"
: > "$DNS_TMP"

if command -v logread >/dev/null 2>&1; then
  logread 2>/dev/null | grep "dnsmasq" | grep "query" | grep " from $IP" | tail -n 200 | awk -v ip="$IP" '
  {
    line=$0
    ts=line
    sub(/ dnsmasq.*$/,"",ts)
    sub(/ daemon\..*$/,"",ts)

    domain=line
    sub(/^.*query\[[^]]*\] /,"",domain)
    sub(" from " ip ".*$","",domain)

    if(domain!="") print tolower(domain) "|" ts "|" line
  }' | sort -u > "$DNS_TMP"
fi

YT_DNS_COUNT="$(awk -F'|' '$1 ~ /youtube|googlevideo|ytimg|ggpht|youtu\.be/{c++} END{print c+0}' "$DNS_TMP" 2>/dev/null)"
[ -z "$YT_DNS_COUNT" ] && YT_DNS_COUNT="0"

app_guess_awk='
function is_google_ip(ip){
  split(ip,a,".")
  p2=a[1] "." a[2]
  p3=a[1] "." a[2] "." a[3]

  if(p2=="142.250") return 1
  if(p2=="142.251") return 1
  if(p2=="142.252") return 1
  if(p2=="172.217") return 1
  if(p2=="172.253") return 1
  if(p2=="216.58") return 1
  if(p2=="64.233") return 1
  if(p2=="74.125") return 1
  if(p2=="108.177") return 1
  if(p2=="173.194") return 1
  if(p2=="209.85") return 1
  if(p2=="216.239") return 1
  if(p3=="35.190.247") return 1
  return 0
}

function is_meta_ip(ip){
  split(ip,a,".")
  p2=a[1] "." a[2]
  if(p2=="31.13") return 1
  if(p2=="157.240") return 1
  if(p2=="129.134") return 1
  return 0
}

function is_cloudflare_ip(ip){
  split(ip,a,".")
  p2=a[1] "." a[2]
  if(p2=="104.16") return 1
  if(p2=="104.17") return 1
  if(p2=="104.18") return 1
  if(p2=="104.19") return 1
  if(p2=="172.64") return 1
  if(p2=="172.65") return 1
  if(p2=="188.114") return 1
  return 0
}

function appname(p,dst,proto){
  if(is_google_ip(dst) && (p==443 || p==80 || p==5228 || p==5223)) return "YouTube / Google Services probable"
  if(is_meta_ip(dst) && (p==443 || p==5222 || p==5223)) return "Facebook / WhatsApp / Instagram probable"
  if(is_cloudflare_ip(dst) && p==443) return "Cloudflare-hosted Website"

  if(p==443) return "Web / HTTPS Apps"
  if(p==80) return "Web / HTTP"
  if(p==53) return "DNS"
  if(p==853) return "DNS-over-TLS"
  if(p==123) return "Time Sync / NTP"
  if(p==5228 || p==5223 || p==5222) return "Push / Messaging"
  if(p==3478 || p==3479 || p==3480) return "Video Call / STUN"
  if(p==1935) return "Streaming"
  if(p==500 || p==4500 || p==1701 || p==1723 || p==1194 || p==51820) return "VPN"
  if(p==25 || p==465 || p==587 || p==993 || p==995 || p==143 || p==110) return "Email"
  if(p==8080 || p==8443) return "Web App / Proxy"
  if(p>=27000 && p<=27100) return "Gaming / Steam"
  if(p>=6881 && p<=6999) return "Torrent / P2P"
  return "Other"
}
'

cat <<HTML
<div class="panelMini">
  <h3>YouTube Detection</h3>
  <table>
    <tr><th>Signal</th><th>Result</th><th>Time</th></tr>
HTML

if [ "$YT_DNS_COUNT" -gt 0 ]; then
  echo "<tr><td>DNS Domains</td><td><b style=\"color:#15803d\">YouTube detected from DNS domains</b></td><td>$SEEN_NOW</td></tr>"
else
  echo "<tr><td>DNS Domains</td><td>No YouTube DNS domain found yet</td><td>$SEEN_NOW</td></tr>"
fi

if [ -f "$CT" ]; then
  GOOGLE_CONN="$(awk -v ip="$IP" "$app_guess_awk"'
  {
    src=""; dst=""; dport=""; proto=$3
    for(i=1;i<=NF;i++){
      if($i ~ /^src=/ && src==""){src=substr($i,5)}
      if($i ~ /^dst=/ && dst==""){dst=substr($i,5)}
      if($i ~ /^dport=/ && dport==""){dport=substr($i,7)}
    }
    if(src==ip && dport!="" && is_google_ip(dst) && (dport==443 || dport==80 || dport==5228 || dport==5223)) c++
  }
  END{print c+0}' "$CT")"
else
  GOOGLE_CONN="0"
fi

if [ "$GOOGLE_CONN" -gt 0 ]; then
  echo "<tr><td>Google CDN Connections</td><td><b style=\"color:#b45309\">$GOOGLE_CONN live Google/YouTube probable connections</b></td><td>$SEEN_NOW</td></tr>"
else
  echo "<tr><td>Google CDN Connections</td><td>No Google/YouTube probable live connection right now</td><td>$SEEN_NOW</td></tr>"
fi

cat <<HTML
  </table>
</div>

<div class="panelMini">
  <h3>App Guess from Live Connections</h3>
  <table>
    <tr><th>App / Traffic Type</th><th>Active Connections</th><th>Last Seen</th></tr>
HTML

if [ -f "$CT" ]; then
  awk -v ip="$IP" -v now="$SEEN_NOW" "$app_guess_awk"'
  {
    src=""; dst=""; dport=""; proto=$3
    for(i=1;i<=NF;i++){
      if($i ~ /^src=/ && src==""){src=substr($i,5)}
      if($i ~ /^dst=/ && dst==""){dst=substr($i,5)}
      if($i ~ /^dport=/ && dport==""){dport=substr($i,7)}
    }
    if(src==ip && dport!=""){
      a=appname(dport+0,dst,proto)
      count[a]++
    }
  }
  END{
    any=0
    for(a in count){
      any=1
      printf "<tr><td><b>%s</b></td><td>%d</td><td>%s</td></tr>\n", a, count[a], now
    }
    if(!any) print "<tr><td colspan=\"3\">No live connections found right now.</td></tr>"
  }' "$CT"
else
  echo '<tr><td colspan="3">conntrack file not available.</td></tr>'
fi

cat <<HTML
  </table>
</div>

<div class="panelMini">
  <h3>Live Connections</h3>
  <table>
    <tr><th>Seen At</th><th>Proto</th><th>Remote IP</th><th>Port</th><th>App Guess</th><th>State</th></tr>
HTML

if [ -f "$CT" ]; then
  awk -v ip="$IP" -v now="$SEEN_NOW" "$app_guess_awk"'
  {
    src=""; dst=""; dport=""; proto=$3; state="-"
    for(i=1;i<=NF;i++){
      if($i ~ /^src=/ && src==""){src=substr($i,5)}
      if($i ~ /^dst=/ && dst==""){dst=substr($i,5)}
      if($i ~ /^dport=/ && dport==""){dport=substr($i,7)}
      if($i=="ESTABLISHED" || $i=="SYN_SENT" || $i=="TIME_WAIT" || $i=="CLOSE_WAIT"){state=$i}
    }
    if(src==ip && dport!=""){
      key=proto "|" dst "|" dport "|" state
      if(!seen[key]++){
        printf "<tr><td>%s</td><td>%s</td><td><code>%s</code></td><td>%s</td><td>%s</td><td>%s</td></tr>\n", now, proto,dst,dport,appname(dport+0,dst,proto),state
        c++
      }
    }
  }
  END{
    if(c==0) print "<tr><td colspan=\"6\">No live connections found right now.</td></tr>"
  }' "$CT" | head -n 100
else
  echo '<tr><td colspan="6">conntrack file not available.</td></tr>'
fi

cat <<HTML
  </table>
</div>

<div class="panelMini">
  <h3>Recent DNS Domains</h3>
  <table>
    <tr><th>Time</th><th>Domain</th><th>App Guess</th></tr>
HTML

if [ -s "$DNS_TMP" ]; then
  awk -F'|' '
  function guess(d){
    if(d ~ /youtube|googlevideo|ytimg|ggpht|youtu\.be/) return "YouTube"
    if(d ~ /google|gstatic|googleapis/) return "Google"
    if(d ~ /facebook|fbcdn|instagram|whatsapp/) return "Meta Apps"
    if(d ~ /tiktok|byteoversea|musical\.ly/) return "TikTok"
    if(d ~ /netflix|nflxvideo/) return "Netflix"
    if(d ~ /spotify/) return "Spotify"
    if(d ~ /cloudflare/) return "Cloudflare"
    return "Domain"
  }
  {
    printf "<tr><td>%s</td><td><b>%s</b></td><td>%s</td></tr>\n", $2, $1, guess($1)
  }' "$DNS_TMP" | tail -n 100
else
  echo '<tr><td colspan="3">No DNS domains yet. Click Enable DNS Domain Log, then browse from this device and refresh.</td></tr>'
fi

cat <<HTML
  </table>
</div>
HTML

rm -f "$API" "$DNS_TMP"
exit 0
