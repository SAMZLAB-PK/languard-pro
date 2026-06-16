#!/bin/sh
# LANGUARD_AUTH_GUARD
if [ -x /www/cgi-bin/languard-auth-guard.sh ]; then
  . /www/cgi-bin/languard-auth-guard.sh
  lg_require_auth || exit 0
fi
echo "Content-Type: text/html; charset=utf-8"
echo "Cache-Control: no-cache"
echo ""

API_OUT="/tmp/languard-health-api.out"
/www/cgi-bin/dashboard-live-api.sh > "$API_OUT" 2>&1

TOTAL_LINE="$(grep '^TOTAL|' "$API_OUT" | head -n 1)"
META_LINE="$(grep '^META|' "$API_OUT" | head -n 1)"
DEV_COUNT="$(grep -c '^DEV|' "$API_OUT" 2>/dev/null)"

TOTAL="$(echo "$TOTAL_LINE" | awk -F'|' '{print $2}')"
ONLINE="$(echo "$TOTAL_LINE" | awk -F'|' '{print $3}')"
OFFLINE="$(echo "$TOTAL_LINE" | awk -F'|' '{print $4}')"
BLOCKED="$(echo "$TOTAL_LINE" | awk -F'|' '{print $5}')"
TAILSCALE="$(echo "$TOTAL_LINE" | awk -F'|' '{print $6}')"
WANUP="$(echo "$TOTAL_LINE" | awk -F'|' '{print $7}')"
WANIP="$(echo "$TOTAL_LINE" | awk -F'|' '{print $8}')"
DELETED="$(echo "$TOTAL_LINE" | awk -F'|' '{print $9}')"

RTDL="$(echo "$META_LINE" | awk -F'|' '{print $2}')"
RTUL="$(echo "$META_LINE" | awk -F'|' '{print $3}')"
TODAY="$(echo "$META_LINE" | awk -F'|' '{print $4}')"
MONTH="$(echo "$META_LINE" | awk -F'|' '{print $5}')"
ALLTOTAL="$(echo "$META_LINE" | awk -F'|' '{print $6}')"
WANIFACE="$(echo "$META_LINE" | awk -F'|' '{print $7}')"

[ -z "$TOTAL" ] && TOTAL="0"
[ -z "$ONLINE" ] && ONLINE="0"
[ -z "$OFFLINE" ] && OFFLINE="0"
[ -z "$BLOCKED" ] && BLOCKED="0"
[ -z "$TAILSCALE" ] && TAILSCALE="0"
[ -z "$DELETED" ] && DELETED="0"
[ -z "$RTDL" ] && RTDL="0"
[ -z "$RTUL" ] && RTUL="0"
[ -z "$TODAY" ] && TODAY="0.00"
[ -z "$MONTH" ] && MONTH="0.00"
[ -z "$ALLTOTAL" ] && ALLTOTAL="0.00"
[ -z "$WANIFACE" ] && WANIFACE="wan"
[ -z "$WANIP" ] && WANIP="0.0.0.0"

if [ "$WANUP" = "1" ]; then
  WANSTATUS="UP"
  WANCOLOR="ok"
else
  WANSTATUS="DOWN"
  WANCOLOR="bad"
fi

UPTIME_TX="$(awk '{s=int($1); d=int(s/86400); h=int((s%86400)/3600); m=int((s%3600)/60); printf "%sd %sh %sm", d,h,m}' /proc/uptime 2>/dev/null)"

row_file(){
  label="$1"
  file="$2"
  if [ -f "$file" ]; then
    size="$(ls -lh "$file" 2>/dev/null | awk '{print $5}')"
    lines="$(wc -l < "$file" 2>/dev/null)"
    [ -z "$size" ] && size="-"
    [ -z "$lines" ] && lines="0"
    echo "<tr><td>$label</td><td>$file</td><td class='ok'>OK</td><td>$size</td><td>$lines</td></tr>"
  else
    echo "<tr><td>$label</td><td>$file</td><td class='bad'>Missing</td><td>-</td><td>-</td></tr>"
  fi
}

row_exec(){
  label="$1"
  file="$2"
  if [ -x "$file" ]; then
    echo "<tr><td>$label</td><td>$file</td><td class='ok'>Executable</td></tr>"
  elif [ -f "$file" ]; then
    echo "<tr><td>$label</td><td>$file</td><td class='warn'>Not executable</td></tr>"
  else
    echo "<tr><td>$label</td><td>$file</td><td class='bad'>Missing</td></tr>"
  fi
}

latest_backup="$(ls -t /root/languard-backups/lg_manual_*.tar.gz 2>/dev/null | head -n 1)"
if [ -n "$latest_backup" ]; then
  latest_backup_info="$(ls -lh "$latest_backup" | awk '{print $9 " | " $5 " | " $6 " " $7 " " $8}')"
else
  latest_backup_info="No manual backup found"
fi

cat <<HTML
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>LanGuard Health</title>
<style>
body{margin:0;font-family:Arial,Helvetica,sans-serif;background:#f4f6f8;color:#111827}
.top{background:linear-gradient(180deg,#24282d,#171a1f);color:#fff;padding:16px}
h1{margin:0;font-size:24px}.sub{font-size:13px;color:#cbd5e1;margin-top:5px}
.wrap{padding:16px;max-width:1250px;margin:0 auto}
.grid{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:10px;margin-bottom:14px}
.card{background:#fff;border:1px solid #d6dee8;border-radius:8px;box-shadow:0 1px 4px rgba(15,23,42,.1);padding:12px}
.card span{display:block;color:#64748b;text-transform:uppercase;font-size:10px;font-weight:800;letter-spacing:.08em}
.card b{display:block;font-size:22px;margin-top:5px}
.panel{background:#fff;border:1px solid #d6dee8;border-radius:8px;box-shadow:0 1px 4px rgba(15,23,42,.1);margin-bottom:14px;overflow:hidden}
.panel h2{font-size:17px;margin:0;padding:12px;border-bottom:1px solid #e2e8f0;background:#f8fafc}
table{width:100%;border-collapse:collapse}
th,td{padding:9px 10px;border-bottom:1px solid #e2e8f0;text-align:left;font-size:13px}
th{background:#edf2f7;color:#475569;text-transform:uppercase;font-size:10px;letter-spacing:.08em}
.ok{color:#15803d;font-weight:800}.bad{color:#b91c1c;font-weight:800}.warn{color:#b45309;font-weight:800}.blue{color:#2563eb;font-weight:800}.purple{color:#7c3aed;font-weight:800}
pre{background:#0f172a;color:#e5e7eb;padding:12px;margin:0;overflow:auto;font-size:12px;white-space:pre-wrap}
.btn{display:inline-flex;align-items:center;justify-content:center;background:#2563eb;color:white;text-decoration:none;border-radius:5px;padding:9px 12px;font-weight:800;margin:4px 4px 12px 0}
.btn.gray{background:#64748b}
@media(max-width:900px){.grid{grid-template-columns:repeat(2,minmax(0,1fr))}}
@media(max-width:600px){.grid{grid-template-columns:1fr}table{font-size:12px}}
/* HEALTH TOP NAV FIX START */
.top{display:flex !important;align-items:center !important;justify-content:space-between !important;gap:14px !important;flex-wrap:wrap !important;}
.topNav{display:flex !important;align-items:center !important;gap:8px !important;flex-wrap:wrap !important;}
.topNav .btn{margin:0 !important;background:#2563eb !important;color:#fff !important;}
.topNav .btn.gray{background:#64748b !important;}
.wrap > a.btn{display:none !important;}
@media(max-width:800px){.top{align-items:flex-start !important}.topNav{width:100% !important}}
/* HEALTH TOP NAV FIX END */
</style>
</head>
<body>
<div class="top">
  <h1>LanGuard Health</h1>
  <div class="sub">System status · data health · backend checks</div>
</div>

<div class="wrap">
  <a class="btn" href="/cgi-bin/devices.sh">Back to Dashboard</a>
  <a class="btn gray" href="/cgi-bin/languard-maintenance.sh">Tools</a>
  <a class="btn gray" href="/cgi-bin/languard-health.sh?refresh=1">Refresh Health</a>

  <div class="grid">
    <div class="card"><span>Total Devices</span><b>$TOTAL</b></div>
    <div class="card"><span>Online</span><b class="ok">$ONLINE</b></div>
    <div class="card"><span>Offline</span><b class="bad">$OFFLINE</b></div>
    <div class="card"><span>Blocked</span><b class="warn">$BLOCKED</b></div>
    <div class="card"><span>Tailscale</span><b class="blue">$TAILSCALE</b></div>
    <div class="card"><span>Deleted</span><b class="purple">$DELETED</b></div>
    <div class="card"><span>WAN</span><b class="$WANCOLOR">$WANSTATUS</b></div>
    <div class="card"><span>Uptime</span><b style="font-size:17px">$UPTIME_TX</b></div>
  </div>

  <div class="grid">
    <div class="card"><span>Realtime DL</span><b>$RTDL KBps</b></div>
    <div class="card"><span>Realtime UL</span><b>$RTUL KBps</b></div>
    <div class="card"><span>Today Usage</span><b>$TODAY GB</b></div>
    <div class="card"><span>Monthly Usage</span><b>$MONTH GB</b></div>
  </div>

  <div class="panel">
    <h2>WAN / API</h2>
    <table>
      <tr><th>Item</th><th>Value</th></tr>
      <tr><td>WAN Interface</td><td>$WANIFACE</td></tr>
      <tr><td>WAN IP</td><td>$WANIP</td></tr>
      <tr><td>API DEV rows</td><td>$DEV_COUNT</td></tr>
      <tr><td>All Devices Total Usage</td><td>$ALLTOTAL GB</td></tr>
      <tr><td>Current Time</td><td>$(date)</td></tr>
      <tr><td>Latest Backup</td><td>$latest_backup_info</td></tr>
    </table>
  </div>

  <div class="panel">
    <h2>Database Files</h2>
    <table>
      <tr><th>Name</th><th>Path</th><th>Status</th><th>Size</th><th>Lines</th></tr>
HTML

row_file "Devices DB" "/etc/ispdash/devices.db"
row_file "Usage DB" "/etc/ispdash/device_usage.db"
row_file "Old Usage DB" "/etc/ispdash/usage.db"
row_file "Names DB" "/etc/ispdash/names.db"
row_file "Blocked DB" "/etc/ispdash/blocked.db"
row_file "Deleted DB" "/etc/ispdash/deleted.db"
row_file "Limits DB" "/etc/ispdash/limits.db"
row_file "Static IP DB" "/etc/ispdash/staticips.db"
row_file "Audit Log" "/etc/ispdash/audit.log"

cat <<HTML
    </table>
  </div>

  <div class="panel">
    <h2>Script Checks</h2>
    <table>
      <tr><th>Name</th><th>Path</th><th>Status</th></tr>
HTML

row_exec "Dashboard UI" "/www/cgi-bin/devices.sh"
row_exec "Live API" "/www/cgi-bin/dashboard-live-api.sh"
row_exec "Action Script" "/www/cgi-bin/languard-action.sh"
row_exec "Audit Wrapper" "/www/cgi-bin/languard-action-audit.sh"
row_exec "Backup Script" "/www/cgi-bin/languard-backup.sh"
row_exec "Audit Script" "/www/cgi-bin/languard-audit.sh"
row_exec "Sync Devices" "/root/languard-sync-devices.sh"
row_exec "Per Device Usage" "/root/languard-perdevice-usage.sh"
row_exec "Traffic Stats" "/root/languard-traffic-stats.sh"
row_exec "Limits Engine" "/root/languard-limits-engine.sh"

cat <<HTML
    </table>
  </div>

  <div class="panel">
    <h2>Current Device Usage Breakdown</h2>
    <table>
      <tr><th>Status</th><th>Name</th><th>IP</th><th>MAC</th><th>Type</th><th>Day</th><th>Month</th><th>Total</th></tr>
HTML

grep '^DEV|' "$API_OUT" | awk -F'|' '
{
  printf "<tr><td>%s</td><td>%s</td><td>%s</td><td><code>%s</code></td><td>%s</td><td>%s GB</td><td>%s GB</td><td>%s GB</td></tr>\n", $3,$5,$4,$2,$8,$16,$17,$18
}'

cat <<HTML
    </table>
  </div>

  <div class="panel">
    <h2>Cron Jobs</h2>
    <pre>$(cat /etc/crontabs/root 2>/dev/null)</pre>
  </div>

  <div class="panel">
    <h2>Raw API First Lines</h2>
    <pre>$(sed -n '1,40p' "$API_OUT" 2>/dev/null)</pre>
  </div>
</div>
<script>
/* HEALTH TOP NAV FIX START */
(function(){
  function moveHealthButtons(){
    var top=document.querySelector(".top");
    var wrap=document.querySelector(".wrap");
    if(!top||!wrap||document.querySelector(".topNav")) return;
    var nav=document.createElement("div");
    nav.className="topNav";
    var links=Array.prototype.slice.call(wrap.querySelectorAll("a.btn")).slice(0,3);
    links.forEach(function(a){nav.appendChild(a);});
    top.appendChild(nav);
  }
  if(document.readyState==="loading"){document.addEventListener("DOMContentLoaded",moveHealthButtons);}else{moveHealthButtons();}
})();
/* HEALTH TOP NAV FIX END */
</script>
</body>
</html>
HTML

exit 0
