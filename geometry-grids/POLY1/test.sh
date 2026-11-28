#!/bin/sh
set -u
NIM=${NIM:-nim}
cd "$(dirname "$0")"
LIMIT=5000
# Hard wall-clock kill on every program run, like the judge does.
# Judge limit is LIMIT ms; +1 s rounded up covers process start and disk flush on this box.
TL=$(( (LIMIT + 999) / 1000 + 1 ))
command -v timeout >/dev/null || { echo 'timeout command missing, refusing to run unbounded'; exit 1; }
guard() { timeout -k 1 "${TL}s" "$@"; }
rm -rf build .nimcache got_*.txt
"$NIM" c --version 2>&1 | head -1
timeout 600s "$NIM" c -d:release --nimcache:.nimcache --out:build/solution solution.nim || exit 1
# The judge builds Nim without -d:release; verify that exact build as well.
timeout 600s "$NIM" c --nimcache:.nimcache --out:build/solution_debug solution.nim || exit 1
[ -f gen.py ] || { echo 'gen.py missing'; exit 1; }
timeout 300s python3 gen.py >/dev/null || { echo 'gen.py failed or ran over 300 s'; exit 1; }
fail=0
run() {
  guard "$1" < "in/$2.txt" > "got_$2.txt" 2>/dev/null
  code=$?
  if [ "$code" -ge 124 ]; then
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
    guard "$1" < "$2" > "$3"; code=$?
    t1=$(date +%s%N)
    ms=$(( (t1 - t0) / 1000000 )); [ "$ms" -lt "$w" ] && w=$ms
    b=$(wc -c < "$3"); [ "$code" -ge 124 ] && to=1
    k=$((k + 1))
  done
  [ "$to" -eq 0 ] || { echo "TIMEOUT killed at ${TL}s wall"; return 124; }
  [ "$w" -lt "$LIMIT" ] || return 1
  printf "%s ms %s bytes\n" "$w" "$b"
}
run build/solution 1_sample
[ "$fail" -eq 0 ] || { echo "sample failed"; exit 1; }
echo "sample OK"
worst=0
for f in in/*.txt; do
  name=$(basename "$f" .txt); [ "$name" = "1_sample" ] && continue
  t0=$(date +%s%N); run build/solution "$name"; t1=$(date +%s%N)
  ms=$(( (t1 - t0) / 1000000 )); [ "$ms" -gt "$worst" ] && worst=$ms
done
echo "worst case $worst ms / $LIMIT ms limit"
[ "$fail" -eq 0 ] || exit 1
[ "$worst" -ge "$LIMIT" ] && { echo "too slow"; exit 1; }
# Per-problem scratch paths: a shared /tmp name lets one problem's stress file
# or gate output leak into another problem's run when harnesses run at once.
code=$(basename "$(pwd)")
time_msg=$(best build/solution in/3_wide.txt "/tmp/${code}_gate.txt"); stat=$?
echo "worst case gate $time_msg / $LIMIT ms limit (hard kill ${TL}s)"
[ "$stat" -eq 0 ] || exit 1
io_msg=$(best build/solution in/5_io.txt "/tmp/${code}_io_gate.txt"); stat=$?
echo "output gate $io_msg / $LIMIT ms limit (hard kill ${TL}s)"
[ "$stat" -eq 0 ] || exit 1
for stress in /tmp/${code}_big.txt /tmp/${code}_io_big.txt /tmp/${code}_io_parse.txt; do
  [ -f "$stress" ] || continue
  msg=$(best build/solution "$stress" "/tmp/${code}_stress.txt"); stat=$?
  echo "stress $stress $msg / $LIMIT ms limit"
  [ "$stat" -eq 0 ] || exit 1
done
for f in in/*.txt; do
  name=$(basename "$f" .txt)
  run build/solution_debug "$name"
done
echo "judge build (no -d:release) OK"
[ "$fail" -eq 0 ] || exit 1
judge_msg=$(best build/solution_debug in/3_wide.txt "/tmp/${code}_judge_gate.txt"); stat=$?
echo "judge build gate $judge_msg / $LIMIT ms limit (hard kill ${TL}s)"
[ "$stat" -eq 0 ] || exit 1
echo "generalized OK"
exit 0
