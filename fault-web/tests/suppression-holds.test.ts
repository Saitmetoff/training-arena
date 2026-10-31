import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {PGlite} from '@electric-sql/pglite';
import {HOLD_MIGRATION_PATH} from '../src/lib/server/local-repository';

test('upgrade preserves complaint and abuse holds in both namespaces until manual clearance',async()=>{
  const db=new PGlite();await db.waitReady;
  try {
    await db.exec('create role anon; create role authenticated; create role service_role bypassrls;');
    for(const name of ['20261004112705_fault_waitlist_stage3.sql','20261004161500_fault_waitlist_preview_isolation.sql'])
      await db.exec(await readFile(`../supabase/migrations/${name}`,'utf8'));
    for(const schema of ['fault_waitlist','fault_waitlist_preview']) {
      await db.query(`insert into ${schema}.subscribers(email,consent_at,consent_version,attribution,status,confirmed_at,suppressed,suppression_reason)
        values('held@example.invalid',now(),'test','{}','subscribed',now(),true,'email.complained')`);
      await db.query(`insert into ${schema}.suppressions values('held@example.invalid',true,'email.complained','2026-10-01')`);
    }
    await db.exec(await readFile(HOLD_MIGRATION_PATH,'utf8'));
    // Reapplying the replacement must preserve data and permissions too.
    await db.exec(await readFile(HOLD_MIGRATION_PATH,'utf8'));
    for(const schema of ['fault_waitlist','fault_waitlist_preview']) {
      const rpc=`public.${schema}_command`;
      const command=async(op:string,args:Record<string,unknown>)=>(await db.query<{data:Record<string,unknown>}>(`select ${rpc}($1,$2::jsonb) data`,[op,JSON.stringify(args)])).rows[0].data;
      const event=async(id:string,type:string,day:number,email='held@example.invalid')=>command('webhook',{id,type,timestamp:`2026-10-${String(day).padStart(2,'0')}T00:00:00Z`,recipients:[email]});
      for(const reason of ['email.complained','abuse']) {
        await db.query(`update ${schema}.suppressions set active=true,reason=$1,updated_at='2026-10-01' where email='held@example.invalid'`,[reason]);
        await db.query(`update ${schema}.subscribers set suppressed=true,suppression_reason=$1 where email='held@example.invalid'`,[reason]);
        for(const [index,type] of ['suppression.added','email.bounced','email.suppressed','suppression.removed'].entries()) {
          await event(`${reason}/${index}`,type,index+2);
          assert.deepEqual((await db.query(`select active,reason from ${schema}.suppressions where email='held@example.invalid'`)).rows,[{active:true,reason}]);
          assert.deepEqual((await db.query(`select suppressed,suppression_reason from ${schema}.subscribers where email='held@example.invalid'`)).rows,[{suppressed:true,suppression_reason:reason}]);
          assert.equal((await command('counts',{})).uniqueConfirmedSubscribed,0);
        }
        assert.equal((await event(`${reason}/3`,'suppression.removed',5)).duplicate,true);
      }
      // A normal bounce remains removable; an older removal cannot release it.
      await event('bounce','email.bounced',8,'bounce@example.invalid');
      await event('stale','suppression.removed',7,'bounce@example.invalid');
      assert.equal((await db.query<{active:boolean}>(`select active from ${schema}.suppressions where email='bounce@example.invalid'`)).rows[0].active,true);
      await event('remove','suppression.removed',9,'bounce@example.invalid');
      assert.equal((await db.query<{active:boolean}>(`select active from ${schema}.suppressions where email='bounce@example.invalid'`)).rows[0].active,false);
      // Simulate an explicit administrative clearance, then allow later provider updates.
      await db.exec(`update ${schema}.suppressions set active=false where email='held@example.invalid'; update ${schema}.subscribers set suppressed=false where email='held@example.invalid'`);
      await event('cleared','suppression.removed',10);
      assert.equal((await command('counts',{})).uniqueConfirmedSubscribed,1);
      for(const role of ['anon','authenticated']) {
        await db.exec(`set role ${role}`);await assert.rejects(()=>command('counts',{}));await db.exec('reset role');
      }
      await db.exec('set role service_role');assert.equal((await command('counts',{})).uniqueConfirmedSubscribed,1);await db.exec('reset role');
    }
  } finally {await db.close();}
});
