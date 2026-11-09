const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const root = process.cwd();
const docDir = path.join(root, 'docs/battle-core/pc-campaign-design');
const sourcePath = path.join(root, 'tmp/session-requirements-html-20261031/source-before.md');
const source = fs.readFileSync(sourcePath, 'utf8');
const categories = {W:'진행 방식·보존',D:'확정 설계 결정',I:'구현·검사 성과',G:'브랜치·푸시',P:'남은 기능·검증',C:'문서 관리'};
const items = source.split(/\r?\n/).filter(line => /^\| [WDIGPC]\d{2} \|/.test(line)).map(line => {
  const cells = line.split('|').slice(1,-1).map(cell=>cell.trim());
  if(cells.length !== 4) throw new Error('Unexpected table cells: '+line);
  return {id:cells[0], baselineStatus:cells[1], category:categories[cells[0][0]], requirement:cells[2], acceptance:cells[3]};
});
if(items.length !== 41 || new Set(items.map(x=>x.id)).size !== 41) throw new Error('Expected 41 unique source rows');
const baselineId = crypto.createHash('sha256').update(JSON.stringify(items)).digest('hex');
const sourceSha = crypto.createHash('sha256').update(source).digest('hex');
const data = {appId:'sbt-session-requirements',formatVersion:1,baselineDate:'2026-10-31',baselineId,sourceMarkdownSha256:sourceSha,overallReadiness:'NOT_READY',items};
const html = String.raw`<!doctype html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="light">
<title>세션 요구사항 관리 · 우주 삼국지</title>
<style>
:root{font-family:"Malgun Gothic","Apple SD Gothic Neo",system-ui,sans-serif;color:#17233a;background:#f4f6fb;font-synthesis:none;--blue:#2353b8;--border:#dce2ed;--muted:#5d687c;--green:#126348;--amber:#8a4e09}*{box-sizing:border-box}body{margin:0}button,input,select,textarea{font:inherit}button,select{cursor:pointer}button:focus-visible,a:focus-visible,input:focus-visible,select:focus-visible,textarea:focus-visible,summary:focus-visible{outline:3px solid #7da4fa;outline-offset:3px}a{color:#174ca7;text-decoration-thickness:1px;text-underline-offset:3px;overflow-wrap:anywhere}button{border:1px solid var(--border);border-radius:10px;background:#fff;color:#253753;min-height:42px;padding:9px 14px;font-weight:600}button:hover{background:#edf2fc}.primary{background:var(--blue);border-color:var(--blue);color:white}.primary:hover{background:#1c4295}.wrap{max-width:1240px;padding:32px 28px 60px;margin:auto}.eyebrow{margin:0 0 8px;font-size:12px;font-weight:700;letter-spacing:.06em;color:var(--blue)}h1{font-size:30px;letter-spacing:-.05em;margin:0 0 10px;line-height:1.3}.subtitle{color:var(--muted);margin:0;line-height:1.7;font-size:14px}.topline{display:flex;justify-content:space-between;align-items:flex-start;gap:24px}.backup-actions{display:flex;gap:8px;flex-wrap:wrap;justify-content:flex-end}.summary{margin:26px 0 20px;display:grid;grid-template-columns:minmax(0,1.45fr) minmax(0,1fr);gap:16px}.panel{background:white;border:1px solid var(--border);border-radius:16px;padding:21px 23px;box-shadow:0 3px 15px #24365304}.progress-head{display:flex;justify-content:space-between;gap:12px;align-items:center}.label{font-size:13px;font-weight:700;color:#40506b}.ratio{font-size:30px;font-weight:800;letter-spacing:-.04em}.ratio span{font-size:14px;font-weight:500;color:var(--muted);margin-left:6px}.progress{height:9px;background:#e7edf9;border-radius:30px;margin:15px 0 12px;overflow:hidden}.progress>div{height:100%;background:#456dcc;transition:width .15s}.small{font-size:12px;line-height:1.75;color:var(--muted);margin:0}.context-head{display:flex;align-items:center;justify-content:space-between;gap:10px;margin-bottom:10px}.not-ready{font-size:12px;font-weight:800;color:#8a3b10;background:#fff0e5;border:1px solid #f4d1b8;padding:5px 9px;border-radius:7px}.context-lines{display:flex;gap:7px 15px;flex-wrap:wrap;margin-bottom:8px;font-size:12px;color:#47566d}.context-lines code{font-size:12px;overflow-wrap:anywhere}.storage-row{display:flex;align-items:center;gap:8px;flex-wrap:wrap;border:1px solid #dbe4f1;background:#edf3fc;border-radius:10px;padding:10px 14px;margin:0 0 12px;font-size:12px;line-height:1.6;color:#375178}.storage-row.warning{background:#fff3e3;border-color:#efcb92;color:#7e4204}.dot{width:7px;height:7px;flex:none;border-radius:50%;background:#4d6fa9}.storage-row.warning .dot{background:#b36b0e}.notice{border-radius:10px;margin:0 0 12px;padding:11px 14px;font-size:13px;line-height:1.6;background:#e9f6ef;color:#11543f;border:1px solid #b7d8c8}.notice.error{background:#fff0ee;color:#9a2f29;border-color:#e7b7b0}.toolbar{position:sticky;top:0;z-index:3;background:#f4f6fbf5;padding:14px 0 16px;backdrop-filter:blur(10px)}.filter-row{display:flex;gap:8px;flex-wrap:wrap;margin-bottom:12px}.filter{font-size:13px;padding:8px 13px;min-height:39px;border-radius:30px;font-weight:600;display:inline-flex;align-items:center;gap:8px}.filter[aria-pressed="true"]{background:#263e6d;border-color:#263e6d;color:white}.filter .count{font-variant-numeric:tabular-nums;opacity:.8;font-size:12px}.controls{display:grid;grid-template-columns:minmax(180px,1fr) 185px auto;gap:10px;align-items:end}.control{display:flex;flex-direction:column;gap:5px}.control>label{font-size:12px;color:#536177;font-weight:600}.control input,.control select{width:100%;height:43px;border:1px solid #cfd8e7;border-radius:10px;background:white;color:#263753;padding:9px 12px;font-size:13px}.only-changed{display:flex;align-items:center;gap:7px;font-size:12px;white-space:nowrap;padding:12px 3px;min-height:43px;color:#526079}.only-changed input{width:16px;height:16px;accent-color:var(--blue)}.results-bar{display:flex;justify-content:space-between;align-items:center;gap:12px;font-size:12px;color:var(--muted);padding:4px 0 13px}.results-bar strong{color:#273a58}.cards{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:14px}.card{background:white;border:1px solid var(--border);border-radius:13px;padding:18px 20px;min-width:0;border-top:3px solid #d1d9e8}.card[data-current="완료"]{border-top-color:#77af9a}.card[data-current="미완료"]{border-top-color:#d6ac71}.card[data-current="상시준수"]{border-top-color:#9aaee1}.card-head{display:flex;justify-content:space-between;align-items:flex-start;gap:12px;margin-bottom:13px}.card h2{font-size:13px;font-weight:700;margin:0;display:flex;align-items:center;gap:9px;color:#40516d;line-height:1.5}.id{font-size:12px;letter-spacing:.02em;background:#eff2f7;padding:3px 7px;border-radius:5px;color:#2c4266}.status-edit{display:flex;gap:5px;flex-direction:column;align-items:flex-end;flex:none}.status-edit label{font-size:10px;color:#6b7587}.status-edit select{border:1px solid #cfd9e9;border-radius:7px;background:#f8faff;color:#344c76;padding:5px 6px;font-size:12px;min-height:32px}.requirement{font-size:13px;line-height:1.85;margin:0 0 12px;overflow-wrap:anywhere;word-break:keep-all}.requirement code,.acceptance code{font-size:.92em;background:#f1f3f8;border-radius:4px;padding:1px 4px;overflow-wrap:anywhere;word-break:break-all}.baseline{font-size:11px;color:#6f7887;display:flex;align-items:center;gap:8px;flex-wrap:wrap;margin:0 0 10px}.edited{font-size:10px;color:#3459a1;background:#edf2fd;padding:2px 6px;border-radius:4px}.card details{border-top:1px solid #ebedf3;padding-top:10px}.card summary{font-size:12px;color:#54637b;cursor:pointer;line-height:1.8}.card details[open] summary{margin-bottom:9px}.acceptance{font-size:12px;line-height:1.85;background:#f7f9fc;border-radius:8px;padding:11px 12px;margin:0 0 12px;overflow-wrap:anywhere;word-break:keep-all}.note-label{font-size:11px;font-weight:700;color:#59667b;display:block;margin-bottom:6px}.note{display:block;width:100%;resize:vertical;min-height:75px;border:1px solid #d6dfec;border-radius:8px;padding:9px 10px;font-size:12px;line-height:1.7;color:#263c5a;background:#fff}.note::placeholder{color:#8993a5}.empty{padding:55px 20px;background:white;border:1px dashed #c8d3e6;border-radius:14px;text-align:center;color:var(--muted);font-size:14px}.footer{border-top:1px solid var(--border);padding-top:17px;margin-top:25px;display:flex;justify-content:space-between;gap:14px;flex-wrap:wrap;font-size:11px;line-height:1.9;color:#6c7687}.sr-only{position:absolute;width:1px;height:1px;padding:0;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border:0}[hidden]{display:none!important}@media(max-width:760px){.wrap{padding:22px 17px 40px}.topline{display:block}h1{font-size:26px}.backup-actions{justify-content:flex-start;margin-top:16px}.summary{grid-template-columns:1fr;margin-top:21px;gap:11px}.panel{padding:18px}.cards{grid-template-columns:1fr}.controls{grid-template-columns:minmax(0,1fr) 150px}.only-changed{grid-column:1/-1;padding:0 2px;min-height:25px}.toolbar{padding-top:10px}.card{padding:16px 17px}.results-bar{align-items:flex-start}.filter{padding:7px 11px;font-size:12px;gap:6px;min-height:37px}}@media(max-width:380px){.wrap{padding:18px 12px 32px}.controls{grid-template-columns:1fr}.only-changed{grid-column:auto}.backup-actions{gap:6px}.backup-actions button{font-size:12px;padding:8px 11px}.filter-row{gap:5px}.filter{padding:7px 9px;font-size:11px;gap:5px}.panel{padding:15px}.card{padding:14px}.ratio{font-size:27px}.context-head{align-items:flex-start}.progress-head{align-items:flex-start}.card-head{gap:8px}.card h2{gap:6px;font-size:12px}}
</style>
</head>
<body>
<main class="wrap">
<header class="topline">
<div><p class="eyebrow">우주 삼국지 · 작업 관리</p><h1>세션 요구사항</h1><p class="subtitle">완료한 일과 남은 일을 근거와 함께 관리합니다.<br>기준 목록과 이 브라우저에서 바꾼 상태를 구분합니다.</p></div>
<div class="backup-actions"><button id="export-button" class="primary" type="button">백업 내보내기</button><button id="import-button" type="button">백업 가져오기</button><button id="text-backup-button" type="button">텍스트 백업</button><input id="import-file" type="file" accept="application/json,.json" hidden aria-label="요구사항 백업 JSON 파일"></div>
</header>
<section class="summary" aria-label="진행 요약">
<div class="panel"><div class="progress-head"><div><span class="label">기준 시점 일반 요구 32개 중 현재 완료</span><p class="small">기준 상시준수 9개는 상태를 바꿔도 계산에서 제외합니다.</p></div><div class="ratio"><b id="progress-number">23</b><span>/ 32</span></div></div><div class="progress" role="progressbar" aria-label="기준 일반 요구 완료율" aria-valuemin="0" aria-valuemax="32" aria-valuenow="23" id="progress-bar"><div id="progress-fill"></div></div><p class="small"><strong id="progress-percent">71.9%</strong> · 항목의 완료 표시는 아래 전체 준비 판정을 바꾸지 않습니다.</p></div>
<div class="panel"><div class="context-head"><span class="label">전체 I01b 준비 판정</span><span class="not-ready">NOT_READY</span></div><div class="context-lines"><span>P2b 부분 복원 구성요소 완료 · 미커밋</span><span>P2c 정식 계획·구현 미착수</span></div><p class="small">실제 host/replay·전체 저장/재개·제품 공간은 미완료입니다.<br><code>codex/feature-i01b-not_remove</code> · <code>fb660ce</code> 푸시 완료</p></div>
</section>
<div class="storage-row" id="storage-status" role="status" aria-live="polite"><span class="dot" aria-hidden="true"></span><span id="storage-text">브라우저 저장 상태를 확인하고 있습니다.</span></div>
<p class="small" style="margin-bottom:12px">기준 목록은 이 HTML에 담겨 있습니다. 편집은 이 브라우저·주소에 저장됩니다. 파일에 반영하려면 백업을 전달하세요. 가져오기는 검증 후 편집 전체를 교체합니다.</p>
<div id="transfer-message" class="notice" role="alert" hidden></div>
<section id="text-backup-panel" class="panel" style="margin-bottom:14px" hidden aria-label="텍스트 백업"><label for="text-backup" class="note-label">현재 상태·메모 JSON 백업</label><p class="small">아래 전체 내용을 복사해 UTF-8 .json 파일로 저장하세요. 다운로드가 차단되어도 이 내용으로 백업을 보관할 수 있습니다. 편집 후에는 다시 생성하세요.</p><textarea id="text-backup" class="note" rows="6" readonly spellcheck="false"></textarea><button id="select-backup-button" type="button" style="margin-top:8px">전체 선택</button></section>
<section class="toolbar" aria-label="요구사항 찾기">
<div class="filter-row" role="group" aria-label="상태 필터"><button type="button" class="filter" data-filter="전체" aria-pressed="true">전체 <span class="count" data-count="전체">41</span></button><button type="button" class="filter" data-filter="완료" aria-pressed="false">완료 <span class="count" data-count="완료">23</span></button><button type="button" class="filter" data-filter="미완료" aria-pressed="false">미완료 <span class="count" data-count="미완료">9</span></button><button type="button" class="filter" data-filter="상시준수" aria-pressed="false">상시준수 <span class="count" data-count="상시준수">9</span></button></div>
<div class="controls"><div class="control"><label for="search">검색</label><input id="search" type="search" placeholder="요구 ID, 내용, 근거, 메모 검색" autocomplete="off"></div><div class="control"><label for="category">분류</label><select id="category"><option value="">모든 분류</option></select></div><label class="only-changed"><input id="changed-only" type="checkbox">브라우저 변경만</label></div>
</section>
<div class="results-bar"><span><strong id="result-count">41개</strong> 표시</span><span id="edited-count">기준과 다른 편집 없음</span></div>
<section id="cards" class="cards" aria-label="요구사항 목록"></section>
<div class="empty" id="empty-state" hidden>조건에 맞는 요구사항이 없습니다. 검색어나 필터를 바꿔보세요.</div>
<footer class="footer"><span>기준: 2026-10-31 · 41개 요구 · 저장/재개 전체 완료와 구분</span><span><a href="SESSION-REQUIREMENTS-CHECKLIST-20261031.md">기준 시점 문서</a> · <a href="../CHECKLIST-OPEN.md">전체 작업 체크리스트</a></span></footer>
<p id="action-announcement" class="sr-only" role="status" aria-live="polite"></p>
</main>
<!-- Authoring source of truth: #requirements-data. Preserve all 41 IDs and evidence.
Browser overrides are local only; backup JSON must be reviewed to update this file.
The source Markdown is a preserved baseline reference, not the ongoing HTML authority. -->
<script id="requirements-data" type="application/json">REPLACE_DATA_BLOCK</script>
<script>
(function(){
'use strict';
const BASE = JSON.parse(document.getElementById('requirements-data').textContent);
const STATES = ['완료','미완료','상시준수'];
const MAX_NOTE = 4000, MAX_FILE_BYTES = 1048576;
const STORAGE_PREFIX = BASE.appId + ':v' + BASE.formatVersion + ':';
const STORAGE_KEY = STORAGE_PREFIX + BASE.baselineId;
const rows = BASE.items;
const byId = new Map(rows.map(function(item){return [item.id,item];}));
const progressIds = rows.filter(function(item){return item.baselineStatus !== '상시준수';}).map(function(item){return item.id;});
let edits = baselineEdits(), filter = '전체', lastSaved = '', storageMode = 'baseline', storageWarning = '', importSerial = 0;
const cards = document.getElementById('cards');
const storageStatus = document.getElementById('storage-status');
function baselineEdits(){return new Map(rows.map(function(item){return [item.id,{status:item.baselineStatus,note:''}];}));}
function object(value){return value !== null && typeof value === 'object' && !Array.isArray(value);}
function keys(value,expected){return object(value) && Object.keys(value).length === expected.length && expected.every(function(key){return Object.prototype.hasOwnProperty.call(value,key);});}
function validateBackup(value){
 if(!keys(value,['appId','formatVersion','baselineId','exportedAt','items'])) throw new Error('백업 파일의 필드 구성이 올바르지 않습니다.');
 if(value.appId !== BASE.appId || value.formatVersion !== BASE.formatVersion) throw new Error('이 관리 화면의 백업 형식·버전이 아닙니다.');
 if(value.baselineId !== BASE.baselineId) throw new Error('다른 기준 목록의 백업입니다. 현재 목록에 자동 적용하지 않았습니다.');
 if(typeof value.exportedAt !== 'string' || value.exportedAt.length > 40 || !/^\d{4}-\d\d-\d\dT/.test(value.exportedAt) || !Number.isFinite(Date.parse(value.exportedAt))) throw new Error('백업 시각의 형식이 올바르지 않습니다.');
 if(!Array.isArray(value.items) || value.items.length !== rows.length) throw new Error('41개 요구 항목이 모두 들어 있어야 합니다.');
 const next = new Map();
 value.items.forEach(function(item){
  if(!keys(item,['id','status','note']) || typeof item.id !== 'string' || !byId.has(item.id) || next.has(item.id)) throw new Error('요구 ID가 중복됐거나 알 수 없는 항목이 있습니다.');
  if(typeof item.status !== 'string' || !STATES.includes(item.status)) throw new Error('허용되지 않은 상태가 있습니다.');
  if(typeof item.note !== 'string' || item.note.length > MAX_NOTE) throw new Error('메모는 항목당 4,000자 이내의 문자열이어야 합니다.');
  next.set(item.id,{status:item.status,note:item.note});
 });
 if(next.size !== byId.size) throw new Error('누락된 요구 ID가 있습니다.');
 return new Map(rows.map(function(item){return [item.id,next.get(item.id)];}));
}
function backup(){return {appId:BASE.appId,formatVersion:BASE.formatVersion,baselineId:BASE.baselineId,exportedAt:new Date().toISOString(),items:rows.map(function(item){const value=edits.get(item.id);return {id:item.id,status:value.status,note:value.note};})};}
function notice(message,error){const node=document.getElementById('transfer-message');node.textContent=message;node.classList.toggle('error',!!error);node.hidden=false;}
function showStorage(){
 let text = '기준 상태 · 아직 브라우저 편집이 없습니다.';
 if(storageMode === 'saved') text='이 브라우저에 저장됨 · '+lastSaved;
 if(storageMode === 'unsaved') text='저장 안 됨 · 현재 편집은 화면에만 있습니다. 새로고침하면 잃을 수 있으니 백업을 내보내세요.';
 if(storageMode === 'invalid') text='기존 브라우저 저장을 적용하지 못했습니다. 기준 목록을 표시합니다. '+storageWarning;
 if(storageMode === 'other') text='다른 기준 목록의 저장 내용은 자동 적용하지 않았습니다. 필요한 백업은 직접 가져오세요.';
 document.getElementById('storage-text').textContent=text;
 storageStatus.classList.toggle('warning',['unsaved','invalid','other'].includes(storageMode));
}
function persist(){
 try{localStorage.setItem(STORAGE_KEY,JSON.stringify(backup()));lastSaved=new Date().toLocaleTimeString('ko-KR');storageMode='saved';showStorage();return true;}
 catch(error){storageMode='unsaved';showStorage();return false;}
}
function load(){
 try{
  const raw=localStorage.getItem(STORAGE_KEY);
  if(raw !== null){
   if(raw.length > MAX_FILE_BYTES) throw new Error('기존 저장 내용이 너무 큽니다.');
   edits=validateBackup(JSON.parse(raw));storageMode='saved';lastSaved='이전 편집 복원';
  }else{
   for(let i=0;i<localStorage.length;i++){const key=localStorage.key(i);if(key && key.startsWith(STORAGE_PREFIX) && key!==STORAGE_KEY){storageMode='other';break;}}
  }
 }catch(error){storageMode='invalid';storageWarning='변경 사항은 백업 파일로 관리하세요.';}
 showStorage();
}
const safeTargets = new Set();
rows.forEach(function(item){[item.requirement,item.acceptance].forEach(function(text){const re=/\[([^\]]+)\]\(([^)]+)\)/g;let match;while((match=re.exec(text))){const target=match[2];if(!/^[a-z][a-z0-9+.-]*:/i.test(target) && !target.startsWith('//') && !target.startsWith('/') && !target.includes('\\'))safeTargets.add(target);}});});
function rich(text){
 const frag=document.createDocumentFragment();
 const re=/\[([^\]]+)\]\(([^)]+)\)|\x60([^\x60]+)\x60/g;let last=0,match;
 while((match=re.exec(text))){
  frag.appendChild(document.createTextNode(text.slice(last,match.index)));
  if(match[3]!==undefined){const code=document.createElement('code');code.textContent=match[3];frag.appendChild(code);}
  else if(safeTargets.has(match[2])){const link=document.createElement('a');link.textContent=match[1];link.setAttribute('href',match[2]);link.target='_blank';link.rel='noopener';frag.appendChild(link);}
  else frag.appendChild(document.createTextNode(match[0]));
  last=re.lastIndex;
 }
 frag.appendChild(document.createTextNode(text.slice(last)));return frag;
}
function changed(item){const value=edits.get(item.id);return value.status!==item.baselineStatus || value.note!=='';}
function updateSummary(){
 const counts={'전체':rows.length,'완료':0,'미완료':0,'상시준수':0};let changedCount=0;
 rows.forEach(function(item){counts[edits.get(item.id).status]++;if(changed(item))changedCount++;});
 document.querySelectorAll('[data-count]').forEach(function(node){node.textContent=counts[node.dataset.count];});
 const done=progressIds.filter(function(id){return edits.get(id).status==='완료';}).length;
 document.getElementById('progress-number').textContent=done;
 document.getElementById('progress-percent').textContent=(done/progressIds.length*100).toFixed(1)+'%';
 document.getElementById('progress-fill').style.width=(done/progressIds.length*100)+'%';
 document.getElementById('progress-bar').setAttribute('aria-valuenow',String(done));
 document.getElementById('edited-count').textContent=changedCount ? '브라우저 변경 '+changedCount+'개' : '기준과 다른 편집 없음';
}
function render(){
 updateSummary();
 const query=document.getElementById('search').value.trim().toLocaleLowerCase('ko-KR').split(/\s+/).filter(Boolean);
 const category=document.getElementById('category').value;
 const onlyChanged=document.getElementById('changed-only').checked;
 const visible=rows.filter(function(item){const value=edits.get(item.id);const haystack=[item.id,item.category,item.requirement,item.acceptance,value.note,value.status].join(' ').toLocaleLowerCase('ko-KR');return (filter==='전체'||filter===value.status)&&(!category||category===item.category)&&(!onlyChanged||changed(item))&&query.every(function(word){return haystack.includes(word);});});
 cards.replaceChildren();
 visible.forEach(function(item){
  const value=edits.get(item.id);const card=document.createElement('article');card.className='card';card.dataset.id=item.id;card.dataset.current=value.status;
  const head=document.createElement('div');head.className='card-head';
  const title=document.createElement('h2');const id=document.createElement('span');id.className='id';id.textContent=item.id;title.append(id,document.createTextNode(item.category));head.appendChild(title);
  const editor=document.createElement('div');editor.className='status-edit';const label=document.createElement('label');label.htmlFor='status-'+item.id;label.textContent='상태';
  const select=document.createElement('select');select.id='status-'+item.id;select.dataset.statusId=item.id;select.setAttribute('aria-label',item.id+' 상태');STATES.forEach(function(status){const option=document.createElement('option');option.value=status;option.textContent=status;select.appendChild(option);});select.value=value.status;editor.append(label,select);head.appendChild(editor);
  const text=document.createElement('p');text.className='requirement';text.appendChild(rich(item.requirement));
  const baseline=document.createElement('div');baseline.className='baseline';baseline.appendChild(document.createTextNode('기준 상태: '+item.baselineStatus));if(changed(item)){const badge=document.createElement('span');badge.className='edited';badge.textContent='브라우저 변경';baseline.appendChild(badge);}
  const details=document.createElement('details');const summary=document.createElement('summary');summary.textContent='완료 기준·다음 적용'+(value.note?' · 메모 있음':'');
  const acceptance=document.createElement('p');acceptance.className='acceptance';acceptance.appendChild(rich(item.acceptance));
  const noteLabel=document.createElement('label');noteLabel.className='note-label';noteLabel.htmlFor='note-'+item.id;noteLabel.textContent=item.id+' 메모';const note=document.createElement('textarea');note.className='note';note.id='note-'+item.id;note.dataset.noteId=item.id;note.maxLength=MAX_NOTE;note.rows=3;note.placeholder='현재 진행 내용이나 확인할 근거를 남기세요.';note.value=value.note;
  details.append(summary,acceptance,noteLabel,note);card.append(head,text,baseline,details);cards.appendChild(card);
 });
 document.getElementById('result-count').textContent=visible.length+'개 / 전체 '+rows.length+'개';
 document.getElementById('empty-state').hidden=visible.length!==0;
}
rows.map(function(item){return item.category;}).filter(function(value,index,array){return array.indexOf(value)===index;}).forEach(function(category){const option=document.createElement('option');option.value=category;option.textContent=category;document.getElementById('category').appendChild(option);});
document.querySelectorAll('[data-filter]').forEach(function(button){button.addEventListener('click',function(){filter=button.dataset.filter;document.querySelectorAll('[data-filter]').forEach(function(other){other.setAttribute('aria-pressed',String(other===button));});render();});});
['search','category','changed-only'].forEach(function(id){document.getElementById(id).addEventListener(id==='search'?'input':'change',render);});
cards.addEventListener('change',function(event){const node=event.target;if(!node.matches('[data-status-id]'))return;const id=node.dataset.statusId;if(!byId.has(id)||!STATES.includes(node.value))return;edits.set(id,{status:node.value,note:edits.get(id).note});persist();render();document.getElementById('action-announcement').textContent=id+' 상태를 변경했습니다.';});
cards.addEventListener('input',function(event){const node=event.target;if(!node.matches('[data-note-id]'))return;const id=node.dataset.noteId;if(!byId.has(id))return;const note=node.value.slice(0,MAX_NOTE);if(node.value!==note)node.value=note;edits.set(id,{status:edits.get(id).status,note:note});persist();updateSummary();const card=node.closest('article');const baseline=card.querySelector('.baseline');let badge=baseline.querySelector('.edited');if(changed(byId.get(id))&&!badge){badge=document.createElement('span');badge.className='edited';badge.textContent='브라우저 변경';baseline.appendChild(badge);}if(!changed(byId.get(id))&&badge)badge.remove();card.querySelector('summary').textContent='완료 기준·다음 적용'+(note?' · 메모 있음':'');});
function textBackup(){const text=JSON.stringify(backup(),null,2);document.getElementById('text-backup').value=text;document.getElementById('text-backup-panel').hidden=false;return text;}
document.getElementById('text-backup-button').addEventListener('click',function(){textBackup();document.getElementById('text-backup').focus();notice('현재 상태의 JSON을 생성했습니다. 전체 내용을 복사해 .json 파일로 저장하세요.',false);});
document.getElementById('select-backup-button').addEventListener('click',function(){const node=document.getElementById('text-backup');node.focus();node.select();});
document.getElementById('export-button').addEventListener('click',function(){const blob=new Blob([textBackup()],{type:'application/json;charset=utf-8'});const url=URL.createObjectURL(blob);const link=document.createElement('a');link.href=url;link.download='session-requirements-backup-'+new Date().toISOString().slice(0,10)+'.json';document.body.appendChild(link);link.click();link.remove();setTimeout(function(){URL.revokeObjectURL(url);},1000);notice('백업 다운로드를 요청했습니다. 저장된 파일을 확인하세요. 다운로드가 안 되면 아래 JSON 전체를 복사해 .json 파일로 저장하세요.',false);});
document.getElementById('import-button').addEventListener('click',function(){document.getElementById('import-file').click();});
document.getElementById('import-file').addEventListener('change',async function(event){const file=event.target.files[0];if(!file)return;const serial=++importSerial;try{if(file.size>MAX_FILE_BYTES)throw new Error('백업 파일은 1MB 이하여야 합니다.');const raw=await file.text();const next=validateBackup(JSON.parse(raw));if(serial!==importSerial)return;edits=next;const saved=persist();render();notice(saved?'백업을 가져와 이 브라우저에 저장했습니다.':'백업은 적용했지만 브라우저에 저장하지 못했습니다. 현재 편집을 다시 내보내 보관하세요.',!saved);}catch(error){if(serial===importSerial)notice('가져오지 않았습니다. '+(error instanceof SyntaxError?'JSON 문법을 확인하세요.':error.message),true);}finally{if(serial===importSerial)event.target.value='';}});
load();render();
})();
</script>
</body>
</html>
`;
const json = JSON.stringify(data).replace(/</g,'\\u003c').replace(/\u2028/g,'\\u2028').replace(/\u2029/g,'\\u2029');
const target = path.join(docDir,'SESSION-REQUIREMENTS-CHECKLIST-20261031.html');
fs.writeFileSync(target,html.replace('REPLACE_DATA_BLOCK',json),'utf8');
fs.writeFileSync(path.join(root,'tmp/session-requirements-html-20261031/baseline-data.json'),JSON.stringify(data,null,2),'utf8');
console.log(JSON.stringify({target,items:items.length,baselineId,sourceSha,bytes:fs.statSync(target).size}));