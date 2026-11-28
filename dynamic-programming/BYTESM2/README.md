# BYTESM2 — Philosophers Stone (SPOJ)

<https://www.spoj.com/problems/BYTESM2/>

## Problem

Collect the most stones on a trip from the first row of a tiled chamber to the last row. From a tile Harry may step to the tile below it or to a diagonal tile in the next row, and he collects the stones on each visited tile.

The input starts with the test count `T`. Each test gives the row count `h` and column count `w`, followed by `h` rows of `w` stone counts. Output one maximum total per test.

| item | bound |
|---|---|
| test cases T | 1 to 100 |
| rows h | 1 to 100 |
| columns w | 1 to 100 |
| stones per tile | 0 to 100 |
| judge limit | 1000 ms, 1536 MB |

A trip starts in any column of the first row and ends in any column of the last row.

Sample input:

```
1
6 5
3 1 7 4 2
2 1 3 1 1
1 2 2 1 8
2 2 1 5 3
2 1 4 4 4
5 2 7 5 1
```

Sample output:

```
32
```

## Idea

Keep only the best total that can reach each tile, like marking the highest score on each step of a staircase. Each tile looks at the three tiles above it and adds its own stones.

The algorithm is row-by-row dynamic programming with two rows of storage. Each tile costs three comparisons and one addition. Enumerating every route would revisit the same tiles many times and grow exponentially.

Two rolling rows hold the whole frontier, so the table never grows beyond one row.

## Why It Works

1. The best route into a tile must come from one of three tiles in the previous row.
2. The tile's own stones are added after choosing the best predecessor.
3. Processing rows in order guarantees that all predecessors are already final.
4. After the last row, the best tile in that row is the best trip total.
5. Swapping the two rows reuses memory without losing any predecessor values.

| term | meaning |
|---|---|
| `previousRow` | best totals ending on tiles in the row above |
| `currentRow` | best totals ending on tiles in the current row |
| `bestAbove` | largest eligible predecessor total |
| `bestHarvest` | largest total in the final row |

For the sample, the final row of totals is 19, 16, 26, 32, 22, and the largest entry 32 is printed. This matches the sample output.

The last row holds the answer after the sweep finishes.

## Code

**Input and scanner.** The reader loads every token with a hand scanner.

```nim
const flushBlockBytes = 1 shl 17

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

All input arrives in one string.
The scanner skips spaces and newlines automatically.
The output buffer flushes large blocks only.

**Row sweep.** The solver folds each row into the next and keeps two rows.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  var previousRow = newSeq[int](columnCount)
  var currentRow = newSeq[int](columnCount)
  for rowIndex in 0 .. rowCount - 1:
    for columnIndex in 0 .. columnCount - 1:
      let stoneCount = nextInt(inputData, scanPos)
      var bestAbove = previousRow[columnIndex]
      if columnIndex > 0 and previousRow[columnIndex - 1] > bestAbove:
        bestAbove = previousRow[columnIndex - 1]
      if columnIndex + 1 < columnCount and previousRow[columnIndex + 1] > bestAbove:
        bestAbove = previousRow[columnIndex + 1]
      currentRow[columnIndex] = stoneCount + bestAbove
    swap previousRow, currentRow
  var bestHarvest = previousRow[0]
  for columnIndex in 1 .. columnCount - 1:
    if previousRow[columnIndex] > bestHarvest:
      bestHarvest = previousRow[columnIndex]
  appendOutput($bestHarvest)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Boundary columns skip the missing diagonal.
The swap keeps the previous row available for the next pass.
Each tile is visited once per test.

## Complexity

Every tile costs a constant number of operations.

| phase | time | space |
|---|---|---|
| input read | one pass over all tokens | one input string |
| row sweep | three comparisons per tile | two rows of w integers |
| final scan | one pass over w totals | constant |
| output | one buffered write | block buffer |

Two rolling rows keep the sweep cheap in memory.

| measure | Big O |
|---|---|
| time | O(T · h · w) |
| space | O(w) |

A full search of all routes would revisit shared tiles many times. The row sweep settles each tile once.
