// Read-only diagnostics: no requests, provider calls, environment writes or secret values.
import {readFileSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
import {resolve} from 'node:path';

export function inspectLaunchReadiness(env:Record<string,string|undefined>,source:{landing:string;privacy:string;support:string}) {
  const blockers:{code:string;message:string}[]=[];
  const warnings:{code:string;message:string}[]=[];
  const block=(code:string,message:string)=>blockers.push({code,message});
  const environment=['preview','production'].includes(env.FAULT_ENVIRONMENT||'')?env.FAULT_ENVIRONMENT:null;
  if(!environment)block('environment_required','Set FAULT_ENVIRONMENT explicitly to preview or production; local simulation is not hosted readiness.');
  if(env.FAULT_LOCAL_TEST_MODE==='true')block('local_simulation_enabled','Disable FAULT_LOCAL_TEST_MODE for hosted verification.');
  for(const name of ['SUPABASE_URL','SUPABASE_SERVICE_ROLE_KEY','RESEND_API_KEY','RESEND_FROM','RESEND_WEBHOOK_SECRET','FAULT_ENCRYPTION_KEY','FAULT_RATE_LIMIT_SECRET']) {
    if(!env[name]?.trim())block('missing_environment',`Configure ${name} through the intended environment secret store.`);
  }
  if(!env.FAULT_DISPATCH_SECRET?.trim()&&!env.CRON_SECRET?.trim())block('retry_auth_required','Configure FAULT_DISPATCH_SECRET for authenticated external dispatch or CRON_SECRET for the Vercel retry backstop; verify the chosen retry cadence separately.');
  if(!env.POSTHOG_PROJECT_KEY?.trim())warnings.push({code:'analytics_not_configured',message:'Optional PostHog delivery is not configured in this process environment. Analytics jobs may retry; database lifecycle/counts remain authoritative.'});
  if(!env.CRON_SECRET?.trim())warnings.push({code:'daily_backstop_not_authenticated',message:'The Vercel daily backstop lacks CRON_SECRET in this process environment. An authenticated external dispatcher can use FAULT_DISPATCH_SECRET instead; verify its actual cadence.'});
  if(env.FAULT_ENCRYPTION_KEY&&!/^[a-f0-9]{64}$/.test(env.FAULT_ENCRYPTION_KEY))block('encryption_key_invalid','FAULT_ENCRYPTION_KEY must be 64 lowercase hexadecimal characters.');
  const site=env.FAULT_SITE_URL||(env.VERCEL_URL?`https://${env.VERCEL_URL}`:'');
  try {
    const url=new URL(site);
    if(url.protocol!=='https:'||url.username||url.password||url.search||url.hash||url.pathname!=='/'||['localhost','127.0.0.1','[::1]'].includes(url.hostname))throw Error();
  }catch{block('site_origin_required','Set FAULT_SITE_URL to the verified HTTPS site origin, or use the exact VERCEL_URL fallback.');}
  if(!['https://eu.i.posthog.com','https://us.i.posthog.com'].includes(env.POSTHOG_HOST||'https://eu.i.posthog.com'))warnings.push({code:'analytics_host_invalid',message:'Optional analytics delivery requires a supported EU or US POSTHOG_HOST ingestion origin; database signup does not depend on PostHog.'});
  if(environment==='preview'&&!env.FAULT_TEST_RECIPIENTS?.split(',').some(value=>value.trim()))block('test_recipient_required','Configure the permitted preview recipient allowlist before any real preview mail.');
  if(env.FAULT_DELIVERY_READY!=='true')block('delivery_closed','FAULT_DELIVERY_READY is closed. Keep it closed until hosted sender, webhook and recovery verification succeeds.');
  if(source.landing.includes('Development preview')||source.privacy.includes('before public collection opens')||source.support.includes('still being configured'))block('public_copy_incomplete','Finalize the operator identity, support contact, retention/deletion policy and preview copy before public collection.');
  return {
    configurationReady:blockers.length===0,
    publicLaunchApproved:false,
    environment,
    blockers,
    warnings,
    scope:'Local process environment and source files only; missing local values do not establish absent hosted configuration. No remote account, database state or migration ledger was checked.',
    verificationRequired:[
      'Verify all three waitlist migrations on the intended hosted project, including the 20261020173359 complaint-hold correction; do not rerun schema creation.',
      'Verify sender/domain, signed provider events and known-suppression reconciliation for the intended environment.',
      'Verify one permitted real preview confirmation, replay, unsubscribe and durable retry without leaking email or tokens into analytics.',
      'Choose and verify a retry cadence inside the 23-hour job deadline; the configured daily Vercel backstop is insufficient alone.',
      'Before an authorized public publication, review canonical/indexing settings and verify the anonymous production flow.'
    ],
    payments:'No checkout or paid offer is configured. The current signup records no-charge launch-update interest; pricing and subscription terms remain undecided.',
    appLinks:'A genuine FAULT_ANDROID_CERT_SHA256 release fingerprint is a separate Android release dependency, not a waitlist requirement.'
  };
}

if(process.argv[1]&&resolve(process.argv[1])===fileURLToPath(import.meta.url)) {
  const read=(path:string)=>readFileSync(new URL(path,import.meta.url),'utf8');
  const report=inspectLaunchReadiness(process.env,{
    landing:read('../src/components/Landing.tsx'),privacy:read('../src/app/privacy/page.tsx'),support:read('../src/app/support/page.tsx')
  });
  console.log(JSON.stringify(report,null,2));
  if(!report.configurationReady)process.exitCode=1;
}
