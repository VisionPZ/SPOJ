#!/bin/sh
# Usage: bin/submit_wave.sh CODE[:FILE]...  -- submit each source through Vivaldi, print verdict lines
set -u
root=$(dirname "$0")/..
for spec in "$@"; do
  code=${spec%%:*}
  file=${spec#*:}
  [ "$file" = "$code" ] && file="$root/$code/solution.nim"
  echo "== submit $code =="
  timeout 300 node "$root/bin/spoj_submit.mjs" "$code" "$file" --lang nim 2>&1 | grep -E "SUBMISSION|POST status|no nim|no debuggable|FAILED|language:" | tail -3
done
