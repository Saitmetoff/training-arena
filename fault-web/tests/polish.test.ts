/// <reference types="node" />
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createSiteMetadata } from '../src/lib/metadata';
import { formatVtt } from '../src/lib/captions';

const TITLE = 'Fault — Give your next set a reason.';
const DESCRIPTION =
  'Fault is being built for solo push-up practice. Enter your own rep count and keep a record on your phone. Android first.';

type Image = { url: string; width: number; height: number; alt: string };

test('createSiteMetadata exposes the approved preview metadata only', () => {
  const metadata = createSiteMetadata('https://fault.example');
  assert.equal(metadata.title, TITLE);
  assert.equal(metadata.description, DESCRIPTION);
  assert.equal(String(metadata.metadataBase), 'https://fault.example/');
  assert.deepEqual(metadata.alternates, { canonical: '/' });
  assert.deepEqual(metadata.robots, { index: false, follow: false });
  assert.deepEqual(metadata.icons, { icon: '/icon.svg' });

  const og = metadata.openGraph as unknown as { type: string; url: string; images: Image[] };
  assert.equal(og.type, 'website');
  assert.equal(og.url, '/');
  assert.equal(og.images[0].url, '/social-preview.png');
  assert.equal(og.images[0].width, 1200);
  assert.equal(og.images[0].height, 630);
  assert.ok(og.images[0].alt.length > 20);

  const twitter = metadata.twitter as unknown as { card: string; images: string[] };
  assert.equal(twitter.card, 'summary_large_image');
  assert.deepEqual(twitter.images, ['/social-preview.png']);
});

test('createSiteMetadata makes no app-store, availability or metric claims', () => {
  const serialized = JSON.stringify(createSiteMetadata('https://fault.example'));
  assert.equal('appLinks' in createSiteMetadata('https://fault.example'), false);
  assert.equal(/app[_-]?store|google play|aggregateRating|downloads?/i.test(serialized), false);
});

test('createSiteMetadata rejects a non-absolute site URL', () => {
  assert.throws(() => createSiteMetadata('not-a-url'), TypeError);
});

test('formatVtt emits a valid header and ordered cues', () => {
  const vtt = formatVtt([
    { start: 1, end: 4.5, text: 'Complete your push-ups.' },
    { start: 5, end: 7, text: 'Enter your count.' },
  ]);
  assert.equal(
    vtt,
    'WEBVTT\n\n1\n00:00:01.000 --> 00:00:04.500\nComplete your push-ups.\n\n2\n00:00:05.000 --> 00:00:07.000\nEnter your count.\n',
  );
});

test('formatVtt rounds timestamps once with carry across seconds and minutes', () => {
  const vtt = formatVtt([{ start: 59.9996, end: 3599.9996, text: 'Carry' }]);
  assert.match(vtt, /00:01:00\.000 --> 01:00:00\.000/);
});

test('formatVtt normalizes CRLF and blank lines but keeps multiline text', () => {
  const vtt = formatVtt([{ start: 0, end: 2, text: 'First line\r\n\r\n\r\nSecond line\u0007' }]);
  assert.equal(vtt, 'WEBVTT\n\n1\n00:00:00.000 --> 00:00:02.000\nFirst line\nSecond line\n');
});

test('formatVtt escapes markup-significant characters', () => {
  const vtt = formatVtt([{ start: 0, end: 1, text: 'A & B < C > D' }]);
  assert.match(vtt, /A &amp; B &lt; C &gt; D/);
});

test('formatVtt allows touching cues and empty input', () => {
  const vtt = formatVtt([
    { start: 0, end: 1, text: 'a' },
    { start: 1, end: 2, text: 'b' },
  ]);
  assert.match(vtt, /00:00:01\.000 --> 00:00:02\.000/);
  assert.equal(formatVtt([]), 'WEBVTT\n');
});

test('formatVtt rejects injection, overlap and invalid timings', () => {
  assert.throws(
    () => formatVtt([{ start: 0, end: 1, text: '00:00:01.000 --> 00:00:02.000' }]),
    RangeError,
  );
  assert.throws(
    () => formatVtt([{ start: 0, end: 3, text: 'a' }, { start: 2.5, end: 4, text: 'b' }]),
    RangeError,
  );
  assert.throws(() => formatVtt([{ start: -1, end: 1, text: 'a' }]), RangeError);
  assert.throws(() => formatVtt([{ start: 2, end: 2, text: 'a' }]), RangeError);
  assert.throws(() => formatVtt([{ start: Number.NaN, end: 1, text: 'a' }]), RangeError);
});
test('formatVtt rejects sub-millisecond zero-length cues and empty caption payloads',()=>{
 assert.throws(()=>formatVtt([{start:.0001,end:.0002,text:'Rounded away'}]),RangeError);
 assert.throws(()=>formatVtt([{start:0,end:1,text:'\r\n\u0007'}]),RangeError);
 assert.throws(()=>formatVtt([{start:0,end:Number.MAX_VALUE,text:'Unsafe precision'}]),RangeError);
});
