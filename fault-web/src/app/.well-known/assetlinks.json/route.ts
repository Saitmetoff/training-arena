// Website publication alone does not validate Android App Links.
export function GET(){
  const fingerprints=(process.env.FAULT_ANDROID_CERT_SHA256||'').split(',').map(v=>v.trim().toUpperCase()).filter(Boolean);
  if(!fingerprints.length||fingerprints.some(v=>!/^([0-9A-F]{2}:){31}[0-9A-F]{2}$/.test(v)))return Response.json({error:'release_certificate_required'},{status:503,headers:{'Cache-Control':'no-store'}});
  return Response.json([{relation:['delegate_permission/common.handle_all_urls'],target:{namespace:'android_app',package_name:'app.trainingarena.mobile',sha256_cert_fingerprints:fingerprints}}],{headers:{'Cache-Control':'public, max-age=300'}});
}
