// Run from fault-web before a deployment when the source public pages change.
// Copy public files only; preserve challenge resolver/deletion behavior and source config.
import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {resolve} from 'node:path';
const source=resolve('../challenge-web'),target=resolve('public/legacy');
await mkdir(target,{recursive:true});
const files=['index.html','privacy.html','support.html','delete-account.html','config.js','app.js','link.js','styles.css','pages.js','delete_account.js'];
for(const file of files){
 let content=await readFile(resolve(source,file),'utf8');
 if(file.endsWith('.html'))content=content.replace('<head>','<head>\n  <base href="/legacy/">');
 if(file==='index.html')content=content.replaceAll('60 seconds. Push-ups or squats. Camera-counted. Install Fault and accept the live challenge.','Open a Fault challenge link. Product availability depends on the intended app release.');
 await writeFile(resolve(target,file),content);
}
console.log(`Prepared ${files.length} legacy public assets. Source owner/backend configuration still controls release readiness.`);
