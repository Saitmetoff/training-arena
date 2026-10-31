-- ============================================================================
-- Training Arena — schema, constraint and security surface tests (pgTAP)
-- Run with: supabase test db
-- The whole file runs in one transaction and rolls back.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select no_plan();

-- ----------------------------------------------------------------------------
-- Helpers (transaction-local user/session fixtures)
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

select pg_temp.mkuser('a0000000-0000-4000-8000-000000000001', 't_schema_alice');
select pg_temp.mkuser('a0000000-0000-4000-8000-000000000002', 't_schema_bob');

-- ----------------------------------------------------------------------------
-- Namespace, RLS and grants
-- ----------------------------------------------------------------------------
select is(
  (select count(*)::integer
   from pg_class c
   where c.relnamespace = 'public'::regnamespace
     and c.relname ~ '^arena_'
     and c.relkind = 'r'),
  15,
  'all 15 arena tables including the counter inventory exist'
);

select is(
  (select count(*)::integer
   from pg_class c
   where c.relnamespace = 'public'::regnamespace
     and c.relname ~ '^arena_'
     and c.relkind = 'r'
     and not c.relrowsecurity),
  0,
  'every arena table has RLS enabled'
);

select is(
  (select count(*)::integer
   from pg_policies
   where schemaname = 'public' and tablename ~ '^arena_'),
  0,
  'no client RLS policies exist (default deny)'
);

select ok(
  not has_table_privilege('anon', 'public.arena_profiles', 'SELECT'),
  'anon cannot read profiles'
);
select ok(
  not has_table_privilege('authenticated', 'public.arena_receipts', 'SELECT'),
  'authenticated cannot read receipts'
);
select ok(
  not has_table_privilege('authenticated', 'public.arena_profiles', 'UPDATE'),
  'authenticated cannot update profiles (including rating)'
);
select ok(
  not has_table_privilege('authenticated', 'public.arena_match_players', 'INSERT'),
  'authenticated cannot insert match players or scores'
);
select ok(
  not has_function_privilege('anon', 'public.arena_get_profile(uuid,uuid)', 'EXECUTE'),
  'anon cannot execute RPCs'
);
select ok(
  not has_function_privilege('authenticated', 'public.arena_get_profile(uuid,uuid)', 'EXECUTE'),
  'authenticated cannot execute RPCs'
);
select ok(
  has_function_privilege('service_role', 'public.arena_get_profile(uuid,uuid)', 'EXECUTE'),
  'service_role can execute RPCs'
);

-- RLS denies direct client access even if the grant surface regressed.
set local role authenticated;
select throws_ok(
  $$ select count(*) from public.arena_profiles $$,
  '42501',
  null,
  'direct profile reads are denied to authenticated'
);
select throws_ok(
  $$ insert into public.arena_profiles (user_id) values ('a0000000-0000-4000-8000-0000000000ff') $$,
  '42501',
  null,
  'direct profile inserts are denied to authenticated'
);
reset role;

-- ----------------------------------------------------------------------------
-- Profile constraints
-- ----------------------------------------------------------------------------
select throws_ok(
  $$ update public.arena_profiles set username = 't_Schema_Alice'
     where user_id = 'a0000000-0000-4000-8000-000000000002' $$,
  '23505',
  null,
  'usernames are unique after case normalization'
);
select throws_ok(
  $$ update public.arena_profiles set username = 'bad name'
     where user_id = 'a0000000-0000-4000-8000-000000000001' $$,
  '23514',
  null,
  'usernames reject spaces'
);
select throws_ok(
  $$ update public.arena_profiles set username = 'admin'
     where user_id = 'a0000000-0000-4000-8000-000000000001' $$,
  '23514',
  null,
  'reserved usernames are rejected'
);
select throws_ok(
  $$ update public.arena_profiles set rating = -1
     where user_id = 'a0000000-0000-4000-8000-000000000001' $$,
  '23514',
  null,
  'ratings cannot go negative'
);
select throws_ok(
  $$ update public.arena_profiles set ranked_wins = 2, ranked_battles = 1
     where user_id = 'a0000000-0000-4000-8000-000000000001' $$,
  '23514',
  null,
  'ranked wins cannot exceed battles'
);
select throws_ok(
  $$ update public.arena_profiles set avatar_url = 'http://insecure.example/a.png'
     where user_id = 'a0000000-0000-4000-8000-000000000001' $$,
  '23514',
  null,
  'avatar urls must be https'
);

-- ----------------------------------------------------------------------------
-- Link constraints
-- ----------------------------------------------------------------------------
select throws_ok(
  $$ insert into public.arena_links (token, user_id)
     values ('TOO-SHORT', 'a0000000-0000-4000-8000-000000000001') $$,
  '23514',
  null,
  'link tokens must be 12 lowercase alphanumerics'
);
insert into public.arena_links (token, user_id)
values ('testschema01', 'a0000000-0000-4000-8000-000000000001');
select throws_ok(
  $$ insert into public.arena_links (token, user_id)
     values ('testschema02', 'a0000000-0000-4000-8000-000000000001') $$,
  '23505',
  null,
  'a user has at most one active challenge link'
);

-- ----------------------------------------------------------------------------
-- Request constraints
-- ----------------------------------------------------------------------------
select throws_ok(
  $$ insert into public.arena_requests (sender_id, recipient_id)
     values ('a0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001') $$,
  '23514',
  null,
  'a player cannot send a request to themselves'
);
insert into public.arena_requests (sender_id, recipient_id)
values ('a0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000002');
select throws_ok(
  $$ insert into public.arena_requests (sender_id, recipient_id)
     values ('a0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000002') $$,
  '23505',
  null,
  'only one pending request per sender/recipient pair'
);
select throws_ok(
  $$ update public.arena_requests set status = 'accepted', responded_at = now()
     where sender_id = 'a0000000-0000-4000-8000-000000000001' $$,
  '23514',
  null,
  'an accepted request must carry a match id'
);
select throws_ok(
  $$ update public.arena_requests set expires_at = created_at
     where sender_id = 'a0000000-0000-4000-8000-000000000001' $$,
  '23514',
  null,
  'request expiry must be after creation'
);

-- ----------------------------------------------------------------------------
-- Queue constraints
-- ----------------------------------------------------------------------------
insert into public.arena_queue (user_id)
values ('a0000000-0000-4000-8000-000000000001');
select throws_ok(
  $$ insert into public.arena_queue (user_id)
     values ('a0000000-0000-4000-8000-000000000001') $$,
  '23505',
  null,
  'one active queue seat per user'
);
select throws_ok(
  $$ update public.arena_queue set status = 'matched'
     where user_id = 'a0000000-0000-4000-8000-000000000001' $$,
  '23514',
  null,
  'a matched seat must carry its match and timestamp'
);

-- ----------------------------------------------------------------------------
-- Match, player and receipt constraints
-- ----------------------------------------------------------------------------
create temporary table schema_test_match as
with inserted as (
  insert into public.arena_matches (mode, exercise, status, origin)
  values ('casual', 'pushups', 'preparing', 'request') returning id
) select id from inserted;

select throws_ok(
  $$ insert into public.arena_matches (mode, exercise, status, origin, starts_at, ends_at)
     values ('casual', 'pushups', 'preparing', 'request', now(), now() + interval '30 seconds') $$,
  '23514',
  null,
  'the round must be exactly 60 seconds'
);

insert into public.arena_match_players (match_id, user_id, slot, rating_before)
select id, 'a0000000-0000-4000-8000-000000000001', 1, 1000 from schema_test_match;

select throws_ok(
  $$ insert into public.arena_match_players (match_id, user_id, slot, rating_before)
     select id, 'a0000000-0000-4000-8000-000000000001', 2, 1000 from schema_test_match $$,
  '23505',
  null,
  'a player can only be in one active match'
);

select throws_ok(
  $$ insert into public.arena_receipts (match_id, exercise, mode, outcome, winner_id, players, finished_at, reason)
     select id, 'pushups', 'casual', 'win', null, '[]'::jsonb, now(), 'test' from schema_test_match $$,
  '23514',
  null,
  'a win receipt must name a winner'
);

select throws_ok(
  $$ insert into public.arena_receipts (match_id, exercise, mode, outcome, winner_id, players, finished_at, reason)
     select id, 'pushups', 'casual', 'draw', null, '[{}]'::jsonb, now(), 'test' from schema_test_match $$,
  '23514',
  null,
  'a receipt must snapshot exactly two players'
);

-- ----------------------------------------------------------------------------
-- Analytics and device constraints
-- ----------------------------------------------------------------------------
select throws_ok(
  $$ insert into public.arena_analytics_events (event, properties)
     values ('Bad Event', '{}'::jsonb) $$,
  '23514',
  null,
  'analytics event names are constrained'
);
select throws_ok(
  $$ insert into public.arena_analytics_events (event, properties)
     values ('valid_event', '[]'::jsonb) $$,
  '23514',
  null,
  'analytics properties must be an object'
);
select throws_ok(
  $$ insert into public.arena_devices (token, user_id)
     values ('short', 'a0000000-0000-4000-8000-000000000001') $$,
  '23514',
  null,
  'device tokens have a minimum length'
);

-- ----------------------------------------------------------------------------
-- Immutability triggers (even the table owner cannot rewrite evidence)
-- ----------------------------------------------------------------------------
insert into public.arena_rating_history (match_id, user_id, rating_before, rating_after, rating_change)
select id, 'a0000000-0000-4000-8000-000000000001', 1000, 1000, 0
from schema_test_match;

select throws_ok(
  $$ update public.arena_rating_history set rating_after = 9999 $$,
  'AR025',
  null,
  'rating history rows cannot be updated'
);
select throws_ok(
  $$ delete from public.arena_rating_history $$,
  'AR025',
  null,
  'rating history rows cannot be deleted'
);
insert into public.arena_match_events (match_id, user_id, event_id, sequence, observed_at, counter_version)
select id, 'a0000000-0000-4000-8000-000000000001', gen_random_uuid(), 1, now(), 'test'
from schema_test_match;

select throws_ok(
  $$ update public.arena_match_events set event_id = gen_random_uuid() $$,
  'AR025',
  null,
  'rep events cannot be updated'
);
select throws_ok(
  $$ delete from public.arena_match_events $$,
  'AR025',
  null,
  'rep events cannot be deleted'
);

insert into public.arena_receipts (match_id, exercise, mode, outcome, winner_id, players, finished_at, reason)
select id, 'pushups', 'casual', 'draw', null,
       jsonb_build_array(
         jsonb_build_object('id', 'a0000000-0000-4000-8000-000000000001', 'score', 1),
         jsonb_build_object('id', 'a0000000-0000-4000-8000-000000000002', 'score', 1)
       ),
       now(), 'test'
from schema_test_match;

select throws_ok(
  $$ update public.arena_receipts set outcome = 'win' $$,
  'AR025',
  null,
  'receipts cannot be updated'
);
select throws_ok(
  $$ delete from public.arena_receipts $$,
  'AR025',
  null,
  'receipts cannot be deleted'
);

-- ----------------------------------------------------------------------------
-- Freshly created users get a profile automatically
-- ----------------------------------------------------------------------------
insert into auth.users (
  instance_id, id, aud, role, email, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values (
  '00000000-0000-0000-0000-000000000000',
  'a0000000-0000-4000-8000-000000000003',
  'authenticated', 'authenticated', 't_schema_carol@fixture.invalid', now(),
  '{}', '{}', now(), now()
);

select is(
  (select rating from public.arena_profiles
   where user_id = 'a0000000-0000-4000-8000-000000000003'),
  1000,
  'a new auth user gets a 1000-rated profile with a null username'
);
select is(
  (select username from public.arena_profiles
   where user_id = 'a0000000-0000-4000-8000-000000000003'),
  null::text,
  'the automatic profile has no username yet'
);

select * from finish();
rollback;
