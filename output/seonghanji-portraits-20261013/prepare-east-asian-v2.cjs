const fs=require('fs'),path=require('path'),crypto=require('crypto');
const src=__dirname,dst=path.resolve(src,'../seonghanji-portraits-east-asian-20261016');
if(fs.existsSync(path.join(dst,'manifest.json')))throw Error('Version already prepared');
fs.mkdirSync(path.join(dst,'images'),{recursive:true});
const m=JSON.parse(fs.readFileSync(path.join(src,'manifest.json'),'utf8'));
const labels=[...new Set(m.records.map(r=>r.visualCasting?.label).filter(Boolean))];
const inventory=m.records.filter(r=>r.status==='generated').map(r=>{
 const file=path.join(src,'images',r.filename),b=fs.readFileSync(file);
 return {id:r.id,name:r.name,file,bytes:b.length,width:b.readUInt32BE(16),height:b.readUInt32BE(20),sha256:crypto.createHash('sha256').update(b).digest('hex'),documentedCasting:r.visualCasting,reuse:r.visualCasting?.label==='동아시아계'};
});
for(const r of m.records){
 const reuse=r.status==='generated'&&r.visualCasting?.label==='동아시아계';
 const old=r.visualCasting?.description;
 r.previousVersion={status:r.status,prompt:r.prompt,visualCasting:r.visualCasting,image:r.status==='generated'?path.join(src,'images',r.filename):null};
 if(old)r.prompt=r.prompt.split(old).join('East Asian human, natural East Asian features and individually varied skin tones');
 r.prompt=r.prompt.replaceAll('East or Central Asian human appearance appropriate to the named person','East Asian human with natural individually distinct features').replaceAll('Multiethnic SF casting direction:','East Asian SF casting direction:').replaceAll('assigned multiethnic casting','East Asian casting').replaceAll('Characters of every background can hold any faction, authority level or role.','Retain the individual character role and faction.');
 r.prompt+=' Final casting requirement: this character is East Asian. Give this individual a distinctive East Asian face, varied age-appropriate hair and facial structure. All characters in this collection are East Asian. Reference is for cinematic rendering, uniform materials, framing and lighting only; do not copy the reference face. No text or identity labels anywhere in the portrait.';
 r.visualCasting={label:'동아시아계',description:'East Asian human with individually distinct natural features',fictionalInterpretation:true,...(r.prompt.includes('adult woman')?{beautyDirection:'아름다운 성인 여성'}:{})};
 r.tags=[...r.tags.filter(t=>!labels.includes(t)),'동아시아계'];
 if(reuse){fs.copyFileSync(path.join(src,'images',r.filename),path.join(dst,'images',r.filename));r.reusedFrom=path.join(src,'images',r.filename);}
 else {r.status='pending';delete r.generatedSource;delete r.generator;delete r.bytes;}
}
m.imageSpecification.diverseHumanCasting=false;
m.imageSpecification.castingBalance={requestedOn:'2026-10-16',allCharacters:'East Asian',proportion:1};
m.imageSpecification.referenceImage=path.join(src,'images','SHJ-G001.png');
m.version='east-asian-20261016';
fs.writeFileSync(path.join(dst,'manifest.json'),JSON.stringify(m,null,2));
fs.writeFileSync(path.join(dst,'prompts.jsonl'),m.records.map(r=>JSON.stringify({id:r.id,name:r.name,prompt:r.prompt})).join('\n'));
fs.writeFileSync(path.join(dst,'source-inventory.json'),JSON.stringify(inventory,null,2));
for(const f of ['next.cjs','resize.ps1','save-result.cjs','export-tags.cjs','verify.ps1'])fs.copyFileSync(path.join(src,f),path.join(dst,f));
require(path.join(dst,'export-tags.cjs'));
fs.writeFileSync(path.join(dst,'production-rules.md'),'# 제작 규칙 — 2026-10-16\n\n- 501명 전원 동아시아계로 표현한다. 이전의 다인종/비율 배정은 폐기한다.\n- 글자 없는 561×701 PNG, 이름과 식별 태그는 별도 JSON/CSV.\n- 여성은 모두 아름다운 성인 여성, 역할에 맞는 제복·갑옷.\n- 기존 180장은 원본 버전에 보존한다. 기록상 동아시아계 30장은 재사용하고 150장은 교체 생성한다. 미완료 321명을 포함해 471장 생성 필요.\n- 원본 샘플 파일은 사라졌다. 기존 조조 초상 SHJ-G001을 조명·질감·구도의 참고로 사용한다.\n- 이미지 생성은 imagegen 스킬과 내장 image_gen 도구로 각 인물별 수행한다.\n- manifest 상태가 실제 완료 기준이다. next.cjs로 pending을 읽고 resize.ps1 후 save-result.cjs로 등록한다.\n- 완료 기준: 501장 모두 존재, 561×701, 태그와 ID 1:1 연결, 생성 결과 육안 확인.\n');
console.log(JSON.stringify({directory:dst,reused:inventory.filter(x=>x.reuse).length,regenerate:inventory.filter(x=>!x.reuse).length,pending:m.records.filter(r=>r.status==='pending').length}));
