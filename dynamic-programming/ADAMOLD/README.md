# ADAMOLD — Ada and Mold (SPOJ)

<https://www.spoj.com/problems/ADAMOLD/>

## Problem

A row of plants has a bloom value each. Place K separators to split the row into K plus one segments so that the total pairwise xor mold value is smallest.

The first line gives N and K. The next line or lines give the N bloom values. Output one integer, the minimal mold value; it can exceed 32 bits.

| item | bound |
|---|---|
| plants N | 1 to 5000 |
| separators K | 1 to N minus one |
| bloom value | 0 to 10 to the 9 |
| judge limit | 5000 ms, 1536 MB |

The number of segments drives the dynamic program; the xor pairs need 64 bit sums.

Sample input:

```
6 1
1 2 3 4 5 6
```

Sample output:

```
12
```

## Idea

Split the row at the best places, like choosing where to cut a ribbon so the crooked parts stay together. For one segment, count ones and zeros at each bit; the bit contributes ones times zeros times the bit value. Prefix counts give that cost in one short loop. A dynamic program then tries every cut for every segment and keeps the cheapest. Recounting all pairs for each cut would take far longer. Prefix bit counts make each candidate cut cheap.

## Why It Works

1. The xor of a pair is the sum over bits where the two values differ.
2. At one bit, each one pairs with each zero, giving ones times zeros differing pairs.
3. `onePrefix` counts ones up to any position, so a segment cost needs 31 subtractions.
4. `previousCosts` holds the best cost for a fixed number of segments and end position.
5. Trying every split position adds one segment cost and keeps the smallest total.
6. After K separators, `previousCosts` at the last plant is the answer.

| term | meaning |
|---|---|
| `segmentCost` | pairwise xor sum of one segment |
| `onePrefix` | count of ones at each bit up to each position |
| `previousCosts` | best cost for the current segment count |
| `currentCosts` | best cost while adding the next segment |
| `infiniteCost` | sentinel used before a candidate is found |

The table names every quantity that the dynamic program carries.

A script trace of the sample with one separator:

| split after | left cost | right cost | total |
|---|---|---|---|
| 1 | 0 | 42 | 42 |
| 2 | 3 | 24 | 27 |
| 3 | 6 | 6 | 12 |
| 4 | 24 | 3 | 27 |
| 5 | 42 | 0 | 42 |

The minimum twelve matches the sample output.

Costs use `int64` because a single segment can exceed two billion.

## Code

**Input and segment cost.** The reader loads the row, and prefix ones make each segment cost cheap.

```nim
const flushBlockBytes = 1 shl 17
const bitWidth = 31

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc segmentCost(leftIndex: int, rightIndex: int, prefixStride: int, onePrefix: seq[int64]): int64 =
  let segmentLength = int64(rightIndex - leftIndex)
  var totalCost: int64 = 0
  for bitIndex in 0 .. bitWidth - 1:
    let prefixBase = bitIndex * prefixStride
    let onesCount = onePrefix[prefixBase + rightIndex] - onePrefix[prefixBase + leftIndex]
    let zerosCount = segmentLength - onesCount
    totalCost = totalCost + (int64(1) shl bitIndex) * onesCount * zerosCount
  return totalCost

let bloomCount = nextInt(inputData, scanPos)
let separatorCount = nextInt(inputData, scanPos)
var bloomValues = newSeq[int64](bloomCount)
for valueIndex in 0 .. bloomCount - 1:
  bloomValues[valueIndex] = int64(nextInt(inputData, scanPos))

let prefixStride = bloomCount + 1
var onePrefix = newSeq[int64](bitWidth * prefixStride)
for bitIndex in 0 .. bitWidth - 1:
  let prefixBase = bitIndex * prefixStride
  for valueIndex in 0 .. bloomCount - 1:
    let oneBit = if ((bloomValues[valueIndex] shr bitIndex) and int64(1)) != 0: int64(1) else: int64(0)
    onePrefix[prefixBase + valueIndex + 1] = onePrefix[prefixBase + valueIndex] + oneBit
```

Each bit gets its own prefix row.
The segment cost reads two prefix entries per bit.
All 31 bits of a value are covered.

**Segment dynamic program.** Each row of the program adds one segment and tries every cut.

```nim
let infiniteCost = int64(1) shl 62
var previousCosts = newSeq[int64](bloomCount + 1)
var currentCosts = newSeq[int64](bloomCount + 1)
for rightIndex in 1 .. bloomCount:
  previousCosts[rightIndex] = segmentCost(0, rightIndex, prefixStride, onePrefix)

for segmentIndex in 2 .. separatorCount + 1:
  for rightIndex in 0 .. bloomCount:
    currentCosts[rightIndex] = infiniteCost
  for rightIndex in segmentIndex .. bloomCount:
    var bestCost = infiniteCost
    for splitIndex in segmentIndex - 1 .. rightIndex - 1:
      let candidateCost = previousCosts[splitIndex] + segmentCost(splitIndex, rightIndex, prefixStride, onePrefix)
      if candidateCost < bestCost:
        bestCost = candidateCost
    currentCosts[rightIndex] = bestCost
  for rightIndex in 0 .. bloomCount:
    let carriedCost = currentCosts[rightIndex]
    currentCosts[rightIndex] = previousCosts[rightIndex]
    previousCosts[rightIndex] = carriedCost

appendOutput($previousCosts[bloomCount])
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The split index leaves one plant for each later segment.
Rows are swapped by copying values, with no alias between them.
The final row is printed once after all separators.

## Complexity

Cost lookups dominate the dynamic program; each lookup touches 31 bit rows.

| phase | time | space |
|---|---|---|
| prefix build | N times 31 bit tests | 31 times N counts |
| first segment | N cost lookups | one cost array |
| later segments | K times N squared split trials | two cost arrays |
| output | one line | block buffer |

Each split trial costs 31 subtractions and multiplies.

| measure | Big O |
|---|---|
| time | O(K times N squared times 31) |
| space | O(N times 31) |

Enumerating all pairs inside every candidate segment is slower than using the prefix rows.

Prefix bit counts reduce each cut to a short formula and keep the dynamic program simple.
