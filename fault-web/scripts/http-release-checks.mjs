import {readFileSync,writeFileSync} from 'node:fs';
import {randomUUID} from 'node:crypto';
import assert from 'node:assert/strict';
const base='http://127.0.0.1:3006',email=`stage5-${Date.now()}@example.invalid`;
const touch={content_id:'fault-dev-test',creative_id:'fault-dev-test-a',utm_source:'test',utm_medium:'test',utm_campaign:'development',utm_content:'fault-dev-test-a',timestamp:new Date().toISOString()};
const visitorId=randomUUID(),evidence={mode:'LOCAL SIMULATION: production build, PGlite and provider spools, no live email',checks:[]};
async function post(path,body,origin=base){const r=await fetch(base+path,{method:'POST',headers:{'Content-Type':'application/json',Origin:origin},body:JSON.stringify(body)});const data=await r.json();return {status:r.status,...data};}
function record(id,value,expected){assert.equal(value.status,expected,id);evidence.checks.push({id,...value});}
record('reject foreign origin',await post('/api/waitlist',{email,consent:true},'https://foreign.invalid'),403);
record('invalid input',await post('/api/waitlist',{email:'invalid',consent:true}),400);
record('forged server event',await post('/api/events',{event:'waitlist_confirmed',visitorId}),400);
record('vital token injection',await post('/api/vitals',{visitorId,metric:{name:'LCP',id:'a'.repeat(64),value:1}}),400);
const signup={email,consent:true,analyticsConsent:true,visitorId,website:'',attribution:{first:touch,last:touch}};
record('pending signup',await post('/api/waitlist',signup),202);
record('duplicate signup',await post('/api/waitlist',signup),202);
const messages=readFileSync('.local/email-spool.jsonl','utf8').trim().split(/\r?\n/).map(l=>JSON.parse(l)).filter(m=>m.to===email);
assert.equal(messages.length,1);evidence.oneMessageForDuplicate=true;
const confirmation=new URL(messages[0].confirmationUrl).hash.slice(7),unsubscribe=new URL(messages[0].unsubscribeUrl).hash.slice(7);
record('confirm once',await post('/api/confirm',{token:confirmation}),200);assert.equal(evidence.checks.at(-1).state,'confirmed');
record('used token replay',await post('/api/confirm',{token:confirmation}),200);assert.equal(evidence.checks.at(-1).state,'used');
record('invalid token',await post('/api/confirm',{token:'0'.repeat(64)}),200);assert.equal(evidence.checks.at(-1).state,'invalid');
record('unsubscribe',await post('/api/unsubscribe',{token:unsubscribe}),200);assert.equal(evidence.checks.at(-1).state,'unsubscribed');
record('unsubscribe replay',await post('/api/unsubscribe',{token:unsubscribe}),200);assert.equal(evidence.checks.at(-1).state,'unsubscribed');
const cron=await fetch(base+'/api/internal/cron');assert.equal(cron.status,401);evidence.cronWithoutSecret=401;
const webhook=await post('/api/webhooks/resend',{type:'email.bounced'});assert.equal(webhook.status,503);evidence.webhookWithoutSecret=503;
// Allow after-response delivery to settle, retaining all identifiers locally only.
await new Promise(r=>setTimeout(r,1000));
const analytics=readFileSync('.local/analytics-spool.jsonl','utf8').trim().split(/\r?\n/).map(l=>JSON.parse(l)).filter(e=>e.distinct_id===visitorId);
const confirmations=analytics.filter(e=>e.event==='waitlist_confirmed');const submits=analytics.filter(e=>e.event==='waitlist_submit');
assert.equal(confirmations.length,1);assert.equal(submits.length,1);
assert.equal(confirmations[0].properties.attribution.last.creative_id,touch.creative_id);
assert(!JSON.stringify(analytics).includes(email));assert(!JSON.stringify(analytics).includes(confirmation));
evidence.transitions={subscriberCreatedEvents:submits.length,confirmationEvents:confirmations.length,creative:'fault-dev-test-a',rawEmailOrTokenInAnalytics:false,internalTest:true};
evidence.remaining=['Live Supabase/Resend/PostHog lifecycle not exercised','Expiry, provider failures/retries, throttling and signed suppression checks use fresh-database integration regressions','Authoritative eligible count/exclusion is proven in regression database, not inferred from HTTP response'];
writeFileSync('test-results/stage5/http-flow.json',JSON.stringify(evidence,null,2));console.log('Local HTTP lifecycle passed; sanitized report saved. No live email sent.');
