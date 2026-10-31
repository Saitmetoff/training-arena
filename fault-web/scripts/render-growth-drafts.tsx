import {render} from 'react-email';
import React from 'react';
import {mkdirSync,writeFileSync} from 'node:fs';
import {resolve} from 'node:path';
import assert from 'node:assert/strict';
import GrowthDraft,{GROWTH_DRAFTS,type GrowthKind} from '../emails/GrowthDraft';
const out=resolve('../design/fault-website/growth-2026-10-04-01');mkdirSync(out,{recursive:true});
async function main(){
const results=[];
for(const kind of Object.keys(GROWTH_DRAFTS) as GrowthKind[]){
 const template=<GrowthDraft kind={kind} siteUrl="https://example.invalid/verified-site-required" unsubscribeUrl="https://example.invalid/individual-unsubscribe-required" operatorAddress="[OPERATOR_ADDRESS]" replyToLabel="[REPLY_TO_ADDRESS]" draftNotice/>;
 const html=await render(template),plain=await render(template,{plainText:true});
 assert(Buffer.byteLength(html)<102*1024);assert(html.includes('lang="en"'));assert(html.includes('<h1'));assert(plain.includes('Unsubscribe'));
 assert(!/<svg|<img|display:\s*(flex|grid)/i.test(html));
 writeFileSync(resolve(out,`${kind}.html`),html);writeFileSync(resolve(out,`${kind}.txt`),plain);
 results.push({kind,subject:GROWTH_DRAFTS[kind].subject,bytes:Buffer.byteLength(html),lang:'en',heading:true,plainText:true,images:false,sending:false,links:'Reserved .invalid placeholders only'});
}
writeFileSync('test-results/stage6/email-render.json',JSON.stringify(results,null,2));console.log('Three local email previews and plain-text drafts rendered; no send occurred.');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
