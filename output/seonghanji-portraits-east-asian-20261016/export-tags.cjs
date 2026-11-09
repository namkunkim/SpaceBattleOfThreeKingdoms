const fs=require('fs'),path=require('path');const dir=__dirname,m=JSON.parse(fs.readFileSync(path.join(dir,'manifest.json'),'utf8'));
const tags=m.records.map(r=>({id:r.id,name:r.name,faction:r.faction,role:r.role,tags:r.tags,image:'images/'+r.filename,status:r.status,width:r.targetWidth,height:r.targetHeight,visualCasting:r.visualCasting?.label||'',fictionalAppearance:true,source:r.source,sourceLine:r.line}));
fs.writeFileSync(path.join(dir,'tags.json'),JSON.stringify(tags,null,2));
const columns=['id','name','faction','role','tags','image','status','width','height','visualCasting','fictionalAppearance','source','sourceLine'];const q=x=>'"'+String(x??'').replace(/"/g,'""')+'"';
fs.writeFileSync(path.join(dir,'tags.csv'),'\ufeff'+[columns.join(','),...tags.map(r=>columns.map(k=>q(Array.isArray(r[k])?r[k].join(';'):r[k])).join(','))].join('\r\n'));
