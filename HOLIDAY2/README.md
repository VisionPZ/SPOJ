# HOLIDAY2 — Getting Rid of the Holidays (Act II) (SPOJ)

<https://www.spoj.com/problems/HOLIDAY2/>

## Problem

A worker rests every `r` days, and every kept holiday must fall on a rest day. Drop exactly `k` holidays so that rhythm stays as long as possible.

Read `t` cases. Each case gives `n`, `k`, and `n` periods. Holiday `i` returns every `t_i` days, starting on day zero.

Print the removed holiday numbers in increasing order, numbered from 1 to `n`.

The limits set the size of the search:

| Quantity | Bound |
| --- | --- |
| Test cases `t` | at most 100 |
| Holidays `n` | at most 100 |
| Removals `k` | `1 <= k < n` |
| Period `t_i` | 1 to 10^18 |
| Time limit | 17000 ms |
| Memory limit | 1536 MB |
| Source limit | 4096 B |

The small holiday count makes a search over common divisors practical.

The sample cases:

```
2
6 4
1 3 4 5 6 1
8 4
200 125 200 999 380 500 200 500
```

```
1 3 4 6
2 4 5 8
```

## Idea

Think of a rhythm as a ruler whose marks fall every `r` days. A holiday fits only when its period lands exactly on a mark.

A valid rhythm divides every kept period, so the best one is a gcd (greatest common divisor) of the kept periods. The program builds candidate values by taking each period's gcd with values seen earlier. An open-addressed hash set stores those values without duplicates.

Then the program counts how many periods each candidate divides.

Cost per period: one gcd against each known candidate, then one divisibility test per candidate. Scanning every integer up to 10^18 cannot finish. Candidate gcds are few, so the search stays small.

## Why It Works

Four facts prove the search exact.

1. Holiday `i` falls on days `t_i`, `2t_i`, `3t_i`, and so on. Rest days are `r`, `2r`, `3r`, and so on. Every holiday lands on a rest day exactly when `r` divides `t_i`.
2. Let `m` be the number of kept holidays. If `d` divides at least `m` periods, their gcd is a multiple of `d` and divides at least `m` periods. An optimum therefore appears among the gcds of subsets of size `m`.
3. Processing periods in order and gcd-ing each with every known candidate generates every subset gcd. Each new subset either adds a period or keeps the earlier gcd.
4. The hash set uses a 64-bit multiplier and linear probing. Zero marks an empty slot because gcds of positive periods are positive.

The main values and their roles:

| Term | Meaning |
| --- | --- |
| `keepCount` | holidays left after the removals |
| `common` | gcd of an earlier candidate with the new period |
| `multiples` | periods divisible by the candidate rhythm |
| `bestRhythm` | largest candidate with enough supporting periods |
| `ValueSet` | open-addressed set holding unique candidates |
| `slotFor` | mixed hash index for one value |

These terms keep the search on divisor values, never on raw days.

A script computes this trace from the first sample case:

```
keep 2 of 6 periods [1, 3, 4, 5, 6, 1]
rhythm 3 divides 2 periods
rhythm 2 divides 2 periods
rhythm 1 divides 6 periods
best rhythm 3
removed holidays 1 3 4 6
```

The periods 3 and 6 support rhythm 3, so the program keeps them and removes holidays 1, 3, 4, and 6.

## Code

**Input and scanner.** One read loop loads the stream, and a hand scanner parses signed-digit values.

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

The loop ends at end of input, so blank lines cannot split a case. The scanner ignores non-digits, and all periods stay positive. It touches each input byte once.

**GCD and set.** `gcdOf` runs Euclid's rule, and `ValueSet` stores candidates without duplicates.

```nim
proc gcdOf(left: int64, right: int64): int64 =
  var first = left
  var second = right
  while second != 0:
    let rest = first mod second
    first = second
    second = rest
  first

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

The gcd loop stops when the remainder is zero. Zero marks an empty hash slot because candidate gcds stay positive. The table doubles at half load, so each insert stays cheap.

**Buffered output.** One string collects every answer line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes at `flushBlockBytes`, which avoids one write per number. Each flush clears the same string. Work stays proportional to the answer text.

**Case driver.** The loop builds candidates, picks the rhythm, and prints removals.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let holidayCount = int(nextInt(inputData, scanPos))
  let removeCount = int(nextInt(inputData, scanPos))
  var periods = newSeq[int64](holidayCount)
  for idx in 0 ..< holidayCount:
    periods[idx] = nextInt(inputData, scanPos)
  let keepCount = holidayCount - removeCount
  var seen: ValueSet
  seen.slots = newSeq[int64](1024)
  var candidates = newSeq[int64]()
  for value in periods:
    if not seen.inSet(value):
      seen.addSet(value)
      candidates.add value
    let before = candidates.len
    for idx in 0 ..< before:
      let common = gcdOf(candidates[idx], value)
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
  for idx in 0 ..< holidayCount:
    if periods[idx] mod bestRhythm == 0 and kept < keepCount:
      kept += 1
    else:
      removed.add idx + 1
  for idx in 0 ..< removed.len:
    if idx > 0:
      appendOutput " "
    appendOutput $(removed[idx])
  appendOutput "\n"

stdout.write outputBuffer
outputBuffer.setLen 0
```

The inner loop stops at `before`, the candidate count before the current period. New entries need no reprocessing there. The rhythm scan stops as soon as `keepCount` multiples appear.

The reconstruction keeps the first `keepCount` supporting holidays.

## Complexity

Candidate building and counting share the same nested shape.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | O(input bytes) | one input buffer |
| Candidate gcds | O(s * n) per case | O(s) candidates |
| Rhythm counting | O(s * n) per case | O(1) extra |
| Reconstruction and output | O(n + k) | O(k) removed numbers |

Here `s` is the number of unique candidate values.

| Measure | Big O |
| --- | --- |
| Time | O(s * n) per case |
| Space | O(s + n) plus I/O buffers |

A naive scan over every integer up to 10^18 would cost O(10^18 * n) time per case.
