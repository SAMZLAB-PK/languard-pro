#!/bin/sh
# LANGUARD_AUTH_GUARD
if [ -x /www/cgi-bin/languard-auth-guard.sh ]; then
  . /www/cgi-bin/languard-auth-guard.sh
  lg_require_auth || exit 0
fi
echo "Content-Type: text/html; charset=utf-8"
echo "Cache-Control: no-cache"
echo ""

DB="/etc/ispdash/device_usage.db"
TRUST="/etc/ispdash/trusted.db"
SCHED="/etc/ispdash/schedules.db"
AUDIT="/etc/ispdash/audit.log"
LIMITS="/etc/ispdash/limits.db"

mkdir -p /etc/ispdash
touch "$DB" "$TRUST" "$SCHED" "$AUDIT" "$LIMITS"

urldecode(){
  printf '%b' "$(echo "$1" | sed 's/+/ /g;s/%/\\x/g')"
}

getq(){
  echo "$QUERY_STRING" | tr '&' '\n' | awk -F= -v k="$1" '$1==k{print $2; exit}'
}

MAC="$(urldecode "$(getq mac)" | tr 'A-F' 'a-f' | sed 's/[^0-9a-f:]//g')"

if ! echo "$MAC" | grep -Eiq '^[0-9a-f]{2}(:[0-9a-f]{2}){5}$'; then
cat <<HTML
<!doctype html><html><head><title>LanGuard Device</title></head>
<body style="font-family:Arial;padding:20px">
<h2>Invalid device MAC</h2>
<a href="/cgi-bin/devices.sh">Back to Dashboard</a>
<script>
/* DEVICE ACTIVITY START */
(function(){
  const mac = new URLSearchParams(location.search).get("mac") || "";

  function ensureActivityPanel(){
    if(document.getElementById("activityPanel")) return;
    const wrap = document.querySelector(".wrap");
    if(!wrap) return;

    const panel = document.createElement("div");
    panel.id = "activityPanel";
    panel.className = "panel";
    panel.innerHTML = "<h2>Browsing / Apps Activity</h2><div id=\"activityBody\" style=\"padding:12px\">Loading activity...</div>";

    const usagePanel = Array.from(document.querySelectorAll(".panel h2")).find(h => h.textContent.trim() === "Usage Records");
    if(usagePanel && usagePanel.closest(".panel")){
      wrap.insertBefore(panel, usagePanel.closest(".panel"));
    }else{
      wrap.appendChild(panel);
    }
  }

  window.loadActivity = async function(){
    ensureActivityPanel();
    const box = document.getElementById("activityBody");
    if(!box) return;
    box.innerHTML = "Loading activity...";
    try{
      const r = await fetch("/cgi-bin/languard-activity.sh?action=html&mac=" + encodeURIComponent(mac) + "&_=" + Date.now(), {cache:"no-store"});
      box.innerHTML = await r.text();
    }catch(e){
      box.innerHTML = "<div class=\"activityWarn\">Activity load failed: " + e.message + "</div>";
    }
  };

  window.enableDnsLog = async function(){
    ensureActivityPanel();
    const box = document.getElementById("activityBody");
    try{
      const r = await fetch("/cgi-bin/languard-activity.sh?action=enable_dnslog&mac=" + encodeURIComponent(mac) + "&_=" + Date.now(), {cache:"no-store"});
      alert((await r.text()).replace(/<[^>]*>/g,""));
      setTimeout(loadActivity, 1000);
    }catch(e){
      alert("DNS log enable failed: " + e.message);
    }
  };

  ensureActivityPanel();
  loadActivity();
})();
/* DEVICE ACTIVITY END */
</script>
</body></html>
HTML
exit 0
fi

API="/tmp/languard-device-details-api.$$"
/www/cgi-bin/dashboard-live-api.sh > "$API" 2>/dev/null

DEV_LINE="$(awk -F'|' -v m="$MAC" '$1=="DEV" && tolower($2)==m{print; exit}' "$API")"

STATUS="$(echo "$DEV_LINE" | awk -F'|' '{print $3}')"
IP="$(echo "$DEV_LINE" | awk -F'|' '{print $4}')"
NAME="$(echo "$DEV_LINE" | awk -F'|' '{print $5}')"
TYPE="$(echo "$DEV_LINE" | awk -F'|' '{print $8}')"
LIMIT_STATE="$(echo "$DEV_LINE" | awk -F'|' '{print $15}')"
DAY_GB="$(echo "$DEV_LINE" | awk -F'|' '{print $16}')"
MONTH_GB="$(echo "$DEV_LINE" | awk -F'|' '{print $17}')"
TOTAL_GB="$(echo "$DEV_LINE" | awk -F'|' '{print $18}')"
DL="$(echo "$DEV_LINE" | awk -F'|' '{print $19}')"
UL="$(echo "$DEV_LINE" | awk -F'|' '{print $20}')"

[ -z "$NAME" ] && NAME="$MAC"
[ -z "$STATUS" ] && STATUS="UNKNOWN"
[ -z "$IP" ] && IP="No IP"
[ -z "$TYPE" ] && TYPE="LAN"
[ -z "$LIMIT_STATE" ] && LIMIT_STATE="OFF"
[ -z "$DAY_GB" ] && DAY_GB="0.00"
[ -z "$MONTH_GB" ] && MONTH_GB="0.00"
[ -z "$TOTAL_GB" ] && TOTAL_GB="0.00"
[ -z "$DL" ] && DL="0"
[ -z "$UL" ] && UL="0"

TRUSTED="UNKNOWN"
grep -qi "^$MAC|" "$TRUST" 2>/dev/null && TRUSTED="TRUSTED"

SCHED_LINE="$(awk -F'|' -v m="$MAC" 'tolower($1)==m{print; exit}' "$SCHED")"
SCH_ENABLED="$(echo "$SCHED_LINE" | awk -F'|' '{print $2}')"
SCH_START="$(echo "$SCHED_LINE" | awk -F'|' '{print $3}')"
SCH_END="$(echo "$SCHED_LINE" | awk -F'|' '{print $4}')"

[ "$SCH_ENABLED" = "1" ] || SCH_ENABLED="0"
[ -z "$SCH_START" ] && SCH_START="-"
[ -z "$SCH_END" ] && SCH_END="-"

LIMIT_LINE="$(awk -F'|' -v m="$MAC" 'tolower($1)==m{print; exit}' "$LIMITS")"
LIM_ENABLED="$(echo "$LIMIT_LINE" | awk -F'|' '{print $2}')"
LIM_DL="$(echo "$LIMIT_LINE" | awk -F'|' '{print $3}')"
LIM_UL="$(echo "$LIMIT_LINE" | awk -F'|' '{print $4}')"
LIM_DATA="$(echo "$LIMIT_LINE" | awk -F'|' '{print $5}')"

[ "$LIM_ENABLED" = "1" ] || LIM_ENABLED="0"
[ -z "$LIM_DL" ] && LIM_DL="0"
[ -z "$LIM_UL" ] && LIM_UL="0"
[ -z "$LIM_DATA" ] && LIM_DATA="0"

cat <<HTML
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>LanGuard Device Details</title>
<style>
body{margin:0;font-family:Arial,Helvetica,sans-serif;background:#f4f6f8;color:#111827}
.top{background:linear-gradient(180deg,#24282d,#171a1f);color:#fff;padding:16px;display:flex;align-items:center;justify-content:space-between;gap:14px;flex-wrap:wrap}
h1{margin:0;font-size:24px}.sub{font-size:13px;color:#cbd5e1;margin-top:5px}
.nav{display:flex;gap:8px;flex-wrap:wrap}
.btn{display:inline-flex;align-items:center;justify-content:center;background:#2563eb;color:#fff;text-decoration:none;border:0;border-radius:5px;padding:9px 12px;font-weight:800;cursor:pointer}
.btn.gray{background:#64748b}.btn.green{background:#16a34a}.btn.red{background:#dc2626}
.wrap{padding:16px;max-width:1250px;margin:0 auto}
.grid{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:10px;margin-bottom:14px}
.card{background:#fff;border:1px solid #d6dee8;border-radius:8px;box-shadow:0 1px 4px rgba(15,23,42,.1);padding:13px}
.card span{display:block;color:#64748b;text-transform:uppercase;font-size:10px;font-weight:800;letter-spacing:.08em}
.card b{display:block;font-size:22px;margin-top:5px}
.panel{background:#fff;border:1px solid #d6dee8;border-radius:8px;box-shadow:0 1px 4px rgba(15,23,42,.1);margin-bottom:14px;overflow:hidden}
.panel h2{margin:0;padding:12px;border-bottom:1px solid #e2e8f0;background:#f8fafc;font-size:17px}
table{width:100%;border-collapse:collapse}
th,td{padding:9px 10px;border-bottom:1px solid #e2e8f0;text-align:left;font-size:13px;vertical-align:middle}
th{background:#edf2f7;color:#475569;text-transform:uppercase;font-size:10px;letter-spacing:.08em}
.ok{color:#15803d;font-weight:900}.bad{color:#b91c1c;font-weight:900}.warn{color:#b45309;font-weight:900}.blue{color:#2563eb;font-weight:900}.purple{color:#7c3aed;font-weight:900}
.badge{display:inline-flex;align-items:center;justify-content:center;min-width:86px;border-radius:4px;padding:5px 8px;font-size:11px;font-weight:900}
.online{background:#dcfce7;color:#15803d}.offline{background:#fee2e2;color:#b91c1c}.blocked{background:#fef3c7;color:#92400e}.trusted{background:#dcfce7;color:#15803d}.unknown{background:#fed7aa;color:#9a3412}
pre{background:#0f172a;color:#e5e7eb;margin:0;padding:12px;overflow:auto;white-space:pre-wrap;font-size:12px;min-height:140px}
code{font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;font-size:12px}
@media(max-width:900px){.grid{grid-template-columns:repeat(2,minmax(0,1fr))}.panel{overflow:auto}table{min-width:760px}}
@media(max-width:600px){.grid{grid-template-columns:1fr}.top{align-items:flex-start}}
/* DEVICE ACTIVITY START */
.activityNote{background:#fff;border:1px solid #d6dee8;border-radius:8px;box-shadow:0 1px 4px rgba(15,23,42,.1);padding:12px;margin-bottom:14px;color:#334155;font-size:13px;line-height:1.45}
.activityWarn{background:#fef3c7;color:#92400e;border:1px solid #fde68a;border-radius:8px;padding:12px;margin-bottom:14px;font-weight:800}
.panelMini{background:#fff;border:1px solid #d6dee8;border-radius:8px;box-shadow:0 1px 4px rgba(15,23,42,.1);margin-bottom:14px;overflow:hidden}
.panelMini h3{margin:0;padding:11px 12px;background:#f8fafc;border-bottom:1px solid #e2e8f0;font-size:16px}
#activityPanel .btn{margin-left:6px;margin-top:4px}
#activityPanel table{width:100%;border-collapse:collapse}
#activityPanel th,#activityPanel td{padding:8px 10px;border-bottom:1px solid #e2e8f0;text-align:left;font-size:13px;vertical-align:middle}
#activityPanel th{background:#edf2f7;color:#475569;text-transform:uppercase;font-size:10px;letter-spacing:.08em}
#activityPanel code{font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;font-size:12px}
@media(max-width:700px){#activityPanel{overflow:auto}#activityPanel table{min-width:720px}}
/* DEVICE ACTIVITY END */
</style>
</head>
<body>
<div class="top">
  <div>
    <h1>$NAME</h1>
    <div class="sub">$IP · $MAC · $TYPE</div>
  </div>
  <div class="nav">
    <a class="btn" href="/cgi-bin/devices.sh">Dashboard</a>
    <a class="btn gray" href="/cgi-bin/languard-health.sh">Health</a>
    <a class="btn gray" href="/cgi-bin/languard-reports.sh">Reports</a>
  </div>
</div>

<div class="wrap">
  <div class="grid">
    <div class="card"><span>Status</span><b>$STATUS</b></div>
    <div class="card"><span>Trust</span><b>$TRUSTED</b></div>
    <div class="card"><span>Today</span><b>$DAY_GB GB</b></div>
    <div class="card"><span>Month</span><b>$MONTH_GB GB</b></div>
    <div class="card"><span>Total</span><b>$TOTAL_GB GB</b></div>
    <div class="card"><span>Realtime DL</span><b>$DL KBps</b></div>
    <div class="card"><span>Realtime UL</span><b>$UL KBps</b></div>
    <div class="card"><span>Limit State</span><b>$LIMIT_STATE</b></div>
  </div>

  <div class="panel">
    <h2>Device Control Status</h2>
    <table>
      <tr><th>Item</th><th>Value</th></tr>
      <tr><td>Name</td><td><b>$NAME</b></td></tr>
      <tr><td>IP</td><td>$IP</td></tr>
      <tr><td>MAC</td><td><code>$MAC</code></td></tr>
      <tr><td>Type</td><td>$TYPE</td></tr>
      <tr><td>Trust Status</td><td>$TRUSTED</td></tr>
      <tr><td>Speed Limit Enabled</td><td>$LIM_ENABLED</td></tr>
      <tr><td>Download Limit</td><td>$LIM_DL KBps</td></tr>
      <tr><td>Upload Limit</td><td>$LIM_UL KBps</td></tr>
      <tr><td>Data Limit</td><td>$LIM_DATA GB</td></tr>
      <tr><td>Schedule Enabled</td><td>$SCH_ENABLED</td></tr>
      <tr><td>Schedule Time</td><td>$SCH_START to $SCH_END</td></tr>
    </table>
  </div>

  <div class="panel">
    <h2>Usage Records</h2>
    <table>
      <tr><th>Day</th><th>Month</th><th>Daily GB</th><th>Monthly GB</th><th>Total GB</th></tr>
HTML

awk -F'|' -v m="$MAC" '
tolower($3)==m{
  d=$4/1024/1024/1024
  mo=$5/1024/1024/1024
  t=$6/1024/1024/1024
  printf "<tr><td>%s</td><td>%s</td><td>%.2f GB</td><td>%.2f GB</td><td>%.2f GB</td></tr>\n",$1,$2,d,mo,t
}' "$DB" | tail -n 60

cat <<HTML
    </table>
  </div>

  <div class="panel">
    <h2>Related Audit Log</h2>
    <pre>$(grep -i "$MAC" "$AUDIT" 2>/dev/null | tail -n 80)</pre>
  </div>
</div>
<script>
/* DEVICE ACTIVITY START */
(function(){
  const mac = new URLSearchParams(location.search).get("mac") || "";

  function ensureActivityPanel(){
    if(document.getElementById("activityPanel")) return;
    const wrap = document.querySelector(".wrap");
    if(!wrap) return;

    const panel = document.createElement("div");
    panel.id = "activityPanel";
    panel.className = "panel";
    panel.innerHTML = "<h2>Browsing / Apps Activity</h2><div id=\"activityBody\" style=\"padding:12px\">Loading activity...</div>";

    const usagePanel = Array.from(document.querySelectorAll(".panel h2")).find(h => h.textContent.trim() === "Usage Records");
    if(usagePanel && usagePanel.closest(".panel")){
      wrap.insertBefore(panel, usagePanel.closest(".panel"));
    }else{
      wrap.appendChild(panel);
    }
  }

  window.loadActivity = async function(){
    ensureActivityPanel();
    const box = document.getElementById("activityBody");
    if(!box) return;
    box.innerHTML = "Loading activity...";
    try{
      const r = await fetch("/cgi-bin/languard-activity.sh?action=html&mac=" + encodeURIComponent(mac) + "&_=" + Date.now(), {cache:"no-store"});
      box.innerHTML = await r.text();
    }catch(e){
      box.innerHTML = "<div class=\"activityWarn\">Activity load failed: " + e.message + "</div>";
    }
  };

  window.enableDnsLog = async function(){
    ensureActivityPanel();
    const box = document.getElementById("activityBody");
    try{
      const r = await fetch("/cgi-bin/languard-activity.sh?action=enable_dnslog&mac=" + encodeURIComponent(mac) + "&_=" + Date.now(), {cache:"no-store"});
      alert((await r.text()).replace(/<[^>]*>/g,""));
      setTimeout(loadActivity, 1000);
    }catch(e){
      alert("DNS log enable failed: " + e.message);
    }
  };

  ensureActivityPanel();
  loadActivity();
})();
/* DEVICE ACTIVITY END */
</script>
</body>
</html>
HTML

rm -f "$API"
exit 0
