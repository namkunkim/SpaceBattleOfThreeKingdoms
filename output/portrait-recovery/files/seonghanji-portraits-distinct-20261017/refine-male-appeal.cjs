const fs=require('fs'),path=require('path');
const p=path.join(__dirname,'manifest.json'),m=JSON.parse(fs.readFileSync(p,'utf8'));
const rework=new Set(['SHJ-G005','SHJ-G006','SHJ-G007','SHJ-G008','SHJ-G010']);
const override={
 '조홍':{age:48,face:'long angular handsome face, high defined cheekbones, prominent gently hooked nose, thin well-shaped lips, elegant arched brows and warm confident eyes; thick neatly side-parted black hair with silver temples; clean-shaven face; lean athletic shoulders'},
 '순욱':{age:44,face:'handsome refined oval face, soft defined jaw, broad smooth forehead, large calm eyes with fine straight brows, straight medium nose and full lower lip; neatly combed black hair with a subtle side part; perfectly clean-shaven; slender upright build and reassuring composed expression'},
 '순유':{age:53,face:'mature handsome diamond-shaped face, high defined cheekbones, narrow forehead, wide-set small warm eyes, broad straight nose and a wide well-shaped mouth; neatly trimmed short black hair with grey sides; small tidy separate moustache and clean-shaven chin; lean fit shoulders'},
 '곽가':{age:32,face:'handsome youthful lean angular face, pointed chin, high temples, long expressive hooded eyes, thick fine eyebrows, straight broad-bridged nose and narrow well-shaped lips; tidy medium-short black hair brushed backward with full hairline; completely clean-shaven; lean upright build and subtle charming confident smile'},
 '전위':{age:39,face:'ruggedly handsome broad rectangular face, deep wide-set warm eyes, thick straight brows, large straight nose and broad full mouth; neat short black military fade; short well-trimmed full beard; very muscular broad shoulders and protective confident expression'},
 '허저':{age:41,face:'handsome powerful round face, broad defined jaw, full healthy cheeks, bright large hooded eyes, straight low brows, wide straight nose and balanced full lips; tidy short straight black crew cut; completely clean-shaven; very broad muscular shoulders and a warm trustworthy expression'}
};
const tidy=['neatly combed short black side-part haircut','tidy short straight black crew cut','clean short military fade with a compact top','neatly brushed-back medium-short black hair','well-groomed silver short side-parted hair','neat medium-short center-parted straight black hair'];
let updated=0,replaced=0;
for(let i=0;i<m.records.length;i++){
 const r=m.records[i];if(r.prompt.includes('East Asian woman,'))continue;
 if(rework.has(r.id)&&r.status==='generated'){
  r.supersededPortraits=[...(r.supersededPortraits||[]),{file:'images/'+r.filename,prompt:r.prompt,reason:'User requested generally handsome approachable men with neat hair'}];
  r.status='pending';r.filename=r.id+'-v2.png';delete r.generatedSource;delete r.generator;delete r.bytes;replaced++;
 }
 if(r.status!=='pending')continue;
 let face=r.visualCasting.faceDesign,age=r.visualCasting.age;
 if(override[r.name])({face,age}=override[r.name]);
 else {
  face=face.replace(/very long gaunt face/g,'long defined handsome face').replace(/hollow cheeks/g,'lean healthy defined cheeks').replace(/very lean narrow shoulders/g,'lean fit shoulders').replace(/skeptical squint/g,'engaging confident gaze').replace(/rough two-day stubble only/g,'short meticulously groomed stubble only').replace(/thin lips and a small tight mouth/g,'well-shaped thin lips and a relaxed small mouth');
  if(r.name!=='하후돈')face=face.replace(/completely shaved scalp|bald crown with grey hair only at the sides|bald crown with grey side hair|short silver hair with a sharply receding hairline|smooth black center-part bob ending at the ears|medium-length straight hair tucked behind both ears|long straight black hair tied tightly at the nape|shaved sides and a compact topknot|short untidy black bristles|short naturally wavy hair brushed forward|thick straight hair swept vertically upward/g,tidy[i%tidy.length]);
  if(age>64&&r.name!=='황충')age=50+(i%12);
 }
 const oldFace=r.visualCasting.faceDesign;
 r.prompt=r.prompt.replace(oldFace,face).replace(/East Asian man, age \d+\./,'East Asian man, age '+age+'.');
 r.prompt=r.prompt.replace('Use ordinary believable human individuality; do not automatically beautify every man or add a goatee. Facial hair must match the specified design exactly.','Overall art direction: a handsome, likable and approachable adult man, with balanced attractive proportions and a distinct individual face. Preserve this particular skull, eyes, nose, mouth, age and build; attractive does not mean the same actor. Healthy well-kept skin, neat professional hairstyle and meticulous grooming. Warm intelligent eyes and calm confident charisma; do not make every man angry or gaunt. Facial hair must be tidy and follow the specified design; do not add a default goatee.');
 r.visualCasting={...r.visualCasting,age,faceDesign:face,appealDirection:'대체로 호감형 미남, 단정한 머리'};
 r.castingSpec=face;updated++;
}
m.imageSpecification.maleAppealDirection='Generally handsome, approachable men with neat professional hair; preserve distinctive face structure and varied ages';
fs.writeFileSync(p,JSON.stringify(m,null,2));
fs.writeFileSync(path.join(__dirname,'prompts.jsonl'),m.records.map(r=>JSON.stringify({id:r.id,name:r.name,prompt:r.prompt})).join('\n'));
require('./export-tags.cjs');
fs.appendFileSync(path.join(__dirname,'production-rules.md'),'\n- 추가 지시: 남성은 대체로 호감형 미남과 단정한 머리. 골격·눈·코·입·턱·나이 차이는 유지한다. 조홍·순욱·순유·곽가·전위 기존 결과는 보존하고 v2 파일로 교체 생성한다. 무작위 고령/마른 체형이 무장 역할을 흐리는 경우 개별 보정한다.\n');
console.log(JSON.stringify({updated,rework:replaced,completed:m.records.filter(r=>r.status==='generated').length,total:m.total}));
