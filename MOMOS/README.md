# MOMOS — FEASTOFPIGS (SPOJ)
<https://www.spoj.com/problems/MOMOS/>

## Problem

Count the momos left after pigs eat every indexed momo divisible by their hunger value.

Momos are numbered 0 through N-1.
A pig with hunger a eats momo i when i divided by a leaves remainder zero.
A momo eaten once is gone, so overlaps count only once.
The input gives N and K on the first line, then K hunger values on separate lines.
Output one integer: the number of momos still on the table.

| item | bound |
|---|---|
| momos N, small case | 1 to 1000000, with K at most 100 |
| momos N, large case | 1 to 100000000000000, with K at most 20 |
| hunger of each pig | 1 to N |
| judge limit | 2000 ms, 1536 MB |

The two regimes need different methods because N can reach a large value.

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

Use a marking sheet when the row is short, and count marks with inclusion-exclusion when the row is huge.

When K exceeds twenty, N is at most a million, so a boolean array can mark each eaten momo directly.
When K is at most twenty, only two to the K subsets exist.
Each subset contributes the count of multiples of its least common multiple, with a sign from the subset size.
Hunger values that divide another hunger value are dropped first because their momos are already covered.

The input regime decides which exact method runs.

## Why It Works

1. A pig eats exactly the multiples of its hunger, including momo zero.
2. The number of multiples of L in the range 0 through N-1 is (N-1) divided by L, plus one.
3. Inclusion-exclusion adds odd subsets and subtracts even subsets to count each momo once.
4. If hunger a divides hunger b, every multiple of b is also a multiple of a, so b is redundant.
5. A least common multiple above N is capped at N to avoid overflow; it still covers momo zero.

| term | meaning |
|---|---|
| `momoCount` | the number of momos N |
| `hungerValues` | the hunger of each pig |
| `subsetLcms` | the capped least common multiple for each subset |
| `leftover` | the number of uneaten momos |

For the sample, the counts for hungers 3, 6 and 5 are 7, 4 and 4.
The pair intersections give 4, 2 and 1, and the triple intersection gives 1.
The union is 7 plus 4 plus 4 minus 4 minus 2 minus 1 plus 1, which is 9.
Twenty minus nine leaves 11 momos.

## Code

**Input, gcd and output helper.** The reader loads N, K and all hunger values, then sorts them.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

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

Sorting puts small divisors first, which makes the redundancy test simple.
The insertion sort avoids relying on a library comparator.

**Sieve or subsets.** Short rows are marked directly; large rows use capped least common multiples.

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
else:
  var keptHungers = newSeq[int64]()
  for hunger in hungerValues:
    var redundant = false
    for kept in keptHungers:
      if hunger mod kept == 0:
        redundant = true
        break
    if not redundant:
      keptHungers.add hunger

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

appendOutput($leftover)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The cap keeps products below the 64-bit limit and leaves the count for momo zero exact.
One final flush writes the answer line.

## Complexity

The two regimes have different costs.

| phase | time | space |
|---|---|---|
| input read | one pass over hungers | one input string |
| marking regime | N steps summed over pigs | one boolean per momo |
| subset regime | one pass over two to the K subsets | one integer per subset |

| measure | Big O |
|---|---|
| marking time | O(N times K) worst case |
| subset time | O(K times 2 to the K) |
| space | O(N) or O(2 to the K) |

Trying inclusion-exclusion with a hundred pigs would need far too many subsets.

Each regime uses the method that fits its stated bound.
