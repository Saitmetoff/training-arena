import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {GET} from '../src/app/.well-known/assetlinks.json/route';
test('legacy copies preserve resolver and deletion code, and anchor nested challenge assets',()=>{
 for(const file of ['app.js','link.js','delete_account.js','config.js','pages.js'])assert.equal(readFileSync(`public/legacy/${file}`,'utf8'),readFileSync(`../challenge-web/${file}`,'utf8'));
 const html=readFileSync('public/legacy/index.html','utf8');assert.match(html,/<base href="\/legacy\/">/);assert.doesNotMatch(html,/Camera-counted/);
});
test('App Links fail closed without a real certificate; configured identity retains package',async()=>{
 const before=process.env.FAULT_ANDROID_CERT_SHA256;
 try{
  delete process.env.FAULT_ANDROID_CERT_SHA256;assert.equal(GET().status,503);
  process.env.FAULT_ANDROID_CERT_SHA256='REPLACE_WITH_RELEASE_CERT_SHA256_FINGERPRINT';assert.equal(GET().status,503);
  process.env.FAULT_ANDROID_CERT_SHA256=Array(32).fill('AB').join(':');
  const response=GET();assert.equal(response.status,200);
  const body=await response.json();assert.equal(body[0].target.package_name,'app.trainingarena.mobile');assert.equal(body[0].target.sha256_cert_fingerprints[0],process.env.FAULT_ANDROID_CERT_SHA256);
 }finally{if(before===undefined)delete process.env.FAULT_ANDROID_CERT_SHA256;else process.env.FAULT_ANDROID_CERT_SHA256=before;}
});
