# spoj-local

直接复用你**已登录的 Vivaldi 浏览器会话**抓取 SPOJ 页面。SPOJ 全站有 Cloudflare 验证，云端 Browser Run 和新建的无头浏览器都过不去；借用已登录的浏览器标签页可以正常访问。

原理：Vivaldi 启动时已带 `--remote-debugging-port=9222`。脚本通过 CDP 找到 SPOJ 标签页，借用它在同一个会话里打开目标 URL，抓完自动恢复原页面。不需要密码，也不复制 cookie。

## 用法

```sh
cd spoj-local

# 检查当前 SPOJ 标签页状态
node spoj-cdp.mjs check

# 抓取登录后的页面（默认输出正文）
node spoj-cdp.mjs fetch https://www.spoj.com/myaccount/

# 其他格式
node spoj-cdp.mjs fetch https://www.spoj.com/status/ html
node spoj-cdp.mjs fetch https://www.spoj.com/status/ links
node spoj-cdp.mjs fetch https://www.spoj.com/status/ screenshot --out status.png
node spoj-cdp.mjs fetch https://www.spoj.com/status/ pdf --out status.pdf
node spoj-cdp.mjs fetch https://www.spoj.com/myaccount/ title
```

可用模式：`text`（默认）、`html`、`title`、`url`、`links`、`screenshot`、`pdf`。

在 OpenCode 里直接说：`运行 node spoj-local/spoj-cdp.mjs fetch <URL>`。

## 前置条件

- Vivaldi 必须带 `--remote-debugging-port=9222` 运行（当前已满足）。
- 至少保留一个已登录的 SPOJ 标签页（当前是 `https://www.spoj.com/myaccount/`）。
- 抓取期间脚本借用该标签页，结束后自动导航回原 URL；同一时间只能运行一个抓取（有锁文件 `.cdp.lock`）。

如果 Vivaldi 重启后没有调试端口，用以下命令重新启动（保留原 profile 和登录态）：

```sh
vivaldi --remote-debugging-port=9222 --remote-allow-origins=*
```
