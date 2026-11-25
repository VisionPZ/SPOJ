# TJANDRAS — Tjandra 19th birthday (EASY) (SPOJ)

<https://www.spoj.com/problems/TJANDRAS/>

## Problem

Matchsticks form a grid of unit cells, and the score counts every rectangle whose four sides exist. Given a stick budget, report the largest possible rectangle count.

Each test case holds one stick count n below 1000000000. Print one maximum per case.

| item | bound |
|---|---|
| test cases | at most 100 |
| stick count n | below 1000000000 |
| judge limit | 3263 ms, 1536 MB |

Unused sticks are allowed.

Sample input:

```
5
3
4
8
12
15
```

Sample output:

```
0
1
3
9
12
```

## Idea

Picture stacking books in rows: sharing side edges buys more rectangles, like sharing walls between rooms.

The best shape is a left-aligned stack of rows with lengths that never increase downward. A scan over the row count uses division to get the longest common row and the number of longer rows. The count of sub-rectangles then follows from triangular sums.

Trying every stick arrangement grows far too fast for a billion sticks.

The row-count scan turns a puzzle into O(log n) work per candidate row.

## Why It Works

1. A row of length L uses L+1 horizontal edges and 2L vertical edges with its neighbors.
2. For non-increasing row lengths, total sticks equal 2 times cells plus the top row plus row count.
3. With row count a and common length q, the stick cost is a times 2q+1 plus q.
4. Extra cells go to the earliest rows to keep lengths non-increasing.
5. Each extra cell beyond the first costs two more sticks.
6. A rectangle spanning rows i through j is limited by the shortest row j.
7. Summing over row pairs gives triangular number products.

| term | meaning |
|---|---|
| `matchCount` | stick budget n |
| `rowCount` | number of rows in the trial shape |
| `baseLength` | common length q of every row |
| `extraRows` | rows lengthened by one cell |
| `bestRectangles` | largest count found so far |

Rounding goes down because sticks are whole and unused sticks are allowed.

A script trace for n = 15 lists the best shape per row count:

```
rows 1 -> length 4, rectangles 10
rows 2 -> lengths 3 2, rectangles 12
rows 3 -> lengths 2 2 1, rectangles 12
rows 4 -> lengths 1 1 1 1, rectangles 10
answer 12
```

The trace matches the last sample answer.

## Code

**Input and scanning.** The reader loads one stick budget per case.

```nim
const flushBlockBytes = 1 shl 17
const maxRowsToScan: int64 = 100000

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

The scanner skips line breaks between budgets.
A 64-bit value holds n below one billion.
The row scan stops early for tiny budgets.

**Closed-form row scan.** Division replaces a search over row lengths.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let matchCount: int64 = int64(nextInt(inputData, scanPos))
  var rowLimit: int64 = matchCount
  if rowLimit > maxRowsToScan:
    rowLimit = maxRowsToScan
  var bestRectangles: int64 = 0
  var rowCount: int64 = 1
  while rowCount <= rowLimit:
    let budgetAfterRows = matchCount - rowCount
    let denominator = 2 * rowCount + 1
    let baseLength = budgetAfterRows div denominator
    let leftover = budgetAfterRows mod denominator
    var extraRows: int64 = 0
    if leftover > 0:
      extraRows = (leftover - 1) div 2
      if extraRows >= rowCount:
        extraRows = rowCount - 1
    let triangularLength = baseLength * (baseLength + 1) div 2
    let triangularRows = rowCount * (rowCount + 1) div 2
    let baseRectangles = triangularLength * triangularRows
    let extraRectangles = (baseLength + 1) * extraRows * (extraRows + 1) div 2
    let totalRectangles = baseRectangles + extraRectangles
    if totalRectangles > bestRectangles:
      bestRectangles = totalRectangles
    if baseLength == 0:
      break
    rowCount += 1
  appendOutput($bestRectangles)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The quotient is the common row length.
The remainder funds the first extra cell and later ones.
Triangular products stay inside signed 64-bit range.

## Complexity

Each trial row count needs a fixed number of arithmetic steps.

| phase | time | space |
|---|---|---|
| input read | one pass over budgets | one input string |
| row scan | up to 100000 trials per case | constant working space |
| output | one line per case | block buffer |

No shape is stored in memory.

| measure | Big O |
|---|---|
| time per case | O(min(n, 100000)) |
| space per case | O(1) |

Enumerating stick layouts would be exponential in the budget.

The row-count scan gives the compact answer.
