"""Apply only the explicit marketing guardrails; preserve the owner's draft."""
from pathlib import Path
import difflib
import hashlib

root = Path(__file__).resolve().parents[1]
path = root / 'docs/social/UGC_VIDEO_GENERATION_STRATEGY.md'
before_bytes = path.read_bytes()
before = before_bytes.decode('utf-8')
after = before
replacements = {
    '**4 Gemini Pro accounts**': '**one Gemini Pro account per person**',
    '**4 Gemini Pro Accounts**': '**One Gemini Pro account per person**',
    '4 distinct developer quotas': 'one provider allowance per person',
    'Gemini[4 Gemini Pro Accounts / Imagen 3]': 'Gemini[One Gemini Pro account per person / Imagen 3]',
    'Use Gemini Pro Accounts 1 & 2': 'Use one Gemini Pro account per person',
}
for old, new in replacements.items():
    if old not in after:
        raise SystemExit('Expected quota-multiplication wording not found: ' + old)
    after = after.replace(old, new)
marker = '## 1. Executive Summary & Objective'
gates = '''## Hard gates

- No video may show a phone counting reps or any counter UI until `qa/camera/beta_device_results.json` holds real devices with status `passed`.
- One account per person per provider. Multiplying free quotas with multiple accounts is not permitted.
- Before using an AI video tool commercially, record its commercial-use terms URL and the date checked. Without that record the tool is not allowed.

'''
if marker not in after:
    raise SystemExit('Expected insertion point not found')
after = after.replace(marker, gates + marker, 1)
path.write_bytes(after.encode('utf-8'))
patch = ''.join(difflib.unified_diff(before.splitlines(keepends=True), after.splitlines(keepends=True),
    fromfile='a/docs/social/UGC_VIDEO_GENERATION_STRATEGY.md',
    tofile='b/docs/social/UGC_VIDEO_GENERATION_STRATEGY.md'))
(root / 'docs/audit/WP3_UGC_GUARDRAILS.patch').write_text(patch, encoding='utf-8', newline='')
print('Original owner draft SHA256:', hashlib.sha256(before_bytes).hexdigest())
print('Added Hard gates and removed only the five quota-multiplication phrases.')
print('All other original draft content preserved. Own diff saved as WP3_UGC_GUARDRAILS.patch.')
