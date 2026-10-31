-- Run manually against the hosted pilot, never interpret local fixture totals
-- as customer activity. Set since to the real cohort start; as_of freezes the
-- observation window. Deleted participants cannot contribute to user cohorts.
-- Read-only aggregates: no account ids, emails, links or tokens are returned.
begin transaction read only;
with params as (
  select '2026-10-01T00:00:00Z'::timestamptz as since, now() as as_of
), full_round_players as (
  select p.user_id, r.match_id, r.finished_at
  from public.arena_receipts r
  join public.arena_match_players p on p.match_id = r.match_id
  cross join params
  where r.mode = 'casual' and r.reason = 'round_complete'
    and r.outcome <> 'no_result' and r.finished_at <= params.as_of
), first_rounds as (
  select user_id, min(finished_at) as first_at
  from full_round_players group by user_id
), cohort as (
  select f.* from first_rounds f cross join params
  where f.first_at >= params.since
), mature as (
  select c.* from cohort c cross join params
  where c.first_at <= params.as_of - interval '7 days'
), returns as (
  select m.user_id from mature m where exists (
    select 1 from full_round_players r where r.user_id = m.user_id
      and r.finished_at > m.first_at
      and r.finished_at <= m.first_at + interval '7 days'
  )
), requests as (
  select q.* from public.arena_requests q cross join params
  where q.created_at >= params.since and q.created_at <= params.as_of
), accepted as (
  select * from requests where status = 'accepted'
), converted as (
  select q.id from accepted q join public.arena_receipts r on r.match_id = q.match_id
  cross join params
  where r.reason = 'round_complete' and r.outcome <> 'no_result'
    and r.finished_at <= params.as_of
), outcomes as (
  select r.* from public.arena_receipts r cross join params
  where r.mode = 'casual' and r.finished_at >= params.since
    and r.finished_at <= params.as_of
)
select metric, observations from (
  select 'players_first_full_round' as metric, count(*) as observations from cohort
  union all select 'players_with_mature_7_day_window', count(*) from mature
  union all select 'players_returned_within_7_days', count(*) from returns
  union all select 'requests_created', count(*) from requests
  union all select 'requests_accepted', count(*) from accepted
  union all select 'accepted_requests_with_full_round', count(*) from converted
  union all select 'casual_full_rounds', count(*) from outcomes where reason = 'round_complete' and outcome <> 'no_result'
  union all select 'casual_forfeits', count(*) from outcomes where reason <> 'round_complete' and outcome <> 'no_result'
  union all select 'casual_no_results', count(*) from outcomes where outcome = 'no_result'
) totals order by metric;
rollback;
