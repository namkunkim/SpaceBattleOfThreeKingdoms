const fs=require('fs'),path=require('path'),cp=require('child_process');const dir=__dirname,mp=path.join(dir,'manifest.json'),qp=path.join(dir,'western-revision.json');
const [id,source]=process.argv.slice(2),q=JSON.parse(fs.readFileSync(qp)),m=JSON.parse(fs.readFileSync(mp)),v=q.records.find(x=>x.id===id),r=m.records.find(x=>x.id===id);if(!v||!r||v.status!=='pending')throw Error('Revision state');
if(!fs.existsSync(path.join(dir,'images',v.filename)))throw Error('Resize replacement first');
r.supersededPortraits=[...(r.supersededPortraits||[]),{file:'images/'+r.filename,prompt:r.prompt,visualCasting:r.visualCasting,generatedSource:r.generatedSource,sha256:r.sha256,reason:q.reason}];
Object.assign(r,{filename:v.filename,prompt:v.prompt,castingSpec:v.castingSpec,visualCasting:v.visualCasting,tags:v.tags});delete r.sha256;delete r.bytes;
m.imageSpecification.castingBalance={requestedOn:'2026-10-18',eastAsian:488,westernMediterranean:6,arab:7,scope:'Western-region faction only; creative fictional casting'};
fs.writeFileSync(mp,JSON.stringify(m,null,2));fs.writeFileSync(path.join(dir,'prompts.jsonl'),m.records.map(r=>JSON.stringify({id:r.id,name:r.name,prompt:r.prompt})).join('\n'));
console.log(cp.execFileSync(process.execPath,[path.join(dir,'save-result.cjs'),id,source],{encoding:'utf8'}).trim());
v.status='generated';v.generatedSource=source;fs.writeFileSync(qp,JSON.stringify(q,null,2));console.log('Western replacements: '+q.records.filter(r=>r.status==='generated').length+'/13');
