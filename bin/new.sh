#!/bin/sh
# Usage: bin/new.sh CODE LIMIT_MS   -- scaffold a problem dir with the standard harness
set -u
code=${1:?code}; limit=${2:?limit ms}
root=$(dirname "$0")/..
[ -d "$root/$code" ] && { echo "$code dir exists"; exit 1; }
mkdir -p "$root/$code/in" "$root/$code/out" "$root/$code/build"
sed "s/__LIMIT_MS__/$limit/" "$root/bin/test_template.sh" > "$root/$code/test.sh"
chmod +x "$root/$code/test.sh"
printf 'build/\nin/\nout/\ngot_*.txt\n.nimcache/\n__pycache__/\n' > "$root/$code/.gitignore"
echo "$code scaffold ready (limit ${limit} ms)"
