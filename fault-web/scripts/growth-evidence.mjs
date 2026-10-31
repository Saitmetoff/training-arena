import {readFileSync,writeFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {createHash} from 'node:crypto';
const root=resolve('..'),prefix=resolve(root,'tmp/fault-opencode/06-growth-batch');
const usage={provider:'opencode-go',model:'deepseek-v4.1-flash',session:null,input:0,output:0,reasoning:0,cacheRead:0,cacheWrite:0,reportedCost:0,toolReads:[],toolWrites:[],shellCommands:[],reportedOnly:true};
for(const suffix of ['.events.jsonl','.correction.events.jsonl']){
 const bytes=readFileSync(prefix+suffix),raw=bytes[0]===255&&bytes[1]===254?bytes.toString('utf16le').replace(/^\uFEFF/,''):bytes.toString('utf8').replace(/^\uFEFF/,'');
 for(const line of raw.split(/\r?\n/)){if(!line.trim())continue;let e;try{e=JSON.parse(line);}catch{continue;}
  usage.session=e.sessionID||usage.session;const p=e.part;
  if(e.type==='step_finish'&&p){const t=p.tokens||{};usage.input+=t.input||0;usage.output+=t.output||0;usage.reasoning+=t.reasoning||0;usage.cacheRead+=t.cache?.read||0;usage.cacheWrite+=t.cache?.write||0;usage.reportedCost+=p.cost||0;}
  if(e.type==='tool_use'&&p){const input=p.state?.input||{};
   if(p.tool==='read')usage.toolReads.push(input.filePath);
   if(['write','edit'].includes(p.tool))usage.toolWrites.push(input.filePath);
   if(p.tool==='apply_patch')usage.toolWrites.push(...(input.patchText||'').split('\n').filter(x=>/^\*\*\* (Add|Update|Delete) File:/.test(x)));
   if(p.tool==='bash')usage.shellCommands.push(input.command);
  }
 }
}
for(const key of ['toolReads','toolWrites','shellCommands'])usage[key]=[...new Set(usage[key])];
writeFileSync(prefix+'.usage.json',JSON.stringify(usage,null,2));
const headers=readFileSync('test-results/stage6/hosted.headers','utf8'),html=readFileSync('test-results/stage6/hosted.html','utf8'),signupHeaders=readFileSync('test-results/stage6/hosted-signup.headers','utf8');
const url='https://fault-website-k0yue7h1i-priler003-7576s-projects.vercel.app';
const anon=await fetch(url+'/growth-preview',{redirect:'manual'});
const hosted={url:url+'/growth-preview',deployment:'dpl_2uCNpSfgG4cnPdfAA2QMgw6YrdyZ',target:'preview',status:'Ready',authenticatedPage:Number(headers.match(/HTTP\/[^ ]+ (\d+)/)?.[1]),treatmentPresent:html.includes('Send confirmation email'),noindex:html.includes('noindex'),signupStatus:Number(signupHeaders.match(/HTTP\/[^ ]+ (\d+)/)?.[1]),anonymousStatus:anon.status,anonymousRedirectHost:new URL(anon.headers.get('location')||url,url).host,signupConfigurationRequired:JSON.parse(readFileSync('test-results/stage6/hosted-signup.json','utf8')).code==='configuration_required',public:false};
writeFileSync('test-results/stage6/hosted.json',JSON.stringify(hosted,null,2));
const paths=['fault-web/src/components/SignupForm.tsx','fault-web/src/components/Landing.tsx','fault-web/src/app/page.tsx','fault-web/src/app/growth-preview/page.tsx','fault-web/src/lib/contracts.ts','fault-web/tests/growth.test.ts','fault-web/emails/GrowthDraft.tsx'];
writeFileSync('test-results/stage6/change-manifest.json',JSON.stringify({generatedAt:new Date().toISOString(),files:paths.map(path=>({path,sha256:createHash('sha256').update(readFileSync(resolve(root,path))).digest('hex')})),baseline:'test-results/stage5/source-manifest.json',scope:'Stage 6 changed and new reviewed sources; not a full recovery archive'},null,2));
console.log(JSON.stringify({hosted,usage},null,2));
