import {randomUUID} from 'node:crypto';
import {canonicalEmail,CONSENT_VERSION,isRecord,sanitizeAttribution,UUID} from '../contracts';
import {digest,newToken,seal,privateBucket,unseal} from './crypto';
import type {Repository,CommandResult} from './repository';
export type EmailPayload={to:string;confirmationUrl:string;unsubscribeUrl:string};
export type Job={id:string;kind:'email'|'analytics';lease_id:string;attempts:number;created_at:string;encrypted_payload:string;event_payload:Record<string,unknown>};
export type ProviderResult={ok:boolean;providerId?:string;errorCode?:string;retryable?:boolean};
export interface Providers { email(payload:EmailPayload,jobId:string):Promise<ProviderResult>; analytics(payload:Record<string,unknown>,jobId:string):Promise<ProviderResult> }
export type ServiceConfig={siteUrl:string;encryptionKey:string;rateSecret:string;internalTest:boolean;allowedRecipients?:string[]};
export class FlowError extends Error {constructor(public status:number,public code:string){super(code);}}
export class WaitlistService {
  constructor(public repo:Repository,public config:ServiceConfig,public providers:Providers){}
  async rate(value:string,scope:string,limit:number,windowMs:number) {
    const window=Math.floor(Date.now()/windowMs);
    const result=await this.repo.command('rate',{key:`${scope}:${window}:${privateBucket(value,this.config.rateSecret)}`,limit,expiresAt:new Date((window+2)*windowMs).toISOString()});
    if(!result.allowed)throw new FlowError(429,'rate_limited');
  }
  async signup(input:unknown,ip:string) {
    await this.rate(ip,'signup-ip',10,600_000);
    if(!isRecord(input))throw new FlowError(400,'invalid_request');
    if(typeof input.website==='string'&&input.website.length)return {state:'pending',created:false};
    if(Object.keys(input).some(k=>!['email','consent','website','attribution','visitorId','analyticsConsent'].includes(k)))throw new FlowError(400,'invalid_request');
    const email=canonicalEmail(input.email);
    if(!email||input.consent!==true)throw new FlowError(400,'invalid_email_or_consent');
    if(this.config.allowedRecipients?.length && !this.config.allowedRecipients.includes(email))throw new FlowError(503,'test_recipient_only');
    await this.rate(email,'signup-address',3,3600_000);
    const confirmation=newToken(),unsubscribe=newToken(),now=Date.now(),jobId=randomUUID();
    const analyticsConsent=input.analyticsConsent===true;
    const visitorId=analyticsConsent&&typeof input.visitorId==='string'&&UUID.test(input.visitorId)?input.visitorId:null;
    const payload:EmailPayload={to:email,confirmationUrl:`${this.config.siteUrl}/confirm#token=${confirmation}`,unsubscribeUrl:`${this.config.siteUrl}/unsubscribe#token=${unsubscribe}`};
    const result=await this.repo.command('signup',{email,consentVersion:CONSENT_VERSION,attribution:sanitizeAttribution(input.attribution),visitorId,analyticsConsent,
      internalTest:this.config.internalTest,jobId,encryptedPayload:seal(payload,this.config.encryptionKey),tokens:[
        {kind:'confirm',digest:digest(confirmation),expiresAt:new Date(now+86400_000).toISOString()},
        {kind:'unsubscribe',digest:digest(unsubscribe),expiresAt:new Date(now+365*86400_000).toISOString()}]});
    if(result.jobId) {
      const sent=await this.dispatch(String(result.jobId));
      if(!sent.ok)throw new FlowError(503,'confirmation_delivery_pending');
    } else {
      // Recover durable work from a previous request without creating another address.
      await this.dispatch();
    }
    return result;
  }
  async token(action:'confirm'|'unsubscribe',input:unknown,ip:string) {
    await this.rate(ip,'token-ip',30,600_000);
    if(!isRecord(input)||Object.keys(input).some(k=>k!=='token')||typeof input.token!=='string'||!/^[a-f0-9]{64}$/.test(input.token))return {state:'invalid'};
    return this.repo.command(action,{digest:digest(input.token)});
  }
  async dispatch(jobId?:string):Promise<ProviderResult> {
    const claimed=await this.repo.command('claim',{jobId:jobId??null});
    if(!claimed.id)return {ok:true};
    const job=claimed as unknown as Job;let result:ProviderResult;
    try {
      if(job.kind==='email') {
        const payload=unseal<EmailPayload>(job.encrypted_payload,this.config.encryptionKey);
        if(this.config.allowedRecipients?.length&&!this.config.allowedRecipients.includes(payload.to))result={ok:false,errorCode:'test_recipient_only',retryable:false};
        else result=await this.providers.email(payload,job.id);
      } else result=await this.providers.analytics({...job.event_payload,timestamp:job.created_at},job.id);
    } catch {result={ok:false,errorCode:'provider_unavailable',retryable:true};}
    await this.repo.command('finish',{jobId:job.id,leaseId:job.lease_id,...result});
    return result;
  }
}
