#!/usr/bin/env node
// Extract SPOJ cookies by launching the user's Vivaldi with a copy of their profile
// and reading the decrypted cookie store over Chrome DevTools Protocol.
// Usage: bin/spoj_cookies.mjs [--head] [--page URL]
import { spawn } from 'node:child_process';
import fs from 'node:fs';

const HOME = '/home/pingz';
const SOURCE = process.env.SPOJ_SOURCE_PROFILE || HOME + '/.config/vivaldi';
const PROFILE = process.env.SPOJ_PROFILE || '/home/pingz/Storage/Projects/SPOJ/.spoj-profile';
const PORT = Number(process.env.SPOJ_PORT || 12345);
const HEAD = process.argv.includes('--head');
const START = process.env.SPOJ_START || 'about:blank';
const WAIT_MS = Number(process.env.SPOJ_WAIT_MS || 40000);
const OUT = process.env.SPOJ_COOKIE_OUT || '/home/pingz/Storage/Projects/SPOJ/.spoj/cookies.json';

fs.mkdirSync(PROFILE + '/Default', { recursive: true });
if (PROFILE !== SOURCE) {
  for (const name of ['Cookies', 'Preferences']) {
    const src = SOURCE + '/Default/' + name;
    if (fs.existsSync(src)) fs.cpSync(src, PROFILE + '/Default/' + name, { recursive: true, force: true });
  }
}

const child = spawn('/opt/vivaldi/vivaldi', [
  '--user-data-dir=' + PROFILE, '--no-first-run', '--no-restore-state-on-startup',
  '--disable-gpu', '--disable-session-crashed-bubble',
  '--remote-debugging-port=' + PORT, ...(HEAD ? ['--headless=new'] : []), START,
], { stdio: 'ignore' });

const sleep = (ms) => new Promise(r => setTimeout(r, ms));

async function pageTarget() {
  for (let i = 0; i < 60; i++) {
    try {
      const res = await fetch('http://127.0.0.1:' + PORT + '/json/list', { signal: AbortSignal.timeout(2000) });
      for (const t of await res.json()) if (t.type === 'page') return t;
    } catch {}
    await sleep(500);
  }
  return null;
}

(async () => {
  const page = await pageTarget();
  if (!page) { child.kill('SIGKILL'); console.error('NO_DEBUG_PAGE'); process.exit(3); }

  const ws = new WebSocket(page.webSocketDebuggerUrl);
  const pending = new Map();
  let nextId = 1;
  ws.onmessage = (ev) => {
    const msg = JSON.parse(ev.data);
    if (msg.id && pending.has(msg.id)) {
      const job = pending.get(msg.id);
      pending.delete(msg.id);
      msg.error ? job.reject(new Error(msg.error.message)) : job.resolve(msg.result);
    }
  };
  const failAll = (err) => { for (const job of pending.values()) job.reject(err); pending.clear(); };
  ws.onerror = () => failAll(new Error('ws error'));
  ws.onclose = () => failAll(new Error('ws closed'));
  await Promise.race([new Promise(r => ws.onopen = r), sleep(15000)]);

  const send = (method, params = {}) => new Promise((res, rej) => {
    const id = nextId++;
    pending.set(id, { resolve: res, reject: rej });
    ws.send(JSON.stringify({ id, method, params }));
    setTimeout(() => { if (pending.has(id)) { pending.delete(id); rej(new Error('timeout ' + method)); } }, 8000);
  });

  await send('Network.enable').catch(() => {});
  let cookies = [];
  const started = Date.now();
  while (Date.now() - started < WAIT_MS) {
    try {
      cookies = (process.env.SPOJ_ALL ? (await send('Network.getAllCookies')).cookies : (await send('Network.getCookies', { urls: ['https://www.spoj.com/', 'https://spoj.com/'] })).cookies).filter(c => /spoj/i.test(c.domain));
      if (cookies.some(c => c.name === 'cf_clearance')) break;
    } catch (err) {
      console.error('CDP: ' + err.message);
      break;
    }
    await sleep(3000);
  }

  const userAgent = await send('Runtime.evaluate', { expression: 'navigator.userAgent', returnByValue: true }).then(r => r.result.value).catch(() => null);
  fs.mkdirSync(OUT.replace(/\/[^/]+$/, ''), { recursive: true });
  fs.writeFileSync(OUT.replace(/cookies\.json$/, 'user_agent.txt'), userAgent || '');
  fs.writeFileSync(OUT, JSON.stringify(cookies, null, 1));
  console.error('cookies=' + cookies.length + ' -> ' + OUT);
  for (const c of cookies) console.error(c.name + '=' + c.value.slice(0, 24));
  ws.close();
  child.kill('SIGKILL');
  process.exit(cookies.length ? 0 : 2);
})();
