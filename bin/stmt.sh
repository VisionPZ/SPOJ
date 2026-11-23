#!/bin/sh
# Usage: bin/stmt.sh PROB [more]
# Prints the SPOJ statement (text) for problem code PROB from the Wayback mirror.
# SPOJ itself Cloudflares every non-JS client, so direct fetch returns 403.
set -u
code=${1:?problem code required}
extra=""
[ "${2:-}" = more ] && extra="more"
cache="/tmp/spoj_stmt"
mkdir -p "$cache"
raw="$cache/$code.html"
txt="$cache/$code.txt"
[ -f "$txt" ] && [ "${extra:-}" != more ] && { cat "$txt"; exit 0; }
snap=$(curl -s -m 20 "http://archive.org/wayback/available?url=spoj.com/problems/$code/" \
  | python3 -c 'import json,sys; d=json.load(sys.stdin); s=d.get("archived_snapshots",{}).get("closest",{}); print(s.get("url",""))')
if [ -z "$snap" ]; then echo "no archive snapshot for $code" >&2; exit 1; fi
curl -sL -m 60 -o "$raw" "$snap" || { echo "fetch failed" >&2; exit 1; }
python3 - "$raw" "$txt" "$code" <<'PY'
import sys, re
from bs4 import BeautifulSoup
raw, txt, code = sys.argv[1], sys.argv[2], sys.argv[3]
soup = BeautifulSoup(open(raw, encoding="utf-8", errors="replace").read(), "html.parser")
for tag in soup(["script", "style"]):
    tag.decompose()
main = soup.find(id="problem") or soup.body or soup
text = main.get_text("\n")
keep, printing = [], False
for line in text.split("\n"):
    line = line.rstrip()
    if not line:
        if keep and keep[-1] == "":
            continue
        keep.append("")
        continue
    keep.append(line)
open(txt, "w").write("\n".join(keep).strip() + "\n")
sys.stdout.write("\n".join(keep).strip() + "\n")
PY
mv "$raw" "$raw" 2>/dev/null
exit 0
