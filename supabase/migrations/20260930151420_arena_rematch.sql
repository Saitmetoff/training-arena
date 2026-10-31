-- Fresh casual requests from a finished match. Scores and receipts are untouched.
create or replace function public.arena_request_rematch(
  p_actor uuid, p_session uuid, p_match_id uuid
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_opponent uuid;
  v_request uuid;
  v_token text;
begin
  perform public.arena_assert_actor(p_actor, p_session);
  select peer.user_id into v_opponent
  from public.arena_matches m
  join public.arena_match_players own on own.match_id = m.id and own.user_id = p_actor
  join public.arena_match_players peer on peer.match_id = m.id and peer.user_id <> p_actor
  where m.id = p_match_id and m.status = 'finished';
  if v_opponent is null then
    perform public.arena_fail('AR003', 'finished match not found');
  end if;

  -- Serialize both directions so two simultaneous rematch taps recover one request.
  perform pg_advisory_xact_lock(hashtextextended(
    least(p_actor, v_opponent)::text || greatest(p_actor, v_opponent)::text, 0));
  if public.arena_are_blocked(p_actor, v_opponent) then
    perform public.arena_fail('AR010', 'challenge is not available');
  end if;
  if public.arena_active_match_id(p_actor) is not null
     or public.arena_active_match_id(v_opponent) is not null then
    perform public.arena_fail('AR011', 'finish the current match first');
  end if;
  if not exists (select 1 from public.arena_profiles
                 where user_id = v_opponent and deleted_at is null) then
    perform public.arena_fail('AR006', 'challenge link is not available');
  end if;
  perform public.arena_expire_requests_for(p_actor);
  select id into v_request from public.arena_requests
  where status = 'pending' and expires_at > now()
    and ((sender_id = p_actor and recipient_id = v_opponent)
      or (sender_id = v_opponent and recipient_id = p_actor))
  order by created_at limit 1;
  if v_request is not null then
    return jsonb_build_object('request', public.arena_request_json(v_request));
  end if;
  v_token := public.arena_link_json(v_opponent)->>'token';
  return public.arena_request_send(p_actor, p_session, v_token);
end;
$$;

revoke all on function public.arena_request_rematch(uuid, uuid, uuid)
  from public, anon, authenticated;
grant execute on function public.arena_request_rematch(uuid, uuid, uuid) to service_role;
