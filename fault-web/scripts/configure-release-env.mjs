// Owner-authorized server configuration. Values go to Vercel via stdin, never argv/logs.
import {randomBytes} from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {readFileSync,writeFileSync,existsSync,unlinkSync} from 'node:fs';
const store='.local/release-secrets.json';
const saved=existsSync(store)?JSON.parse(readFileSync(store,'utf8')):{};
const jobs=[];
for(const target of ['preview','production'])for(const name of ['FAULT_ENCRYPTION_KEY','FAULT_RATE_LIMIT_SECRET','FAULT_DISPATCH_SECRET','CRON_SECRET']){
 const id=`${target}:${name}`;saved[id]??=randomBytes(32).toString('hex');jobs.push({name,target,value:saved[id],sensitive:true});
}
writeFileSync(store,JSON.stringify(saved));
jobs.push({name:'POSTHOG_PROJECT_KEY',target:'preview,production',value:readFileSync('.local/posthog-ingestion-key','utf8').trim(),sensitive:true});
jobs.push({name:'SUPABASE_URL',target:'preview,production',value:'https://rfruhwgdrlrzhllzmztk.supabase.co',sensitive:false});
jobs.push({name:'POSTHOG_HOST',target:'preview,production',value:'https://eu.i.posthog.com',sensitive:false});
jobs.push({name:'FAULT_DELIVERY_READY',target:'preview,production',value:'false',sensitive:false});
jobs.push({name:'FAULT_ENVIRONMENT',target:'preview',value:'preview',sensitive:false});
jobs.push({name:'FAULT_ENVIRONMENT',target:'production',value:'production',sensitive:false});
const results=[];
for(const job of jobs){
 const run=spawnSync('rtk',['proxy','npx.cmd','--yes','vercel@62.2.0','env','add',job.name,job.target,job.sensitive?'--sensitive':'--no-sensitive','--project','fault-website'],{windowsHide:true,encoding:'utf8',timeout:30_000,input:job.value+'\n'});
 results.push({name:job.name,target:job.target,sensitive:job.sensitive,exitCode:run.status});
 console.log(`${job.name} (${job.target}): ${run.status===0?'stored':'not stored; inspect account configuration'}`);
 if(run.status!==0)break;
}
writeFileSync('test-results/stage5/environment-config.json',JSON.stringify(results,null,2));
unlinkSync('.local/posthog-ingestion-key');
if(results.some(r=>r.exitCode!==0))process.exitCode=1;
