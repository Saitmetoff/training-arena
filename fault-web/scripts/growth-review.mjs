import {spawnSync} from 'node:child_process';
import {mkdirSync,writeFileSync,readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import assert from 'node:assert/strict';
const base='http://127.0.0.1:3008',out=resolve('test-results/stage6'),shots=resolve('../design/fault-website');
mkdirSync(out,{recursive:true});
function browser(...args){const r=spawnSync('rtk',['proxy','npx.cmd','--yes','agent-browser','--session','fault-stage6',...args],{windowsHide:true,encoding:'utf8',timeout:30000});if(r.status!==0)throw new Error((r.stdout||r.stderr||'Browser failed').slice(0,400));return r.stdout;}
function inspect(code){const raw=browser('--json','eval',code),r=JSON.parse(raw.slice(raw.indexOf('{')));assert(r.success);return r.data.result;}
const evidence={mode:'Local production build; simulated providers only',viewports:[],checks:[],limits:['Emulated Chromium viewports; no physical touch, Safari or social-platform in-app browser','200% text size emulation, not native zoom','No live email, event ingestion, video or acquisition result']};
browser('open',base);evidence.control=inspect(`({labels:[...document.querySelectorAll('form.signup button')].map(b=>b.textContent)})`);assert(evidence.control.labels.every(x=>x==='Join the waitlist'));
browser('open',base+'/growth-preview?content_id=fault-growth-r&creative_id=fault-growth-d01-r&utm_source=instagram&utm_medium=organic-social&utm_campaign=growth-iteration-01&utm_content=fault-growth-d01-r');
for(const [name,w,h] of [['desktop',1440,1000],['tablet',768,1024],['mobile',390,844],['320',320,900]]){
 browser('set','viewport',String(w),String(h));inspect('window.scrollTo(0,0)');
 const value=inspect(`({width:innerWidth,contentWidth:document.documentElement.scrollWidth,labels:[...document.querySelectorAll('form.signup button')].map(b=>b.textContent),variant:document.querySelector('form.signup').dataset.signupVariant})`);
 assert(value.contentWidth<=value.width);assert(value.labels.every(x=>x==='Send confirmation email'));
 browser('screenshot',resolve(shots,`stage6-${name}.png`),'--full');evidence.viewports.push({name,...value});
}
browser('reload');browser('press','Tab');browser('press','Enter');evidence.skip=inspect(`({id:document.activeElement.id,tag:document.activeElement.tagName})`);assert.equal(evidence.skip.id,'main');
inspect(`document.querySelector('form.signup button').focus()`);browser('press','Enter');
evidence.invalid=inspect(`({invalid:[...document.querySelectorAll('form.signup input:invalid')].map(x=>x.name),state:document.querySelector('form.signup').dataset.state})`);assert.equal(evidence.invalid.state,'idle');assert(evidence.invalid.invalid.includes('email'));
browser('fill','section.hero input[name="email"]',`growth-ui-${Date.now()}@example.invalid`);browser('check','section.hero input[name="consent"]');browser('check','section.hero input[type="checkbox"]:not([name])');
inspect(`document.querySelector('form.signup button').focus()`);browser('press','Enter');
// A subsequent browser command observes the async response; do not fabricate pending state.
evidence.pending=inspect(`({state:document.querySelector('form.signup').dataset.state,button:document.querySelector('form.signup button').textContent,status:document.querySelector('form.signup .form-status').textContent})`);
assert.equal(evidence.pending.state,'pending');assert.equal(evidence.pending.button,'Resend confirmation');
browser('set','viewport','390','844');browser('set','media','reduced-motion');browser('reload');
evidence.reduced=inspect(`({reduce:matchMedia('(prefers-reduced-motion: reduce)').matches,labels:[...document.querySelectorAll('form.signup button')].map(x=>x.textContent),caption:document.querySelector('.sequence-caption').textContent,running:document.getAnimations().filter(a=>a.playState==='running').length})`);
assert(evidence.reduced.reduce);assert.equal(evidence.reduced.running,0);browser('screenshot',resolve(shots,'stage6-reduced-motion.png'),'--full');
browser('set','viewport','768','1024');browser('reload');
inspect(`for(const e of document.querySelectorAll('body *'))e.dataset.qaSize=getComputedStyle(e).fontSize;for(const e of document.querySelectorAll('body *'))e.style.fontSize=(parseFloat(e.dataset.qaSize)*2)+'px';window.scrollTo(0,0)`);
evidence.reflow=inspect(`({width:innerWidth,contentWidth:document.documentElement.scrollWidth,clipped:[...document.querySelectorAll('h1,h2,p,label,button')].filter(e=>e.getBoundingClientRect().right>innerWidth+1).map(e=>e.textContent.slice(0,60))})`);assert(evidence.reflow.contentWidth<=evidence.reflow.width);assert.equal(evidence.reflow.clipped.length,0);
browser('screenshot',resolve(shots,'stage6-text-200.png'),'--full');browser('reload');evidence.errors=browser('errors');
writeFileSync(resolve(out,'browser.json'),JSON.stringify(evidence,null,2));
// Reuse the established lifecycle check in a distinct report/creative; no Stage 5 files are overwritten.
const http=readFileSync('scripts/http-release-checks.mjs','utf8').replaceAll('3006','3008').replaceAll('stage5','stage6').replaceAll("content_id:'fault-dev-test',creative_id:'fault-dev-test-a',utm_source:'test',utm_medium:'test',utm_campaign:'development',utm_content:'fault-dev-test-a'","content_id:'fault-growth-r',creative_id:'fault-growth-d01-r',utm_source:'instagram',utm_medium:'organic-social',utm_campaign:'growth-iteration-01',utm_content:'fault-growth-d01-r'").replaceAll("creative:'fault-dev-test-a'","creative:'fault-growth-d01-r'");
writeFileSync(resolve(out,'http-check.mjs'),http);const check=spawnSync('rtk',['proxy','node',resolve(out,'http-check.mjs')],{windowsHide:true,encoding:'utf8',timeout:30000});assert.equal(check.status,0,check.stdout+check.stderr);console.log('Growth browser and local lifecycle checks passed; no live email sent.');
