"""Run Arena SQL contracts on an isolated native PostgreSQL database.

Supabase Auth/Storage table seams are minimal fixtures. This is SQL evidence,
not Auth service, pg_cron scheduling, hosted deployment or physical evidence.
Never point this tool at a user's database: it creates its own named database.
"""
import argparse
import re
import subprocess
import urllib.request
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--psql', default='C:/Program Files/PostgreSQL/18/bin/psql.exe')
parser.add_argument('--port', default='55432')
parser.add_argument('--tests-only', action='store_true')
args = parser.parse_args()
repo = Path(__file__).resolve().parents[2]
out = repo / 'artifacts/owner-acceptance/sql-evidence'
out.mkdir(parents=True, exist_ok=True)
database = 'arena_acceptance_20261023'
command = [args.psql, '-X', '-h', '127.0.0.1', '-p', args.port, '-U', 'postgres', '-v', 'ON_ERROR_STOP=1', '-At']

def sql(text, db=database):
    result = subprocess.run(command + ['-d', db], input=text, capture_output=True, text=True, encoding='utf-8')
    if result.returncode:
        raise RuntimeError(result.stderr[-3000:])
    return result.stdout

if not args.tests_only:
  sql(f'create database {database};', db='postgres')
  sql('''create schema extensions; create schema auth; create schema storage;
create role anon; create role authenticated; create role service_role bypassrls;
grant usage on schema public,extensions,auth,storage to anon,authenticated,service_role;
create table auth.users (id uuid primary key, instance_id uuid, aud text, role text,
email text, email_confirmed_at timestamptz, raw_app_meta_data jsonb, raw_user_meta_data jsonb,
created_at timestamptz, updated_at timestamptz);
create table auth.sessions(id uuid primary key, user_id uuid references auth.users(id) on delete cascade,
created_at timestamptz, updated_at timestamptz, not_after timestamptz);
create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
''')
if not args.tests_only:
  pgtap = urllib.request.urlopen('https://raw.githubusercontent.com/theory/pgtap/v1.3.4/sql/pgtap.sql.in', timeout=30).read().decode()
  pgtap = pgtap.replace('__VERSION__', '1.003004').replace('__OS__', 'windows')
  sql('set search_path=extensions,public;\n' + pgtap)
  for path in sorted((repo/'supabase/migrations').glob('*arena*.sql')):
    if 'maintenance_schedule' in path.name:
        continue  # Native Windows PostgreSQL lacks Supabase's pg_cron extension.
    sql(path.read_text(encoding='utf-8-sig'))
    print('APPLIED', path.name)
failed = []
total = 0
for path in sorted((repo/'supabase/tests').glob('arena*.sql')):
    if 'maintenance_schedule' in path.name:
        continue
    source = re.sub(r'create extension if not exists pgtap with schema extensions;', '', path.read_text(encoding='utf-8-sig'), flags=re.I)
    result = sql('set search_path=public,extensions;\n'+source)
    (out/(path.stem+'.tap.txt')).write_text(result, encoding='utf-8')
    assertions = re.findall(r'^(?:not )?ok \d+', result, re.M)
    errors = re.findall(r'^not ok .*|^# (?:Failed|Looks like).*', result, re.M)
    total += len(assertions)
    print(path.name, len(assertions), 'assertions', 'FAIL' if errors else 'PASS')
    failed.extend(errors)
print('TOTAL', total, 'assertions;', len(failed), 'failures')
for error in failed: print(error)
raise SystemExit(bool(failed))
