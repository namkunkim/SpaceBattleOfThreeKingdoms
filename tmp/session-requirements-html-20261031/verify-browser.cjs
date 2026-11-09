const fs=require('fs'),path=require('path'),assert=require('assert/strict');
const {pathToFileURL}=require('url');
const {chromium}=require('C:/Users/nk782/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const dir=path.resolve('tmp/session-requirements-html-20261031');
const htmlPath=path.resolve('docs/battle-core/pc-campaign-design/SESSION-REQUIREMENTS-CHECKLIST-20261031.html');
const url=pathToFileURL(htmlPath).href;
const data=JSON.parse(fs.readFileSync(path.join(dir,'baseline-data.json'),'utf8'));
const storageKey=data.appId+':v'+data.formatVersion+':'+data.baselineId;
const checks=[],errors=[],external=[],downloadResults=[];
function check(ok,label){assert.ok(ok,label);checks.push(label);}
async function snapshot(page){return page.evaluate(key=>({cards:[...document.querySelectorAll('.card')].map(card=>({id:card.dataset.id,status:card.querySelector('select').value,note:card.querySelector('textarea').value})),counts:[...document.querySelectorAll('[data-count]')].map(x=>x.textContent),progress:document.getElementById('progress-number').textContent,storage:localStorage.getItem(key),storageLabel:document.getElementById('storage-text').textContent}),storageKey);}
async function input(page,value,name='backup.json'){await page.locator('#import-file').setInputFiles({name,mimeType:'application/json',buffer:Buffer.from(typeof value==='string'?value:JSON.stringify(value))});}
async function exportBackup(page,label){const pending=page.waitForEvent('download');await page.locator('#export-button').click();const download=await pending;const target=path.join(dir,label+'.json');try{await download.saveAs(target);downloadResults.push({label,saved:true});}catch(error){downloadResults.push({label,saved:false,error:error.message});}check((await page.locator('#transfer-message').innerText()).includes('다운로드를 요청'),'export wording does not claim saved');await page.locator('#text-backup-button').click();const raw=await page.locator('#text-backup').inputValue();await page.locator('#select-backup-button').click();check(await page.evaluate(()=>{const n=document.getElementById('text-backup');return n.selectionEnd-n.selectionStart===n.value.length;}),'manual backup all text selectable');fs.writeFileSync(path.join(dir,label+'-text.json'),raw);return JSON.parse(raw);}
async function settle(page){await page.waitForFunction(()=>document.getElementById('import-file').value==='');}
(async()=>{
 const browser=await chromium.launch({executablePath:'C:/Program Files/Google/Chrome/Application/chrome.exe',headless:true});
 const contexts=[];
 async function context(options={}){const c=await browser.newContext({...options,acceptDownloads:true});contexts.push(c);c.on('page',p=>{p.on('pageerror',error=>errors.push(error.message));p.on('request',request=>{if(/^https?:/.test(request.url())&&!request.url().startsWith('http://127.0.0.1:'))external.push(request.url());});});return c;}
 const ctx=await context({viewport:{width:1365,height:950}}),page=await ctx.newPage();
 await page.goto(url);await page.waitForSelector('.card');
 check(await page.locator('.card').count()===41,'file URL renders all 41');
 assert.deepEqual(await page.locator('[data-count]').allTextContents(),['41','23','9','9']);checks.push('baseline counts 41/23/9/9');
 check(await page.locator('#progress-number').innerText()==='23','baseline progress 23/32');
 await page.locator('[data-filter="미완료"]').click();check(await page.locator('.card').count()===9,'pending filter 9');
 await page.locator('#search').fill('P01');check(await page.locator('.card').count()===1,'ID search plus status');
 await page.locator('#search').fill('no-match-xyz');check(await page.locator('.card').count()===0&&await page.locator('#empty-state').isVisible(),'empty search feedback');
 await page.locator('#search').fill('');await page.locator('[data-filter="전체"]').click();
 await page.locator('#category').selectOption('확정 설계 결정');check(await page.locator('.card').count()===9,'category filter 9 decisions');
 await page.locator('#category').selectOption('');
 await page.locator('#status-W01').selectOption('완료');check(await page.locator('#progress-number').innerText()==='23','baseline standing excluded from numerator and denominator');
 await page.locator('#status-P01').selectOption('완료');check(await page.locator('#progress-number').innerText()==='24','ordinary requirement increases progress to24/32');
 const note='메모검증token-OP41-20261031 <img src=x onerror="window.__bad=1"><script>window.__bad=1</script>';
 await page.locator('[data-id="P01"] summary').click();await page.locator('#note-P01').fill(note);
 check(await page.locator('img').count()===0&&!await page.evaluate(()=>window.__bad),'notes do not render executable HTML');
 await page.reload();await page.waitForSelector('.card');
 check(await page.locator('#status-P01').inputValue()==='완료'&&await page.locator('#status-W01').inputValue()==='완료'&&await page.locator('#note-P01').inputValue()===note,'status and notes persist after file reload');
 check(await page.locator('.not-ready').innerText()==='NOT_READY','overall NOT_READY independent of edits');
 await page.locator('#changed-only').check();check(await page.locator('.card').count()===2,'changed-only filter2');await page.locator('#changed-only').uncheck();
 await page.locator('#search').fill('메모검증token-OP41-20261031');check(await page.locator('.card').count()===1,'notes included in search');await page.locator('#search').fill('');
 const backup=await exportBackup(page,'roundtrip-backup');
 check(backup.items.length===41&&backup.items.find(x=>x.id==='P01').note===note,'exported text JSON contains41 states and notes');
 await page.locator('#status-P01').selectOption('미완료');await input(page,backup);await settle(page);
 check(await page.locator('#status-P01').inputValue()==='완료'&&await page.locator('#note-P01').inputValue()===note,'valid import restores exported state');
 const badCases=[];
 function bad(label,mutator){const value=structuredClone(backup);mutator(value);badCases.push([label,value]);}
 badCases.push(['malformed JSON','{bad']);bad('wrong app',x=>x.appId='other');bad('wrong version',x=>x.formatVersion=2);bad('wrong baseline',x=>x.baselineId='old');bad('missing ID',x=>x.items.pop());bad('duplicate ID',x=>x.items[40]=structuredClone(x.items[0]));bad('unknown ID',x=>x.items[40].id='Z99');bad('invalid state',x=>x.items[40].status='<img>');bad('note type',x=>x.items[40].note=7);bad('note length',x=>x.items[40].note='x'.repeat(4001));bad('extra item field',x=>x.items[40].unsafe=true);bad('extra top field',x=>x.other=true);bad('prototype key',x=>Object.defineProperty(x.items[40],'__proto__',{value:{polluted:true},enumerable:true}));bad('timestamp type',x=>x.exportedAt=3);bad('items object',x=>x.items={});
 for(const [label,value] of badCases){const before=await snapshot(page);await input(page,value);await settle(page);assert.deepEqual(await snapshot(page),before,label+' atomic UI/notes/storage');check(await page.locator('#transfer-message').getAttribute('class').then(x=>x.includes('error')),label+' explicit refusal');}
 const beforeLarge=await snapshot(page);await page.locator('#import-file').setInputFiles({name:'huge.json',mimeType:'application/json',buffer:Buffer.alloc(1048577,32)});await settle(page);assert.deepEqual(await snapshot(page),beforeLarge);checks.push('oversized import atomic refusal');
 const current=await snapshot(page);const allDone=structuredClone(backup);allDone.items.forEach(x=>x.status='완료');await input(page,allDone);await settle(page);check(await page.locator('#progress-number').innerText()==='32'&&await page.locator('.not-ready').innerText()==='NOT_READY','all items checked cannot promote readiness');
 await input(page,backup);await settle(page);
 const duplicateDOM=await page.evaluate(()=>{const ids=[...document.querySelectorAll('[id]')].map(x=>x.id);return ids.length-new Set(ids).size;});check(duplicateDOM===0,'unique element IDs');
 check(await page.getByLabel('P01 상태',{exact:true}).count()===1,'status control has accessible name');
 await page.locator('#search').focus();check(await page.evaluate(()=>document.activeElement.id==='search'),'keyboard focus on search');
 const c2=await context();const denied=await c2.newPage();await denied.addInitScript(()=>{Storage.prototype.setItem=function(){throw new DOMException('Denied','QuotaExceededError');};});await denied.goto(url);await denied.waitForSelector('.card');await denied.locator('#status-P02').selectOption('완료');check(await denied.locator('#status-P02').inputValue()==='완료'&&(await denied.locator('#storage-text').innerText()).includes('저장 안 됨'),'write-denied storage keeps edits and warns');const deniedBackup=await exportBackup(denied,'storage-denied-backup');check(deniedBackup.items.find(x=>x.id==='P02').status==='완료','backup export available when storage denied');await denied.reload();await denied.waitForSelector('.card');check(await denied.locator('#status-P02').inputValue()==='미완료','unsaved warning corresponds to actual reload loss');
 const c3=await context();const blocked=await c3.newPage();await blocked.addInitScript(()=>Object.defineProperty(window,'localStorage',{get(){throw new DOMException('Blocked','SecurityError');}}));await blocked.goto(url);await blocked.waitForSelector('.card');await blocked.locator('#status-P02').selectOption('완료');check(await blocked.locator('#status-P02').inputValue()==='완료'&&(await blocked.locator('#storage-text').innerText()).includes('저장 안 됨'),'fully blocked storage fallback is editable');
 const c4=await context();const old=await c4.newPage();await old.addInitScript(({prefix})=>localStorage.setItem(prefix+'old-baseline','old saved content'),{prefix:data.appId+':v'+data.formatVersion+':'});await old.goto(url);await old.waitForSelector('.card');check((await old.locator('#storage-text').innerText()).includes('자동 적용하지')&&await old.locator('#progress-number').innerText()==='23','other baseline storage not automatically applied');
 const c5=await context();const malformed=await c5.newPage();await malformed.addInitScript(({key})=>localStorage.setItem(key,'bad saved JSON'),{key:storageKey});await malformed.goto(url);await malformed.waitForSelector('.card');check((await malformed.locator('#storage-text').innerText()).includes('적용하지 못')&&await malformed.evaluate(key=>localStorage.getItem(key),storageKey)==='bad saved JSON','invalid saved data is preserved and not applied');
 const clean=await context({viewport:{width:1365,height:950}});const desktop=await clean.newPage();await desktop.goto(url);await desktop.waitForSelector('.card');await desktop.screenshot({path:path.join(dir,'desktop.png'),fullPage:false});
 const mobileContext=await context({viewport:{width:320,height:1000},deviceScaleFactor:1});const mobile=await mobileContext.newPage();await mobile.goto(url);await mobile.waitForSelector('.card');check(await mobile.evaluate(()=>document.documentElement.scrollWidth<=window.innerWidth),'320px no horizontal overflow');await mobile.screenshot({path:path.join(dir,'mobile-320.png'),fullPage:false});
 const tabletContext=await context({viewport:{width:768,height:1024}});const tablet=await tabletContext.newPage();await tablet.goto(url);await tablet.waitForSelector('.card');check(await tablet.evaluate(()=>document.documentElement.scrollWidth<=window.innerWidth),'768px no horizontal overflow');
 check(errors.length===0,'zero page errors in browser contexts');check(external.length===0,'zero external HTTP requests');
 const result={ok:true,downloadResults,checks,checkCount:checks.length,invalidImports:badCases.length+1,errors,externalRequests:external,sourceRows:data.items.length,baselineCounts:{complete:23,pending:9,standing:9},progressDenominator:32,screenshots:['desktop.png','mobile-320.png'],fileUrl:url,previewUrl:'http://127.0.0.1:59352/docs/battle-core/pc-campaign-design/SESSION-REQUIREMENTS-CHECKLIST-20261031.html'};
 fs.writeFileSync(path.join(dir,'browser-results.json'),JSON.stringify(result,null,2));
 for(const context of contexts)await context.close();await browser.close();console.log(JSON.stringify({ok:true,checks:checks.length,invalidImports:badCases.length+1,pageErrors:errors.length,externalRequests:external.length}));
})().catch(error=>{fs.writeFileSync(path.join(dir,'browser-failure.txt'),error.stack);console.error(error);process.exit(1);});