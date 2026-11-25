# QTGIFT1 — New year love story (SPOJ)

<https://www.spoj.com/problems/QTGIFT1/>

## Problem

There are n money packs in a row. Take packs to maximize the total, but never take k packs in a row.

Input starts with n and k on one line, then n pack values on the next line.

Output a single number: the largest total DB can take.

| item | bound |
|---|---|
| packs n | at most 1000000 |
| forbidden run k | 1 to n |
| pack value | 0 to 2000 |
| judge limit | 1000 ms, 1536 MB |

The pack count drives the design toward a linear scan.

Sample input:

```
5 3
6 19 8 7 13
```

Sample output:

```
45
```

## Idea

Place skipped packs like toll booths along a road: no stretch of k exits may lack a booth, and you want the cheapest booths.

Every legal choice skips at least one pack in each group of k. Since all values are nonnegative, the best total skips the cheapest valid set. A cost scan finds that set with a sliding minimum over the last k positions. Checking every subset would grow exponentially, and a block-by-block dynamic program costs O(n times k).

The sliding minimum makes each pack cost constant time.

## Why It Works

1. Taking k packs in a row is forbidden, so a legal run holds at most k-1 taken packs.
2. Every group of k consecutive packs must contain at least one skipped pack.
3. The taken total equals the all-pack total minus the skipped values.
4. Skipped packs sit at most k positions apart, with at most k-1 taken packs at both ends.
5. The cost at position i uses the cheapest previous skip within k positions.
6. A monotone deque stores those candidate costs in increasing order, so the minimum is at its head.
7. The final skip must leave at most k-1 packs after it, and that gives the answer.

| term | meaning |
|---|---|
| `packCount` | number of packs |
| `skipLength` | forbidden consecutive run k |
| `totalSum` | sum of every pack value |
| `candidateIndex` | deque of skip positions in order |
| `candidateCost` | cost for each deque position |
| `headIndex` | front of the sliding window |
| `tailIndex` | insertion end of the deque |
| `bestPrevious` | cheapest valid earlier skip |
| `currentCost` | cheapest cost with a skip here |
| `minFinalCost` | cheapest cost among valid last skips |
| `bestMoney` | maximum money DB can take |

The table follows one pack from input to the sliding minimum.

A script-traced run on the sample shows the picked skip:

```
values: [6, 19, 8, 7, 13]  k: 3
total: 53  chosen skips: [2]
answer: 45
```

Skipping the pack worth 8 breaks all three-packs-in-a-row groups at the lowest cost.

The deque drops candidates older than k positions before each cost is formed.
The final guard accepts only last skips that leave fewer than k packs behind.

## Code

**Input and scanner.** The reader loads all tokens and tracks written text.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const hugeValue = int64(1 shl 60)

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The hand scanner avoids one string object per pack value.
The sentinel `hugeValue` stands in for a missing previous skip.
The output buffer holds the single answer line.

**Sliding-minimum scan.** Each pack adds one deque entry and removes expired ones.

```nim
let packCount = nextInt(inputData, scanPos)
let skipLength = nextInt(inputData, scanPos)
var candidateIndex = newSeq[int](packCount)
var candidateCost = newSeq[int64](packCount)
var headIndex = 0
var tailIndex = 0
var totalSum: int64 = 0
var minFinalCost: int64 = hugeValue
let lastFirstSkip = skipLength - 1
let firstFinalSkip = packCount - skipLength
for packIndex in 0 .. packCount - 1:
  let packValue = int64(nextInt(inputData, scanPos))
  totalSum = totalSum + packValue
  while headIndex < tailIndex and candidateIndex[headIndex] < packIndex - skipLength:
    headIndex += 1
  var bestPrevious: int64 = hugeValue
  if packIndex <= lastFirstSkip:
    bestPrevious = 0
  if headIndex < tailIndex and candidateCost[headIndex] < bestPrevious:
    bestPrevious = candidateCost[headIndex]
  let currentCost = packValue + bestPrevious
  while tailIndex > headIndex and candidateCost[tailIndex - 1] >= currentCost:
    tailIndex -= 1
  candidateIndex[tailIndex] = packIndex
  candidateCost[tailIndex] = currentCost
  tailIndex += 1
  if packIndex >= firstFinalSkip and currentCost < minFinalCost:
    minFinalCost = currentCost
let bestMoney = totalSum - minFinalCost
appendOutput($bestMoney)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop bound is the pack count from the header.
The deletion loop keeps only skips inside the last k positions.
Each pack enters and leaves the deque once, so the scan is linear.

## Complexity

The scan visits every pack once and answers with one line.

| phase | time | space |
|---|---|---|
| input read | one pass over pack values | one input string |
| sliding minimum | one deque step per pack | two index and cost arrays |
| output | one number | block buffer |

Both arrays grow with n, and the deque reuses them without reallocation.

| measure | Big O |
|---|---|
| time | O(n) |
| space | O(n) |

A block-by-block dynamic program examines k earlier positions per pack.
The sliding minimum reduces that to one comparison per pack.
