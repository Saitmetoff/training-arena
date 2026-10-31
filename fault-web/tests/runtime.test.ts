import {test} from 'node:test';
import assert from 'node:assert/strict';
import {execFile} from 'node:child_process';
import {promisify} from 'node:util';
const run=promisify(execFile);

test('rollback keeps recovery routes open and collection/delivery closed',async()=>{
  const result=await run(process.execPath,['--import','tsx','--conditions=react-server','tests/fixtures/recovery-runtime.ts'],{timeout:60_000});
  assert.match(result.stdout,/Recovery routes verified/);
});

test('development suppression reconciliation only calls the preview RPC',async()=>{
  for(const environment of ['development','preview']) {
    const result=await run(process.execPath,['--import','tsx','--require','./tests/fixtures/reconcile-transport.cjs','scripts/reconcile-suppressions.ts'],{
      timeout:30_000,env:{...process.env,FAULT_ENVIRONMENT:environment,RESEND_API_KEY:'re_fixture',SUPABASE_URL:'https://database.invalid',SUPABASE_SERVICE_ROLE_KEY:'test-service-key'}
    });
    assert.match(result.stdout,/"reconciled":1/);
  }
  await assert.rejects(()=>run(process.execPath,['--import','tsx','scripts/reconcile-suppressions.ts'],{
    timeout:30_000,env:{...process.env,FAULT_ENVIRONMENT:'production',RESEND_API_KEY:'re_fixture',SUPABASE_URL:'https://database.invalid',SUPABASE_SERVICE_ROLE_KEY:'test-service-key'}
  }));
});
