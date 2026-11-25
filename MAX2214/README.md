# MAX2214 — Max 2214 (SPOJ)
<https://www.spoj.com/problems/MAX2214/>

## Problem

Place as many 2 by 2 squares and horizontal 1 by 4 bars as possible on a board with marked cells. Blocks must stay inside the board, avoid marked cells, and never overlap.

Input has one case. It starts with R and C, followed by R strings of C characters. A dot marks a free cell and an X marks a blocked cell. Print the maximum block count on one line.

| Constraint | Value |
| --- | --- |
| Rows R | 1 to 52 |
| Columns C | 1 to 22 |
| Cell character | '.' or 'X' |
| Judge time | 1976 ms |
| Judge memory | 1536 MB |

The sample input and its expected output follow byte for byte.

```
4 5
X....
X..XX
X..XX
....X
```

```
3
```

## Idea

Treat each row like a strip that can hold small bricks, and remember which bricks reach the next strip.

A 2 by 2 square uses two columns in the current row and two in the next row. A 1 by 4 bar uses four columns in the current row only. The program enumerates every row tiling made of gaps, column pairs, and 4-cell runs. For each tiling it splits the column pairs into pairs started in the previous row and pairs started in this row. A profile dynamic program keeps the best count for each previous-row mask. Enumerating whole placements of the board would be exponential in both dimensions. Row profiles keep the state to one column mask. Sweep rows, split pairs, then carry the next mask.

## Why It Works

1. Every block covers exactly four cells.
2. A 1 by 4 bar fits inside one row, so it only uses free cells in that row.
3. A 2 by 2 square uses the same two columns in two adjacent rows.
4. A row tiling assigns each occupied cell to a gap, a column pair, or a 4-cell run.
5. Splitting column pairs into old and new pairs accounts for each square exactly once.

| Term | Meaning |
| --- | --- |
| `tilingDominoMasks` | column pairs used by squares in a row tiling |
| `tilingBarMasks` | columns used by horizontal bars in a row tiling |
| `rowValues` | best count for each mask carried into the current row |
| `subsetBlocks` | blocks started in the current row for one pair split |

A script-generated check uses an empty board with 2 rows and 5 columns. The first row places squares on columns 0-1 and 2-3, so its next-row mask is 15 and its count is 2. The second row carries mask 15 and starts no new block, so the final count stays 2. No placement reaches three blocks because each block needs four cells.

## Code

**Input and grid reader.** The reader loads the whole stream and turns marked cells into column masks.

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

proc nextGridRow(data: string, pos: var int, width: int): string =
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\n' or data[pos] == '\r' or data[pos] == '\t'):
    pos += 1
  result = ""
  var taken = 0
  while taken < width and pos < data.len:
    result.add data[pos]
    pos += 1
    taken += 1

proc countBits(value: int): int =
  var remaining = value
  result = 0
  while remaining != 0:
    remaining = remaining and (remaining - 1)
    result += 1
```

Grid rows keep their dot and X characters unchanged.
Each bit of a mask is one board column.
`countBits` counts set columns in a mask.

**Output writer.** One buffer holds the single answer line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer follows the shared write path.
One flush emits the answer.
No other output is produced.

**Grid setup.** Each marked cell sets one bit in its row mask.

```nim
let rowCount = nextInt(inputData, scanPos)
let columnCount = nextInt(inputData, scanPos)
var blockedMasks = newSeq[int](rowCount)
var rowIndex = 0
while rowIndex < rowCount:
  let gridRow = nextGridRow(inputData, scanPos, columnCount)
  var columnIndex = 0
  while columnIndex < columnCount:
    if gridRow[columnIndex] == 'X':
      blockedMasks[rowIndex] = blockedMasks[rowIndex] or (1 shl columnIndex)
    columnIndex += 1
  rowIndex += 1
```

The row reader preserves every character.
Marked cells block both square halves and bars.
Unmarked cells remain available.

**Tiling enumeration.** Recursion places a gap, a column pair, or a 4-cell run at the first open column.

```nim
var tilingDominoMasks = newSeq[int]()
var tilingBarMasks = newSeq[int]()
var tilingStarts = newSeq[int]()
var subsetPreviousMasks = newSeq[int32]()
var subsetNextMasks = newSeq[int32]()
var subsetBlocks = newSeq[int8]()
var activeDominoes = newSeq[int]()

proc enumerateTilings(column: int, dominoMask: int, barMask: int, dominoCount: int, barCount: int) =
  if column == columnCount:
    tilingDominoMasks.add dominoMask
    tilingBarMasks.add barMask
    tilingStarts.add subsetPreviousMasks.len
    let subsetTotal = 1 shl dominoCount
    var subset = 0
    while subset < subsetTotal:
      var previousMask = 0
      var dominoPosition = 0
      while dominoPosition < dominoCount:
        if (subset and (1 shl dominoPosition)) != 0:
          previousMask = previousMask or activeDominoes[dominoPosition]
        dominoPosition += 1
      let nextMask = dominoMask and (not previousMask)
      let placedNow = dominoCount - countBits(subset) + barCount
      subsetPreviousMasks.add int32(previousMask)
      subsetNextMasks.add int32(nextMask)
      subsetBlocks.add int8(placedNow)
      subset += 1
    return
  enumerateTilings(column + 1, dominoMask, barMask, dominoCount, barCount)
  if column + 1 < columnCount:
    let squareMask = (1 shl column) or (1 shl (column + 1))
    activeDominoes.add squareMask
    enumerateTilings(column + 2, dominoMask or squareMask, barMask, dominoCount + 1, barCount)
    activeDominoes.setLen activeDominoes.len - 1
  if column + 4 <= columnCount:
    let firstBit = 1 shl column
    let secondBit = 1 shl (column + 1)
    let thirdBit = 1 shl (column + 2)
    let fourthBit = 1 shl (column + 3)
    enumerateTilings(column + 4, dominoMask, barMask or firstBit or secondBit or thirdBit or fourthBit, dominoCount, barCount + 1)

enumerateTilings(0, 0, 0, 0, 0)
```

Each complete tiling produces one subset per split.
`previousMask` lists squares counted in an earlier row.
`nextMask` lists squares counted in this row.

**Row sweep.** Each row selects compatible tilings and updates the carried mask values.

```nim
let tilingCount = tilingDominoMasks.len
let maskLimit = 1 shl columnCount
var rowValues = newSeq[int16](maskLimit)
var nextValues = newSeq[int16](maskLimit)
var maskIndex = 0
while maskIndex < maskLimit:
  rowValues[maskIndex] = int16(-1)
  nextValues[maskIndex] = int16(-1)
  maskIndex += 1
rowValues[0] = 0
let lastRow = rowCount - 1
rowIndex = 0
while rowIndex < rowCount:
  let blockedHere = blockedMasks[rowIndex]
  var blockedNext = 0
  if rowIndex == lastRow:
    blockedNext = maskLimit - 1
  else:
    blockedNext = blockedMasks[rowIndex + 1]
  maskIndex = 0
  while maskIndex < maskLimit:
    nextValues[maskIndex] = int16(-1)
    maskIndex += 1
  var tilingIndex = 0
  while tilingIndex < tilingCount:
    if (tilingDominoMasks[tilingIndex] and blockedHere) != 0 or (tilingBarMasks[tilingIndex] and blockedHere) != 0:
      tilingIndex += 1
      continue
    let subsetStart = tilingStarts[tilingIndex]
    var subsetEnd = subsetPreviousMasks.len
    if tilingIndex + 1 < tilingCount:
      subsetEnd = tilingStarts[tilingIndex + 1]
    var subsetIndex = subsetStart
    while subsetIndex < subsetEnd:
      let nextMask = int(subsetNextMasks[subsetIndex])
      if (nextMask and blockedNext) == 0:
        let previousMask = int(subsetPreviousMasks[subsetIndex])
        let previousBest = int(rowValues[previousMask])
        if previousBest >= 0:
          let candidate = previousBest + int(subsetBlocks[subsetIndex])
          if candidate > int(nextValues[nextMask]):
            nextValues[nextMask] = int16(candidate)
      subsetIndex += 1
    tilingIndex += 1
  swap rowValues, nextValues
  rowIndex += 1
appendOutput($int(rowValues[0]))
appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

The last row forbids any carried square.
A tiling is skipped when it touches a marked cell.
The empty carried mask after the last row holds the answer.

## Complexity

Tiling enumeration happens once. Each row scans all tilings and their pair splits.

| Phase | Time | Space |
| --- | --- | --- |
| Grid setup | one pass over R times C cells | R row masks |
| Tiling enumeration | O(F(C)) generated tilings | tiling and subset tables |
| Row sweep | O(R times S) subset splits | two arrays of 2 to the C |
| Output | one line | one output buffer |

| Measure | Big O |
| --- | --- |
| Time | O(R times S) after setup |
| Space | O(2 to the C plus S) |

Searching all block placements over the whole board grows far faster with C.

Enumerate row tilings once, then sweep rows with a compact column-mask state.
