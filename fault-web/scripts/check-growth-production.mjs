import {spawn} from 'node:child_process';
import {writeFileSync} from 'node:fs';
import assert from 'node:assert/strict';
const port=3009,base=`http://127.0.0.1:${port}`;
const child=spawn('rtk',['proxy','node','node_modules/next/dist/bin/next','start','--hostname','127.0.0.1','--port',String(port)],{windowsHide:true,stdio:'ignore',env:{...process.env,FAULT_ENVIRONMENT:'production',VERCEL_ENV:'production',FAULT_LOCAL_TEST_MODE:'false',FAULT_DELIVERY_READY:'false',FAULT_SITE_URL:base}});
try{
 let ready=false;for(let i=0;i<50;i++){try{const r=await fetch(base);if(r.ok){ready=true;break;}}catch{}await new Promise(r=>setTimeout(r,200));}assert(ready);
 const route=await fetch(base+'/growth-preview');assert.equal(route.status,404);
 writeFileSync('test-results/stage6/production-guard.json',JSON.stringify({mode:'Local production environment with delivery disabled; no service writes',root:200,growthPreview:route.status,runtimeGuard:true},null,2));
 console.log('Production environment returns 404 for the growth preview.');
}finally{
 // Terminate only the newly spawned process tree, never a guessed or reused PID.
 const {spawnSync}=await import('node:child_process');spawnSync('rtk',['proxy','taskkill','/PID',String(child.pid),'/T','/F'],{windowsHide:true,stdio:'ignore'});
}
