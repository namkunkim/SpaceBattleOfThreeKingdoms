const fs=require('fs'),path=require('path');
const p=path.join(__dirname,'prepare.cjs');let s=fs.readFileSync(p,'utf8');
s=s.replace("name.includes('·')?name.split('·'): [name]","name.includes('·')&&!name.includes('(')?name.split('·'): [name]");
const start=s.indexOf('const seen=new Map()'),end=s.indexOf('const female=',start);
s=s.slice(0,start)+"const seen=new Map(),duplicates=[];const unique=records.filter(o=>{const k=o.name+'|'+o.faction;if(o.tier==='F'&&['여개','왕항'].includes(o.name)){duplicates.push({name:o.name,removed:o.source,reason:'Same Shu officer already included'});return false;}if(seen.has(k)){duplicates.push({name:o.name,removed:o.source});return false;}seen.set(k,o);return true;});\n"+s.slice(end);
fs.writeFileSync(p,s);
