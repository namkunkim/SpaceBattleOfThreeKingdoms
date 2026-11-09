const http=require('http'),fs=require('fs'),path=require('path');
const root=process.cwd();
const entry='/docs/battle-core/pc-campaign-design/SESSION-REQUIREMENTS-CHECKLIST-20261031.html';
const server=http.createServer((req,res)=>{
 let name;try{name=decodeURIComponent(new URL(req.url,'http://127.0.0.1').pathname);}catch{res.writeHead(400);res.end();return;}
 if(name==='/'){res.writeHead(302,{Location:entry});res.end();return;}
 const target=path.resolve(root,'.'+name);
 if(!target.startsWith(root+path.sep)||name.split('/').some(p=>['.git','.codex','.agents','.aws'].includes(p))){res.writeHead(403);res.end();return;}
 fs.stat(target,(error,stat)=>{if(error||!stat.isFile()){res.writeHead(404);res.end('Not found');return;}const type={'.html':'text/html; charset=utf-8','.md':'text/plain; charset=utf-8','.json':'application/json; charset=utf-8','.png':'image/png'}[path.extname(target)]||'application/octet-stream';res.writeHead(200,{'Content-Type':type,'Cache-Control':'no-store'});if(req.method==='HEAD')res.end();else fs.createReadStream(target).pipe(res);});
});
server.listen(0,'127.0.0.1',()=>console.log(JSON.stringify({url:'http://127.0.0.1:'+server.address().port+entry,root,host:'127.0.0.1'})));