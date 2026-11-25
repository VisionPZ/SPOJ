# OMWG — One more weird game (SPOJ)

<https://www.spoj.com/problems/OMWG/>

## Problem

Color every cell of a grid one at a time, and report the largest possible total score. Each move scores the number of already colored cells that share a side with the chosen cell, so the answer is the number of side-adjacent cell pairs in the grid.

The first line holds the case count. Each later line holds the row count and the column count. Print one integer per case.

| Item | Bound |
|---|---|
| Cases | 1 to 100 |
| Rows N | 0 to 1000 |
| Columns M | 0 to 1000 |
| Judge limit | 500 ms, 1536 MB |

An empty row or column leaves no cell pairs to score.

The sample input colors a two by two grid:

```
1
2 2
```

The expected output is:

```
4
```

## Idea

Think of every shared side as a ticket that gets cashed when its second cell is colored, like a turnstile that charges only on the way out. Count side-adjacent pairs directly; no ordering search is needed. Horizontal pairs number `rowCount - 1` per row and vertical pairs number `columnCount - 1` per column. Trying every coloring order would explore an enormous search tree, while this count takes constant work per case. The maximum equals the fixed total, so no strategy can beat it.

## Why It Works

1. Each shared side joins exactly two cells.
2. The first of those cells is colored before the second one.
3. The second cell scores that shared side once, and never again.
4. Every shared side contributes one point in every complete coloring.
5. Horizontal and vertical sides are disjoint, so their counts add.

| Term | Meaning |
|---|---|
| `rowCount` | number of grid rows |
| `columnCount` | number of grid columns |
| `totalScore` | number of shared sides, hence the fixed total |

Empty grids have no cells and no shared sides.

A two by two grid has two horizontal pairs and two vertical pairs:

```
rows = 2, columns = 2
horizontal: (2 - 1) * 2 = 2
vertical:   (2 - 1) * 2 = 2
total:      2 + 2 = 4
```

The trace matches the sample output of four.

## Code

**Input and scanning.** The hand reader loads the case count and every grid size.

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
```

One pass reads all lines into a single string.
The scanner skips whitespace between numbers.
No number here is negative, so no sign branch appears.

**Output buffer.** Appending text avoids one write per case.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after it grows past the block size.
A final flush emits any remaining text.

**Pair count.** One formula handles every non-empty grid.

```nim
let caseCount = nextInt(inputData, scanPos)
var caseIndex = 1
while caseIndex <= caseCount:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  var totalScore: int64 = 0
  if rowCount > 0 and columnCount > 0:
    totalScore = int64(rowCount - 1) * int64(columnCount) + int64(columnCount - 1) * int64(rowCount)
  appendOutput($totalScore)
  outputBuffer.add '\n'
  caseIndex += 1
stdout.write outputBuffer
outputBuffer.setLen 0
```

The zero guard prevents a negative term on empty grids.
Both products use a 64-bit result for safety.
One line is appended per case.

## Complexity

Reading the input and writing the answers dominate.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over the case list | one input string |
| Pair count | constant work per case | constant |
| Output | one line per case | block buffer |

No grid is ever stored in memory.

| Measure | Big O |
|---|---|
| Time | O(T) |
| Space | O(1) besides input and output buffers |

Searching all coloring orders would take factorial time, so the direct count wins.
