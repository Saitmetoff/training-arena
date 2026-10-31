-- The no-push beta still needs expiry/outage sweeps when everyone goes offline.
-- Reuse the existing database function; no HTTP bearer or FCM secret is needed.
create extension if not exists pg_cron with schema pg_catalog;
select cron.schedule('arena-maintenance', '* * * * *',
  'select public.arena_maintenance();');
revoke usage on schema cron from anon, authenticated;
