/// <reference types="node" />
import {Resend} from 'resend';
import {canonicalEmail} from '../src/lib/contracts';
import {supabaseRepository} from '../src/lib/server/repository';

// Run in the intended development environment before accepting live signups.
// Authentication to the provider API establishes provenance; never import an unverified user-supplied list.
async function main(){
 const required=['RESEND_API_KEY','SUPABASE_URL','SUPABASE_SERVICE_ROLE_KEY'];
 if(required.some(k=>!process.env[k]))throw Error('configuration_required');
 if(process.env.FAULT_ENVIRONMENT==='production')throw Error('development_only');
 const resend=new Resend(process.env.RESEND_API_KEY);
  const repo=await supabaseRepository(process.env.SUPABASE_URL!,process.env.SUPABASE_SERVICE_ROLE_KEY!,'preview');
 let after:string|undefined,imported=0;
 for(let page=0;page<10000;page++){
  const {data,error}=await resend.suppressions.list({limit:100,...(after?{after}:{})},{signal:AbortSignal.timeout(10000)});
  if(error||!data)throw Error('provider_read_failed');
  for(const item of data.data){
   const email=canonicalEmail(item.email);
   if(!email||!Number.isFinite(Date.parse(item.created_at)))throw Error('provider_record_invalid');
   await repo.command('webhook',{id:`resend-reconcile/${item.id}`,type:item.origin==='complaint'?'email.complained':'suppression.added',timestamp:item.created_at,recipients:[email]});
   imported++;
  }
  if(!data.has_more){console.log(JSON.stringify({reconciled:imported,metric:await repo.command('counts',{})}));return;}
  const next=data.data.at(-1)?.id;if(!next||next===after)throw Error('provider_cursor_invalid');after=next;
 }
 throw Error('pagination_limit');
}
main().catch(()=>{console.error('Suppression reconciliation failed; signups remain gated until configuration and provider access are verified.');process.exitCode=1;});
