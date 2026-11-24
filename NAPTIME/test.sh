#!/bin/sh
set -u
NIM=${NIM:-nim}
cd "$(dirname "$0")"
LIMIT=1000
TL=$(( (LIMIT + 999) / 1000 + 1 ))
command -v timeout >/dev/null || { echo 'timeout command missing, refusing to run unbounded'; exit 1; }
guard() { timeout -k 1 "${TL}s" "$@"; }
SCRATCH=/tmp/opencode
code=$(basename "$(pwd)")
rm -rf build .nimcache .nimcache2 got_*.txt
"$NIM" c --version 2>&1 | head -1
timeout 600s "$NIM" c -d:release --nimcache:.nimcache --out:build/solution solution.nim || exit 1
timeout 600s "$NIM" c --nimcache:.nimcache2 --out:build/solution_judge solution.nim || exit 1
[ -f gen.py ] || { echo 'gen.py missing'; exit 1; }
timeout 300s python3 gen.py >/dev/null || { echo 'gen.py failed or ran over 300 s'; exit 1; }

fail=0
run() {
  guard "$1" < "in/$2.txt" > "got_$2.txt" 2>/dev/null
  run_code=$?
  if [ "$run_code" -ge 124 ]; then
    echo "TIMEOUT $2 killed at ${TL}s wall (judge ${LIMIT} ms)"
    rm -f "got_$2.txt"; fail=1; return
  fi
  if cmp -s "out/$2.out" "got_$2.txt"; then
    rm -f "got_$2.txt"
  else
    echo "FAIL $2"; rm -f "got_$2.txt"; fail=1
  fi
}

best() {
  w=99999999; b=0; k=1; to=0
  while [ $k -le 3 ]; do
    t0=$(date +%s%N)
    guard "$1" < "$2" > "$3"; run_code=$?
    t1=$(date +%s%N)
    ms=$(( (t1 - t0) / 1000000 )); [ "$ms" -lt "$w" ] && w=$ms
    b=$(wc -c < "$3"); [ "$run_code" -ge 124 ] && to=1
    k=$((k + 1))
  done
  [ "$to" -eq 0 ] || { echo "TIMEOUT killed at ${TL}s wall"; return 124; }
  printf "%s ms %s bytes\n" "$w" "$b"
}

verify() {
  binary=$1
  label=$2
  fail=0
  run "$binary" 1_sample
  [ "$fail" -eq 0 ] || { echo "$label sample failed"; return 1; }
  echo "$label sample OK"
  worst=0
  for f in in/*.txt; do
    name=$(basename "$f" .txt); [ "$name" = "1_sample" ] && continue
    t0=$(date +%s%N); run "$binary" "$name"; t1=$(date +%s%N)
    ms=$(( (t1 - t0) / 1000000 )); [ "$ms" -gt "$worst" ] && worst=$ms
  done
  echo "$label worst case $worst ms / $LIMIT ms limit"
  [ "$fail" -eq 0 ] || return 1
  [ "$worst" -ge "$LIMIT" ] && { echo "$label too slow"; return 1; }
  gate=$(ls -S in/*.txt | head -1)
  msg=$(best "$binary" "$gate" build/gate.txt); stat=$?
  echo "$label output gate $msg / $LIMIT ms limit (hard kill ${TL}s)"
  [ "$stat" -eq 0 ] || return 1
  for stress in "$SCRATCH/${code}_big.txt" "$SCRATCH/${code}_io_big.txt" "$SCRATCH/${code}_io_parse.txt"; do
    [ -f "$stress" ] || continue
    msg=$(best "$binary" "$stress" build/stress.txt); stat=$?
    echo "$label stress $stress $msg / $LIMIT ms limit"
    [ "$stat" -eq 0 ] || return 1
  done
  [ "$fail" -eq 0 ] || return 1
  echo "$label generalized OK"
  return 0
}

verify build/solution release || exit 1
verify build/solution_judge judge || exit 1
exit 0
