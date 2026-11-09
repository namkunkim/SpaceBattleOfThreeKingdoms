const fs=require('fs'),path=require('path');
const p=path.join(__dirname,'manifest.json'),m=JSON.parse(fs.readFileSync(p,'utf8'));
const choices=[['동아시아계','East Asian human, medium-light skin'],['유럽계','Western European human, fair skin'],['동남아시아계','Southeast Asian human, tan skin']];
const labels=['동아시아계','아프리카계','남아시아계','유럽계','동남아시아계','중동·북아프리카계','라틴아메리카계','태평양제도계','북미원주민계','혼혈'];
let i=0;
for(const r of m.records){
 if(r.status!=='pending')continue;
 const slot=(i++*7)%20,c=choices[slot<11?0:slot<19?1:2];
 const old=r.visualCasting?.description;
 if(!old||!r.prompt.includes(old))throw Error('Missing casting description: '+r.id);
 r.prompt=r.prompt.split(old).join(c[1]);
 r.visualCasting={label:c[0],description:c[1],fictionalInterpretation:true};
 r.tags=[...r.tags.filter(t=>!labels.includes(t)),c[0]];
}
m.imageSpecification.castingBalance={requestedOn:'2026-10-16',pendingAllocation:'55% East Asian, 40% Western European, 5% Southeast Asian; retain completed portraits',blackMinority:true};
fs.writeFileSync(p,JSON.stringify(m,null,2));
fs.writeFileSync(path.join(__dirname,'prompts.jsonl'),m.records.map(r=>JSON.stringify({id:r.id,name:r.name,prompt:r.prompt})).join('\n'));
require('./export-tags.cjs');
const counts={};for(const r of m.records){const k=r.visualCasting?.label||'unspecified';counts[k]=(counts[k]||0)+1;}
console.log(JSON.stringify({pendingUpdated:i,counts}));
