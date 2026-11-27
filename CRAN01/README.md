# CRAN01 — An Experiment by Penny (SPOJ)

<https://www.spoj.com/problems/CRAN01/>

## Problem

A specimen starts on one cell of an n by m grid. Each second, every occupied cell may spread to at most two of its four side neighbors, and occupied cells stay occupied. Report the fewest seconds needed to fill the grid.

Input starts with T, the number of test cases. Each of the next T lines holds four integers: rows n, columns m, starting row x, and starting column y. Output one minimum time per line.

| item | bound |
|---|---|
| test cases T | 1 to 50 |
| rows n | 1 to 500 |
| columns m | 1 to 500 |
| start | 1 <= x <= n, 1 <= y <= m |
| judge limit | 3000 ms, 1536 MB |

Rows and columns are counted from one.

Sample input:

```
2
1 1 1 1
11 10 6 4
```

Sample output:

```
0
11
```

## Idea

The slowest cell is a farthest corner, like the last house reached when news travels one street per minute in each direction. Each second adds one step of row or column distance, so a cell at Manhattan distance d cannot fill sooner than d seconds.

The two-neighbor rule supplies enough branching to fill every cell within that distance. One formula with four subtractions answers each case in constant time. Simulating every spread step would cost far more work on a large grid.

The answer is the largest Manhattan distance from the start to any cell.

## Why It Works

1. A move changes the row or the column by one, never both.
2. A cell at row distance a and column distance b therefore needs a + b seconds at least.
3. The farthest row distance is the larger of x - 1 and n - x.
4. The farthest column distance is the larger of y - 1 and m - y.
5. Adding those two maxima gives the distance to a farthest corner.
6. Two new neighbors per occupied cell fill every closer cell inside that time.

| term | meaning |
|---|---|
| `rowsAbove` | rows between the start and the top edge |
| `rowsBelow` | rows between the start and the bottom edge |
| `columnsLeft` | columns between the start and the left edge |
| `columnsRight` | columns between the start and the right edge |
| `farthestRows` | larger vertical distance to an edge |
| `farthestColumns` | larger horizontal distance to an edge |

A worked trace from the generator:

| quantity | value |
|---|---|
| rows above row 6 of 11 | 5 |
| rows below row 6 of 11 | 5 |
| columns left of column 4 of 10 | 3 |
| columns right of column 4 of 10 | 6 |
| answer | 5 + 6 = 11 |

The trace matches the second sample answer.

## Code

**Input and buffer.** The reader loads all cases and sets up buffered output.

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
Each case consumes exactly four integers.
The buffer holds one line per case.

**Distance calculation.** Four edge distances give the answer directly.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  let initialRow = nextInt(inputData, scanPos)
  let initialColumn = nextInt(inputData, scanPos)
  let rowsAbove = initialRow - 1
  let rowsBelow = rowCount - initialRow
  let columnsLeft = initialColumn - 1
  let columnsRight = columnCount - initialColumn
  var farthestRows = rowsAbove
  if rowsBelow > farthestRows:
    farthestRows = rowsBelow
  var farthestColumns = columnsLeft
  if columnsRight > farthestColumns:
    farthestColumns = columnsRight
  appendOutput($(farthestRows + farthestColumns))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The larger row distance is chosen first.
The larger column distance is chosen next.
Their sum is written once per case.

## Complexity

Each test case reads four integers and writes one answer.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| distance work | four subtractions per case | constant |
| output | one line per case | block buffer |

Reading the input dominates the runtime.

| measure | Big O |
|---|---|
| time | O(T) |
| space | O(input size) |

Simulating the spread cell by cell would cost far more than four subtractions.
The closed form keeps large grids cheap.
