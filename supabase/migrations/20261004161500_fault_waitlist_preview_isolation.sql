-- Additive Fault website namespace. No Arena tables/functions/grants are changed.
create schema if not exists fault_waitlist_preview;
revoke all on schema fault_waitlist_preview from public, anon, authenticated;
grant usage on schema fault_waitlist_preview to service_role;

create table fault_waitlist_preview.subscribers (
  id uuid primary key default gen_random_uuid(), email text not null unique,
  status text not null default 'pending' check(status in ('pending','subscribed','unsubscribed')),
  created_at timestamptz not null default now(), confirmed_at timestamptz, first_confirmed_at timestamptz,
  unsubscribed_at timestamptz, consent_at timestamptz not null, consent_version text not null,
  attribution jsonb not null, visitor_id uuid, analytics_consent boolean not null default false,
  suppressed boolean not null default false, suppression_reason text, suppression_at timestamptz,
  abuse boolean not null default false, internal_test boolean not null default false,
  last_requested_at timestamptz not null default now(),
  check(email=lower(btrim(email)) and length(email)<=254)
);
create table fault_waitlist_preview.tokens (
  id uuid primary key default gen_random_uuid(), subscriber_id uuid not null references fault_waitlist_preview.subscribers(id),
  digest text not null unique check(digest ~ '^[a-f0-9]{64}$'), kind text not null check(kind in ('confirm','unsubscribe')),
  expires_at timestamptz not null, consumed_at timestamptz, created_at timestamptz not null default now()
);
create table fault_waitlist_preview.outbox (
  id uuid primary key, subscriber_id uuid references fault_waitlist_preview.subscribers(id),
  kind text not null check(kind in ('email','analytics')), dedupe_key text not null unique,
  encrypted_payload text, event_payload jsonb,
  state text not null default 'queued' check(state in ('queued','leased','sent','failed','cancelled')),
  attempts integer not null default 0, available_at timestamptz not null default now(), lease_until timestamptz,
  lease_id uuid, expires_at timestamptz not null, created_at timestamptz not null default now(),
  provider_id text, error_code text, finished_at timestamptz
);
create index fault_outbox_ready on fault_waitlist_preview.outbox(available_at) where state in ('queued','leased');
create index fault_tokens_subscriber on fault_waitlist_preview.tokens(subscriber_id,kind);
create table fault_waitlist_preview.receipts (id text primary key, type text not null, received_at timestamptz not null default now());
create table fault_waitlist_preview.suppressions (email text primary key, active boolean not null, reason text not null, updated_at timestamptz not null);
create table fault_waitlist_preview.rate_limits (key text primary key, count integer not null, expires_at timestamptz not null);
alter table fault_waitlist_preview.subscribers enable row level security;
alter table fault_waitlist_preview.tokens enable row level security;
alter table fault_waitlist_preview.outbox enable row level security;
alter table fault_waitlist_preview.receipts enable row level security;
alter table fault_waitlist_preview.suppressions enable row level security;
alter table fault_waitlist_preview.rate_limits enable row level security;
revoke all on all tables in schema fault_waitlist_preview from public,anon,authenticated;
grant select,insert,update,delete on all tables in schema fault_waitlist_preview to service_role;

-- Invoker-only RPC. Service role has explicit schema/table grants and RLS bypass.
-- No public client can execute this or reach private tables.
create function public.fault_waitlist_preview_command(p_op text,p_args jsonb)
returns jsonb language plpgsql security invoker set search_path='' as $$
declare
  s fault_waitlist_preview.subscribers%rowtype; t fault_waitlist_preview.tokens%rowtype; j fault_waitlist_preview.outbox%rowtype;
  affected integer; created boolean:=false; first_confirmation boolean:=false;
  event_id uuid; token jsonb; recipient text; evt text; event_time timestamptz; prior fault_waitlist_preview.suppressions%rowtype;
  claim uuid; result jsonb; email_job uuid;
begin
  if p_op='rate' then
    insert into fault_waitlist_preview.rate_limits(key,count,expires_at)
    values(p_args->>'key',1,(p_args->>'expiresAt')::timestamptz)
    on conflict(key) do update set count=fault_waitlist_preview.rate_limits.count+1 returning count into affected;
    return jsonb_build_object('allowed',affected<=(p_args->>'limit')::integer);
  elsif p_op='signup' then
    -- Serializes duplicate creation/rejoin on canonical email without leaking status.
    perform pg_advisory_xact_lock(hashtextextended(p_args->>'email',0));
    select * into s from fault_waitlist_preview.subscribers where email=p_args->>'email' for update;
    if found then
      if s.suppressed or s.abuse or s.status='subscribed' or s.last_requested_at>now()-interval '60 seconds' then
        return jsonb_build_object('state','pending','created',false);
      end if;
      update fault_waitlist_preview.tokens set consumed_at=now() where subscriber_id=s.id and kind='confirm' and consumed_at is null;
      update fault_waitlist_preview.outbox set state='cancelled',encrypted_payload=null where subscriber_id=s.id and kind='email' and state in ('queued','leased');
      update fault_waitlist_preview.subscribers set status='pending',confirmed_at=null,last_requested_at=now(),consent_at=now(),
        consent_version=p_args->>'consentVersion',analytics_consent=coalesce((p_args->>'analyticsConsent')::boolean,false),
        visitor_id=(p_args->>'visitorId')::uuid,attribution=p_args->'attribution',internal_test=(p_args->>'internalTest')::boolean
      where id=s.id returning * into s;
    else
      if exists(select 1 from fault_waitlist_preview.suppressions where email=p_args->>'email' and active) then
        return jsonb_build_object('state','pending','created',false);
      end if;
      insert into fault_waitlist_preview.subscribers(email,consent_at,consent_version,attribution,visitor_id,analytics_consent,internal_test)
      values(p_args->>'email',now(),p_args->>'consentVersion',p_args->'attribution',(p_args->>'visitorId')::uuid,
        coalesce((p_args->>'analyticsConsent')::boolean,false),(p_args->>'internalTest')::boolean) returning * into s;
      created:=true;
    end if;
    for token in select value from jsonb_array_elements(p_args->'tokens') loop
      insert into fault_waitlist_preview.tokens(subscriber_id,digest,kind,expires_at)
      values(s.id,token->>'digest',token->>'kind',(token->>'expiresAt')::timestamptz);
    end loop;
    email_job:=(p_args->>'jobId')::uuid;
    insert into fault_waitlist_preview.outbox(id,subscriber_id,kind,dedupe_key,encrypted_payload,expires_at)
    values(email_job,s.id,'email','confirmation/'||email_job,p_args->>'encryptedPayload',now()+interval '23 hours');
    if created and s.analytics_consent then
      event_id:=gen_random_uuid();
      insert into fault_waitlist_preview.outbox(id,subscriber_id,kind,dedupe_key,event_payload,expires_at)
      values(event_id,s.id,'analytics','waitlist_submit/'||s.id,jsonb_build_object('event','waitlist_submit','distinct_id',coalesce(s.visitor_id,s.id),'insert_id',event_id,
      'properties',jsonb_build_object('attribution',s.attribution,'internal_test',s.internal_test)),now()+interval '23 hours');
    end if;
    return jsonb_build_object('state','pending','created',created,'jobId',email_job);
  elsif p_op in ('confirm','unsubscribe') then
    select * into t from fault_waitlist_preview.tokens where digest=p_args->>'digest' and kind=p_op;
    if not found then return jsonb_build_object('state','invalid'); end if;
    select * into s from fault_waitlist_preview.subscribers where id=t.subscriber_id for update;
    select * into t from fault_waitlist_preview.tokens where id=t.id for update;
    if p_op='confirm' and t.consumed_at is not null then return jsonb_build_object('state','used'); end if;
    if t.expires_at<=now() then return jsonb_build_object('state','expired'); end if;
    if p_op='confirm' then
      if s.status='unsubscribed' or s.suppressed or s.abuse then return jsonb_build_object('state','unsubscribed'); end if;
      update fault_waitlist_preview.tokens set consumed_at=now() where id=t.id;
      if s.status='subscribed' then return jsonb_build_object('state','used'); end if;
      first_confirmation:=s.first_confirmed_at is null;
      update fault_waitlist_preview.subscribers set status='subscribed',confirmed_at=now(),first_confirmed_at=coalesce(first_confirmed_at,now()),unsubscribed_at=null where id=s.id;
      if s.analytics_consent then
        event_id:=gen_random_uuid();
        insert into fault_waitlist_preview.outbox(id,subscriber_id,kind,dedupe_key,event_payload,expires_at)
        values(event_id,s.id,'analytics','waitlist_confirmed/'||t.id,
        jsonb_build_object('event','waitlist_confirmed','distinct_id',coalesce(s.visitor_id,s.id),'insert_id',event_id,'properties',jsonb_build_object('attribution',s.attribution,'internal_test',s.internal_test,'first_confirmation',first_confirmation)),now()+interval '23 hours')
        on conflict(dedupe_key) do nothing;
      end if;
      return jsonb_build_object('state','confirmed','transition',true,'firstConfirmation',first_confirmation);
    else
      update fault_waitlist_preview.subscribers set status='unsubscribed',unsubscribed_at=coalesce(unsubscribed_at,now()) where id=s.id;
      update fault_waitlist_preview.tokens set consumed_at=now() where subscriber_id=s.id and consumed_at is null;
      update fault_waitlist_preview.outbox set state='cancelled',encrypted_payload=null where subscriber_id=s.id and kind='email' and state in ('queued','leased');
      return jsonb_build_object('state','unsubscribed','transition',s.status<>'unsubscribed');
    end if;
  elsif p_op='claim' then
    update fault_waitlist_preview.outbox set state='failed',error_code='expired',encrypted_payload=null,finished_at=now()
      where state in ('queued','leased') and expires_at<=now();
    select * into j from fault_waitlist_preview.outbox
      where (state='queued' or (state='leased' and lease_until<now())) and available_at<=now() and expires_at>now() and attempts<8
      and (p_args->>'jobId' is null or id=(p_args->>'jobId')::uuid)
      order by available_at,created_at for update skip locked limit 1;
    if not found then return '{}'::jsonb; end if;
    if j.kind='email' then
      select * into s from fault_waitlist_preview.subscribers where id=j.subscriber_id;
      if s.status<>'pending' or s.suppressed or s.abuse then
        update fault_waitlist_preview.outbox set state='cancelled',encrypted_payload=null where id=j.id;
        return '{}'::jsonb;
      end if;
    end if;
    claim:=gen_random_uuid();
    update fault_waitlist_preview.outbox set state='leased',lease_id=claim,lease_until=now()+interval '2 minutes',attempts=attempts+1 where id=j.id returning * into j;
    return to_jsonb(j);
  elsif p_op='finish' then
    select * into j from fault_waitlist_preview.outbox where id=(p_args->>'jobId')::uuid and lease_id=(p_args->>'leaseId')::uuid and state='leased' for update;
    if not found then return jsonb_build_object('updated',false); end if;
    if (p_args->>'ok')::boolean then
      update fault_waitlist_preview.outbox set state='sent',provider_id=p_args->>'providerId',encrypted_payload=null,finished_at=now(),lease_until=null where id=j.id;
    elsif coalesce((p_args->>'retryable')::boolean,false) and j.attempts<8 then
      update fault_waitlist_preview.outbox set state='queued',error_code=p_args->>'errorCode',available_at=now()+make_interval(secs=>least(3600,30*power(2,j.attempts)::integer)),lease_until=null where id=j.id;
    else
      update fault_waitlist_preview.outbox set state='failed',error_code=p_args->>'errorCode',encrypted_payload=null,finished_at=now(),lease_until=null where id=j.id;
    end if;
    return jsonb_build_object('updated',true);
  elsif p_op='webhook' then
    insert into fault_waitlist_preview.receipts(id,type) values(p_args->>'id',p_args->>'type') on conflict do nothing;
    get diagnostics affected=row_count;
    if affected=0 then return jsonb_build_object('duplicate',true); end if;
    evt:=p_args->>'type'; event_time:=(p_args->>'timestamp')::timestamptz;
    for recipient in select value from jsonb_array_elements_text(p_args->'recipients') order by value loop
      perform pg_advisory_xact_lock(hashtextextended(recipient,0));
      select * into prior from fault_waitlist_preview.suppressions where email=recipient for update;
      if evt in ('email.bounced','email.complained','email.suppressed','suppression.added','suppression.removed') then
        if evt='suppression.removed' and prior.reason in ('email.complained','abuse') then continue; end if;
        if prior.updated_at is not null and prior.updated_at>event_time then continue; end if;
        insert into fault_waitlist_preview.suppressions(email,active,reason,updated_at)
        values(recipient,evt<>'suppression.removed',evt,event_time)
        on conflict(email) do update set active=excluded.active,reason=excluded.reason,updated_at=excluded.updated_at;
        update fault_waitlist_preview.subscribers set suppressed=evt<>'suppression.removed',suppression_reason=evt,suppression_at=event_time where email=recipient;
        if evt<>'suppression.removed' then
          update fault_waitlist_preview.outbox set state='cancelled',encrypted_payload=null where kind='email' and state in ('queued','leased') and subscriber_id in(select id from fault_waitlist_preview.subscribers where email=recipient);
        end if;
      elsif evt='contact.updated' then
        update fault_waitlist_preview.subscribers set status='unsubscribed',unsubscribed_at=now() where email=recipient and consent_at<=event_time;
        update fault_waitlist_preview.tokens set consumed_at=now() where consumed_at is null and subscriber_id in(select id from fault_waitlist_preview.subscribers where email=recipient and status='unsubscribed');
        update fault_waitlist_preview.outbox set state='cancelled',encrypted_payload=null where kind='email' and state in ('queued','leased') and subscriber_id in(select id from fault_waitlist_preview.subscribers where email=recipient and status='unsubscribed');
      end if;
    end loop;
    return jsonb_build_object('processed',true);
  elsif p_op='browser_event' then
    event_id:=gen_random_uuid();
    insert into fault_waitlist_preview.outbox(id,kind,dedupe_key,event_payload,expires_at)
    values(event_id,'analytics','browser/'||event_id,p_args->'eventPayload',now()+interval '23 hours');
    return jsonb_build_object('queued',true);
  elsif p_op='counts' then
    select jsonb_build_object('uniqueConfirmedSubscribed',count(*),'snapshotAt',now()) into result from fault_waitlist_preview.subscribers
    where status='subscribed' and confirmed_at is not null and not suppressed and not abuse and not internal_test;
    return result;
  elsif p_op='maintenance' then
    delete from fault_waitlist_preview.rate_limits where expires_at<now();
    delete from fault_waitlist_preview.tokens where expires_at<now()-interval '7 days';
    return jsonb_build_object('cleaned',true);
  end if;
  raise exception 'unsupported operation';
end $$;
revoke execute on function public.fault_waitlist_preview_command(text,jsonb) from public,anon,authenticated;
grant execute on function public.fault_waitlist_preview_command(text,jsonb) to service_role;

