#!/usr/bin/env python3
import concurrent.futures as cf
import json, os, re, subprocess, sys, time

from bs4 import BeautifulSoup

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
stmt_dir = os.path.join(root, "stmts")
os.makedirs(stmt_dir, exist_ok=True)


def fetch(code):
    txt_path = os.path.join(stmt_dir, code + ".txt")
    if os.path.exists(txt_path) and os.path.getsize(txt_path) > 500:
        return open(txt_path, encoding="utf-8").read()
    api = "http://archive.org/wayback/available?url=www.spoj.com/problems/%s/" % code
    snap = ""
    for _ in range(6):
        out = subprocess.run(["curl", "-s", "-m", "25", api],
                             capture_output=True, text=True).stdout
        try:
            snap = json.loads(out).get(subprocess.run(["curl", "-s", "-m", "25", api],
                                         capture_output=True, text=True).stdout).get(
            "archived_snapshots", {}).get("closest", {}).get("url", "")
        except Exception:
            snap = ""
        if snap:
            break
        time.sleep(8)
    if not snap:
        return ""
    html = ""
    for _ in range(6):
        r = subprocess.run(["curl", "-sL", "-m", "90", snap],
                           capture_output=True, text=True, errors="replace")
        if r.returncode == 0 and len(r.stdout) > 5000:
            html = r.stdout
            break
        time.sleep(8)
    if not html:
        return ""
    soup = BeautifulSoup(html, "html.parser")
    for tag in soup(["script", "style", "noscript"]):
        tag.decompose()
    lines = [l.rstrip() for l in soup.get_text("\n").split("\n")]
    out, blank = [], 0
    stop_words = {"About", "Legal:", "Terms of Service"}
    for line in lines:
        if line in stop_words and "About" in stop_words and len(out) > 40:
            break
        if not line:
            blank += 1
            if blank > 1:
                continue
            out.append("")
            continue
        blank = 0
        out.append(line)
    text = "\n".join(out).strip() + "\n"
    open(txt_path, "w", encoding="utf-8").write(text)
    return text


def field(text, label):
    m = re.search(r"^%s:\s*\n(.*)$" % re.escape(label), text, re.M | re.I)
    return (m.group(1).strip() if m else "")


def main():
    codes = [c.strip() for c in open(sys.argv[1]) if c.strip()]
    with cf.ThreadPoolExecutor(max_workers=2) as ex:
        texts = dict(zip(codes, ex.map(fetch, codes)))
    rows = []
    for code in codes:
        text = texts.get(code, "")
        title = ""
        m = re.search(r"^%s - (.*)$" % re.escape(code), text, re.M)
        if m:
            title = m.group(1).strip()
        rows.append("\t".join([
            code, title, field(text, "Time limit"), field(text, "Source limit"),
            field(text, "Memory limit"), field(text, "Languages") or "ALL",
            "todo" if text else "no_statement",
        ]))
        open(os.path.join(stmt_dir, code + ".txt"), "w", encoding="utf-8").write(text)
    print("\n".join(rows))


main()
