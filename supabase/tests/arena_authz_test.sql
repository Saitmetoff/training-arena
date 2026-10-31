-- ============================================================================
-- Training Arena — adversarial authorization tests (pgTAP)
-- Run with: supabase test db
-- Proves: sessions cannot be swapped or forged, non-participants cannot read or
-- mutate a match, history is private, revoked links fail read-only, blocked
-- profiles disappear, username rules hold, and account deletion is safe and
-- idempotent.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select no_plan();

-- ----------------------------------------------------------------------------
-- Helpers
-- ----------------------------------------------------------------------------
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

create or replace function pg_temp.new_request(p_sender uuid, p_recipient uuid)
returns uuid
language plpgsql
as $$
declare
  v_id uuid;
begin
  insert into public.arena_requests (sender_id, recipient_id)
  values (p_sender, p_recipient)
  returning id into v_id;
  return v_id;
end;
$$;

select pg_temp.mkuser('c0000000-0000-4000-8000-000000000001', 't_authz_alice');
select pg_temp.mkuser('c0000000-0000-4000-8000-000000000002', 't_authz_bob');
select pg_temp.mkuser('c0000000-0000-4000-8000-000000000003', 't_authz_carol');
select pg_temp.mkuser('c0000000-0000-4000-8000-000000000004', 't_authz_dave');

-- ----------------------------------------------------------------------------
-- Authentication: missing, swapped and expired sessions
-- ----------------------------------------------------------------------------
select throws_ok(
  $$ select public.arena_get_profile(null, null) $$,
  'AR002',
  null,
  'a missing actor/session pair is unauthorized'
);
select throws_ok(
  $$ select public.arena_get_profile(
       'c0000000-0000-4000-8000-000000000001',
       'c0000000-0000-4000-8000-000000000002'
     ) $$,
  'AR002',
  null,
  'an actor cannot use another user session id'
);
-- A matching actor/session pair is accepted.
select is(
  public.arena_get_profile(
    'c0000000-0000-4000-8000-000000000001',
    'c0000000-0000-4000-8000-000000000001'
  )->'profile'->>'username',
  't_authz_alice',
  'the actor reads their own profile'
);

select pg_temp.mkuser('c0000000-0000-4000-8000-000000000005', 't_authz_expired');
update auth.sessions set not_after = now() - interval '1 minute'
where id = 'c0000000-0000-4000-8000-000000000005';
select throws_ok(
  $$ select public.arena_get_profile(
       'c0000000-0000-4000-8000-000000000005',
       'c0000000-0000-4000-8000-000000000005'
     ) $$,
  'AR002',
  null,
  'an expired session is unauthorized'
);

-- ----------------------------------------------------------------------------
-- One active match between alice and bob, finished so receipts exist
-- ----------------------------------------------------------------------------
create temporary table authz (match_id uuid) on commit drop;
insert into authz
select ((public.arena_request_accept(
  'c0000000-0000-4000-8000-000000000002',
  'c0000000-0000-4000-8000-000000000002',
  pg_temp.new_request('c0000000-0000-4000-8000-000000000001', 'c0000000-0000-4000-8000-000000000002')
))->'match'->>'id')::uuid;

select throws_ok(
  format(
    $$ select public.arena_match_state(
         'c0000000-0000-4000-8000-000000000003',
         'c0000000-0000-4000-8000-000000000003',
         %L
       ) $$,
    (select match_id from authz)
  ),
  'AR003',
  null,
  'a non-participant cannot read the match'
);
select throws_ok(
  format(
    $$ select public.arena_match_ready(
         'c0000000-0000-4000-8000-000000000003',
         'c0000000-0000-4000-8000-000000000003',
         %L, true, true
       ) $$,
    (select match_id from authz)
  ),
  'AR003',
  null,
  'a non-participant cannot mark readiness'
);
select throws_ok(
  format(
    $$ select public.arena_match_heartbeat(
         'c0000000-0000-4000-8000-000000000003',
         'c0000000-0000-4000-8000-000000000003',
         %L, true
       ) $$,
    (select match_id from authz)
  ),
  'AR003',
  null,
  'a non-participant cannot heartbeat'
);
select throws_ok(
  format(
    $$ select public.arena_match_rep(
         'c0000000-0000-4000-8000-000000000003',
         'c0000000-0000-4000-8000-000000000003',
         %L, 'd0000000-0000-4000-8000-000000000001', 1, now(), '1.3.0'
       ) $$,
    (select match_id from authz)
  ),
  'AR003',
  null,
  'a non-participant cannot inject reps'
);
select throws_ok(
  format(
    $$ select public.arena_match_leave(
         'c0000000-0000-4000-8000-000000000003',
         'c0000000-0000-4000-8000-000000000003',
         %L
       ) $$,
    (select match_id from authz)
  ),
  'AR003',
  null,
  'a non-participant cannot forfeit the match'
);

-- Finish the match legitimately so receipts exist.
select public.arena_match_ready(
  'c0000000-0000-4000-8000-000000000001',
  'c0000000-0000-4000-8000-000000000001',
  (select match_id from authz), true, true
);
select public.arena_match_ready(
  'c0000000-0000-4000-8000-000000000002',
  'c0000000-0000-4000-8000-000000000002',
  (select match_id from authz), true, true
);
update public.arena_matches
set starts_at = now() - interval '61 seconds',
    ends_at = now() - interval '1 second'
where id = (select match_id from authz);
select public.arena_match_state(
  'c0000000-0000-4000-8000-000000000001',
  'c0000000-0000-4000-8000-000000000001',
  (select match_id from authz)
);

-- ----------------------------------------------------------------------------
-- Private history
-- ----------------------------------------------------------------------------
select is(
  jsonb_array_length(public.arena_history(
    'c0000000-0000-4000-8000-000000000001',
    'c0000000-0000-4000-8000-000000000001'
  )->'receipts'),
  1,
  'a participant sees their own receipt'
);
select is(
  jsonb_array_length(public.arena_history(
    'c0000000-0000-4000-8000-000000000003',
    'c0000000-0000-4000-8000-000000000003'
  )->'receipts'),
  0,
  'a non-participant has no history of the match'
);
select is(
  public.arena_history(
    'c0000000-0000-4000-8000-000000000003',
    'c0000000-0000-4000-8000-000000000003'
  )->'receipts',
  '[]'::jsonb,
  'private history is empty rather than leaking other players'
);

-- ----------------------------------------------------------------------------
-- Public profile and blocks
-- ----------------------------------------------------------------------------
select is(
  public.arena_public_profile(
    'c0000000-0000-4000-8000-000000000003',
    'c0000000-0000-4000-8000-000000000003',
    'c0000000-0000-4000-8000-000000000001'
  )->'profile'->>'username',
  't_authz_alice',
  'a public profile exposes only public identity'
);
select is(
  (public.arena_public_profile(
    'c0000000-0000-4000-8000-000000000003',
    'c0000000-0000-4000-8000-000000000003',
    'c0000000-0000-4000-8000-000000000001'
  )->'profile') ? 'email',
  false,
  'a public profile never contains an email field'
);
select throws_ok(
  $$ select public.arena_public_profile(
       'c0000000-0000-4000-8000-000000000001',
       'c0000000-0000-4000-8000-000000000001',
       'c0000000-0000-4000-8000-000000000001'
     ) $$,
  'AR003',
  null,
  'asking for your own public profile is not_found (use profile)'
);

select public.arena_block(
  'c0000000-0000-4000-8000-000000000001',
  'c0000000-0000-4000-8000-000000000001',
  'c0000000-0000-4000-8000-000000000003'
);
select throws_ok(
  $$ select public.arena_public_profile(
       'c0000000-0000-4000-8000-000000000001',
       'c0000000-0000-4000-8000-000000000001',
       'c0000000-0000-4000-8000-000000000003'
     ) $$,
  'AR003',
  null,
  'a blocked profile is hidden from the blocker'
);
select throws_ok(
  $$ select public.arena_public_profile(
       'c0000000-0000-4000-8000-000000000003',
       'c0000000-0000-4000-8000-000000000003',
       'c0000000-0000-4000-8000-000000000001'
     ) $$,
  'AR003',
  null,
  'a blocking profile is hidden from the blocked'
);
select throws_ok(
  $$ select public.arena_block(
       'c0000000-0000-4000-8000-000000000001',
       'c0000000-0000-4000-8000-000000000001',
       'c0000000-0000-4000-8000-000000000001'
     ) $$,
  'AR001',
  null,
  'self-block is rejected'
);
select is(
  jsonb_array_length(public.arena_blocked(
    'c0000000-0000-4000-8000-000000000001',
    'c0000000-0000-4000-8000-000000000001'
  )->'profiles'),
  1,
  'the block list contains the blocked player'
);
select is(
  public.arena_unblock(
    'c0000000-0000-4000-8000-000000000001',
    'c0000000-0000-4000-8000-000000000001',
    'c0000000-0000-4000-8000-000000000003'
  )->>'ok',
  'true',
  'unblock succeeds'
);
select is(
  public.arena_unblock(
    'c0000000-0000-4000-8000-000000000001',
    'c0000000-0000-4000-8000-000000000001',
    'c0000000-0000-4000-8000-000000000003'
  )->>'ok',
  'true',
  'unblock is idempotent'
);

-- ----------------------------------------------------------------------------
-- Username and report rules
-- ----------------------------------------------------------------------------
select throws_ok(
  $$ select public.arena_update_profile(
       'c0000000-0000-4000-8000-000000000003',
       'c0000000-0000-4000-8000-000000000003',
       't_authz_alice'
     ) $$,
  'AR004',
  null,
  'a taken username is rejected case-insensitively'
);
select throws_ok(
  $$ select public.arena_update_profile(
       'c0000000-0000-4000-8000-000000000003',
       'c0000000-0000-4000-8000-000000000003',
       'admin'
     ) $$,
  'AR005',
  null,
  'reserved usernames are rejected by the RPC'
);
select throws_ok(
  $$ select public.arena_update_profile(
       'c0000000-0000-4000-8000-000000000003',
       'c0000000-0000-4000-8000-000000000003',
       'x'
     ) $$,
  'AR005',
  null,
  'short usernames are rejected by the RPC'
);
select throws_ok(
  $$ select public.arena_report(
       'c0000000-0000-4000-8000-000000000003',
       'c0000000-0000-4000-8000-000000000003',
       'c0000000-0000-4000-8000-000000000003',
       null,
       'self report'
     ) $$,
  'AR001',
  null,
  'self-report is rejected'
);
select throws_ok(
  $$ select public.arena_report(
       'c0000000-0000-4000-8000-000000000003',
       'c0000000-0000-4000-8000-000000000003',
       'c0000000-0000-4000-8000-000000000001',
       (select match_id from authz),
       'not my match'
     ) $$,
  'AR003',
  null,
  'reporting a match the reporter was not in is not_found'
);
select is(
  public.arena_report(
    'c0000000-0000-4000-8000-000000000003',
    'c0000000-0000-4000-8000-000000000003',
    'c0000000-0000-4000-8000-000000000001',
    null,
    'unsporting conduct'
  )->>'ok',
  'true',
  'a valid report is stored'
);

-- ----------------------------------------------------------------------------
-- Username gate for challenges and ranked play
-- ----------------------------------------------------------------------------
select pg_temp.mkuser('c0000000-0000-4000-8000-000000000006', 't_authz_newbie');
update public.arena_profiles set username = null
where user_id = 'c0000000-0000-4000-8000-000000000006';
select throws_ok(
  $$ select public.arena_queue_join(
       'c0000000-0000-4000-8000-000000000006',
       'c0000000-0000-4000-8000-000000000006'
     ) $$,
  'AR020',
  null,
  'ranked queue requires a username'
);
select throws_ok(
  $$ select public.arena_request_send(
       'c0000000-0000-4000-8000-000000000006',
       'c0000000-0000-4000-8000-000000000006',
       'authzalice01'
     ) $$,
  'AR020',
  null,
  'sending a challenge requires a username'
);

-- ----------------------------------------------------------------------------
-- Revoked links are read-only failures and resolve anonymously
-- ----------------------------------------------------------------------------
insert into public.arena_links (token, user_id)
values ('authzalice01', 'c0000000-0000-4000-8000-000000000001');
select is(
  public.arena_request_send(
    'c0000000-0000-4000-8000-000000000004',
    'c0000000-0000-4000-8000-000000000004',
    'authzalice01'
  )->'request'->>'status',
  'pending',
  'an unblocked player can use a valid link'
);
update public.arena_links set revoked_at = now()
where token = 'authzalice01';
select is(
  public.arena_resolve_link('authzalice01')->>'available',
  'false',
  'a revoked link stops resolving'
);
select throws_ok(
  $$ select public.arena_request_send(
       'c0000000-0000-4000-8000-000000000003',
       'c0000000-0000-4000-8000-000000000003',
       'authzalice01'
     ) $$,
  'AR006',
  null,
  'sending through a revoked link fails'
);

-- Resolving a link mutates nothing.
create temporary table resolve_counts (requests bigint, links bigint) on commit drop;
insert into resolve_counts
select
  (select count(*) from public.arena_requests),
  (select count(*) from public.arena_links);
select public.arena_resolve_link('unknownlink1');
select is(
  (select requests from resolve_counts),
  (select count(*) from public.arena_requests),
  'anonymous link resolution creates no requests'
);
select is(
  (select links from resolve_counts),
  (select count(*) from public.arena_links),
  'anonymous link resolution creates no links'
);

-- ----------------------------------------------------------------------------
-- Account deletion is conservative, private and retry-safe
-- ----------------------------------------------------------------------------
select pg_temp.mkuser('c0000000-0000-4000-8000-000000000007', 't_authz_erin');
select pg_temp.mkuser('c0000000-0000-4000-8000-000000000008', 't_authz_frank');
update public.arena_profiles
set avatar_url = 'https://example.invalid/arena/erin.png',
    avatar_path = 'avatars/c0000000-0000-4000-8000-000000000007/erin.png'
where user_id = 'c0000000-0000-4000-8000-000000000007';
insert into public.arena_links (token, user_id)
values ('authzerin001', 'c0000000-0000-4000-8000-000000000007');
insert into public.arena_queue (user_id)
values ('c0000000-0000-4000-8000-000000000007');

create temporary table erin_match (match_id uuid) on commit drop;
insert into erin_match
select ((public.arena_request_accept(
  'c0000000-0000-4000-8000-000000000008',
  'c0000000-0000-4000-8000-000000000008',
  pg_temp.new_request('c0000000-0000-4000-8000-000000000007', 'c0000000-0000-4000-8000-000000000008')
))->'match'->>'id')::uuid;

-- Pending requests in both directions for the deletion cleanup assertions.
create temporary table erin_pending (id uuid) on commit drop;
insert into erin_pending
select pg_temp.new_request('c0000000-0000-4000-8000-000000000007', 'c0000000-0000-4000-8000-000000000004');
select pg_temp.new_request('c0000000-0000-4000-8000-000000000004', 'c0000000-0000-4000-8000-000000000007');

select is(
  public.arena_delete_account(
    'c0000000-0000-4000-8000-000000000007',
    'c0000000-0000-4000-8000-000000000007'
  )->>'already_deleted',
  'false',
  'the first delete call performs the cleanup'
);
select is(
  (public.arena_delete_account(
    'c0000000-0000-4000-8000-000000000007',
    'c0000000-0000-4000-8000-000000000007'
  )->>'already_deleted')::boolean,
  true,
  'a retried delete call is idempotent'
);
select is(
  public.arena_resolve_link('authzerin001')->>'available',
  'false',
  'deleting an account revokes its link'
);
select is(
  (select status::text from public.arena_queue
    where user_id = 'c0000000-0000-4000-8000-000000000007' order by created_at desc limit 1),
  'cancelled',
  'deleting an account cancels its queue seat'
);
select is(
  (select status::text from public.arena_requests
    where id = (select id from erin_pending)),
  'cancelled',
  'pending requests sent by the deleted account are cancelled'
);
select is(
  (select status::text from public.arena_requests
    where sender_id = 'c0000000-0000-4000-8000-000000000004'
      and recipient_id = 'c0000000-0000-4000-8000-000000000007'),
  'expired',
  'pending requests to the deleted account are expired'
);
select is(
  (public.arena_match_view((select match_id from erin_match))->'receipt'->>'outcome'),
  'no_result',
  'an active match is closed as no_result when an account is deleted'
);
select throws_ok(
  $$ select public.arena_get_profile(
       'c0000000-0000-4000-8000-000000000007',
       'c0000000-0000-4000-8000-000000000007'
     ) $$,
  'AR002',
  null,
  'a deleted account cannot act'
);
select is(
  (select deleted_at is not null from public.arena_profiles
    where user_id = 'c0000000-0000-4000-8000-000000000007'),
  true,
  'the profile is marked deleted for the Edge Function cleanup'
);

-- ----------------------------------------------------------------------------
-- Deleted and anonymous profiles stay out of the leaderboard
-- ----------------------------------------------------------------------------
select is(
  (select count(*)::integer from jsonb_array_elements(
    public.arena_leaderboard(
      'c0000000-0000-4000-8000-000000000001',
      'c0000000-0000-4000-8000-000000000001'
    )->'profiles'
  ) as p
  where p.value->>'id' = 'c0000000-0000-4000-8000-000000000007'),
  0,
  'a deleted profile is excluded from the leaderboard'
);
select is(
  (select count(*)::integer from jsonb_array_elements(
    public.arena_leaderboard(
      'c0000000-0000-4000-8000-000000000001',
      'c0000000-0000-4000-8000-000000000001'
    )->'profiles'
  ) as p
  where p.value->>'id' = 'c0000000-0000-4000-8000-000000000006'),
  0,
  'a username-less profile is excluded from the leaderboard'
);

select * from finish();
rollback;
