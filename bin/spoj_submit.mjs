#!/usr/bin/env node
// Submit a solution to SPOJ through the user's Vivaldi (Cloudflare needs a real browser),
// then poll the judge status. Usage: bin/spoj_submit.mjs CODE FILE [--lang nim] [--form-only]
import { spawn } from 'node:child_process';
import fs from 'node:fs';
import pathMod from 'node:path';

const SOURCE = '/home/pingz/.config/vivaldi';
const PROFILE = process.env.SPOJ_PROFILE || '/home/pingz/Storage/Projects/SPOJ/.spoj-profile';
const PORT = Number(process.env.SPOJ_PORT || 12345);
const VIVALDI = process.env.SPOJ_BIN || '/opt/vivaldi/vivaldi';
const sleep = (ms) => new Promise(r => setTimeout(r, ms));

const args = process.argv.slice(2);
const code = args[0];
const file = args[1];
if (!code || !file) { console.error('usage: spoj_submit.mjs CODE FILE [--lang nim]'); process.exit(2); }
const langName = args.includes('--lang') ? args[args.indexOf('--lang') + 1].toLowerCase() : 'nim';
const formOnly = args.includes('--form-only');

for (const name of ['Cookies', 'Preferences']) {
  const src = SOURCE + '/Default/' + name;
  if (fs.existsSync(src)) fs.cpSync(src, PROFILE + '/Default/' + name, { recursive: true, force: true });
}

let child = null;
function launchBrowser() {
  child = spawn(VIVALDI, [
    '--user-data-dir=' + PROFILE, '--no-first-run', '--no-restore-state-on-startup',
    '--disable-gpu', '--remote-debugging-port=' + PORT, 'https://www.spoj.com/problems/classical/',
  ], { stdio: 'ignore' });
}

async function existingTarget() { try { const res = await fetch('http://127.0.0.1:' + PORT + '/json/list', { signal: AbortSignal.timeout(3000) }); return (await res.json()).find(t => t.type === 'page'); } catch { return null; } }
async function pageTarget() {
  let fast = await existingTarget();
  if (fast) return fast;
  launchBrowser();
  for (let i = 0; i < 60; i++) {
    try {
      const res = await fetch('http://127.0.0.1:' + PORT + '/json/list', { signal: AbortSignal.timeout(2000) });
      const page = (await res.json()).find(t => t.type === 'page');
      if (page) return page;
    } catch {}
    await sleep(500);
  }
  return null;
}

function finish(child, codeExit) {
  if (child) child.kill('SIGKILL');
  process.exit(codeExit);
}

(async () => {
  const page = await pageTarget();
  if (!page) { console.error('no debuggable tab: another Vivaldi may hold that profile'); finish(child, 3); }

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
  await Promise.race([new Promise(r => ws.onopen = r), sleep(20000)]);

  const sendOnce = (method, params) => new Promise((res, rej) => {
    const id = nextId++;
    pending.set(id, { resolve: res, reject: rej });
    ws.send(JSON.stringify({ id, method, params }));
    setTimeout(() => { if (pending.has(id)) { pending.delete(id); rej(new Error('cdp timeout ' + method)); } }, 20000);
  });
  const evaluate = async (expression) => {
    let lastError = null;
    for (let attempt = 0; attempt < 4; attempt++) {
      try {
        const out = await sendOnce('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
        if (out.exceptionDetails) throw new Error('page: ' + (out.exceptionDetails.exception?.description || out.exceptionDetails.text));
        return out.result.value;
      } catch (err) {
        lastError = err;
        await sleep(2000);
      }
    }
    throw lastError;
  };
  const inPage = (expression) => evaluate('(async function () { ' + expression + ' })()');

  const sendPage = (method, params = {}) => sendOnce(method, params).catch(() => null);
  const navigate = async (url) => { await sendPage('Page.enable'); await sendPage('Page.navigate', { url }); await sleep(2500); };
  const waitFor = async (predicate, ms) => {
    const started = Date.now();
    while (Date.now() - started < ms) {
      const value = await evaluate('(' + predicate + ')');
      if (value) return value;
      await sleep(1500);
    }
    return null;
  };

  await navigate('https://www.spoj.com/problems/' + code + '/');
  await waitFor("location.href.indexOf('/problems/') > -1 && document.title.indexOf('moment') < 0", 90000);
  const pageState = await evaluate('({ title: document.title, url: location.href })');
  console.error('page: ' + JSON.stringify(pageState));

  await navigate('https://www.spoj.com/submit/' + code + '/');
  await waitFor('document.forms.length > 0', 60000);
  const formSpec = await inPage(`
    const form = document.forms[0];
    return {
      action: form.action, method: form.method,
      fields: [...form.elements].map(el => ({ name: el.name, type: el.type, value: el.value,
        options: el.tagName.toLowerCase() === 'select' ? [...el.options].map(o => o.value + ' = ' + o.text) : null })),
    };
  `);
  console.log(JSON.stringify(formSpec, null, 1));
  if (formOnly) finish(child, 0);

  const language = await evaluate(`
    (function () {
      const wanted = ${JSON.stringify(langName)};
      const select = [...document.forms[0].elements].find(el => el.tagName.toLowerCase() === 'select' && /lang/i.test(el.name || ''));
      const match = [...select.options].find(o => o.text.toLowerCase().startsWith(wanted));
      return match ? { name: select.name, value: match.value, text: match.text } : { error: 'no ' + wanted + ' language' };
    })()
  `);
  console.error('language: ' + JSON.stringify(language));
  if (language.error) finish(child, 5);

  const bytes = fs.readFileSync(file);
  const post = await inPage(`
    const bytes = Uint8Array.from(atob(${JSON.stringify(bytes.toString('base64'))}), c => c.charCodeAt(0));
    const form = document.forms[0];
    const body = new FormData();
    for (const el of form.elements) {
      if (el.type === 'file') body.append(el.name, new Blob([bytes]), ${JSON.stringify(pathMod.basename(file))});
      else if (el.tagName.toLowerCase() === 'select') body.append(el.name, ${JSON.stringify(String(language.value))});
      else if (el.name) body.append(el.name, el.value);
    }
    const res = await fetch(form.action, { method: 'POST', body, credentials: 'same-origin' });
    return { status: res.status, text: await res.text() };
  `);
  fs.writeFileSync('/tmp/spoj_post_response.html', post.text);
  console.error('POST status: ' + post.status);

  for (let attempt = 0; attempt < 10; attempt++) {
    await sleep(4000);
    const status = await inPage(`
      const html = await (await fetch('https://www.spoj.com/status/' + ${JSON.stringify(code)} + '/')).text();
      const doc = new DOMParser().parseFromString(html, 'text/html');
      return [...doc.querySelectorAll('tr')].slice(0, 8).map(r => [...r.cells].map(c => c.textContent.trim()).join(' | '));
    `);
    if (!status || status.error) { console.error('status read failed: ' + JSON.stringify(status)); continue; }
    const mine = status.filter(row => /\| Ping \|/.test(row));
    console.error('rows: ' + JSON.stringify(status.slice(0, 3)));
    if (mine.length) {
      console.log('SUBMISSION: ' + mine[0]);
      const result = mine[0].split(' | ');
      if (result.length && !/in queue|founding|wait|running/i.test(result.join(' '))) finish(child, /Accepted/i.test(mine[0]) ? 0 : 1);
    }
  }
  console.error('status still pending after polls');
  finish(child, 2);
})().catch(err => { console.error('FAILED: ' + (err.message || err)); finish(child, 9); });
