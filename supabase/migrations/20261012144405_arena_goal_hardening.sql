-- WP2: new migration only. Client tracking is self-reported, not proof of exercise.
create table public.arena_counter_versions (version text primary key);
insert into public.arena_counter_versions(version)
values ('arena-counter/1.2.1'), ('1.3.0');
-- Keep the actual legacy wire value in the inventory. The strict semver gate
-- below deliberately rejects its prefix; legacy clients need an owner rollout decision.
alter table public.arena_counter_versions enable row level security;
revoke all on public.arena_counter_versions from public, anon, authenticated;
grant select on public.arena_counter_versions to service_role;

create index arena_analytics_user_time_idx
  on public.arena_analytics_events(user_id, created_at desc);

create or replace function public.arena_match_rep(
  p_actor uuid, p_session uuid, p_match_id uuid, p_event_id uuid,
  p_sequence bigint, p_observed_at timestamptz, p_counter_version text
)
returns jsonb language plpgsql volatile security definer
set search_path = public, pg_temp
as $$
declare
  v_actor public.arena_profiles;
  v_match public.arena_matches;
  v_player public.arena_match_players;
  v_version text;
  v_now timestamptz;
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
  v_version := coalesce(p_counter_version, '');
  if v_version !~ '^[0-9]+\.[0-9]+\.[0-9]+$'
     or char_length(v_version) > 32
     or not exists (select 1 from public.arena_counter_versions where version = v_version) then
    perform public.arena_fail('AR001', 'counter_version must be an allowed semantic version');
  end if;
  if p_match_id is null or not exists (
    select 1 from public.arena_match_players mp
    where mp.match_id = p_match_id and mp.user_id = p_actor
  ) then
    perform public.arena_fail('AR003', 'match not found');
  end if;
  perform public.arena_match_tick(p_match_id);
  select * into v_match from public.arena_matches where id = p_match_id;
  if exists (select 1 from public.arena_match_events e
    where e.match_id = p_match_id and e.event_id = p_event_id) then
    return jsonb_build_object('match', public.arena_match_view(p_match_id));
  end if;
  if v_match.status in ('finished', 'no_result') then
    perform public.arena_fail('AR014', 'match is no longer live');
  end if;
  if v_match.status <> 'live' then
    perform public.arena_fail('AR014', 'match is not live');
  end if;
  -- Serialize checks and insert on the same player/round row.
  select * into v_player from public.arena_match_players
  where match_id = p_match_id and user_id = p_actor for update;
  v_now := clock_timestamp();
  if v_player.left_at is not null then
    perform public.arena_fail('AR014', 'player has left the match');
  end if;
  if not v_player.tracking or v_player.last_tracking_at is null
     or v_now - v_player.last_tracking_at > interval '5 seconds' then
    perform public.arena_fail('AR016', 'camera tracking is not fresh');
  end if;
  if p_observed_at > v_now + interval '2 seconds'
     or p_observed_at < v_match.starts_at - interval '2 seconds' then
    perform public.arena_fail('AR015', 'rep was observed outside the round window');
  end if;
  if p_sequence <= v_player.last_sequence then
    perform public.arena_fail('AR015', 'rep sequence is not increasing');
  end if;
  if v_player.score >= 240 then
    perform public.arena_fail('AR017', 'rep rate exceeds the round limit');
  end if;
  if exists (select 1 from public.arena_match_events e
    where e.match_id = p_match_id and e.user_id = p_actor
      and e.received_at > v_now - interval '150 milliseconds') then
    perform public.arena_fail('AR017', 'rep rate is too high');
  end if;
  if (select count(*) from public.arena_match_events e
    where e.match_id = p_match_id and e.user_id = p_actor
      and e.received_at > v_now - interval '5 seconds') >= 10 then
    perform public.arena_fail('AR017', 'rep rate exceeds 10 accepted reps in 5 seconds');
  end if;
  begin
    insert into public.arena_match_events(
      match_id,user_id,event_id,sequence,observed_at,counter_version,received_at)
    values(p_match_id,p_actor,p_event_id,p_sequence,p_observed_at,v_version,v_now);
  exception when unique_violation then
    return jsonb_build_object('match', public.arena_match_view(p_match_id));
  end;
  update public.arena_match_players
  set score = score + 1, last_sequence = p_sequence, last_seen_at = v_now
  where match_id = p_match_id and user_id = p_actor;
  return jsonb_build_object('match', public.arena_match_view(p_match_id));
end;
$$;

create or replace function public.arena_analytics(
  p_actor uuid, p_session uuid, p_event text, p_properties jsonb
)
returns jsonb language plpgsql volatile security definer
set search_path = public, pg_temp
as $$
declare
  v_actor public.arena_profiles;
  v_event text;
  v_properties jsonb;
  v_now timestamptz;
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
  -- Serialize per-user counts so concurrent requests cannot pass the same slot.
  perform 1 from public.arena_profiles where user_id = p_actor for update;
  v_now := clock_timestamp();
  if (select count(*) from public.arena_analytics_events
      where user_id = p_actor and created_at > v_now - interval '1 hour') >= 120 then
    perform public.arena_fail('AR017', 'analytics exceeds 120 events per hour');
  end if;
  insert into public.arena_analytics_events(user_id,event,properties,created_at)
  values(p_actor,v_event,v_properties,v_now);
  return jsonb_build_object('ok',true);
end;
$$;

revoke all on function public.arena_match_rep(uuid,uuid,uuid,uuid,bigint,timestamptz,text)
  from public, anon, authenticated;
grant execute on function public.arena_match_rep(uuid,uuid,uuid,uuid,bigint,timestamptz,text)
  to service_role;
revoke all on function public.arena_analytics(uuid,uuid,text,jsonb)
  from public, anon, authenticated;
grant execute on function public.arena_analytics(uuid,uuid,text,jsonb) to service_role;
