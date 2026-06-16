#!/bin/sh
# LANGUARD_AUTH_GUARD
if [ -x /www/cgi-bin/languard-auth-guard.sh ]; then
  . /www/cgi-bin/languard-auth-guard.sh
  lg_require_auth || exit 0
fi
echo "Content-Type: text/html; charset=utf-8"
echo "Cache-Control: no-cache"
echo ""

POLICY="$(cat /etc/ispdash/unknown_policy 2>/dev/null)"
[ -z "$POLICY" ] && POLICY="alert"

API="/tmp/languard-security-api.$$"
/www/cgi-bin/dashboard-live-api.sh > "$API" 2>/dev/null

cat <<HTML
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>LanGuard Security</title>
<style>
body{margin:0;font-family:Arial,Helvetica,sans-serif;background:#f4f6f8;color:#111827}
.top{background:linear-gradient(180deg,#24282d,#171a1f);color:#fff;padding:16px;display:flex;align-items:center;justify-content:space-between;gap:14px;flex-wrap:wrap}
h1{margin:0;font-size:24px}.sub{font-size:13px;color:#cbd5e1;margin-top:5px}
.nav{display:flex;gap:8px;flex-wrap:wrap}
.btn{display:inline-flex;align-items:center;justify-content:center;border:0;border-radius:5px;background:#2563eb;color:#fff;text-decoration:none;font-weight:800;padding:9px 12px;cursor:pointer}
.btn.gray{background:#64748b}.btn.green{background:#16a34a}.btn.red{background:#dc2626}.btn.amber{background:#d97706}.btn.purple{background:#7c3aed}
.wrap{padding:16px;max-width:1250px;margin:0 auto}
.grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:12px;margin-bottom:14px}
.card{background:#fff;border:1px solid #d6dee8;border-radius:8px;box-shadow:0 1px 4px rgba(15,23,42,.1);padding:14px}
.card span{display:block;color:#64748b;font-size:10px;text-transform:uppercase;font-weight:800;letter-spacing:.08em}
.card b{display:block;font-size:24px;margin-top:5px}
.panel{background:#fff;border:1px solid #d6dee8;border-radius:8px;box-shadow:0 1px 4px rgba(15,23,42,.1);margin-bottom:14px;overflow:hidden}
.panel h2{margin:0;padding:12px;border-bottom:1px solid #e2e8f0;background:#f8fafc;font-size:17px;display:flex;align-items:center;justify-content:space-between;gap:10px;flex-wrap:wrap}
table{width:100%;border-collapse:collapse}
th,td{padding:9px 10px;border-bottom:1px solid #e2e8f0;text-align:left;font-size:13px;vertical-align:middle}
th{background:#edf2f7;color:#475569;text-transform:uppercase;font-size:10px;letter-spacing:.08em}
tr:hover td{background:#f8fbff}
.ok{color:#15803d;font-weight:900}.bad{color:#b91c1c;font-weight:900}.warn{color:#b45309;font-weight:900}.blue{color:#2563eb;font-weight:900}
.badge{display:inline-flex;min-width:80px;justify-content:center;padding:5px 8px;border-radius:4px;font-weight:900;font-size:11px}
.badge.unknown{background:#fed7aa;color:#9a3412}.badge.trusted{background:#dcfce7;color:#15803d}.badge.policy{background:#dbeafe;color:#1d4ed8}
code{font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;font-size:12px}
.note{color:#64748b;font-size:13px;line-height:1.45;padding:12px}
pre{background:#0f172a;color:#e5e7eb;padding:12px;margin:0;overflow:auto;white-space:pre-wrap;font-size:12px;min-height:120px}
@media(max-width:900px){.grid{grid-template-columns:1fr}.panel{overflow:auto}table{min-width:850px}.top{align-items:flex-start}}
</style>
</head>
<body>
<div class="top">
  <div>
    <h1>LanGuard Security</h1>
    <div class="sub">Unknown device protection · trusted devices · auto-block policy</div>
  </div>
  <div class="nav">
    <a class="btn" href="/cgi-bin/devices.sh">Dashboard</a>
    <a class="btn gray" href="/cgi-bin/languard-maintenance.sh">Tools</a>
    <a class="btn gray" href="/cgi-bin/languard-health.sh">Health</a>
  </div>
</div>

<div class="wrap">
HTML

UNKNOWN_COUNT="$(/www/cgi-bin/languard-trust.sh?action=unknown 2>/dev/null | grep -c '^UNKNOWN|')"
TRUSTED_COUNT="$(wc -l < /etc/ispdash/trusted.db 2>/dev/null)"
SEEN_COUNT="$(wc -l < /etc/ispdash/unknown_seen.db 2>/dev/null)"
[ -z "$TRUSTED_COUNT" ] && TRUSTED_COUNT="0"
[ -z "$SEEN_COUNT" ] && SEEN_COUNT="0"

cat <<HTML
  <div class="grid">
    <div class="card"><span>Current Unknown</span><b class="warn">$UNKNOWN_COUNT</b></div>
    <div class="card"><span>Trusted Devices</span><b class="ok">$TRUSTED_COUNT</b></div>
    <div class="card"><span>Policy</span><b class="blue">$POLICY</b></div>
  </div>

  <div class="panel">
    <h2>
      Security Policy
      <span class="badge policy">Current: $POLICY</span>
    </h2>
    <div class="note">
      <b>Alert only</b> mode unknown device ko highlight aur audit log mein record karta hai.  
      <b>Auto block</b> mode unknown LAN device ko automatic block kar sakta hai. Pehle Alert mode recommended hai.
      <br><br>
      <button class="btn green" onclick="setPolicy('alert')">Set Alert Only</button>
      <button class="btn red" onclick="setPolicy('block')">Set Auto Block Unknown LAN</button>
      <button class="btn amber" onclick="trustAll()">Trust All Current Devices</button>
    </div>
  </div>

  <div class="panel">
    <h2>Current Unknown Devices <button class="btn gray" onclick="location.reload()">Refresh</button></h2>
    <table>
      <tr><th>Status</th><th>Name</th><th>IP</th><th>MAC</th><th>Type</th><th>Today</th><th>Month</th><th>Total</th><th>Action</th></tr>
HTML

/www/cgi-bin/languard-trust.sh?action=unknown 2>/dev/null | awk -F'|' '
BEGIN{count=0}
$1=="UNKNOWN"{
  count++
  printf "<tr><td><span class=\"badge unknown\">UNKNOWN</span></td><td><b>%s</b></td><td>%s</td><td><code>%s</code></td><td>%s</td><td>%s GB</td><td>%s GB</td><td>%s GB</td><td><button class=\"btn green\" onclick=\"trustDevice('\''%s'\'','\''%s'\'')\">Trust</button></td></tr>\n", $5,$4,$2,$6,$7,$8,$9,$2,$5
}
END{
  if(count==0) print "<tr><td colspan=\"9\" class=\"ok\">No unknown devices right now.</td></tr>"
}'

cat <<HTML
    </table>
  </div>

  <div class="panel">
    <h2>Trusted Devices</h2>
    <table>
      <tr><th>Status</th><th>Name</th><th>IP</th><th>MAC</th><th>Type</th><th>Action</th></tr>
HTML

awk -F'|' '
FNR==NR{
  trusted[tolower($1)]=$2 "|" $3
  next
}
$1=="DEV"{
  m=tolower($2)
  if(m in trusted){
    printf "<tr><td><span class=\"badge trusted\">TRUSTED</span></td><td><b>%s</b></td><td>%s</td><td><code>%s</code></td><td>%s</td><td><button class=\"btn red\" onclick=\"untrustDevice('\''%s'\'')\">Untrust</button></td></tr>\n", $5,$4,$2,$8,$2
    shown[m]=1
  }
}
END{
  for(m in trusted){
    if(!(m in shown)){
      split(trusted[m],a,"|")
      printf "<tr><td><span class=\"badge trusted\">TRUSTED</span></td><td><b>%s</b></td><td>-</td><td><code>%s</code></td><td>-</td><td><button class=\"btn red\" onclick=\"untrustDevice('\''%s'\'')\">Untrust</button></td></tr>\n", a[1],m,m
    }
  }
}' /etc/ispdash/trusted.db "$API"

cat <<HTML
    </table>
  </div>

  <div class="panel">
    <h2>Recently Detected Unknown MACs</h2>
    <pre>$(tail -n 80 /etc/ispdash/unknown_seen.db 2>/dev/null)</pre>
  </div>
</div>

<script>
async function call(url){
  const r = await fetch(url + '&_=' + Date.now(), {cache:'no-store'});
  const t = await r.text();
  alert(t);
  location.reload();
}
function trustDevice(mac,name){
  call('/cgi-bin/languard-trust.sh?action=trust&mac=' + encodeURIComponent(mac) + '&name=' + encodeURIComponent(name || ''));
}
function untrustDevice(mac){
  if(confirm('Untrust this device?')) call('/cgi-bin/languard-trust.sh?action=untrust&mac=' + encodeURIComponent(mac));
}
function setPolicy(mode){
  if(mode === 'block'){
    if(!confirm('Auto-block unknown LAN devices? Use carefully.')) return;
  }
  call('/cgi-bin/languard-trust.sh?action=policy&mode=' + encodeURIComponent(mode));
}
function trustAll(){
  if(confirm('Trust all current devices as baseline?')){
    call('/cgi-bin/languard-trust.sh?action=trust_all');
  }
}
</script>
</body>
</html>
HTML

rm -f "$API"
exit 0
