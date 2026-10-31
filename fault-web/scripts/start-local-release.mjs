import {spawn} from 'node:child_process';
const port=process.argv[2]||'3002';if(!/^30\d{2}$/.test(port))throw new Error('Local release port must be in 3000–3099');
const child=spawn('rtk',['proxy','node','node_modules/next/dist/bin/next','start','--hostname','127.0.0.1','--port',port],{windowsHide:true,stdio:'inherit',env:{...process.env,FAULT_SITE_URL:`http://127.0.0.1:${port}`,FAULT_ENVIRONMENT:'development',FAULT_LOCAL_TEST_MODE:'true'}});
child.on('close',code=>{process.exitCode=code??1;});
