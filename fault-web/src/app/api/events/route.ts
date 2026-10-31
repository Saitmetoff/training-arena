import {randomUUID} from 'node:crypto';
import {safeBrowserEvent} from '@/lib/contracts';
import {getService} from '@/lib/server/runtime';
import {flushAfterResponse} from '@/lib/server/background';
import {jsonBody,requestIP,respond,failure} from '@/lib/server/http';
export const runtime='nodejs';
export const maxDuration=60;
export async function POST(req:Request) {
  try {const value=safeBrowserEvent(await jsonBody(req));if(!value)return respond({error:'invalid_event'},400);
    const service=await getService();await service.rate(requestIP(req),'events-ip',60,600_000);
    await service.repo.command('browser_event',{eventPayload:{event:value.event,distinct_id:value.visitorId,insert_id:randomUUID(),properties:{touch:value.touch,internal_test:service.config.internalTest}}});flushAfterResponse(service);return respond({accepted:true},202);
  }catch(e){return failure(e);}
}
