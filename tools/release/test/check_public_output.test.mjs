import assert from 'node:assert/strict';
import { test } from 'node:test';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { checkPublicOutput } from '../check_public_output.mjs';

test('passing public-output fixture scans every nested file', t => {
  const root = mkdtempSync(join(tmpdir(),'arena-public-pass-'));
  t.after(()=>rmSync(root,{recursive:true,force:true}));
  mkdirSync(join(root,'assets'));
  writeFileSync(join(root,'index.html'),'<h1>Owner supplied content</h1>');
  writeFileSync(join(root,'assets','bundle.js'),'const ready = true;');
  assert.deepEqual(checkPublicOutput([root]),[]);
});
test('failing fixture rejects both markers in arbitrary nested/binary output', t => {
  const root = mkdtempSync(join(tmpdir(),'arena-public-fail-'));
  t.after(()=>rmSync(root,{recursive:true,force:true}));
  mkdirSync(join(root,'nested'));
  writeFileSync(join(root,'index.html'),'[[OWNER: legal entity]]');
  writeFileSync(join(root,'nested','asset.bin'),Buffer.from('prefix\0example.invalid\0suffix'));
  assert.equal(checkPublicOutput([root]).length,2);
});
test('required missing output fails closed',()=> {
  assert.equal(checkPublicOutput([{path:join(tmpdir(),'arena-missing-output-path'),required:true}]).length,1);
});
