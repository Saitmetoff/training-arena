import {test} from 'node:test';
import assert from 'node:assert/strict';
import {safeVital} from '../src/lib/vitals';
const visitorId='123e4567-e89b-42d3-a456-426614174000';
const metric={name:'LCP',id:'v4-1791127763671-1234567890123',value:2100};
test('field measurements accept bounded metrics, including real zero CLS',()=>{
  assert.ok(safeVital({visitorId,metric}));
  assert.ok(safeVital({visitorId,metric:{...metric,name:'CLS',value:0}}));
  assert.ok(safeVital({visitorId,metric:{...metric,name:'INP',value:180}}));
});
test('field measurements reject raw entries, URLs, email, tokens and forged events',()=>{
  for(const extra of [{email:'synthetic@example.invalid'},{url:'/confirm#token=private'},{entries:[]},{event:'waitlist_confirmed'}])assert.equal(safeVital({visitorId,metric,...extra}),null);
  for(const change of [{name:'waitlist_confirmed'},{value:-1},{value:Infinity},{value:NaN},{value:600001},{id:'a'.repeat(64)},{id:'synthetic@example.invalid'},{entries:[]}])assert.equal(safeVital({visitorId,metric:{...metric,...change}}),null);
  assert.equal(safeVital({visitorId:'synthetic@example.invalid',metric}),null);
  assert.equal(safeVital({visitorId,metric:{...metric,name:'CLS',value:101}}),null);
});
