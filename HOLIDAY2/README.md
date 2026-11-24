## Problem

There are `n` holidays, and holiday `i` returns every `t_i` days. Choose exactly `k` of them to remove so the longest work rhythm `r` remains valid. Workers rest every `r` days, so each kept period must be a multiple of `r`. Print the removed holiday numbers in increasing order, numbered from 1 to `n`.

The limits set the size of the search.

| Quantity | Bound |
| --- | --- |
| Test cases | t <= 100 |
| Holidays per case | n <= 100 |
| Removals | 1 <= k < n |
| Period | 1 <= t_i <= 10^18 |
| Time limit | 17000 ms |
| Memory limit | 1536 MB |
| Source limit | 4096 B |

The small holiday count makes a search over common divisors practical.

## Idea

The program searches greatest common divisors (gcds) of subsets instead of trying every rhythm. A rhythm works only when it divides every kept period, so the best one is a gcd of the kept periods. Scanning all integers up to 10^18 is impossible, while subset gcds are few.

Cost per period: one gcd against each known candidate.

## Why It Works

A holiday falls on days `t_i`, 2t_i, 3t_i, and so on. The days off are `r`, 2r, 3r, and so on. Every holiday lands on a day off exactly when `r` divides `t_i`.

Let `m` be the number of kept holidays. If a number `d` divides at least `m` periods, take their gcd. That gcd is a multiple of `d`. It also divides at least `m` periods. An optimum therefore appears among the gcds of subsets of size `m`.

Each formula term has one job:

`keepCount = holidayCount - removeCount` counts the holidays left after removals.

`common = gcdOf(candidates[j], value)` joins an earlier subset gcd with the new period.

`multiples >= keepCount` accepts a rhythm with enough supporting periods.

A script computes this example from the first sample case:

```
keep 2 of 6 periods [1, 3, 4, 5, 6, 1]
rhythm 3 divides 2 periods
rhythm 2 divides 2 periods
rhythm 1 divides 6 periods
best rhythm 3
removed holidays 1 3 4 6
```

The periods 3 and 6 support rhythm 3, so the program removes holidays 1, 3, 4 and 6.

## Code

The input loop reads the whole stream before parsing.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0'i64
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - firstDigitValue)
    pos += 1
  value
```
The loop ends at end of input, so blank lines cannot split a case. The scanner ignores non-digits, and periods are positive, so no sign branch is needed. It touches each input byte once.

The set stores candidates without duplicates.

```nim
proc gcdOf(left: int64, right: int64): int64 =
  var a = left
  var b = right
  while b != 0:
    let rest = a mod b
    a = b
    b = rest
  a

type ValueSet = object
  slots: seq[int64]
  used: int

proc slotFor(value: int64, mask: int): int =
  let mixed = uint64(value) * 11400714819323198485'u64
  int((mixed xor (mixed shr 29)) and uint64(mask))

proc growSet(store: var ValueSet) =
  var fresh = newSeq[int64](store.slots.len * 2)
  let mask = fresh.len - 1
  for value in store.slots:
    if value != 0:
      var idx = slotFor(value, mask)
      while fresh[idx] != 0:
        idx = (idx + 1) and mask
      fresh[idx] = value
  store.slots = fresh

proc inSet(store: var ValueSet, value: int64): bool =
  let mask = store.slots.len - 1
  var idx = slotFor(value, mask)
  while store.slots[idx] != 0:
    if store.slots[idx] == value:
      return true
    idx = (idx + 1) and mask
  false

proc addSet(store: var ValueSet, value: int64) =
  if (store.used + 1) * 2 >= store.slots.len:
    store.growSet()
  let mask = store.slots.len - 1
  var idx = slotFor(value, mask)
  while store.slots[idx] != 0 and store.slots[idx] != value:
    idx = (idx + 1) and mask
  if store.slots[idx] == 0:
    store.slots[idx] = value
    store.used += 1
```
The gcd loop runs until the remainder is zero. Zero marks an empty hash slot because gcds of positive periods are positive. The table doubles when half full, which keeps each insert cheap.

The output buffer batches all writes.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```
The buffer flushes when it reaches `flushBlockBytes`. This avoids one write per number. Each flush clears the same string.

The main loop selects the rhythm and the removals.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let holidayCount = int(nextInt(inputData, scanPos))
  let removeCount = int(nextInt(inputData, scanPos))
  var periods = newSeq[int64](holidayCount)
  for i in 0 ..< holidayCount:
    periods[i] = nextInt(inputData, scanPos)
  let keepCount = holidayCount - removeCount
  var seen: ValueSet
  seen.slots = newSeq[int64](1024)
  var candidates = newSeq[int64]()
  for value in periods:
    if not seen.inSet(value):
      seen.addSet(value)
      candidates.add value
    let before = candidates.len
    for j in 0 ..< before:
      let common = gcdOf(candidates[j], value)
      if not seen.inSet(common):
        seen.addSet(common)
        candidates.add common
  var bestRhythm = 0'i64
  for rhythm in candidates:
    if rhythm <= bestRhythm:
      continue
    var multiples = 0
    for period in periods:
      if period mod rhythm == 0:
        multiples += 1
        if multiples >= keepCount:
          break
    if multiples >= keepCount:
      bestRhythm = rhythm
  var removed = newSeq[int]()
  var kept = 0
  for i in 0 ..< holidayCount:
    if periods[i] mod bestRhythm == 0 and kept < keepCount:
      kept += 1
    else:
      removed.add i + 1
  for j in 0 ..< removed.len:
    if j > 0:
      appendOutput " "
    appendOutput $(removed[j])
  appendOutput "\n"

stdout.write outputBuffer
outputBuffer.setLen 0
```
The outer loop runs once per test case. The inner loop stops at `before`, the candidate count before the current period, so new entries need no reprocessing. The scan stops at `keepCount` multiples.

## Complexity

Reading and parsing touch each input byte once, at O(input size). Let `s` be the number of candidates and `n` the holiday count. Building candidates costs one gcd per candidate per period, at O(s * n). Counting costs one divisibility check per candidate per period, also O(s * n). Output writes `k` indices per case.

Total time is O(s * n) per case, where `s` is at most the number of divisors across the periods. Space is O(s + n) for the candidates and the periods, plus the input and output buffers. A naive scan over every integer up to 10^18 would cost O(10^18 * n) per case.
