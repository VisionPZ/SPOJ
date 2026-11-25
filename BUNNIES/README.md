# BUNNIES — Bunnies (SPOJ)

<https://www.spoj.com/problems/BUNNIES/>

## Problem

Pompom knows how many taps break each egg, but a shuffle hides which egg is which. She needs a plan that guarantees K broken eggs with the fewest taps in the worst arrangement.

Input starts with T test cases. Each case gives N and K, then the N tap counts.

Output gives one minimum worst-case tap count per case.

The bounds from the statement:

| item | bound |
|---|---|
| test cases T | 1 to 10 |
| eggs N | K to 3000 |
| target K | 1 to N |
| tap count per egg | 1 to 1000000 |
| judge limit | 1000 ms, 1536 MB |

The product of N and K drives the design.

Sample input:

```
3
2 1
5 8
2 1
5 58
3 2
1 2 3
```

The sample holds three cases with different targets.

Sample output:

```
8
10
5
```

The three worst-case plans cost 8, 10, and 5 taps.

## Idea

Keep only the cheapest line at each usage level, like picking a phone plan by how many minutes you use. Here each threshold becomes a line, and a hull discards lines that can never win.

The method is dynamic programming over broken eggs and available eggs, accelerated by a monotone convex hull. Sorting puts the tap counts in nondecreasing order, which makes hull insertion linear. Each state costs amortized constant time, so the table costs O(NK).

Trying every group split for every state costs cubic time.

## Why It Works

1. Sort the tap counts, then call the sorted values A.
2. Let state (j, i) mean breaking j eggs using the first i sorted eggs.
3. Choose k as the first egg in the final tapped group. That group holds i - k + 1 eggs and costs (i - k + 1) times A[k].
4. The recurrence takes the minimum of state (j - 1, k - 1) plus that group cost over all k from j to i.
5. Rewrite each candidate as a line: intercept equals state (j - 1, k - 1) minus k times A[k], slope equals A[k], and query point equals i + 1.
6. Slopes rise with k and query points rise with i, so a hull pops obsolete lines once each.

The main terms and formulas:

| term | meaning |
|---|---|
| `breakCounts` | tap counts sorted into nondecreasing order |
| `previousRow` | costs for the target one lower than the current row |
| `currentRow` | costs filled for the current target |
| `hullSlope` | slope of each line on the hull |
| `hullIntercept` | intercept of each line on the hull |
| `queryPoint` | i + 1, where the hull is queried |

Slopes and queries both rise, so the hull stays monotone.

A script trace over sorted counts 1, 2, 3 with target 2 gives:

```
j=1 i=1: candidates [(1, 1)] -> 1
j=1 i=2: candidates [(2, 1), (2, 2)] -> 2
j=1 i=3: candidates [(3, 1), (4, 2), (3, 3)] -> 3
j=2 i=2: candidates [(3, 2)] -> 3
j=2 i=3: candidates [(5, 2), (5, 3)] -> 5
answer 5
```

Each line enters and leaves the hull once, so the hull work stays linear per row.

All costs fit in a signed 64-bit value, so no extra width is needed.

## Code

**Input, sorting, and buffer.** One read loads stdin, and insertion sort orders the tap counts.

```nim
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
```

The scanner skips spaces and line breaks.
Insertion sort keeps the code small for 3000 values.
Answers collect in one output string.

**Hull-accelerated table.** Each row builds a hull from the previous row.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let eggCount = nextInt(inputData, scanPos)
  let targetBroken = nextInt(inputData, scanPos)
  var breakCounts = newSeq[int64](eggCount)
  for eggIndex in 0 .. eggCount - 1:
    breakCounts[eggIndex] = int64(nextInt(inputData, scanPos))
  for sortIndex in 1 .. eggCount - 1:
    let keyCount = breakCounts[sortIndex]
    var holeIndex = sortIndex
    while holeIndex > 0 and breakCounts[holeIndex - 1] > keyCount:
      breakCounts[holeIndex] = breakCounts[holeIndex - 1]
      holeIndex -= 1
    breakCounts[holeIndex] = keyCount
  var previousRow = newSeq[int64](eggCount + 1)
  var currentRow = newSeq[int64](eggCount + 1)
  var hullSlope = newSeq[int64](eggCount + 2)
  var hullIntercept = newSeq[int64](eggCount + 2)
  for brokenTarget in 1 .. targetBroken:
    var hullCount = 0
    currentRow[0] = 0
    for availableEggs in brokenTarget .. eggCount:
      let lineSlope = breakCounts[availableEggs - 1]
      let lineIntercept = previousRow[availableEggs - 1] -
                          int64(availableEggs) * lineSlope
      while hullCount >= 2:
        let lowerSlope = hullSlope[hullCount - 2]
        let lowerIntercept = hullIntercept[hullCount - 2]
        let middleSlope = hullSlope[hullCount - 1]
        let middleIntercept = hullIntercept[hullCount - 1]
        if middleSlope == lowerSlope:
          if middleIntercept >= lowerIntercept:
            hullCount -= 1
            continue
          break
        if lineSlope == middleSlope:
          if lineIntercept <= middleIntercept:
            hullCount -= 1
            continue
          break
        let turnOld = (middleIntercept - lineIntercept) * (middleSlope - lowerSlope)
        let turnNew = (lowerIntercept - middleIntercept) * (lineSlope - middleSlope)
        if turnOld >= turnNew:
          hullCount -= 1
        else:
          break
      if hullCount > 0:
        let queryPoint = int64(availableEggs + 1)
        let topValue = hullIntercept[hullCount - 1] +
                       hullSlope[hullCount - 1] * queryPoint
        let newValue = lineIntercept + lineSlope * queryPoint
        if topValue > newValue:
          hullSlope[hullCount] = lineSlope
          hullIntercept[hullCount] = lineIntercept
          hullCount += 1
      else:
        hullSlope[hullCount] = lineSlope
        hullIntercept[hullCount] = lineIntercept
        hullCount += 1
      let queryPoint = int64(availableEggs + 1)
      while hullCount >= 2:
        let topValue = hullIntercept[hullCount - 1] +
                       hullSlope[hullCount - 1] * queryPoint
        let belowValue = hullIntercept[hullCount - 2] +
                         hullSlope[hullCount - 2] * queryPoint
        if topValue >= belowValue:
          hullCount -= 1
        else:
          break
      currentRow[availableEggs] = hullIntercept[hullCount - 1] +
                                  hullSlope[hullCount - 1] * queryPoint
    swap previousRow, currentRow
  appendOutput($previousRow[eggCount])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Equal slopes keep the line with the lower intercept.
Cross products compare turn points without division.
The last row entry is the answer for the case.

## Complexity

Cost comes from sorting and filling the table.

| phase | time | space |
|---|---|---|
| input read | one pass over tokens | one input string |
| sort | O(N log N) comparisons | one count array |
| table fill | K rows of up to N hull queries | two rows and two hull arrays |
| output | one line per case | block buffer |

The table fill dominates for large N and K.

The overall asymptotic bounds:

| measure | Big O |
|---|---|
| time | O(N log N + NK) per case |
| space | O(N) |

A plain triple loop tries every split for every state and costs O(N^3) per case.
The hull turns each split search into amortized constant work.
