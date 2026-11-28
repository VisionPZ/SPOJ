# QKP — Queens, Knights and Pawns (SPOJ)
<https://www.spoj.com/problems/QKP/>

## Problem

A board has queens, knights, and pawns. Count the empty squares that no queen or knight attacks. Pawns never attack, but they stop queen rays.

| item | bound |
|---|---|
| board rows and columns | at most 1000 each |
| pieces of each type | at most 100 |
| coordinates | 1-based row then column |
| judge limit | 400 ms, 1536 MB |

A case with `0 0` ends the input. Each case prints one numbered line.

Sample input:

```
4 4
2 1 4 2 4
1 1 2
1 2 3
2 3
1 1 2
1 1 1
0
1000 1000
1 3 3
0
0
0 0
```

Sample output:

```
Board 1 has 6 safe squares.
Board 2 has 0 safe squares.
Board 3 has 996998 safe squares.
```

## Idea

Reading queen attacks is like shining eight flashlights from each queen, with pieces acting as walls. Knights instead hop to a short fixed list of squares. The algorithm marks attacked cells once and then scans the board. Rechecking every square against every piece would repeat the same work many times.

## Why It Works

1. A queen ray travels in one of eight untiled directions.
2. The first occupied cell on that ray stops the ray, and that cell stays unmarked by it.
3. A knight reaches up to eight cells and ignores blockers.
4. Marked cells together with occupied cells cover every unsafe square.
5. Counting the remaining cells gives the number of safe squares.

| term | meaning |
|---|---|
| `occupied` | byte flag for each square holding a piece |
| `attacked` | byte flag for each square under attack |
| `rowSteps` | eight row directions from a queen |
| `knightRowSteps` | eight row offsets from a knight |
| `safeCount` | number of empty, unmarked squares |

On the first sample board, queens sit at `(1,4)` and `(2,4)`, a knight at `(1,2)`, and a pawn at `(2,3)`. The pawn stops the ray from `(2,4)` toward the lower left. Six squares stay safe: `(1,1)`, `(2,1)`, `(2,2)`, `(3,2)`, `(4,1)`, and `(4,3)`.

The `directionCount` constant keeps queen rays and knight hops in one shared loop shape.

## Code

**Input and helpers.** The reader loads all text, and the eight offsets drive both attack types.

```nim
const flushBlockBytes = 1 shl 17
const directionCount = 8

var rowSteps = [1, 1, 0, -1, -1, -1, 0, 1]
var columnSteps = [0, 1, 1, 1, 0, -1, -1, -1]
var knightRowSteps = [1, 2, 2, 1, -1, -2, -2, -1]
var knightColumnSteps = [2, 1, -1, -2, 2, 1, -1, -2]

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

All coordinates are positive, so the scanner skips separators only.
The block flush keeps writes rare.
Rows and columns are converted to zero-based indexes when read.

**Board scan.** Each board marks occupancy, then queen rays, then knight hops.

```nim
var boardNumber = 0
while true:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  if rowCount == 0 and columnCount == 0:
    break
  boardNumber += 1
  var queenRows = newSeq[int]()
  var queenColumns = newSeq[int]()
  var knightRows = newSeq[int]()
  var knightColumns = newSeq[int]()
  var cellCount = rowCount * columnCount
  var occupied = newSeq[uint8](cellCount)
  var attacked = newSeq[uint8](cellCount)
  let queenCount = nextInt(inputData, scanPos)
  for pieceIndex in 0 .. queenCount - 1:
    let pieceRow = nextInt(inputData, scanPos) - 1
    let pieceColumn = nextInt(inputData, scanPos) - 1
    queenRows.add pieceRow
    queenColumns.add pieceColumn
    occupied[pieceRow * columnCount + pieceColumn] = 1
  let knightCount = nextInt(inputData, scanPos)
  for pieceIndex in 0 .. knightCount - 1:
    let pieceRow = nextInt(inputData, scanPos) - 1
    let pieceColumn = nextInt(inputData, scanPos) - 1
    knightRows.add pieceRow
    knightColumns.add pieceColumn
    occupied[pieceRow * columnCount + pieceColumn] = 1
  let pawnCount = nextInt(inputData, scanPos)
  for pieceIndex in 0 .. pawnCount - 1:
    let pieceRow = nextInt(inputData, scanPos) - 1
    let pieceColumn = nextInt(inputData, scanPos) - 1
    occupied[pieceRow * columnCount + pieceColumn] = 1
  for queenIndex in 0 .. queenRows.len - 1:
    let startRow = queenRows[queenIndex]
    let startColumn = queenColumns[queenIndex]
    for directionIndex in 0 .. directionCount - 1:
      var stepRow = startRow + rowSteps[directionIndex]
      var stepColumn = startColumn + columnSteps[directionIndex]
      while stepRow >= 0 and stepRow < rowCount and stepColumn >= 0 and stepColumn < columnCount:
        let cellIndex = stepRow * columnCount + stepColumn
        if occupied[cellIndex] != 0:
          break
        attacked[cellIndex] = 1
        stepRow = stepRow + rowSteps[directionIndex]
        stepColumn = stepColumn + columnSteps[directionIndex]
  for knightIndex in 0 .. knightRows.len - 1:
    let startRow = knightRows[knightIndex]
    let startColumn = knightColumns[knightIndex]
    for directionIndex in 0 .. directionCount - 1:
      let stepRow = startRow + knightRowSteps[directionIndex]
      let stepColumn = startColumn + knightColumnSteps[directionIndex]
      if stepRow >= 0 and stepRow < rowCount and stepColumn >= 0 and stepColumn < columnCount:
        attacked[stepRow * columnCount + stepColumn] = 1
  var safeCount: int64 = 0
  for cellIndex in 0 .. cellCount - 1:
    if occupied[cellIndex] == 0 and attacked[cellIndex] == 0:
      safeCount += 1
  appendOutput("Board ")
  appendOutput($boardNumber)
  appendOutput(" has ")
  appendOutput($safeCount)
  appendOutput(" safe squares.\n")
```

Every piece sets the occupancy flag for its square.
A queen ray stops before it marks an occupied square.
Knight hops land directly in the attack grid.
The final scan counts only squares that are empty and unmarked.

## Complexity

| phase | time | space |
|---|---|---|
| read pieces | one pass over three piece lists | piece position arrays |
| queen rays | at most 8 times 1000 cells per queen | two byte grids |
| knight hops | 8 cells per knight | two byte grids |
| final scan | one pass over the board | block buffer |

| measure | Big O |
|---|---|
| per board | O(n*m + Q*8*max(n,m) + K) |
| space | O(n*m) |

Checking each square against every queen would cost far more on a large board.
