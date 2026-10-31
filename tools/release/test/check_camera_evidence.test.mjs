import { test } from 'node:test';
import assert from 'node:assert/strict';
import { checkCameraEvidence, cameraChecks } from '../check_camera_evidence.mjs';

const passing = () => ({
  status: 'passed', tested_commit: 'a'.repeat(40), counter_version: 'arena-counter/1.2.1',
  reviewer: 'Device QA', reviewed_at: '2026-09-30',
  devices: ['Redmi 10', 'Second phone'].map(model => ({
    model, physical: true, android: '13', unresolved_discrepancies: 0,
    checks: Object.fromEntries(cameraChecks.map(key => [key, 'passed'])),
    rounds: [{exercise: 'pushups', view: 'side', human: 20, app: 20, false_positives: 0}],
  })),
});

test('unfinished or emulator-only camera evidence cannot enable release counting', () => {
  assert.ok(checkCameraEvidence({status: 'blocked', devices: []}).length);
  const record = passing();
  record.devices[1].physical = false;
  assert.ok(checkCameraEvidence(record).length);
});
test('both phones need all checks and resolved discrepancies', () => {
  const record = passing();
  assert.deepEqual(checkCameraEvidence(record), []);
  record.devices[1].checks.partial_framing = 'pending';
  record.devices[0].rounds[0].false_positives = 1;
  assert.ok(checkCameraEvidence(record).length >= 2);
});
