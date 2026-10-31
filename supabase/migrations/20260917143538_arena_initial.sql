-- ============================================================================
-- Training Arena — initial schema (task 04, part 1 of 2)
-- ============================================================================
-- Scope: enums, tables, constraints, indexes, triggers, RLS and grants for the
-- `arena_*` namespace in `public`. RPCs live in the sibling migration
-- `20260917143539_arena_rpc.sql`.
--
-- Product invariants encoded here:
--   * durable challenge links, 24h requests, matches only after acceptance,
--     one immutable receipt per match;
--   * only `pushups` and `squats` exist;
--   * ranked queue matches change Elo (1000 start, K=32); personal challenges
--     are casual and never change rating;
--   * one active match per user, one queued seat per user, unique normalized
--     usernames, one receipt per match.
--
-- Security model:
--   * `anon` and `authenticated` get no table, sequence or function grants.
--     Every read/write goes through the `arena` Edge Function with the
--     service role and an explicitly verified actor id.
--   * RLS is enabled on every table and no policies exist, so even a future
--     accidental grant still fails closed.
--   * Receipts, rating history and rep events are immutable by trigger.
--
-- Rollback notes (run only on an empty/pre-production project; order matters):
--   1. drop function public.arena_forbid_mutation();
--   2. drop trigger arena_on_auth_user_created on auth.users;
--   3. drop function public.arena_handle_new_user();
--   4. drop table public.arena_analytics_events, public.arena_notification_outbox,
--      public.arena_devices, public.arena_reports, public.arena_blocks,
--      public.arena_queue, public.arena_rating_history, public.arena_receipts,
--      public.arena_match_events, public.arena_match_players, public.arena_matches,
--      public.arena_requests, public.arena_links, public.arena_profiles;
--   5. drop type public.arena_notification_status, public.arena_queue_status,
--      public.arena_request_status, public.arena_outcome,
--      public.arena_match_status, public.arena_match_mode, public.arena_exercise;
--   6. delete from storage.buckets where id = 'arena-avatars';
--   The RPC migration must be rolled back first: it creates functions that
--   depend on these tables.
-- ============================================================================

create extension if not exists pgcrypto with schema extensions;

-- ----------------------------------------------------------------------------
-- Enumerated domain values. These are the wire values in docs/API.md.
-- ----------------------------------------------------------------------------
create type public.arena_exercise as enum ('pushups', 'squats');
create type public.arena_match_mode as enum ('casual', 'ranked');
create type public.arena_match_status as enum
  ('preparing', 'countdown', 'live', 'finished', 'no_result');
create type public.arena_outcome as enum ('win', 'draw', 'no_result');
create type public.arena_request_status as enum
  ('pending', 'accepted', 'declined', 'cancelled', 'expired');
create type public.arena_queue_status as enum
  ('queued', 'matched', 'cancelled', 'expired');
create type public.arena_notification_status as enum
  ('pending', 'leased', 'delivered', 'failed', 'skipped');

-- ----------------------------------------------------------------------------
-- arena_profiles — one row per auth user, created by trigger on sign-up.
-- ----------------------------------------------------------------------------
create table public.arena_profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  username text,
  username_normalized text generated always as (lower(username)) stored,
  avatar_url text,
  avatar_path text,
  rating integer not null default 1000,
  ranked_wins integer not null default 0,
  ranked_battles integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint arena_profiles_rating_non_negative check (rating >= 0),
  constraint arena_profiles_wins_non_negative check (ranked_wins >= 0),
  constraint arena_profiles_battles_non_negative check (ranked_battles >= 0),
  constraint arena_profiles_wins_le_battles check (ranked_wins <= ranked_battles),
  constraint arena_profiles_username_format check (
    username is null or username ~ '^[A-Za-z0-9_]{3,20}$'
  ),
  constraint arena_profiles_username_reserved check (
    username is null
    or lower(username) not in (
      'arena', 'admin', 'administrator', 'support', 'moderator',
      'trainingarena', 'system', 'official', 'mod', 'staff'
    )
  ),
  constraint arena_profiles_avatar_url_https check (
    avatar_url is null or avatar_url ~ '^https://'
  )
);

-- Case-insensitive uniqueness for usernames; null usernames are allowed until
-- the player picks one and are excluded from the index.
create unique index arena_profiles_username_key
  on public.arena_profiles (username_normalized)
  where username is not null;

create index arena_profiles_leaderboard_idx
  on public.arena_profiles (rating desc, ranked_wins desc, created_at asc)
  where username is not null and deleted_at is null;

-- ----------------------------------------------------------------------------
-- arena_links — durable challenge links. A user has at most one active link;
-- rotation revokes the previous token, it never expires by itself.
-- ----------------------------------------------------------------------------
create table public.arena_links (
  token text primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  rotated_at timestamptz,
  revoked_at timestamptz,
  constraint arena_links_token_format check (token ~ '^[a-z0-9]{12}$'),
  constraint arena_links_revoked_after_created check (
    revoked_at is null or revoked_at >= created_at
  )
);

create unique index arena_links_active_user_idx
  on public.arena_links (user_id)
  where revoked_at is null;

create index arena_links_user_idx on public.arena_links (user_id, created_at desc);

-- ----------------------------------------------------------------------------
-- arena_matches — created only after an accepted request or a queue pairing.
-- Status is driven by server time in arena_match_tick.
-- ----------------------------------------------------------------------------
create table public.arena_matches (
  id uuid primary key default gen_random_uuid(),
  mode public.arena_match_mode not null,
  exercise public.arena_exercise not null,
  status public.arena_match_status not null default 'preparing',
  origin text not null,
  request_id uuid,
  created_at timestamptz not null default now(),
  prep_expires_at timestamptz not null default (now() + interval '10 minutes'),
  countdown_started_at timestamptz,
  starts_at timestamptz,
  ends_at timestamptz,
  live_started_at timestamptz,
  finished_at timestamptz,
  closed_reason text,
  constraint arena_matches_origin_valid check (origin in ('request', 'ranked_queue')),
  constraint arena_matches_prep_deadline check (prep_expires_at > created_at),
  constraint arena_matches_clock_consistency check (
    (starts_at is null and ends_at is null and countdown_started_at is null)
    or (
      starts_at is not null
      and ends_at is not null
      and ends_at = starts_at + interval '60 seconds'
    )
  ),
  constraint arena_matches_closed_consistency check (
    (status in ('finished', 'no_result') and finished_at is not null and closed_reason is not null)
    or (status in ('preparing', 'countdown', 'live') and finished_at is null)
  ),
  constraint arena_matches_closed_reason_length check (
    closed_reason is null or char_length(closed_reason) between 1 and 200
  )
);

create index arena_matches_active_idx
  on public.arena_matches (status)
  where status in ('preparing', 'countdown', 'live');

-- ----------------------------------------------------------------------------
-- arena_requests — one recipient invitation, valid 24 hours. Personal
-- challenges are always casual; exercise is selected when a match is created.
-- ----------------------------------------------------------------------------
create table public.arena_requests (
  id uuid primary key default gen_random_uuid(),
  link_token text references public.arena_links (token) on delete set null,
  sender_id uuid not null references auth.users (id) on delete cascade,
  recipient_id uuid not null references auth.users (id) on delete cascade,
  status public.arena_request_status not null default 'pending',
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '24 hours'),
  responded_at timestamptz,
  match_id uuid references public.arena_matches (id) on delete restrict,
  constraint arena_requests_not_self check (sender_id <> recipient_id),
  constraint arena_requests_expiry_after_create check (expires_at > created_at),
  constraint arena_requests_accepted_has_match check (
    status <> 'accepted' or match_id is not null
  ),
  constraint arena_requests_pending_not_responded check (
    (status = 'pending' and responded_at is null)
    or (status <> 'pending' and responded_at is not null)
  )
);

create unique index arena_requests_pending_pair_idx
  on public.arena_requests (sender_id, recipient_id)
  where status = 'pending';

create index arena_requests_recipient_idx
  on public.arena_requests (recipient_id, status, expires_at desc);

create index arena_requests_sender_idx
  on public.arena_requests (sender_id, status, expires_at desc);

-- Matches created from a request link back to it; deleting a request keeps the
-- match history intact.
alter table public.arena_matches
  add constraint arena_matches_request_fk
  foreign key (request_id) references public.arena_requests (id) on delete set null;

-- ----------------------------------------------------------------------------
-- arena_match_players — one row per player per match. `is_active` plus the
-- partial unique index enforce the single-active-match rule. Snapshot columns
-- keep a live match readable even if a profile is deleted mid-match.
-- ----------------------------------------------------------------------------
create table public.arena_match_players (
  match_id uuid not null references public.arena_matches (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  slot smallint not null,
  username_snapshot text,
  avatar_url_snapshot text,
  rating_before integer not null,
  score integer not null default 0,
  last_sequence bigint not null default 0,
  ready boolean not null default false,
  practice_complete boolean not null default false,
  tracking boolean not null default false,
  last_seen_at timestamptz not null default clock_timestamp(),
  last_tracking_at timestamptz,
  left_at timestamptz,
  is_active boolean not null default true,
  primary key (match_id, user_id),
  constraint arena_match_players_slot_valid check (slot in (1, 2)),
  constraint arena_match_players_score_non_negative check (score >= 0),
  constraint arena_match_players_sequence_non_negative check (last_sequence >= 0),
  unique (match_id, slot)
);

-- A player can be in at most one live/preparing match at a time.
create unique index arena_match_players_active_user_idx
  on public.arena_match_players (user_id)
  where is_active;

create index arena_match_players_user_idx
  on public.arena_match_players (user_id, match_id);

-- ----------------------------------------------------------------------------
-- arena_match_events — accepted camera rep events. Immutable audit trail with
-- per-player idempotency and strict sequence ordering.
-- ----------------------------------------------------------------------------
create table public.arena_match_events (
  id uuid primary key default gen_random_uuid(),
  match_id uuid not null references public.arena_matches (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  event_id uuid not null,
  sequence bigint not null,
  observed_at timestamptz not null,
  received_at timestamptz not null default clock_timestamp(),
  counter_version text not null,
  constraint arena_match_events_sequence_positive check (sequence > 0),
  constraint arena_match_events_counter_version_length check (
    char_length(counter_version) between 1 and 32
  ),
  unique (match_id, event_id),
  unique (match_id, user_id, sequence)
);

create index arena_match_events_rate_idx
  on public.arena_match_events (match_id, user_id, received_at desc);

-- ----------------------------------------------------------------------------
-- arena_queue — one active seat per user; seats expire after 60 seconds.
-- ----------------------------------------------------------------------------
create table public.arena_queue (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  status public.arena_queue_status not null default 'queued',
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '60 seconds'),
  matched_at timestamptz,
  match_id uuid references public.arena_matches (id) on delete set null,
  constraint arena_queue_expiry_after_create check (expires_at > created_at),
  constraint arena_queue_matched_consistent check (
    (status = 'matched') = (matched_at is not null and match_id is not null)
  )
);

create unique index arena_queue_active_user_idx
  on public.arena_queue (user_id)
  where status = 'queued';

create index arena_queue_queued_idx
  on public.arena_queue (created_at asc)
  where status = 'queued';

-- ----------------------------------------------------------------------------
-- arena_receipts — immutable, one per match, the only evidence for history
-- and sharing. `players` is the frozen identity/score/rating snapshot.
-- ----------------------------------------------------------------------------
create table public.arena_receipts (
  id uuid primary key default gen_random_uuid(),
  match_id uuid not null references public.arena_matches (id) on delete restrict,
  exercise public.arena_exercise not null,
  mode public.arena_match_mode not null,
  outcome public.arena_outcome not null,
  winner_id uuid,
  players jsonb not null,
  finished_at timestamptz not null,
  reason text not null,
  created_at timestamptz not null default now(),
  constraint arena_receipts_match_unique unique (match_id),
  constraint arena_receipts_winner_consistent check (
    (outcome = 'win' and winner_id is not null)
    or (outcome <> 'win' and winner_id is null)
  ),
  constraint arena_receipts_players_array check (
    jsonb_typeof(players) = 'array' and jsonb_array_length(players) = 2
  ),
  constraint arena_receipts_reason_length check (char_length(reason) between 1 and 200)
);

create index arena_receipts_finished_idx on public.arena_receipts (finished_at desc);

-- ----------------------------------------------------------------------------
-- arena_rating_history — exactly-once Elo audit, unique per match and player.
-- user_id is nullable so the counterpart audit survives account deletion.
-- ----------------------------------------------------------------------------
create table public.arena_rating_history (
  id uuid primary key default gen_random_uuid(),
  match_id uuid not null references public.arena_matches (id) on delete restrict,
  user_id uuid references auth.users (id) on delete set null,
  rating_before integer not null,
  rating_after integer not null,
  rating_change integer not null,
  created_at timestamptz not null default now(),
  constraint arena_rating_history_change_consistent check (
    rating_after = rating_before + rating_change
  ),
  unique (match_id, user_id)
);

-- ----------------------------------------------------------------------------
-- arena_blocks — mutual exclusion for requests and queue matching.
-- ----------------------------------------------------------------------------
create table public.arena_blocks (
  blocker_id uuid not null references auth.users (id) on delete cascade,
  blocked_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint arena_blocks_not_self check (blocker_id <> blocked_id)
);

create index arena_blocks_blocked_idx on public.arena_blocks (blocked_id);

-- ----------------------------------------------------------------------------
-- arena_reports — abuse reports; the server never enforces behaviour from
-- them, moderation is manual.
-- ----------------------------------------------------------------------------
create table public.arena_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users (id) on delete cascade,
  target_user_id uuid not null references auth.users (id) on delete cascade,
  match_id uuid references public.arena_matches (id) on delete set null,
  reason text not null,
  created_at timestamptz not null default now(),
  constraint arena_reports_not_self check (reporter_id <> target_user_id),
  constraint arena_reports_reason_length check (char_length(reason) between 3 and 500)
);

create index arena_reports_target_idx
  on public.arena_reports (target_user_id, created_at desc);

-- ----------------------------------------------------------------------------
-- arena_devices — push tokens registered with the service role. One token
-- maps to one current user; re-registration reassigns it.
-- ----------------------------------------------------------------------------
create table public.arena_devices (
  token text primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  platform text not null default 'android',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint arena_devices_token_length check (char_length(token) between 8 and 4096),
  constraint arena_devices_platform_valid check (platform in ('android', 'ios'))
);

create index arena_devices_user_idx on public.arena_devices (user_id);

-- ----------------------------------------------------------------------------
-- arena_notification_outbox — transactional outbox; platform delivery is best
-- effort and the inbox stays authoritative. The dispatcher leases rows.
-- ----------------------------------------------------------------------------
create table public.arena_notification_outbox (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  kind text not null,
  payload jsonb not null default '{}'::jsonb,
  status public.arena_notification_status not null default 'pending',
  attempts integer not null default 0,
  available_at timestamptz not null default now(),
  lease_owner text,
  lease_expires_at timestamptz,
  delivered_at timestamptz,
  last_error text,
  created_at timestamptz not null default now(),
  constraint arena_outbox_kind_valid check (
    kind in ('challenge_request', 'request_accepted', 'request_declined', 'match_ready', 'match_finished')
  ),
  constraint arena_outbox_attempts_non_negative check (attempts >= 0),
  constraint arena_outbox_lease_consistent check (
    (status = 'leased' and lease_owner is not null and lease_expires_at is not null)
    or (status <> 'leased')
  )
);

create index arena_outbox_due_idx
  on public.arena_notification_outbox (available_at asc)
  where status = 'pending';

-- ----------------------------------------------------------------------------
-- arena_analytics_events — server-received product analytics. No camera data
-- is ever accepted; properties are capped in the RPC.
-- ----------------------------------------------------------------------------
create table public.arena_analytics_events (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users (id) on delete set null,
  event text not null,
  properties jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint arena_analytics_event_format check (event ~ '^[a-z][a-z0-9_]{1,48}$'),
  constraint arena_analytics_properties_object check (jsonb_typeof(properties) = 'object')
);

create index arena_analytics_event_idx
  on public.arena_analytics_events (event, created_at desc);

-- ----------------------------------------------------------------------------
-- Triggers
-- ----------------------------------------------------------------------------
create or replace function public.arena_handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.arena_profiles (user_id)
  values (new.id)
  on conflict (user_id) do nothing;
  return new;
end;
$$;

create trigger arena_on_auth_user_created
  after insert on auth.users
  for each row execute function public.arena_handle_new_user();

create or replace function public.arena_touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger arena_profiles_touch
  before update on public.arena_profiles
  for each row execute function public.arena_touch_updated_at();

create trigger arena_devices_touch
  before update on public.arena_devices
  for each row execute function public.arena_touch_updated_at();

-- Receipts, rating history and rep events must never change after insert.
create or replace function public.arena_forbid_mutation()
returns trigger
language plpgsql
as $$
begin
  raise exception using
    errcode = 'AR025',
    message = 'immutable row in ' || tg_table_name || ' cannot be modified or deleted';
end;
$$;

create trigger arena_receipts_immutable
  before update or delete on public.arena_receipts
  for each row execute function public.arena_forbid_mutation();

create trigger arena_rating_history_immutable
  before update or delete on public.arena_rating_history
  for each row execute function public.arena_forbid_mutation();

create trigger arena_match_events_immutable
  before update or delete on public.arena_match_events
  for each row execute function public.arena_forbid_mutation();

-- ----------------------------------------------------------------------------
-- RLS: enabled everywhere, no policies. Only the service role (which bypasses
-- RLS) reaches these tables, and only from server-only code.
-- ----------------------------------------------------------------------------
alter table public.arena_profiles enable row level security;
alter table public.arena_links enable row level security;
alter table public.arena_requests enable row level security;
alter table public.arena_matches enable row level security;
alter table public.arena_match_players enable row level security;
alter table public.arena_match_events enable row level security;
alter table public.arena_queue enable row level security;
alter table public.arena_receipts enable row level security;
alter table public.arena_rating_history enable row level security;
alter table public.arena_blocks enable row level security;
alter table public.arena_reports enable row level security;
alter table public.arena_devices enable row level security;
alter table public.arena_notification_outbox enable row level security;
alter table public.arena_analytics_events enable row level security;

-- Belt and braces: remove every client grant even if the platform default
-- privileges change later.
revoke all on all tables in schema public from anon, authenticated;
revoke all on all sequences in schema public from anon, authenticated;
revoke all on all functions in schema public from public, anon, authenticated;

alter default privileges in schema public revoke all on tables from anon, authenticated;
alter default privileges in schema public revoke all on sequences from anon, authenticated;
alter default privileges in schema public revoke all on functions from anon, authenticated;

-- The service role keeps explicit access for server-only code paths.
grant usage on schema public to service_role;
grant all on all tables in schema public to service_role;
grant all on all sequences in schema public to service_role;

-- ----------------------------------------------------------------------------
-- Avatar storage. Public bucket: avatars are deliberate public profile
-- content. Writes happen only through the service-role Edge Function.
-- ----------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'arena-avatars',
  'arena-avatars',
  true,
  2097152,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do nothing;
