import {test} from 'node:test';
import assert from 'node:assert/strict';
import {createLocalDatabase} from '../src/lib/server/local-repository';
import {WaitlistService,type Providers} from '../src/lib/server/service';
import type {Repository} from '../src/lib/server/repository';
test('preview cannot claim production outbox or consume its token; counts and dedupe stay separate',async()=>{
 const {db,repository:production}=await createLocalDatabase();
 try{
  const preview:Repository={async command(op,args){return (await db.query<{data:Record<string,unknown>}>('select public.fault_waitlist_preview_command($1,$2::jsonb) data',[op,JSON.stringify(args)])).rows[0].data;}};
  const providers:Providers={async email(){return {ok:false,errorCode:'temporary',retryable:true};},async analytics(){return {ok:true};}};
  const p=new WaitlistService(production,{siteUrl:'https://production.invalid',encryptionKey:'a'.repeat(64),rateSecret:'production',internalTest:false},providers);
  const v=new WaitlistService(preview,{siteUrl:'https://preview.invalid',encryptionKey:'b'.repeat(64),rateSecret:'preview',internalTest:true},providers);
  const input={email:'isolated@example.invalid',consent:true};
  await assert.rejects(()=>p.signup(input,'ip'));await assert.rejects(()=>v.signup(input,'ip'));
  await db.exec("update fault_waitlist.outbox set available_at=now(); update fault_waitlist_preview.outbox set available_at=now()");
  const prodJob=await production.command('claim',{}),previewJob=await preview.command('claim',{});
  assert.ok(prodJob.id);assert.ok(previewJob.id);assert.notEqual(prodJob.id,previewJob.id);
  assert.equal((await preview.command('claim',{jobId:prodJob.id})).id,undefined);
  const token=(await db.query<{digest:string}>("select digest from fault_waitlist.tokens where kind='confirm'")).rows[0].digest;
  assert.equal((await preview.command('confirm',{digest:token})).state,'invalid');
  assert.equal((await production.command('confirm',{digest:token})).state,'confirmed');
  assert.equal((await production.command('counts',{})).uniqueConfirmedSubscribed,1);
  assert.equal((await preview.command('counts',{})).uniqueConfirmedSubscribed,0);
  assert.equal((await db.query<{n:number}>('select count(*)::int n from fault_waitlist.subscribers')).rows[0].n,1);
  assert.equal((await db.query<{n:number}>('select count(*)::int n from fault_waitlist_preview.subscribers')).rows[0].n,1);
  await db.exec('set role anon');await assert.rejects(()=>preview.command('counts',{}));await db.exec('reset role');
 }finally{await db.close();}
});
