# MOMOS — FEASTOFPIGS (SPOJ)

<https://www.spoj.com/problems/MOMOS/>

## Problem

N momos numbered 0 to N-1 sit in a row. K pigs attend, and the j-th pig has hunger a[j]. A pig eats every momo whose number is divisible by its hunger, so a pig with hunger 3 eats momos 0, 3, 6, and so on. A momo once eaten stays eaten. Count the momos left on the table.

The input guarantees one of two regimes: (N ≤ 10^6 and K ≤ 100) or (N ≤ 10^14 and K ≤ 20). Every hunger lies between 1 and N.

| item | bound |
|---|---|
| momos N | 10^6 with K ≤ 100, or 10^14 with K ≤ 20 |
| pigs K | 1 ≤ K ≤ 100 |
| hungers a[j] | 1 ≤ a[j] ≤ N |
| judge limit | 2000 ms, 1536 MB |

The two regimes need two different tools: a marking table for small N, a subset formula for small K.

Sample input:

```
20 3
3
6
5
```

Sample output:

```
11
```

## Idea

A pig eats exactly the multiples of its hunger, so the feast leaves the numbers that are not multiples of any hunger.

When K is large, N is at most 10^6, so the program can simply knock out every multiple of every hunger in a boolean table, like a sieve. When K is at most 20, N can be 10^14 and no table fits, so the program counts the union of the multiples by inclusion-exclusion over the 2^K subsets. A hunger that is a multiple of a smaller hunger is dropped first: its multiples were already eaten.

Takeaway: small N means a table, small K means subsets.

## Why It Works

1. A pig with hunger a eats exactly the multiples of a in 0..N-1.
2. If hunger h is a multiple of a kept hunger g, every multiple of h is a multiple of g, so h adds no new eaten momos and can be removed.
3. Inclusion-exclusion over the kept hungers counts each momo in the union exactly once: add odd-sized subsets, subtract even-sized ones.
4. The multiples of L in 0..N-1 are 0, L, 2L, ..., so their count is (N-1) div L + 1.
5. Each subset LCM is built from the subset with its lowest bit removed, one table entry per mask.
6. If a true LCM exceeds N it is clamped to N; both give count 1 because only momo 0 is divisible by a number larger than N-1.
7. The answer is N minus the union size.

For the sample, hunger 6 is a multiple of 3, so it is dropped. The kept hungers are 3 and 5. Multiples of 3: 7 momos. Multiples of 5: 4 momos. Multiples of 15: 2 momos. Eaten = 7 + 4 - 2 = 9, so 20 - 9 = 11 remain.

Momo 0 is divisible by everything, so with at least one pig it is always eaten, which the +1 in the count formula captures.

## Code

**Input and scanning.** The hand reader loads the file, parses 64-bit values, and provides the gcd used by the LCM table.

```nim
const flushBlockBytes = 1 shl 17
const subsetSwitch = 20

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  return value

proc gcdValues(firstValue, secondValue: int64): int64 =
  var larger = firstValue
  var smaller = secondValue
  while smaller != 0:
    let remainder = larger mod smaller
    larger = smaller
    smaller = remainder
  return larger
```

The scanner skips spaces and newlines.
`int64` holds N up to 10^14 exactly.

**Buffered output.** One string collects the answer line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Large outputs flush in blocks.
One final write closes the remaining text.

**Reading and sorting.** The hungers are sorted so redundancy checks see the smallest first.

```nim
let momoCount = nextInt(inputData, scanPos)
let pigCount = int(nextInt(inputData, scanPos))
var hungerValues = newSeq[int64](pigCount)
for pigIndex in 0 .. pigCount - 1:
  hungerValues[pigIndex] = nextInt(inputData, scanPos)

var insertionIndex = 1
while insertionIndex < hungerValues.len:
  let heldValue = hungerValues[insertionIndex]
  var shiftIndex = insertionIndex - 1
  while shiftIndex >= 0 and hungerValues[shiftIndex] > heldValue:
    hungerValues[shiftIndex + 1] = hungerValues[shiftIndex]
    shiftIndex -= 1
  hungerValues[shiftIndex + 1] = heldValue
  insertionIndex += 1
```

Insertion sort is fine for at most 100 values.

**Dense marking.** When K exceeds 20, N is at most 10^6 and a table is used.

```nim
var leftover: int64 = 0
if pigCount > subsetSwitch:
  var eatenMomos = newSeq[bool](int(momoCount))
  var eatenCount: int64 = 0
  for hunger in hungerValues:
    var position: int64 = 0
    while position < momoCount:
      let momoIndex = int(position)
      if not eatenMomos[momoIndex]:
        eatenMomos[momoIndex] = true
        eatenCount += 1
      position += hunger
  leftover = momoCount - eatenCount
```

Each pig walks its own multiples and counts only fresh momos.

**Dropping redundant hungers.** A hunger divisible by a kept one is skipped.

```nim
  var keptHungers = newSeq[int64]()
  for hunger in hungerValues:
    var redundant = false
    for kept in keptHungers:
      if hunger mod kept == 0:
        redundant = true
        break
    if not redundant:
      keptHungers.add hunger
```

**LCM table.** One entry per subset mask, built from the mask minus its lowest bit.

```nim
  let subsetCount = 1 shl keptHungers.len
  var subsetLcms = newSeq[int64](subsetCount)
  subsetLcms[0] = 1
  var subsetMask = 1
  while subsetMask < subsetCount:
    let lowBit = subsetMask and (-subsetMask)
    var bitIndex = 0
    var probe = lowBit
    while probe > 1:
      probe = probe shr 1
      bitIndex += 1
    let previousMask = subsetMask xor lowBit
    let previousLcm = subsetLcms[previousMask]
    let divisor = keptHungers[bitIndex]
    let common = gcdValues(previousLcm, divisor)
    if previousLcm div common > momoCount div divisor:
      subsetLcms[subsetMask] = momoCount
    else:
      subsetLcms[subsetMask] = previousLcm div common * divisor
    subsetMask += 1
```

The overflow test compares the quotient with N before multiplying.
A clamped LCM of N still counts exactly momo 0.

**Inclusion-exclusion.** Odd masks add, even masks subtract.

```nim
  var eatenCount: int64 = 0
  subsetMask = 1
  while subsetMask < subsetCount:
    let currentLcm = subsetLcms[subsetMask]
    let multipleCount = (momoCount - 1) div currentLcm + 1
    var bitCount = 0
    var probe = subsetMask
    while probe != 0:
      bitCount += probe and 1
      probe = probe shr 1
    if (bitCount and 1) == 1:
      eatenCount += multipleCount
    else:
      eatenCount -= multipleCount
    subsetMask += 1
  leftover = momoCount - eatenCount
```

The loop skips mask 0, the empty subset.

**Answer line.** The leftover count is written once.

```nim
appendOutput($leftover)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

## Complexity

The dense path touches each eaten momo a few times; the subset path runs once per mask.

| phase | time | space |
|---|---|---|
| read input | one pass over the file | one string |
| dense marking | sum of N / a[j] | N booleans |
| subset path | one step per mask | 2^K LCMs |
| output | one line | one block buffer |

| measure | Big O |
|---|---|
| time | O(N · K) or O(2^K), by regime |
| space | O(N) or O(2^K), by regime |

A table for N = 10^14 would need 100 TB, and 2^K subsets for K = 100 would be 2^100.

Takeaway: pick the tool that matches the guaranteed bound.
