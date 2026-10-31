"""Archive only explicit deployable sources; exclude credentials, logs and data."""
from pathlib import Path
import hashlib
import json
import zipfile

app = Path(__file__).resolve().parent.parent
repo = app.parent
files = []
for directory in ('src', 'public', 'emails'):
    files.extend(p for p in (app / directory).rglob('*') if p.is_file())
for name in ('package.json', 'package-lock.json', 'next.config.ts', 'next-env.d.ts', 'tsconfig.json', 'vercel.json'):
    files.append(app / name)
files.extend(repo / 'supabase/migrations' / name for name in (
    '20261004112705_fault_waitlist_stage3.sql',
    '20261004161500_fault_waitlist_preview_isolation.sql',
    '20261020173359_fault_waitlist_preserve_complaint_holds.sql'))
manifest = []
archive = repo / 'tmp/fault-opencode/05-validated-source.zip'
with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as bundle:
    for path in sorted(files):
        if not path.resolve().is_relative_to(repo.resolve()):
            raise ValueError('Source escaped intended workspace')
        relative = path.relative_to(repo).as_posix()
        data = path.read_bytes()
        manifest.append({'path': relative, 'sha256': hashlib.sha256(data).hexdigest(), 'bytes': len(data)})
        bundle.writestr(relative, data)
fingerprint = hashlib.sha256(json.dumps(manifest, sort_keys=True).encode()).hexdigest()
(app / 'test-results/stage5/source-manifest.json').write_text(json.dumps({'fingerprint': fingerprint, 'files': manifest}, indent=2), encoding='utf-8')
print(f'Archived {len(files)} explicit source files; manifest fingerprint {fingerprint}. No credentials/data included.')
