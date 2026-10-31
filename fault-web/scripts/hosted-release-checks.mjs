import {spawnSync} from 'node:child_process';
import {readFileSync,writeFileSync} from 'node:fs';
const url='https://fault-website-mdwznrktl-priler003-7576s-projects.vercel.app',out='test-results/stage5';
const evidence={url,deployment:'dpl_CD2k11aeY7AUvFvzTEYUdacA5oNf',target:'preview',routes:[]};
for(const [id,path] of [['home','/'],['challenge','/c/ABC123'],['privacy','/privacy.html'],['support','/support.html'],['delete','/delete-account.html'],['assetlinks','/.well-known/assetlinks.json'],['social','/social-preview.png'],['qa','/qa-media'],['cron','/api/internal/cron']]){
 const body=`${out}/hosted-${id}.body`,head=`${out}/hosted-${id}.headers`;
 const run=spawnSync('rtk',['proxy','npx.cmd','--yes','vercel@62.2.0','curl',path,'--deployment',url,'--','--output',body,'--dump-header',head],{windowsHide:true,encoding:'utf8',timeout:30_000});
 if(run.status!==0)throw new Error(`Hosted check failed ${id}`);
 const h=readFileSync(head,'utf8'),b=readFileSync(body);
 const status=Number([...h.matchAll(/HTTP\/\S+\s+(\d+)/g)].at(-1)?.[1]);
 evidence.routes.push({id,path,status,bytes:b.length,contentType:h.match(/^content-type:\s*(.+)$/im)?.[1]?.trim(),robots:h.match(/^x-robots-tag:\s*(.+)$/im)?.[1]?.trim(),legacyBase:id==='challenge'?b.toString().includes('<base href="/legacy/">'):undefined});
 console.log(`${path}: ${status}`);
}
const post=spawnSync('rtk',['proxy','npx.cmd','--yes','vercel@62.2.0','curl','/api/waitlist','--deployment',url,'--','--request','POST','--header',`Origin: ${url}`,'--header','Content-Type: application/json','--data','{"email":"invalid","consent":true}','--output',`${out}/hosted-signup.body`,'--dump-header',`${out}/hosted-signup.headers`],{windowsHide:true,encoding:'utf8',timeout:30_000});
if(post.status!==0)throw new Error('Hosted API probe failed');
const apiHeaders=readFileSync(`${out}/hosted-signup.headers`,'utf8');
evidence.signupGuard={status:Number([...apiHeaders.matchAll(/HTTP\/\S+\s+(\d+)/g)].at(-1)?.[1]),...JSON.parse(readFileSync(`${out}/hosted-signup.body`,'utf8'))};
const response=await fetch(url,{redirect:'manual'});const body=await response.text();
evidence.anonymous={status:response.status,location:response.headers.get('location')?.split('?')[0]||null,authenticationScreen:/vercel|authentication/i.test(body)&&!body.includes('Give your next set a reason')};
writeFileSync(`${out}/hosted.json`,JSON.stringify(evidence,null,2));
console.log('Sanitized hosted evidence saved. Raw headers remain local only.');
