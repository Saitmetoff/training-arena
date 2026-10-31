-- ============================================================================
-- Training Arena — lifecycle/state-transition tests (pgTAP)
-- Run with: supabase test db
-- Covers: link resolve/rotate/revoke, request send/accept/decline/cancel/expire,
-- queue join/poll/leave/match/expire/block, preparation, ready gate, countdown,
-- live reps (idempotency, sequence, tracking, window, rate), round close,
-- draws, forfeits, absence, service outage, prep timeout and ranked Elo.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select no_plan();

-- ----------------------------------------------------------------------------
-- Fixtures and helpers
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

create or replace function pg_temp.mklink(p_id uuid, p_token text)
returns void
language sql
as $$
  insert into public.arena_links (token, user_id) values (p_token, p_id);
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

-- Reaches live status through the real RPCs, then fast-forwards server time.
create or replace function pg_temp.live_match(p_a uuid, p_b uuid, p_mode text default 'casual')
returns uuid
language plpgsql
as $$
declare
  v_request uuid;
  v_match uuid;
begin
  v_request := pg_temp.new_request(p_a, p_b);
  v_match := ((public.arena_request_accept(p_b, p_b, v_request))->'match'->>'id')::uuid;
  if p_mode = 'ranked' then
    update public.arena_matches set mode = 'ranked' where id = v_match;
  end if;
  perform public.arena_match_ready(p_a, p_a, v_match, true, true);
  perform public.arena_match_ready(p_b, p_b, v_match, true, true);
  update public.arena_matches
  set starts_at = now() - interval '1 second',
      ends_at = now() + interval '59 seconds'
  where id = v_match;
  perform public.arena_match_heartbeat(p_a, p_a, v_match, true);
  return v_match;
end;
$$;

create or replace function pg_temp.match_field(p_match uuid, p_field text)
returns text
language sql
as $$
  select (public.arena_match_view(p_match))->>p_field;
$$;

create or replace function pg_temp.player_score(p_match uuid, p_user uuid)
returns integer
language sql
as $$
  select mp.score from public.arena_match_players mp
  where mp.match_id = p_match and mp.user_id = p_user;
$$;

select pg_temp.mkuser('b0000000-0000-4000-8000-000000000001', 't_flow_alice');
select pg_temp.mkuser('b0000000-0000-4000-8000-000000000002', 't_flow_bob');
select pg_temp.mkuser('b0000000-0000-4000-8000-000000000003', 't_flow_carol');
select pg_temp.mkuser('b0000000-0000-4000-8000-000000000004', 't_flow_dave');
select pg_temp.mkuser('b0000000-0000-4000-8000-000000000005', 't_flow_erin');
select pg_temp.mkuser('b0000000-0000-4000-8000-000000000006', 't_flow_frank');

-- ----------------------------------------------------------------------------
-- Durable links: resolve, revoke, rotate
-- ----------------------------------------------------------------------------
select pg_temp.mklink('b0000000-0000-4000-8000-000000000001', 'flowalice001');

select is(
  public.arena_resolve_link('flowalice001')->>'available',
  'true',
  'an active link resolves for anonymous callers'
);
select is(
  public.arena_resolve_link('FLOWALICE001')->>'available',
  'true',
  'link input is case-insensitive'
);
select is(
  public.arena_resolve_link('unknownlink1')->>'available',
  'false',
  'an unknown link is unavailable without disclosing that it never existed'
);
select is(
  (select owner->>'username' from jsonb_to_record(public.arena_resolve_link('flowalice001')) as x(owner jsonb)) ,
  't_flow_alice',
  'a resolved link exposes the safe public identity'
);

create temporary table rotated_link (token text) on commit drop;
insert into rotated_link
select public.arena_rotate_link(
  'b0000000-0000-4000-8000-000000000001',
  'b0000000-0000-4000-8000-000000000001'
)->'link'->>'token';

select is(
  (select token from rotated_link),
  public.arena_link_json('b0000000-0000-4000-8000-000000000001')->>'token',
  'rotation returns the new active token'
);
select is(
  public.arena_resolve_link('flowalice001')->>'available',
  'false',
  'the previous token stops resolving after rotation'
);
select isnt(
  (select token from rotated_link),
  'flowalice001',
  'rotation actually changes the token'
);

-- Revoke the new link and prove read-only failure.
update public.arena_links
set revoked_at = now()
where user_id = 'b0000000-0000-4000-8000-000000000001' and revoked_at is null;
select is(
  public.arena_resolve_link('flowalice001')->>'available',
  'false',
  'a revoked token stops resolving'
);
select throws_ok(
  $$ select public.arena_request_send(
       'b0000000-0000-4000-8000-000000000002',
       'b0000000-0000-4000-8000-000000000002',
       (select token from public.arena_links
          where user_id = 'b0000000-0000-4000-8000-000000000001' and revoked_at is null)
     ) $$,
  'AR006',
  null,
  'sending to a revoked link fails with link_not_found'
);

-- ----------------------------------------------------------------------------
-- Requests: send, duplicate, self, accept, decline, cancel, expire
-- ----------------------------------------------------------------------------
select pg_temp.mklink('b0000000-0000-4000-8000-000000000001', 'flowalice002');

create temporary table sent_request (payload jsonb) on commit drop;
insert into sent_request
select public.arena_request_send(
  'b0000000-0000-4000-8000-000000000002',
  'b0000000-0000-4000-8000-000000000002',
  'flowalice002'
);

select is(
  (select payload->'request'->>'status' from sent_request),
  'pending',
  'a request starts pending'
);
select is(
  (select payload->'request'->>'expires_at' from sent_request) is not null,
  true,
  'a request always carries an expiry'
);
select throws_ok(
  $$ select public.arena_request_send(
       'b0000000-0000-4000-8000-000000000002',
       'b0000000-0000-4000-8000-000000000002',
       'flowalice002'
     ) $$,
  'AR009',
  null,
  'a duplicate pending request is rejected'
);
select throws_ok(
  $$ select public.arena_request_send(
       'b0000000-0000-4000-8000-000000000001',
       'b0000000-0000-4000-8000-000000000001',
       'flowalice002'
     ) $$,
  'AR001',
  null,
  'a player cannot challenge themselves'
);

select is(
  public.arena_request_respond(
    'b0000000-0000-4000-8000-000000000001',
    'b0000000-0000-4000-8000-000000000001',
    (select id from public.arena_requests
      where recipient_id = 'b0000000-0000-4000-8000-000000000001' and status = 'pending'),
    'decline'
  )->'request'->>'status',
  'declined',
  'the recipient can decline'
);

-- Cancel path
select pg_temp.new_request('b0000000-0000-4000-8000-000000000002', 'b0000000-0000-4000-8000-000000000001');
select is(
  public.arena_request_respond(
    'b0000000-0000-4000-8000-000000000002',
    'b0000000-0000-4000-8000-000000000002',
    (select id from public.arena_requests
      where sender_id = 'b0000000-0000-4000-8000-000000000002' and status = 'pending'),
    'cancel'
  )->'request'->>'status',
  'cancelled',
  'the sender can cancel'
);

-- Expiry path
create temporary table expired_request (id uuid) on commit drop;
insert into expired_request
select pg_temp.new_request('b0000000-0000-4000-8000-000000000002', 'b0000000-0000-4000-8000-000000000001');
update public.arena_requests
set created_at = now() - interval '25 hours',
    expires_at = now() - interval '1 hour'
where id = (select id from expired_request);
select throws_ok(
  format(
    $$ select public.arena_request_accept(
         'b0000000-0000-4000-8000-000000000001',
         'b0000000-0000-4000-8000-000000000001',
         %L
       ) $$,
    (select id from expired_request)
  ),
  'AR008',
  null,
  'accepting after 24 hours fails with request_expired'
);
-- Inbox polling applies the persisted expiry lazily (the failed accept rolled
-- back, so nothing was written by the attempt).
select public.arena_inbox(
  'b0000000-0000-4000-8000-000000000001',
  'b0000000-0000-4000-8000-000000000001'
);
select is(
  (select status::text from public.arena_requests where id = (select id from expired_request)),
  'expired',
  'inbox polling persists the expired status'
);

-- ----------------------------------------------------------------------------
-- Preparation, ready gate and countdown
-- ----------------------------------------------------------------------------
create temporary table flow (id text primary key, match_id uuid, match2_id uuid) on commit drop;
insert into flow (id) values ('flow');
update flow
set match_id = (public.arena_request_accept(
      'b0000000-0000-4000-8000-000000000001',
      'b0000000-0000-4000-8000-000000000001',
      pg_temp.new_request('b0000000-0000-4000-8000-000000000002', 'b0000000-0000-4000-8000-000000000001')
    )->'match'->>'id')::uuid;

select is(pg_temp.match_field((select match_id from flow), 'status'), 'preparing', 'accepting a request creates a preparing match');
select is(
  public.arena_match_ready(
    'b0000000-0000-4000-8000-000000000002',
    'b0000000-0000-4000-8000-000000000002',
    (select match_id from flow),
    true,
    true
  )->'match'->>'status',
  'preparing',
  'one player cannot start the countdown alone'
);
select is(
  public.arena_match_ready(
    'b0000000-0000-4000-8000-000000000001',
    'b0000000-0000-4000-8000-000000000001',
    (select match_id from flow),
    true,
    true
  )->'match'->>'status',
  'countdown',
  'readiness from the second player starts the countdown'
);
select is(
  extract(epoch from (
    (public.arena_match_view((select match_id from flow))->>'ends_at')::timestamptz
    - (public.arena_match_view((select match_id from flow))->>'starts_at')::timestamptz
  ))::integer,
  60,
  'the live round is exactly 60 seconds'
);

select is(
  public.arena_match_heartbeat(
    'b0000000-0000-4000-8000-000000000002',
    'b0000000-0000-4000-8000-000000000002',
    (select match_id from flow),
    false
  )->'match'->>'status',
  'preparing',
  'tracking loss during countdown reverts to preparing'
);
select is(
  public.arena_match_view((select match_id from flow))->>'starts_at',
  null,
  'the cancelled countdown clears its server clock'
);
select is(
  public.arena_match_ready(
    'b0000000-0000-4000-8000-000000000002',
    'b0000000-0000-4000-8000-000000000002',
    (select match_id from flow),
    true,
    true
  )->'match'->>'status',
  'countdown',
  'regaining tracking and readiness restarts the countdown'
);

-- Fast-forward to live through the real tick.
update public.arena_matches
set starts_at = now() - interval '1 second',
    ends_at = now() + interval '59 seconds'
where id = (select match_id from flow);
select is(
  public.arena_match_heartbeat(
    'b0000000-0000-4000-8000-000000000002',
    'b0000000-0000-4000-8000-000000000002',
    (select match_id from flow),
    true
  )->'match'->>'status',
  'live',
  'server time moves countdown to live'
);

-- ----------------------------------------------------------------------------
-- Reps: accepting, duplicate idempotency, sequence, window, tracking, rate
-- ----------------------------------------------------------------------------
select is(
  public.arena_match_rep(
    'b0000000-0000-4000-8000-000000000002',
    'b0000000-0000-4000-8000-000000000002',
    (select match_id from flow),
    'e0000000-0000-4000-8000-000000000001',
    1,
    now(),
    '1.3.0'
  )->'match'->'players'->0->>'score',
  '1',
  'a valid live rep is counted'
);
select is(
  public.arena_match_rep(
    'b0000000-0000-4000-8000-000000000002',
    'b0000000-0000-4000-8000-000000000002',
    (select match_id from flow),
    'e0000000-0000-4000-8000-000000000001',
    1,
    now(),
    '1.3.0'
  )->'match'->'players'->0->>'score',
  '1',
  'a retried event_id does not double-count'
);
select is(
  (select count(*)::integer from public.arena_match_events
    where match_id = (select match_id from flow)
      and user_id = 'b0000000-0000-4000-8000-000000000002'),
  1,
  'the duplicate retry stored no second event row'
);
select throws_ok(
  format(
    $$ select public.arena_match_rep(
         'b0000000-0000-4000-8000-000000000002',
         'b0000000-0000-4000-8000-000000000002',
         %L, 'e0000000-0000-4000-8000-000000000002', 1, now(), '1.3.0'
       ) $$,
    (select match_id from flow)
  ),
  'AR015',
  null,
  'a stale sequence is rejected'
);
select throws_ok(
  format(
    $$ select public.arena_match_rep(
         'b0000000-0000-4000-8000-000000000002',
         'b0000000-0000-4000-8000-000000000002',
         %L, 'e0000000-0000-4000-8000-000000000003', 2, now() + interval '1 hour', '1.3.0'
       ) $$,
    (select match_id from flow)
  ),
  'AR015',
  null,
  'a rep observed far outside the round window is rejected'
);
update public.arena_match_players
set last_tracking_at = now() - interval '30 seconds'
where match_id = (select match_id from flow) and user_id = 'b0000000-0000-4000-8000-000000000002';
select throws_ok(
  format(
    $$ select public.arena_match_rep(
         'b0000000-0000-4000-8000-000000000002',
         'b0000000-0000-4000-8000-000000000002',
         %L, 'e0000000-0000-4000-8000-000000000004', 2, now(), '1.3.0'
       ) $$,
    (select match_id from flow)
  ),
  'AR016',
  null,
  'stale tracking rejects new reps'
);
update public.arena_match_players
set last_tracking_at = now()
where match_id = (select match_id from flow) and user_id = 'b0000000-0000-4000-8000-000000000002';

select pg_sleep(0.2);
select is(
  public.arena_match_rep(
    'b0000000-0000-4000-8000-000000000002',
    'b0000000-0000-4000-8000-000000000002',
    (select match_id from flow),
    'e0000000-0000-4000-8000-000000000005',
    2,
    now(),
    '1.3.0'
  )->'match'->'players'->0->>'score',
  '2',
  'a fresh event with an increasing sequence is counted'
);
select throws_ok(
  format(
    $$ select public.arena_match_rep(
         'b0000000-0000-4000-8000-000000000002',
         'b0000000-0000-4000-8000-000000000002',
         %L, 'e0000000-0000-4000-8000-000000000006', 3, now(), '1.3.0'
       ) $$,
    (select match_id from flow)
  ),
  'AR017',
  null,
  'rep flooding is rate limited'
);

-- ----------------------------------------------------------------------------
-- Round close by score, then immutability of the result
-- ----------------------------------------------------------------------------
update public.arena_matches
set starts_at = now() - interval '61 seconds',
    ends_at = now() - interval '1 second'
where id = (select match_id from flow);
select is(
  public.arena_match_state(
    'b0000000-0000-4000-8000-000000000002',
    'b0000000-0000-4000-8000-000000000002',
    (select match_id from flow)
  )->'match'->>'status',
  'finished',
  'the server closes the match when the round ends'
);
select is(
  public.arena_match_view((select match_id from flow))->'receipt'->>'outcome',
  'win',
  'the higher score wins'
);
select is(
  (public.arena_match_view((select match_id from flow))->'receipt'->>'winner_id')::uuid,
  'b0000000-0000-4000-8000-000000000002'::uuid,
  'the winner is the player who scored more'
);
select is(
  (select count(*)::integer from public.arena_receipts where match_id = (select match_id from flow)),
  1,
  'exactly one receipt per match'
);
select is(
  (select rating from public.arena_profiles where user_id = 'b0000000-0000-4000-8000-000000000002'),
  1000,
  'a casual win never changes rating'
);
select is(
  (select count(*)::integer from public.arena_rating_history where match_id = (select match_id from flow)),
  0,
  'a casual result writes no rating history'
);
select is(
  (public.arena_match_view((select match_id from flow))->'receipt'->'players'->0->>'rating_change'),
  null,
  'a casual receipt has no rating change snapshot'
);
select throws_ok(
  format(
    $$ select public.arena_match_rep(
         'b0000000-0000-4000-8000-000000000002',
         'b0000000-0000-4000-8000-000000000002',
         %L, 'e0000000-0000-4000-8000-000000000007', 3, now(), '1.3.0'
       ) $$,
    (select match_id from flow)
  ),
  'AR014',
  null,
  'new reps after the final whistle are rejected'
);
select is(
  public.arena_match_rep(
    'b0000000-0000-4000-8000-000000000002',
    'b0000000-0000-4000-8000-000000000002',
    (select match_id from flow),
    'e0000000-0000-4000-8000-000000000005',
    3,
    now(),
    '1.3.0'
  )->'match'->>'status',
  'finished',
  'a retried accepted event on a closed match is still idempotent'
);

-- ----------------------------------------------------------------------------
-- Draws stay draws
-- ----------------------------------------------------------------------------
select pg_temp.mkuser('b0000000-0000-4000-8000-000000000007', 't_flow_grace');
select pg_temp.mkuser('b0000000-0000-4000-8000-000000000008', 't_flow_heidi');
update flow set match2_id = pg_temp.live_match(
  'b0000000-0000-4000-8000-000000000007',
  'b0000000-0000-4000-8000-000000000008'
);
update public.arena_matches
set starts_at = now() - interval '61 seconds',
    ends_at = now() - interval '1 second'
where id = (select match2_id from flow);
select is(
  public.arena_match_state(
    'b0000000-0000-4000-8000-000000000007',
    'b0000000-0000-4000-8000-000000000007',
    (select match2_id from flow)
  )->'match'->'receipt'->>'outcome',
  'draw',
  'equal scores remain a draw'
);
select is(
  (public.arena_match_view((select match2_id from flow))->'receipt'->>'winner_id'),
  null,
  'a draw has no winner'
);

-- ----------------------------------------------------------------------------
-- Forfeit: one player absent for more than ten seconds
-- ----------------------------------------------------------------------------
select pg_temp.mkuser('b0000000-0000-4000-8000-000000000009', 't_flow_ivan');
select pg_temp.mkuser('b0000000-0000-4000-8000-000000000010', 't_flow_jane');
create temporary table flow2 (match_id uuid) on commit drop;
insert into flow2
values (pg_temp.live_match('b0000000-0000-4000-8000-000000000009', 'b0000000-0000-4000-8000-000000000010', 'ranked'));

update public.arena_match_players
set last_seen_at = now() - interval '30 seconds'
where match_id = (select match_id from flow2)
  and user_id = 'b0000000-0000-4000-8000-000000000010';

select is(
  public.arena_match_state(
    'b0000000-0000-4000-8000-000000000009',
    'b0000000-0000-4000-8000-000000000009',
    (select match_id from flow2)
  )->'match'->'receipt'->>'outcome',
  'win',
  'an absent player forfeits'
);
select is(
  (public.arena_match_view((select match_id from flow2))->'receipt'->>'winner_id')::uuid,
  'b0000000-0000-4000-8000-000000000009'::uuid,
  'the present player wins the forfeit'
);
select is(
  (public.arena_match_view((select match_id from flow2))->'receipt'->>'reason'),
  'opponent_absent',
  'the forfeit reason is recorded'
);

-- Ranked Elo updates both ratings exactly once.
select is(
  (select rating from public.arena_profiles where user_id = 'b0000000-0000-4000-8000-000000000009'),
  1016,
  'the ranked winner gains 16 points at equal rating'
);
select is(
  (select rating from public.arena_profiles where user_id = 'b0000000-0000-4000-8000-000000000010'),
  984,
  'the ranked loser drops 16 points at equal rating'
);
select is(
  (select count(*)::integer from public.arena_rating_history where match_id = (select match_id from flow2)),
  2,
  'both rating updates are recorded in the audit table'
);
select is(
  (select ranked_battles from public.arena_profiles where user_id = 'b0000000-0000-4000-8000-000000000009'),
  1,
  'the ranked battle counter increments once'
);
select is(
  public.arena_match_state(
    'b0000000-0000-4000-8000-000000000009',
    'b0000000-0000-4000-8000-000000000009',
    (select match_id from flow2)
  )->'match'->>'status',
  'finished',
  'retrying the close is idempotent'
);
select is(
  (select rating from public.arena_profiles where user_id = 'b0000000-0000-4000-8000-000000000009'),
  1016,
  'retrying the close never double-credits rating'
);
select is(
  (select count(*)::integer from public.arena_rating_history where match_id = (select match_id from flow2)),
  2,
  'retrying the close never duplicates rating history'
);

-- ----------------------------------------------------------------------------
-- Shared outage: both players absent -> no_result and no rating change
-- ----------------------------------------------------------------------------
select pg_temp.mkuser('b0000000-0000-4000-8000-000000000011', 't_flow_karl');
select pg_temp.mkuser('b0000000-0000-4000-8000-000000000012', 't_flow_lisa');
create temporary table flow3 (match_id uuid) on commit drop;
insert into flow3
values (pg_temp.live_match('b0000000-0000-4000-8000-000000000011', 'b0000000-0000-4000-8000-000000000012', 'ranked'));

update public.arena_match_players
set last_seen_at = now() - interval '30 seconds'
where match_id = (select match_id from flow3);

select is(
  public.arena_match_state(
    'b0000000-0000-4000-8000-000000000011',
    'b0000000-0000-4000-8000-000000000011',
    (select match_id from flow3)
  )->'match'->>'status',
  'no_result',
  'both absent yields no_result'
);
select is(
  (public.arena_match_view((select match_id from flow3))->'receipt'->>'reason'),
  'service_outage',
  'the conservative no_result reason is recorded'
);
select is(
  (select rating from public.arena_profiles where user_id = 'b0000000-0000-4000-8000-000000000011'),
  1000,
  'no_result leaves the ranked rating unchanged'
);
select is(
  (select count(*)::integer from public.arena_rating_history where match_id = (select match_id from flow3)),
  0,
  'no_result writes no rating history'
);
select is(
  public.arena_match_view((select match_id from flow3))->'receipt'->'players'->0->>'rating_change',
  null,
  'no_result receipts have no rating change'
);

-- ----------------------------------------------------------------------------
-- Early readiness never forfeits at live start
-- ----------------------------------------------------------------------------
select pg_temp.mkuser('b0000000-0000-4000-8000-00000000002a', 't_flow_early1');
select pg_temp.mkuser('b0000000-0000-4000-8000-00000000002b', 't_flow_early2');
create temporary table flow_early (match_id uuid) on commit drop;
insert into flow_early
values (
  (
    (
      public.arena_request_accept(
        'b0000000-0000-4000-8000-00000000002b',
        'b0000000-0000-4000-8000-00000000002b',
        pg_temp.new_request(
          'b0000000-0000-4000-8000-00000000002a',
          'b0000000-0000-4000-8000-00000000002b'
        )
      )
    )->'match'->>'id'
  )::uuid
);

-- Olga readies first, then waits while Paul takes the practice rep.
select lives_ok(
  format(
    'select public.arena_match_ready(%L, %L, %L, true, true)',
    'b0000000-0000-4000-8000-00000000002a',
    'b0000000-0000-4000-8000-00000000002a',
    (select match_id from flow_early)
  ),
  'the first player can confirm ready'
);
update public.arena_match_players
set last_seen_at = now() - interval '30 seconds'
where match_id = (select match_id from flow_early)
  and user_id = 'b0000000-0000-4000-8000-00000000002a';

-- Paul readies; the countdown starts and the match turns live.
select lives_ok(
  format(
    'select public.arena_match_ready(%L, %L, %L, true, true)',
    'b0000000-0000-4000-8000-00000000002b',
    'b0000000-0000-4000-8000-00000000002b',
    (select match_id from flow_early)
  ),
  'the second player can confirm ready'
);
update public.arena_matches
set starts_at = now() - interval '1 second',
    ends_at = now() + interval '59 seconds'
where id = (select match_id from flow_early);
select lives_ok(
  format(
    'select public.arena_match_heartbeat(%L, %L, %L, true)',
    'b0000000-0000-4000-8000-00000000002b',
    'b0000000-0000-4000-8000-00000000002b',
    (select match_id from flow_early)
  ),
  'the live phase starts on the next tick'
);

select is(
  public.arena_match_view((select match_id from flow_early))->>'status',
  'live',
  'an early-ready player is not forfeited when the live phase starts'
);
select is(
  public.arena_match_view((select match_id from flow_early))->'receipt'->>'outcome',
  null,
  'no forfeit receipt is written at the live start'
);

-- The live recovery window still forfeits a player who then goes missing.
update public.arena_match_players
set last_seen_at = now() - interval '30 seconds'
where match_id = (select match_id from flow_early)
  and user_id = 'b0000000-0000-4000-8000-00000000002a';
select is(
  public.arena_match_state(
    'b0000000-0000-4000-8000-00000000002b',
    'b0000000-0000-4000-8000-00000000002b',
    (select match_id from flow_early)
  )->'match'->'receipt'->>'reason',
  'opponent_absent',
  'absence during live still forfeits after the fresh start'
);

-- ----------------------------------------------------------------------------
-- A shared outage across the live start is still reconciled
-- ----------------------------------------------------------------------------
select pg_temp.mkuser('b0000000-0000-4000-8000-00000000002c', 't_flow_out1');
select pg_temp.mkuser('b0000000-0000-4000-8000-00000000002d', 't_flow_out2');
create temporary table flow_outage (match_id uuid) on commit drop;
insert into flow_outage
values (
  (
    (
      public.arena_request_accept(
        'b0000000-0000-4000-8000-00000000002d',
        'b0000000-0000-4000-8000-00000000002d',
        pg_temp.new_request(
          'b0000000-0000-4000-8000-00000000002c',
          'b0000000-0000-4000-8000-00000000002d'
        )
      )
    )->'match'->>'id'
  )::uuid
);
select lives_ok(
  format(
    'select public.arena_match_ready(%L, %L, %L, true, true)',
    'b0000000-0000-4000-8000-00000000002c',
    'b0000000-0000-4000-8000-00000000002c',
    (select match_id from flow_outage)
  ),
  'the first player can confirm ready before the outage'
);
select lives_ok(
  format(
    'select public.arena_match_ready(%L, %L, %L, true, true)',
    'b0000000-0000-4000-8000-00000000002d',
    'b0000000-0000-4000-8000-00000000002d',
    (select match_id from flow_outage)
  ),
  'the second player can confirm ready before the outage'
);

-- Both clients disappear during the countdown. Live started 12 s ago and no
-- heartbeat arrived since, so the first sweep must reconcile the outage
-- instead of lifting the pair to the sweep clock as present.
update public.arena_matches
set starts_at = now() - interval '12 seconds',
    ends_at = now() + interval '48 seconds'
where id = (select match_id from flow_outage);
update public.arena_match_players
set last_seen_at = now() - interval '30 seconds'
where match_id = (select match_id from flow_outage);
select is(
  public.arena_match_state(
    'b0000000-0000-4000-8000-00000000002c',
    'b0000000-0000-4000-8000-00000000002c',
    (select match_id from flow_outage)
  )->'match'->>'status',
  'no_result',
  'a shared outage across the live start closes as no_result'
);
select is(
  public.arena_match_view((select match_id from flow_outage))
    ->'receipt'->>'reason',
  'service_outage',
  'the shared-outage reason is recorded after the live-start presence lift'
);

-- ----------------------------------------------------------------------------
-- Voluntary leave
-- ----------------------------------------------------------------------------
select pg_temp.mkuser('b0000000-0000-4000-8000-000000000013', 't_flow_mia');
select pg_temp.mkuser('b0000000-0000-4000-8000-000000000014', 't_flow_nick');
create temporary table flow4 (match_id uuid) on commit drop;
insert into flow4
values (pg_temp.live_match('b0000000-0000-4000-8000-000000000013', 'b0000000-0000-4000-8000-000000000014'));

select is(
  public.arena_match_leave(
    'b0000000-0000-4000-8000-000000000014',
    'b0000000-0000-4000-8000-000000000014',
    (select match_id from flow4)
  )->'match'->'receipt'->>'outcome',
  'win',
  'leaving a live match forfeits to the opponent'
);
select is(
  (public.arena_match_view((select match_id from flow4))->'receipt'->>'winner_id')::uuid,
  'b0000000-0000-4000-8000-000000000013'::uuid,
  'the remaining player is the winner'
);

-- Leaving during preparation is a no_result, never a rating change.
create temporary table flow5 (match_id uuid) on commit drop;
insert into flow5
select ((public.arena_request_accept(
  'b0000000-0000-4000-8000-000000000013',
  'b0000000-0000-4000-8000-000000000013',
  pg_temp.new_request('b0000000-0000-4000-8000-000000000014', 'b0000000-0000-4000-8000-000000000013')
))->'match'->>'id')::uuid;

select is(
  public.arena_match_leave(
    'b0000000-0000-4000-8000-000000000014',
    'b0000000-0000-4000-8000-000000000014',
    (select match_id from flow5)
  )->'match'->>'status',
  'no_result',
  'leaving during preparation closes without a result'
);

-- ----------------------------------------------------------------------------
-- Preparation abandoned for ten minutes expires without rating
-- ----------------------------------------------------------------------------
select pg_temp.mkuser('b0000000-0000-4000-8000-000000000015', 't_flow_olga');
select pg_temp.mkuser('b0000000-0000-4000-8000-000000000016', 't_flow_paul');
create temporary table flow6 (match_id uuid) on commit drop;
insert into flow6
select ((public.arena_request_accept(
  'b0000000-0000-4000-8000-000000000016',
  'b0000000-0000-4000-8000-000000000016',
  pg_temp.new_request('b0000000-0000-4000-8000-000000000015', 'b0000000-0000-4000-8000-000000000016')
))->'match'->>'id')::uuid;
update public.arena_matches
set created_at = now() - interval '20 minutes',
    prep_expires_at = now() - interval '10 minutes'
where id = (select match_id from flow6);

select is(
  public.arena_match_state(
    'b0000000-0000-4000-8000-000000000015',
    'b0000000-0000-4000-8000-000000000015',
    (select match_id from flow6)
  )->'match'->>'status',
  'no_result',
  'abandoned preparation expires'
);
select is(
  (public.arena_match_view((select match_id from flow6))->'receipt'->>'reason'),
  'prep_timeout',
  'the prep timeout reason is recorded'
);

-- ----------------------------------------------------------------------------
-- Ranked queue: join idempotency, matching, expiry, leave, blocks
-- ----------------------------------------------------------------------------
select is(
  public.arena_queue_join(
    'b0000000-0000-4000-8000-000000000003',
    'b0000000-0000-4000-8000-000000000003'
  )->>'queued',
  'true',
  'joining the queue creates a seat'
);
select is(
  (select count(*)::integer from public.arena_queue
    where user_id = 'b0000000-0000-4000-8000-000000000003' and status = 'queued'),
  1,
  'only one active seat per user exists'
);
select is(
  public.arena_queue_join(
    'b0000000-0000-4000-8000-000000000003',
    'b0000000-0000-4000-8000-000000000003'
  )->>'queued',
  'true',
  'joining twice is idempotent'
);
select is(
  (select count(*)::integer from public.arena_queue
    where user_id = 'b0000000-0000-4000-8000-000000000003' and status = 'queued'),
  1,
  'joining twice created no second seat'
);

select is(
  public.arena_queue_join(
    'b0000000-0000-4000-8000-000000000004',
    'b0000000-0000-4000-8000-000000000004'
  )->'match'->>'status',
  'preparing',
  'a second queued player is matched immediately'
);
select is(
  public.arena_queue_join(
    'b0000000-0000-4000-8000-000000000004',
    'b0000000-0000-4000-8000-000000000004'
  )->'match'->>'mode',
  'ranked',
  'queue matches are ranked'
);
select is(
  public.arena_active_match_id('b0000000-0000-4000-8000-000000000003') = public.arena_active_match_id('b0000000-0000-4000-8000-000000000004'),
  true,
  'both queued players land in the same active match'
);
select is(
  (select count(*)::integer from public.arena_queue
    where user_id in ('b0000000-0000-4000-8000-000000000003', 'b0000000-0000-4000-8000-000000000004')
      and status = 'matched'),
  2,
  'both queue seats are marked matched'
);

-- Queue expiry (a queued seat older than 60 seconds)
select pg_temp.mkuser('b0000000-0000-4000-8000-000000000017', 't_flow_quinn');
select public.arena_queue_join('b0000000-0000-4000-8000-000000000017', 'b0000000-0000-4000-8000-000000000017');
update public.arena_queue
set created_at = now() - interval '2 minutes',
    expires_at = now() - interval '1 minute'
where user_id = 'b0000000-0000-4000-8000-000000000017' and status = 'queued';
select is(
  public.arena_queue_poll(
    'b0000000-0000-4000-8000-000000000017',
    'b0000000-0000-4000-8000-000000000017'
  )->>'queued',
  'false',
  'an expired queue seat reports not queued'
);
select is(
  (select status::text from public.arena_queue
    where user_id = 'b0000000-0000-4000-8000-000000000017' order by created_at desc limit 1),
  'expired',
  'the expired seat is persisted as expired'
);

-- Queue leave
select public.arena_queue_join('b0000000-0000-4000-8000-000000000017', 'b0000000-0000-4000-8000-000000000017');
select is(
  public.arena_queue_leave('b0000000-0000-4000-8000-000000000017', 'b0000000-0000-4000-8000-000000000017')->>'ok',
  'true',
  'leaving the queue succeeds'
);
select is(
  (select status::text from public.arena_queue
    where user_id = 'b0000000-0000-4000-8000-000000000017' and status = 'cancelled' limit 1),
  'cancelled',
  'the seat is cancelled'
);

-- A blocked pair is never matched.
insert into public.arena_blocks (blocker_id, blocked_id)
values ('b0000000-0000-4000-8000-000000000005', 'b0000000-0000-4000-8000-000000000006');
select public.arena_queue_join('b0000000-0000-4000-8000-000000000005', 'b0000000-0000-4000-8000-000000000005');
select public.arena_queue_join('b0000000-0000-4000-8000-000000000006', 'b0000000-0000-4000-8000-000000000006');
update public.arena_queue
set created_at = now() - interval '30 seconds',
    expires_at = now() + interval '30 seconds'
where status = 'queued';
select is(
  public.arena_queue_poll(
    'b0000000-0000-4000-8000-000000000006',
    'b0000000-0000-4000-8000-000000000006'
  )->>'match',
  null,
  'blocked players are never matched together'
);

-- Blocking also stops a new request (006 -> 005, blocked by 005).
select pg_temp.mklink('b0000000-0000-4000-8000-000000000005', 'flowerin0025');
select throws_ok(
  $$ select public.arena_request_send(
       'b0000000-0000-4000-8000-000000000006',
       'b0000000-0000-4000-8000-000000000006',
       'flowerin0025'
     ) $$,
  'AR010',
  null,
  'a blocked player cannot send a request to the blocker'
);

-- ----------------------------------------------------------------------------
-- One active battle per player (003 is already in a ranked match)
-- ----------------------------------------------------------------------------
select throws_ok(
  format(
    $$ select public.arena_request_accept(
         'b0000000-0000-4000-8000-000000000003',
         'b0000000-0000-4000-8000-000000000003',
         %L
       ) $$,
    pg_temp.new_request('b0000000-0000-4000-8000-000000000017', 'b0000000-0000-4000-8000-000000000003')
  ),
  'AR011',
  null,
  'a busy player cannot accept another battle'
);

-- ----------------------------------------------------------------------------
-- Maintenance sweep closes idle work
-- ----------------------------------------------------------------------------
select pg_temp.mkuser('b0000000-0000-4000-8000-000000000018', 't_flow_rhea');
select pg_temp.mkuser('b0000000-0000-4000-8000-000000000019', 't_flow_sam');
insert into public.arena_requests (sender_id, recipient_id, created_at, expires_at)
values (
  'b0000000-0000-4000-8000-000000000018',
  'b0000000-0000-4000-8000-000000000019',
  now() - interval '25 hours',
  now() - interval '1 hour'
);
select is(
  (public.arena_maintenance()->>'expired_requests')::integer >= 1,
  true,
  'maintenance expires overdue requests'
);

select * from finish();
rollback;
