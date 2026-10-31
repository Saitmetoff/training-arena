-- Forward-only current-build handshake. Existing five-argument RPCs retain
-- their locking, membership and readiness semantics; only the service gateway
-- can execute these wrappers. No legacy compatibility path is added.
create function public.arena_assert_counter_version(p_actor uuid, p_session uuid, p_counter_version text)
returns void language plpgsql volatile security definer
set search_path = public, pg_temp as $$
begin
  perform public.arena_assert_actor(p_actor, p_session);
  if coalesce(p_counter_version, '') !~ '^[0-9]+\.[0-9]+\.[0-9]+$'
     or char_length(p_counter_version) > 32
     or not exists (select 1 from public.arena_counter_versions where version = p_counter_version) then
    perform public.arena_fail('AR001', 'counter_version must be an allowed semantic version');
  end if;
end;
$$;

create function public.arena_match_ready_versioned(
  p_actor uuid, p_session uuid, p_match_id uuid, p_tracking boolean,
  p_practice_complete boolean, p_counter_version text)
returns jsonb language plpgsql volatile security definer
set search_path = public, pg_temp as $$
begin
  perform public.arena_assert_counter_version(p_actor, p_session, p_counter_version);
  return public.arena_match_ready(p_actor, p_session, p_match_id, p_tracking, p_practice_complete);
end;
$$;

create function public.arena_match_state_versioned(
  p_actor uuid, p_session uuid, p_match_id uuid, p_counter_version text)
returns jsonb language plpgsql volatile security definer
set search_path = public, pg_temp as $$
begin
  perform public.arena_assert_counter_version(p_actor, p_session, p_counter_version);
  return public.arena_match_state(p_actor, p_session, p_match_id);
end;
$$;

create function public.arena_match_heartbeat_versioned(
  p_actor uuid, p_session uuid, p_match_id uuid, p_tracking boolean, p_counter_version text)
returns jsonb language plpgsql volatile security definer
set search_path = public, pg_temp as $$
begin
  perform public.arena_assert_counter_version(p_actor, p_session, p_counter_version);
  return public.arena_match_heartbeat(p_actor, p_session, p_match_id, p_tracking);
end;
$$;

revoke all on function public.arena_assert_counter_version(uuid,uuid,text) from public, anon, authenticated;
revoke all on function public.arena_match_ready_versioned(uuid,uuid,uuid,boolean,boolean,text) from public, anon, authenticated;
revoke all on function public.arena_match_state_versioned(uuid,uuid,uuid,text) from public, anon, authenticated;
revoke all on function public.arena_match_heartbeat_versioned(uuid,uuid,uuid,boolean,text) from public, anon, authenticated;
grant execute on function public.arena_assert_counter_version(uuid,uuid,text) to service_role;
grant execute on function public.arena_match_ready_versioned(uuid,uuid,uuid,boolean,boolean,text) to service_role;
grant execute on function public.arena_match_state_versioned(uuid,uuid,uuid,text) to service_role;
grant execute on function public.arena_match_heartbeat_versioned(uuid,uuid,uuid,boolean,text) to service_role;
