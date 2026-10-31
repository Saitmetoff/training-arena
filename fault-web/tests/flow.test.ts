/// <reference types="node" />
import test from 'node:test';
import assert from 'node:assert/strict';
import {randomUUID,randomBytes} from 'node:crypto';
import {createLocalDatabase} from '../src/lib/server/local-repository';
import {WaitlistService,type EmailPayload,type Providers,FlowError} from '../src/lib/server/service';
import {digest} from '../src/lib/server/crypto';
import {applyVerifiedEvent,verifiedEvent} from '../src/lib/server/webhooks';
import {Webhook} from 'svix';
test('PostgreSQL-backed signup, token lifecycle, retries, attribution and exclusions',async t=>{
  const {db,repository}=await createLocalDatabase();
  const emails:EmailPayload[]=[],events:Record<string,unknown>[]=[];let failEmail=false;
  const providers:Providers={async email(payload){if(failEmail)return {ok:false,errorCode:'temporary',retryable:true};emails.push(payload);return {ok:true,providerId:randomUUID()};},async analytics(payload){events.push(payload);return {ok:true,providerId:randomUUID()};}};
  const service=new WaitlistService(repository,{siteUrl:'https://fault-test.invalid',encryptionKey:'a'.repeat(64),rateSecret:'test-secret',internalTest:false},providers);
  const touch={content_id:'fault-dev-test',creative_id:'fault-dev-test-a',utm_source:'test',utm_medium:'test',utm_campaign:'development',utm_content:'fault-dev-test-a',timestamp:new Date().toISOString()};
  const input={email:' Person@Example.com ',consent:true,website:'',analyticsConsent:true,visitorId:randomUUID(),attribution:{first:touch,last:touch}};
  const token=(url:string)=>new URL(url).hash.slice(7);
  await t.test('pending is durable and duplicate addresses create one row/message',async()=>{
    const first=await service.signup(input,'ip1');assert.equal(first.created,true);
    const second=await service.signup({...input,email:'person@example.com'},'ip1');assert.equal(second.created,false);
    assert.equal(emails.length,1);
    assert.equal((await repository.command('counts',{})).uniqueConfirmedSubscribed,0);
    assert.equal((await db.query<{n:number}>('select count(*)::integer n from fault_waitlist.subscribers')).rows[0].n,1);
  });
  await t.test('confirmation changes state once; cross-device source retained; replay has no extra event',async()=>{
    const payload=emails[0];assert.equal((await service.token('confirm',{token:token(payload.confirmationUrl)},'other-device')).state,'confirmed');
    assert.equal((await service.token('confirm',{token:token(payload.confirmationUrl)},'other-device')).state,'used');
    assert.equal((await repository.command('counts',{})).uniqueConfirmedSubscribed,1);
    const out=await db.query<{dedupe_key:string;event_payload:Record<string,unknown>}>("select dedupe_key,event_payload from fault_waitlist.outbox where kind='analytics'");
    assert.equal(out.rows.filter(r=>r.dedupe_key.startsWith('waitlist_confirmed/')).length,1);
    const confirm=out.rows.find(r=>r.dedupe_key.startsWith('waitlist_confirmed/'))!.event_payload;
    assert.equal(confirm.distinct_id,input.visitorId);
    assert.equal((confirm.properties as {attribution:{last:typeof touch}}).attribution.last.creative_id,'fault-dev-test-a');
    assert(!JSON.stringify(out.rows).includes('person@example.com'));assert(!JSON.stringify(out.rows).includes(token(payload.confirmationUrl)));
  });
  await t.test('unsubscribe is idempotent and immediately excludes the address',async()=>{
    const value=token(emails[0].unsubscribeUrl);
    assert.equal((await service.token('unsubscribe',{token:value},'ip1')).state,'unsubscribed');
    assert.equal((await service.token('unsubscribe',{token:value},'ip1')).state,'unsubscribed');
    assert.equal((await repository.command('counts',{})).uniqueConfirmedSubscribed,0);
  });
  await t.test('expiry, invalid tokens and cancellation after unsubscribe fail safely',async()=>{
    await service.signup({...input,email:'expires@example.com'},'ip2');const payload=emails.at(-1)!;
    await db.query("update fault_waitlist.tokens set expires_at=now()-interval '1 second' where digest=$1",[digest(token(payload.confirmationUrl))]);
    assert.equal((await service.token('confirm',{token:token(payload.confirmationUrl)},'ip2')).state,'expired');
    assert.equal((await service.token('confirm',{token:'0'.repeat(64)},'ip2')).state,'invalid');
    await service.signup({...input,email:'leave@example.com'},'ip3');const leave=emails.at(-1)!;
    await service.token('unsubscribe',{token:token(leave.unsubscribeUrl)},'ip3');
    assert.equal((await service.token('confirm',{token:token(leave.confirmationUrl)},'ip3')).state,'used');
  });
  await t.test('durable delivery retry keeps one stable job and token',async()=>{
    failEmail=true;await assert.rejects(()=>service.signup({...input,email:'retry@example.com'},'ip4'),(e:unknown)=>e instanceof FlowError&&e.status===503);
    const jobs=await db.query<{id:string;encrypted_payload:string;state:string}>("select o.id,o.encrypted_payload,o.state from fault_waitlist.outbox o join fault_waitlist.subscribers s on s.id=o.subscriber_id where s.email='retry@example.com' and kind='email'");
    assert.equal(jobs.rows.length,1);assert.equal(jobs.rows[0].state,'queued');assert(!jobs.rows[0].encrypted_payload.includes('retry@example.com'));
    await db.query('update fault_waitlist.outbox set available_at=now() where id=$1',[jobs.rows[0].id]);
    failEmail=false;assert.equal((await service.dispatch(jobs.rows[0].id)).ok,true);
    const after=await db.query<{state:string;encrypted_payload:string|null}>('select state,encrypted_payload from fault_waitlist.outbox where id=$1',[jobs.rows[0].id]);
    assert.equal(after.rows[0].state,'sent');assert.equal(after.rows[0].encrypted_payload,null);
  });
  await t.test('verified suppression receipts replay safely and stale removals cannot reinclude',async()=>{
    await service.signup({...input,email:'suppressed@example.com'},'ip5');const payload=emails.at(-1)!;
    await service.token('confirm',{token:token(payload.confirmationUrl)},'ip5');
    const timestamp=new Date().toISOString();const event={type:'email.bounced',created_at:timestamp,data:{to:['suppressed@example.com']}};
    assert.equal((await applyVerifiedEvent(repository,event,'msg_bounce1')).processed,true);
    assert.equal((await applyVerifiedEvent(repository,event,'msg_bounce1')).duplicate,true);
    await applyVerifiedEvent(repository,{type:'suppression.removed',created_at:new Date(Date.now()-60_000).toISOString(),data:{email:'suppressed@example.com'}},'msg_oldremove');
    assert.equal((await repository.command('counts',{})).uniqueConfirmedSubscribed,0);
  });
  await t.test('spoofed, modified and old signatures cannot mutate data',async()=>{
    const secret='whsec_'+randomBytes(32).toString('base64');const webhook=new Webhook(secret),id='msg_signed1',date=new Date();
    const raw=JSON.stringify({type:'email.complained',created_at:date.toISOString(),data:{to:['retry@example.com']}});
    const signature=webhook.sign(id,date,raw);const headers={'svix-id':id,'svix-timestamp':String(Math.floor(date.getTime()/1000)),'svix-signature':signature};
    assert.throws(()=>verifiedEvent(raw+' ',headers,secret));assert.throws(()=>verifiedEvent(raw,{...headers,'svix-timestamp':'1'},secret));
    await applyVerifiedEvent(repository,verifiedEvent(raw,headers,secret),id);
    assert.equal((await db.query<{suppressed:boolean}>("select suppressed from fault_waitlist.subscribers where email='retry@example.com'")).rows[0].suppressed,true);
  });
  await t.test('public roles cannot read addresses or execute the RPC',async()=>{
    await db.exec('set role anon');
    await assert.rejects(()=>db.query('select * from fault_waitlist.subscribers'));
    await assert.rejects(()=>repository.command('counts',{}));await db.exec('reset role');
    await db.exec('set role authenticated');await assert.rejects(()=>repository.command('counts',{}));await db.exec('reset role');
    await db.exec('set role service_role');assert.equal((await repository.command('counts',{})).uniqueConfirmedSubscribed,0);await db.exec('reset role');
  });
  await t.test('persistent rate limits, tests and abuse remain excluded',async()=>{
    for(let i=0;i<3;i++)await service.rate('flood','test',3,600_000);
    await assert.rejects(()=>service.rate('flood','test',3,600_000),(e:unknown)=>e instanceof FlowError&&e.status===429);
    await db.exec("update fault_waitlist.subscribers set status='subscribed',confirmed_at=now(),suppressed=false,internal_test=true where email='retry@example.com'");
    assert.equal((await repository.command('counts',{})).uniqueConfirmedSubscribed,0);
    await db.exec("update fault_waitlist.subscribers set internal_test=false,abuse=true where email='retry@example.com'");
    assert.equal((await repository.command('counts',{})).uniqueConfirmedSubscribed,0);
  });
  await t.test('fresh consent can rejoin without a duplicate address; each confirmation transition emits once',async()=>{
    const rejoin={...input,email:'rejoin@example.invalid'};
    await service.signup(rejoin,'rejoin-ip');
    const initial=emails.at(-1)!;
    await service.token('confirm',{token:token(initial.confirmationUrl)},'rejoin-ip');
    await service.token('unsubscribe',{token:token(initial.unsubscribeUrl)},'rejoin-ip');
    await db.exec("update fault_waitlist.subscribers set last_requested_at=now()-interval '61 seconds' where email='rejoin@example.invalid'");
    const again=await service.signup(rejoin,'rejoin-ip');assert.equal(again.created,false);
    const latest=emails.at(-1)!;
    const result=await service.token('confirm',{token:token(latest.confirmationUrl)},'rejoin-ip');
    assert.equal(result.firstConfirmation,false);assert.equal(result.transition,true);
    assert.equal((await service.token('confirm',{token:token(latest.confirmationUrl)},'rejoin-ip')).state,'used');
    const row=(await db.query<{id:string}>("select id from fault_waitlist.subscribers where email='rejoin@example.invalid'")).rows[0];
    const confirmations=(await db.query<{n:number}>("select count(*)::integer n from fault_waitlist.outbox where subscriber_id=$1 and event_payload->>'event'='waitlist_confirmed'",[row.id])).rows[0].n;
    assert.equal(confirmations,2);
    assert.equal((await repository.command('counts',{})).uniqueConfirmedSubscribed,1);
    await service.token('unsubscribe',{token:token(latest.unsubscribeUrl)},'rejoin-ip');
    assert.equal((await repository.command('counts',{})).uniqueConfirmedSubscribed,0);
  });
  await db.close();
});
