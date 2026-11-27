# COPER — Crane Operator (SPOJ)

<https://www.spoj.com/problems/COPER/>

## Problem

Each case hides a target arrangement of boxes over numbered locations. The answer is the fewest crane moves that turn the starting arrangement into that target.

Input starts with T, the number of cases. Each of the next T lines holds six integers: N, M, q, p, m, d. Output one line per case with the minimum move count.

The recurrence sets c0 = 0 and c(i+1) = (c(i) * q + p) mod m. Box i goes to (c(i) + d*x + y) mod N, with x and y non-negative, avoiding M and all earlier destinations. Choose the smallest y first, then the smallest x. The forbidden location is `M mod N`, as the note on the judge page says.

The bounds from the statement:

| Item | Bound |
|---|---|
| Test cases T | at most 7 000 |
| Locations N | at most 1 000 000 |
| Forbidden location M | at most 1 000 000 |
| Step d | at most 1 000 000 |
| Recurrence values q, p, m | at most 10 000 |
| Judge limit | 40 s, 1 536 MB |

The million-location bound paired with up to 7 000 cases drives the design. Because `m <= 10 000`, the recurrence values repeat quickly and induce few distinct starting points inside each residue class.

Write `d_eff = d mod N` (replacing `0` by `1` for `N > 1`, since `d = 0` and `d = 1` visit slots in identical order `c_i, c_i + 1, ... mod N`), `g = gcd(d_eff, N)`, `n' = N / g`, and `d' = d_eff / g`. Because `1 <= d_eff < N`, we always have `n' >= 2`.

The sample case:

```
1
8 3 5 2 7 4
```

```
6
```

The sample answer is six moves.

## Idea

Instead of maintaining a million-bit bitmap and an 8 MB column lookup table, exploit the fact that every box starts at one of at most `m <= 10 000` values `c_i`.

Inside any residue class `row mod g`, the starting columns are `(c_i div g + carry) mod n'`. Sorting the distinct starting units splits the cyclic row into contiguous free intervals ("runs"). Each run stores two 32-bit integers: its next free location `slot` and its remaining capacity `cap`. Assigning a box simply reads `runs[r].slot`, advances `slot` by `+d mod N` in registers, and decrements `cap`. Only when a run exhausts (`cap == 0`) does a small DSU merge it into the next run.

Across all three regimes of `g` vs `maxC = max(c_i)`:

- **`g == 1`**: At most `streamLen <= m` runs in the single row (plus one split for `M mod N`). Once `activeRuns == 1`, all remaining boxes fill sequentially in a tight register loop.
- **`1 < g <= maxC + 1`**: At most `g * ((maxC div g) + 2) <= 30 000` runs total across all `g` rows, fitting inside L2 cache (~240 KB). Tracking `rowActiveRuns` eliminates per-box row fullness checks on the fast path.
- **`g > maxC + 1`**: Only rows `0 .. maxC` receive direct probes (with 2 runs each: carry 0 and carry 1). All remaining rows `maxC + 1 .. g - 1` collapse into a single virtual overflow row filled sequentially row by row.

For the second pass, a single-walker cycle trace stalls on L2/L3 cache latency (one dependent load in flight at a time). Running 24 independent walkers concurrently with work-stealing and write prefetching (`__builtin_prefetch`) keeps ~24 memory loads in flight in parallel. Every vertex in a permutation has in-degree 1, so a walker hitting a visited vertex can only meet one of the 24 active walker origins. Therefore 24 recycled tags detect cycles and merge paths in O(1) space.

Finally, normalized parameter tuples `(N, M mod N, q mod m, p mod m, m, d_eff)` are memoized in a fixed open-addressing hash table so repeated cases answer in O(1).

## Why It Works

Six facts carry the proof.

1. When `d mod N == 0`, `(c_i + 0*x + y) mod N` visits `c_i, c_i + 1, ... mod N`, identical to `d mod N == 1`. Replacing `0` with `1` ensures `1 <= d_eff < N`, so `g < N` and `n' >= 2`.
2. For fixed `y`, `d*x mod N` stays in one residue class `row = (c_i + y) mod g`, stepping by `d' = d_eff / g` through its `n'` columns. Multiplying columns by `stepInverse = (d')^{-1} mod n'` turns a step of `+d mod N` into `+1` unit.
3. Because `0 <= c_i <= maxC < m`, every starting column `(c_i div g + carry) mod n'` lies among at most `min(n', (maxC div g) + 2)` values. Partitioning each row at these sorted starting units creates runs whose slots advance strictly by `+d mod N` without any `columnFromUnit` table. Splitting at `excludedUnit` adds at most one extra run.
4. For `g > maxC + 1`, every `c_i < g`, so `c_i div g == 0`. Rows `maxC + 1 .. g - 1` are never probed directly and always enter with `carry == 0`, so they fill sequentially from unit `0` (`slot = row, row + d, ...`), skipping `M mod N` if encountered.
5. In the destination permutation `P` (`P(0) = M mod N`, `P(i) = dest(i)`), let `C` be the total cycle count and `F` the fixed-point count. Every nontrivial cycle of length `L > 1` costs `L + 1` moves except the cycle containing `0`, which costs `L - 1`. Summing gives `N + C - 2F - (2 if M mod N != 0 else 0)`.
6. In the 24-walker cycle counter, each active walker `k` owns a single open start vertex marked `-2 - tailTag[k]` (`owner[tailTag[k]] == k`), while internal vertices are marked `-1`. Because every vertex has in-degree 1, no walker can enter an internal vertex; any hit on `< 0` must land on some active start `u = owner[-2 - val]`. If `u == k`, a cycle closes (`cycles += 1`); otherwise `k`'s path prepends to `u`'s path by swapping `tailTag[u]` and `tailTag[k]`, immediately recycling the now-closed tag.

The terms and formulas:

| Term | Meaning |
|---|---|
| `d_eff` | effective step, `d mod N` (or `1` when `d mod N == 0`) |
| `g` | residue class count `gcd(d_eff, N)` |
| `n'` | slots per class `N / g` (always `>= 2`) |
| `stepInverse` | inverse of `d' = d_eff / g` modulo `n'` |
| `Run(cap, slot)` | remaining free slots and next actual slot in one cyclic interval |
| `walkerCount` | 24 concurrent cycle walkers exploiting memory-level parallelism |
| `totalMoves` | `N + cycles - 2 * fixed - (2 if excludedLocation != 0 else 0)` |

A trace of the sample case:

```
N=8 M=3 d=4 g=4 n1=2 dp=1 inv=1 excluded=3
box c class col row y startCol startUnit slot
  1 2     2   0   2 0        0         0    2
  2 5     1   1   1 0        1         1    5
  3 6     2   1   2 0        1         1    6
  4 4     0   1   0 0        1         1    4
  5 1     1   0   1 0        0         0    1
  6 0     0   0   0 0        0         0    0
  7 2     2   0   3 1        0         0    7
successor 0->3 1->2 2->5 3->6 4->4 5->1 6->0 7->7
cycles=4 fixed=2 excluded!=0 -> 8 + 4 - 4 - 2 = 6
```

## Code

Constants, types, and preallocated reused tables. Every buffer is allocated once globally.

```nim
{.push checks: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxLocationCount = 1000000
const maxRecurrenceModulus = 10000
const maxRuns = 32005
const walkerCount = 24
const memoBits = 14
const memoSize = 1 shl memoBits
const memoMask = memoSize - 1
const memoMaxLoad = (memoSize * 3) shr 2

type
  Run = object
    cap: int32
    slot: int32
  MemoEntry = object
    n: int32
    e: int32
    q: int32
    p: int32
    m: int32
    d: int32
    ans: int32
    used: int32

var generation = 0
var memoCount = 0

var runs = newSeq[Run](maxRuns)
var runNext = newSeq[int32](maxRuns)
var runParent = newSeq[int32](maxRuns)
var runRow = newSeq[int32](maxRuns)
var rowActiveRuns = newSeq[int32](maxRecurrenceModulus + 4)
var rowParent = newSeq[int32](maxRecurrenceModulus + 4)
var boxDestination = newSeq[int32](maxLocationCount + 1)

var valueStamp = newSeq[int](maxRecurrenceModulus + 1)
var valueIndex = newSeq[int32](maxRecurrenceModulus + 1)
var streamValues = newSeq[int32](maxRecurrenceModulus + 2)
var streamClass = newSeq[int32](maxRecurrenceModulus + 2)
var streamRow = newSeq[int32](maxRecurrenceModulus + 2)
var streamRun = newSeq[int32](maxRecurrenceModulus + 2)
var streamRank0 = newSeq[int32](maxRecurrenceModulus + 2)
var streamRank1 = newSeq[int32](maxRecurrenceModulus + 2)

var colStamp = newSeq[int](maxRecurrenceModulus + 4)
var sortKeys = newSeq[int32](maxRecurrenceModulus + 4)
var sortVals = newSeq[int32](maxRecurrenceModulus + 4)
var sortedU = newSeq[int32](maxRecurrenceModulus + 4)
var sortedCol = newSeq[int32](maxRecurrenceModulus + 4)
var rankOfCol = newSeq[int32](maxRecurrenceModulus + 4)
var baseCap = newSeq[int32](maxRecurrenceModulus + 4)
var baseOffset = newSeq[int32](maxRecurrenceModulus + 4)
var memoTable = newSeq[MemoEntry](memoSize)
```

`Run` packs capacity and slot into 8 bytes so each assignment hits one cache line. `maxRuns` holds the worst-case `<= 29 998` runs across all regimes plus the excluded-slot split.

Scanner, arithmetic, DSU, sorting, binary search, and hash helpers.

```nim
proc prefetchWrite(p: pointer, rw: cint = 1, loc: cint = 3) {.importc: "__builtin_prefetch", nodecl.}

proc nextInt(inputData: string, scanPos: var int): int {.inline.} =
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return value

proc gcdValues(firstValue, secondValue: int): int {.inline.} =
  var dividend = firstValue
  var divisor = secondValue
  while divisor != 0:
    let remainder = dividend mod divisor
    dividend = divisor
    divisor = remainder
  return dividend

proc modInverse(value, modulus: int): int {.inline.} =
  if modulus == 1: return 0
  var oldCoeff = 0
  var coeff = 1
  var oldRem = modulus
  var rem = value mod modulus
  while rem != 0:
    let quotient = oldRem div rem
    let nextOldCoeff = coeff
    coeff = oldCoeff - quotient * coeff
    oldCoeff = nextOldCoeff
    let nextOldRem = rem
    rem = oldRem - quotient * rem
    oldRem = nextOldRem
  result = oldCoeff mod modulus
  if result < 0: result += modulus

proc find32(parent: var seq[int32], index: int32): int32 {.inline.} =
  var cursor = index
  var p = parent[cursor]
  while p != cursor:
    let gp = parent[p]
    parent[cursor] = gp
    cursor = gp
    p = parent[cursor]
  return cursor

proc sortPairs(keys, vals: var seq[int32], n: int) =
  var stackL: array[64, int]
  var stackR: array[64, int]
  if n <= 1: return
  stackL[0] = 0
  stackR[0] = n - 1
  var sp = 1
  while sp > 0:
    sp -= 1
    var lo = stackL[sp]
    var hi = stackR[sp]
    while hi - lo > 16:
      let mid = (lo + hi) shr 1
      if keys[mid] < keys[lo]:
        swap(keys[mid], keys[lo]); swap(vals[mid], vals[lo])
      if keys[hi] < keys[lo]:
        swap(keys[hi], keys[lo]); swap(vals[hi], vals[lo])
      if keys[hi] < keys[mid]:
        swap(keys[hi], keys[mid]); swap(vals[hi], vals[mid])
      let pivot = keys[mid]
      var i = lo
      var j = hi
      while true:
        while keys[i] < pivot: i += 1
        while keys[j] > pivot: j -= 1
        if i >= j: break
        swap(keys[i], keys[j]); swap(vals[i], vals[j])
        i += 1
        j -= 1
      if j - lo < hi - j:
        if j + 1 < hi:
          stackL[sp] = j + 1; stackR[sp] = hi; sp += 1
        hi = j
      else:
        if lo < j:
          stackL[sp] = lo; stackR[sp] = j; sp += 1
        lo = j + 1
    for i in lo + 1 .. hi:
      let k = keys[i]
      let v = vals[i]
      var j = i - 1
      while j >= lo and keys[j] > k:
        keys[j + 1] = keys[j]
        vals[j + 1] = vals[j]
        j -= 1
      keys[j + 1] = k
      vals[j + 1] = v

proc findIntervalIdx(sortedU: seq[int32], kCount: int, uE: int32): int {.inline.} =
  if uE < sortedU[0]:
    return kCount - 1
  var lo = 0
  var hi = kCount - 1
  while lo < hi:
    let mid = (lo + hi + 1) shr 1
    if sortedU[mid] <= uE:
      lo = mid
    else:
      hi = mid - 1
  return lo

template addModN(s, d32, n32: int32): int32 =
  let tmp = s + d32 - n32
  if tmp < 0: tmp + n32 else: tmp

proc mixHash(n, e, q, p, m, d: int32): int {.inline.} =
  var h = uint64(uint32(n)) * 0x9e3779b97f4a7c15'u64
  h = (h xor uint64(uint32(e))) * 0xbf58476d1ce4e5b9'u64
  h = (h xor ((uint64(uint32(q)) shl 16) or uint64(uint32(p)))) * 0x94d049bb133111eb'u64
  h = (h xor ((uint64(uint32(m)) shl 24) or uint64(uint32(d)))) * 0x9e3779b97f4a7c15'u64
  h = h xor (h shr 30)
  return int(h and uint64(memoMask))
```

`sortPairs` sorts up to `m` `(unit, index)` pairs in place with median-of-three iterative quicksort and insertion sort. `addModN` compiles to branchless conditional move arithmetic.

Multi-walker cycle counter with work-stealing and write prefetching.

```nim
proc countCyclesSimple(n: int, excludedLocation: int): int =
  let dest = cast[ptr array[maxLocationCount + 1, int32]](addr boxDestination[0])
  var cycles = 0
  var fixed = 0
  for startSlot in 0 .. n - 1:
    var cur = dest[startSlot]
    if cur < 0: continue
    cycles += 1
    if cur == int32(startSlot):
      fixed += 1
      continue
    dest[startSlot] = -1'i32
    while cur != int32(startSlot):
      let nxt = dest[cur]
      dest[cur] = -1'i32
      cur = nxt
  result = n + cycles - 2 * fixed
  if excludedLocation != 0: result -= 2

proc countCyclesMulti(n: int, excludedLocation: int): int =
  if n <= walkerCount * 4:
    return countCyclesSimple(n, excludedLocation)
  var head: array[walkerCount, int32]
  var tailTag: array[walkerCount, int32]
  var owner: array[walkerCount, int32]
  var scanPos: array[walkerCount, int32]
  var scanEnd: array[walkerCount, int32]
  var active: array[walkerCount, bool]
  var cycles = 0
  var fixed = 0
  var activeCount = 0

  let dest = cast[ptr array[maxLocationCount + 1, int32]](addr boxDestination[0])
  let chunk = n div walkerCount
  for k in 0 .. walkerCount - 1:
    scanPos[k] = int32(k * chunk)
    scanEnd[k] = if k == walkerCount - 1: int32(n) else: int32((k + 1) * chunk)
    tailTag[k] = int32(k)
    owner[k] = int32(k)
    active[k] = true
    activeCount += 1

  template grabNext(k: int) =
    block grabBlock:
      while true:
        var sp = scanPos[k]
        let se = scanEnd[k]
        while sp < se:
          let nxt = dest[sp]
          if nxt >= 0:
            if nxt == sp:
              cycles += 1
              fixed += 1
              sp += 1
            else:
              dest[sp] = -2'i32 - tailTag[k]
              head[k] = nxt
              scanPos[k] = sp + 1
              break grabBlock
          else:
            sp += 1
        scanPos[k] = sp
        var bestIdx = -1
        var bestRem = 1'i32
        for j in 0 .. walkerCount - 1:
          let rem = scanEnd[j] - scanPos[j]
          if rem > bestRem:
            bestRem = rem
            bestIdx = j
        if bestIdx >= 0:
          let mid = scanPos[bestIdx] + (bestRem shr 1)
          scanPos[k] = mid
          scanEnd[k] = scanEnd[bestIdx]
          scanEnd[bestIdx] = mid
          continue
        active[k] = false
        activeCount -= 1
        break grabBlock

  for k in 0 .. walkerCount - 1:
    grabNext(k)

  while activeCount == walkerCount:
    for k in 0 .. walkerCount - 1:
      let h = head[k]
      let nxt = dest[h]
      if nxt >= 0:
        dest[h] = -1'i32
        head[k] = nxt
        prefetchWrite(addr dest[nxt], 1, 3)
      else:
        let hitTag = -2'i32 - nxt
        let u = owner[hitTag]
        if u == int32(k):
          cycles += 1
        else:
          let myTag = tailTag[k]
          tailTag[u] = myTag
          owner[myTag] = u
          tailTag[k] = hitTag
          owner[hitTag] = int32(k)
        grabNext(k)

  while activeCount > 0:
    for k in 0 .. walkerCount - 1:
      if not active[k]: continue
      let h = head[k]
      let nxt = dest[h]
      if nxt >= 0:
        dest[h] = -1'i32
        head[k] = nxt
      else:
        let hitTag = -2'i32 - nxt
        let u = owner[hitTag]
        if u == int32(k):
          cycles += 1
        else:
          let myTag = tailTag[k]
          tailTag[u] = myTag
          owner[myTag] = u
          tailTag[k] = hitTag
          owner[hitTag] = int32(k)
        grabNext(k)

  result = n + cycles - 2 * fixed
  if excludedLocation != 0: result -= 2
```

Small cases fall back to `countCyclesSimple`. Large cases split `[0, N)` into 24 slices; when a walker exhausts its slice it halves the largest remaining slice so all 24 walkers stay busy.

`countMoves` normalization, memoization lookup, recurrence stream build, and Regime 1 (`classCount == 1`).

```nim
proc countMoves(locationCount, emptyLocation, recurrenceMultiplier, recurrenceAdd,
                recurrenceModulus, step: int): int =
  if locationCount <= 1: return 0
  let excludedLocation = emptyLocation mod locationCount
  var dModN = step mod locationCount
  if dModN == 0: dModN = 1
  let qMod = recurrenceMultiplier mod recurrenceModulus
  let pMod = recurrenceAdd mod recurrenceModulus

  let n32 = int32(locationCount)
  let e32 = int32(excludedLocation)
  let q32 = int32(qMod)
  let p32 = int32(pMod)
  let m32 = int32(recurrenceModulus)
  let d32 = int32(dModN)

  var memoIdx = mixHash(n32, e32, q32, p32, m32, d32)
  while memoTable[memoIdx].used != 0:
    if memoTable[memoIdx].n == n32 and memoTable[memoIdx].e == e32 and
       memoTable[memoIdx].q == q32 and memoTable[memoIdx].p == p32 and
       memoTable[memoIdx].m == m32 and memoTable[memoIdx].d == d32:
      return int(memoTable[memoIdx].ans)
    memoIdx = (memoIdx + 1) and memoMask

  let classCount = gcdValues(dModN, locationCount)
  let slotsPerClass = locationCount div classCount
  let stepPerClass = dModN div classCount
  let stepInverse = modInverse(stepPerClass, slotsPerClass)

  generation += 1
  var streamLen = 0
  var curVal = 0
  var maxC = 0
  while valueStamp[curVal] != generation:
    valueStamp[curVal] = generation
    valueIndex[curVal] = int32(streamLen)
    streamValues[streamLen] = int32(curVal)
    if curVal > maxC: maxC = curVal
    streamLen += 1
    curVal = (curVal * qMod + pMod) mod recurrenceModulus
  let cycleStart = int(valueIndex[curVal])

  var streamIndex = 1
  if streamIndex >= streamLen: streamIndex = cycleStart

  let runsP = cast[ptr array[maxRuns, Run]](addr runs[0])
  let destP = cast[ptr array[maxLocationCount + 1, int32]](addr boxDestination[0])
  let srP = cast[ptr array[maxRecurrenceModulus + 2, int32]](addr streamRun[0])

  if classCount == 1:
    for si in 0 .. streamLen - 1:
      let col = int(streamValues[si]) mod locationCount
      let u = int32((int64(stepInverse) * int64(col)) mod int64(locationCount))
      sortKeys[si] = u
      sortVals[si] = int32(si)
    sortPairs(sortKeys, sortVals, streamLen)
    var kCount = 0
    for idx in 0 .. streamLen - 1:
      let u = sortKeys[idx]
      let si = int(sortVals[idx])
      if kCount == 0 or sortedU[kCount - 1] != u:
        sortedU[kCount] = u
        sortedCol[kCount] = int32(int(streamValues[si]) mod locationCount)
        kCount += 1
      srP[si] = int32(kCount - 1)
    for j in 0 .. kCount - 2:
      runsP[j] = Run(cap: sortedU[j + 1] - sortedU[j], slot: sortedCol[j])
      runNext[j] = int32(j + 1)
      runParent[j] = int32(j)
    runsP[kCount - 1] = Run(cap: n32 - sortedU[kCount - 1] + sortedU[0], slot: sortedCol[kCount - 1])
    runNext[kCount - 1] = 0'i32
    runParent[kCount - 1] = int32(kCount - 1)
    var activeRuns = kCount

    let uE = int32((int64(stepInverse) * int64(excludedLocation)) mod int64(locationCount))
    let jE = findIntervalIdx(sortedU, kCount, uE)
    var off = uE - sortedU[jE]
    if off < 0: off += n32
    if off == 0:
      runsP[jE].slot = addModN(runsP[jE].slot, d32, n32)
      runsP[jE].cap -= 1
      if runsP[jE].cap == 0:
        runParent[jE] = runNext[jE]
        activeRuns -= 1
    else:
      let extra = kCount
      let rem = runsP[jE].cap - off - 1
      runsP[jE].cap = off
      let s = addModN(e32, d32, n32)
      runsP[extra] = Run(cap: rem, slot: s)
      runNext[extra] = runNext[jE]
      runNext[jE] = int32(extra)
      if rem == 0:
        runParent[extra] = runNext[extra]
      else:
        runParent[extra] = int32(extra)
        activeRuns += 1

    var boxNumber = 1
    var si = streamIndex
    while boxNumber < locationCount:
      if activeRuns == 1:
        var r = srP[si]
        if runsP[r].cap == 0: r = find32(runParent, r)
        var s = runsP[r].slot
        if d32 == 1'i32:
          let firstSpan = int(n32 - s)
          let remTotal = locationCount - boxNumber
          if firstSpan >= remTotal:
            for b in boxNumber .. locationCount - 1:
              destP[b] = s
              s += 1
          else:
            let mid = boxNumber + firstSpan
            for b in boxNumber .. mid - 1:
              destP[b] = s
              s += 1
            s = 0
            for b in mid .. locationCount - 1:
              destP[b] = s
              s += 1
        elif d32 == n32 - 1'i32:
          let firstSpan = int(s) + 1
          let remTotal = locationCount - boxNumber
          if firstSpan >= remTotal:
            for b in boxNumber .. locationCount - 1:
              destP[b] = s
              s -= 1
          else:
            let mid = boxNumber + firstSpan
            for b in boxNumber .. mid - 1:
              destP[b] = s
              s -= 1
            s = n32 - 1'i32
            for b in mid .. locationCount - 1:
              destP[b] = s
              s -= 1
        else:
          for b in boxNumber .. locationCount - 1:
            destP[b] = s
            s = addModN(s, d32, n32)
        break
      var chunk = streamLen - si
      let remBoxes = locationCount - boxNumber
      if chunk > remBoxes: chunk = remBoxes
      let endSi = si + chunk - 1
      var b = boxNumber
      for siCur in si .. endSi:
        var r = srP[siCur]
        if runsP[r].cap == 0:
          r = find32(runParent, r)
          srP[siCur] = r
        let s = runsP[r].slot
        destP[b] = s
        b += 1
        runsP[r].slot = addModN(s, d32, n32)
        let rem = runsP[r].cap - 1
        runsP[r].cap = rem
        if rem == 0:
          runParent[r] = runNext[r]
          activeRuns -= 1
      boxNumber = b
      si += chunk
      if si == streamLen: si = cycleStart
```

Regime 2 (`1 < classCount <= maxC + 1`). Only the distinct columns appearing in the recurrence stream (and their carry-1 successors) split each row.

```nim
  elif classCount <= maxC + 1:
    var colCount = 0
    for si in 0 .. streamLen - 1:
      let c = int(streamValues[si])
      let bc = (c div classCount) mod slotsPerClass
      if colStamp[bc] != generation:
        colStamp[bc] = generation
        sortKeys[colCount] = int32((int64(stepInverse) * int64(bc)) mod int64(slotsPerClass))
        sortVals[colCount] = int32(bc)
        colCount += 1
      var bc1 = bc + 1
      if bc1 == slotsPerClass: bc1 = 0
      if colStamp[bc1] != generation:
        colStamp[bc1] = generation
        sortKeys[colCount] = int32((int64(stepInverse) * int64(bc1)) mod int64(slotsPerClass))
        sortVals[colCount] = int32(bc1)
        colCount += 1
    sortPairs(sortKeys, sortVals, colCount)
    for j in 0 .. colCount - 1:
      sortedU[j] = sortKeys[j]
      let col = sortVals[j]
      sortedCol[j] = col
      rankOfCol[col] = int32(j)
    for j in 0 .. colCount - 2:
      baseCap[j] = sortedU[j + 1] - sortedU[j]
      baseOffset[j] = int32(classCount) * sortedCol[j]
    baseCap[colCount - 1] = int32(slotsPerClass) - sortedU[colCount - 1] + sortedU[0]
    baseOffset[colCount - 1] = int32(classCount) * sortedCol[colCount - 1]

    var base = 0
    let k32 = int32(colCount)
    for row in 0 .. classCount - 1:
      let r32 = int32(row)
      for j in 0 .. colCount - 1:
        let idx = base + j
        runsP[idx] = Run(cap: baseCap[j], slot: r32 + baseOffset[j])
        runNext[idx] = int32(base + (if j + 1 < colCount: j + 1 else: 0))
        runParent[idx] = int32(idx)
        runRow[idx] = r32
      rowActiveRuns[row] = k32
      rowParent[row] = r32
      base += colCount
    rowParent[classCount] = int32(classCount)

    let eRow = excludedLocation mod classCount
    let eCol = excludedLocation div classCount
    let uE = int32((int64(stepInverse) * int64(eCol)) mod int64(slotsPerClass))
    let jE = findIntervalIdx(sortedU, colCount, uE)
    var off = uE - sortedU[jE]
    if off < 0: off += int32(slotsPerClass)
    let runE = eRow * colCount + jE
    if off == 0:
      runsP[runE].slot = addModN(runsP[runE].slot, d32, n32)
      runsP[runE].cap -= 1
      if runsP[runE].cap == 0:
        runParent[runE] = runNext[runE]
        rowActiveRuns[eRow] -= 1
    else:
      let extra = classCount * colCount
      let rem = runsP[runE].cap - off - 1
      runsP[runE].cap = off
      let s = addModN(e32, d32, n32)
      runsP[extra] = Run(cap: rem, slot: s)
      runNext[extra] = runNext[runE]
      runNext[runE] = int32(extra)
      runRow[extra] = int32(eRow)
      if rem == 0:
        runParent[extra] = runNext[extra]
      else:
        runParent[extra] = int32(extra)
        rowActiveRuns[eRow] += 1

    for si in 0 .. streamLen - 1:
      let c = int(streamValues[si])
      let cls = c mod classCount
      let bc = (c div classCount) mod slotsPerClass
      var bc1 = bc + 1
      if bc1 == slotsPerClass: bc1 = 0
      streamClass[si] = int32(cls)
      streamRow[si] = int32(cls)
      let r0 = rankOfCol[bc]
      streamRank0[si] = r0
      streamRank1[si] = rankOfCol[bc1]
      srP[si] = int32(cls * colCount) + r0

    let g32 = int32(classCount)
    var boxNumber = 1
    var si = streamIndex
    while boxNumber < locationCount:
      var chunk = streamLen - si
      let remBoxes = locationCount - boxNumber
      if chunk > remBoxes: chunk = remBoxes
      let endSi = si + chunk - 1
      var b = boxNumber
      for siCur in si .. endSi:
        var r = srP[siCur]
        if runsP[r].cap == 0:
          var row = streamRow[siCur]
          if rowActiveRuns[row] == 0:
            row = find32(rowParent, row)
            if row == g32:
              row = find32(rowParent, 0'i32)
            streamRow[siCur] = row
            let rk = if row < streamClass[siCur]: streamRank1[siCur] else: streamRank0[siCur]
            r = row * k32 + rk
            if runsP[r].cap == 0:
              r = find32(runParent, r)
          else:
            r = find32(runParent, r)
          srP[siCur] = r
        let s = runsP[r].slot
        destP[b] = s
        b += 1
        runsP[r].slot = addModN(s, d32, n32)
        let rem = runsP[r].cap - 1
        runsP[r].cap = rem
        if rem == 0:
          runParent[r] = runNext[r]
          let row = runRow[r]
          let ar = rowActiveRuns[row] - 1
          rowActiveRuns[row] = ar
          if ar == 0:
            rowParent[row] = row + 1
      boxNumber = b
      si += chunk
      if si == streamLen: si = cycleStart
```

Regime 3 (`classCount > maxC + 1`), bulk overflow fast path, cycle count call, and memo insertion.

```nim
  else:
    let rActive = maxC + 1
    let g32 = int32(classCount)
    let spc32 = int32(slotsPerClass)
    let inv32 = int32(stepInverse)
    let cap1 = spc32 - inv32
    var base = 0
    for row in 0 .. rActive - 1:
      let r32 = int32(row)
      runsP[base] = Run(cap: inv32, slot: r32)
      runNext[base] = int32(base + 1)
      runParent[base] = int32(base)
      runRow[base] = r32
      runsP[base + 1] = Run(cap: cap1, slot: r32 + g32)
      runNext[base + 1] = int32(base)
      runParent[base + 1] = int32(base + 1)
      runRow[base + 1] = r32
      rowActiveRuns[row] = 2'i32
      rowParent[row] = r32
      base += 2
    let eRow = excludedLocation mod classCount
    let eCol = excludedLocation div classCount
    var overflowTotal = (classCount - rActive) * slotsPerClass
    if eRow >= rActive: overflowTotal -= 1
    rowActiveRuns[rActive] = int32(overflowTotal)
    rowParent[rActive] = int32(rActive)
    rowParent[rActive + 1] = int32(rActive + 1)
    var overflowRow = int32(rActive)
    var overflowSlot = int32(rActive)
    var overflowFree = spc32 - (if eRow == rActive: 1'i32 else: 0'i32)

    if eRow < rActive:
      let uE = int32((int64(stepInverse) * int64(eCol)) mod int64(slotsPerClass))
      var jE: int
      var off: int32
      if uE < inv32:
        jE = 0
        off = uE
      else:
        jE = 1
        off = uE - inv32
      let runE = eRow * 2 + jE
      if off == 0:
        runsP[runE].slot = addModN(runsP[runE].slot, d32, n32)
        runsP[runE].cap -= 1
        if runsP[runE].cap == 0:
          runParent[runE] = runNext[runE]
          rowActiveRuns[eRow] -= 1
      else:
        let extra = rActive * 2
        let rem = runsP[runE].cap - off - 1
        runsP[runE].cap = off
        let s = addModN(e32, d32, n32)
        runsP[extra] = Run(cap: rem, slot: s)
        runNext[extra] = runNext[runE]
        runNext[runE] = int32(extra)
        runRow[extra] = int32(eRow)
        if rem == 0:
          runParent[extra] = runNext[extra]
        else:
          runParent[extra] = int32(extra)
          rowActiveRuns[eRow] += 1

    for si in 0 .. streamLen - 1:
      let c = streamValues[si]
      streamClass[si] = c
      streamRow[si] = c
      srP[si] = c shl 1

    let rAct32 = int32(rActive)
    let rEnd32 = int32(rActive + 1)
    let eRow32 = int32(eRow)
    let cycleLen = streamLen - cycleStart
    var nonOverflowInCycle = cycleLen
    var boxNumber = 1
    var si = streamIndex
    while boxNumber < locationCount:
      if si >= cycleStart and nonOverflowInCycle == 0 and rowActiveRuns[rActive] > 0:
        var take = int(rowActiveRuns[rActive])
        let remBoxes = locationCount - boxNumber
        if take > remBoxes: take = remBoxes
        var b = boxNumber
        let bEnd = boxNumber + take
        if overflowRow == eRow32 or overflowFree != spc32:
          var rowTake = int(overflowFree)
          if b + rowTake > bEnd: rowTake = bEnd - b
          var s = overflowSlot
          if overflowRow == eRow32:
            for j in 0 .. rowTake - 1:
              if s == e32: s = addModN(s, d32, n32)
              destP[b] = s
              b += 1
              s = addModN(s, d32, n32)
          else:
            for j in 0 .. rowTake - 1:
              destP[b] = s
              b += 1
              s = addModN(s, d32, n32)
          overflowSlot = s
          overflowFree -= int32(rowTake)
          if overflowFree == 0:
            overflowRow += 1
            overflowSlot = overflowRow
            overflowFree = spc32
            if overflowRow == eRow32:
              overflowFree -= 1
        while b < bEnd:
          if overflowRow == eRow32:
            var rowTake = int(overflowFree)
            if b + rowTake > bEnd: rowTake = bEnd - b
            var s = overflowSlot
            for j in 0 .. rowTake - 1:
              if s == e32: s = addModN(s, d32, n32)
              destP[b] = s
              b += 1
              s = addModN(s, d32, n32)
            overflowSlot = s
            overflowFree -= int32(rowTake)
            if overflowFree == 0:
              overflowRow += 1
              overflowSlot = overflowRow
              overflowFree = spc32
            continue
          var maxRow = g32
          if overflowRow < eRow32: maxRow = eRow32
          let availRows = int(maxRow - overflowRow)
          let fullRowsByB = (bEnd - b) div slotsPerClass
          let fullRows = if availRows < fullRowsByB: availRows else: fullRowsByB
          if fullRows > 0:
            var rCur = overflowRow
            let rStop = rCur + int32(fullRows)
            if slotsPerClass == 2:
              while rCur < rStop:
                destP[b] = rCur
                destP[b + 1] = rCur + g32
                b += 2
                rCur += 1
            else:
              while rCur < rStop:
                var s = rCur
                for j in 0 .. slotsPerClass - 1:
                  destP[b] = s
                  b += 1
                  s = addModN(s, d32, n32)
                rCur += 1
            overflowRow = rStop
            overflowSlot = rStop
            overflowFree = spc32
            if overflowRow == eRow32:
              overflowFree -= 1
          else:
            let rowTake = bEnd - b
            var s = overflowSlot
            for j in 0 .. rowTake - 1:
              destP[b] = s
              b += 1
              s = addModN(s, d32, n32)
            overflowSlot = s
            overflowFree -= int32(rowTake)
        rowActiveRuns[rActive] -= int32(take)
        if rowActiveRuns[rActive] == 0:
          rowParent[rActive] = rEnd32
        boxNumber = bEnd
        si = cycleStart + ((si - cycleStart + take) mod cycleLen)
        continue

      var chunk = streamLen - si
      let remBoxes = locationCount - boxNumber
      if chunk > remBoxes: chunk = remBoxes
      let endSi = si + chunk - 1
      var b = boxNumber
      for siCur in si .. endSi:
        var r = srP[siCur]
        if r < 0:
          if rowActiveRuns[rActive] == 0:
            var row = find32(rowParent, 0'i32)
            streamRow[siCur] = row
            if siCur >= cycleStart: nonOverflowInCycle += 1
            let carry = if row < streamClass[siCur]: 1'i32 else: 0'i32
            r = (row shl 1) + carry
            if runsP[r].cap == 0:
              r = find32(runParent, r)
            srP[siCur] = r
            let s = runsP[r].slot
            destP[b] = s
            b += 1
            runsP[r].slot = addModN(s, d32, n32)
            let rem = runsP[r].cap - 1
            runsP[r].cap = rem
            if rem == 0:
              runParent[r] = runNext[r]
              let rr = runRow[r]
              let ar = rowActiveRuns[rr] - 1
              rowActiveRuns[rr] = ar
              if ar == 0:
                rowParent[rr] = rr + 1
          else:
            if overflowSlot == e32:
              overflowSlot = addModN(overflowSlot, d32, n32)
            destP[b] = overflowSlot
            b += 1
            overflowSlot = addModN(overflowSlot, d32, n32)
            overflowFree -= 1
            if overflowFree == 0:
              overflowRow += 1
              overflowSlot = overflowRow
              overflowFree = spc32
              if overflowRow == eRow32:
                overflowFree -= 1
            let rf = rowActiveRuns[rActive] - 1
            rowActiveRuns[rActive] = rf
            if rf == 0:
              rowParent[rActive] = rEnd32
        else:
          if runsP[r].cap == 0:
            var row = streamRow[siCur]
            if rowActiveRuns[row] == 0:
              row = find32(rowParent, row)
              if row == rEnd32:
                row = find32(rowParent, 0'i32)
              streamRow[siCur] = row
              if row == rAct32:
                srP[siCur] = -1'i32
                if siCur >= cycleStart: nonOverflowInCycle -= 1
                if overflowSlot == e32:
                  overflowSlot = addModN(overflowSlot, d32, n32)
                destP[b] = overflowSlot
                b += 1
                overflowSlot = addModN(overflowSlot, d32, n32)
                overflowFree -= 1
                if overflowFree == 0:
                  overflowRow += 1
                  overflowSlot = overflowRow
                  overflowFree = spc32
                  if overflowRow == eRow32:
                    overflowFree -= 1
                let rf = rowActiveRuns[rActive] - 1
                rowActiveRuns[rActive] = rf
                if rf == 0:
                  rowParent[rActive] = rEnd32
                continue
              let carry = if row < streamClass[siCur]: 1'i32 else: 0'i32
              r = (row shl 1) + carry
              if runsP[r].cap == 0:
                r = find32(runParent, r)
            else:
              r = find32(runParent, r)
            srP[siCur] = r
          let s = runsP[r].slot
          destP[b] = s
          b += 1
          runsP[r].slot = addModN(s, d32, n32)
          let rem = runsP[r].cap - 1
          runsP[r].cap = rem
          if rem == 0:
            runParent[r] = runNext[r]
            let rr = runRow[r]
            let ar = rowActiveRuns[rr] - 1
            rowActiveRuns[rr] = ar
            if ar == 0:
              rowParent[rr] = rr + 1
      boxNumber = b
      si += chunk
      if si == streamLen: si = cycleStart

  destP[0] = e32
  result = countCyclesMulti(locationCount, excludedLocation)
  if memoCount < memoMaxLoad:
    memoTable[memoIdx] = MemoEntry(n: n32, e: e32, q: q32, p: p32, m: m32, d: d32, ans: int32(result), used: 1'i32)
    memoCount += 1
```

Driver. Single `readAll(stdin)` read and block-flushed output.

```nim
let inputData = readAll(stdin)
var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = newStringOfCap(flushBlockBytes + 64)
for caseIndex in 0 .. caseCount - 1:
  let locationCount = nextInt(inputData, scanPos)
  let emptyLocation = nextInt(inputData, scanPos)
  let recurrenceMultiplier = nextInt(inputData, scanPos)
  let recurrenceAdd = nextInt(inputData, scanPos)
  let recurrenceModulus = nextInt(inputData, scanPos)
  let step = nextInt(inputData, scanPos)
  let answer = countMoves(locationCount, emptyLocation, recurrenceMultiplier,
                          recurrenceAdd, recurrenceModulus, step)
  outputBuffer.add $answer
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Memoization | O(1) expected lookup per case | fixed 512 KB open-addressing table |
| Per-case setup | O(K log K + g * K) with `g * K <= 3m` | <= 32 005 packed runs (~256 KB) |
| Configuration build | O(N) sequential destination writes + O(m alpha(m)) merges | 4 MB 32-bit destination array |
| Move count | O(N) 24-way parallel cycle walk | O(1) walker state (in-place tags) |
| Output | one write per block | block buffer |

The overall bounds:

| Measure | Big O |
|---|---|
| Time | O(N + m log m) per distinct case, O(1) per repeated normalized tuple |
| Space | O(N + m) globally reused buffers (~5 MB total) |
