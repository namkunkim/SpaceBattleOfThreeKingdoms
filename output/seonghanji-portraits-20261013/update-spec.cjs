const fs=require('fs'),path=require('path');const dir=__dirname;
const mp=path.join(dir,'manifest.json'),m=JSON.parse(fs.readFileSync(mp,'utf8'));
if(m.imageSpecification?.width===561 && m.imageSpecification?.height===701 && m.imageSpecification?.textInImage===false){console.log('Specification already current; preserving generated portraits.');process.exit(0);}
fs.mkdirSync(path.join(dir,'drafts'),{recursive:true});
for(const r of m.records){
 if(r.status==='generated'){const old=path.join(dir,'images',r.filename);if(fs.existsSync(old))fs.renameSync(old,path.join(dir,'drafts',r.filename));r.status='pending';r.supersededReason='Nameplate removed per user instruction';}
 r.filename=r.id+'.png';
 r.prompt=r.prompt.replace(/Bottom dark name panel,[\s\S]*?ONE portrait, no grid\./,'No text, letters, numbers, nameplates, captions, identity tags, logos or watermarks anywhere in the image. The portrait fills the entire canvas. ONE portrait, no grid.');
 r.prompt+=' Delivery size: 561 x 701 pixels (half the width and height of the Cao Cao reference portrait). Keep face and role readable at this final small size.';
 r.targetWidth=561;r.targetHeight=701;
}
m.imageSpecification={width:561,height:701,textInImage:false,metadataFiles:['tags.json','tags.csv'],referenceSize:{width:1122,height:1402},scale:0.5};
fs.writeFileSync(mp,JSON.stringify(m,null,2));
fs.writeFileSync(path.join(dir,'prompts.jsonl'),m.records.map(r=>JSON.stringify({id:r.id,name:r.name,prompt:r.prompt})).join('\n'));
fs.writeFileSync(path.join(dir,'README.md'),'# 성한지 장수 초상 제작\n\n최종 규격: 561×701 PNG. 초상 내부에 글자·이름·태그를 넣지 않는다. 이름·소속·역할·식별 ID·태그는 tags.json / tags.csv로 분리한다. 이미지 파일은 images/<ID>.png로 연결한다. 원전 문서의 수치와 인물 특징을 참고하며, 외모는 창작 시각 해석이다.\n\n명장 150명, 일반 무장 249명, 이역 인물 102명: 총 501명. 복수 인물 행은 개인별로 분리하고, 동일 인물인 여개·왕항은 중복 제외했다. 동명이인은 소속과 ID로 구분한다. 익명의 맹달 부장 집단은 개인 식별 불가로 제외하며 맹달 본인은 포함한다. 확장 유보 후보와 절차적 미정 인물은 포함하지 않는다.\n\nmanifest.json은 출처 문서·행 번호·특성·생성 상태·프롬프트를 기록한다. prompts.jsonl은 인물별 실제 제작 지시다. image_gen 기본 내장 도구를 사용한다.\n');
require('./export-tags.cjs');
console.log(JSON.stringify({total:m.total,spec:m.imageSpecification,pending:m.records.filter(x=>x.status==='pending').length}));
