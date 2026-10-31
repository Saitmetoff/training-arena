import {spawnSync} from 'node:child_process';
import {writeFileSync,mkdirSync} from 'node:fs';
import {resolve} from 'node:path';
const base=process.env.FAULT_QA_URL||'http://127.0.0.1:3006',out=resolve('test-results/stage5'),shots=resolve('../design/fault-website');
mkdirSync(out,{recursive:true});
function browser(...args){
 const run=spawnSync('rtk',['proxy','npx.cmd','--yes','agent-browser','--session','fault-stage5',...args],{windowsHide:true,encoding:'utf8',timeout:30_000});
 if(run.status!==0)throw new Error(`Browser ${args[0]} failed: ${(run.stdout||run.stderr||run.error?.message||'').slice(0,400)}`);
 return run.stdout;
}
function inspect(code){const raw=browser('--json','eval',code);const result=JSON.parse(raw.slice(raw.indexOf('{')));if(!result.success)throw new Error('Browser evaluation failed');return result.data.result;}
const evidence={base,mode:'Local production build; email and analytics providers simulated',viewports:[],routes:[],keyboard:[],limits:['No physical touch device, Safari or social-platform in-app browser available','200% text reflow is DOM text enlargement, not native browser zoom']};
browser('open',base);
for(const [name,width,height] of [['desktop',1440,1000],['tablet',768,1024],['mobile',390,844],['320',320,800]]){
 browser('set','viewport',String(width),String(height));
 inspect('window.scrollTo(0,0)');
 const measurement=inspect(`({width:innerWidth,contentWidth:document.documentElement.scrollWidth,fonts:document.fonts.status,headline:document.querySelector('h1').innerText,buttons:[...document.querySelectorAll('.sequence-controls button')].map(b=>({label:b.textContent,width:b.getBoundingClientRect().width,height:b.getBoundingClientRect().height}))})`);
 const screenshot=`stage5-${name}.png`;browser('screenshot',resolve(shots,screenshot),'--full');
 evidence.viewports.push({name,...measurement,screenshot:`design/fault-website/${screenshot}`});console.log(`${name}: ${measurement.width}px, content ${measurement.contentWidth}px`);
}
// Native keyboard activation: skip link and product control. No synthetic click.
browser('reload');browser('press','Tab');
evidence.keyboard.push(inspect(`({action:'first Tab',focused:document.activeElement.textContent})`));browser('press','Enter');
evidence.keyboard.push(inspect(`({action:'activate skip link',focused:document.activeElement.id})`));
inspect(`(()=>{const b=document.querySelectorAll('.sequence-controls button')[1];b.scrollIntoView({block:'center'});b.focus()})()`);browser('press','Enter');
evidence.keyboard.push(inspect(`({action:'activate Enter sequence',selected:[...document.querySelectorAll('button')].filter(x=>x.getAttribute('aria-pressed')==='true').map(x=>x.textContent),caption:document.querySelector('.sequence-caption')?.textContent})`));
browser('set','viewport','390','844');browser('set','media','reduced-motion');browser('reload');
evidence.reducedMotion=inspect(`({preference:matchMedia('(prefers-reduced-motion: reduce)').matches,caption:document.querySelector('.sequence-caption')?.textContent,animations:document.getAnimations().map(a=>({duration:a.effect?.getTiming().duration,playState:a.playState}))})`);
browser('screenshot',resolve(shots,'stage5-reduced-motion.png'),'--full');
// Repeat scrolling and keyboard transitions under reduced motion.
for(let i=0;i<3;i++){browser('scroll','down','1200');browser('scroll','up','1200');}
inspect(`document.querySelectorAll('.sequence-controls button')[3].focus()`);browser('press','Enter');
evidence.reducedMotion.review=inspect(`({selected:[...document.querySelectorAll('button')].filter(x=>x.getAttribute('aria-pressed')==='true').map(x=>x.textContent),caption:document.querySelector('.sequence-caption')?.textContent})`);
// Check enlarged text without claiming native browser zoom.
browser('set','viewport','768','1024');browser('reload');
inspect(`for(const e of document.querySelectorAll('body *')){const c=getComputedStyle(e);e.dataset.qaFont=c.fontSize;}for(const e of document.querySelectorAll('body *')){e.style.fontSize=(parseFloat(e.dataset.qaFont)*2)+'px';}window.scrollTo(0,0)`);
evidence.textReflow=inspect(`({mode:'200% computed text sizes',width:innerWidth,contentWidth:document.documentElement.scrollWidth,clipped:[...document.querySelectorAll('h1,h2,p,label,button')].filter(e=>e.getBoundingClientRect().right>innerWidth+1).map(e=>e.textContent.slice(0,80)).slice(0,12)})`);
browser('screenshot',resolve(shots,'stage5-text-200.png'),'--full');
browser('reload');
for(const path of ['/c/ABC123','/privacy.html','/support.html','/delete-account.html','/.well-known/assetlinks.json','/confirm','/unsubscribe','/api/internal/cron','/qa-media','/social-preview.png']){
 const response=await fetch(base+path);const type=response.headers.get('content-type');let body=type?.includes('text/html')?await response.text():'';
 evidence.routes.push({path,status:response.status,contentType:type,referrerPolicy:response.headers.get('referrer-policy'),robots:response.headers.get('x-robots-tag'),legacyBase:body.includes('<base href="/legacy/">')});
}
browser('open',base+'/c/ABC123');evidence.challenge=inspect(`({heading:document.querySelector('h1')?.textContent,scripts:[...document.scripts].map(s=>new URL(s.src).pathname),codeVisible:document.body.textContent.includes('ABC123')})`);
browser('open',base);
evidence.console=browser('errors');
writeFileSync(resolve(out,'browser.json'),JSON.stringify(evidence,null,2));
console.log('Browser evidence saved; local providers only.');
