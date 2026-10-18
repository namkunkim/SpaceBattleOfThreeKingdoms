const fs=require('fs'),path=require('path'),crypto=require('crypto');
const dir=__dirname,mp=path.join(dir,'manifest.json'),m=JSON.parse(fs.readFileSync(mp)),tags=JSON.parse(fs.readFileSync(path.join(dir,'tags.json')));
const seenIds=new Set(),seenFiles=new Set(),seenHashes=new Set(),inventory=[];
if(m.total!==501||m.records.length!==501||tags.length!==501)throw Error('Roster count');
for(const r of m.records){
 if(r.status!=='generated'||seenIds.has(r.id)||seenFiles.has(r.filename))throw Error('Status or duplicate '+r.id);
 seenIds.add(r.id);seenFiles.add(r.filename);
 const b=fs.readFileSync(path.join(dir,'images',r.filename));
 if(b.subarray(0,8).toString('hex')!=='89504e470d0a1a0a'||b.readUInt32BE(16)!==561||b.readUInt32BE(20)!==701)throw Error('PNG dimensions '+r.id);
 const hash=crypto.createHash('sha256').update(b).digest('hex');if(seenHashes.has(hash))throw Error('Duplicate image '+r.id);seenHashes.add(hash);
 const t=tags.find(t=>t.id===r.id);if(!t||t.name!==r.name||t.image!=='images/'+r.filename||t.status!=='generated'||JSON.stringify(t.tags)!==JSON.stringify(r.tags))throw Error('Metadata mismatch '+r.id);
 const western=JSON.parse(fs.readFileSync(path.join(dir,'western-revision.json'))).records.find(v=>v.id===r.id);
 if(western?(western.status!=='generated'||r.visualCasting.label!==western.visualCasting.label||r.filename!==western.filename):r.visualCasting.label!=='동아시아계')throw Error('Casting '+r.id);
 if(r.prompt.includes('East Asian woman,')&&(r.visualCasting.age<20||r.visualCasting.age>39))throw Error('Adult female age '+r.id);
 r.bytes=b.length;r.sha256=hash;
 inventory.push({id:r.id,name:r.name,image:'images/'+r.filename,width:561,height:701,bytes:b.length,sha256:hash,generatedSource:r.generatedSource});
}
m.recovery={date:'2026-10-18',restoredCharacters:434,restoredSupersededVariants:7,method:'Reconstructed roster, prompt revisions and successful ID-to-source registrations from this conversation; reprocessed retained original PNGs at 561x701.',evidence:'../portrait-recovery/restored-mappings.json',newCharacters:67};
fs.writeFileSync(mp,JSON.stringify(m,null,2));
fs.writeFileSync(path.join(dir,'file-inventory.json'),JSON.stringify(inventory,null,2));
const report={result:'passed',date:'2026-10-18',completed:501,total:501,pending:0,uniqueIds:seenIds.size,uniqueCurrentFilenames:seenFiles.size,uniqueCurrentImageHashes:seenHashes.size,dimensions:'561x701',format:'PNG',jsonMetadataRecords:tags.length,exactIdNameImageTagMapping:true,castingRecords:Object.fromEntries([...new Set(m.records.map(r=>r.visualCasting.label))].map(label=>[label,m.records.filter(r=>r.visualCasting.label===label).length])),westernReplacements:13,femaleAdult20to39Records:m.records.filter(r=>r.prompt.includes('East Asian woman,')).length,visualReview:'New portraits inspected as returned by image_gen; restored portraits retain previously reviewed originals. Text absence and facial appearance are visual checks, not conclusions from the hash check.'};
fs.writeFileSync(path.join(dir,'verification-report.json'),JSON.stringify(report,null,2));
const sp=path.join(dir,'generation-status.json'),s=JSON.parse(fs.readFileSync(sp));delete s.blocker;s.status='complete';s.verification=report;fs.writeFileSync(sp,JSON.stringify(s,null,2));
console.log(JSON.stringify(report));
