#!/usr/bin/env node
// Fetch arbitrary SPOJ URLs through the user's Vivaldi (Cloudflare needs a real browser).
// Usage: bin/spoj_url.mjs URL [URL...]   prints title + innerText of each page
import { spawn } from 'node:child_process';
import fs from 'node:fs';
const SOURCE = '/home/pingz/.config/vivaldi';
const PROFILE = process.env.SPOJ_PROFILE || '/home/pingz/Storage/Projects/SPOJ/.spoj-profile';
const PORT = Number(process.env.SPOJ_PORT || 12345);
const urls = process.argv.slice(2);
if (!process.env.SPOJ_KEEP_PROFILE) {
  for (const name of ['Cookies', 'Preferences']) {
    const src = SOURCE + '/Default/' + name;
    try { if (fs.existsSync(src)) { fs.mkdirSync(PROFILE + '/Default', { recursive: true }); fs.cpSync(src, PROFILE + '/Default/' + name, { force: true }); } } catch (err) { console.error('profile copy skipped: ' + err.message); }
  }
}
for (const lock of ['SingletonLock', 'SingletonSocket', 'SingletonCookie']) {
  try { fs.rmSync(PROFILE + '/Default/' + lock); } catch {}
  try { fs.rmSync(PROFILE + '/' + lock); } catch {}
}
let child = null;
const sleep = (ms) => new Promise(r => setTimeout(r, ms));
async function existingTarget() { try { const r = await fetch('http://127.0.0.1:' + PORT + '/json/list', { signal: AbortSignal.timeout(3000) }); return (await r.json()).find(t => t.type === 'page'); } catch { return null; } }
async function pageTarget() { let fast = await existingTarget(); if (fast) return fast; launch(); for (let i = 0; i < 160; i++) { try { const res = await fetch('http://127.0.0.1:' + PORT + '/json/list', { signal: AbortSignal.timeout(2000) }); const page = (await res.json()).find(t => t.type === 'page' && /spoj\.com/.test(t.url)); if (page) return page; } catch {} await sleep(500); } return null; }
async function launch() {
  child = spawn('/opt/vivaldi/vivaldi', ['--user-data-dir=' + PROFILE, '--no-first-run', '--no-restore-state-on-startup', '--disable-gpu', '--remote-debugging-port=' + PORT, 'https://www.spoj.com/problems/'], { stdio: 'ignore' });
}
(async () => {
  let page = null;
  try { const list = await (await fetch('http://127.0.0.1:' + PORT + '/json/list', { signal: AbortSignal.timeout(3000) })).json(); page = list.find(t => t.type === 'page' && /spoj\.com/.test(t.url)); } catch {}
  if (!page) { await launch(); page = await pageTarget(); }
  if (!page) { console.error('no debuggable tab'); if (child) child.kill('SIGKILL'); process.exit(3); }
  const ws = new WebSocket(page.webSocketDebuggerUrl);
  const pending = new Map(); let nextId = 1;
  ws.onmessage = (ev) => { const m = JSON.parse(ev.data); if (m.id && pending.has(m.id)) { const job = pending.get(m.id); pending.delete(m.id); m.error ? job.reject(new Error(m.error.message)) : job.resolve(m.result); } };
  await Promise.race([new Promise(r => ws.onopen = r), sleep(20000)]);
  const send = (method, params = {}) => new Promise((res, rej) => { const id = nextId++; pending.set(id, { resolve: res, reject: rej }); ws.send(JSON.stringify({ id, method, params })); setTimeout(() => { if (pending.has(id)) { pending.delete(id); rej(new Error('cdp timeout ' + method)); } }, 60000); });
  const evaluate = async (expression) => {
    let last = null;
    for (let attempt = 0; attempt < 5; attempt++) {
      try {
        const out = await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
        if (out.exceptionDetails) throw new Error('page: ' + (out.exceptionDetails.exception?.description || out.exceptionDetails.text));
        return out.result.value;
      } catch (err) { last = err; await sleep(4000); }
    }
    throw last;
  };
  await send('Page.enable').catch(() => null);
  await evaluate("document.title").catch(() => null);
  for (const url of urls) {
    try {
      const r = await evaluate(`(async function(){ const res = await fetch(${JSON.stringify(url)}, {credentials:'include'}); const html = await res.text(); const doc = new DOMParser().parseFromString(html, 'text/html'); return { status: res.status, text: (doc.body ? doc.body.innerText : '').replace(/\\r/g,'') }; })()`);
      fs.writeFileSync('/tmp/spoj_url_' + encodeURIComponent(url).slice(0, 60) + '.txt', r.text || '');
      if (r.status === 403 || /Just a moment|Enable JavaScript and cookies/i.test(r.text || '')) console.log('CLOUDFLARE BLOCK on ' + url);
      console.log('==== ' + url + ' [HTTP ' + r.status + '] ====');
      console.log((r.text || '').replace(/^\s+/, '').slice(0, 3000));
      console.log();
    } catch (err) { console.log('==== ' + url + ' ERROR ' + err.message + ' ===='); }
  }
  if (child) child.kill('SIGKILL');
  process.exit(0);
})().catch(err => { console.error('FAILED: ' + err.message); if (child) child.kill('SIGKILL'); process.exit(9); });
