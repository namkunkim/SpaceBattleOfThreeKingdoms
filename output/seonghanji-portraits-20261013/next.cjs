const fs=require('fs'),path=require('path');const m=JSON.parse(fs.readFileSync(path.join(__dirname,'manifest.json'),'utf8'));
console.log(JSON.stringify({total:m.total,completed:m.records.filter(x=>x.status==='generated').length,records:m.records.filter(x=>x.status==='pending'&&(process.argv[3]!=='female'||x.prompt.includes('adult woman'))).slice(0,Number(process.argv[2]||5))}));
