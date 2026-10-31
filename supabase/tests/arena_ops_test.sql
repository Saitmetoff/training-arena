-- ============================================================================
-- Training Arena — outbox, dispatcher and device registration tests (pgTAP)
-- Run with: supabase test db
-- Covers: transactional notification enqueue, lease ownership and expiry,
-- retry/backoff, terminal failure, and device token reassignment/cap.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select no_plan();

create or replace function pg_temp.mkuser(p_id uuid, p_name text)
returns void
language plpgsql
as $$
begin
  insert into auth.users (
    instance_id, id, aud, role, email, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at
  )
  values (
    '00000000-0000-0000-0000-000000000000', p_id, 'authenticated',
    'authenticated', p_id::text || '@fixture.invalid', now(),
    '{}', '{}', now(), now()
  )
  on conflict (id) do nothing;
  update public.arena_profiles set username = p_name where user_id = p_id;
  insert into auth.sessions (id, user_id, created_at, updated_at, not_after)
  values (p_id, p_id, now(), now(), now() + interval '1 day')
  on conflict (id) do nothing;
end;
$$;

select pg_temp.mkuser('d0000000-0000-4000-8000-000000000001', 't_ops_alice');
select pg_temp.mkuser('d0000000-0000-4000-8000-000000000002', 't_ops_bob');
select pg_temp.mkuser('d0000000-0000-4000-8000-000000000003', 't_ops_carol');

-- Isolate this suite from other notifications (rolled back with the file).
delete from public.arena_notification_outbox;

-- Request delivery enqueues exactly one notification for the recipient.
insert into public.arena_links (token, user_id)
values ('opsalice0001', 'd0000000-0000-4000-8000-000000000001');
select public.arena_request_send(
  'd0000000-0000-4000-8000-000000000002',
  'd0000000-0000-4000-8000-000000000002',
  'opsalice0001'
);
select is(
  (select count(*)::integer from public.arena_notification_outbox
    where user_id = 'd0000000-0000-4000-8000-000000000001'
      and kind = 'challenge_request'),
  1,
  'a request enqueues exactly one challenge_request notification'
);

-- A dispatcher lease claims the row and counts the attempt.
select is(
  jsonb_array_length(public.arena_outbox_lease('dispatcher-a', 10, 60)),
  1,
  'the dispatcher leases the due notification'
);
select is(
  (select status::text from public.arena_notification_outbox
    where kind = 'challenge_request' limit 1),
  'leased',
  'the leased row is marked leased'
);
select is(
  (select attempts from public.arena_notification_outbox
    where kind = 'challenge_request' limit 1),
  1,
  'leasing increments the attempt counter'
);

-- Another dispatcher cannot steal an unexpired lease.
select is(
  jsonb_array_length(public.arena_outbox_lease('dispatcher-b', 10, 60)),
  0,
  'an unexpired lease is not stolen by another dispatcher'
);

-- Only the lease owner can confirm; a failed delivery backs off.
select is(
  public.arena_outbox_confirm(
    (select id from public.arena_notification_outbox where kind = 'challenge_request' limit 1),
    'dispatcher-b', false, 'wrong owner', 30
  )->>'ok',
  'false',
  'a non-owner cannot confirm the lease'
);
select is(
  public.arena_outbox_confirm(
    (select id from public.arena_notification_outbox where kind = 'challenge_request' limit 1),
    'dispatcher-a', false, 'provider unavailable', 30
  )->>'ok',
  'true',
  'the owner confirms a failed delivery'
);
select is(
  (select status::text from public.arena_notification_outbox
    where kind = 'challenge_request' limit 1),
  'pending',
  'a failed delivery returns to pending for retry'
);
select is(
  (select available_at > clock_timestamp() from public.arena_notification_outbox
    where kind = 'challenge_request' limit 1),
  true,
  'the retry is scheduled in the future'
);

-- An expired lease is reclaimable.
update public.arena_notification_outbox
set available_at = clock_timestamp() - interval '1 second',
    status = 'leased', lease_owner = 'dispatcher-dead',
    lease_expires_at = clock_timestamp() - interval '1 second'
where kind = 'challenge_request';
select is(
  jsonb_array_length(public.arena_outbox_lease('dispatcher-c', 10, 60)),
  1,
  'an expired lease is reclaimed'
);

-- After five attempts a failure is terminal.
select public.arena_outbox_confirm(
  (select id from public.arena_notification_outbox where kind = 'challenge_request' limit 1),
  'dispatcher-c', false, 'still failing', 30
);
update public.arena_notification_outbox
set attempts = 5, available_at = clock_timestamp() - interval '1 second'
where kind = 'challenge_request';
select public.arena_outbox_lease('dispatcher-d', 10, 60);
select public.arena_outbox_confirm(
  (select id from public.arena_notification_outbox where kind = 'challenge_request' limit 1),
  'dispatcher-d', false, 'terminal', 30
);
select is(
  (select status::text from public.arena_notification_outbox
    where kind = 'challenge_request' limit 1),
  'failed',
  'a notification that keeps failing becomes terminal'
);

-- Device registration: defaults, reassignment and validation.
select is(
  public.arena_device_register(
    'd0000000-0000-4000-8000-000000000001',
    'd0000000-0000-4000-8000-000000000001',
    'device-token-alice-1',
    null
  )->>'ok',
  'true',
  'device registration succeeds without a platform'
);
select is(
  (select platform from public.arena_devices where token = 'device-token-alice-1'),
  'android',
  'the platform defaults to android'
);
select public.arena_device_register(
  'd0000000-0000-4000-8000-000000000002',
  'd0000000-0000-4000-8000-000000000002',
  'device-token-alice-1',
  'ios'
);
select is(
  (select user_id from public.arena_devices where token = 'device-token-alice-1'),
  'd0000000-0000-4000-8000-000000000002'::uuid,
  're-registering a token reassigns it to the current user'
);
select throws_ok(
  $$ select public.arena_device_register(
       'd0000000-0000-4000-8000-000000000001',
       'd0000000-0000-4000-8000-000000000001',
       'short',
       'android'
     ) $$,
  'AR001',
  null,
  'a too-short device token is rejected'
);

-- Registering eleven tokens keeps only the ten most recent.
do $$
declare
  i integer;
begin
  for i in 1..11 loop
    perform public.arena_device_register(
      'd0000000-0000-4000-8000-000000000003',
      'd0000000-0000-4000-8000-000000000003',
      'device-token-carol-' || lpad(i::text, 2, '0'),
      'android'
    );
  end loop;
end;
$$;
select is(
  (select count(*)::integer from public.arena_devices
    where user_id = 'd0000000-0000-4000-8000-000000000003'),
  10,
  'a user keeps at most ten device tokens'
);

-- Dispatcher maintenance also expires overdue requests and queue seats.
insert into public.arena_requests (sender_id, recipient_id, created_at, expires_at)
values (
  'd0000000-0000-4000-8000-000000000002',
  'd0000000-0000-4000-8000-000000000003',
  now() - interval '25 hours',
  now() - interval '1 hour'
);
insert into public.arena_queue (user_id, created_at, expires_at)
values (
  'd0000000-0000-4000-8000-000000000002',
  now() - interval '2 minutes',
  now() - interval '1 minute'
);
create temporary table ops_maintenance (report jsonb) on commit drop;
insert into ops_maintenance select public.arena_maintenance();
select is(
  ((select report->>'expired_requests' from ops_maintenance))::integer >= 1,
  true,
  'maintenance expires overdue requests'
);
select is(
  ((select report->>'expired_queue_seats' from ops_maintenance))::integer >= 1,
  true,
  'maintenance expires overdue queue seats'
);

select * from finish();
rollback;
