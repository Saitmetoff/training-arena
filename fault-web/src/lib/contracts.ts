// Shared validation contains no credentials or provider calls.
export const CONSENT_VERSION = 'fault-updates-2026-10-04';
export const CAMPAIGNS = {
  'fault-growth-r': {creativeIds:['fault-growth-d01-r','fault-growth-d03-r','fault-growth-d05-r','fault-growth-d07-r','fault-growth-d09-r','fault-growth-d11-r','fault-growth-d13-r'],campaign:'growth-iteration-01',sources:['instagram','tiktok','youtube'],medium:'organic-social'},
  'fault-growth-p': {creativeIds:['fault-growth-d02-p','fault-growth-d04-p','fault-growth-d06-p','fault-growth-d08-p','fault-growth-d10-p','fault-growth-d12-p','fault-growth-d14-p'],campaign:'growth-iteration-01',sources:['instagram','tiktok','youtube'],medium:'organic-social'},
  'fault-solo-001': { creativeIds: ['fault-solo-001-vertical-a','fault-solo-001-vertical-b'], campaign:'solo-prelaunch', sources:['instagram','tiktok','youtube'], medium:'organic-social' },
  'fault-bio': { creativeIds:['fault-bio'], campaign:'solo-prelaunch', sources:['instagram','tiktok','youtube'], medium:'bio' },
  'fault-dev-test': { creativeIds:['fault-dev-test-a'], campaign:'development', sources:['test'], medium:'test' }
} as const;
export type Touch = { content_id:string; creative_id:string; utm_source:string; utm_medium:string; utm_campaign:string; utm_content:string; timestamp:string };
export type Attribution = { first:Touch|null; last:Touch|null; credit:'direct'|'last-eligible-touch-30d' };
export function canonicalEmail(input:unknown):string|null {
  if(typeof input!=='string' || /[\r\n\x00-\x1f\x7f]/.test(input)) return null;
  const email=input.trim().toLowerCase();
  if(email.length>254 || !/^[a-z0-9!#$%&'*+\-/=?^_`{|}~]+(?:\.[a-z0-9!#$%&'*+\-/=?^_`{|}~]+)*@(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$/.test(email)) return null;
  if(email.split('@')[0].length>64) return null;
  return email;
}
export function isRecord(input:unknown):input is Record<string,unknown> { return !!input && typeof input==='object' && !Array.isArray(input); }
export function sanitizeTouch(input:unknown,now=Date.now()):Touch|null {
  if(!isRecord(input)) return null;
  const keys=['content_id','creative_id','utm_source','utm_medium','utm_campaign','utm_content','timestamp'];
  if(Object.keys(input).some(k=>!keys.includes(k)) || keys.some(k=>typeof input[k]!=='string')) return null;
  const campaign=CAMPAIGNS[input.content_id as keyof typeof CAMPAIGNS];
  if(!campaign || !(campaign.creativeIds as readonly string[]).includes(input.creative_id as string) || !(campaign.sources as readonly string[]).includes(input.utm_source as string) || input.utm_campaign!==campaign.campaign || input.utm_medium!==campaign.medium || input.utm_content!==input.creative_id) return null;
  const time=Date.parse(input.timestamp as string);
  if(!Number.isFinite(time) || time>now+60_000 || time<now-30*86400_000) return null;
  return Object.fromEntries(keys.map(k=>[k,input[k]])) as Touch;
}
export function sanitizeAttribution(input:unknown,now=Date.now()):Attribution {
  const first=isRecord(input)?sanitizeTouch(input.first,now):null;
  const last=isRecord(input)?sanitizeTouch(input.last,now):null;
  return {first,last,credit:last?'last-eligible-touch-30d':'direct'};
}
export const UUID=/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
export function safeBrowserEvent(input:unknown):{event:string;visitorId:string;touch:Touch|null}|null {
  if(!isRecord(input) || Object.keys(input).some(k=>!['event','visitorId','touch'].includes(k))) return null;
  if(!['landing_view','demo_play','share_click'].includes(input.event as string) || typeof input.visitorId!=='string' || !UUID.test(input.visitorId)) return null;
  if(input.touch!=null && !sanitizeTouch(input.touch)) return null;
  return {event:input.event as string,visitorId:input.visitorId,touch:sanitizeTouch(input.touch)};
}
