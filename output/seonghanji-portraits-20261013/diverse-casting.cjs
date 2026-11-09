const fs=require('fs'),path=require('path');const p=path.join(__dirname,'manifest.json'),m=JSON.parse(fs.readFileSync(p,'utf8'));
const castings=[
 ['동아시아계','East Asian human, medium-light skin'],
 ['아프리카계','Black human of African descent, deep brown skin'],
 ['남아시아계','South Asian human, warm brown skin'],
 ['유럽계','White human of European descent, fair skin'],
 ['동남아시아계','Southeast Asian human, tan skin'],
 ['중동·북아프리카계','Middle Eastern or North African human, olive skin'],
 ['라틴아메리카계','Latino human with mixed heritage, medium brown skin'],
 ['태평양제도계','Pacific Islander human, warm tan-brown skin'],
 ['북미원주민계','Indigenous North American human, medium copper-brown skin'],
 ['혼혈','human with mixed African and East Asian heritage, medium-dark skin']
];
for(let i=0;i<m.records.length;i++){
 const r=m.records[i];if(r.status!=='pending'){r.visualCasting={label:'동아시아계',fictionalInterpretation:true};continue;}
 const c=castings[(i*7+3)%castings.length];r.visualCasting={label:c[0],description:c[1],fictionalInterpretation:true};
 r.prompt=r.prompt.replace('East or Central Asian human appearance appropriate to the named person',c[1]).replace('culturally appropriate Mediterranean, West Asian or South Asian human appearance according to this named historical person',c[1]);
 r.prompt+=` Multiethnic SF casting direction: ${c[1]}. Historical name and documented gameplay role are retained, while ancestry is a fictional future-world visual reinterpretation. Distinct respectful natural human face, no ethnic caricatures, no ethnic costumes or stereotypes. Characters of every background can hold any faction, authority level or role.`;
 r.tags=[...r.tags.filter(t=>!castings.some(c=>c[0]===t)),c[0]];
}
m.imageSpecification.diverseHumanCasting=true;m.imageSpecification.ancestryIsFictionalInterpretation=true;
fs.writeFileSync(p,JSON.stringify(m,null,2));fs.writeFileSync(path.join(__dirname,'prompts.jsonl'),m.records.map(r=>JSON.stringify({id:r.id,name:r.name,prompt:r.prompt})).join('\n'));
require('./export-tags.cjs');
console.log(JSON.stringify({completed:m.records.filter(r=>r.status==='generated').length,total:m.total,pending:m.records.filter(r=>r.status==='pending').length,castings:castings.map(c=>c[0])}));
