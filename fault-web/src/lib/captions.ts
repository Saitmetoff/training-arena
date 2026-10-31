// WEBVTT formatting contract. Produces only what callers supply; no invented captions.

export type Cue = {start: number; end: number; text: string};

function timestamp(seconds: number): string {
  const total = Math.round(seconds * 1000);
  const ms = total % 1000;
  const whole = Math.floor(total / 1000);
  const s = whole % 60;
  const m = Math.floor(whole / 60) % 60;
  const h = Math.floor(whole / 3600);
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}.${String(ms).padStart(3, '0')}`;
}

function normalizeText(text: string, index: number): string {
  const lines = text.replace(/\r\n?/g, '\n');
  if (lines.includes('-->')) throw new RangeError(`Cue ${index} text contains a timing injection.`);
  const clean = lines
    .replace(/[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f]/g, '')
    .replace(/[ \t]+\n/g, '\n')
    .replace(/\n[ \t]*(?:\n[ \t]*)+/g, '\n')
    .trim();
  if (!clean) throw new RangeError(`Cue ${index} text is empty.`);
  return clean.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

export function formatVtt(cues: Cue[]): string {
  let previousEnd = 0;
  const blocks = cues.map((cue, index) => {
    if (!Number.isFinite(cue.start) || !Number.isFinite(cue.end)) {
      throw new RangeError(`Cue ${index} has a non-finite timestamp.`);
    }
    if (cue.start < 0 || Math.round(cue.end*1000) <= Math.round(cue.start*1000) || !Number.isSafeInteger(Math.round(cue.end*1000))) {
      throw new RangeError(`Cue ${index} must have end greater than start and non-negative seconds.`);
    }
    if (index > 0 && Math.round(cue.start*1000) < Math.round(previousEnd*1000)) {
      throw new RangeError(`Cue ${index} overlaps the previous cue.`);
    }
    previousEnd = cue.end;
    return `${index + 1}\n${timestamp(cue.start)} --> ${timestamp(cue.end)}\n${normalizeText(cue.text, index)}`;
  });
  return `${['WEBVTT', ...blocks].join('\n\n')}\n`;
}
