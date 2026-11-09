const fs=require('fs'),path=require('path'),crypto=require('crypto');
const dirs=['C:/WorkSpace/Seonghanji/assets/preproduction/p0-04','C:/WorkSpace/SpaceBattleOfThreeKingdoms/assets/portraits'];
const all=[];
function walk(dir){if(!fs.existsSync(dir))return;for(const d of fs.readdirSync(dir,{withFileTypes:true})){const p=path.join(dir,d.name);if(d.isDirectory())walk(p);else if(/\.(png|jpg|jpeg|webp)$/i.test(d.name)){const b=fs.readFileSync(p);all.push({path:p,bytes:b.length,sha256:crypto.createHash('sha256').update(b).digest('hex'),...(b.subarray(1,4).toString()==='PNG'?{width:b.readUInt32BE(16),height:b.readUInt32BE(20)}:{})});}}}
dirs.forEach(walk);
fs.writeFileSync(path.join(__dirname,'existing-project-portraits.json'),JSON.stringify(all,null,2));
console.log(JSON.stringify({files:all.length,unique:new Set(all.map(x=>x.sha256)).size}));
