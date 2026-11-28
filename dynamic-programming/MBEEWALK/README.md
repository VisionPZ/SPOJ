# MBEEWALK — Bee Walk (SPOJ)

<https://www.spoj.com/problems/MBEEWALK/>

## Problem

A larva walks on a honeycomb, taking six possible steps each time. Axial coordinates `(x, y)` label each cell. Count walks of `n` steps that finish in the starting cell.

The input starts with the number of test cases. Each following line holds one step count `n`. The output holds one count per line, in input order.

| item | bound |
|---|---|
| step count `n` | 1 to 14 |
| answer | below 2^31 |
| judge limit | 1000 ms, 1536 MB |

The step count drives the design, since only fourteen distinct answers exist.

Sample input:

```
2
2
4
```

Sample output:

```
6
90
```

## Idea

Move a whole crowd of counters cell by cell, like pouring sand through a grid of buckets. This is dynamic programming on a hexagonal grid of coordinates.

Precompute the answer for every step count from one to fourteen. Each step scans the occupied cells and adds six neighbor counts. The naive way lists all 6^n direction strings, which grows far faster.

The table is built once, so each query is one array lookup.

## Why It Works

1. Axial coordinates `(x, y)` give each cell six neighbors with fixed offsets.
2. A count in a cell after `s` steps equals the sum of counts that can step into it.
3. The starting cell holds one walk after zero steps, and every other cell holds zero.
4. The count at the center after step `s` is the number of closed walks of length `s`.
5. Same-length walks stay in one layer, so later steps never rewrite earlier answers.

| term | meaning |
|---|---|
| `currentCounts` | walks ending at each cell after the current step |
| `nextCounts` | walks ending at each cell after the next step |
| `stepDirections` | the six axial neighbor offsets |
| `walkAnswers` | closed-walk count for each step count |

The term table names the four arrays that carry the computation.

A worked trace from the generator lists closed-walk counts by step count:

```
steps:  0  1   2   3    4     5      6
walks:  1  0   6  12   90   360   2040
```

Two back-and-forth steps give six walks, matching the first sample answer.

## Code

**Input and scanning.** One pass loads all tokens, and a hand scanner reads integers.

```nim
const flushBlockBytes = 1 shl 17
const stepDirectionCount = 6
const maxWalkSteps = 14
const coordinateOffset = 14
const gridSide = 2 * coordinateOffset + 1
const centerCell = coordinateOffset * gridSide + coordinateOffset

const stepDirections: array[stepDirectionCount, array[2, int]] = [
  [1, 0], [0, 1], [-1, 1], [-1, 0], [0, -1], [1, -1]
]

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
```

The offset keeps every reachable cell inside a square grid.
The scanner skips whitespace and builds each value one digit at a time.
Loading input once keeps the hot loop free of calls to the input stream.

**Buffered output.** A single string collects answers and flushes in large blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes at 128 KiB instead of on every line.
This keeps the write path cheap even for thousands of test cases.

**Precomputed walk table.** Fourteen sweeps fill the answer table once.

```nim
var walkAnswers = newSeq[int](maxWalkSteps + 1)
var currentCounts = newSeq[int](gridSide * gridSide)
var nextCounts = newSeq[int](gridSide * gridSide)
currentCounts[centerCell] = 1

for stepNumber in 1 .. maxWalkSteps:
  for cellIndex in 0 .. nextCounts.len - 1:
    nextCounts[cellIndex] = 0
  for cellIndex in 0 .. currentCounts.len - 1:
    let pathCount = currentCounts[cellIndex]
    if pathCount == 0:
      continue
    let gridX = cellIndex div gridSide - coordinateOffset
    let gridY = cellIndex mod gridSide - coordinateOffset
    for directionIndex in 0 .. stepDirectionCount - 1:
      let nextX = gridX + stepDirections[directionIndex][0]
      let nextY = gridY + stepDirections[directionIndex][1]
      let nextCell = (nextX + coordinateOffset) * gridSide + nextY + coordinateOffset
      nextCounts[nextCell] = nextCounts[nextCell] + pathCount
  for cellIndex in 0 .. currentCounts.len - 1:
    currentCounts[cellIndex] = nextCounts[cellIndex]
  walkAnswers[stepNumber] = currentCounts[centerCell]
```

Empty cells are skipped, so only reachable cells do work.
The center count is recorded right after each sweep.
Two arrays swap roles each sweep, avoiding allocation inside the loop.

**Answer loop.** Each query reads one table entry.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let walkSteps = nextInt(inputData, scanPos)
  appendOutput($walkAnswers[walkSteps])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop runs once per test case.
Every answer ends with one newline, and the final flush happens after the loop.

## Complexity

Precomputation dominates; answering a query costs one lookup.

| phase | time | space |
|---|---|---|
| input read | one pass over test cases | input string |
| precompute | 14 sweeps over a 29 by 29 grid | two count arrays |
| output | one block flush per 128 KiB | output buffer |

The phases show that precomputation is fixed and small.

| measure | Big O |
|---|---|
| time | O(T + 14 * 6 * 29^2) |
| space | O(29^2 + T) for the buffered answers |

Listing all direction strings costs O(6^n), which grows steeply with n. Precomputation replaces that growth with one small fixed sweep, so each query is a table lookup.
