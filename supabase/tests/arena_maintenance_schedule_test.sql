begin;
select extensions.plan(3);
select extensions.ok(exists(select 1 from pg_extension where extname = 'pg_cron'),
  'database maintenance has a scheduler');
select extensions.is((select schedule from cron.job where jobname = 'arena-maintenance'),
  '* * * * *', 'maintenance sweeps every minute even with no clients online');
select extensions.ok(exists(select 1 from cron.job where jobname = 'arena-maintenance'
  and command = 'select public.arena_maintenance();' and active and username = 'postgres'),
  'the job calls only existing maintenance as the database owner');
select * from extensions.finish();
rollback;
