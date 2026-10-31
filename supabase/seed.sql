-- ============================================================================
-- Training Arena — LOCAL DEVELOPMENT FIXTURES ONLY
-- ============================================================================
-- Every row below is invented test data:
--   * emails use the reserved `.invalid` TLD and cannot receive mail;
--   * usernames start with `fixture_`;
--   * tokens contain the word `fixture` and are deliberately guessable;
--   * the password is documented and fake.
-- This file runs only on `supabase db reset` (local). It is never applied by
-- `supabase db push`, and it must never be loaded into a hosted project.
-- ============================================================================

-- Sessions are inserted with fixed ids so local end-to-end scripts can sign a
-- development JWT with sub/session_id without touching Auth.
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change
)
values
  (
    '00000000-0000-0000-0000-000000000000',
    '11111111-1111-4111-8111-111111111111',
    'authenticated', 'authenticated', 'fixture.alice@arena.invalid',
    extensions.crypt('fixture-password-only', extensions.gen_salt('bf')), now(),
    '{"provider":"email","providers":["email"]}', '{}', now(), now(),
    '', '', '', ''
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '22222222-2222-4222-8222-222222222222',
    'authenticated', 'authenticated', 'fixture.bob@arena.invalid',
    extensions.crypt('fixture-password-only', extensions.gen_salt('bf')), now(),
    '{"provider":"email","providers":["email"]}', '{}', now(), now(),
    '', '', '', ''
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '33333333-3333-4333-8333-333333333333',
    'authenticated', 'authenticated', 'fixture.carol@arena.invalid',
    extensions.crypt('fixture-password-only', extensions.gen_salt('bf')), now(),
    '{"provider":"email","providers":["email"]}', '{}', now(), now(),
    '', '', '', ''
  )
on conflict (id) do nothing;

insert into auth.identities (
  provider_id, user_id, identity_data, provider, last_sign_in_at,
  created_at, updated_at
)
values
  (
    '11111111-1111-4111-8111-111111111111',
    '11111111-1111-4111-8111-111111111111',
    '{"sub":"11111111-1111-4111-8111-111111111111","email":"fixture.alice@arena.invalid"}',
    'email', now(), now(), now()
  ),
  (
    '22222222-2222-4222-8222-222222222222',
    '22222222-2222-4222-8222-222222222222',
    '{"sub":"22222222-2222-4222-8222-222222222222","email":"fixture.bob@arena.invalid"}',
    'email', now(), now(), now()
  ),
  (
    '33333333-3333-4333-8333-333333333333',
    '33333333-3333-4333-8333-333333333333',
    '{"sub":"33333333-3333-4333-8333-333333333333","email":"fixture.carol@arena.invalid"}',
    'email', now(), now(), now()
  )
on conflict (provider_id, provider) do nothing;

insert into auth.sessions (id, user_id, created_at, updated_at, not_after)
values
  ('91111111-1111-4111-8111-111111111111', '11111111-1111-4111-8111-111111111111', now(), now(), now() + interval '30 days'),
  ('92222222-2222-4222-8222-222222222222', '22222222-2222-4222-8222-222222222222', now(), now(), now() + interval '30 days'),
  ('93333333-3333-4333-8333-333333333333', '33333333-3333-4333-8333-333333333333', now(), now(), now() + interval '30 days')
on conflict (id) do nothing;

-- Profiles are created by the auth trigger; fill in the fixture identity.
update public.arena_profiles
set username = 'fixture_alice', rating = 1042, ranked_wins = 7, ranked_battles = 11
where user_id = '11111111-1111-4111-8111-111111111111';

update public.arena_profiles
set username = 'fixture_bob', rating = 1000, ranked_wins = 0, ranked_battles = 0
where user_id = '22222222-2222-4222-8222-222222222222';

update public.arena_profiles
set username = 'fixture_carol', rating = 988, ranked_wins = 3, ranked_battles = 10
where user_id = '33333333-3333-4333-8333-333333333333';

-- Durable challenge links with obviously fake, guessable tokens.
insert into public.arena_links (token, user_id)
values
  ('fixturealice', '11111111-1111-4111-8111-111111111111'),
  ('fixturebobbb', '22222222-2222-4222-8222-222222222222'),
  ('fixturecarol', '33333333-3333-4333-8333-333333333333')
on conflict (token) do nothing;

-- One pending invitation for local manual testing (bob -> alice).
insert into public.arena_requests (
  id, link_token, sender_id, recipient_id, expires_at
)
values (
  '44444444-4444-4444-8444-444444444444',
  'fixturebobbb',
  '22222222-2222-4222-8222-222222222222',
  '11111111-1111-4111-8111-111111111111',
  now() + interval '24 hours'
)
on conflict (id) do nothing;

-- One fake device token so the local dispatcher smoke test has a target.
insert into public.arena_devices (token, user_id, platform)
values ('fixture-device-token-alice', '11111111-1111-4111-8111-111111111111', 'android')
on conflict (token) do nothing;
