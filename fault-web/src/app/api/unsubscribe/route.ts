import {getRecoveryService} from '@/lib/server/runtime';
import {jsonBody,requestIP,respond,failure} from '@/lib/server/http';
export const runtime='nodejs';
export const maxDuration=60;
export async function POST(req:Request) {
  try{const input=await jsonBody(req);const service=await getRecoveryService();const result=await service.token('unsubscribe',input,requestIP(req));return respond({state:result.state});}catch(e){return failure(e);}
}
