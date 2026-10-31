import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';

const html = readFileSync(new URL('./launch-board.html', import.meta.url), 'utf8');
const names = ['soloAttempts', 'soloCompleted', 'practiceAttempts', 'practiceAbandoned', 'maturePlayers', 'returnedPlayers'];
const inputs = Object.fromEntries(names.map(name => [name, { value: '' }]));
const outputs = Object.fromEntries(['solo-rate', 'practice-rate', 'return-rate', 'metrics-error'].map(id => [id, { value: '', textContent: '', setAttribute() {} }]));
let submit;
const form = { elements: { namedItem: name => inputs[name] }, addEventListener: (_, callback) => { submit = callback; } };
for (const name of names) assert.ok(html.includes(`name="${name}"`));
runInNewContext(html.match(/<script>([\s\S]*?)<\/script>/)[1], {
  document: { getElementById: id => id === 'metrics-form' ? form : outputs[id] },
});
submit({ preventDefault() {} });
assert.equal(outputs['solo-rate'].value, 'Unobserved');
Object.assign(inputs.soloAttempts, { value: '20' });
Object.assign(inputs.soloCompleted, { value: '15' });
submit({ preventDefault() {} });
assert.equal(outputs['solo-rate'].value, '75.0% · 15/20');
inputs.soloCompleted.value = '21';
submit({ preventDefault() {} });
assert.equal(outputs['solo-rate'].value, 'Invalid totals');
assert.ok(outputs['metrics-error'].textContent);
console.log('Launch board: 3 calculation/validation cases passed.');
