begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

select ok(not has_function_privilege('authenticated',
  'public.arena_request_rematch(uuid,uuid,uuid)', 'EXECUTE'),
  'clients cannot impersonate a rematch actor through direct RPC');
select ok(has_function_privilege('service_role',
  'public.arena_request_rematch(uuid,uuid,uuid)', 'EXECUTE'),
  'verified Edge calls can request a rematch');

insert into auth.users (id, aud, role, email, email_confirmed_at, raw_app_meta_data, raw_user_meta_data)
select id, 'authenticated', 'authenticated', id::text || '@fixture.invalid', now(), '{}', '{}'
from unnest(array[
  'e0000000-0000-4000-8000-000000000001'::uuid,
  'e0000000-0000-4000-8000-000000000002'::uuid,
  'e0000000-0000-4000-8000-000000000003'::uuid
]) id;
update public.arena_profiles set username = 't_rematch_' || right(user_id::text, 1)
where user_id::text like 'e0000000-%';
insert into auth.sessions (id, user_id, created_at, updated_at, not_after)
select user_id, user_id, now(), now(), now() + interval '1 day'
from public.arena_profiles where user_id::text like 'e0000000-%';
insert into public.arena_links(token, user_id)
values ('rematchbob01', 'e0000000-0000-4000-8000-000000000002');

create temp table rematch_ids (original uuid, request uuid, fresh uuid, receipt jsonb);
insert into rematch_ids(request)
select (public.arena_request_send(
  'e0000000-0000-4000-8000-000000000001',
  'e0000000-0000-4000-8000-000000000001', 'rematchbob01')->'request'->>'id')::uuid;
update rematch_ids set original = (public.arena_request_accept(
  'e0000000-0000-4000-8000-000000000002',
  'e0000000-0000-4000-8000-000000000002', request)->'match'->>'id')::uuid;
select public.arena_close_match(original, 'completed', 'win', 'e0000000-0000-4000-8000-000000000001') from rematch_ids;
update rematch_ids set receipt = public.arena_receipt_json(original);

select throws_ok(format('select public.arena_request_rematch(%L, %L, %L)',
  'e0000000-0000-4000-8000-000000000003', 'e0000000-0000-4000-8000-000000000003', original),
  'AR003', 'finished match not found', 'nonparticipants cannot request a rematch') from rematch_ids;
update rematch_ids set request = (public.arena_request_rematch(
  'e0000000-0000-4000-8000-000000000001',
  'e0000000-0000-4000-8000-000000000001', original)->'request'->>'id')::uuid;
select is((public.arena_request_rematch(
  'e0000000-0000-4000-8000-000000000001',
  'e0000000-0000-4000-8000-000000000001', original)->'request'->>'id')::uuid,
  request, 'repeated taps recover the existing pending request') from rematch_ids;
select is(public.arena_active_match_id('e0000000-0000-4000-8000-000000000001'), null::uuid,
  'requesting a rematch never starts another match');
select is(public.arena_receipt_json(original), receipt, 'the old receipt stays immutable') from rematch_ids;
select is((public.arena_request_rematch(
  'e0000000-0000-4000-8000-000000000002',
  'e0000000-0000-4000-8000-000000000002', original)->'request'->>'id')::uuid,
  request, 'opposite-direction taps recover the pending incoming request') from rematch_ids;
update public.arena_requests set created_at = now() - interval '2 days',
  expires_at = now() - interval '1 day' where id = (select request from rematch_ids);
select isnt((public.arena_request_rematch(
  'e0000000-0000-4000-8000-000000000001',
  'e0000000-0000-4000-8000-000000000001', original)->'request'->>'id')::uuid,
  request, 'an expired request is replaced with a fresh request') from rematch_ids;
update rematch_ids set request = (public.arena_request_rematch(
  'e0000000-0000-4000-8000-000000000001',
  'e0000000-0000-4000-8000-000000000001', original)->'request'->>'id')::uuid;
update rematch_ids set fresh = (public.arena_request_accept(
  'e0000000-0000-4000-8000-000000000002',
  'e0000000-0000-4000-8000-000000000002', request)->'match'->>'id')::uuid;
select isnt(fresh, original, 'accepting creates a new match') from rematch_ids;
select is(public.arena_match_view(fresh)->>'mode', 'casual', 'rematches are casual') from rematch_ids;
select is(public.arena_match_view(fresh)->>'status', 'preparing', 'both players must prepare again') from rematch_ids;
select ok(not exists (select 1 from public.arena_match_players where match_id = fresh and (score <> 0 or ready)),
  'scores and readiness are reset') from rematch_ids;
select throws_ok(format('select public.arena_request_rematch(%L, %L, %L)',
  'e0000000-0000-4000-8000-000000000001', 'e0000000-0000-4000-8000-000000000001', original),
  'AR011', 'finish the current match first', 'busy players cannot rematch') from rematch_ids;
select throws_ok(format('select public.arena_request_rematch(%L, %L, %L)',
  'e0000000-0000-4000-8000-000000000001', 'e0000000-0000-4000-8000-000000000001', fresh),
  'AR003', 'finished match not found', 'unfinished matches cannot be reused') from rematch_ids;
select public.arena_close_match(fresh, 'completed', 'draw', null) from rematch_ids;
select public.arena_block('e0000000-0000-4000-8000-000000000002',
  'e0000000-0000-4000-8000-000000000002', 'e0000000-0000-4000-8000-000000000001');
select throws_ok(format('select public.arena_request_rematch(%L, %L, %L)',
  'e0000000-0000-4000-8000-000000000001', 'e0000000-0000-4000-8000-000000000001', original),
  'AR010', 'challenge is not available', 'blocks still protect rematches') from rematch_ids;
select * from finish();
rollback;
