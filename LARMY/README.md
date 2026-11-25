# LARMY — Lannister Army (SPOJ)

<https://www.spoj.com/problems/LARMY/>

## Problem

Cut a row of warriors into exactly k nonempty rows so the total number of inversions inside the rows is as small as possible. An inversion is a pair where a taller warrior stands before a shorter one in the same row.

Input gives one line with the warrior count and the row count, then one line of heights. Output the minimum total unhappiness as one integer.

| item | bound |
|---|---|
| warriors N | 1 to 5000 |
| rows K | 1 to N |
| height H[i] | 1 to 100000 |
| judge limit | 1000 ms, 1536 MB |

Both N and K reach 5000, so a plain quadratic pass per row is too costly.

Sample input:

```
6 3
20 50 30 60 40 100
```

The sample has six warriors and three rows.

Sample output:

```
0
```

Rows 20 50, 30 60 and 40 100 each have no inversion.

## Idea

Choosing cuts is like placing dividers in a line of books to reduce disorder inside each segment. Build a table of inversion counts for every segment first, then run a partition dynamic program. The best cut for a longer prefix never moves left when the prefix grows, so divide-and-conquer optimization narrows the search each round. Each round scans about N log N candidates, while a plain dynamic program scans N^2 candidates per round. Build the cost table, then move the search bounds inward.

## Why It Works

1. Inversions inside disjoint rows add up, so each cut only separates pairs across the boundary.
2. For fixed right end r, scanning left ends downward adds one taller predecessor at each step, which yields every segment cost in one pass.
3. Inversion cost satisfies the quadrangle inequality, so the best cut for prefix i is never to the left of the best cut for prefix i - 1.
4. Divide-and-conquer evaluation uses that order to shrink the candidate interval for each prefix.

| term | meaning |
|---|---|
| `inversionCosts` | inversion count of each inclusive segment of warriors |
| `previousCosts` | best total for prefixes using the previous row count |
| `currentCosts` | best total for prefixes using the current row count |
| `computeSplitRange` | recursive search over monotone best cuts |

The four terms cover the cost table and one dynamic-programming layer.

A script trace of the second sample with eight warriors and three rows:

```
row 1: 20 50                 cost 0
row 2: 30 60 40 100          cost 1
row 3: 5 1                   cost 1
total                        2
```

The pair 60, 40 and the pair 5, 1 are the only inversions.

## Code

**Input and recursion.** The reader loads the heights and declares the shared tables.

```nim
const flushBlockBytes = 1 shl 17
const infinityValue = 4000000000000000000'i64

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

var warriorCount = 0
var inversionCosts: seq[int32]
var previousCosts: seq[int64]
var currentCosts: seq[int64]
```

Costs fit in 32-bit words, while dynamic-programming totals use 64-bit words.
The tables are shared so the recursive search reads them without copying.
The large constant marks prefixes that cannot yet use the current row count.

**Monotone search.** Each recursive call tries one middle prefix and narrows both halves.

```nim
proc computeSplitRange(lowIndex, highIndex, optLow, optHigh: int) =
  if lowIndex > highIndex:
    return
  let middleIndex = (lowIndex + highIndex) div 2
  var upperSplit = optHigh
  if upperSplit > middleIndex - 1:
    upperSplit = middleIndex - 1
  var bestValue = infinityValue
  var bestSplit = optLow
  var splitIndex = optLow
  while splitIndex <= upperSplit:
    let previousValue = previousCosts[splitIndex]
    if previousValue < infinityValue:
      let candidateValue = previousValue + int64(inversionCosts[(splitIndex + 1) * warriorCount + middleIndex])
      if candidateValue < bestValue:
        bestValue = candidateValue
        bestSplit = splitIndex
    splitIndex += 1
  currentCosts[middleIndex] = bestValue
  computeSplitRange(lowIndex, middleIndex - 1, optLow, bestSplit)
  computeSplitRange(middleIndex + 1, highIndex, bestSplit, optHigh)
```

A split must leave at least one warrior in the last row.
The best split is passed as the right bound for the left half.
Strict improvement keeps the smallest best split, which preserves monotone order.

**Cost table and layers.** A downward scan fills one column, then layers update the answer.

```nim
let totalWarriors = nextInt(inputData, scanPos)
let wantedRows = nextInt(inputData, scanPos)
var heights = newSeq[int32](totalWarriors)
for heightIndex in 0 .. totalWarriors - 1:
  heights[heightIndex] = int32(nextInt(inputData, scanPos))

var answerValue: int64 = 0
if wantedRows >= totalWarriors:
  answerValue = 0
elif wantedRows == 1:
  var totalInversions: int64 = 0
  for leftIndex in 0 .. totalWarriors - 1:
    for rightIndex in leftIndex + 1 .. totalWarriors - 1:
      if heights[leftIndex] > heights[rightIndex]:
        totalInversions += 1
  answerValue = totalInversions
else:
  warriorCount = totalWarriors
  inversionCosts = newSeq[int32](warriorCount * warriorCount)
  for rightIndex in 0 .. warriorCount - 1:
    var greaterCount: int32 = 0
    var leftIndex = rightIndex - 1
    while leftIndex >= 0:
      if heights[leftIndex] > heights[rightIndex]:
        greaterCount += 1
      inversionCosts[leftIndex * warriorCount + rightIndex] = inversionCosts[leftIndex * warriorCount + rightIndex - 1] + greaterCount
      leftIndex -= 1
  previousCosts = newSeq[int64](warriorCount)
  for endIndex in 0 .. warriorCount - 1:
    previousCosts[endIndex] = int64(inversionCosts[endIndex])
  for rowCount in 2 .. wantedRows:
    currentCosts = newSeq[int64](warriorCount)
    computeSplitRange(rowCount - 1, warriorCount - 1, rowCount - 2, warriorCount - 1)
    swap(previousCosts, currentCosts)
    if previousCosts[warriorCount - 1] == 0'i64:
      break
  answerValue = previousCosts[warriorCount - 1]

appendOutput($answerValue)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The greater-count accumulator adds one term for each new left end.
Each row layer starts its search at the earliest prefix that fits that row count.
A zero total ends the loop, since later row counts cannot improve it.

## Complexity

The cost table is built once and shared by every row layer.

| phase | time | space |
|---|---|---|
| input read | one token scan | one height array |
| cost table | one downward scan per right end | N^2 costs |
| row layers | O(N log N) split tests per row | two prefix arrays |
| output | one buffered write | block buffer |

The cost table dominates memory, while the row layers dominate time.

| measure | Big O |
|---|---|
| time | O(N^2 + K N log N) |
| space | O(N^2) |

A plain dynamic program would test O(N^2) splits per row, about N log N times more work at the largest bounds. Monotone splits keep the full run inside the time limit.
