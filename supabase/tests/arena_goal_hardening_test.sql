-- SYNTHETIC database fixtures; no claim of physical exercise or hosted validation.
begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

create temporary table goal_fixture on commit drop as
select gen_random_uuid() actor, gen_random_uuid() peer,
       gen_random_uuid() match_id, gen_random_uuid() old_match,
       gen_random_uuid() accepted_event;
insert into auth.users(id,aud,role)
select actor,'authenticated','authenticated' from goal_fixture
union all select peer,'authenticated','authenticated' from goal_fixture;
insert into auth.sessions(id,user_id,created_at,updated_at,not_after)
select actor,actor,now(),now(),now()+interval '1 day' from goal_fixture
union all select peer,peer,now(),now(),now()+interval '1 day' from goal_fixture;

select ok((select relrowsecurity from pg_class where oid='public.arena_counter_versions'::regclass),
  'version inventory has RLS');
select ok(not has_table_privilege('anon','public.arena_counter_versions','SELECT'),
  'anonymous users cannot read version inventory');
select ok(not has_table_privilege('authenticated','public.arena_counter_versions','INSERT'),
  'clients cannot add allowed counter versions');
select ok(exists(select 1 from public.arena_counter_versions where version='arena-counter/1.2.1'),
  'actual legacy wire value is inventoried');
select ok(exists(select 1 from public.arena_counter_versions where version='1.3.0'),
  'new WP1 semantic version is allowed');

insert into public.arena_matches(id,mode,exercise,status,origin,starts_at,ends_at,countdown_started_at)
select match_id,'casual'::public.arena_match_mode,'pushups'::public.arena_exercise,
  'live'::public.arena_match_status,'request',now()-interval '1 second',
  now()+interval '59 seconds',now()-interval '6 seconds' from goal_fixture
union all select old_match,'casual','pushups','live','request',now()-interval '1 second',
  now()+interval '59 seconds',now()-interval '6 seconds' from goal_fixture;
insert into public.arena_match_players(match_id,user_id,slot,rating_before,score,last_sequence,
  tracking,last_tracking_at,is_active)
select match_id,actor,1,1000,9,9,true,clock_timestamp(),true from goal_fixture
union all select match_id,peer,2,1000,0,0,true,clock_timestamp(),true from goal_fixture
union all select old_match,actor,1,1000,10,10,true,clock_timestamp(),false from goal_fixture
union all select old_match,peer,2,1000,0,0,true,clock_timestamp(),false from goal_fixture;
insert into public.arena_match_events(match_id,user_id,event_id,sequence,observed_at,received_at,counter_version)
select match_id,actor,gen_random_uuid(),i,now(),clock_timestamp()-interval '2 seconds'-i*interval '200 milliseconds','1.3.0'
from goal_fixture cross join generate_series(1,9) i;
insert into public.arena_match_events(match_id,user_id,event_id,sequence,observed_at,received_at,counter_version)
select old_match,actor,gen_random_uuid(),i,now(),clock_timestamp()-interval '1 second','1.3.0'
from goal_fixture cross join generate_series(1,10) i;

select throws_ok($$select public.arena_match_rep(actor,actor,match_id,gen_random_uuid(),10,now(),'1.3') from goal_fixture$$,
  'AR001','counter_version must be an allowed semantic version','malformed version fails');
select throws_ok($$select public.arena_match_rep(actor,actor,match_id,gen_random_uuid(),10,now(),'9.9.9') from goal_fixture$$,
  'AR001','counter_version must be an allowed semantic version','unknown semantic version fails');
select throws_ok($$select public.arena_match_rep(actor,actor,match_id,gen_random_uuid(),10,now(),'arena-counter/1.2.1') from goal_fixture$$,
  'AR001','counter_version must be an allowed semantic version','legacy prefix fails strict semantic-version gate');
select lives_ok($$select public.arena_match_rep(actor,actor,match_id,accepted_event,10,now(),'1.3.0') from goal_fixture$$,
  'tenth accepted rep is allowed; another round does not consume its quota');
select is((select count(*)::integer from public.arena_match_events where match_id=(select match_id from goal_fixture)
  and user_id=(select actor from goal_fixture)),10,'exactly ten accepted events');
select lives_ok($$select public.arena_match_rep(actor,actor,match_id,accepted_event,10,now(),'1.3.0') from goal_fixture$$,
  'idempotent retry does not consume another quota slot');
select pg_sleep(0.16);
select throws_ok($$select public.arena_match_rep(actor,actor,match_id,gen_random_uuid(),11,now(),'1.3.0') from goal_fixture$$,
  'AR017','rep rate exceeds 10 accepted reps in 5 seconds','eleventh rep fails rolling window after the 150ms gap');
select lives_ok($$select public.arena_match_rep(peer,peer,match_id,gen_random_uuid(),1,now(),'1.3.0') from goal_fixture$$,
  'peer has an independent quota');
select throws_ok($$select public.arena_match_rep(peer,peer,match_id,gen_random_uuid(),2,now(),'1.3.0') from goal_fixture$$,
  'AR017','rep rate is too high','150ms gap is retained');
update public.arena_match_players set score=240
where match_id=(select match_id from goal_fixture) and user_id=(select peer from goal_fixture);
select throws_ok($$select public.arena_match_rep(peer,peer,match_id,gen_random_uuid(),2,now(),'1.3.0') from goal_fixture$$,
  'AR017','rep rate exceeds the round limit','240 round cap is retained');

insert into public.arena_analytics_events(user_id,event,created_at)
select actor,'audit_event',clock_timestamp()-interval '30 minutes'
from goal_fixture cross join generate_series(1,119);
insert into public.arena_analytics_events(user_id,event,created_at)
select actor,'old_event',clock_timestamp()-interval '65 minutes'
from goal_fixture cross join generate_series(1,200);
select lives_ok($$select public.arena_analytics(actor,actor,'audit_event','{}') from goal_fixture$$,
  '120th event allowed; events older than one hour do not consume quota');
select throws_ok($$select public.arena_analytics(actor,actor,'audit_event','{}') from goal_fixture$$,
  'AR017','analytics exceeds 120 events per hour','121st event maps to existing rate_limited error');
select lives_ok($$select public.arena_analytics(peer,peer,'audit_event','{}') from goal_fixture$$,
  'analytics quota is per user');
select * from finish();
rollback;
