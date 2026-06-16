#!/bin/sh
# LANGUARD_AUTH_GUARD
if [ -x /www/cgi-bin/languard-auth-guard.sh ]; then
  . /www/cgi-bin/languard-auth-guard.sh
  lg_require_auth || exit 0
fi
echo "Content-Type: text/html; charset=utf-8"
echo "Cache-Control: no-cache"
echo ""

cat <<'HTML'
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>LanGuard Tools</title>
<style>
body{margin:0;font-family:Arial,Helvetica,sans-serif;background:#f4f6f8;color:#111827}
.top{background:linear-gradient(180deg,#24282d,#171a1f);color:#fff;padding:16px}
h1{margin:0;font-size:24px}.sub{color:#cbd5e1;font-size:13px;margin-top:5px}
.wrap{padding:16px;max-width:1100px;margin:0 auto}
.grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:14px}
.card{background:#fff;border:1px solid #d6dee8;border-radius:8px;box-shadow:0 1px 4px rgba(15,23,42,.1);padding:14px}
.card h2{margin:0 0 10px;font-size:18px}
.btn{border:0;border-radius:5px;background:#2563eb;color:white;font-weight:800;padding:9px 12px;cursor:pointer;margin:4px 4px 4px 0}
.btn.red{background:#dc2626}.btn.green{background:#16a34a}.btn.gray{background:#64748b}
pre{background:#0f172a;color:#e5e7eb;padding:12px;border-radius:6px;overflow:auto;min-height:160px;white-space:pre-wrap;font-size:12px}
.note{font-size:13px;color:#64748b;line-height:1.45}
a{color:#2563eb;font-weight:700;text-decoration:none}
@media(max-width:800px){.grid{grid-template-columns:1fr}}
/* TOOLS TOP NAV FIX START */
.top{
  display:flex !important;
  align-items:center !important;
  justify-content:space-between !important;
  gap:14px !important;
  flex-wrap:wrap !important;
}
.topNav{
  display:flex !important;
  align-items:center !important;
  gap:8px !important;
  flex-wrap:wrap !important;
}
.topNav .btn{
  margin:0 !important;
  background:#2563eb !important;
  color:#fff !important;
  text-decoration:none !important;
  border-radius:5px !important;
  padding:9px 12px !important;
  font-weight:800 !important;
}
.topNav .btn.gray{background:#64748b !important;}
.wrap > p:first-child{display:none !important;}
.wrap > a[href="/cgi-bin/languard-health.sh"]{display:none !important;}
@media(max-width:800px){
  .top{align-items:flex-start !important;}
  .topNav{width:100% !important;}
}
/* TOOLS TOP NAV FIX END */
</style>
</head>
<body>
<div class="top">
  <h1>LanGuard Tools</h1>
  <div class="sub">Backup · Restore · Audit Log</div>
</div>
<div class="wrap">
  <p><a href="/cgi-bin/devices.sh">← Back to dashboard</a></p>
  <a class="btn gray" href="/cgi-bin/languard-health.sh">Health</a>

  <div class="grid">
    <div class="card">
      <h2>Backup / Restore</h2>
      <button class="btn green" onclick="createBackup()">Create Backup</button>
      <button class="btn" onclick="listBackups()">Refresh List</button>
      <button class="btn gray" onclick="location.href='/cgi-bin/languard-backup.sh?action=download_latest'">Download Latest</button>
      <button class="btn red" onclick="restoreLatest()">Restore Latest</button>
      <p class="note">Use Restore Latest only when the dashboard is corrupted. It restores files from the latest backup.</p>
      <pre id="backups">Loading...</pre>
    </div>

    <div class="card">
      <h2>Audit Log</h2>
      <button class="btn" onclick="loadAudit()">Refresh Log</button>
      <button class="btn red" onclick="clearAudit()">Clear Log</button>
      <p class="note">Block, unblock, delete, restore, limit changes, and backup actions are recorded here.</p>
      <pre id="audit">Loading...</pre>
    </div>
  </div>
</div>

<script>
async function txt(url){
  const r=await fetch(url+'&_='+Date.now(),{cache:'no-store'});
  return await r.text();
}
async function createBackup(){
  document.getElementById('backups').textContent='Creating backup...';
  const t=await txt('/cgi-bin/languard-backup.sh?action=create');
  await listBackups();
  alert(t);
}
async function listBackups(){
  const t=await txt('/cgi-bin/languard-backup.sh?action=list');
  document.getElementById('backups').textContent=t || 'No backups yet.';
}
async function restoreLatest(){
  const ok=prompt('Type YES to restore latest backup');
  if(ok!=='YES') return;
  document.getElementById('backups').textContent='Restoring latest backup...';
  const t=await txt('/cgi-bin/languard-backup.sh?action=restore_latest&confirm=YES');
  alert(t);
  await listBackups();
}
async function loadAudit(){
  const r=await fetch('/cgi-bin/languard-audit.sh?action=read&_='+Date.now(),{cache:'no-store'});
  const t=await r.text();
  document.getElementById('audit').textContent=t || 'No audit records yet.';
}
async function clearAudit(){
  const ok=prompt('Type YES to clear audit log');
  if(ok!=='YES') return;
  const r=await fetch('/cgi-bin/languard-audit.sh?action=clear&confirm=YES&_='+Date.now(),{cache:'no-store'});
  alert(await r.text());
  await loadAudit();
}
listBackups();
loadAudit();
</script>
<script>
/* TOOLS TOP NAV FIX START */
(function(){
  function addToolsTopNav(){
    if(document.getElementById("toolsTopNav")) return;
    var top=document.querySelector(".top");
    if(!top) return;
    var nav=document.createElement("div");
    nav.id="toolsTopNav";
    nav.className="topNav";
    var dash=document.createElement("a");
    dash.className="btn";
    dash.href="/cgi-bin/devices.sh";
    dash.textContent="Back to Dashboard";
    var health=document.createElement("a");
    health.className="btn gray";
    health.href="/cgi-bin/languard-health.sh";
    health.textContent="Health";
    nav.appendChild(dash);
    nav.appendChild(health);
    top.appendChild(nav);
  }
  if(document.readyState==="loading"){document.addEventListener("DOMContentLoaded",addToolsTopNav);}else{addToolsTopNav();}
})();
/* TOOLS TOP NAV FIX END */
</script>
<script>
/* TOOLS SECURITY TOP BUTTON START */
(function(){
  function addSecurityToTools(){
    var nav=document.querySelector(".topNav");
    if(!nav || document.getElementById("toolsSecurityBtn")) return;
    var a=document.createElement("a");
    a.id="toolsSecurityBtn";
    a.className="btn gray";
    a.href="/cgi-bin/languard-security.sh";
    a.textContent="Security";
    nav.appendChild(a);
  }
  if(document.readyState==="loading"){document.addEventListener("DOMContentLoaded",addSecurityToTools);}else{addSecurityToTools();}
})();
/* TOOLS SECURITY TOP BUTTON END */
</script>
</body>
</html>
HTML

exit 0
