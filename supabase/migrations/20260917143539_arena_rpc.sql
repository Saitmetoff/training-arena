-- ============================================================================
-- Training Arena — authoritative RPCs (task 04, part 2 of 2)
-- ============================================================================
-- Every client action from docs/API.md is one `security definer` RPC in this
-- file. They are executable only by `service_role`; the `arena` Edge Function
-- verifies the bearer token, resolves `sub` + `session_id`, and then calls
-- these functions. No RPC trusts a client-supplied user id, rating, outcome,
-- observed timestamp or exercise.
--
-- Error contract: SQLSTATE `AR0xx` is raised through `arena_fail`. The Edge
-- Function maps it to `{error:{code,message}}` (see docs/API.md catalogue):
--   AR001 invalid_request, AR002 unauthorized, AR003 not_found,
--   AR004 username_taken, AR005 username_invalid, AR006 link_not_found,
--   AR007 request_closed, AR008 request_expired, AR009 request_exists,
--   AR010 blocked, AR011 busy, AR012 match_not_ready, AR013 match_closed,
--   AR014 match_not_live, AR015 rep_rejected, AR016 tracking_stale,
--   AR017 rate_limited, AR018 avatar_invalid, AR019 avatar_too_large,
--   AR020 username_required, AR021 forbidden, AR022 invalid_action,
--   AR023 payload_too_large, AR024 conflict, AR025 internal_error.
--
-- Match clock (server time only):
--   accepted/queued -> preparing (10 min deadline)
--   both ready       -> countdown (5 s) -> live (60 s) -> finished/no_result
-- Rep events are idempotent by event_id, strictly increasing by sequence,
-- accepted only while live with fresh tracking, and capped per round.
--
-- Rollback notes: drop every function in this file (they depend on the
-- tables from 20260917143538_arena_initial.sql, which must be rolled back
-- afterwards). Because all functions are revoked from PUBLIC/anon/authenticated
-- and granted only to service_role, dropping the schema migration first would
-- fail on dependencies; drop in this order:
--   1. drop function public.arena_outbox_confirm(...); ... (all signatures)
--   2. drop the 20260917143538 schema objects.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Internal helpers
-- ----------------------------------------------------------------------------
create or replace function public.arena_fail(p_code text, p_message text)
returns void
language plpgsql
volatile
as $$
begin
  raise exception using errcode = p_code, message = p_message;
end;
$$;

create or replace function public.arena_assert_actor(p_actor uuid, p_session uuid)
returns public.arena_profiles
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_profile public.arena_profiles;
begin
  if p_actor is null or p_session is null then
    perform public.arena_fail('AR002', 'authentication required');
  end if;
  if not exists (
    select 1
    from auth.sessions s
    where s.id = p_session
      and s.user_id = p_actor
      and (s.not_after is null or s.not_after > now())
  ) then
    perform public.arena_fail('AR002', 'session is no longer active');
  end if;
  select * into v_profile from public.arena_profiles where user_id = p_actor;
  if not found then
    insert into public.arena_profiles (user_id) values (p_actor)
    on conflict (user_id) do nothing;
    select * into v_profile from public.arena_profiles where user_id = p_actor;
  end if;
  if v_profile.user_id is null or v_profile.deleted_at is not null then
    perform public.arena_fail('AR002', 'account is unavailable');
  end if;
  return v_profile;
end;
$$;

create or replace function public.arena_profile_json(p_user_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select jsonb_build_object(
    'id', pr.user_id,
    'username', pr.username,
    'avatar_url', pr.avatar_url,
    'rating', pr.rating,
    'ranked_wins', pr.ranked_wins,
    'ranked_battles', pr.ranked_battles
  )
  from public.arena_profiles pr
  where pr.user_id = p_user_id
    and pr.deleted_at is null;
$$;

create or replace function public.arena_link_json(p_user_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select jsonb_build_object('token', l.token, 'code', l.token)
  from public.arena_links l
  where l.user_id = p_user_id
    and l.revoked_at is null
  order by l.created_at desc
  limit 1;
$$;

create or replace function public.arena_active_match_id(p_user_id uuid)
returns uuid
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select m.id
  from public.arena_match_players mp
  join public.arena_matches m on m.id = mp.match_id
  where mp.user_id = p_user_id
    and mp.is_active
    and m.status in ('preparing', 'countdown', 'live')
  order by m.created_at desc
  limit 1;
$$;

create or replace function public.arena_are_blocked(p_a uuid, p_b uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.arena_blocks b
    where (b.blocker_id = p_a and b.blocked_id = p_b)
       or (b.blocker_id = p_b and b.blocked_id = p_a)
  );
$$;

create or replace function public.arena_new_token()
returns text
language sql
volatile
as $$
  select lower(encode(extensions.gen_random_bytes(6), 'hex'));
$$;

create or replace function public.arena_notify(
  p_user_id uuid,
  p_kind text,
  p_payload jsonb
)
returns void
language sql
volatile
security definer
set search_path = public, pg_temp
as $$
  insert into public.arena_notification_outbox (user_id, kind, payload)
  values (p_user_id, p_kind, coalesce(p_payload, '{}'::jsonb));
$$;

create or replace function public.arena_receipt_json(p_receipt_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select jsonb_build_object(
    'id', r.id,
    'match_id', r.match_id,
    'exercise', r.exercise,
    'mode', r.mode,
    'players', r.players,
    'winner_id', r.winner_id,
    'outcome', r.outcome,
    'finished_at', r.finished_at,
    'reason', r.reason
  )
  from public.arena_receipts r
  where r.id = p_receipt_id;
$$;

create or replace function public.arena_match_view(p_match_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select jsonb_build_object(
    'id', m.id,
    'exercise', m.exercise,
    'mode', m.mode,
    'status', m.status,
    'players', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', mp.user_id,
          'username', coalesce(pr.username, mp.username_snapshot),
          'avatar_url', coalesce(pr.avatar_url, mp.avatar_url_snapshot),
          'score', mp.score,
          'ready', mp.ready,
          'last_seen', mp.last_seen_at,
          'tracking', mp.tracking,
          'practice_complete', mp.practice_complete,
          'left', mp.left_at is not null
        )
        order by mp.slot
      )
      from public.arena_match_players mp
      left join public.arena_profiles pr on pr.user_id = mp.user_id
      where mp.match_id = m.id
    ), '[]'::jsonb),
    'starts_at', m.starts_at,
    'ends_at', m.ends_at,
    'server_now', clock_timestamp(),
    'receipt', (
      select public.arena_receipt_json(r.id)
      from public.arena_receipts r
      where r.match_id = m.id
    )
  )
  from public.arena_matches m
  where m.id = p_match_id;
$$;

create or replace function public.arena_request_json(p_request_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select jsonb_build_object(
    'id', r.id,
    'sender', public.arena_profile_json(r.sender_id),
    'recipient', public.arena_profile_json(r.recipient_id),
    'status', r.status,
    'created_at', r.created_at,
    'expires_at', r.expires_at,
    'match_id', r.match_id
  )
  from public.arena_requests r
  where r.id = p_request_id;
$$;

create or replace function public.arena_expire_requests_for(p_user_id uuid)
returns integer
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_count integer;
begin
  update public.arena_requests
  set status = 'expired', responded_at = now()
  where status = 'pending'
    and expires_at <= now()
    and (sender_id = p_user_id or recipient_id = p_user_id);
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

-- ----------------------------------------------------------------------------
-- Match clock and closure. `arena_close_match` is the single writer of
-- receipts, rating updates and rating history, so it is safe under retries
-- and concurrency: the match row lock plus the unique keys on receipts and
-- rating history make a second closure a no-op.
-- ----------------------------------------------------------------------------
create or replace function public.arena_close_match(
  p_match_id uuid,
  p_reason text,
  p_outcome public.arena_outcome default null,
  p_winner uuid default null
)
returns uuid
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_match public.arena_matches;
  v_receipt_id uuid;
  v_p1 public.arena_match_players;
  v_p2 public.arena_match_players;
  v_username1 text;
  v_username2 text;
  v_avatar1 text;
  v_avatar2 text;
  v_outcome public.arena_outcome;
  v_winner uuid;
  v_rating1 integer;
  v_rating2 integer;
  v_after1 integer;
  v_after2 integer;
  v_change1 integer;
  v_change2 integer;
  v_score1 numeric;
  v_score2 numeric;
  v_players jsonb;
begin
  select * into v_match
  from public.arena_matches
  where id = p_match_id
  for update;
  if not found then
    perform public.arena_fail('AR003', 'match not found');
  end if;
  if v_match.status in ('finished', 'no_result') then
    select r.id into v_receipt_id
    from public.arena_receipts r
    where r.match_id = p_match_id;
    if v_receipt_id is null then
      perform public.arena_fail('AR025', 'closed match has no receipt');
    end if;
    return v_receipt_id;
  end if;

  select * into v_p1
  from public.arena_match_players
  where match_id = p_match_id and slot = 1
  for update;
  select * into v_p2
  from public.arena_match_players
  where match_id = p_match_id and slot = 2
  for update;
  if v_p1.user_id is null or v_p2.user_id is null then
    perform public.arena_fail('AR025', 'match is missing a player');
  end if;

  if p_outcome is null then
    if v_p1.score > v_p2.score then
      v_outcome := 'win';
      v_winner := v_p1.user_id;
    elsif v_p2.score > v_p1.score then
      v_outcome := 'win';
      v_winner := v_p2.user_id;
    else
      v_outcome := 'draw';
      v_winner := null;
    end if;
  else
    v_outcome := p_outcome;
    v_winner := p_winner;
    if v_outcome = 'win'
       and v_winner is distinct from v_p1.user_id
       and v_winner is distinct from v_p2.user_id then
      perform public.arena_fail('AR025', 'winner is not a match player');
    end if;
    if v_outcome <> 'win' then
      v_winner := null;
    end if;
  end if;

  v_change1 := null;
  v_change2 := null;
  v_after1 := null;
  v_after2 := null;

  if v_match.mode = 'ranked' and v_outcome <> 'no_result' then
    select rating into v_rating1
    from public.arena_profiles where user_id = v_p1.user_id for update;
    select rating into v_rating2
    from public.arena_profiles where user_id = v_p2.user_id for update;
    if v_rating1 is null or v_rating2 is null then
      perform public.arena_fail('AR025', 'ranked player profile is missing');
    end if;
    if v_outcome = 'win' then
      v_score1 := case when v_winner = v_p1.user_id then 1.0 else 0.0 end;
    else
      v_score1 := 0.5;
    end if;
    v_score2 := 1.0 - v_score1;
    v_change1 := round(
      32.0 * (
        v_score1
        - 1.0 / (1.0 + power(10.0, (v_rating2 - v_rating1) / 400.0))
      )
    )::integer;
    v_change2 := round(
      32.0 * (
        v_score2
        - 1.0 / (1.0 + power(10.0, (v_rating1 - v_rating2) / 400.0))
      )
    )::integer;
    v_after1 := v_rating1 + v_change1;
    v_after2 := v_rating2 + v_change2;

    update public.arena_profiles
    set rating = v_after1,
        ranked_battles = ranked_battles + 1,
        ranked_wins = ranked_wins
          + case when v_outcome = 'win' and v_winner = v_p1.user_id then 1 else 0 end
    where user_id = v_p1.user_id;

    update public.arena_profiles
    set rating = v_after2,
        ranked_battles = ranked_battles + 1,
        ranked_wins = ranked_wins
          + case when v_outcome = 'win' and v_winner = v_p2.user_id then 1 else 0 end
    where user_id = v_p2.user_id;

    insert into public.arena_rating_history (
      match_id, user_id, rating_before, rating_after, rating_change
    )
    values
      (p_match_id, v_p1.user_id, v_rating1, v_after1, v_change1),
      (p_match_id, v_p2.user_id, v_rating2, v_after2, v_change2);
  end if;

  select pr.username, pr.avatar_url
    into v_username1, v_avatar1
  from public.arena_profiles pr where pr.user_id = v_p1.user_id;
  select pr.username, pr.avatar_url
    into v_username2, v_avatar2
  from public.arena_profiles pr where pr.user_id = v_p2.user_id;

  v_players := jsonb_build_array(
    jsonb_build_object(
      'id', v_p1.user_id,
      'username', coalesce(v_username1, v_p1.username_snapshot),
      'avatar_url', coalesce(v_avatar1, v_p1.avatar_url_snapshot),
      'score', v_p1.score,
      'rating_after', v_after1,
      'rating_change', v_change1
    ),
    jsonb_build_object(
      'id', v_p2.user_id,
      'username', coalesce(v_username2, v_p2.username_snapshot),
      'avatar_url', coalesce(v_avatar2, v_p2.avatar_url_snapshot),
      'score', v_p2.score,
      'rating_after', v_after2,
      'rating_change', v_change2
    )
  );

  insert into public.arena_receipts (
    match_id, exercise, mode, outcome, winner_id, players, finished_at, reason
  )
  values (
    p_match_id, v_match.exercise, v_match.mode, v_outcome, v_winner,
    v_players, now(), p_reason
  )
  on conflict (match_id) do nothing
  returning id into v_receipt_id;

  if v_receipt_id is null then
    select r.id into v_receipt_id
    from public.arena_receipts r
    where r.match_id = p_match_id;
    return v_receipt_id;
  end if;

  update public.arena_matches
  set status = case
        when v_outcome = 'no_result' then 'no_result'::public.arena_match_status
        else 'finished'::public.arena_match_status
      end,
      finished_at = now(),
      closed_reason = p_reason
  where id = p_match_id;

  update public.arena_match_players
  set is_active = false
  where match_id = p_match_id;

  perform public.arena_notify(
    v_p1.user_id, 'match_finished',
    jsonb_build_object('match_id', v_match.id, 'receipt_id', v_receipt_id)
  );
  perform public.arena_notify(
    v_p2.user_id, 'match_finished',
    jsonb_build_object('match_id', v_match.id, 'receipt_id', v_receipt_id)
  );

  return v_receipt_id;
end;
$$;

create or replace function public.arena_match_tick(p_match_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_match public.arena_matches;
  v_left integer;
  v_stale integer;
  v_winner uuid;
begin
  select * into v_match
  from public.arena_matches
  where id = p_match_id
  for update;
  if not found then
    perform public.arena_fail('AR003', 'match not found');
  end if;
  if v_match.status in ('finished', 'no_result') then
    return;
  end if;

  if v_match.status = 'preparing' then
    if clock_timestamp() >= v_match.prep_expires_at then
      perform public.arena_close_match(p_match_id, 'prep_timeout', 'no_result', null);
    end if;
    return;
  end if;

  if v_match.status = 'countdown' then
    if clock_timestamp() < v_match.starts_at then
      return;
    end if;
    update public.arena_matches
    set status = 'live', live_started_at = v_match.starts_at
    where id = p_match_id;
    v_match.status := 'live';
  end if;

  select
    count(*) filter (where mp.left_at is not null),
    count(*) filter (
      where mp.left_at is null
        and clock_timestamp() - mp.last_seen_at > interval '10 seconds'
    )
  into v_left, v_stale
  from public.arena_match_players mp
  where mp.match_id = p_match_id;

  if v_left = 1 then
    select mp.user_id into v_winner
    from public.arena_match_players mp
    where mp.match_id = p_match_id and mp.left_at is null;
    perform public.arena_close_match(p_match_id, 'opponent_left', 'win', v_winner);
    return;
  end if;

  if clock_timestamp() >= v_match.ends_at then
    if v_stale = 2 then
      perform public.arena_close_match(p_match_id, 'service_outage', 'no_result', null);
    elsif v_stale = 1 then
      select mp.user_id into v_winner
      from public.arena_match_players mp
      where mp.match_id = p_match_id
        and mp.left_at is null
        and clock_timestamp() - mp.last_seen_at <= interval '10 seconds';
      perform public.arena_close_match(p_match_id, 'opponent_absent', 'win', v_winner);
    else
      perform public.arena_close_match(p_match_id, 'round_complete', null, null);
    end if;
    return;
  end if;

  if v_stale = 2 then
    perform public.arena_close_match(p_match_id, 'service_outage', 'no_result', null);
  elsif v_stale = 1 then
    select mp.user_id into v_winner
    from public.arena_match_players mp
    where mp.match_id = p_match_id
      and mp.left_at is null
      and clock_timestamp() - mp.last_seen_at <= interval '10 seconds';
    perform public.arena_close_match(p_match_id, 'opponent_absent', 'win', v_winner);
  end if;
end;
$$;

-- Recomputes readiness for both players and starts/cancels the countdown.
-- Callers must already hold the match row lock (via arena_match_tick).
create or replace function public.arena_after_player_update(p_match_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_match public.arena_matches;
  v_p1 public.arena_match_players;
  v_p2 public.arena_match_players;
  v_ready1 boolean;
  v_ready2 boolean;
  v_start timestamptz;
begin
  select * into v_match
  from public.arena_matches
  where id = p_match_id
  for update;
  if v_match.status not in ('preparing', 'countdown') then
    return;
  end if;

  select * into v_p1
  from public.arena_match_players
  where match_id = p_match_id and slot = 1;
  select * into v_p2
  from public.arena_match_players
  where match_id = p_match_id and slot = 2;

  update public.arena_match_players
  set ready = practice_complete and tracking
  where match_id = p_match_id;

  v_ready1 := v_p1.practice_complete and v_p1.tracking;
  v_ready2 := v_p2.practice_complete and v_p2.tracking;

  if v_match.status = 'countdown' and not (v_ready1 and v_ready2) then
    update public.arena_matches
    set status = 'preparing',
        countdown_started_at = null,
        starts_at = null,
        ends_at = null
    where id = p_match_id;
    return;
  end if;

  if v_match.status = 'preparing' and v_ready1 and v_ready2 then
    v_start := clock_timestamp() + interval '5 seconds';
    update public.arena_matches
    set status = 'countdown',
        countdown_started_at = clock_timestamp(),
        starts_at = v_start,
        ends_at = v_start + interval '60 seconds'
    where id = p_match_id;
    perform public.arena_notify(
      v_p1.user_id, 'match_ready', jsonb_build_object('match_id', p_match_id)
    );
    perform public.arena_notify(
      v_p2.user_id, 'match_ready', jsonb_build_object('match_id', p_match_id)
    );
  end if;
end;
$$;

-- ----------------------------------------------------------------------------
-- Ranked queue. One active seat per user; matching excludes blocked pairs and
-- anyone already in an active match. `skip locked` avoids cross-wait deadlocks
-- between two simultaneous pollers.
-- ----------------------------------------------------------------------------
create or replace function public.arena_queue_try_match(p_user_id uuid)
returns uuid
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_seat public.arena_queue;
  v_other public.arena_queue;
  v_match_id uuid;
  v_exercise public.arena_exercise;
  v_slot_self smallint;
  v_slot_other smallint;
  v_profile_self public.arena_profiles;
  v_profile_other public.arena_profiles;
begin
  select * into v_seat
  from public.arena_queue
  where user_id = p_user_id and status = 'queued'
  for update;
  if not found then
    return null;
  end if;
  if v_seat.expires_at <= now() then
    update public.arena_queue
    set status = 'expired'
    where id = v_seat.id;
    return null;
  end if;

  select q.* into v_other
  from public.arena_queue q
  where q.status = 'queued'
    and q.user_id <> p_user_id
    and q.expires_at > now()
    and not exists (
      select 1 from public.arena_blocks b
      where (b.blocker_id = p_user_id and b.blocked_id = q.user_id)
         or (b.blocker_id = q.user_id and b.blocked_id = p_user_id)
    )
    and not exists (
      select 1 from public.arena_match_players mp
      where mp.user_id in (p_user_id, q.user_id) and mp.is_active
    )
  order by q.created_at asc
  limit 1
  for update skip locked;

  if not found then
    return null;
  end if;

  v_exercise := case when random() < 0.5 then 'pushups'::public.arena_exercise
                     else 'squats'::public.arena_exercise end;

  insert into public.arena_matches (
    mode, exercise, status, origin, prep_expires_at
  )
  values (
    'ranked', v_exercise, 'preparing', 'ranked_queue',
    now() + interval '10 minutes'
  )
  returning id into v_match_id;

  if v_other.created_at <= v_seat.created_at then
    v_slot_other := 1;
    v_slot_self := 2;
  else
    v_slot_other := 2;
    v_slot_self := 1;
  end if;

  select * into v_profile_self from public.arena_profiles where user_id = p_user_id;
  select * into v_profile_other from public.arena_profiles where user_id = v_other.user_id;

  begin
    insert into public.arena_match_players (
      match_id, user_id, slot, username_snapshot, avatar_url_snapshot,
      rating_before
    )
    values
      (v_match_id, v_other.user_id, v_slot_other,
       v_profile_other.username, v_profile_other.avatar_url, v_profile_other.rating),
      (v_match_id, p_user_id, v_slot_self,
       v_profile_self.username, v_profile_self.avatar_url, v_profile_self.rating);
  exception when unique_violation then
    perform public.arena_fail('AR011', 'a player already has an active match');
  end;

  update public.arena_queue
  set status = 'matched', matched_at = now(), match_id = v_match_id
  where id in (v_seat.id, v_other.id);

  perform public.arena_notify(
    p_user_id, 'match_ready', jsonb_build_object('match_id', v_match_id)
  );
  perform public.arena_notify(
    v_other.user_id, 'match_ready', jsonb_build_object('match_id', v_match_id)
  );

  return v_match_id;
end;
$$;

-- ----------------------------------------------------------------------------
-- Actions: profile, avatar and link
-- ----------------------------------------------------------------------------
create or replace function public.arena_get_profile(p_actor uuid, p_session uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor public.arena_profiles;
begin
  v_actor := public.arena_assert_actor(p_actor, p_session);
  return jsonb_build_object(
    'profile', public.arena_profile_json(p_actor),
    'link', public.arena_link_json(p_actor),
    'active_match_id', public.arena_active_match_id(p_actor)
  );
end;
$$;

create or replace function public.arena_update_profile(
  p_actor uuid,
  p_session uuid,
  p_username text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor public.arena_profiles;
  v_username text;
begin
  v_actor := public.arena_assert_actor(p_actor, p_session);
  v_username := btrim(coalesce(p_username, ''));
  if v_username = '' then
    perform public.arena_fail('AR005', 'username is required');
  end if;
  if char_length(v_username) not between 3 and 20 then
    perform public.arena_fail('AR005', 'username must be 3-20 characters');
  end if;
  if v_username !~ '^[A-Za-z0-9_]{3,20}$' then
    perform public.arena_fail('AR005', 'username may only contain letters, digits and underscore');
  end if;
  if lower(v_username) in (
    'arena', 'admin', 'administrator', 'support', 'moderator',
    'trainingarena', 'system', 'official', 'mod', 'staff'
  ) then
    perform public.arena_fail('AR005', 'username is reserved');
  end if;
  if exists (
    select 1 from public.arena_profiles
    where username_normalized = lower(v_username)
      and user_id <> p_actor
  ) then
    perform public.arena_fail('AR004', 'username is already taken');
  end if;
  begin
    update public.arena_profiles
    set username = v_username
    where user_id = p_actor;
  exception when unique_violation then
    perform public.arena_fail('AR004', 'username is already taken');
  end;
  return jsonb_build_object('profile', public.arena_profile_json(p_actor));
end;
$$;

create or replace function public.arena_set_avatar(
  p_actor uuid,
  p_session uuid,
  p_avatar_url text,
  p_avatar_path text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor public.arena_profiles;
  v_previous text;
begin
  v_actor := public.arena_assert_actor(p_actor, p_session);
  if p_avatar_url is null or p_avatar_url !~ '^https://' then
    perform public.arena_fail('AR018', 'avatar url must be https');
  end if;
  if p_avatar_path is null
     or p_avatar_path not like 'avatars/' || p_actor::text || '/%'
     or p_avatar_path like '%..%' then
    perform public.arena_fail('AR018', 'avatar path is not owned by the actor');
  end if;
  select avatar_path into v_previous
  from public.arena_profiles where user_id = p_actor;
  update public.arena_profiles
  set avatar_url = p_avatar_url, avatar_path = p_avatar_path
  where user_id = p_actor;
  return jsonb_build_object(
    'profile', public.arena_profile_json(p_actor),
    'previous_avatar_path', v_previous
  );
end;
$$;

create or replace function public.arena_clear_avatar(p_actor uuid, p_session uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor public.arena_profiles;
  v_previous text;
begin
  v_actor := public.arena_assert_actor(p_actor, p_session);
  select avatar_path into v_previous
  from public.arena_profiles where user_id = p_actor;
  update public.arena_profiles
  set avatar_url = null, avatar_path = null
  where user_id = p_actor;
  return jsonb_build_object(
    'profile', public.arena_profile_json(p_actor),
    'previous_avatar_path', v_previous
  );
end;
$$;

create or replace function public.arena_rotate_link(p_actor uuid, p_session uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor public.arena_profiles;
  v_token text;
  v_inserted boolean := false;
  i integer;
begin
  v_actor := public.arena_assert_actor(p_actor, p_session);
  update public.arena_links
  set revoked_at = now()
  where user_id = p_actor and revoked_at is null;
  for i in 1..10 loop
    v_token := public.arena_new_token();
    begin
      insert into public.arena_links (token, user_id)
      values (v_token, p_actor);
      v_inserted := true;
      exit;
    exception when unique_violation then
      v_inserted := false;
    end;
  end loop;
  if not v_inserted then
    perform public.arena_fail('AR024', 'could not allocate a challenge token');
  end if;
  return jsonb_build_object('link', public.arena_link_json(p_actor));
end;
$$;

create or replace function public.arena_resolve_link(p_token text)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_token text;
  v_owner uuid;
begin
  v_token := lower(btrim(coalesce(p_token, '')));
  if v_token !~ '^[a-z0-9]{12}$' then
    return jsonb_build_object('owner', null, 'available', false);
  end if;
  select l.user_id into v_owner
  from public.arena_links l
  where l.token = v_token and l.revoked_at is null;
  if not found then
    return jsonb_build_object('owner', null, 'available', false);
  end if;
  if not exists (
    select 1 from public.arena_profiles pr
    where pr.user_id = v_owner and pr.deleted_at is null
  ) then
    return jsonb_build_object('owner', null, 'available', false);
  end if;
  return jsonb_build_object(
    'owner', public.arena_profile_json(v_owner),
    'available', true
  );
end;
$$;

-- ----------------------------------------------------------------------------
-- Actions: inbox and requests
-- ----------------------------------------------------------------------------
create or replace function public.arena_inbox(p_actor uuid, p_session uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor public.arena_profiles;
begin
  v_actor := public.arena_assert_actor(p_actor, p_session);
  perform public.arena_expire_requests_for(p_actor);
  return jsonb_build_object(
    'requests', coalesce((
      select jsonb_agg(public.arena_request_json(r.id) order by r.created_at desc)
      from public.arena_requests r
      where (r.sender_id = p_actor or r.recipient_id = p_actor)
        and r.created_at > now() - interval '7 days'
    ), '[]'::jsonb),
    'active_match_id', public.arena_active_match_id(p_actor),
    'link', public.arena_link_json(p_actor)
  );
end;
$$;

create or replace function public.arena_request_send(
  p_actor uuid,
  p_session uuid,
  p_token text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor public.arena_profiles;
  v_token text;
  v_owner uuid;
  v_request_id uuid;
begin
  v_actor := public.arena_assert_actor(p_actor, p_session);
  if v_actor.username is null then
    perform public.arena_fail('AR020', 'choose a username before challenging');
  end if;
  if public.arena_active_match_id(p_actor) is not null then
    perform public.arena_fail('AR011', 'finish the current match first');
  end if;

  v_token := lower(btrim(coalesce(p_token, '')));
  if v_token !~ '^[a-z0-9]{12}$' then
    perform public.arena_fail('AR006', 'challenge link is not available');
  end if;
  select l.user_id into v_owner
  from public.arena_links l
  where l.token = v_token and l.revoked_at is null;
  if not found then
    perform public.arena_fail('AR006', 'challenge link is not available');
  end if;
  if not exists (
    select 1 from public.arena_profiles pr
    where pr.user_id = v_owner and pr.deleted_at is null
  ) then
    perform public.arena_fail('AR006', 'challenge link is not available');
  end if;
  if v_owner = p_actor then
    perform public.arena_fail('AR001', 'a player cannot challenge themselves');
  end if;
  if public.arena_are_blocked(p_actor, v_owner) then
    perform public.arena_fail('AR010', 'challenge is not available');
  end if;
  if exists (
    select 1 from public.arena_requests r
    where r.sender_id = p_actor
      and r.recipient_id = v_owner
      and r.status = 'pending'
  ) then
    perform public.arena_fail('AR009', 'a request to this player is already pending');
  end if;

  update public.arena_queue
  set status = 'cancelled'
  where user_id = p_actor and status = 'queued';

  insert into public.arena_requests (link_token, sender_id, recipient_id)
  values (v_token, p_actor, v_owner)
  returning id into v_request_id;

  perform public.arena_notify(
    v_owner, 'challenge_request',
    jsonb_build_object(
      'request_id', v_request_id,
      'sender_id', p_actor,
      'sender_username', v_actor.username
    )
  );

  return jsonb_build_object('request', public.arena_request_json(v_request_id));
end;
$$;

create or replace function public.arena_request_accept(
  p_actor uuid,
  p_session uuid,
  p_request_id uuid
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor public.arena_profiles;
  v_request public.arena_requests;
  v_sender public.arena_profiles;
  v_exercise public.arena_exercise;
  v_match_id uuid;
begin
  v_actor := public.arena_assert_actor(p_actor, p_session);
  if p_request_id is null then
    perform public.arena_fail('AR001', 'request id is required');
  end if;

  select * into v_request
  from public.arena_requests
  where id = p_request_id
  for update;
  if not found or v_request.recipient_id <> p_actor then
    perform public.arena_fail('AR003', 'request not found');
  end if;
  if v_request.status <> 'pending' then
    perform public.arena_fail('AR007', 'request is already ' || v_request.status::text);
  end if;
  -- An expired request is refused here; the persistent `expired` status is
  -- applied lazily by arena_inbox/arena_maintenance (a RAISE would roll back
  -- any write made in this transaction).
  if v_request.expires_at <= now() then
    perform public.arena_fail('AR008', 'request has expired');
  end if;
  if public.arena_active_match_id(p_actor) is not null
     or public.arena_active_match_id(v_request.sender_id) is not null then
    perform public.arena_fail('AR011', 'one of the players already has an active match');
  end if;

  select * into v_sender
  from public.arena_profiles
  where user_id = v_request.sender_id;
  if v_sender.user_id is null or v_sender.deleted_at is not null then
    update public.arena_requests
    set status = 'cancelled', responded_at = now()
    where id = v_request.id;
    perform public.arena_fail('AR006', 'challenger is no longer available');
  end if;

  -- Accepting a battle removes both players from the ranked queue so nobody
  -- can be paired into a second active match.
  update public.arena_queue
  set status = 'cancelled'
  where user_id in (p_actor, v_request.sender_id) and status = 'queued';

  v_exercise := case when random() < 0.5 then 'pushups'::public.arena_exercise
                     else 'squats'::public.arena_exercise end;

  insert into public.arena_matches (
    mode, exercise, status, origin, request_id, prep_expires_at
  )
  values (
    'casual', v_exercise, 'preparing', 'request', v_request.id,
    now() + interval '10 minutes'
  )
  returning id into v_match_id;

  begin
    insert into public.arena_match_players (
      match_id, user_id, slot, username_snapshot, avatar_url_snapshot,
      rating_before
    )
    values
      (v_match_id, v_request.sender_id, 1,
       v_sender.username, v_sender.avatar_url, v_sender.rating),
      (v_match_id, p_actor, 2,
       v_actor.username, v_actor.avatar_url, v_actor.rating);
  exception when unique_violation then
    perform public.arena_fail('AR011', 'a player already has an active match');
  end;

  update public.arena_requests
  set status = 'accepted', responded_at = now(), match_id = v_match_id
  where id = v_request.id;

  perform public.arena_notify(
    v_request.sender_id, 'request_accepted',
    jsonb_build_object('request_id', v_request.id, 'match_id', v_match_id)
  );

  return jsonb_build_object('match', public.arena_match_view(v_match_id));
end;
$$;

create or replace function public.arena_request_respond(
  p_actor uuid,
  p_session uuid,
  p_request_id uuid,
  p_response text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor public.arena_profiles;
  v_request public.arena_requests;
  v_response text;
  v_status public.arena_request_status;
  v_notify_user uuid;
begin
  v_actor := public.arena_assert_actor(p_actor, p_session);
  v_response := lower(btrim(coalesce(p_response, '')));
  if v_response not in ('decline', 'cancel') then
    perform public.arena_fail('AR001', 'response must be decline or cancel');
  end if;
  if p_request_id is null then
    perform public.arena_fail('AR001', 'request id is required');
  end if;

  select * into v_request
  from public.arena_requests
  where id = p_request_id
  for update;
  if not found then
    perform public.arena_fail('AR003', 'request not found');
  end if;
  if v_response = 'decline' and v_request.recipient_id <> p_actor then
    perform public.arena_fail('AR003', 'request not found');
  end if;
  if v_response = 'cancel' and v_request.sender_id <> p_actor then
    perform public.arena_fail('AR003', 'request not found');
  end if;
  if v_request.status <> 'pending' then
    perform public.arena_fail('AR007', 'request is already ' || v_request.status::text);
  end if;
  if v_request.expires_at <= now() then
    perform public.arena_fail('AR008', 'request has expired');
  end if;

  if v_response = 'decline' then
    v_status := 'declined';
    v_notify_user := v_request.sender_id;
  else
    v_status := 'cancelled';
    v_notify_user := v_request.recipient_id;
  end if;

  update public.arena_requests
  set status = v_status, responded_at = now()
  where id = v_request.id;

  perform public.arena_notify(
    v_notify_user, 'request_declined',
    jsonb_build_object('request_id', v_request.id, 'status', v_status)
  );

  return jsonb_build_object('request', public.arena_request_json(v_request.id));
end;
$$;

-- ----------------------------------------------------------------------------
-- Actions: ranked queue
-- ----------------------------------------------------------------------------
create or replace function public.arena_queue_join(p_actor uuid, p_session uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor public.arena_profiles;
  v_match_id uuid;
  v_seat public.arena_queue;
begin
  v_actor := public.arena_assert_actor(p_actor, p_session);
  if v_actor.username is null then
    perform public.arena_fail('AR020', 'choose a username before ranked play');
  end if;

  update public.arena_queue
  set status = 'expired'
  where user_id = p_actor and status = 'queued' and expires_at <= now();

  v_match_id := public.arena_active_match_id(p_actor);
  if v_match_id is not null then
    return jsonb_build_object(
      'match', public.arena_match_view(v_match_id),
      'queued', false,
      'queued_since', null,
      'expires_at', null
    );
  end if;

  select * into v_seat
  from public.arena_queue
  where user_id = p_actor and status = 'queued'
  for update;
  if not found then
    insert into public.arena_queue (user_id)
    values (p_actor)
    returning * into v_seat;
  end if;

  v_match_id := public.arena_queue_try_match(p_actor);
  if v_match_id is not null then
    return jsonb_build_object(
      'match', public.arena_match_view(v_match_id),
      'queued', false,
      'queued_since', null,
      'expires_at', null
    );
  end if;

  select * into v_seat
  from public.arena_queue
  where id = v_seat.id;
  return jsonb_build_object(
    'match', null,
    'queued', v_seat.status = 'queued',
    'queued_since', v_seat.created_at,
    'expires_at', v_seat.expires_at
  );
end;
$$;

create or replace function public.arena_queue_poll(p_actor uuid, p_session uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor public.arena_profiles;
  v_match_id uuid;
  v_seat public.arena_queue;
begin
  v_actor := public.arena_assert_actor(p_actor, p_session);

  update public.arena_queue
  set status = 'expired'
  where user_id = p_actor and status = 'queued' and expires_at <= now();

  v_match_id := public.arena_active_match_id(p_actor);
  if v_match_id is not null then
    return jsonb_build_object(
      'match', public.arena_match_view(v_match_id),
      'queued', false,
      'queued_since', null,
      'expires_at', null
    );
  end if;

  select * into v_seat
  from public.arena_queue
  where user_id = p_actor and status = 'queued'
  for update;
  if not found then
    return jsonb_build_object(
      'match', null, 'queued', false, 'queued_since', null, 'expires_at', null
    );
  end if;

  v_match_id := public.arena_queue_try_match(p_actor);
  if v_match_id is not null then
    return jsonb_build_object(
      'match', public.arena_match_view(v_match_id),
      'queued', false,
      'queued_since', null,
      'expires_at', null
    );
  end if;

  select * into v_seat from public.arena_queue where id = v_seat.id;
  return jsonb_build_object(
    'match', null,
    'queued', v_seat.status = 'queued',
    'queued_since', v_seat.created_at,
    'expires_at', v_seat.expires_at
  );
end;
$$;

create or replace function public.arena_queue_leave(p_actor uuid, p_session uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor public.arena_profiles;
begin
  v_actor := public.arena_assert_actor(p_actor, p_session);
  update public.arena_queue
  set status = 'cancelled'
  where user_id = p_actor and status = 'queued';
  return jsonb_build_object('ok', true);
end;
$$;

-- ----------------------------------------------------------------------------
-- Actions: match lifecycle
-- ----------------------------------------------------------------------------
create or replace function public.arena_match_state(
  p_actor uuid,
  p_session uuid,
  p_match_id uuid
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor public.arena_profiles;
begin
  v_actor := public.arena_assert_actor(p_actor, p_session);
  if p_match_id is null or not exists (
    select 1 from public.arena_match_players mp
    where mp.match_id = p_match_id and mp.user_id = p_actor
  ) then
    perform public.arena_fail('AR003', 'match not found');
  end if;
  perform public.arena_match_tick(p_match_id);
  return jsonb_build_object('match', public.arena_match_view(p_match_id));
end;
$$;

create or replace function public.arena_match_ready(
  p_actor uuid,
  p_session uuid,
  p_match_id uuid,
  p_tracking boolean,
  p_practice_complete boolean
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor public.arena_profiles;
  v_match public.arena_matches;
  v_player public.arena_match_players;
begin
  v_actor := public.arena_assert_actor(p_actor, p_session);
  if p_match_id is null or not exists (
    select 1 from public.arena_match_players mp
    where mp.match_id = p_match_id and mp.user_id = p_actor
  ) then
    perform public.arena_fail('AR003', 'match not found');
  end if;
  perform public.arena_match_tick(p_match_id);
  select * into v_match from public.arena_matches where id = p_match_id;
  if v_match.status in ('finished', 'no_result') then
    return jsonb_build_object('match', public.arena_match_view(p_match_id));
  end if;

  select * into v_player
  from public.arena_match_players
  where match_id = p_match_id and user_id = p_actor
  for update;
  if v_player.left_at is not null then
    perform public.arena_fail('AR013', 'player has left the match');
  end if;

  if v_match.status = 'live' then
    update public.arena_match_players
    set         last_seen_at = clock_timestamp(),
        tracking = coalesce(p_tracking, false),
        last_tracking_at = case when coalesce(p_tracking, false) then clock_timestamp() else last_tracking_at end,
        practice_complete = practice_complete or coalesce(p_practice_complete, false)
    where match_id = p_match_id and user_id = p_actor;
  else
    update public.arena_match_players
    set         last_seen_at = clock_timestamp(),
        tracking = coalesce(p_tracking, false),
        last_tracking_at = case when coalesce(p_tracking, false) then clock_timestamp() else last_tracking_at end,
        practice_complete = case
          when v_match.status = 'preparing' then coalesce(p_practice_complete, false)
          else practice_complete or coalesce(p_practice_complete, false)
        end
    where match_id = p_match_id and user_id = p_actor;
    perform public.arena_after_player_update(p_match_id);
  end if;

  return jsonb_build_object('match', public.arena_match_view(p_match_id));
end;
$$;

create or replace function public.arena_match_heartbeat(
  p_actor uuid,
  p_session uuid,
  p_match_id uuid,
  p_tracking boolean
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor public.arena_profiles;
  v_match public.arena_matches;
  v_player public.arena_match_players;
begin
  v_actor := public.arena_assert_actor(p_actor, p_session);
  if p_match_id is null or not exists (
    select 1 from public.arena_match_players mp
    where mp.match_id = p_match_id and mp.user_id = p_actor
  ) then
    perform public.arena_fail('AR003', 'match not found');
  end if;
  perform public.arena_match_tick(p_match_id);
  select * into v_match from public.arena_matches where id = p_match_id;
  if v_match.status in ('finished', 'no_result') then
    return jsonb_build_object('match', public.arena_match_view(p_match_id));
  end if;

  select * into v_player
  from public.arena_match_players
  where match_id = p_match_id and user_id = p_actor
  for update;
  if v_player.left_at is null then
    update public.arena_match_players
    set last_seen_at = clock_timestamp(),
        tracking = coalesce(p_tracking, false),
        last_tracking_at = case when coalesce(p_tracking, false) then clock_timestamp() else last_tracking_at end
    where match_id = p_match_id and user_id = p_actor;
    perform public.arena_after_player_update(p_match_id);
  end if;

  return jsonb_build_object('match', public.arena_match_view(p_match_id));
end;
$$;

create or replace function public.arena_match_rep(
  p_actor uuid,
  p_session uuid,
  p_match_id uuid,
  p_event_id uuid,
  p_sequence bigint,
  p_observed_at timestamptz,
  p_counter_version text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor public.arena_profiles;
  v_match public.arena_matches;
  v_player public.arena_match_players;
  v_version text;
begin
  v_actor := public.arena_assert_actor(p_actor, p_session);
  if p_event_id is null then
    perform public.arena_fail('AR001', 'event_id is required');
  end if;
  if p_sequence is null or p_sequence <= 0 then
    perform public.arena_fail('AR001', 'sequence must be a positive integer');
  end if;
  if p_observed_at is null then
    perform public.arena_fail('AR001', 'observed_at is required');
  end if;
  v_version := btrim(coalesce(p_counter_version, ''));
  if v_version = '' or char_length(v_version) > 32 then
    perform public.arena_fail('AR001', 'counter_version must be 1-32 characters');
  end if;

  if p_match_id is null or not exists (
    select 1 from public.arena_match_players mp
    where mp.match_id = p_match_id and mp.user_id = p_actor
  ) then
    perform public.arena_fail('AR003', 'match not found');
  end if;

  perform public.arena_match_tick(p_match_id);
  select * into v_match from public.arena_matches where id = p_match_id;

  if exists (
    select 1 from public.arena_match_events e
    where e.match_id = p_match_id and e.event_id = p_event_id
  ) then
    return jsonb_build_object('match', public.arena_match_view(p_match_id));
  end if;

  if v_match.status in ('finished', 'no_result') then
    perform public.arena_fail('AR014', 'match is no longer live');
  end if;
  if v_match.status <> 'live' then
    perform public.arena_fail('AR014', 'match is not live');
  end if;

  select * into v_player
  from public.arena_match_players
  where match_id = p_match_id and user_id = p_actor
  for update;
  if v_player.left_at is not null then
    perform public.arena_fail('AR014', 'player has left the match');
  end if;
  if not v_player.tracking
     or v_player.last_tracking_at is null
     or clock_timestamp() - v_player.last_tracking_at > interval '5 seconds' then
    perform public.arena_fail('AR016', 'camera tracking is not fresh');
  end if;
  if p_observed_at > clock_timestamp() + interval '2 seconds'
     or p_observed_at < v_match.starts_at - interval '2 seconds' then
    perform public.arena_fail('AR015', 'rep was observed outside the round window');
  end if;
  if p_sequence <= v_player.last_sequence then
    perform public.arena_fail('AR015', 'rep sequence is not increasing');
  end if;
  if v_player.score >= 240 then
    perform public.arena_fail('AR017', 'rep rate exceeds the round limit');
  end if;
  if exists (
    select 1 from public.arena_match_events e
    where e.match_id = p_match_id
      and e.user_id = p_actor
      and e.received_at > clock_timestamp() - interval '150 milliseconds'
  ) then
    perform public.arena_fail('AR017', 'rep rate is too high');
  end if;

  begin
    insert into public.arena_match_events (
      match_id, user_id, event_id, sequence, observed_at, counter_version
    )
    values (
      p_match_id, p_actor, p_event_id, p_sequence, p_observed_at, v_version
    );
  exception when unique_violation then
    return jsonb_build_object('match', public.arena_match_view(p_match_id));
  end;

  update public.arena_match_players
  set score = score + 1,
      last_sequence = p_sequence,
      last_seen_at = clock_timestamp()
  where match_id = p_match_id and user_id = p_actor;

  return jsonb_build_object('match', public.arena_match_view(p_match_id));
end;
$$;

create or replace function public.arena_match_leave(
  p_actor uuid,
  p_session uuid,
  p_match_id uuid
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor public.arena_profiles;
  v_match public.arena_matches;
  v_other uuid;
begin
  v_actor := public.arena_assert_actor(p_actor, p_session);
  if p_match_id is null or not exists (
    select 1 from public.arena_match_players mp
    where mp.match_id = p_match_id and mp.user_id = p_actor
  ) then
    perform public.arena_fail('AR003', 'match not found');
  end if;
  perform public.arena_match_tick(p_match_id);
  select * into v_match from public.arena_matches where id = p_match_id;
  if v_match.status in ('finished', 'no_result') then
    return jsonb_build_object('match', public.arena_match_view(p_match_id));
  end if;

  update public.arena_match_players
  set left_at = coalesce(left_at, now())
  where match_id = p_match_id and user_id = p_actor;

  if v_match.status = 'preparing' then
    perform public.arena_close_match(p_match_id, 'abandoned_preparing', 'no_result', null);
  else
    select mp.user_id into v_other
    from public.arena_match_players mp
    where mp.match_id = p_match_id and mp.user_id <> p_actor
    order by mp.slot
    limit 1;
    perform public.arena_close_match(p_match_id, 'opponent_left', 'win', v_other);
  end if;

  return jsonb_build_object('match', public.arena_match_view(p_match_id));
end;
$$;

-- ----------------------------------------------------------------------------
-- Actions: leaderboard, history, public profile
-- ----------------------------------------------------------------------------
create or replace function public.arena_leaderboard(p_actor uuid, p_session uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor public.arena_profiles;
begin
  v_actor := public.arena_assert_actor(p_actor, p_session);
  return jsonb_build_object(
    'profiles', coalesce((
      select jsonb_agg(row_json order by rnk asc)
      from (
        select
          row.rnk,
          jsonb_build_object(
            'id', row.user_id,
            'username', row.username,
            'avatar_url', row.avatar_url,
            'rating', row.rating,
            'ranked_wins', row.ranked_wins,
            'ranked_battles', row.ranked_battles,
            'rank', row.rnk
          ) as row_json
        from (
          select
            pr.user_id,
            pr.username,
            pr.avatar_url,
            pr.rating,
            pr.ranked_wins,
            pr.ranked_battles,
            rank() over (
              order by pr.rating desc, pr.ranked_wins desc, pr.created_at asc
            ) as rnk
          from public.arena_profiles pr
          where pr.username is not null and pr.deleted_at is null
        ) row
        where row.rnk <= 100 or row.user_id = p_actor
      ) ranked_rows
    ), '[]'::jsonb)
  );
end;
$$;

create or replace function public.arena_history(p_actor uuid, p_session uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor public.arena_profiles;
begin
  v_actor := public.arena_assert_actor(p_actor, p_session);
  return jsonb_build_object(
    'receipts', coalesce((
      select jsonb_agg(public.arena_receipt_json(r.id) order by r.finished_at desc)
      from (
        select rc.id, rc.finished_at
        from public.arena_receipts rc
        where exists (
          select 1 from jsonb_array_elements(rc.players) as pl
          where pl ->> 'id' = p_actor::text
        )
        order by rc.finished_at desc
        limit 100
      ) r
    ), '[]'::jsonb)
  );
end;
$$;

create or replace function public.arena_public_profile(
  p_actor uuid,
  p_session uuid,
  p_user_id uuid
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor public.arena_profiles;
begin
  v_actor := public.arena_assert_actor(p_actor, p_session);
  if p_user_id is null
     or p_user_id = p_actor
     or public.arena_are_blocked(p_actor, p_user_id)
     or not exists (
       select 1 from public.arena_profiles pr
       where pr.user_id = p_user_id and pr.deleted_at is null
     ) then
    perform public.arena_fail('AR003', 'profile not found');
  end if;
  return jsonb_build_object('profile', public.arena_profile_json(p_user_id));
end;
$$;

-- ----------------------------------------------------------------------------
-- Actions: reports, blocks, devices, analytics
-- ----------------------------------------------------------------------------
create or replace function public.arena_report(
  p_actor uuid,
  p_session uuid,
  p_target_user_id uuid,
  p_match_id uuid,
  p_reason text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor public.arena_profiles;
  v_reason text;
begin
  v_actor := public.arena_assert_actor(p_actor, p_session);
  if p_target_user_id is null or p_target_user_id = p_actor then
    perform public.arena_fail('AR001', 'report target is invalid');
  end if;
  if not exists (
    select 1 from public.arena_profiles pr
    where pr.user_id = p_target_user_id and pr.deleted_at is null
  ) then
    perform public.arena_fail('AR003', 'profile not found');
  end if;
  v_reason := btrim(coalesce(p_reason, ''));
  if char_length(v_reason) not between 3 and 500 then
    perform public.arena_fail('AR001', 'reason must be 3-500 characters');
  end if;
  if p_match_id is not null and not exists (
    select 1 from public.arena_match_players mp
    where mp.match_id = p_match_id and mp.user_id = p_actor
  ) then
    perform public.arena_fail('AR003', 'match not found');
  end if;
  insert into public.arena_reports (reporter_id, target_user_id, match_id, reason)
  values (p_actor, p_target_user_id, p_match_id, v_reason);
  return jsonb_build_object('ok', true);
end;
$$;

create or replace function public.arena_block(
  p_actor uuid,
  p_session uuid,
  p_target_user_id uuid
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor public.arena_profiles;
begin
  v_actor := public.arena_assert_actor(p_actor, p_session);
  if p_target_user_id is null or p_target_user_id = p_actor then
    perform public.arena_fail('AR001', 'block target is invalid');
  end if;
  if not exists (
    select 1 from public.arena_profiles pr
    where pr.user_id = p_target_user_id and pr.deleted_at is null
  ) then
    perform public.arena_fail('AR003', 'profile not found');
  end if;

  insert into public.arena_blocks (blocker_id, blocked_id)
  values (p_actor, p_target_user_id)
  on conflict (blocker_id, blocked_id) do nothing;

  update public.arena_requests
  set status = case
        when sender_id = p_actor then 'cancelled'::public.arena_request_status
        else 'declined'::public.arena_request_status
      end,
      responded_at = now()
  where status = 'pending'
    and (
      (sender_id = p_actor and recipient_id = p_target_user_id)
      or (sender_id = p_target_user_id and recipient_id = p_actor)
    );

  return jsonb_build_object('ok', true);
end;
$$;

create or replace function public.arena_unblock(
  p_actor uuid,
  p_session uuid,
  p_target_user_id uuid
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor public.arena_profiles;
begin
  v_actor := public.arena_assert_actor(p_actor, p_session);
  if p_target_user_id is null or p_target_user_id = p_actor then
    perform public.arena_fail('AR001', 'unblock target is invalid');
  end if;
  delete from public.arena_blocks
  where blocker_id = p_actor and blocked_id = p_target_user_id;
  return jsonb_build_object('ok', true);
end;
$$;

create or replace function public.arena_blocked(p_actor uuid, p_session uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor public.arena_profiles;
begin
  v_actor := public.arena_assert_actor(p_actor, p_session);
  return jsonb_build_object(
    'profiles', coalesce((
      select jsonb_agg(public.arena_profile_json(b.blocked_id) order by b.created_at desc)
      from public.arena_blocks b
      where b.blocker_id = p_actor
    ), '[]'::jsonb)
  );
end;
$$;

create or replace function public.arena_device_register(
  p_actor uuid,
  p_session uuid,
  p_token text,
  p_platform text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor public.arena_profiles;
  v_token text;
  v_platform text;
begin
  v_actor := public.arena_assert_actor(p_actor, p_session);
  v_token := btrim(coalesce(p_token, ''));
  if char_length(v_token) not between 8 and 4096 then
    perform public.arena_fail('AR001', 'device token length is invalid');
  end if;
  v_platform := lower(btrim(coalesce(p_platform, 'android')));
  if v_platform not in ('android', 'ios') then
    v_platform := 'android';
  end if;
  insert into public.arena_devices (token, user_id, platform)
  values (v_token, p_actor, v_platform)
  on conflict (token) do update
    set user_id = excluded.user_id,
        platform = excluded.platform,
        updated_at = now();
  delete from public.arena_devices
  where user_id = p_actor
    and token not in (
      select d.token from public.arena_devices d
      where d.user_id = p_actor
      order by d.updated_at desc
      limit 10
    );
  return jsonb_build_object('ok', true);
end;
$$;

create or replace function public.arena_analytics(
  p_actor uuid,
  p_session uuid,
  p_event text,
  p_properties jsonb
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor public.arena_profiles;
  v_event text;
  v_properties jsonb;
begin
  v_actor := public.arena_assert_actor(p_actor, p_session);
  v_event := lower(btrim(coalesce(p_event, '')));
  if v_event !~ '^[a-z][a-z0-9_]{1,48}$' then
    perform public.arena_fail('AR001', 'event name is invalid');
  end if;
  v_properties := coalesce(p_properties, '{}'::jsonb);
  if jsonb_typeof(v_properties) <> 'object' then
    perform public.arena_fail('AR001', 'properties must be an object');
  end if;
  if pg_column_size(v_properties) > 8192 then
    perform public.arena_fail('AR023', 'properties are too large');
  end if;
  insert into public.arena_analytics_events (user_id, event, properties)
  values (p_actor, v_event, v_properties);
  return jsonb_build_object('ok', true);
end;
$$;

-- ----------------------------------------------------------------------------
-- Account deletion. Runs first and returns the avatar path so the Edge
-- Function can remove storage and then delete the auth user. Retry-safe: a
-- second call still returns the stored path and {already_deleted:true}.
-- ----------------------------------------------------------------------------
create or replace function public.arena_delete_account(p_actor uuid, p_session uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_profile public.arena_profiles;
  v_match_id uuid;
  v_paths text[];
begin
  if p_actor is null or p_session is null then
    perform public.arena_fail('AR002', 'authentication required');
  end if;
  if not exists (
    select 1 from auth.sessions s
    where s.id = p_session and s.user_id = p_actor
      and (s.not_after is null or s.not_after > now())
  ) then
    perform public.arena_fail('AR002', 'session is no longer active');
  end if;
  select * into v_profile
  from public.arena_profiles
  where user_id = p_actor
  for update;
  if not found then
    perform public.arena_fail('AR002', 'account is unavailable');
  end if;

  select coalesce(array_agg(p), '{}')
  into v_paths
  from (
    select v_profile.avatar_path as p where v_profile.avatar_path is not null
  ) paths;

  if v_profile.deleted_at is not null then
    return jsonb_build_object(
      'ok', true, 'already_deleted', true, 'avatar_paths', to_jsonb(v_paths)
    );
  end if;

  loop
    v_match_id := public.arena_active_match_id(p_actor);
    exit when v_match_id is null;
    perform public.arena_close_match(v_match_id, 'account_deleted', 'no_result', null);
  end loop;

  update public.arena_links
  set revoked_at = now()
  where user_id = p_actor and revoked_at is null;

  update public.arena_queue
  set status = 'cancelled'
  where user_id = p_actor and status = 'queued';

  update public.arena_requests
  set status = case
        when sender_id = p_actor then 'cancelled'::public.arena_request_status
        else 'expired'::public.arena_request_status
      end,
      responded_at = now()
  where status = 'pending'
    and (sender_id = p_actor or recipient_id = p_actor);

  delete from public.arena_devices where user_id = p_actor;

  update public.arena_profiles
  set deleted_at = now()
  where user_id = p_actor;

  return jsonb_build_object(
    'ok', true, 'already_deleted', false, 'avatar_paths', to_jsonb(v_paths)
  );
end;
$$;

-- ----------------------------------------------------------------------------
-- Maintenance worker (service role only): expires overdue requests and queue
-- seats and ticks every active match so abandoned preparation and silent
-- participants close even without client traffic.
-- ----------------------------------------------------------------------------
create or replace function public.arena_maintenance()
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_requests integer;
  v_queue integer;
  v_matches integer := 0;
  v_match_id uuid;
begin
  update public.arena_requests
  set status = 'expired', responded_at = now()
  where status = 'pending' and expires_at <= now();
  get diagnostics v_requests = row_count;

  update public.arena_queue
  set status = 'expired'
  where status = 'queued' and expires_at <= now();
  get diagnostics v_queue = row_count;

  for v_match_id in
    select m.id from public.arena_matches m
    where m.status in ('preparing', 'countdown', 'live')
    order by m.created_at asc
    limit 500
  loop
    begin
      perform public.arena_match_tick(v_match_id);
      v_matches := v_matches + 1;
    exception when others then
      -- One bad match must not stop the sweep; the next tick retries.
      null;
    end;
  end loop;

  return jsonb_build_object(
    'expired_requests', v_requests,
    'expired_queue_seats', v_queue,
    'ticked_matches', v_matches
  );
end;
$$;

-- ----------------------------------------------------------------------------
-- Notification outbox lease/confirm used by the arena-dispatcher function.
-- A lease is reclaimed when its deadline passes, so a crashed dispatcher
-- cannot strand notifications.
-- ----------------------------------------------------------------------------
create or replace function public.arena_outbox_lease(
  p_owner text,
  p_limit integer,
  p_lease_seconds integer
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_owner text;
  v_limit integer;
  v_seconds integer;
  v_result jsonb;
begin
  v_owner := btrim(coalesce(p_owner, ''));
  if v_owner = '' then
    perform public.arena_fail('AR001', 'lease owner is required');
  end if;
  v_limit := least(greatest(coalesce(p_limit, 20), 1), 100);
  v_seconds := least(greatest(coalesce(p_lease_seconds, 60), 10), 600);

  with candidates as (
    select o.id
    from public.arena_notification_outbox o
    where (o.status = 'pending' and o.available_at <= now())
       or (o.status = 'leased' and o.lease_expires_at <= now())
    order by o.available_at asc
    limit v_limit
    for update skip locked
  ),
  leased as (
    update public.arena_notification_outbox o
    set status = 'leased',
        lease_owner = v_owner,
        lease_expires_at = now() + make_interval(secs => v_seconds),
        attempts = o.attempts + 1
    from candidates c
    where o.id = c.id
    returning o.id, o.user_id, o.kind, o.payload, o.attempts
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', l.id,
        'user_id', l.user_id,
        'kind', l.kind,
        'payload', l.payload,
        'attempts', l.attempts,
        'devices', coalesce((
          select jsonb_agg(d.token)
          from public.arena_devices d
          where d.user_id = l.user_id
        ), '[]'::jsonb)
      )
    ),
    '[]'::jsonb
  )
  into v_result
  from leased l;

  return v_result;
end;
$$;

create or replace function public.arena_outbox_confirm(
  p_id uuid,
  p_owner text,
  p_delivered boolean,
  p_error text,
  p_retry_seconds integer
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_updated integer;
begin
  update public.arena_notification_outbox
  set status = case
        when coalesce(p_delivered, false) then 'delivered'::public.arena_notification_status
        when attempts >= 5 then 'failed'::public.arena_notification_status
        else 'pending'::public.arena_notification_status
      end,
      delivered_at = case when coalesce(p_delivered, false) then now() else null end,
      lease_owner = null,
      lease_expires_at = null,
      available_at = case
        when coalesce(p_delivered, false) then available_at
        else now() + make_interval(secs => least(greatest(coalesce(p_retry_seconds, 30), 5), 3600))
      end,
      last_error = left(p_error, 500)
  where id = p_id
    and status = 'leased'
    and lease_owner = p_owner;
  get diagnostics v_updated = row_count;
  return jsonb_build_object('ok', v_updated = 1);
end;
$$;

-- ----------------------------------------------------------------------------
-- Grants: every RPC is service-role only. Clients reach them exclusively
-- through the Edge Function, which has already verified the JWT.
-- ----------------------------------------------------------------------------
revoke all on all functions in schema public from public, anon, authenticated;
grant execute on all functions in schema public to service_role;
