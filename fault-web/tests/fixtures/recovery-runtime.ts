import assert from 'node:assert/strict';
import {randomBytes} from 'node:crypto';
import {Webhook} from 'svix';
import {createLocalDatabase} from '../../src/lib/server/local-repository';
import {WaitlistService,type EmailPayload} from '../../src/lib/server/service';

async function main() {
  Object.assign(process.env,{
    FAULT_LOCAL_TEST_MODE:'false',FAULT_ENVIRONMENT:'production',FAULT_SITE_URL:'https://fault.invalid',FAULT_DELIVERY_READY:'false',
    SUPABASE_URL:'https://database.invalid',SUPABASE_SERVICE_ROLE_KEY:'test-service-key',RESEND_API_KEY:'re_fixture',RESEND_FROM:'test@example.invalid',
    FAULT_ENCRYPTION_KEY:'a'.repeat(64),FAULT_RATE_LIMIT_SECRET:'fixture-rate-secret',FAULT_DISPATCH_SECRET:'fixture-dispatch-secret',
    RESEND_WEBHOOK_SECRET:'whsec_'+randomBytes(32).toString('base64')
  });
  const {db,repository}=await createLocalDatabase();
  const originalFetch=globalThis.fetch,unexpected:string[]=[];
  globalThis.fetch=async(input,init)=>{
    const request=new Request(input,init);
    if(request.url!=='https://database.invalid/rest/v1/rpc/fault_waitlist_command') {
      unexpected.push(request.url);throw new Error('Unexpected network request');
    }
    const body=await request.json();return Response.json(await repository.command(body.p_op,body.p_args));
  };
  try {
    const emails:EmailPayload[]=[];
    const seed=new WaitlistService(repository,{siteUrl:'https://fault.invalid',encryptionKey:'a'.repeat(64),rateSecret:'seed',internalTest:false},{
      async email(payload){emails.push(payload);return {ok:false,errorCode:'temporary',retryable:true};},async analytics(){return {ok:true};}
    });
    for(const email of ['leave@example.invalid','complaint@example.invalid','queued@example.invalid'])await assert.rejects(()=>seed.signup({email,consent:true},email));
    await db.exec('update fault_waitlist.outbox set available_at=now()');
    const {POST:unsubscribe}=await import('../../src/app/api/unsubscribe/route');
    const request=(path:string,body:unknown)=>new Request(`https://fault.invalid${path}`,{method:'POST',headers:{origin:'https://fault.invalid','content-type':'application/json'},body:JSON.stringify(body)});
    const optOut=await unsubscribe(request('/api/unsubscribe',{token:new URL(emails[0].unsubscribeUrl).hash.slice(7)}));
    assert.equal(optOut.status,200);assert.deepEqual(await optOut.json(),{state:'unsubscribed'});
    assert.equal((await db.query<{state:string}>("select state from fault_waitlist.outbox o join fault_waitlist.subscribers s on s.id=o.subscriber_id where s.email='leave@example.invalid'")).rows[0].state,'cancelled');

    const {POST:webhook}=await import('../../src/app/api/webhooks/resend/route');
    const id='msg_rollback',date=new Date(),raw=JSON.stringify({type:'email.complained',created_at:date.toISOString(),data:{to:['complaint@example.invalid']}});
    const headers={'svix-id':id,'svix-timestamp':String(Math.floor(date.getTime()/1000)),'svix-signature':new Webhook(process.env.RESEND_WEBHOOK_SECRET!).sign(id,date,raw)};
    for(let i=0;i<2;i++)assert.equal((await webhook(new Request('https://fault.invalid/api/webhooks/resend',{method:'POST',headers,body:raw}))).status,200);
    assert.equal((await webhook(new Request('https://fault.invalid/api/webhooks/resend',{method:'POST',headers,body:raw+' '}))).status,400);
    assert.deepEqual((await db.query("select suppressed,suppression_reason from fault_waitlist.subscribers where email='complaint@example.invalid'")).rows,[{suppressed:true,suppression_reason:'email.complained'}]);

    const runtime=await import('../../src/lib/server/runtime');
    assert.equal(runtime.configured(),false);await assert.rejects(()=>runtime.getService());
    process.env.FAULT_DELIVERY_READY='true';await runtime.getService();process.env.FAULT_DELIVERY_READY='false';
    await assert.rejects(()=>runtime.getService());
    const {POST:signup}=await import('../../src/app/api/waitlist/route');
    assert.equal((await signup(request('/api/waitlist',{email:'new@example.invalid',consent:true}))).status,503);
    const {POST:dispatch}=await import('../../src/app/api/internal/dispatch/route');
    assert.equal((await dispatch(new Request('https://fault.invalid/api/internal/dispatch',{method:'POST',headers:{authorization:'Bearer fixture-dispatch-secret'}}))).status,503);
    assert.deepEqual((await db.query("select state,attempts from fault_waitlist.outbox o join fault_waitlist.subscribers s on s.id=o.subscriber_id where s.email='queued@example.invalid'")).rows,[{state:'queued',attempts:1}]);
    assert.deepEqual(unexpected,[]);
    console.log('Recovery routes verified; no provider requests or extra delivery.');
  } finally {globalThis.fetch=originalFetch;await db.close();}
}
main().catch(error=>{console.error(error);process.exitCode=1;});
