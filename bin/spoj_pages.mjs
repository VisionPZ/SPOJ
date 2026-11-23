#!/usr/bin/env node
// Fetch SPOJ problem pages through the user's Vivaldi (Cloudflare needs a real browser).
// Usage: bin/spoj_pages.mjs CODE [CODE...]  -> prints per code: TIME, MEM, SRC, then first 900 chars of statement text
import { spawn } from 'node:child_process';
import fs from 'node:fs';
const SOURCE = '/home/pingz/.config/vivaldi';
const PROFILE = process.env.SPOJ_PROFILE || '/home/pingz/Storage/Projects/SPOJ/.spoj-profile';
const PORT = Number(process.env.SPOJ_PORT || 12345);
const codes = process.argv.slice(2);
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
function launchBrowser() { child = spawn('/opt/vivaldi/vivaldi', ['--user-data-dir=' + PROFILE, '--no-first-run', '--no-restore-state-on-startup', '--disable-gpu', '--remote-debugging-port=' + PORT, 'about:blank'], { stdio: 'ignore' }); }
const sleep = (ms) => new Promise(r => setTimeout(r, ms));
async function existingTarget() { try { const r = await fetch('http://127.0.0.1:' + PORT + '/json/list', { signal: AbortSignal.timeout(3000) }); return (await r.json()).find(t => t.type === 'page'); } catch { return null; } }
async function pageTarget() { let fast = await existingTarget(); if (fast) return fast; launchBrowser(); for (let i = 0; i < 160; i++) { try { const res = await fetch('http://127.0.0.1:' + PORT + '/json/list', { signal: AbortSignal.timeout(2000) }); const page = (await res.json()).find(t => t.type === 'page'); if (page) return page; } catch {} await sleep(500); } return null; }
(async () => {
  const page = await pageTarget();
  if (!page) { console.error('no debuggable tab'); (child && child.kill('SIGKILL')); process.exit(3); }
  const ws = new WebSocket(page.webSocketDebuggerUrl);
  const pending = new Map(); let nextId = 1;
  ws.onmessage = (ev) => { const m = JSON.parse(ev.data); if (m.id && pending.has(m.id)) { const job = pending.get(m.id); pending.delete(m.id); m.error ? job.reject(new Error(m.error.message)) : job.resolve(m.result); } };
  await Promise.race([new Promise(r => ws.onopen = r), sleep(20000)]);
  const send = (method, params = {}) => new Promise((res, rej) => { const id = nextId++; pending.set(id, { resolve: res, reject: rej }); ws.send(JSON.stringify({ id, method, params })); setTimeout(() => { if (pending.has(id)) { pending.delete(id); rej(new Error('cdp timeout ' + method)); } }, 25000); });
  const evaluate = async (expression) => {
    let last = null;
    for (let attempt = 0; attempt < 4; attempt++) {
      try {
        const out = await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
        if (out.exceptionDetails) throw new Error('page: ' + (out.exceptionDetails.exception?.description || out.exceptionDetails.text));
        return out.result.value;
      } catch (err) { last = err; await sleep(3000); }
    }
    throw last;
  };
  const sendPage = (method, params = {}) => send(method, params).catch(() => null);
  await sendPage('Page.enable');
  await sendPage('Page.navigate', { url: 'https://www.spoj.com/problems/' + codes[0] + '/' });
  for (let wait = 0; wait < 20; wait++) {
    const state = await evaluate("({ title: document.title, url: location.href })");
    if (state && state.url && state.url.indexOf('/problems/') > -1 && String(state.title).toLowerCase().indexOf('moment') < 0) break;
    await sleep(2000);
  }
  for (const code of codes) {
    try {
      const info = await evaluate(`(async function(){
        const html = await (await fetch('https://www.spoj.com/problems/${code}/')).text();
        const doc = new DOMParser().parseFromString(html, 'text/html');
        const meta = doc.querySelector('.problem-metadata') || doc.body;
        const text = (doc.querySelector('#problem') || doc.body).innerText || '';
        return { meta: (meta.innerText||'').replace(/\\s+/g,' ').slice(0,400), head: text.replace(/\\s+/g,' ').slice(0,1400) };
      })()`);
      console.log('==== ' + code + ' ====');
      console.log(info.meta);
      console.log(info.head);
      console.log();
    } catch (err) { console.log('==== ' + code + ' ==== ERROR ' + err.message); }
  }
  (child && child.kill('SIGKILL'));
  process.exit(0);
})().catch(err => { console.error('FAILED: ' + err.message); (child && child.kill('SIGKILL')); process.exit(9); });
