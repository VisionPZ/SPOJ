import { launch } from "@cloudflare/playwright";

const USER_SELECTOR =
  'input[name="username"], input[name="login_user"], input[name="email"], input[type="email"], #username, #email';
const PASS_SELECTOR = 'input[type="password"]';
const SUBMIT_SELECTOR =
  'button[type="submit"], input[type="submit"], button:has-text("Log in"), button:has-text("Sign in")';

const json = (obj, status = 200) =>
  new Response(JSON.stringify(obj, null, 2), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
    },
  });

function configFrom(request, env) {
  const q = new URL(request.url).searchParams;
  return {
    target: q.get("url"),
    mode: q.get("mode") || "text",
    session: q.get("session") || "default",
    fresh: ["1", "true", "yes"].includes((q.get("fresh") || "").toLowerCase()),
    loginUrl: q.get("login_url") || env.LOGIN_URL || "",
    userSelector: env.LOGIN_USER_SELECTOR || USER_SELECTOR,
    passSelector: env.LOGIN_PASS_SELECTOR || PASS_SELECTOR,
    submitSelector: env.LOGIN_SUBMIT_SELECTOR || SUBMIT_SELECTOR,
    successSelector: env.LOGIN_SUCCESS_SELECTOR || "",
  };
}

async function looksLikeLogin(page) {
  try {
    const path = new URL(page.url()).pathname.toLowerCase();
    if (/(^|\/)(login|signin|sign-in|auth)(\/|$)/.test(path)) return true;
  } catch {
    // Ignore malformed URLs.
  }
  return (await page.locator(PASS_SELECTOR).count()) > 0;
}

async function doLogin(page, cfg, env) {
  if (!env.LOGIN_USER || !env.LOGIN_PASS) {
    throw new Error(
      "LOGIN_USER / LOGIN_PASS secrets are missing. Run: wrangler secret put LOGIN_USER",
    );
  }

  if (cfg.loginUrl) {
    await page.goto(cfg.loginUrl, {
      waitUntil: "domcontentloaded",
      timeout: 60000,
    });
  }

  const user = page.locator(cfg.userSelector).first();
  const pass = page.locator(cfg.passSelector).first();

  // Give challenge pages (e.g. Cloudflare "Just a moment...") time to resolve.
  await user
    .waitFor({ state: "visible", timeout: 45000 })
    .catch(() => {});
  await pass
    .waitFor({ state: "visible", timeout: 45000 })
    .catch(() => {});

  if ((await user.count()) === 0 || (await pass.count()) === 0) {
    const title = await page.title().catch(() => "");
    const snippet = (await page.locator("body").innerText().catch(() => "")).slice(
      0,
      300,
    );
    throw new Error(
      `Login form not found. URL: ${page.url()} | title: ${title} | body: ${snippet}`,
    );
  }

  await user.fill(env.LOGIN_USER);
  await pass.fill(env.LOGIN_PASS);
  await page.locator(cfg.submitSelector).first().click();
  await page.waitForLoadState("domcontentloaded");

  if (cfg.successSelector) {
    await page.locator(cfg.successSelector).first().waitFor({ timeout: 30000 });
  } else {
    await page
      .waitForFunction(
        () => !document.querySelector('input[type="password"]'),
        null,
        { timeout: 30000 },
      )
      .catch(() => {});
  }
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname === "/health") return json({ ok: true });

    const cfg = configFrom(request, env);
    if (!cfg.target) {
      return json(
        {
          error: "missing ?url=",
          example: "/?url=https://example.com/private&mode=text",
          modes: ["text", "html", "title", "url", "screenshot", "pdf", "debug"],
        },
        400,
      );
    }

    const key = `session:${cfg.session}`;
    if (cfg.fresh) await env.SESSION.delete(key);

    let storageState;
    const saved = await env.SESSION.get(key);
    if (saved) {
      try {
        storageState = JSON.parse(saved);
      } catch {
        storageState = undefined;
      }
    }

    let browser;
    try {
      browser = await launch(env.MYBROWSER, { keep_alive: 600000 });
      const context = await browser.newContext({ storageState });
      const page = await context.newPage();

      await page.goto(cfg.target, {
        waitUntil: "domcontentloaded",
        timeout: 60000,
      });

      let didLogin = false;
      if (cfg.fresh || (await looksLikeLogin(page))) {
        await doLogin(page, cfg, env);
        didLogin = true;
        await page.goto(cfg.target, {
          waitUntil: "domcontentloaded",
          timeout: 60000,
        });
      }

      const loginDetected = await looksLikeLogin(page);

      // Persist cookies / localStorage / IndexedDB so the next call is already logged in.
      const state = await context.storageState({ indexedDB: true });
      await env.SESSION.put(key, JSON.stringify(state));

      if (cfg.mode === "debug") {
        return json({
          url: page.url(),
          title: await page.title(),
          didLogin,
          loginDetected,
          cookieCount: state.cookies.length,
          originCount: state.origins.length,
          snippet: (await page.locator("body").innerText()).slice(0, 1000),
        });
      }

      if (loginDetected) {
        return json(
          {
            error: "still on a login page after the login attempt",
            hint:
              "Tune LOGIN_URL / selectors / LOGIN_SUCCESS_SELECTOR, then retry with ?fresh=1",
            url: page.url(),
            snippet: (await page.locator("body").innerText()).slice(0, 1000),
          },
          401,
        );
      }

      let body;
      let contentType;
      switch (cfg.mode) {
        case "html":
          body = await page.content();
          contentType = "text/html; charset=utf-8";
          break;
        case "title":
          body = await page.title();
          contentType = "text/plain; charset=utf-8";
          break;
        case "url":
          body = page.url();
          contentType = "text/plain; charset=utf-8";
          break;
        case "screenshot":
          body = await page.screenshot({ fullPage: true });
          contentType = "image/png";
          break;
        case "pdf":
          body = await page.pdf();
          contentType = "application/pdf";
          break;
        case "text":
        default:
          body = await page.locator("body").innerText();
          contentType = "text/plain; charset=utf-8";
      }

      return new Response(body, {
        headers: {
          "content-type": contentType,
          "cache-control": "no-store",
          "x-session-key": key,
          "x-did-login": String(didLogin),
        },
      });
    } catch (error) {
      return json(
        {
          error: String(error?.message || error),
          hint: "Call with ?mode=debug to inspect the page state.",
        },
        500,
      );
    } finally {
      if (browser) await browser.close().catch(() => {});
    }
  },
};
