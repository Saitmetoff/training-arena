// Stage 5: run ordinary checks, keep raw reports local, expose a compact sanitized index.
import {spawn} from 'node:child_process';
import {mkdir,writeFile} from 'node:fs/promises';
import {resolve} from 'node:path';
const app=resolve('.'),repo=resolve('..'),out=resolve('test-results/stage5');
await mkdir(out,{recursive:true});
const checks=[
 ['typecheck',app,['npm.cmd','run','typecheck']],
 ['regressions',app,['npm.cmd','test']],
 ['build',app,['npm.cmd','run','build']],
 ['dependency-audit',app,['npm.cmd','audit','--omit=dev','--json']],
 ['public-pages',repo,['node','challenge-web/scripts/check.mjs']],
 ['public-pages-release',repo,['node','challenge-web/scripts/check.mjs','--release']],
 ['public-page-tests',repo,['node','--test','challenge-web/test/link.test.mjs','challenge-web/test/public_pages.test.mjs']],
 ['app-links',repo,['node','tools/release/check_app_links.mjs']],
 ['secret-scan',repo,['node','tools/release/secret_scan.mjs']]
];
const results=[];
for(const [id,cwd,args] of checks){
 console.log(`Checking ${id}`);
 const started=Date.now();
 const result=await new Promise(resolveRun=>{
  const child=spawn('rtk',['proxy',...args],{cwd,windowsHide:true,env:{...process.env,FAULT_LOCAL_TEST_MODE:'false'}});let output='';
  child.stdout.on('data',chunk=>{output+=chunk;});child.stderr.on('data',chunk=>{output+=chunk;});
  child.on('error',error=>resolveRun({exitCode:-1,output:error.message}));
  child.on('close',exitCode=>resolveRun({exitCode,output}));
 });
 await writeFile(`${out}/${id}.txt`,result.output);
 let summary=result.output.split(/\r?\n/).filter(line=>/passed|failed|pending|requires|# tests |# pass |# fail |warning:|error:|Compiled|Route \(app\)/i.test(line)).slice(-16);
 if(id==='dependency-audit'){try{const data=JSON.parse(result.output.slice(result.output.indexOf('{')));summary=[JSON.stringify(data.metadata?.vulnerabilities)];}catch{summary=['Audit parser unavailable; inspect raw local report'];}}
 results.push({id,exitCode:result.exitCode,durationMs:Date.now()-started,command:['rtk','proxy',...args].join(' '),report:`fault-web/test-results/stage5/${id}.txt`,summary});
 console.log(`${id}: exit ${result.exitCode}`);
}
await writeFile(`${out}/checks.json`,JSON.stringify(results,null,2));
console.log('Sanitized check index saved to test-results/stage5/checks.json');
