/**
 * Minimal DevTools-protocol client used by capture.mjs and smoke.mjs.
 * No external dependencies. Requires Node 21+ for the global WebSocket.
 */

import { spawn } from 'node:child_process';
import { existsSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';

const BROWSER_CANDIDATES = [
  process.env.ARENA_BROWSER,
  'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
  'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe',
  'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
  'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/usr/bin/google-chrome',
  '/usr/bin/chromium',
].filter(Boolean);

export const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

export function findBrowser() {
  return BROWSER_CANDIDATES.find((candidate) => existsSync(candidate)) || null;
}

export async function launchBrowser() {
  const browserPath = findBrowser();
  if (!browserPath) {
    throw new Error('No Chromium browser found. Set ARENA_BROWSER to msedge.exe or chrome.exe.');
  }
  const port = 9222 + Math.floor(Math.random() * 500);
  const profileDir = join(tmpdir(), `arena-prototype-${Date.now()}`);
  const browser = spawn(
    browserPath,
    [
      '--headless=new',
      '--disable-gpu',
      '--hide-scrollbars',
      '--no-first-run',
      '--no-default-browser-check',
      '--force-device-scale-factor=1',
      `--user-data-dir=${profileDir}`,
      `--remote-debugging-port=${port}`,
      'about:blank',
    ],
    { stdio: 'ignore' }
  );

  let webSocketUrl = null;
  for (let attempt = 0; attempt < 80 && !webSocketUrl; attempt += 1) {
    try {
      const response = await fetch(`http://127.0.0.1:${port}/json/version`);
      if (response.ok) webSocketUrl = (await response.json()).webSocketDebuggerUrl;
    } catch {
      /* not ready yet */
    }
    if (!webSocketUrl) await sleep(250);
  }
  if (!webSocketUrl) {
    browser.kill();
    throw new Error('DevTools endpoint did not appear');
  }

  const socket = new WebSocket(webSocketUrl);
  await new Promise((resolve, reject) => {
    socket.addEventListener('open', resolve, { once: true });
    socket.addEventListener('error', reject, { once: true });
  });

  const pending = new Map();
  const eventHandlers = new Map();
  let nextId = 1;
  socket.addEventListener('message', (event) => {
    const message = JSON.parse(event.data);
    if (message.id && pending.has(message.id)) {
      const waiter = pending.get(message.id);
      pending.delete(message.id);
      if (message.error) waiter.reject(new Error(message.error.message));
      else waiter.resolve(message.result);
      return;
    }
    if (message.method && eventHandlers.has(message.method)) {
      eventHandlers.get(message.method).forEach((handler) => handler(message.params));
    }
  });

  const rawSend = (method, params = {}, sessionId) => {
    const id = nextId++;
    const message = { id, method, params };
    if (sessionId) message.sessionId = sessionId;
    socket.send(JSON.stringify(message));
    return new Promise((resolve, reject) => {
      pending.set(id, { resolve, reject });
      setTimeout(() => {
        if (pending.has(id)) {
          pending.delete(id);
          reject(new Error(`${method} timed out`));
        }
      }, 30000);
    });
  };

  const { targetId } = await rawSend('Target.createTarget', { url: 'about:blank' });
  const { sessionId } = await rawSend('Target.attachToTarget', { targetId, flatten: true });
  await rawSend('Page.enable', {}, sessionId);
  await rawSend('Runtime.enable', {}, sessionId);

  return {
    send: (method, params) => rawSend(method, params, sessionId),
    on: (method, handler) => {
      if (!eventHandlers.has(method)) eventHandlers.set(method, []);
      eventHandlers.get(method).push(handler);
    },
    close: () => {
      try {
        socket.close();
      } catch {
        /* ignore */
      }
      browser.kill();
    },
  };
}
