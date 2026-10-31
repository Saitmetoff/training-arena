-- ============================================================================
-- Arena live-start presence stamp.
--
-- Readiness is the presence proof during preparation and countdown. Before
-- this migration a player who confirmed ready more than ten seconds before
-- the countdown ended (for example while the other player finished the
-- practice rep) was already "stale" when `arena_match_tick` promoted the
-- match to live, so the very first live tick closed it as
-- `opponent_absent`/`win` without giving that player the documented
-- ten-second recovery window (docs/API.md: "One player absent for more than
-- 10 seconds forfeits"). Refresh both active players' presence at the
-- countdown -> live promotion so the live-phase recovery window always
-- starts when live starts. The mid-round and end-of-round absence rules are
-- unchanged.
-- ============================================================================
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
    -- Both players confirmed ready before the countdown started. Presence is
    -- lifted to the live start (never later), so the recovery window is fair
    -- without hiding an outage that began before live: the promotion is lazy,
    -- and stamping the sweep clock here would grant unearned freshness.
    update public.arena_match_players
    set last_seen_at = greatest(last_seen_at, v_match.starts_at)
    where match_id = p_match_id and left_at is null;
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
