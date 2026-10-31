import {getService} from '@/lib/server/runtime';
import {flushAfterResponse} from '@/lib/server/background';
import {jsonBody,requestIP,respond,failure} from '@/lib/server/http';
export const runtime='nodejs';
export const maxDuration=60;
export async function POST(req:Request) {
  try{const input=await jsonBody(req);const service=await getService();const result=await service.token('confirm',input,requestIP(req));flushAfterResponse(service);return respond({state:result.state});}catch(e){return failure(e);}
}
