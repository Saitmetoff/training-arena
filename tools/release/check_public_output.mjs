#!/usr/bin/env node
// Release publication gate. Owner placeholders remain in source until supplied.
import { existsSync, readdirSync, readFileSync, lstatSync } from 'node:fs';
import { dirname, join, resolve, relative } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const repo = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const forbidden = [Buffer.from('[[OWNER:'), Buffer.from('example.invalid')];

export function checkPublicOutput(roots) {
  const failures = [];
  function visit(path, filter) {
    const stat = lstatSync(path);
    if (stat.isSymbolicLink()) {
      failures.push(`${path}: unresolved symbolic link in public output`);
      return;
    }
    if (stat.isDirectory()) {
      for (const entry of readdirSync(path).sort()) visit(join(path, entry), filter);
    } else if (stat.isFile() && (!filter || filter(path))) {
      const bytes = readFileSync(path);
      if (forbidden.some(token => bytes.includes(token))) {
        failures.push(`${path}: owner placeholder or example.invalid remains`);
      }
    }
  }
  for (const root of roots) {
    const item = typeof root === 'string' ? { path: root, required: true } : root;
    if (!existsSync(item.path)) {
      if (item.required) failures.push(`${item.path}: public output directory missing`);
    } else visit(item.path, item.filter);
  }
  return failures;
}

if (process.argv[1] && pathToFileURL(resolve(process.argv[1])).href === import.meta.url) {
  const requested = process.argv.slice(2);
  const roots = requested.length ? requested.map(path => resolve(path)) : [
    { path: join(repo,'challenge-web'), required: true },
    { path: join(repo,'fault-web/public'), required: true },
    { path: join(repo,'fault-web/out'), required: false },
    { path: join(repo,'fault-web/.next/static'), required: false },
    { path: join(repo,'fault-web/.next/server/app'), required: false,
      filter: path => /\.(html|rsc|body|txt)$/.test(path) },
  ];
  const failures = checkPublicOutput(roots);
  for (const failure of failures) console.error(relative(repo, failure));
  if (failures.length) {
    console.error(`public output check failed: ${failures.length} file(s)`);
    process.exit(1);
  }
  console.log('public output check passed');
}
