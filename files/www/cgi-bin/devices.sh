#!/bin/sh
echo "Content-Type: text/html; charset=utf-8"
echo "Cache-Control: no-cache"
echo ""

cat <<'HTML'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>LanGuard Pro</title>
<style>
:root{--bg:#07111f;--panel:#0b1628;--line:#1e3352;--text:#eaf2ff;--muted:#8ea4c2;--blue:#3b82f6;--green:#22c55e;--red:#ef4444;--amber:#f59e0b;--cyan:#22d3ee;--purple:#a855f7;--shadow:0 24px 70px rgba(0,0,0,.38)}
*{box-sizing:border-box}
body{margin:0;font-family:Inter,Arial,Helvetica,sans-serif;background:radial-gradient(circle at 15% 10%,rgba(59,130,246,.25),transparent 28%),radial-gradient(circle at 85% 0%,rgba(34,197,94,.16),transparent 30%),linear-gradient(180deg,#06101d 0%,#091527 100%);color:var(--text);min-height:100vh}
.wrap{max-width:1500px;margin:0 auto;padding:18px 20px}
.top{display:grid;grid-template-columns:auto 1fr auto;align-items:center;gap:16px;margin-bottom:16px}
.brand{display:flex;align-items:center;gap:12px;min-width:300px}
.logo{width:46px;height:46px;border-radius:16px;background:linear-gradient(135deg,var(--blue),#14b8a6);box-shadow:0 14px 36px rgba(59,130,246,.35);display:grid;place-items:center;font-weight:900;font-size:20px}
h1{font-size:30px;line-height:1;margin:0}
.sub{color:var(--muted);font-size:13px;margin-top:7px}
.headerMetrics{display:grid;grid-template-columns:repeat(5,minmax(115px,1fr));gap:10px}
.hm{background:rgba(17,31,53,.72);border:1px solid rgba(142,164,194,.14);border-radius:18px;padding:10px 12px;text-align:center}
.hm span{display:block;color:var(--muted);font-size:10px;text-transform:uppercase;letter-spacing:.09em}
.hm b{display:block;font-size:18px;margin-top:5px;white-space:nowrap}
.hm small{color:#7f95b3;font-size:10px}
.topActions{display:flex;gap:9px;align-items:center;justify-content:flex-end}
.btn{border:0;border-radius:14px;padding:11px 14px;color:#fff;background:linear-gradient(135deg,var(--blue),#2563eb);font-weight:800;cursor:pointer}
.btn:hover{filter:brightness(1.1)}
.btn.red{background:linear-gradient(135deg,#ef4444,#b91c1c)}
.btn.green{background:linear-gradient(135deg,#22c55e,#15803d)}
.btn.gray{background:linear-gradient(135deg,#64748b,#334155)}
.btn.purple{background:linear-gradient(135deg,#a855f7,#7e22ce)}
.btn.amber{background:linear-gradient(135deg,#f59e0b,#b45309)}
.btn.disabled{background:#334155;color:#94a3b8;cursor:not-allowed}
.btn.small{padding:8px 10px;border-radius:11px;font-size:12px}
.stats{display:grid;grid-template-columns:repeat(7,minmax(0,1fr));gap:12px;margin:16px 0;align-items:stretch}
.stat{padding:16px;border-radius:22px;background:rgba(17,31,53,.78);border:1px solid rgba(142,164,194,.14);text-align:center;display:flex;flex-direction:column;align-items:center;justify-content:center;min-height:92px}
.stat.clickable{cursor:pointer;transition:.15s}
.stat.clickable:hover{transform:translateY(-2px);border-color:rgba(168,85,247,.55)}
.stat.active{border-color:rgba(168,85,247,.8);box-shadow:0 0 0 1px rgba(168,85,247,.35) inset}
.stat span{display:block;color:var(--muted);font-size:12px;text-transform:uppercase;letter-spacing:.08em;text-align:center;width:100%}
.stat b{display:block;font-size:24px;margin-top:8px;text-align:center;width:100%}
.ok{color:var(--green)}.bad{color:var(--red)}.deletedColor{color:#d8b4fe}.cyan{color:#67e8f9}.amberText{color:#fcd34d}
.panel{background:rgba(11,22,40,.84);border:1px solid rgba(142,164,194,.18);border-radius:24px;box-shadow:var(--shadow);backdrop-filter:blur(16px)}
.toolbar{padding:14px;display:flex;gap:10px;align-items:center;justify-content:space-between;flex-wrap:wrap}
.search{min-width:260px;flex:1;background:#07111f;border:1px solid var(--line);color:var(--text);border-radius:14px;padding:12px 14px;outline:none}
.tablewrap{overflow:auto;border-radius:22px}
table{width:100%;border-collapse:collapse;min-width:1580px}
th,td{padding:13px 11px;text-align:left;border-bottom:1px solid rgba(142,164,194,.12);font-size:14px}
th{color:#b8c8df;background:rgba(17,31,53,.9);text-transform:uppercase;font-size:11px;letter-spacing:.08em}
.status,.type,.limtag{display:inline-flex;align-items:center;gap:7px;padding:7px 10px;border-radius:999px;font-weight:900;font-size:12px}
.status:before{content:"";width:8px;height:8px;border-radius:50%}
.online{background:rgba(34,197,94,.12);color:#86efac}.online:before{background:var(--green)}
.offline{background:rgba(239,68,68,.12);color:#fca5a5}.offline:before{background:var(--red)}
.blocked{background:rgba(245,158,11,.14);color:#fcd34d}.blocked:before{background:var(--amber)}
.deleted{background:rgba(168,85,247,.14);color:#d8b4fe}.deleted:before{background:var(--purple)}
.type.lan{background:rgba(59,130,246,.12);color:#93c5fd}
.type.ts{background:rgba(34,211,238,.12);color:#67e8f9}
.limtag.off{background:rgba(100,116,139,.18);color:#cbd5e1}
.limtag.on{background:rgba(34,197,94,.12);color:#86efac}
.limtag.over{background:rgba(239,68,68,.14);color:#fca5a5}
.inputbox{width:100%;background:#07111f;border:1px solid var(--line);color:var(--text);border-radius:12px;padding:10px;outline:none}
.inputbox:focus{border-color:#60a5fa;box-shadow:0 0 0 2px rgba(96,165,250,.18)}
.namebox{max-width:230px}.ipbox{max-width:160px;font-family:ui-monospace,SFMono-Regular,Menlo,monospace}
.inputbox:disabled{opacity:.55;cursor:not-allowed}
.actions{display:flex;gap:7px;flex-wrap:wrap}
.mac{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;color:#b8c8df}
.footer{color:var(--muted);font-size:12px;text-align:center;margin:18px 0 6px}
.notice{color:#9fb4d1;font-size:13px}
.modeBadge{padding:8px 11px;border-radius:999px;background:rgba(168,85,247,.14);color:#d8b4fe;font-weight:900;font-size:12px}
.editBadge{padding:8px 11px;border-radius:999px;background:rgba(245,158,11,.14);color:#fcd34d;font-weight:900;font-size:12px;display:none}
.hint{color:#93a9c7;font-size:11px;line-height:1.35;margin-top:5px}
.trafficMini{display:inline-block;font-weight:900;font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:13px}
.trafficMini.dl{color:#67e8f9}.trafficMini.ul{color:#fcd34d}
.numMini{display:inline-block;font-weight:900;font-family:ui-monospace,SFMono-Regular,Menlo,monospace;color:#dbeafe;font-size:13px}
.trafficSub{font-size:10px;color:#7f95b3;margin-top:4px}
.modalBackdrop{position:fixed;inset:0;background:rgba(0,0,0,.62);display:none;align-items:center;justify-content:center;padding:18px;z-index:50}
.modal{width:min(560px,100%);background:#0b1628;border:1px solid rgba(142,164,194,.22);border-radius:24px;box-shadow:0 30px 90px rgba(0,0,0,.55);padding:18px}
.modalTop{display:flex;align-items:flex-start;justify-content:space-between;gap:12px;margin-bottom:12px}
.modal h2{margin:0;font-size:22px}.modal .mSub{color:var(--muted);font-size:13px;margin-top:5px}
.grid2{display:grid;grid-template-columns:1fr 1fr;gap:12px}
.field{margin-top:12px}.field label{display:block;color:#b8c8df;font-size:12px;text-transform:uppercase;letter-spacing:.08em;margin-bottom:6px}
.checkrow{display:flex;align-items:center;gap:10px;padding:12px;border:1px solid rgba(142,164,194,.18);border-radius:14px;background:#07111f;margin:12px 0}.checkrow input{width:20px;height:20px}
.modalActions{display:flex;gap:8px;flex-wrap:wrap;justify-content:flex-end;margin-top:16px}
@media(max-width:1180px){.top{grid-template-columns:1fr}.headerMetrics{grid-template-columns:repeat(2,minmax(120px,1fr))}.topActions{justify-content:flex-start}.brand{min-width:0}.stats{grid-template-columns:repeat(2,minmax(0,1fr))}}
@media(max-width:900px){.wrap{padding:14px}table{min-width:0}thead{display:none}table,tr,td,tbody{display:block;width:100%}tr{background:rgba(7,17,31,.72);border:1px solid rgba(142,164,194,.14);border-radius:18px;margin:12px;padding:10px}td{border:0;padding:8px}td:before{content:attr(data-label);display:block;color:var(--muted);font-size:11px;text-transform:uppercase;letter-spacing:.08em;margin-bottom:4px}.namebox,.ipbox{max-width:100%}}
/* LanGuard stacked columns patch */
table{min-width:1120px !important;}
.stackCell{display:flex;flex-direction:column;gap:5px;}
.stackTitle{font-weight:900;color:#eaf2ff;}
.stackSub{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;color:#8ea4c2;font-size:12px;word-break:break-all;}
.stackLine{display:flex;align-items:center;gap:8px;white-space:nowrap;}
.stackLabel{min-width:54px;color:#8ea4c2;font-size:10px;text-transform:uppercase;letter-spacing:.08em;}
.stackValue{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-weight:900;color:#dbeafe;}
.stackValue.dl{color:#67e8f9;}
.stackValue.ul{color:#fcd34d;}
.stackValue.daily{color:#86efac;}
.stackValue.monthly{color:#dbeafe;}
.stackValue.total{color:#d8b4fe;}
/* end LanGuard stacked columns patch */
/* LanGuard professional themes patch */
.stats{grid-template-columns:repeat(8,minmax(0,1fr)) !important;gap:8px !important;}
.stat{min-height:68px !important;padding:10px 8px !important;border-radius:16px !important;}
.stat span{font-size:10px !important;}
.stat b{font-size:20px !important;margin-top:5px !important;}
.themeCard{cursor:pointer !important;user-select:none !important;}
.themeCard b{font-size:14px !important;color:#67e8f9 !important;}
.themeCard:hover{transform:translateY(-2px);border-color:rgba(34,211,238,.75) !important;}

body.theme-midnight{background:radial-gradient(circle at 15% 10%,rgba(59,130,246,.25),transparent 28%),radial-gradient(circle at 85% 0%,rgba(34,197,94,.16),transparent 30%),linear-gradient(180deg,#06101d 0%,#091527 100%) !important;}
body.theme-midnight .logo{background:linear-gradient(135deg,#3b82f6,#14b8a6) !important;}

body.theme-emerald{background:radial-gradient(circle at 18% 10%,rgba(34,197,94,.30),transparent 30%),radial-gradient(circle at 85% 5%,rgba(20,184,166,.22),transparent 30%),linear-gradient(180deg,#04140d 0%,#071f17 100%) !important;}
body.theme-emerald .logo{background:linear-gradient(135deg,#22c55e,#14b8a6) !important;}
body.theme-emerald .themeCard,body.theme-emerald .stat.active{border-color:rgba(34,197,94,.80) !important;}

body.theme-cyber{background:radial-gradient(circle at 15% 10%,rgba(34,211,238,.28),transparent 28%),radial-gradient(circle at 85% 0%,rgba(168,85,247,.22),transparent 30%),linear-gradient(180deg,#020617 0%,#08111f 100%) !important;}
body.theme-cyber .logo{background:linear-gradient(135deg,#06b6d4,#8b5cf6) !important;}
body.theme-cyber .themeCard,body.theme-cyber .stat.active{border-color:rgba(34,211,238,.80) !important;}

body.theme-purple{background:radial-gradient(circle at 15% 10%,rgba(168,85,247,.32),transparent 30%),radial-gradient(circle at 85% 0%,rgba(59,130,246,.20),transparent 28%),linear-gradient(180deg,#0c0618 0%,#151025 100%) !important;}
body.theme-purple .logo{background:linear-gradient(135deg,#a855f7,#3b82f6) !important;}
body.theme-purple .themeCard,body.theme-purple .stat.active{border-color:rgba(168,85,247,.85) !important;}

body.theme-amber{background:radial-gradient(circle at 15% 10%,rgba(245,158,11,.30),transparent 28%),radial-gradient(circle at 85% 0%,rgba(251,146,60,.22),transparent 30%),linear-gradient(180deg,#170b02 0%,#241306 100%) !important;}
body.theme-amber .logo{background:linear-gradient(135deg,#f59e0b,#ef4444) !important;}
body.theme-amber .themeCard,body.theme-amber .stat.active{border-color:rgba(245,158,11,.85) !important;}

body.theme-slate{background:radial-gradient(circle at 15% 10%,rgba(100,116,139,.25),transparent 28%),radial-gradient(circle at 85% 0%,rgba(51,65,85,.25),transparent 30%),linear-gradient(180deg,#020617 0%,#0f172a 100%) !important;}
body.theme-slate .logo{background:linear-gradient(135deg,#64748b,#334155) !important;}
body.theme-slate .themeCard,body.theme-slate .stat.active{border-color:rgba(148,163,184,.75) !important;}

body.theme-light{background:linear-gradient(180deg,#eef6ff 0%,#f8fafc 100%) !important;color:#0f172a !important;}
body.theme-light .panel,body.theme-light .stat,body.theme-light .hm,body.theme-light .modal{background:rgba(255,255,255,.94) !important;border-color:#cbd5e1 !important;color:#0f172a !important;}
body.theme-light th{background:#e2e8f0 !important;color:#0f172a !important;}
body.theme-light td{border-bottom-color:#dbe4ef !important;}
body.theme-light .inputbox,body.theme-light .search{background:#ffffff !important;color:#0f172a !important;border-color:#cbd5e1 !important;}
body.theme-light .sub,body.theme-light .hint,body.theme-light .notice,body.theme-light .stackSub,body.theme-light .stackLabel{color:#475569 !important;}
body.theme-light .mac,body.theme-light .numMini,body.theme-light .stackValue{color:#0f172a !important;}
body.theme-light .logo{background:linear-gradient(135deg,#2563eb,#06b6d4) !important;}
body.theme-light .themeCard,body.theme-light .stat.active{border-color:rgba(37,99,235,.75) !important;}

@media(max-width:1180px){.stats{grid-template-columns:repeat(2,minmax(0,1fr)) !important;}}
/* end LanGuard professional themes patch */
/* LanGuard light mobile polish patch */
body.theme-light{
  background:radial-gradient(circle at 12% 8%,rgba(37,99,235,.10),transparent 32%),linear-gradient(180deg,#f4f8fc 0%,#eef3f8 100%) !important;
  color:#111827 !important;
}
body.theme-light .wrap{color:#111827 !important;}
body.theme-light .panel{
  background:rgba(255,255,255,.96) !important;
  border:1px solid #d9e3ef !important;
  box-shadow:0 18px 45px rgba(15,23,42,.10) !important;
}
body.theme-light .hm,body.theme-light .stat{
  background:rgba(255,255,255,.94) !important;
  border-color:#d9e3ef !important;
  box-shadow:0 10px 26px rgba(15,23,42,.07) !important;
  color:#111827 !important;
}
body.theme-light .stat.active{
  border-color:#3b82f6 !important;
  box-shadow:0 0 0 1px rgba(59,130,246,.35) inset,0 10px 26px rgba(37,99,235,.10) !important;
}
body.theme-light th{background:#e8eef6 !important;color:#334155 !important;}
body.theme-light td{border-bottom-color:#e2e8f0 !important;color:#111827 !important;}
body.theme-light .tablewrap{background:transparent !important;}
body.theme-light .inputbox,body.theme-light .search{
  background:#ffffff !important;
  color:#111827 !important;
  border-color:#cbd5e1 !important;
  box-shadow:0 1px 2px rgba(15,23,42,.04) !important;
}
body.theme-light .inputbox:focus,body.theme-light .search:focus{
  border-color:#3b82f6 !important;
  box-shadow:0 0 0 3px rgba(59,130,246,.14) !important;
}
body.theme-light .sub,body.theme-light .hint,body.theme-light .notice,body.theme-light .stackSub,body.theme-light .stackLabel,body.theme-light .trafficSub{
  color:#64748b !important;
}
body.theme-light .mac,body.theme-light .numMini,body.theme-light .stackValue{color:#111827 !important;}
body.theme-light .stackValue.dl,body.theme-light .trafficMini.dl{color:#0284c7 !important;}
body.theme-light .stackValue.ul,body.theme-light .trafficMini.ul{color:#b45309 !important;}
body.theme-light .stackValue.daily{color:#15803d !important;}
body.theme-light .stackValue.total{color:#7c3aed !important;}
body.theme-light .modeBadge{background:#eef2ff !important;color:#4f46e5 !important;}
body.theme-light .editBadge{background:#fef3c7 !important;color:#92400e !important;}
body.theme-light .status.online{background:#dcfce7 !important;color:#15803d !important;}
body.theme-light .status.offline{background:#fee2e2 !important;color:#b91c1c !important;}
body.theme-light .type.lan{background:#dbeafe !important;color:#1d4ed8 !important;}
body.theme-light .type.ts{background:#cffafe !important;color:#0e7490 !important;}
body.theme-light .limtag.off{background:#e2e8f0 !important;color:#334155 !important;}
body.theme-light .limtag.on{background:#dcfce7 !important;color:#15803d !important;}
body.theme-light .logo{background:linear-gradient(135deg,#2563eb,#06b6d4) !important;}
.stackCell{gap:3px !important;}
.stackLine{gap:5px !important;line-height:1.25 !important;margin:0 !important;}
.stackLabel{min-width:38px !important;font-size:9px !important;}
.stackValue{font-size:13px !important;}
td[data-label="Speed"] .stackCell{gap:2px !important;}
td[data-label="Usage"] .stackCell{gap:3px !important;}
.limtag{padding:6px 9px !important;}
@media(max-width:900px){
  body.theme-light .panel{background:rgba(255,255,255,.98) !important;}
  body.theme-light tr{
    background:#ffffff !important;
    border:1px solid #d9e3ef !important;
    box-shadow:0 12px 28px rgba(15,23,42,.08) !important;
  }
  body.theme-light td{color:#111827 !important;}
  body.theme-light td:before{color:#64748b !important;}
  tr{padding:12px !important;margin:12px 0 !important;border-radius:18px !important;}
  td{padding:7px 10px !important;}
  td:before{margin-bottom:5px !important;}
  .stackCell{gap:4px !important;}
  .stackLine{display:grid !important;grid-template-columns:42px auto !important;gap:4px !important;align-items:center !important;}
  .stackLabel{min-width:0 !important;font-size:9px !important;}
  .stackValue,.trafficMini,.numMini{font-size:14px !important;}
  .inputbox{padding:9px 11px !important;border-radius:12px !important;}
  .actions{gap:7px !important;}
  .btn.small{padding:8px 10px !important;font-size:12px !important;}
}
/* end LanGuard light mobile polish patch */
/* LanGuard pro actions light patch */
table{min-width:1080px !important;}
th:nth-child(3),td:nth-child(3){min-width:260px !important;}
th:nth-child(8),td:nth-child(8){width:115px !important;min-width:115px !important;}
.namebox{max-width:310px !important;}
.actions{position:relative !important;display:flex !important;align-items:center !important;justify-content:flex-start !important;}
.actionMenuWrap{position:relative;display:inline-block;}
.actionMain{min-width:82px !important;font-weight:900 !important;}
.actionMenu{
  display:none;
  position:absolute;
  right:0;
  top:calc(100% + 8px);
  min-width:150px;
  padding:8px;
  border-radius:15px;
  background:#0b1628;
  border:1px solid rgba(142,164,194,.25);
  box-shadow:0 18px 45px rgba(0,0,0,.35);
  z-index:9999;
}
.actionMenu.open{display:grid;gap:7px;}
.actionMenu .btn{width:100% !important;text-align:center !important;justify-content:center !important;}
.actionMenu .btn.disabled{pointer-events:none;}
body.theme-light{
  background:linear-gradient(180deg,#f5f8fc 0%,#edf3f9 100%) !important;
  color:#111827 !important;
}
body.theme-light .panel{
  background:#ffffff !important;
  border:1px solid #d8e3ef !important;
  box-shadow:0 18px 45px rgba(15,23,42,.09) !important;
}
body.theme-light .tablewrap{
  background:#ffffff !important;
  border-radius:22px !important;
}
body.theme-light table{background:#ffffff !important;}
body.theme-light th{
  background:#edf3f9 !important;
  color:#475569 !important;
  border-bottom:1px solid #d9e3ef !important;
}
body.theme-light td{
  color:#111827 !important;
  border-bottom:1px solid #e2e8f0 !important;
}
body.theme-light tr:hover{background:#f8fbff !important;}
body.theme-light .inputbox,body.theme-light .search{
  background:#ffffff !important;
  color:#111827 !important;
  border:1px solid #cbd5e1 !important;
  box-shadow:0 1px 2px rgba(15,23,42,.04) !important;
}
body.theme-light .inputbox:focus,body.theme-light .search:focus{
  border-color:#2563eb !important;
  box-shadow:0 0 0 3px rgba(37,99,235,.13) !important;
}
body.theme-light .stat,body.theme-light .hm{
  background:#ffffff !important;
  border-color:#d8e3ef !important;
  box-shadow:0 10px 25px rgba(15,23,42,.06) !important;
}
body.theme-light .stat.active{
  border-color:#2563eb !important;
  box-shadow:0 0 0 1px rgba(37,99,235,.30) inset,0 10px 25px rgba(37,99,235,.08) !important;
}
body.theme-light .modeBadge{background:#eef2ff !important;color:#4338ca !important;}
body.theme-light .actionMenu{
  background:#ffffff !important;
  border:1px solid #d8e3ef !important;
  box-shadow:0 18px 45px rgba(15,23,42,.16) !important;
}
body.theme-light .sub,body.theme-light .hint,body.theme-light .notice,body.theme-light .stackSub,body.theme-light .stackLabel,body.theme-light .trafficSub{color:#64748b !important;}
body.theme-light .stackValue,body.theme-light .numMini,body.theme-light .mac{color:#111827 !important;}
body.theme-light .stackValue.dl,body.theme-light .trafficMini.dl{color:#0284c7 !important;}
body.theme-light .stackValue.ul,body.theme-light .trafficMini.ul{color:#b45309 !important;}
body.theme-light .stackValue.daily{color:#15803d !important;}
body.theme-light .stackValue.total{color:#7c3aed !important;}
.stackLine{gap:4px !important;line-height:1.22 !important;}
.stackLabel{min-width:38px !important;}
@media(max-width:900px){
  table{min-width:0 !important;}
  body.theme-light tr{
    background:#ffffff !important;
    border:1px solid #d8e3ef !important;
    box-shadow:0 12px 28px rgba(15,23,42,.08) !important;
  }
  body.theme-light tr:hover{background:#ffffff !important;}
  td{padding:7px 10px !important;}
  .actionMenu{position:static !important;margin-top:8px !important;min-width:100% !important;}
  .actionMain{width:100% !important;}
  .actions{display:block !important;}
  .namebox{max-width:100% !important;}
}
/* end LanGuard pro actions light patch */
/* LanGuard ImmortalWrt LuCI theme start */

/* ImmortalWrt / LuCI inspired admin-panel theme */
body.theme-immortal{
  --bg:#f4f6f8;
  --panel:#ffffff;
  --line:#d6dee8;
  --text:#1f2937;
  --muted:#64748b;
  --blue:#1d4ed8;
  --green:#16a34a;
  --red:#dc2626;
  --amber:#d97706;
  --cyan:#0284c7;
  --purple:#7c3aed;
  background:#f4f6f8 !important;
  color:#1f2937 !important;
  font-family:Arial,Helvetica,sans-serif !important;
}

body.theme-immortal .wrap{
  max-width:1500px !important;
  padding:0 14px 18px !important;
}

/* LuCI-like dark header */
body.theme-immortal .top{
  background:linear-gradient(180deg,#24282d 0%,#171a1f 100%) !important;
  color:#f8fafc !important;
  border-radius:0 0 5px 5px !important;
  padding:12px 14px !important;
  margin:0 -14px 14px !important;
  box-shadow:0 2px 8px rgba(15,23,42,.25) !important;
  border-bottom:1px solid #111827 !important;
}

body.theme-immortal .brand{
  min-width:270px !important;
}

body.theme-immortal .logo{
  width:34px !important;
  height:34px !important;
  border-radius:4px !important;
  background:#00a3d9 !important;
  color:#ffffff !important;
  box-shadow:none !important;
  font-size:14px !important;
}

body.theme-immortal h1{
  font-size:24px !important;
  font-weight:700 !important;
  color:#ffffff !important;
  letter-spacing:.01em !important;
}

body.theme-immortal .sub{
  color:#cbd5e1 !important;
  font-size:12px !important;
}

/* Top traffic boxes */
body.theme-immortal .headerMetrics{
  gap:8px !important;
}

body.theme-immortal .hm{
  background:#20252b !important;
  border:1px solid #38424f !important;
  border-radius:4px !important;
  box-shadow:none !important;
  padding:8px 10px !important;
}

body.theme-immortal .hm span{
  color:#9fb1c7 !important;
  font-size:9px !important;
  letter-spacing:.08em !important;
}

body.theme-immortal .hm b{
  color:#ffffff !important;
  font-size:15px !important;
}

body.theme-immortal .hm small{
  color:#94a3b8 !important;
}

/* Buttons: LuCI compact style */
body.theme-immortal .btn{
  border-radius:4px !important;
  padding:7px 10px !important;
  font-size:12px !important;
  font-weight:700 !important;
  box-shadow:none !important;
}

body.theme-immortal .btn.small{
  border-radius:4px !important;
  padding:6px 8px !important;
  font-size:11px !important;
}

body.theme-immortal .btn,
body.theme-immortal .btn.gray{
  background:#1d4ed8 !important;
  color:#ffffff !important;
}

body.theme-immortal .btn.red{background:#dc2626 !important;}
body.theme-immortal .btn.green{background:#16a34a !important;}
body.theme-immortal .btn.amber{background:#d97706 !important;}
body.theme-immortal .btn.purple{background:#7c3aed !important;}
body.theme-immortal .btn.disabled{background:#64748b !important;color:#e2e8f0 !important;}

/* Counter cards */
body.theme-immortal .stats{
  grid-template-columns:repeat(8,minmax(0,1fr)) !important;
  gap:8px !important;
  margin:12px 0 !important;
}

body.theme-immortal .stat{
  background:#ffffff !important;
  border:1px solid #d6dee8 !important;
  border-radius:4px !important;
  min-height:64px !important;
  padding:8px !important;
  box-shadow:0 1px 3px rgba(15,23,42,.08) !important;
  color:#1f2937 !important;
}

body.theme-immortal .stat span{
  color:#64748b !important;
  font-size:10px !important;
  font-weight:700 !important;
}

body.theme-immortal .stat b{
  font-size:20px !important;
  color:#0f172a !important;
}

body.theme-immortal .stat.active{
  border-color:#1d4ed8 !important;
  box-shadow:0 0 0 1px rgba(29,78,216,.30) inset,0 1px 3px rgba(15,23,42,.08) !important;
}

body.theme-immortal .stat:hover{
  border-color:#93b4e6 !important;
}

body.theme-immortal .ok{color:#16a34a !important;}
body.theme-immortal .bad{color:#dc2626 !important;}
body.theme-immortal .deletedColor{color:#7c3aed !important;}
body.theme-immortal .themeCard b{
  color:#0284c7 !important;
  font-size:13px !important;
}

/* Main panel */
body.theme-immortal .panel{
  background:#ffffff !important;
  border:1px solid #d6dee8 !important;
  border-radius:4px !important;
  box-shadow:0 1px 4px rgba(15,23,42,.10) !important;
}

body.theme-immortal .toolbar{
  background:#ffffff !important;
  border-bottom:1px solid #e2e8f0 !important;
  padding:10px 12px !important;
}

body.theme-immortal .search{
  background:#ffffff !important;
  color:#1f2937 !important;
  border:1px solid #cbd5e1 !important;
  border-radius:4px !important;
  padding:9px 11px !important;
  box-shadow:inset 0 1px 2px rgba(15,23,42,.04) !important;
}

body.theme-immortal .search:focus,
body.theme-immortal .inputbox:focus{
  border-color:#1d4ed8 !important;
  box-shadow:0 0 0 2px rgba(29,78,216,.14) !important;
}

body.theme-immortal .modeBadge{
  background:#e8f0fe !important;
  color:#1d4ed8 !important;
  border-radius:4px !important;
  font-size:11px !important;
}

body.theme-immortal .editBadge{
  background:#fff7ed !important;
  color:#c2410c !important;
  border-radius:4px !important;
}

body.theme-immortal .notice{
  color:#64748b !important;
}

/* Table */
body.theme-immortal .tablewrap{
  background:#ffffff !important;
  border-radius:0 0 4px 4px !important;
}

body.theme-immortal table{
  background:#ffffff !important;
  min-width:1080px !important;
}

body.theme-immortal th{
  background:#edf2f7 !important;
  color:#475569 !important;
  border-bottom:1px solid #d6dee8 !important;
  font-size:10px !important;
  font-weight:800 !important;
  padding:9px 10px !important;
}

body.theme-immortal td{
  background:#ffffff !important;
  color:#1f2937 !important;
  border-bottom:1px solid #e2e8f0 !important;
  padding:9px 10px !important;
}

body.theme-immortal tr:hover td{
  background:#f8fbff !important;
}

/* Inputs */
body.theme-immortal .inputbox{
  background:#ffffff !important;
  color:#1f2937 !important;
  border:1px solid #cbd5e1 !important;
  border-radius:4px !important;
  padding:7px 9px !important;
  box-shadow:inset 0 1px 2px rgba(15,23,42,.04) !important;
}

body.theme-immortal .namebox{
  max-width:340px !important;
}

body.theme-immortal .ipbox{
  max-width:160px !important;
}

/* Badges */
body.theme-immortal .status,
body.theme-immortal .type,
body.theme-immortal .limtag{
  border-radius:4px !important;
  padding:5px 8px !important;
  font-size:11px !important;
}

body.theme-immortal .status.online{
  background:#dcfce7 !important;
  color:#15803d !important;
}

body.theme-immortal .status.offline{
  background:#fee2e2 !important;
  color:#b91c1c !important;
}

body.theme-immortal .status.blocked{
  background:#fef3c7 !important;
  color:#92400e !important;
}

body.theme-immortal .type.lan{
  background:#dbeafe !important;
  color:#1d4ed8 !important;
}

body.theme-immortal .type.ts{
  background:#cffafe !important;
  color:#0e7490 !important;
}

body.theme-immortal .limtag.off{
  background:#e2e8f0 !important;
  color:#334155 !important;
}

body.theme-immortal .limtag.on{
  background:#dcfce7 !important;
  color:#15803d !important;
}

/* Text stacks */
body.theme-immortal .stackSub,
body.theme-immortal .stackLabel,
body.theme-immortal .hint,
body.theme-immortal .trafficSub{
  color:#64748b !important;
}

body.theme-immortal .mac,
body.theme-immortal .numMini,
body.theme-immortal .stackValue{
  color:#1f2937 !important;
}

body.theme-immortal .stackValue.dl,
body.theme-immortal .trafficMini.dl{
  color:#0284c7 !important;
}

body.theme-immortal .stackValue.ul,
body.theme-immortal .trafficMini.ul{
  color:#b45309 !important;
}

body.theme-immortal .stackValue.daily{
  color:#15803d !important;
}

body.theme-immortal .stackValue.total{
  color:#7c3aed !important;
}

body.theme-immortal .stackCell{
  gap:3px !important;
}

body.theme-immortal .stackLine{
  gap:4px !important;
  line-height:1.22 !important;
}

body.theme-immortal .stackLabel{
  min-width:38px !important;
  font-size:9px !important;
}

/* Action dropdown */
body.theme-immortal .actionMenu{
  background:#ffffff !important;
  border:1px solid #cbd5e1 !important;
  border-radius:4px !important;
  box-shadow:0 12px 30px rgba(15,23,42,.18) !important;
}

/* Modal */
body.theme-immortal .modal{
  background:#ffffff !important;
  border:1px solid #d6dee8 !important;
  border-radius:5px !important;
  color:#1f2937 !important;
  box-shadow:0 20px 55px rgba(15,23,42,.22) !important;
}

body.theme-immortal .modal h2{
  color:#0f172a !important;
}

body.theme-immortal .mSub,
body.theme-immortal .field label{
  color:#64748b !important;
}

body.theme-immortal .checkrow{
  background:#f8fafc !important;
  border:1px solid #d6dee8 !important;
  border-radius:4px !important;
}

/* Mobile */
@media(max-width:1180px){
  body.theme-immortal .stats{
    grid-template-columns:repeat(2,minmax(0,1fr)) !important;
  }
}

@media(max-width:900px){
  body.theme-immortal .wrap{
    padding:0 10px 14px !important;
  }

  body.theme-immortal .top{
    margin:0 -10px 12px !important;
    border-radius:0 0 4px 4px !important;
  }

  body.theme-immortal .headerMetrics{
    grid-template-columns:repeat(2,minmax(120px,1fr)) !important;
  }

  body.theme-immortal table{
    min-width:0 !important;
  }

  body.theme-immortal tr{
    background:#ffffff !important;
    border:1px solid #d6dee8 !important;
    border-radius:5px !important;
    box-shadow:0 2px 8px rgba(15,23,42,.08) !important;
    margin:10px 0 !important;
    padding:10px !important;
  }

  body.theme-immortal td{
    background:#ffffff !important;
    padding:7px 8px !important;
    border-bottom:0 !important;
  }

  body.theme-immortal td:before{
    color:#64748b !important;
    font-weight:800 !important;
  }

  body.theme-immortal .actions{
    display:block !important;
  }

  body.theme-immortal .actionMain{
    width:100% !important;
  }

  body.theme-immortal .actionMenu{
    position:static !important;
    margin-top:7px !important;
    min-width:100% !important;
  }

  body.theme-immortal .namebox,
  body.theme-immortal .ipbox{
    max-width:100% !important;
  }

  body.theme-immortal .stackLine{
    display:grid !important;
    grid-template-columns:42px auto !important;
    gap:4px !important;
  }
}

/* LanGuard ImmortalWrt LuCI theme end */
/* LanGuard status type stack patch */
table{min-width:1020px !important;}
th:nth-child(1),td:nth-child(1){width:118px !important;min-width:118px !important;}
th:nth-child(2),td:nth-child(2){min-width:285px !important;}
th:nth-child(7),td:nth-child(7){width:115px !important;min-width:115px !important;}
.stateStack{
  display:flex;
  flex-direction:column;
  align-items:flex-start;
  justify-content:center;
  gap:7px;
  min-height:48px;
}
.stateStack .status,.stateStack .type{
  min-width:84px;
  justify-content:center;
  padding:6px 9px !important;
  line-height:1 !important;
}
body.theme-immortal .stateStack{gap:5px !important;}
body.theme-immortal .stateStack .status,body.theme-immortal .stateStack .type{
  border-radius:4px !important;
  min-width:76px !important;
  padding:5px 8px !important;
}
body.theme-light .stateStack .status,body.theme-light .stateStack .type{
  box-shadow:none !important;
}
td{vertical-align:middle !important;}
.stackCell{justify-content:center !important;}
.actions{align-items:center !important;}
@media(max-width:900px){
  table{min-width:0 !important;}
  .stateStack{gap:8px !important;align-items:flex-start !important;}
  .stateStack .status,.stateStack .type{min-width:96px !important;}
  td{padding:8px 10px !important;}
  td[data-label="State"]{padding-top:10px !important;}
}
/* end LanGuard status type stack patch */
/* LanGuard mac under ip patch */
table{min-width:1040px !important;}
th:nth-child(1),td:nth-child(1){width:118px !important;min-width:118px !important;}
th:nth-child(2),td:nth-child(2){min-width:320px !important;}
th:nth-child(3),td:nth-child(3){min-width:220px !important;}
th:nth-child(7),td:nth-child(7){width:115px !important;min-width:115px !important;}
.namebox{
  max-width:360px !important;
  font-size:15px !important;
  font-weight:800 !important;
  letter-spacing:.01em !important;
}
.ipMacStack{
  display:flex;
  flex-direction:column;
  gap:5px;
  justify-content:center;
}
.ipMacStack .ipbox{
  max-width:190px !important;
  font-size:14px !important;
  font-weight:800 !important;
}
.ipMacSub{
  font-family:ui-monospace,SFMono-Regular,Menlo,monospace;
  font-size:11px;
  color:#8ea4c2;
  padding-left:2px;
  word-break:break-all;
  line-height:1.25;
}
body.theme-light .ipMacSub,body.theme-immortal .ipMacSub{color:#64748b !important;}
body.theme-light .namebox,body.theme-immortal .namebox{color:#111827 !important;}
body.theme-immortal .namebox{font-size:14px !important;font-weight:700 !important;}
td{vertical-align:middle !important;}
.stackCell{justify-content:center !important;}
.stateStack{justify-content:center !important;}
@media(max-width:900px){
  table{min-width:0 !important;}
  .namebox{max-width:100% !important;font-size:16px !important;}
  .ipMacStack .ipbox{max-width:100% !important;font-size:15px !important;}
  .ipMacSub{font-size:12px !important;margin-top:2px !important;}
  td{padding:8px 10px !important;}
}
/* end LanGuard mac under ip patch */
</style>
</head>
<body>
<div class="wrap">
  <div class="top">
    <div class="brand">
      <div class="logo">LG</div>
      <div>
        <h1>LanGuard Pro</h1>
        <div class="sub">Editable names, static IP, speed limit and data limit</div>
      </div>
    </div>

    <div class="headerMetrics">
      <div class="hm"><span>Realtime DL</span><b id="rtDl" class="cyan">0 KBps</b><small id="wanIface">wan</small></div>
      <div class="hm"><span>Realtime UL</span><b id="rtUl" class="amberText">0 KBps</b><small>WAN upload</small></div>
      <div class="hm"><span>All Devices Today</span><b id="useToday">0.00 GB</b><small>daily usage</small></div>
      <div class="hm"><span>All Devices Monthly</span><b id="useMonth">0.00 GB</b><small>monthly usage</small></div>
      <div class="hm"><span>All Devices Total</span><b id="useTotal">0.00 GB</b><small>since tracking</small></div>
    </div>

    <div class="topActions">
      <button class="btn" onclick="forceRefresh()">Refresh</button>
    </div>
  </div>

  <div class="stats">
    <div class="stat clickable active" id="totalCard" onclick="setFilter('all')"><span>Total</span><b id="total">0</b></div>
    <div class="stat clickable" id="onlineCard" onclick="setFilter('online')"><span>Online</span><b id="online" class="ok">0</b></div>
    <div class="stat clickable" id="offlineCard" onclick="setFilter('offline')"><span>Offline</span><b id="offline" class="bad">0</b></div>
    <div class="stat clickable" id="blockedCard" onclick="setFilter('blocked')"><span>Blocked</span><b id="blocked">0</b></div>
    <div class="stat clickable" id="tailscaleCard" onclick="setFilter('tailscale')"><span>Tailscale</span><b id="tailscale">0</b></div>
    <div class="stat clickable" id="deletedCard" onclick="showDeleted()"><span>Deleted</span><b id="deleted" class="deletedColor">0</b></div>
    <div class="stat"><span>WAN</span><b id="wan">...</b></div>
    <div class="stat clickable themeCard" id="themeCard"><span>Theme</span><b id="themeName">Light</b></div>
  </div>

  <div class="panel">
    <div class="toolbar">
      <input id="search" class="search" placeholder="Search device, IP, MAC, LAN or Tailscale..." oninput="renderRows()" onfocus="pauseEditing()" onblur="resumeEditingSoon()">
      <div class="modeBadge" id="modeBadge">All active devices</div>
      <div class="editBadge" id="editBadge">Editing: auto-refresh paused</div>
      <div class="notice" id="updated">Loading...</div>
    </div>
    <div class="tablewrap">
      <table>
        <thead>
          <tr>
            <th>State</th>
            <th>Device Name</th>
            <th>IP / MAC</th>
            <th>Limit</th>
            <th>Speed</th>
            <th>Usage</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody id="rows"></tbody>
      </table>
    </div>
  </div>

  <div class="footer">Per-device DL/UL live counters are based on router forwarding counters.</div>
</div>

<div class="modalBackdrop" id="limitModal">
  <div class="modal">
    <div class="modalTop">
      <div>
        <h2>Device Limits</h2>
        <div class="mSub" id="lmDevice">Device</div>
      </div>
      <button class="btn gray small" onclick="closeLimits()">Close</button>
    </div>

    <input type="hidden" id="lmMac">

    <div class="checkrow">
      <input type="checkbox" id="lmEnabled">
      <div>
        <b>Enable limits for this device</b>
        <div class="hint">Disable karne se speed/data rules remove ho jayen ge.</div>
      </div>
    </div>

    <div class="grid2">
      <div class="field"><label>Download KBps</label><input class="inputbox" id="lmDl" placeholder="0 = unlimited" inputmode="decimal"></div>
      <div class="field"><label>Upload KBps</label><input class="inputbox" id="lmUl" placeholder="0 = unlimited" inputmode="decimal"></div>
      <div class="field"><label>Monthly Data Limit GB</label><input class="inputbox" id="lmData" placeholder="0 = unlimited" inputmode="decimal"></div>
      <div class="field"><label>Current Usage GB</label><input class="inputbox" id="lmUsage" disabled></div>
    </div>

    <div class="hint">Example: Download 125, Upload 125 = approx 1 Mbps download/upload.</div>

    <div class="modalActions">
      <button class="btn green" onclick="saveLimits()">Save Limits</button>
      <button class="btn amber" onclick="resetUsage()">Reset Usage</button>
      <button class="btn red" onclick="clearLimits()">Clear Limit</button>
    </div>
  </div>
</div>

<script>
let devices = [];
let deletedMode = false;
let activeFilter = 'all';
let editing = false;
let resumeTimer = null;

function esc(s){return String(s ?? '').replace(/[&<>"']/g, m => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'}[m]));}
function enc(s){return encodeURIComponent(s || '');}
function speedFmt(k){k=Number(k||0); if(k>=1024) return (k/1024).toFixed(2)+' MBps'; return Math.round(k)+' KBps';}

function pauseEditing(){editing=true;clearTimeout(resumeTimer);const b=document.getElementById('editBadge');if(b)b.style.display='inline-block';}
function resumeEditingSoon(){clearTimeout(resumeTimer);resumeTimer=setTimeout(()=>{const a=document.activeElement;if(a&&(a.classList.contains('inputbox')||a.id==='search'))return;editing=false;const b=document.getElementById('editBadge');if(b)b.style.display='none';},2500);}
function finishEditing(){editing=false;clearTimeout(resumeTimer);const b=document.getElementById('editBadge');if(b)b.style.display='none';}

async function callAction(url){
  const join=url.includes('?')?'&':'?';
  const res=await fetch(url+join+'_='+Date.now());
  const txt=await res.text();
  if(txt.startsWith('ERR|')) alert(txt);
  finishEditing();
  await loadData(true);
  return txt;
}

async function saveDevice(mac,type){
  const id=mac.replaceAll(':','');
  const nameEl=document.getElementById('name_'+id);
  const ipEl=document.getElementById('ip_'+id);
  const name=nameEl?nameEl.value.trim():'';
  let ip='';
  if(type!=='TAILSCALE'&&ipEl){ip=ipEl.value.trim(); if(ip==='No IP') ip='';}
  await callAction('/cgi-bin/languard-action.sh?action=save&mac='+enc(mac)+'&name='+enc(name)+'&ip='+enc(ip));
}

async function blockDevice(mac){await callAction('/cgi-bin/languard-action.sh?action=block&mac='+enc(mac));}
async function unblockDevice(mac){await callAction('/cgi-bin/languard-action.sh?action=unblock&mac='+enc(mac));}
async function deleteDevice(mac){await callAction('/cgi-bin/languard-action.sh?action=delete&mac='+enc(mac));}
async function restoreDevice(mac){await callAction('/cgi-bin/languard-action.sh?action=restore&mac='+enc(mac));}

function findDevice(mac){return devices.find(x=>x.mac===mac);}

function openLimits(mac){
  const d=findDevice(mac); if(!d) return;
  pauseEditing();
  document.getElementById('lmMac').value=d.mac;
  document.getElementById('lmDevice').textContent=`${d.name} · ${d.ip} · ${d.type}`;
  document.getElementById('lmEnabled').checked=d.limEnabled==='1';
  document.getElementById('lmDl').value=d.limDl||'0';
  document.getElementById('lmUl').value=d.limUl||'0';
  document.getElementById('lmData').value=d.limData||'0';
  document.getElementById('lmUsage').value=d.monthlyGb||d.usageGb||'0.00';
  document.getElementById('limitModal').style.display='flex';
}

function closeLimits(){document.getElementById('limitModal').style.display='none';finishEditing();}

async function saveLimits(){
  const mac=document.getElementById('lmMac').value;
  const enabled=document.getElementById('lmEnabled').checked?'1':'0';
  const dl=document.getElementById('lmDl').value.trim()||'0';
  const ul=document.getElementById('lmUl').value.trim()||'0';
  const data=document.getElementById('lmData').value.trim()||'0';
  await callAction('/cgi-bin/languard-action.sh?action=limit_save&mac='+enc(mac)+'&enabled='+enc(enabled)+'&dl='+enc(dl)+'&ul='+enc(ul)+'&data='+enc(data));
  closeLimits();
}

async function clearLimits(){
  const mac=document.getElementById('lmMac').value;
  await callAction('/cgi-bin/languard-action.sh?action=limit_clear&mac='+enc(mac));
  closeLimits();
}

async function resetUsage(){
  const mac=document.getElementById('lmMac').value;
  await callAction('/cgi-bin/languard-action.sh?action=usage_reset&mac='+enc(mac));
  document.getElementById('lmUsage').value='0.00';
}

function clearFilterCards(){
  ['totalCard','onlineCard','offlineCard','blockedCard','tailscaleCard','deletedCard'].forEach(id=>{
    const el=document.getElementById(id); if(el) el.classList.remove('active');
  });
}

function setFilter(f){
  finishEditing();
  deletedMode=false;
  activeFilter=f||'all';
  clearFilterCards();
  const map={all:'totalCard',online:'onlineCard',offline:'offlineCard',blocked:'blockedCard',tailscale:'tailscaleCard'};
  const labels={all:'All active devices',online:'Online devices',offline:'Offline devices',blocked:'Blocked devices',tailscale:'Tailscale devices'};
  const card=document.getElementById(map[activeFilter]||'totalCard');
  if(card) card.classList.add('active');
  document.getElementById('modeBadge').textContent=labels[activeFilter]||'All active devices';
  loadData(true);
}

function showDeleted(){
  finishEditing();
  deletedMode=true;
  activeFilter='deleted';
  clearFilterCards();
  const card=document.getElementById('deletedCard'); if(card) card.classList.add('active');
  document.getElementById('modeBadge').textContent='Deleted devices';
  loadData(true);
}

function forceRefresh(){finishEditing();loadData(true);}

function renderRows(){
  const q=document.getElementById('search').value.toLowerCase().trim();
  const body=document.getElementById('rows');
  let html='';

  const filtered=devices.filter(d=>{
    const text=`${d.mac} ${d.ip} ${d.name} ${d.status} ${d.type} ${d.limitState}`.toLowerCase();
    const searchOk=!q||text.includes(q);
    let filterOk=true;

    if(!deletedMode){
      if(activeFilter==='online') filterOk=d.status==='ONLINE';
      else if(activeFilter==='offline') filterOk=d.status==='OFFLINE';
      else if(activeFilter==='blocked') filterOk=d.status==='BLOCKED';
      else if(activeFilter==='tailscale') filterOk=d.type==='TAILSCALE';
      else filterOk=true;
    }

    return searchOk&&filterOk;
  });

  filtered.sort((a,b)=>{
    const aTS=a.type==='TAILSCALE'?1:0;
    const bTS=b.type==='TAILSCALE'?1:0;

    if(aTS!==bTS) return aTS-bTS;

    if(aTS===0){
      const au=Number(a.monthlyGb||a.usageGb||0);
      const bu=Number(b.monthlyGb||b.usageGb||0);
      if(bu!==au) return bu-au;

      const ao=a.status==='ONLINE'?0:1;
      const bo=b.status==='ONLINE'?0:1;
      if(ao!==bo) return ao-bo;

      return String(a.name||'').localeCompare(String(b.name||''));
    }

    const ao=a.status==='ONLINE'?0:1;
    const bo=b.status==='ONLINE'?0:1;
    if(ao!==bo) return ao-bo;

    return String(a.name||'').localeCompare(String(b.name||''));
  });

  for(const d of filtered){
    const cls=d.status==='DELETED'?'deleted':(d.status==='BLOCKED'?'blocked':(d.status==='ONLINE'?'online':'offline'));
    const typeCls=d.type==='TAILSCALE'?'ts':'lan';
    const cleanId=d.mac.replaceAll(':','');
    const menuId='act_'+cleanId;
    const ipDisabled=d.type==='TAILSCALE'||deletedMode?'disabled':'';

    let limClass='off';
    let limText='OFF';
    if(d.limitState==='ON'){limClass='on';limText='ON';}
    if(d.limitState==='DATA_BLOCKED'){limClass='over';limText='DATA STOP';}

    let menuButtons='';

    if(deletedMode||d.status==='DELETED'){
      menuButtons=`<button class="btn small green" onclick="restoreDevice('${esc(d.mac)}')">Restore</button>`;
    }else{
      menuButtons=`<button class="btn small" onclick="saveDevice('${esc(d.mac)}','${esc(d.type)}')">Save</button>`;
      menuButtons+=`<button class="btn small amber" onclick="openLimits('${esc(d.mac)}')">Limits</button>`;

      if(d.type==='TAILSCALE'){
        menuButtons+=`<button class="btn small disabled" disabled>TS Device</button>`;
      }else{
        menuButtons+=d.status==='BLOCKED'
          ? `<button class="btn small green" onclick="unblockDevice('${esc(d.mac)}')">Unblock</button>`
          : `<button class="btn small red" onclick="blockDevice('${esc(d.mac)}')">Block</button>`;
      }

      menuButtons+=`<button class="btn small purple" onclick="deleteDevice('${esc(d.mac)}')">Delete</button>`;
    }

    html+=`
      <tr>
        <td data-label="State">
          <div class="stateStack">
            <span class="status ${cls}">${esc(d.status)}</span>
            <span class="type ${typeCls}">${esc(d.type)}</span>
          </div>
        </td>

        <td data-label="Device Name">
          <input class="inputbox namebox" id="name_${cleanId}" value="${esc(d.name)}" onfocus="pauseEditing()" oninput="pauseEditing()" onblur="resumeEditingSoon()" ${deletedMode?'disabled':''}>
        </td>

        <td data-label="IP / MAC">
          <div class="ipMacStack">
            <input class="inputbox ipbox" id="ip_${cleanId}" value="${esc(d.ip)}" onfocus="pauseEditing()" oninput="pauseEditing()" onblur="resumeEditingSoon()" ${ipDisabled}>
            <div class="ipMacSub">${esc(d.mac)}</div>
          </div>
        </td>

        <td data-label="Limit">
          <span class="limtag ${limClass}">${limText}</span>
        </td>

        <td data-label="Speed">
          <div class="stackCell">
            <div class="stackLine"><span class="stackLabel">DL</span><span class="stackValue dl">${speedFmt(d.rtDlKbs)}</span></div>
            <div class="stackLine"><span class="stackLabel">UL</span><span class="stackValue ul">${speedFmt(d.rtUlKbs)}</span></div>
          </div>
        </td>

        <td data-label="Usage">
          <div class="stackCell">
            <div class="stackLine"><span class="stackLabel">Daily</span><span class="stackValue daily">${esc(d.dailyGb)} GB</span></div>
            <div class="stackLine"><span class="stackLabel">Month</span><span class="stackValue monthly">${esc(d.monthlyGb)} GB</span></div>
            <div class="stackLine"><span class="stackLabel">Total</span><span class="stackValue total">${esc(d.totalGb)} GB</span></div>
          </div>
        </td>

        <td data-label="Actions">
          <div class="actions">
            <div class="actionMenuWrap">
              <button class="btn small gray actionMain" onclick="toggleActionMenu(event,'${menuId}')">Manage</button>
              <div class="actionMenu" id="${menuId}" onclick="event.stopPropagation()">
                ${menuButtons}
              </div>
            </div>
          </div>
        </td>
      </tr>`;
  }

  body.innerHTML=html||`<tr><td colspan="7">${deletedMode?'No deleted devices.':'No active devices found.'}</td></tr>`;
}
async function loadData(force=false){
  if(editing&&!force) return;
  const active=document.activeElement;
  if(!force&&active&&(active.classList.contains('inputbox')||active.id==='search')) return;

  const url=deletedMode?'/cgi-bin/dashboard-live-api.sh?view=deleted&_='+Date.now():'/cgi-bin/dashboard-live-api.sh?_='+Date.now();
  const r=await fetch(url);
  const t=await r.text();
  const lines=t.trim().split('\n').filter(Boolean);
  devices=[];

  for(const line of lines){
    const p=line.split('|');

    if(p[0]==='TOTAL'){
      document.getElementById('total').textContent=p[1]||'0';
      document.getElementById('online').textContent=p[2]||'0';
      document.getElementById('offline').textContent=p[3]||'0';
      document.getElementById('blocked').textContent=p[4]||'0';
      document.getElementById('tailscale').textContent=p[5]||'0';
      document.getElementById('wan').textContent=p[6]==='1'?'UP':'DOWN';
      document.getElementById('wan').className=p[6]==='1'?'ok':'bad';
      document.getElementById('deleted').textContent=p[8]||'0';
    }

    if(p[0]==='META'){
      document.getElementById('rtDl').textContent=speedFmt(p[1]);
      document.getElementById('rtUl').textContent=speedFmt(p[2]);
      document.getElementById('useToday').textContent=(p[3]||'0.00')+' GB';
      document.getElementById('useMonth').textContent=(p[4]||'0.00')+' GB';
      document.getElementById('useTotal').textContent=(p[5]||'0.00')+' GB';
      document.getElementById('wanIface').textContent=p[6]||'wan';
    }

    if(p[0]==='DEV'){
      devices.push({
        mac:p[1]||'',
        status:p[2]||'OFFLINE',
        ip:p[3]||'No IP',
        name:p[4]||p[1]||'Unknown',
        blocked:p[5]||'0',
        seen:p[6]||'0',
        type:p[7]||'LAN',
        deleted:p[8]||'0',
        limEnabled:p[9]||'0',
        limDl:p[10]||'0',
        limUl:p[11]||'0',
        limData:p[12]||'0',
        usageGb:p[13]||'0.00',
        limitState:p[14]||'OFF',
        dailyGb:p[15]||'0.00',
        monthlyGb:p[16]||p[13]||'0.00',
        totalGb:p[17]||'0.00',
        rtDlKbs:p[18]||'0',
        rtUlKbs:p[19]||'0'
      });
    }
  }

  document.getElementById('updated').textContent='Last updated: '+new Date().toLocaleTimeString();
  renderRows();
}

loadData(true);
setInterval(()=>loadData(false),3000);
// LanGuard professional themes start
(function(){
  const themes = [
    {id:'midnight', name:'Midnight'},
    {id:'emerald', name:'Emerald'},
    {id:'cyber', name:'Cyber'},
    {id:'purple', name:'Purple'},
    {id:'amber', name:'Amber'},
    {id:'slate', name:'Slate'},
    {id:'light', name:'Light'}
  ];

  function applyTheme(themeId){
    const found = themes.find(t => t.id === themeId) || themes[0];

    document.body.classList.remove(
      'theme-midnight',
      'theme-emerald',
      'theme-cyber',
      'theme-purple',
      'theme-amber',
      'theme-slate',
      'theme-light'
    );

    document.body.classList.add('theme-' + found.id);
    localStorage.setItem('lgTheme', found.id);

    const nameEl = document.getElementById('themeName');
    if(nameEl) nameEl.textContent = found.name;
  }

  function nextTheme(){
    const current = localStorage.getItem('lgTheme') || 'light';
    const index = themes.findIndex(t => t.id === current);
    const next = themes[(index + 1) % themes.length];
    applyTheme(next.id);
  }

  window.toggleTheme = nextTheme;
  window.applyTheme = applyTheme;

  function bindThemeButton(){
    const card = document.getElementById('themeCard');
    if(card){
      card.onclick = nextTheme;
      card.style.cursor = 'pointer';
    }
    applyTheme(localStorage.getItem('lgTheme') || 'light');
  }

  if(document.readyState === 'loading'){
    document.addEventListener('DOMContentLoaded', bindThemeButton);
  } else {
    bindThemeButton();
  }
})();
// LanGuard professional themes end
// LanGuard default light force start
(function(){
  const flag = 'lgLightDefaultAppliedV3';
  if(!localStorage.getItem(flag)){
    localStorage.setItem('lgTheme','light');
    localStorage.setItem(flag,'1');
  }
  if(window.applyTheme){
    window.applyTheme(localStorage.getItem('lgTheme') || 'light');
  }
})();
// LanGuard default light force end
// LanGuard actions dropdown start
function closeAllActionMenus(){
  document.querySelectorAll('.actionMenu.open').forEach(el => el.classList.remove('open'));
}

function toggleActionMenu(ev, id){
  if(ev) ev.stopPropagation();
  const menu = document.getElementById(id);
  if(!menu) return;

  const alreadyOpen = menu.classList.contains('open');
  closeAllActionMenus();

  if(!alreadyOpen){
    menu.classList.add('open');
  }
}

document.addEventListener('click', function(){
  closeAllActionMenus();
});
// LanGuard actions dropdown end
// LanGuard manage pause patch start
let actionMenuPause = false;

function isInputEditingNow(){
  const a = document.activeElement;
  return a && (a.classList.contains('inputbox') || a.id === 'search');
}

function resumeAfterManageClose(){
  if(isInputEditingNow()) return;

  actionMenuPause = false;
  editing = false;

  const b = document.getElementById('editBadge');
  if(b) b.style.display = 'none';
}

function closeAllActionMenus(){
  let hadOpen = false;

  document.querySelectorAll('.actionMenu.open').forEach(el => {
    hadOpen = true;
    el.classList.remove('open');
  });

  if(hadOpen && actionMenuPause){
    setTimeout(resumeAfterManageClose, 300);
  }
}

function toggleActionMenu(ev, id){
  if(ev) ev.stopPropagation();

  const menu = document.getElementById(id);
  if(!menu) return;

  const alreadyOpen = menu.classList.contains('open');

  closeAllActionMenus();

  if(alreadyOpen){
    resumeAfterManageClose();
    return;
  }

  actionMenuPause = true;
  pauseEditing();

  const b = document.getElementById('editBadge');
  if(b){
    b.style.display = 'inline-block';
    b.textContent = 'Manage menu open: auto-refresh paused';
  }

  menu.classList.add('open');
}

document.addEventListener('click', function(){
  closeAllActionMenus();
});
// LanGuard manage pause patch end
// LanGuard ImmortalWrt LuCI theme JS start
(function(){
  const themes = [
    {id:'immortal', name:'Immortal'},
    {id:'midnight', name:'Midnight'},
    {id:'emerald', name:'Emerald'},
    {id:'cyber', name:'Cyber'},
    {id:'purple', name:'Purple'},
    {id:'amber', name:'Amber'},
    {id:'slate', name:'Slate'},
    {id:'light', name:'Light'}
  ];

  function applyTheme(themeId){
    const found = themes.find(t => t.id === themeId) || themes[0];

    document.body.classList.remove(
      'theme-immortal',
      'theme-midnight',
      'theme-emerald',
      'theme-cyber',
      'theme-purple',
      'theme-amber',
      'theme-slate',
      'theme-light',
      'theme-green'
    );

    document.body.classList.add('theme-' + found.id);
    localStorage.setItem('lgTheme', found.id);

    const nameEl = document.getElementById('themeName');
    if(nameEl) nameEl.textContent = found.name;
  }

  function nextTheme(){
    const current = localStorage.getItem('lgTheme') || 'immortal';
    const index = themes.findIndex(t => t.id === current);
    const next = themes[(index + 1) % themes.length];
    applyTheme(next.id);
  }

  window.applyTheme = applyTheme;
  window.toggleTheme = nextTheme;

  function bindThemeButton(){
    const forceFlag = 'lgImmortalDefaultAppliedV1';

    if(!localStorage.getItem(forceFlag)){
      localStorage.setItem('lgTheme','immortal');
      localStorage.setItem(forceFlag,'1');
    }

    const card = document.getElementById('themeCard');
    if(card){
      card.onclick = function(ev){
        if(ev) ev.stopPropagation();
        nextTheme();
      };
      card.style.cursor = 'pointer';
    }

    applyTheme(localStorage.getItem('lgTheme') || 'immortal');
  }

  if(document.readyState === 'loading'){
    document.addEventListener('DOMContentLoaded', bindThemeButton);
  } else {
    bindThemeButton();
  }
})();
// LanGuard ImmortalWrt LuCI theme JS end
</script>
</body>
</html>
HTML

exit 0
