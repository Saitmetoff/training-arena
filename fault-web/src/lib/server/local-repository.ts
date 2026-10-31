// Explicit loopback test harness only; never selected in Vercel or hosted runtime.
import {PGlite} from '@electric-sql/pglite';
import {readFile,mkdir} from 'node:fs/promises';
import path from 'node:path';
import type {Repository} from './repository';
export const SQL_PATH=path.resolve(process.cwd(),'../supabase/migrations/20261004112705_fault_waitlist_stage3.sql');
export const HOLD_MIGRATION_PATH=path.resolve(process.cwd(),'../supabase/migrations/20261020173359_fault_waitlist_preserve_complaint_holds.sql');
export async function createLocalDatabase(directory?:string) {
  const db=new PGlite(directory);await db.waitReady;
  const existing=await db.query<{exists:boolean}>("select exists(select 1 from pg_namespace where nspname='fault_waitlist') as exists");
  if(!existing.rows[0].exists) {
    await db.exec('create role anon; create role authenticated; create role service_role bypassrls;');
    await db.exec(await readFile(SQL_PATH,'utf8'));
  }
  const preview=await db.query<{exists:boolean}>("select exists(select 1 from pg_namespace where nspname='fault_waitlist_preview') as exists");
  if(!preview.rows[0].exists)await db.exec(await readFile(path.resolve(process.cwd(),'../supabase/migrations/20261004161500_fault_waitlist_preview_isolation.sql'),'utf8'));
  // CREATE OR REPLACE is safe for retained local fixtures as well as fresh tests.
  await db.exec(await readFile(HOLD_MIGRATION_PATH,'utf8'));
  const repository:Repository={async command(op,args) {
    const data=await db.query<{data:Record<string,unknown>}>('select public.fault_waitlist_command($1,$2::jsonb) as data',[op,JSON.stringify(args)]);
    return data.rows[0].data;
  }};
  return {db,repository};
}
let instance:ReturnType<typeof createLocalDatabase>|undefined;
export async function localRepository() {
  await mkdir(path.resolve('.local'),{recursive:true});
  return (await (instance??=createLocalDatabase(path.resolve('.local/db')))).repository;
}
