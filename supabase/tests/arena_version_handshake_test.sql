begin;
create extension if not exists pgtap with schema extensions;
select no_plan();
create temporary table version_fixture as select gen_random_uuid() actor,gen_random_uuid() peer;
insert into auth.users(id,aud,role)
select actor,'authenticated','authenticated' from version_fixture
union all select peer,'authenticated','authenticated' from version_fixture;
insert into auth.sessions(id,user_id,not_after)
select actor,actor,now()+interval '1 day' from version_fixture
union all select peer,peer,now()+interval '1 day' from version_fixture;
update public.arena_profiles set username='version_'||left(user_id::text,8)
where user_id in(select actor from version_fixture union all select peer from version_fixture);
insert into public.arena_requests(sender_id,recipient_id) select actor,peer from version_fixture;
create temporary table version_match as select
  (public.arena_request_accept(peer,peer,(select id from public.arena_requests where sender_id=actor))->'match'->>'id')::uuid id
from version_fixture;
select ok(not has_function_privilege('anon','public.arena_match_ready_versioned(uuid,uuid,uuid,boolean,boolean,text)','EXECUTE'),
  'anonymous cannot call versioned ready');
select ok(not has_function_privilege('authenticated','public.arena_match_state_versioned(uuid,uuid,uuid,text)','EXECUTE'),
  'clients cannot bypass verified gateway for restoration');
select throws_ok($$select public.arena_match_ready_versioned(actor,actor,id,true,true,null) from version_fixture,version_match$$,
  'AR001','counter_version must be an allowed semantic version','missing version cannot ready');
select throws_ok($$select public.arena_match_ready_versioned(actor,actor,id,true,true,'arena-counter/1.2.1') from version_fixture,version_match$$,
  'AR001','counter_version must be an allowed semantic version','legacy version cannot ready');
select throws_ok($$select public.arena_match_ready_versioned(actor,actor,id,true,true,'9.9.9') from version_fixture,version_match$$,
  'AR001','counter_version must be an allowed semantic version','unknown numeric version cannot ready');
select is((select count(*)::integer from public.arena_match_players where ready),0,'unsupported readiness mutates no player');
select lives_ok($$select public.arena_match_ready_versioned(actor,actor,id,true,true,'1.3.0') from version_fixture,version_match$$,
  'current version can ready');
select is((select status::text from public.arena_matches where id=(select id from version_match)),'preparing',
  'one supported phone cannot start countdown alone');
select throws_ok($$select public.arena_match_ready_versioned(peer,peer,id,true,true,'1.2.1') from version_fixture,version_match$$,
  'AR001','counter_version must be an allowed semantic version','other unsupported phone still cannot start');
select lives_ok($$select public.arena_match_ready_versioned(peer,peer,id,true,true,'1.3.0') from version_fixture,version_match$$,
  'both current phones ready');
select is((select status::text from public.arena_matches where id=(select id from version_match)),'countdown',
  'countdown starts only after both supported ready gates');
select throws_ok($$select public.arena_match_state_versioned(actor,actor,id,'arena-counter/1.2.1') from version_fixture,version_match$$,
  'AR001','counter_version must be an allowed semantic version','unsupported restore refused');
select throws_ok($$select public.arena_match_heartbeat_versioned(actor,actor,id,true,'arena-counter/1.2.1') from version_fixture,version_match$$,
  'AR001','counter_version must be an allowed semantic version','unsupported live heartbeat refused');
select * from finish();
rollback;
