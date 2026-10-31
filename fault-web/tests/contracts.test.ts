/// <reference types="node" />
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { canonicalEmail, sanitizeTouch, sanitizeAttribution, safeBrowserEvent } from '../src/lib/contracts';
import { EVENT_NAMES, EVENT_DEFINITIONS, CONFIRMATION_FUNNEL, CONVERSION_WINDOW_DAYS } from '../src/lib/event-map';

const NOW = Date.parse('2026-10-04T12:00:00.000Z');
const DAY = 86_400_000;

function validTouch(overrides: Record<string, unknown> = {}) {
  return {
    content_id: 'fault-solo-001',
    creative_id: 'fault-solo-001-vertical-a',
    utm_source: 'instagram',
    utm_medium: 'organic-social',
    utm_campaign: 'solo-prelaunch',
    utm_content: 'fault-solo-001-vertical-a',
    timestamp: new Date(NOW - 3_600_000).toISOString(),
    ...overrides,
  };
}

test('canonicalEmail trims, lowercases and preserves plus/dot distinctions', () => {
  assert.equal(canonicalEmail('  Foo.Bar+Tag@Example.COM  '), 'foo.bar+tag@example.com');
  assert.equal(canonicalEmail('Foo.Bar+Tag@Example.COM'), canonicalEmail('foo.bar+tag@example.com'));
  assert.notEqual(canonicalEmail('a.b@example.com'), canonicalEmail('ab@example.com'));
  assert.notEqual(canonicalEmail('user+one@example.com'), canonicalEmail('user+two@example.com'));
});

test('canonicalEmail rejects malformed, overlong and control-character input', () => {
  assert.equal(canonicalEmail(42), null);
  assert.equal(canonicalEmail('not-an-email'), null);
  assert.equal(canonicalEmail('a@@b.com'), null);
  assert.equal(canonicalEmail(`${'a'.repeat(65)}@example.com`), null);
  assert.equal(canonicalEmail(`${'a'.repeat(60)}@${'b'.repeat(190)}.com`), null);
  assert.equal(canonicalEmail('a@example.com\r\nBcc: x@example.com'), null);
  assert.equal(canonicalEmail('a@example.com\n'), null);
});

test('sanitizeTouch accepts a registered campaign touch', () => {
  const result = sanitizeTouch(validTouch(), NOW);
  assert.deepEqual(result, validTouch());
});

test('sanitizeTouch rejects unknown ids and email-valued fields', () => {
  assert.equal(sanitizeTouch(validTouch({ content_id: 'unknown' }), NOW), null);
  assert.equal(sanitizeTouch(validTouch({ creative_id: 'fault-solo-001-vertical-z' }), NOW), null);
  assert.equal(sanitizeTouch(validTouch({ utm_source: 'facebook' }), NOW), null);
  assert.equal(sanitizeTouch(validTouch({ utm_content: 'person@example.com' }), NOW), null);
  assert.equal(sanitizeTouch(validTouch({ email: 'person@example.com' }), NOW), null);
  assert.equal(sanitizeTouch('person@example.com', NOW), null);
});

test('sanitizeTouch enforces the 30-day window and rejects future times', () => {
  assert.ok(sanitizeTouch(validTouch({ timestamp: new Date(NOW - 30 * DAY + 1000).toISOString() }), NOW));
  assert.equal(sanitizeTouch(validTouch({ timestamp: new Date(NOW - 30 * DAY - 1000).toISOString() }), NOW), null);
  assert.equal(sanitizeTouch(validTouch({ timestamp: new Date(NOW + 120_000).toISOString() }), NOW), null);
  assert.equal(sanitizeTouch(validTouch({ timestamp: 'not-a-time' }), NOW), null);
});

test('sanitizeAttribution credits the last eligible touch or direct', () => {
  const both = sanitizeAttribution({ first: validTouch(), last: validTouch() }, NOW);
  assert.equal(both.credit, 'last-eligible-touch-30d');
  assert.ok(both.first && both.last);

  assert.deepEqual(sanitizeAttribution({ first: null, last: null }, NOW), { first: null, last: null, credit: 'direct' });
  assert.deepEqual(sanitizeAttribution({}, NOW), { first: null, last: null, credit: 'direct' });

  const badLast = sanitizeAttribution({ first: validTouch(), last: { content_id: 'unknown' } }, NOW);
  assert.ok(badLast.first);
  assert.equal(badLast.last, null);
  assert.equal(badLast.credit, 'direct');
});

test('safeBrowserEvent accepts only browser-owned events with a UUID visitor', () => {
  const visitorId = '123e4567-e89b-42d3-a456-426614174000';
  assert.equal(safeBrowserEvent({ event: 'landing_view', visitorId })?.event, 'landing_view');
  assert.equal(safeBrowserEvent({ event: 'demo_play', visitorId })?.event, 'demo_play');
  assert.equal(safeBrowserEvent({ event: 'share_click', visitorId })?.event, 'share_click');

  const touch = validTouch();
  const withTouch = safeBrowserEvent({ event: 'share_click', visitorId, touch });
  assert.ok(withTouch?.touch);
});

test('safeBrowserEvent rejects forged server events, bad ids and extra fields', () => {
  const visitorId = '123e4567-e89b-42d3-a456-426614174000';
  assert.equal(safeBrowserEvent({ event: 'waitlist_submit', visitorId }), null);
  assert.equal(safeBrowserEvent({ event: 'waitlist_confirmed', visitorId }), null);
  assert.equal(safeBrowserEvent(null), null);
  assert.equal(safeBrowserEvent({ event: 'landing_view', visitorId: 'not-a-uuid' }), null);
  assert.equal(safeBrowserEvent({ event: 'landing_view', visitorId: 'person@example.com' }), null);
  assert.equal(safeBrowserEvent({ event: 'landing_view', visitorId, email: 'person@example.com' }), null);
  assert.equal(safeBrowserEvent({ event: 'landing_view', visitorId, token: 'secret' }), null);
  assert.equal(safeBrowserEvent({ event: 'landing_view', visitorId, touch: { content_id: 'unknown' } }), null);
});

test('event map declares the tuple and server-only ownership', () => {
  assert.deepEqual([...EVENT_NAMES], ['landing_view', 'demo_play', 'waitlist_submit', 'waitlist_confirmed', 'share_click']);

  const byName = Object.fromEntries(EVENT_DEFINITIONS.map((definition) => [definition.name, definition]));
  assert.equal(byName.landing_view.owner, 'browser');
  assert.equal(byName.demo_play.owner, 'browser');
  assert.equal(byName.share_click.owner, 'browser');
  assert.equal(byName.waitlist_submit.owner, 'server');
  assert.equal(byName.waitlist_confirmed.owner, 'server');

  for (const definition of EVENT_DEFINITIONS) {
    assert.ok(EVENT_NAMES.includes(definition.name));
    assert.equal(typeof definition.transition, 'string');
    assert.ok(definition.transition.length > 0);
    assert.ok(definition.properties.every((property) => typeof property === 'string'));
  }
  assert.equal(EVENT_DEFINITIONS.length, EVENT_NAMES.length);
});

test('confirmation funnel preserves order and window', () => {
  assert.deepEqual([...CONFIRMATION_FUNNEL], ['landing_view', 'waitlist_submit', 'waitlist_confirmed']);
  assert.equal(CONFIRMATION_FUNNEL[0], 'landing_view');
  assert.equal(CONFIRMATION_FUNNEL[CONFIRMATION_FUNNEL.length - 1], 'waitlist_confirmed');
  assert.equal(CONVERSION_WINDOW_DAYS, 30);
});
