# SQRMINSUM — Minimum Sum (SPOJ)
<https://www.spoj.com/problems/SQRMINSUM/>

## Problem

Start with the array `[1, 2, ..., l]`. One move replaces an entry with the floor of its square root. Apply `k` moves to minimise the sum of the array.

Input starts with `T`. Each case then gives `l` and `k` on separate lines. Output one line per case with the minimal sum.

| item | bound |
|---|---|
| cases T | 10000 |
| array length l | 1 to 10000 |
| moves k | 1 to 10000 |
| judge limit | 5000 ms, 1536 MB |

The product of length and case count drives the design, since both can reach 10000.

Sample input:

```
2
5
2
2327
4895
```

Sample output:

```
10
10647
```

## Idea

Each move saves the difference between a number and its floored square root. Think of each array entry as a stack of coins, where each move takes the biggest visible coin from the tallest stack.

Gains along one entry never increase, because the square root shrinks the number. So the best `k` moves are simply the `k` largest gains over all entries. The program precomputes every gain chain, then uses a Fenwick tree to select the largest gains for each case.

A priority queue simulates all moves one by one and repeats work across cases. Precomputing once and answering each case with a tree query avoids that repeated simulation.

Takeaway: turn repeated moves into one global selection of gains.

## Why It Works

1. Replacing v by `floor(sqrt(v))` lowers the sum by `v - floor(sqrt(v))`.
2. Repeated square roots give a chain `v -> floor(sqrt(v)) -> ... -> 1`.
3. Gains along a chain are nonincreasing, so taking a later gain never requires skipping an earlier one.
4. The array `[1..l]` contributes the union of chains for values `1..l`.
5. The smallest possible sum is the initial sum minus the largest k gains in that union.
6. After all useful gains are spent, further moves act on 1 and change nothing.

| term | meaning |
|---|---|
| `chainHeads` | start and end offsets of gains for each value |
| `countTree` | Fenwick tree of gain frequencies |
| `sumTree` | Fenwick tree of gain totals |
| `skipped` | number of smallest gains left unused |
| `gainSum` | total of the k largest gains |

The sample with `l = 5` and `k = 2` works as follows.

```
initial array: 1 2 3 4 5, sum = 15
gains by value: 2 -> 1, 3 -> 2, 4 -> 2 and 1, 5 -> 3 and 1
all gains: 1 2 2 1 3 1
two largest: 3 and 2, total gain = 5
minimal sum = 15 - 5 = 10
```

Sums fit in `int64`, and the integer square root uses binary search, so no floating point rounding enters the answer.

## Code

**Input and output core.** One read pass, a hand scanner, and a block buffer.

```nim
const flushBlockBytes = 1 shl 17
const maxLength = 10000
const maxGain = 10000
const maxRoot = 101

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
```

The scanner skips line breaks between `l` and `k`. The root bound 101 covers values up to 10000. Output is batched in blocks of 131072 bytes.

**Query buckets.** Cases are grouped by their array length.

```nim
proc integerRoot(value: int): int =
  var low = 1
  var high = maxRoot
  while low < high:
    let middle = (low + high + 1) div 2
    if middle * middle <= value:
      low = middle
    else:
      high = middle - 1
  return low

type Query = object
  lengthValue: int
  moveCount: int
  caseIndex: int

let caseCount = nextInt(inputData, scanPos)
var queries = newSeq[Query](caseCount)
var lengthCounts = newSeq[int](maxLength + 2)
for caseIndex in 0 .. caseCount - 1:
  queries[caseIndex].lengthValue = nextInt(inputData, scanPos)
  queries[caseIndex].moveCount = nextInt(inputData, scanPos)
  queries[caseIndex].caseIndex = caseIndex
  lengthCounts[queries[caseIndex].lengthValue] += 1

var lengthOffsets = newSeq[int](maxLength + 2)
var runningOffset = 0
for lengthValue in 1 .. maxLength:
  lengthOffsets[lengthValue] = runningOffset
  runningOffset += lengthCounts[lengthValue]
var sortedQueries = newSeq[Query](caseCount)
for caseIndex in 0 .. caseCount - 1:
  let carried = queries[caseIndex]
  let destination = lengthOffsets[carried.lengthValue]
  sortedQueries[destination] = carried
  lengthOffsets[carried.lengthValue] += 1
```

Counting by length gives a linear bucket sort. Each case keeps its original index for output order. The root helper avoids floating point errors.

**Gain chains.** Every value contributes a short list of gains.

```nim
var chainHeads = newSeq[int](maxLength + 2)
var chainGains = newSeq[int](0)
var gainCount = 0
for value in 1 .. maxLength:
  chainHeads[value] = gainCount
  var current = value
  while current > 1:
    let child = integerRoot(current)
    chainGains.add(current - child)
    gainCount += 1
    current = child
  chainHeads[value + 1] = gainCount
```

Each chain ends at 1 in at most four steps for values up to 10000. Offsets make chains for one length contiguous. The whole table is built once for all cases.

**Fenwick trees.** Two trees track gain counts and gain sums by value.

```nim
var countTree = newSeq[int](maxGain + 2)
var sumTree = newSeq[int64](maxGain + 2)

proc addGain(gain: int) =
  var index = gain
  while index <= maxGain:
    countTree[index] += 1
    sumTree[index] += int64(gain)
    index += index and -index

proc prefixCount(index: int): int =
  var total = 0
  var cursor = index
  while cursor > 0:
    total += countTree[cursor]
    cursor -= cursor and -cursor
  return total

proc prefixSum(index: int): int64 =
  var total: int64 = 0
  var cursor = index
  while cursor > 0:
    total += sumTree[cursor]
    cursor -= cursor and -cursor
  return total
```

Adding one gain touches O(log 10000) tree cells. Prefix queries support both counts and sums. The low-bit step walks the tree without recursion.

**Answer sweep.** Lengths grow from 1 to 10000, adding gains as they appear.

```nim
var answers = newSeq[int64](caseCount)
var totalCount = 0
var totalSum: int64 = 0
var queryIndex = 0
for lengthValue in 1 .. maxLength:
  for gainPosition in chainHeads[lengthValue] .. chainHeads[lengthValue + 1] - 1:
    addGain(chainGains[gainPosition])
    totalCount += 1
    totalSum += int64(chainGains[gainPosition])
  while queryIndex < caseCount and sortedQueries[queryIndex].lengthValue == lengthValue:
    let moveCount = sortedQueries[queryIndex].moveCount
    var gainSum: int64 = 0
    if moveCount >= totalCount:
      gainSum = totalSum
    else:
      let skipped = totalCount - moveCount
      var bitMask = 1
      while (bitMask shl 1) <= maxGain:
        bitMask = bitMask shl 1
      var lowerIndex = 0
      var accumulated = 0
      while bitMask > 0:
        let nextIndex = lowerIndex + bitMask
        if nextIndex <= maxGain and accumulated + countTree[nextIndex] <= skipped:
          accumulated += countTree[nextIndex]
          lowerIndex = nextIndex
        bitMask = bitMask shr 1
      let chosenIndex = lowerIndex + 1
      if chosenIndex > maxGain:
        gainSum = 0
      else:
        let pointCount = prefixCount(chosenIndex) - accumulated
        let takenAtChosen = pointCount - (skipped - accumulated)
        gainSum = (totalSum - prefixSum(chosenIndex)) +
                  int64(takenAtChosen) * int64(chosenIndex)
    let initialSum = int64(lengthValue) * int64(lengthValue + 1) div 2
    answers[sortedQueries[queryIndex].caseIndex] = initialSum - gainSum
    queryIndex += 1

for caseIndex in 0 .. caseCount - 1:
  appendOutput($answers[caseIndex])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Binary lifting finds the gain value where the top `k` cut occurs. Partial groups at that value use the remaining move count. Results are stored by original case index and printed in input order.

## Complexity

Precomputation runs once, and each case needs one tree search.

| phase | time | space |
|---|---|---|
| bucket sort of cases | O(T + 10000) | O(T) |
| gain chains | O(10000 · 4) | O(40000) |
| sweep and insertion | O(10000 · 4 · log 10000) | two trees of 10000 cells |
| per case query | O(log 10000) | none extra |

The sweep and the case queries dominate, both with a small logarithmic factor.

| measure | Big O |
|---|---|
| preprocessing | O(10000 · log 10000) |
| all cases | O((T + 10000) · log 10000) |
| working space | O(T + 10000) |

Simulating every move for every case would cost O(T · k · log l). Selecting precomputed gains removes that repeated work.

Takeaway: precompute once, then answer each case with one tree query.
