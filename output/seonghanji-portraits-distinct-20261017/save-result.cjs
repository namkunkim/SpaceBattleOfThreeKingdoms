const fs=require('fs'),path=require('path');
const dir=__dirname,mp=path.join(dir,'manifest.json'),m=JSON.parse(fs.readFileSync(mp,'utf8'));
const [id,source]=process.argv.slice(2),r=m.records.find(x=>x.id===id);if(!r)throw Error('Unknown id');
const dest=path.join(dir,'images',r.filename);if(!fs.existsSync(dest))throw Error('Missing image; run resize.ps1 before registering');
r.status='generated';r.generator='built-in image_gen';r.generatedSource=source||r.generatedSource;r.bytes=fs.statSync(dest).size;
fs.writeFileSync(mp,JSON.stringify(m,null,2));
require('./export-tags.cjs');
const esc=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const completed=m.records.filter(x=>x.status==='generated');
fs.writeFileSync(path.join(dir,'generation-status.json'),JSON.stringify({status:completed.length===m.total?'complete':'in_progress',completed:completed.length,total:m.total,remaining:m.total-completed.length,lastCompletedId:r.id,lastCompletedName:r.name,nextId:m.records.find(x=>x.status==='pending')?.id||null,casting:Object.fromEntries([...new Set(m.records.map(x=>x.visualCasting.label))].map(label=>[label,m.records.filter(x=>x.visualCasting.label===label).length])),width:561,height:701,textInPortraits:false,metadataFiles:['tags.json','tags.csv'],generator:'built-in image_gen'},null,2));
const cards=completed.map(x=>`<article data-search="${esc(x.tags.join(' '))}"><img loading="lazy" src="images/${encodeURIComponent(x.filename)}" alt="${esc(x.name)}"><h2>${esc(x.name)}</h2><p>${esc(x.faction)} · ${esc(x.role)}</p><small>${esc(x.tags.map(t=>'#'+t).join(' '))}</small></article>`).join('');
fs.writeFileSync(path.join(dir,'index.html'),`<!doctype html><html lang="ko"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>성한지 장수 초상</title><style>body{background:#09141b;color:#d9e7ee;font:16px system-ui;margin:32px}input{width:min(700px,90%);padding:12px;background:#182a34;color:white;border:1px solid #526d7b}main{display:grid;grid-template-columns:repeat(auto-fill,minmax(250px,1fr));gap:20px;margin-top:24px}article{background:#12212a;padding:12px;border:1px solid #3d5865}img{width:100%;height:auto}h2{margin:12px 0 4px}p,small{color:#9cbbc9}[hidden]{display:none}</style><h1>성한지 장수 초상</h1><p>생성 완료 ${completed.length} / ${m.total}명 · 이름·소속·역할·ID로 검색</p><input aria-label="장수 검색" placeholder="장수 이름 또는 태그 검색" oninput="document.querySelectorAll('article').forEach(e=>e.hidden=!e.dataset.search.toLowerCase().includes(this.value.toLowerCase()))"><main>${cards}</main></html>`);
const revised=completed.filter(x=>x.filename.endsWith('-western-v2.png'));
if(revised.length){const gallery=path.join(dir,'index.html');fs.writeFileSync(gallery,fs.readFileSync(gallery,'utf8').replace('</h1>',`</h1><p>서방권 새 초상 ${revised.length}/13명 반영 · 서구·지중해계 / 아랍계 · 목록에서 ‘서방’으로 검색</p>`));}
console.log(`${r.id} ${r.name} saved; ${completed.length}/${m.total}`);
