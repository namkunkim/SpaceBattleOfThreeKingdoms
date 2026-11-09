import fs from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';
const path=process.argv[2]??'C:/Users/nk782/.codex/visualizations/2026/10/18/01a14eee-563b-71e3-9756-919c86a75a2f/fleet-formations.html';
const html=fs.readFileSync(path,'utf8');
assert(html.length<1000000);
assert(!html.includes('__DATA__'));
class Element {
 constructor(tag='div'){this.tag=tag;this.children=[];this.attrs={};this.clientWidth=340;this.value='all';this.events={};this.style={setProperty(){}};this.classList={toggle(){}};}
 appendChild(e){this.children.push(e);return e;}
 append(...es){this.children.push(...es);}
 setAttribute(k,v){this.attrs[k]=v;}
 replaceChildren(){this.children=[];}
 addEventListener(k,v){this.events[k]=v;}
}
const els=Object.fromEntries(['ship-key','formation-panels','formation-choice','ship-show-all','ship-selection-status'].map(k=>[k,new Element()]));
const root={querySelector:s=>els[s.slice(1)]};
const document={getElementById:()=>root,createElement:tag=>new Element(tag),createElementNS:(_ns,tag)=>new Element(tag)};
const window={addEventListener(){}};
vm.runInNewContext(html.match(/<script>([\s\S]*?)<\/script>/)[1],{document,window,ResizeObserver:class{observe(){}disconnect(){}}});
assert.equal(els['ship-key'].children.length,8);
assert.equal(els['formation-panels'].children.length,7);
for(const panel of els['formation-panels'].children){const svg=panel.children[2];assert.equal(svg.children.filter(e=>e.tag==='g').length,56);}
els['ship-key'].children[6].events.click();
assert.equal(els['ship-key'].children[6].attrs['aria-pressed'],'true');
for(const panel of els['formation-panels'].children){
 const marks=panel.children[2].children.filter(e=>e.tag==='g');
 assert.equal(marks.filter(e=>e.attrs.opacity===1).length,10);
 assert(marks.filter(e=>e.attrs.opacity===1).every(e=>e.attrs['data-ship-type']===6));
 assert(marks.filter(e=>e.attrs.opacity===1).every(e=>e.children.some(c=>c.tag==='rect')));
}
els['formation-choice'].value='2';
els['formation-choice'].events.change();
assert.equal(els['formation-panels'].children.length,1);
assert.equal(els['formation-panels'].children[0].children[0].textContent,'방원진');
assert.equal(els['ship-key'].children[6].attrs['aria-pressed'],'true');
els['ship-key'].children[7].events.click();
assert.equal(els['formation-panels'].children[0].children[2].children.filter(e=>e.tag==='g'&&e.attrs.opacity===1).length,6);
els['ship-key'].children[7].events.click();
assert.equal(els['ship-show-all'].disabled,true);
assert.equal(els['formation-panels'].children[0].children[2].children.filter(e=>e.tag==='g'&&e.attrs.opacity===1).length,56);
els['ship-key'].children[0].events.click();
els['ship-show-all'].events.click();
assert.equal(els['ship-key'].children[0].attrs['aria-pressed'],'false');
const data=JSON.parse(fs.readFileSync('tmp/formation-layout-data.json','utf8'));
for(const texture of data.textures){const buf=Buffer.from(texture.split(',')[1],'base64');assert.equal(buf.readUInt32BE(16),256);assert.equal(buf.readUInt32BE(20),64);}
console.log('VISUAL_PASS: 7 formations, 392 ship image marks, 8 legend entries, selection updates, embedded PNGs valid.');
