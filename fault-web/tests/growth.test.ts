import {test} from 'node:test';
import assert from 'node:assert/strict';
import {CAMPAIGNS,sanitizeAttribution,safeBrowserEvent} from '../src/lib/contracts';
test('all fourteen planned creatives retain source credit; mismatched format and unapproved labels fail closed',()=>{
 const timestamp=new Date().toISOString();
 for(let day=1;day<=14;day++){
  const format=day%2?'r':'p',content_id=`fault-growth-${format}`,creative_id=`fault-growth-d${String(day).padStart(2,'0')}-${format}`;
  for(const utm_source of ['instagram','tiktok','youtube']){
   const touch={content_id,creative_id,utm_source,utm_medium:'organic-social',utm_campaign:'growth-iteration-01',utm_content:creative_id,timestamp};
   const credit=sanitizeAttribution({first:touch,last:touch});
   assert.equal(credit.last?.creative_id,creative_id);
   assert.equal(credit.credit,'last-eligible-touch-30d');
   assert.equal(safeBrowserEvent({event:'landing_view',visitorId:'123e4567-e89b-42d3-a456-426614174000',touch})?.touch?.utm_source,utm_source);
   assert.equal(sanitizeAttribution({last:{...touch,content_id:format==='r'?'fault-growth-p':'fault-growth-r'}}).last,null);
   assert.equal(sanitizeAttribution({last:{...touch,utm_content:'someone@example.com'}}).last,null);
  }
 }
 assert.equal(CAMPAIGNS['fault-growth-r'].creativeIds.length+CAMPAIGNS['fault-growth-p'].creativeIds.length,14);
});
