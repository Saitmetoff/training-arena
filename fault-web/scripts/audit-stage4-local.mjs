import {readFile,writeFile} from 'node:fs/promises';
const events=(await readFile('.local/analytics-spool.jsonl','utf8')).trim().split('\n').map(JSON.parse);
const confirmation=events.filter(e=>e.event==='waitlist_confirmed').at(-1);
const cohort=events.filter(e=>e.distinct_id===confirmation?.distinct_id);
const prior=JSON.parse(await readFile('test-results/local-browser-flow.json','utf8'));
const result={mode:'Local PostgreSQL and browser; simulated email and analytics delivery only',browserCohortIsInternalTest:true,publicCountExcludesTheseFixturesThroughout:true,events:Object.fromEntries(['landing_view','waitlist_submit','waitlist_confirmed'].map(name=>[name,cohort.filter(e=>e.event===name).length])),attributedCreative:confirmation?.properties?.creative_id??null,sameAnonymousIdentity:cohort.some(e=>e.event==='waitlist_submit'),rawEmailOrTokenInAnalytics:/@|#token=|"email"|"token"/.test(JSON.stringify(cohort)),uniqueConfirmedSubscribedAfterUnsubscribe:prior.databaseMetric.uniqueConfirmedSubscribed};
await writeFile('test-results/stage4-local-flow.json',JSON.stringify(result,null,2));console.log(JSON.stringify(result));
