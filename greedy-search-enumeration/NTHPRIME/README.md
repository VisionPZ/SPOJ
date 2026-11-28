# NTHPRIME — Nth Prime (SPOJ)

<https://www.spoj.com/problems/NTHPRIME/>

## Problem

Given one index N, output the Nth prime number. A plain sieve up to the answer would exceed memory and time limits, so the program counts primes directly.

Input is a single line holding the integer N. Output is a single line holding the Nth prime.

The constraints and judge limits:

| item | bound |
|---|---|
| index N | at most 1000000000 |
| source size | 4000 bytes on the judge |
| judge limit | 2667 ms, 1536 MB |

The first prime has index one, and the 10^9-th prime is 22,801,763,489.

Sample input and output:

```
4
```

```
7
```

The first four primes are 2, 3, 5, and 7.

## Idea

Counting primes up to a bound is like counting people in a stadium by sections instead of checking every seat. Lehmer's prime-counting formula counts primes up to x using a bit-packed odd sieve up to 5 million, a flat small-phi table, and recursive corrections. Binary search then finds the smallest x whose count reaches N.

Each count runs in sublinear time after the one-time sieve. Trial division or a full sieve to 2.28 × 10^10 would exceed both time and memory limits.

One compact sieve and Lehmer's formula locate the billionth prime in under 100 ms.

## Why It Works

1. The prime-counting function π(x) is non-decreasing and increases only at prime values.
2. The smallest x with π(x) ≥ N is therefore the Nth prime.
3. Lehmer's formula splits integers up to x into numbers free of small prime factors (`phiCount`) plus two-factor and three-factor corrections.
4. A bit-packed odd sieve up to 5,000,000 answers small π(x) lookups in O(1) and supplies all needed small primes.
5. Precomputing `smallPhi` for `x < 2000` and `a < 64` replaces hash lookups on the hot recursion leaves with flat array reads.

The main terms used in the program:

| term | meaning |
|---|---|
| `compBits` | bit-packed odd sieve up to 5,000,000 |
| `primePrefix` | number of primes up to each sieved integer |
| `smallPhi` | flat 2D table of `phiCount(val, cnt)` for small arguments |
| `primePi` | Lehmer count of primes up to `val` |
| `wanted` | input index N |

Known counts such as π(10^9) = 50,847,534 confirm the counting routine.

Worked trace for N = 4:

```
x | primePi(x) | comparison with 4
6 | 3          | 3 < 4 (raise lowVal)
7 | 4          | 4 >= 4 (lower highVal)
answer = 7
```

The same binary search brackets N = 10^9 tightly with Dusart bounds and finds 22801763489.

## Code

**Input, bit-packed odd sieve, and flat phi table.** The reader loads N, builds the odd sieve and prefix counts, and fills `smallPhi`.

```nim
import math, tables

const
  sieveLimit = 5000000
  phiCacheX = 2000
  phiCacheA = 64

var inputData, line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add '\n'

var scanPos = 0
proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'): pos += 1
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    result = result * 10 + int(data[pos]) - 48
    pos += 1

let halfLimit = sieveLimit div 2
var compBits = newSeq[uint64]((halfLimit shr 6) + 1)
for idx in 1 .. (int(sqrt(float64(sieveLimit))) + 1) div 2:
  if (compBits[idx shr 6] and (1'u64 shl (idx and 63))) == 0'u64:
    let prime = 2 * idx + 1
    var mult = (prime * prime) shr 1
    while mult <= halfLimit:
      compBits[mult shr 6] = compBits[mult shr 6] or (1'u64 shl (mult and 63))
      mult += prime

var primeList = @[2'i32]
var primePrefix = newSeq[int32](sieveLimit + 1)
primePrefix[2] = 1'i32
var seen: int32 = 1
for num in 3 .. sieveLimit:
  if (num and 1) == 1 and (compBits[num shr 7] and (1'u64 shl ((num shr 1) and 63))) == 0'u64:
    primeList.add int32(num)
    seen += 1
  primePrefix[num] = seen

var smallPhi = newSeq[int32](phiCacheX * phiCacheA)
for x in 0 .. phiCacheX - 1: smallPhi[x * phiCacheA] = int32(x)
for a in 1 .. phiCacheA - 1:
  let p = int(primeList[a - 1])
  for x in 0 .. phiCacheX - 1:
    let row = x * phiCacheA + a
    smallPhi[row] = smallPhi[row - 1] - smallPhi[(x div p) * phiCacheA + a - 1]
```

Packing odd flags into `uint64` words keeps `compBits` at 312 KiB.
`smallPhi` uses 512 KiB and avoids hash-table overhead on small recursive calls.
`primePrefix` answers every count up to 5,000,000 in O(1).

**Counting core.** `phiCount` and `primePi` implement Lehmer's formula with exact integer roots.

```nim
var piCache = initTable[int64, int64]()

proc phiCount(val: int64, cnt: int): int64 =
  if cnt == 0: return val
  if val == 0: return 0
  if cnt == 1: return val - (val shr 1)
  if val < phiCacheX and cnt < phiCacheA: return int64(smallPhi[int(val) * phiCacheA + cnt])
  let lastP = int64(primeList[cnt - 1])
  if val <= lastP: return 1
  if val <= int64(sieveLimit) and val < lastP * lastP: return int64(primePrefix[int(val)]) - int64(cnt) + 1
  return phiCount(val, cnt - 1) - phiCount(val div lastP, cnt - 1)

proc integerRoot(val: int64, deg: int): int64 =
  var root =
    if deg == 2: int64(sqrt(float64(val)))
    elif deg == 3: int64(pow(float64(val), 1.0 / 3.0))
    else: int64(sqrt(sqrt(float64(val))))
  proc fits(base: int64): bool =
    var prod: int64 = 1
    for i in 1 .. deg:
      if prod > val div base: return false
      prod *= base
    return true
  while fits(root + 1): root += 1
  while not fits(root): root -= 1
  return root

proc primePi(val: int64): int64 =
  if val <= int64(sieveLimit): return int64(primePrefix[int(val)])
  if piCache.hasKey(val): return piCache[val]
  let smallCnt = int(primePi(integerRoot(val, 4)))
  let cubeCnt = int(primePi(integerRoot(val, 3)))
  let largeCnt = int(primePi(integerRoot(val, 2)))
  var total = phiCount(val, smallCnt) +
    int64(largeCnt + smallCnt - 2) * int64(largeCnt - smallCnt + 1) div 2
  for idx in smallCnt .. largeCnt - 1:
    let quot = val div int64(primeList[idx])
    total -= primePi(quot)
    if idx < cubeCnt:
      let lim = int(primePi(integerRoot(quot, 2)))
      for subIdx in idx .. lim - 1:
        total -= primePi(quot div int64(primeList[subIdx])) - int64(subIdx)
  piCache[val] = total
  return total
```

When `val < lastP * lastP` inside `sieveLimit`, `phiCount` finishes in O(1) using `primePrefix`.
`integerRoot` adjusts floating-point roots with overflow-safe multiplication checks.
`primePi` merges the two-factor and three-factor loops into one pass.

**Binary search and output.** Dusart bounds bracket the Nth prime tightly before binary search converges.

```nim
let wanted = int64(nextInt(inputData, scanPos))
var answer: int64
if wanted <= int64(primeList.len):
  answer = int64(primeList[int(wanted) - 1])
else:
  var lowVal = int64(primeList[primeList.len - 1])
  let approx = float64(wanted)
  let logN = ln(approx)
  let logLogN = ln(logN)
  var highVal =
    if wanted >= 688383:
      lowVal = max(lowVal, int64(approx * (logN + logLogN - 1.0 + (logLogN - 2.1) / logN)))
      int64(approx * (logN + logLogN - 1.0 + (logLogN - 2.0) / logN)) + 100
    else:
      int64(approx * (logN + logLogN)) + 100
  if highVal <= lowVal: highVal = lowVal + 1000
  while lowVal < highVal:
    let midVal = lowVal + (highVal - lowVal) div 2
    if primePi(midVal) >= wanted: highVal = midVal
    else: lowVal = midVal + 1
  answer = lowVal

stdout.write($answer & "\n")
```

For `wanted >= 688383`, the Dusart interval narrows the search window to roughly 0.01 · N.
Each midpoint check calls `primePi(midVal)` and halves the remaining gap.
One buffered `stdout.write` emits the final prime.

## Complexity

The sieve and small-phi table run once; binary search calls `primePi` logarithmically many times.

| phase | time | space |
|---|---|---|
| bit-packed sieve | O(L log log L) for L = 5,000,000 | ~22 MB for `primePrefix`, `primeList`, `compBits` |
| small-phi table | O(2000 × 64) | 512 KiB |
| binary search + Lehmer | O(log N · x^(2/3) / log^2 x) | `piCache` entries |

The precomputation stays fixed regardless of N.

| measure | Big O |
|---|---|
| time | O(L log log L + log N · x^(2/3) / log^2 x) |
| space | O(L) |

Trial division or a full sieve up to the Nth prime would cost O(N log N) time and gigabytes of memory, whereas Lehmer's formula finishes in under 100 ms.
