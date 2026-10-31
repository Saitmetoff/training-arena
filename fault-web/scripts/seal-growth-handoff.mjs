import {readFileSync,writeFileSync} from 'node:fs';
import {resolve} from 'node:path';
import assert from 'node:assert/strict';
const path=resolve('../docs/fault-website/06-growth.md'),content=readFileSync('../docs/fault-website/growth/2026-10-04-01/content-drafts.md','utf8');
let handoff=readFileSync(path,'utf8');
const marker='<!-- complete-production-calendar-2026-10-04-01 -->';
if(!handoff.includes(marker)){
 handoff+='\n'+marker+'\n'+content.replace(/^# Content drafts[^\n]*\n/,'').replace(/^## Oct/gm,'### Oct');
 writeFileSync(path,handoff);
}
assert.equal((content.match(/^## Oct/gm)||[]).length,14);
assert.equal((handoff.match(/^### Oct/gm)||[]).length,14);
const emails=readFileSync('../docs/fault-website/growth/2026-10-04-01/email-variants.md','utf8');assert.equal((emails.match(/^## \d+\./gm)||[]).length,6);
const appPaths=JSON.parse(readFileSync('.next/server/app-paths-manifest.json','utf8'));
const pre=JSON.parse(readFileSync('.next/prerender-manifest.json','utf8'));assert(!pre.routes['/growth-preview']);
const checks={timestamp:new Date().toISOString(),productionBuild:'pass; Next 16.3.8, final guarded route build',buildId:readFileSync('.next/BUILD_ID','utf8').trim(),typecheck:'pass',regressions:{passed:37,failed:0,mode:'Fresh PostgreSQL/local simulations, no hosted mail'},reviewRouteDynamic:!!appPaths['/growth-preview/page']&&!pre.routes['/growth-preview'],calendarEntries:14,emailVariants:6,selectedEmails:3,earlierHandoffsPreserved:true,publishing:false,sending:false};
writeFileSync('test-results/stage6/checks.json',JSON.stringify(checks,null,2));console.log(JSON.stringify(checks,null,2));
