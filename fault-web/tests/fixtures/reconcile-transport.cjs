// Exercise the real CLI and SDKs while rejecting all unexpected network requests.
const assert=require('node:assert/strict');
const calls=[];
globalThis.fetch=async(input,init)=>{
  const request=new Request(input,init);
  if(request.url.startsWith('https://api.resend.com/suppressions'))return Response.json({
    object:'list',data:[{id:'fixture-suppression',email:'Held@Example.invalid',origin:'complaint',created_at:'2026-10-01T00:00:00Z'}],has_more:false
  });
  assert.equal(request.url,'https://database.invalid/rest/v1/rpc/fault_waitlist_preview_command');
  const body=await request.json();calls.push(body);
  return Response.json(body.p_op==='counts'?{uniqueConfirmedSubscribed:0}:{processed:true});
};
process.on('beforeExit',()=>{
  assert.deepEqual(calls.map(c=>c.p_op),['webhook','counts']);
  assert.equal(calls[0].p_args.type,'email.complained');
  assert.deepEqual(calls[0].p_args.recipients,['held@example.invalid']);
});
