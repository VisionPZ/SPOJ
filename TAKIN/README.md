# TAKIN — Taskin and apple tree (SPOJ)

<https://www.spoj.com/problems/TAKIN/>

## Problem

Choose whole trees so the apple total stays within the basket capacity, and make that total as large as possible. Each tree is taken fully or skipped.

Input starts with a test count. Each test gives a tree count and a capacity, then the apple amounts on one line. Output one line per test with the largest fitting total.

| item | bound |
|---|---|
| test cases | 1 to 10 |
| trees per test | 1 to 20 |
| basket capacity | 0 to 20000000000 |
| apples per tree | 0 to 1000000000 |
| judge limit | 1000 ms, 1536 MB |

Twenty trees allow two lists of at most 1024 subset sums, which shapes the design.

Sample input:

```
2
5 6
2 1 2 7 8
5 10
1 2 4 4 6
```

The sample holds two tests with capacities 6 and 10.

Sample output:

```
5
10
```

The best totals use apples 2, 1, 2 and 1, 2, 4, 4.

## Idea

Splitting the trees into two piles is like counting coins in two drawers instead of one large chest. Build every subset sum in each half, sort one list, and pair each sum from the first half with the largest sum from the second half that still fits. This is meet-in-the-middle subset sum. Each half costs 2^(N/2) sums and each pairing costs a binary search of 2^(N/2) items. Scanning all 2^N subsets would cost much more at N = 20. Split first, then probe.

## Why It Works

1. Every subset of all trees is one subset from the left half plus one subset from the right half.
2. The halves are disjoint, so their two sums add without overlap.
3. Sorting the right sums lets a binary search find the largest sum within the remaining capacity.
4. Testing every left sum covers every subset, so the largest fitting total survives.

| term | meaning |
|---|---|
| `leftSums` | subset totals from the first half of trees |
| `rightSums` | sorted subset totals from the second half |
| `remainingCapacity` | room left after choosing a left subset |
| `bestHarvest` | largest fitting total seen so far |

These four terms describe one pass over the sorted right sums.

A script trace of the first sample at capacity 6:

```
left  remaining  right pick  total
0     6           2           2
2     4           2           4
1     5           2           3
3     3           2           5
```

The last row takes trees 2 and 1 from the left half and tree 2 from the right half.

## Code

**Input and buffer.** The reader loads all tokens and sets up one output buffer.

```nim
import algorithm

const flushBlockBytes = 1 shl 17

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

proc compareSums(firstSum: int64, secondSum: int64): int =
  if firstSum < secondSum: return -1
  if firstSum > secondSum: return 1
  return 0
```

The scanner skips spaces and line breaks without converting strings.
One buffer collects all output and flushes in blocks.
The comparator orders 64-bit sums for the right half.

**Subset lists and pairing.** Each half contributes its subset sums before the binary search.

```nim
let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let treeCount = nextInt(inputData, scanPos)
  let basketCapacity = int64(nextInt(inputData, scanPos))
  var appleCounts = newSeq[int64](treeCount)
  for treeIndex in 0 .. treeCount - 1:
    appleCounts[treeIndex] = int64(nextInt(inputData, scanPos))
  let leftSize = treeCount div 2
  let rightSize = treeCount - leftSize
  let leftComboCount = 1 shl leftSize
  let rightComboCount = 1 shl rightSize
  var leftSums = newSeq[int64](leftComboCount)
  for comboMask in 1 .. leftComboCount - 1:
    let lowestBit = comboMask and -comboMask
    var bitPosition = 0
    var bitMarker = 1
    while (comboMask and bitMarker) == 0:
      bitMarker = bitMarker shl 1
      bitPosition += 1
    leftSums[comboMask] = leftSums[comboMask - lowestBit] + appleCounts[bitPosition]
  var rightSums = newSeq[int64](rightComboCount)
  for comboMask in 1 .. rightComboCount - 1:
    let lowestBit = comboMask and -comboMask
    var bitPosition = 0
    var bitMarker = 1
    while (comboMask and bitMarker) == 0:
      bitMarker = bitMarker shl 1
      bitPosition += 1
    rightSums[comboMask] = rightSums[comboMask - lowestBit] + appleCounts[leftSize + bitPosition]
  rightSums.sort(compareSums)
  var bestHarvest: int64 = 0
  for comboMask in 0 .. leftComboCount - 1:
    let leftTotal = leftSums[comboMask]
    if leftTotal > basketCapacity:
      continue
    let remainingCapacity = basketCapacity - leftTotal
    var lowBound = 0
    var highBound = rightComboCount - 1
    var chosenIndex = -1
    while lowBound <= highBound:
      let middleIndex = (lowBound + highBound) div 2
      if rightSums[middleIndex] <= remainingCapacity:
        chosenIndex = middleIndex
        lowBound = middleIndex + 1
      else:
        highBound = middleIndex - 1
    if chosenIndex >= 0:
      let totalHarvest = leftTotal + rightSums[chosenIndex]
      if totalHarvest > bestHarvest:
        bestHarvest = totalHarvest
  appendOutput($bestHarvest)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Each mask adds one tree to the sum of its smaller mask.
The binary search keeps the last right sum within the remaining capacity.
Sums use 64 bits because twenty trees can exceed 2^31.

## Complexity

Each test builds two subset lists and probes one sorted list.

| phase | time | space |
|---|---|---|
| input read | one token scan | input string |
| subset lists | two lists of 2^(N/2) sums | two lists of 2^(N/2) |
| pairing | one binary search per left sum | constant |
| output | one buffered write per test | block buffer |

The largest list size comes from the N = 20 bound.

| measure | Big O |
|---|---|
| time | O(2^(N/2) log 2^(N/2)) per test |
| space | O(2^(N/2)) |

Scanning all 2^N subsets would take about a million checks per test, while the split takes a few thousand. The split keeps every test well inside the time limit.
