import {getService} from '@/lib/server/runtime';
import {flushAfterResponse} from '@/lib/server/background';
import {jsonBody,requestIP,respond,failure} from '@/lib/server/http';
export const runtime='nodejs';
export const maxDuration=60;
export async function POST(req:Request) {
  try {const input=await jsonBody(req);const service=await getService();await service.signup(input,requestIP(req));flushAfterResponse(service);return respond({state:'pending',message:'If this address is eligible, check your inbox for a confirmation link. Your place is confirmed only after you confirm your email.'},202);}catch(e){return failure(e);}
}
