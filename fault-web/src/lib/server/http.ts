import 'server-only';
import {FlowError} from './service';
export function respond(body:unknown,status=200) {return Response.json(body,{status,headers:{'Cache-Control':'no-store'}});}
export function checkOrigin(req:Request) {
  const origin=req.headers.get('origin');const allowed=process.env.FAULT_SITE_URL||(process.env.VERCEL_URL?`https://${process.env.VERCEL_URL}`:undefined);
  if(!origin||!allowed||origin!==new URL(allowed).origin)throw new FlowError(403,'origin_rejected');
  const fetchSite=req.headers.get('sec-fetch-site');if(fetchSite&&fetchSite!=='same-origin'&&fetchSite!=='none')throw new FlowError(403,'origin_rejected');
}
export async function boundedBody(req:Request,max=8192) {
  if(Number(req.headers.get('content-length')||0)>max)throw new FlowError(413,'body_too_large');
  const reader=req.body?.getReader();if(!reader)return '';
  const chunks:Uint8Array[]=[];let length=0;
  for(;;){const {done,value}=await reader.read();if(done)break;length+=value.byteLength;if(length>max){await reader.cancel();throw new FlowError(413,'body_too_large');}chunks.push(value);}
  return Buffer.concat(chunks).toString('utf8');
}
export async function jsonBody(req:Request) {
  checkOrigin(req);if(!req.headers.get('content-type')?.startsWith('application/json'))throw new FlowError(415,'json_required');
  try{return JSON.parse(await boundedBody(req));}catch(e){if(e instanceof FlowError)throw e;throw new FlowError(400,'invalid_json');}
}
export function requestIP(req:Request) {
  // Trust only platform-populated Vercel edge header; never arbitrary forwarded-for locally.
  return process.env.VERCEL?req.headers.get('x-vercel-forwarded-for')?.split(',')[0].trim()||'unknown-edge':'loopback';
}
export function failure(e:unknown) {
  const status=e instanceof FlowError?e.status:503;
  const code=e instanceof FlowError?e.code:'service_unavailable';
  return respond({state:'error',code,message:status===429?'Please wait before trying again.':status===400?'Check your email address and consent, then try again.':status===403?'Open the form on this website to continue.':'We could not complete this request. Please try again shortly.'},status);
}
