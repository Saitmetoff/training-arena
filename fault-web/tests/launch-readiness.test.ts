import {test} from 'node:test';
import assert from 'node:assert/strict';
import {inspectLaunchReadiness} from '../scripts/check-launch-readiness';

const source={landing:'Public waitlist',privacy:'Configured operator policy',support:'Configured support contact'};
const environment={
  FAULT_ENVIRONMENT:'preview',FAULT_SITE_URL:'https://preview.example.com',FAULT_LOCAL_TEST_MODE:'false',FAULT_DELIVERY_READY:'true',
  SUPABASE_URL:'https://database.invalid',SUPABASE_SERVICE_ROLE_KEY:'test-service-key',RESEND_API_KEY:'test-provider-key',
  RESEND_FROM:'test@example.invalid',RESEND_WEBHOOK_SECRET:'test-webhook-key',FAULT_ENCRYPTION_KEY:'a'.repeat(64),
  FAULT_RATE_LIMIT_SECRET:'test-rate-key',FAULT_DISPATCH_SECRET:'test-dispatch-key',CRON_SECRET:'test-cron-key',
  POSTHOG_PROJECT_KEY:'test-analytics-key',FAULT_TEST_RECIPIENTS:'owner@example.invalid'
};

test('configuration report never certifies publication or prints supplied secret values',()=>{
  const report=inspectLaunchReadiness(environment,source);
  assert.equal(report.configurationReady,true);
  assert.equal(report.publicLaunchApproved,false);
  assert(report.verificationRequired.some((item:string)=>item.includes('23-hour')));
  for(const name of ['SUPABASE_SERVICE_ROLE_KEY','RESEND_API_KEY','FAULT_ENCRYPTION_KEY','CRON_SECRET'])assert(!JSON.stringify(report).includes(environment[name as keyof typeof environment]));
});

test('local simulation, missing secrets, incomplete public copy and closed delivery are blockers',()=>{
  const report=inspectLaunchReadiness({...environment,FAULT_ENVIRONMENT:'development',FAULT_LOCAL_TEST_MODE:'true',FAULT_SITE_URL:'http://127.0.0.1:3000',RESEND_WEBHOOK_SECRET:'',CRON_SECRET:'',FAULT_DISPATCH_SECRET:'',FAULT_DELIVERY_READY:'false'},
    {...source,privacy:'Operator required before public collection opens'});
  assert.equal(report.configurationReady,false);
  for(const code of ['environment_required','local_simulation_enabled','site_origin_required','missing_environment','retry_auth_required','delivery_closed','public_copy_incomplete'])assert(report.blockers.some((item:{code:string})=>item.code===code));
});

test('preview requires recipient restriction; production configuration is evaluated separately',()=>{
  assert(inspectLaunchReadiness({...environment,FAULT_TEST_RECIPIENTS:''},source).blockers.some((item:{code:string})=>item.code==='test_recipient_required'));
  assert.equal(inspectLaunchReadiness({...environment,FAULT_ENVIRONMENT:'production',FAULT_TEST_RECIPIENTS:''},source).configurationReady,true);
});

test('invalid encryption key and non-origin canonical URLs fail configuration checks',()=>{
  const credentialedSite=new URL('https://example.com');credentialedSite.username='test';credentialedSite.password='test';
  for(const site of ['https://example.com/path','https://example.com?email=private',credentialedSite.href,'https://localhost'])assert(inspectLaunchReadiness({...environment,FAULT_SITE_URL:site},source).blockers.some((item:{code:string})=>item.code==='site_origin_required'));
  const report=inspectLaunchReadiness({...environment,FAULT_ENCRYPTION_KEY:'invalid'},source);
  assert(report.blockers.some((item:{code:string})=>item.code==='encryption_key_invalid'));
});

test('signup configuration can omit optional analytics and use either retry authentication path',()=>{
  for(const scheduler of [{CRON_SECRET:'',FAULT_DISPATCH_SECRET:'test-dispatch-key'},{CRON_SECRET:'test-cron-key',FAULT_DISPATCH_SECRET:''}]) {
    const report=inspectLaunchReadiness({...environment,...scheduler,POSTHOG_PROJECT_KEY:'',POSTHOG_HOST:'https://example.com'},source);
    assert.equal(report.configurationReady,true);
    assert.equal(report.publicLaunchApproved,false);
    assert(report.warnings.some((item:{code:string})=>item.code==='analytics_not_configured'));
    assert(report.warnings.some((item:{code:string})=>item.code==='analytics_host_invalid'));
    assert.match(report.scope,/missing local values do not establish absent hosted configuration/);
  }
});
