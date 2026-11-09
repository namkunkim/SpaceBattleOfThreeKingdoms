const fs=require('fs'),path=require('path');
const p=path.join(__dirname,'manifest.json'),m=JSON.parse(fs.readFileSync(p,'utf8'));let changed=0,rework=[];
for(const r of m.records){
 const v=r.visualCasting;if(r.prompt.includes('East Asian woman,')||v.age>=55||!v.faceDesign.includes('long straight white beard without moustache'))continue;
 const face=v.faceDesign.replace('long straight white beard without moustache','short neatly trimmed black chin beard without moustache');
 if(r.status==='generated'){
  r.supersededPortraits=[...(r.supersededPortraits||[]),{file:'images/'+r.filename,prompt:r.prompt,reason:'Align beard colour and neat length with youthful casting'}];
  r.filename=r.id+'-v2.png';r.status='pending';delete r.generatedSource;delete r.generator;delete r.bytes;rework.push(r.id);
 }
 r.prompt=r.prompt.replace(v.faceDesign,face);r.castingSpec=face;v.faceDesign=face;changed++;
}
fs.writeFileSync(p,JSON.stringify(m,null,2));fs.writeFileSync(path.join(__dirname,'prompts.jsonl'),m.records.map(r=>JSON.stringify({id:r.id,name:r.name,prompt:r.prompt})).join('\n'));require('./export-tags.cjs');
console.log(JSON.stringify({changed,rework,completed:m.records.filter(r=>r.status==='generated').length,total:m.total}));
