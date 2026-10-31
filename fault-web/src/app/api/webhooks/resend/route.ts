import {getRecoveryService} from '@/lib/server/runtime';
import {verifiedEvent,applyVerifiedEvent} from '@/lib/server/webhooks';
import {boundedBody,respond,failure} from '@/lib/server/http';
export const runtime='nodejs';
export async function POST(req:Request) {
  if(!process.env.RESEND_WEBHOOK_SECRET)return respond({error:'webhook_not_configured'},503);
  let event:unknown;const id=req.headers.get('svix-id')||'';
  try {event=verifiedEvent(await boundedBody(req,256*1024),{'svix-id':id,'svix-timestamp':req.headers.get('svix-timestamp')||'','svix-signature':req.headers.get('svix-signature')||''},process.env.RESEND_WEBHOOK_SECRET);}catch{return respond({error:'invalid_signature'},400);}
  try {await applyVerifiedEvent((await getRecoveryService()).repo,event,id);return respond({received:true});}catch(e){return failure(e);}
}
