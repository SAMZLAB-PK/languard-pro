#!/bin/sh
. /www/cgi-bin/languard-auth-guard.sh 2>/dev/null

if lg_valid_session 2>/dev/null; then
  echo "Status: 302 Found"
  echo "Location: /cgi-bin/devices.sh"
  echo "Cache-Control: no-store"
  echo ""
  exit 0
fi

echo "Content-Type: text/html; charset=utf-8"
echo "Cache-Control: no-store"
echo ""

cat <<'HTML'
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>LanGuard Login</title>
<style>
*{box-sizing:border-box}
body{margin:0;min-height:100vh;display:grid;place-items:center;font-family:Arial,Helvetica,sans-serif;background:#0f172a;color:#111827}
.card{width:min(420px,92vw);background:#fff;border:1px solid #d6dee8;border-radius:14px;box-shadow:0 20px 70px rgba(0,0,0,.35);overflow:hidden}
.top{background:linear-gradient(180deg,#24282d,#171a1f);color:#fff;padding:20px;display:flex;gap:12px;align-items:center}
.logo{width:42px;height:42px;border-radius:8px;background:#0ea5e9;display:grid;place-items:center;font-weight:900}
h1{margin:0;font-size:24px}.sub{font-size:12px;color:#cbd5e1;margin-top:3px}
.body{padding:20px}
label{display:block;font-size:11px;color:#64748b;font-weight:900;text-transform:uppercase;letter-spacing:.08em;margin:12px 0 5px}
input{width:100%;border:1px solid #cbd5e1;border-radius:8px;padding:12px;font-size:15px}
button{width:100%;margin-top:16px;border:0;border-radius:8px;background:#2563eb;color:#fff;font-weight:900;padding:12px;cursor:pointer;font-size:15px}
button:hover{filter:brightness(1.05)}
.err{display:none;margin-top:12px;background:#fee2e2;color:#991b1b;border:1px solid #fecaca;border-radius:8px;padding:10px;font-size:13px}
.note{margin-top:12px;color:#64748b;font-size:12px;line-height:1.4}
</style>
</head>
<body>
<div class="card">
  <div class="top">
    <div class="logo">LG</div>
    <div>
      <h1>LanGuard Pro</h1>
      <div class="sub">Router password login</div>
    </div>
  </div>
  <div class="body">
    <label>Router Username</label>
    <input id="user" autocomplete="username" value="root" autofocus>
    <label>Router Password</label>
    <input id="pass" type="password" autocomplete="current-password">
    <button onclick="login()">Login</button>
    <div class="err" id="err">Invalid router username or password.</div>
    <div class="note">Use your ImmortalWrt/LuCI router password. The username is usually <b>root</b>.</div>
  </div>
</div>

<script>
async function login(){
  const u=document.getElementById('user').value.trim() || 'root';
  const p=document.getElementById('pass').value;
  const err=document.getElementById('err');
  err.style.display='none';

  const r=await fetch('/cgi-bin/languard-auth.sh?action=login&user='+encodeURIComponent(u)+'&pass='+encodeURIComponent(p), {
    cache:'no-store',
    credentials:'same-origin'
  });

  const t=await r.text();

  if(t.indexOf('OK|login')===0){
    location.href='/cgi-bin/devices.sh';
  }else{
    err.style.display='block';
  }
}

document.getElementById('pass').addEventListener('keydown',function(e){
  if(e.key==='Enter') login();
});
document.getElementById('user').addEventListener('keydown',function(e){
  if(e.key==='Enter') document.getElementById('pass').focus();
});
</script>
</body>
</html>
HTML

exit 0
