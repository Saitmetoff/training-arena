import { readFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

export const cameraChecks = [
  'preview_alignment', 'rotation', 'mirroring', 'side_pushups', 'front_pushups',
  'side_squats', 'partial_framing', 'low_light', 'missing_joints', 'half_depth',
  'bounce', 'collapse', 'tracking_recovery', 'lifecycle', 'permission_denial',
  'low_confidence', 'readable_too_close', 'offline_solo', 'save_restart', 'save_failure',
];

// This checks the signed record's completeness, not physical accuracy.
export function checkCameraEvidence(record, version = 'arena-counter/1.2.1') {
  const failures = [];
  if (record?.status !== 'passed' || record.counter_version !== version ||
      !/^[a-f0-9]{40}$/.test(record.tested_commit ?? '') ||
      !record.reviewer?.trim() || !/^\d{4}-\d{2}-\d{2}$/.test(record.reviewed_at ?? '')) {
    failures.push('A reviewed passing record must identify the tested commit and counter version.');
  }
  const devices = Array.isArray(record?.devices) ? record.devices : [];
  if (devices.length < 2 || new Set(devices.map(d => d.model)).size < 2) {
    failures.push('Two distinct physical phone models are required.');
  }
  for (const device of devices) {
    if (device.physical !== true || !device.model?.trim() || !device.android ||
        device.unresolved_discrepancies !== 0 ||
        cameraChecks.some(key => device.checks?.[key] !== 'passed')) {
      failures.push(`${device.model ?? 'Unknown phone'}: device checks are incomplete.`);
    }
    if (!Array.isArray(device.rounds) || !device.rounds.length ||
        device.rounds.some(r => !r.exercise || !r.view ||
          !Number.isInteger(r.human) || r.human < 0 ||
          !Number.isInteger(r.app) || r.app < 0 || r.false_positives !== 0 ||
          (r.app !== r.human && !r.investigation?.trim()))) {
      failures.push(`${device.model ?? 'Unknown phone'}: record every observed count and discrepancy.`);
    }
  }
  return failures;
}

if (process.argv[1] && pathToFileURL(resolve(process.argv[1])).href === import.meta.url) {
  const record = JSON.parse(readFileSync('qa/camera/beta_device_results.json', 'utf8'));
  const version = readFileSync('app/lib/camera/camera_types.dart', 'utf8')
      .match(/arenaCounterVersion\s*=\s*'([^']+)'/)?.[1];
  const failures = checkCameraEvidence(record, version);
  if (!failures.length) {
    try {
      execFileSync('git', ['diff', '--quiet', record.tested_commit, 'HEAD', '--', 'app']);
      execFileSync('git', ['diff', '--quiet', 'HEAD', '--', 'app']);
    } catch {
      failures.push('App changes since the tested commit require another device check.');
    }
  }
  if (failures.length) {
    console.error(failures.join('\n'));
    process.exitCode = 1;
  } else console.log('Reviewed two-phone evidence is complete; app sources match the tested commit.');
}
