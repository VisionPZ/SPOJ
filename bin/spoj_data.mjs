#!/usr/bin/env node
// Run a JS extractor against SPOJ pages through a Vivaldi with remote debugging (Cloudflare needs a real browser).
// Usage: EXPR='<function body taking doc>' bin/spoj_data.mjs URL [URL...]
// Reuses a Vivaldi already listening on :12345; otherwise starts one from .spoj-profile (a copy of the user's Vivaldi SPOJ login).
// SPOJ_RESTART=1 kills that instance first. Saves each page's #problem text to OUT_DIR (default /tmp/spoj_data), prints one JSON line per URL.
import { spawn } from 'node:child_process';
import fs from 'node:fs';
const SOURCE = '/home/pingz/.config/vivaldi';
const PROFILE = process.env.SPOJ_PROFILE || '/home/pingz/Storage/Projects/SPOJ/.spoj-profile';
const PORT = Number(process.env.SPOJ_PORT || 12345);
const EXPR = process.env.EXPR || '(doc) => doc.title';
const outBase = process.env.OUT_DIR || '/tmp/spoj_data';
const urls = process.argv.slice(2);
const launchUrl = process.env.SPOJ_START || 'https://www.spoj.com/problems/classical/';
fs.mkdirSync(outBase, { recursive: true });
const sleep = (ms) => new Promise(r => setTimeout(r, ms));
let child = null;

function killInstance() { try { spawn('pkill', ['-f', 'user-data-dir=' + PROFILE], { stdio: 'ignore' }).on('error', () => {}); } catch {} }
function copyProfile() {
  for (const name of ['Cookies', 'Preferences']) {
    const src = SOURCE + '/Default/' + name;
    try { if (fs.existsSync(src)) { fs.mkdirSync(PROFILE + '/Default', { recursive: true }); fs.cpSync(src, PROFILE + '/Default/' + name, { force: true }); } } catch {}
  }
  for (const lock of ['SingletonLock', 'SingletonSocket', 'SingletonCookie']) {
    try { fs.rmSync(PROFILE + '/Default/' + lock); } catch {}
    try { fs.rmSync(PROFILE + '/' + lock); } catch {}
  }
}
async function listPages() { const res = await fetch('http://127.0.0.1:' + PORT + '/json/list', { signal: AbortSignal.timeout(3000) }); return (await res.json()).filter(t => t.type === 'page'); }
async function pickPage() {
  const pages = await listPages();
  const spoj = pages.find(t => /spoj\.com\/(problems|status|users|submit)/.test(t.url));
  if (spoj) return spoj;
  const web = pages.find(t => /^https?:/.test(t.url));
  if (web) return web;
  const blank = pages.find(t => !t.url.startsWith('chrome-extension'));
  return blank || null;
}
async function launch() {
  copyProfile();
  child = spawn('/opt/vivaldi/vivaldi', ['--user-data-dir=' + PROFILE, '--no-first-run', '--no-restore-state-on-startup', '--disable-gpu', '--remote-debugging-port=' + PORT, launchUrl], { stdio: 'ignore' });
  for (let i = 0; i < 200; i++) { try { const page = await pickPage(); if (page) return page; } catch {} await sleep(500); }
  return null;
}

async function runOnce() {
  let page = null;
  try { page = await pickPage(); } catch {}
  if (!page) page = await launch();
  if (!page) throw new Error('no debuggable tab');
  console.error('driver tab: ' + page.url);
  const ws = new WebSocket(page.webSocketDebuggerUrl);
  const pending = new Map(); let nextId = 1;
  ws.onmessage = (ev) => { const m = JSON.parse(ev.data); if (m.id && pending.has(m.id)) { const job = pending.get(m.id); pending.delete(m.id); m.error ? job.reject(new Error(m.error.message)) : job.resolve(m.result); } };
  ws.onclose = () => { for (const job of pending.values()) job.reject(new Error('cdp closed')); pending.clear(); };
  await Promise.race([new Promise(r => ws.onopen = r), sleep(20000)]);
  const send = (method, params = {}) => new Promise((res, rej) => {
    const id = nextId++; pending.set(id, { resolve: res, reject: rej }); ws.send(JSON.stringify({ id, method, params }));
    setTimeout(() => { if (pending.has(id)) { pending.delete(id); rej(new Error('cdp timeout ' + method)); } }, 60000);
  });
  const evaluate = async (expression) => {
    let last = null;
    for (let attempt = 0; attempt < 2; attempt++) {
      try {
        const out = await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
        if (out.exceptionDetails) throw new Error('page: ' + (out.exceptionDetails.exception?.description || out.exceptionDetails.text));
        return out.result.value;
      } catch (err) { last = err; await sleep(1000); }
    }
    throw last;
  };
  await send('Page.enable').catch(() => null);
  await send('Page.navigate', { url: urls[0] }).catch(() => null);
  for (let wait = 0; wait < 40; wait++) {
    const state = await evaluate('({url: location.href, title: document.title})').catch(() => null);
    if (state && /spoj\.com/.test(state.url) && !/Just a moment|challenge|Attention Required/i.test(state.title)) break;
    await sleep(3000);
  }
  for (const url of urls) {
    const slug = encodeURIComponent(url).replace(/[^A-Za-z0-9._-]/g, '_').slice(0, 90);
    try {
      const r = await evaluate(`(async function(){ const res = await fetch(${JSON.stringify(url)}, {credentials:'include'}); const html = await res.text(); const doc = new DOMParser().parseFromString(html, 'text/html'); const fn = ${EXPR}; return JSON.stringify({ status: res.status, value: fn(doc), text: ((doc.querySelector('#problem') || doc.body) || {innerText:''}).innerText.replace(/\\r/g,'') }); })()`);
      const obj = JSON.parse(r);
      if (obj.text) fs.writeFileSync(outBase + '/' + slug + '.txt', obj.text);
      console.log(JSON.stringify({ url, status: obj.status, value: obj.value }));
      if (obj.status === 403 || /Just a moment|Enable JavaScript and cookies/i.test(obj.text || '')) console.error('CLOUDFLARE BLOCK on ' + url);
    } catch (err) { console.log(JSON.stringify({ url, error: String(err.message || err) })); }
  }
  ws.close();
}

(async () => {
  if (process.env.SPOJ_RESTART) { killInstance(); await sleep(3000); }
  try { await runOnce(); }
  catch (err) {
    console.error('first pass failed: ' + err.message + '; restarting browser');
    if (child) { child.kill('SIGKILL'); child = null; }
    killInstance(); await sleep(4000);
    try { await runOnce(); } catch (err2) { console.error('FAILED: ' + err2.message); process.exit(9); }
  }
  if (child) child.kill('SIGKILL');
  process.exit(0);
})().catch(err => { console.error('FAILED: ' + err.message); if (child) child.kill('SIGKILL'); process.exit(9); });
