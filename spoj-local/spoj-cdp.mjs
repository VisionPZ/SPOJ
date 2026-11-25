import fs from "node:fs";
import path from "node:path";

const BASE = process.env.CDP_BASE || "http://127.0.0.1:9222";
const LOCK = path.join(path.dirname(new URL(import.meta.url).pathname), ".cdp.lock");
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function usage() {
  console.error(
    "用法:\n  node spoj-cdp.mjs check\n  node spoj-cdp.mjs fetch <url> [text|html|title|url|links|screenshot|pdf] [--out FILE]",
  );
}

function acquireLock() {
  if (fs.existsSync(LOCK)) {
    const pid = Number(fs.readFileSync(LOCK, "utf8"));
    try {
      process.kill(pid, 0);
      throw new Error(`另一个 spoj-cdp 进程正在使用浏览器 (PID ${pid})`);
    } catch (e) {
      if (e.code !== "ESRCH") throw e;
    }
  }
  fs.writeFileSync(LOCK, String(process.pid));
}

function releaseLock() {
  try {
    if (Number(fs.readFileSync(LOCK, "utf8")) === process.pid) fs.unlinkSync(LOCK);
  } catch {
    // Lock already gone.
  }
}

function parseArgs(argv) {
  const outIndex = argv.indexOf("--out");
  const out = outIndex >= 0 ? argv[outIndex + 1] : undefined;
  const args =
    outIndex >= 0
      ? argv.filter((a, i) => !a.startsWith("--") && i !== outIndex + 1)
      : argv.filter((a) => !a.startsWith("--"));
  return { out, args };
}

async function connectToSpOJTab() {
  const list = await (await fetch(`${BASE}/json/list`)).json();
  const tab = list.find(
    (t) => t.type === "page" && /spoj\.(com|pl)/i.test(t.url),
  );
  if (!tab) {
    throw new Error(
      "找不到 SPOJ 标签页。请先在 Vivaldi 中打开并登录 https://www.spoj.com/myaccount/",
    );
  }
  const ws = new WebSocket(tab.webSocketDebuggerUrl);
  await new Promise((resolve, reject) => {
    ws.addEventListener("open", resolve, { once: true });
    ws.addEventListener("error", () => reject(new Error("CDP WebSocket 连接失败")), {
      once: true,
    });
  });
  return { tab, ws, originalUrl: tab.url };
}

function makeCaller(ws) {
  let id = 0;
  return function call(method, params = {}, timeout = 30000) {
    return new Promise((resolve, reject) => {
      const myId = ++id;
      const timer = setTimeout(
        () => reject(new Error(`CDP timeout: ${method}`)),
        timeout,
      );
      const handler = (event) => {
        let msg;
        try {
          msg = JSON.parse(event.data);
        } catch {
          return;
        }
        if (msg.id !== myId) return;
        clearTimeout(timer);
        ws.removeEventListener("message", handler);
        if (msg.error) reject(new Error(`${method}: ${JSON.stringify(msg.error)}`));
        else resolve(msg.result);
      };
      ws.addEventListener("message", handler);
      ws.send(JSON.stringify({ id: myId, method, params }));
    });
  };
}

async function evaluate(call, expression, timeout) {
  const result = await call(
    "Runtime.evaluate",
    { expression, returnByValue: true, awaitPromise: true },
    timeout,
  );
  if (result.exceptionDetails) throw new Error(JSON.stringify(result.exceptionDetails));
  return result.result.value;
}

async function waitForPage(call, timeoutMs = 90000) {
  const deadline = Date.now() + timeoutMs;
  let state;
  while (Date.now() < deadline) {
    state = await evaluate(
      call,
      "({ready:document.readyState,title:document.title,url:location.href})",
      10000,
    ).catch(() => null);
    if (state?.ready === "complete") return state;
    await sleep(500);
  }
  return state;
}

async function main() {
  const { args, out } = parseArgs(process.argv.slice(2));
  const [command, url, mode = "text"] = args;
  if (!command || (command !== "check" && !url)) {
    usage();
    process.exit(2);
  }

  acquireLock();
  let session;
  try {
    session = await connectToSpOJTab();
    const call = makeCaller(session.ws);
    await call("Page.enable");
    await call("Runtime.enable");

    if (command === "check") {
      const s = await waitForPage(call);
      console.log(JSON.stringify(s, null, 2));
      return;
    }

    await call("Page.navigate", { url });
    const s = await waitForPage(call);
    if (!s) throw new Error("页面加载超时");
    if (/just a moment|performing security verification/i.test(s.title)) {
      throw new Error("SPOJ 返回 Cloudflare 验证页；请先在 Vivaldi 中手动通过验证。");
    }

    let data;
    switch (mode) {
      case "title":
        data = s.title;
        break;
      case "url":
        data = s.url;
        break;
      case "html":
        data = await evaluate(call, "document.documentElement.outerHTML");
        break;
      case "links":
        data = JSON.stringify(
          await evaluate(
            call,
            "Array.from(document.querySelectorAll('a')).map(a=>({text:a.innerText.trim(),href:a.href})).filter(x=>x.href)",
          ),
          null,
          2,
        );
        break;
      case "screenshot": {
        const shot = await call("Page.captureScreenshot", {
          format: "png",
          captureBeyondViewport: true,
        });
        data = Buffer.from(shot.data, "base64");
        break;
      }
      case "pdf": {
        const pdf = await call("Page.printToPDF", { printBackground: true });
        data = Buffer.from(pdf.data, "base64");
        break;
      }
      case "text":
      default:
        data = await evaluate(call, "document.body.innerText");
    }

    if (out) {
      fs.writeFileSync(out, data);
      console.log(`已保存到 ${out}`);
    } else if (Buffer.isBuffer(data)) {
      console.error("二进制模式请用 --out FILE 保存。");
      process.exitCode = 2;
    } else {
      process.stdout.write(data);
    }
  } finally {
    if (session) {
      // Put the borrowed tab back where it was.
      if (command === "fetch" && session.originalUrl) {
        await makeCaller(session.ws)("Page.navigate", { url: session.originalUrl }, 10000).catch(
          () => {},
        );
      }
      session.ws.close();
    }
    releaseLock();
  }
}

await main();
