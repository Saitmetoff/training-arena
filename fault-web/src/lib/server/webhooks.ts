import {Webhook} from 'svix';
import {canonicalEmail,isRecord} from '../contracts';
import type {Repository} from './repository';
export function verifiedEvent(raw:string,headers:Record<string,string>,secret:string) {
  // Installed Svix2 verifies and returns void. Parse only AFTER successful authentication.
  new Webhook(secret).verify(raw,headers);
  return JSON.parse(raw) as unknown;
}
export async function applyVerifiedEvent(repository:Repository,event:unknown,id:string) {
  if(!isRecord(event)||typeof event.type!=='string'||!isRecord(event.data)||!/^msg_[A-Za-z0-9_-]{1,120}$/.test(id))throw new Error('invalid_webhook');
  const types=['email.bounced','email.complained','email.suppressed','suppression.added','suppression.removed','contact.updated'];
  if(!types.includes(event.type))return {ignored:true};
  if(event.type==='contact.updated'&&event.data.unsubscribed!==true)return {ignored:true};
  const timestamp=typeof event.created_at==='string'?event.created_at:'';
  if(!Number.isFinite(Date.parse(timestamp))||Date.parse(timestamp)>Date.now()+60_000)throw new Error('invalid_webhook');
  const candidates=Array.isArray(event.data.to)?event.data.to:[event.data.email];
  const recipients=[...new Set(candidates.map(canonicalEmail).filter((s):s is string=>s!==null))];
  if(!recipients.length||recipients.length>100)throw new Error('invalid_webhook');
  return repository.command('webhook',{id,type:event.type,timestamp,recipients});
}
