# authed-browser

一个 Cloudflare Worker：用 Playwright 登录你的账号后抓取需要登录的页面，登录态保存在 Workers KV 中。

凭证只作为 Worker Secrets 存在，不会进入聊天记录或 MCP 工具参数。

## 一次性设置

```sh
cd authed-browser
npm install
npx wrangler login
```

创建 KV namespace，把输出的 ID 填进 `wrangler.jsonc` 的 `kv_namespaces[0].id`：

```sh
npx wrangler kv namespace create SESSION
```

写入凭证（不会回显）：

```sh
npx wrangler secret put LOGIN_USER
npx wrangler secret put LOGIN_PASS
```

如果登录页不是目标页自动跳转过去的，设置登录页地址：

```sh
npx wrangler secret put LOGIN_URL
```

如果默认选择器不匹配，用变量覆盖（也可直接改 `wrangler.jsonc` 的 `vars`）：

```sh
# 这些是普通变量，不是 secret
# 在 wrangler.jsonc 的 vars 中修改即可
LOGIN_USER_SELECTOR      # 默认 input[name="username"], input[type="email"], #username, #email
LOGIN_PASS_SELECTOR      # 默认 input[type="password"]
LOGIN_SUBMIT_SELECTOR    # 默认 button[type="submit"], button:has-text("Log in"), ...
LOGIN_SUCCESS_SELECTOR   # 可选，登录完成后出现的元素
```

部署：

```sh
npm run check   # 静态校验，不部署
npm run deploy
```

## 使用

```sh
BASE=https://authed-browser.<你的子域>.workers.dev

# 抓取登录后的页面正文
curl "$BASE/?url=https://app.example.com/dashboard"

# 先看诊断信息（URL / 标题 / 是否识别为登录页 / cookie 数量）
curl "$BASE/?url=https://app.example.com/dashboard&mode=debug"

# 其他输出格式
curl "$BASE/?url=https://app.example.com/dashboard&mode=html"
curl "$BASE/?url=https://app.example.com/dashboard&mode=screenshot" -o shot.png
curl "$BASE/?url=https://app.example.com/dashboard&mode=pdf" -o page.pdf

# 强制重新登录（改了选择器或登录态失效时）
curl "$BASE/?url=https://app.example.com/dashboard&fresh=1"

# 多账号：用不同的 session 名隔离登录态
curl "$BASE/?url=https://app.example.com/dashboard&session=alice"
```

在 OpenCode 里直接说：`用 curl 调 authed-browser Worker 抓取 <URL> 的正文`。

参数说明：

| 参数 | 默认 | 说明 |
| --- | --- | --- |
| `url` | 必填 | 要抓取的目标页面 |
| `mode` | `text` | `text` / `html` / `title` / `url` / `screenshot` / `pdf` / `debug` |
| `fresh` | `0` | `1` 表示删除已存登录态并重新登录 |
| `session` | `default` | KV 中的登录态名，用于多账号隔离 |
| `login_url` | `LOGIN_URL` | 临时指定登录页 |

## 注意

- 登录页识别规则：URL 路径含 `login` / `signin` / `auth`，或页面存在密码输入框。不匹配时用 `?mode=debug` 检查，再调整选择器。
- Browser Run 的请求始终被标记为 bot；带强人机验证或短信 2FA 的站点可能登录失败，需要改用该站点的 API / service token。
- 免费额度：Workers Free 每天 10 分钟浏览器时间。
