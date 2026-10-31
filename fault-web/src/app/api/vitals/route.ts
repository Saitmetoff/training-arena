import {randomUUID} from 'node:crypto';
import {safeVital} from '@/lib/vitals';
import {getService} from '@/lib/server/runtime';
import {flushAfterResponse} from '@/lib/server/background';
import {jsonBody,requestIP,respond,failure} from '@/lib/server/http';
export const runtime='nodejs';
export const maxDuration=60;
export async function POST(req:Request){
  try{
    const value=safeVital(await jsonBody(req));if(!value)return respond({error:'invalid_vital'},400);
    const service=await getService();await service.rate(requestIP(req),'vitals-ip',60,600_000);
    await service.repo.command('browser_event',{eventPayload:{event:'web_vital',distinct_id:value.visitorId,insert_id:randomUUID(),properties:{metric_name:value.metric.name,metric_id:value.metric.id,metric_value:value.metric.value,route:'landing',internal_test:service.config.internalTest}}});
    flushAfterResponse(service);
    return respond({accepted:true},202);
  }catch(e){return failure(e);}
}
