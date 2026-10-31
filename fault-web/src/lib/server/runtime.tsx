import 'server-only';
import {createElement} from 'react';
import {render} from 'react-email';
import {Resend} from 'resend';
import {appendFile,mkdir} from 'node:fs/promises';
import Confirmation from '../../../emails/Confirmation';
import {WaitlistService,FlowError,type Providers} from './service';
import {supabaseRepository} from './repository';
let service:Promise<WaitlistService>|undefined;
export function localTestEnabled() {
  return process.env.FAULT_LOCAL_TEST_MODE==='true'&&!process.env.VERCEL&&['127.0.0.1','localhost','[::1]'].includes(new URL(process.env.FAULT_SITE_URL||'https://example.invalid').hostname);
}
export function configured() {
  return credentialsConfigured()&&(localTestEnabled()||process.env.FAULT_DELIVERY_READY==='true');
}
function credentialsConfigured() {
  return localTestEnabled()||['SUPABASE_URL','SUPABASE_SERVICE_ROLE_KEY','RESEND_API_KEY','RESEND_FROM','FAULT_ENCRYPTION_KEY','FAULT_RATE_LIMIT_SECRET'].every(k=>!!process.env[k]);
}
async function init() {
  if(!credentialsConfigured())throw new FlowError(503,'configuration_required');
  const siteUrl=(process.env.FAULT_SITE_URL||(process.env.VERCEL_URL?`https://${process.env.VERCEL_URL}`:'')).replace(/\/$/,'');
  const site=new URL(siteUrl);if(site.protocol!=='https:'&&!localTestEnabled())throw new FlowError(503,'https_required');
  const key=process.env.FAULT_ENCRYPTION_KEY||'';if(!/^[a-f0-9]{64}$/.test(key)||!process.env.FAULT_RATE_LIMIT_SECRET)throw new FlowError(503,'configuration_required');
  const local=localTestEnabled();
  const repo=local?await (await import('./local-repository')).localRepository():await supabaseRepository(process.env.SUPABASE_URL!,process.env.SUPABASE_SERVICE_ROLE_KEY!,process.env.FAULT_ENVIRONMENT==='production'?'production':'preview');
  const resend=local?null:new Resend(process.env.RESEND_API_KEY);
  const providers:Providers={
    async email(payload,jobId) {
      const component=createElement(Confirmation,{confirmationUrl:payload.confirmationUrl,unsubscribeUrl:payload.unsubscribeUrl});
      const [html,text]=await Promise.all([render(component),render(component,{plainText:true})]);
      if(local) {
        await mkdir('.local',{recursive:true});
        await appendFile('.local/email-spool.jsonl',JSON.stringify({jobId,...payload,html,text})+'\n');
        return {ok:true,providerId:`local-${jobId}`};
      }
      const {data,error}=await resend!.emails.send({from:process.env.RESEND_FROM!,to:[payload.to],subject:'Confirm your Fault email',html,text,tags:[{name:'fault_job',value:jobId}],headers:{'List-Unsubscribe':`<${payload.unsubscribeUrl}>`}},{idempotencyKey:`fault-confirmation/${jobId}`,signal:AbortSignal.timeout(10_000)});
      if(error)return {ok:false,errorCode:error.name,retryable:(error as {statusCode?:number}).statusCode===429||((error as {statusCode?:number}).statusCode??0)>=500};
      return {ok:true,providerId:data!.id};
    },
    async analytics(payload,jobId) {
      const props=payload.properties as Record<string,unknown>;
      const attribution=props.attribution as {last?:Record<string,unknown>}|undefined;
      const touch=attribution?.last||(props.touch as Record<string,unknown>|null);
      const clean:Record<string,unknown>={...payload,properties:{...props,...(touch||{}),site:'fault',environment:process.env.FAULT_ENVIRONMENT||'development','$insert_id':jobId,'$process_person_profile':false,'$geoip_disable':true}};
      delete clean.insert_id;
      if(local) {await appendFile('.local/analytics-spool.jsonl',JSON.stringify(clean)+'\n');return {ok:true,providerId:`local-${jobId}`};}
      if(!process.env.POSTHOG_PROJECT_KEY)return {ok:false,errorCode:'analytics_not_configured',retryable:true};
      const host=process.env.POSTHOG_HOST||'https://eu.i.posthog.com';
      if(!['https://us.i.posthog.com','https://eu.i.posthog.com'].includes(host))return {ok:false,errorCode:'analytics_host_invalid'};
      const response=await fetch(`${host}/i/v0/e/`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({api_key:process.env.POSTHOG_PROJECT_KEY,...clean}),signal:AbortSignal.timeout(10_000)});
      return {ok:response.ok,providerId:jobId,errorCode:response.ok?undefined:`analytics_http_${response.status}`,retryable:response.status===429||response.status>=500};
    }
  };
  const internalTest=process.env.FAULT_ENVIRONMENT!=='production';
  const allowedRecipients=internalTest?(process.env.FAULT_TEST_RECIPIENTS||'').split(',').map(e=>e.trim().toLowerCase()).filter(Boolean):undefined;
  if(internalTest&&!local&&!allowedRecipients?.length)throw new FlowError(503,'test_recipient_required');
  return new WaitlistService(repo,{siteUrl,encryptionKey:key,rateSecret:process.env.FAULT_RATE_LIMIT_SECRET!,internalTest,allowedRecipients},providers);
}
// Recovery callers can apply opt-outs and suppressions while collection/delivery is closed.
export async function getRecoveryService():Promise<Pick<WaitlistService,'repo'|'token'>> {
  try{return await (service??=init());}catch(e){service=undefined;throw e;}
}
export async function getService() {
  // Check on every request, including after the recovery path initializes the cache.
  if(!configured())throw new FlowError(503,'configuration_required');
  try{return await (service??=init());}catch(e){service=undefined;throw e;}
}
