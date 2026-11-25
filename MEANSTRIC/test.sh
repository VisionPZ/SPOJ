#!/bin/sh
set -u
CC=${CC:-g++}
FLAGS=${FLAGS:--O2 -std=c++14}
cd "$(dirname "$0")"
LIMIT=1000
TL=$(( (LIMIT + 999) / 1000 + 1 ))
command -v timeout >/dev/null || { echo 'timeout command missing, refusing to run unbounded'; exit 1; }
guard() { timeout -k 1 "${TL}s" "$@"; }
rm -rf build got_*.txt
mkdir -p build
"$CC" --version 2>&1 | head -1
timeout 600s "$CC" $FLAGS -o build/solution solution.cpp || exit 1
[ -f gen.py ] || { echo 'gen.py missing'; exit 1; }
timeout 300s python3 gen.py >/dev/null || { echo 'gen.py failed or ran over 300 s'; exit 1; }
fail=0
fcmp() {
  python3 -c '
import sys
a = open(sys.argv[1]).read().split()
b = open(sys.argv[2]).read().split()
if len(a) != len(b):
    sys.exit(1)
for x, y in zip(a, b):
    if abs(float(x) - float(y)) > 1.1e-9:
        sys.exit(1)
' "$1" "$2"
}
run() {
  guard build/solution < "in/$1.txt" > "got_$1.txt" 2>/dev/null
  code=$?
  if [ "$code" -ge 124 ]; then
    echo "TIMEOUT $1 killed at ${TL}s wall (judge ${LIMIT} ms)"
    rm -f "got_$1.txt"; fail=1; return
  fi
  if fcmp "out/$1.out" "got_$1.txt"; then
    rm -f "got_$1.txt"
  else
    echo "FAIL $1"; rm -f "got_$1.txt"; fail=1
  fi
}
best() {
  w=99999999; b=0; k=1; to=0
  while [ $k -le 3 ]; do
    t0=$(date +%s%N)
    guard build/solution < "$1" > "$2"; code=$?
    t1=$(date +%s%N)
    ms=$(( (t1 - t0) / 1000000 )); [ "$ms" -lt "$w" ] && w=$ms
    b=$(wc -c < "$2"); [ "$code" -ge 124 ] && to=1
    k=$((k + 1))
  done
  [ "$to" -eq 0 ] || { echo "TIMEOUT killed at ${TL}s wall"; return 124; }
  printf "%s ms %s bytes\n" "$w" "$b"
}
run 1_sample
[ "$fail" -eq 0 ] || { echo "sample failed"; exit 1; }
guard build/solution < in/1_sample.txt > got_sample_exact.txt 2>/dev/null
cmp -s out/1_sample.out got_sample_exact.txt || { echo "sample bytes differ"; exit 1; }
rm -f got_sample_exact.txt
echo "sample OK"
worst=0
for f in in/*.txt; do
  name=$(basename "$f" .txt); [ "$name" = "1_sample" ] && continue
  t0=$(date +%s%N); run "$name"; t1=$(date +%s%N)
  ms=$(( (t1 - t0) / 1000000 )); [ "$ms" -gt "$worst" ] && worst=$ms
done
echo "worst case $worst ms / $LIMIT ms limit"
[ "$fail" -eq 0 ] || exit 1
[ "$worst" -ge "$LIMIT" ] && { echo "too slow"; exit 1; }
code=$(basename "$(pwd)")
gate=$(ls -S in/*.txt | head -1)
msg=$(best "$gate" "/tmp/${code}_gate.txt"); stat=$?
echo "output gate $msg / $LIMIT ms limit (hard kill ${TL}s)"
[ "$stat" -eq 0 ] || exit 1
for stress in /tmp/${code}_big.txt /tmp/${code}_io_big.txt /tmp/${code}_io_parse.txt; do
  [ -f "$stress" ] || continue
  msg=$(best "$stress" "/tmp/${code}_stress.txt"); stat=$?
  echo "stress $stress $msg / $LIMIT ms limit"
  [ "$stat" -eq 0 ] || exit 1
done
[ "$fail" -eq 0 ] || exit 1
echo "generalized OK"
exit 0
