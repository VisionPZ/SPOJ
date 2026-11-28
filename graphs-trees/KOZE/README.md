# KOZE — Sheep (SPOJ)

<https://www.spoj.com/problems/KOZE/>

## Problem

Count the sheep and wolves left alive after wolves attack a fenced backyard. Open sectors let every animal escape; closed sectors keep the animals, and sheep survive there only when they outnumber wolves.

Input gives rows `N`, columns `M`, then `N` strings of `M` characters. The characters are `.` for empty ground, `#` for fence, `k` for sheep, and `v` for wolf. Output one line with the surviving sheep count followed by the surviving wolf count.

| item | bound |
|---|---|
| rows `N` | 3 to 250 |
| columns `M` | 3 to 250 |
| judge limit | 1000 ms, 1536 MB |

A sector is one connected group of non-fence cells joined by horizontal and vertical steps.

```
8 8
.######.
#..k...#
#.####.#
#.#v.#.#
#.#.k#k#
#k.##..#
#.v..v#
.######.
```

```
3 1
```

## Idea

Think of each enclosed yard as a locked room: count the animals inside before declaring a winner. Flood fill discovers each sector in one pass over the grid. Each cell enters the queue once, so the total work stays linear. Checking every pair of cells would waste time on distant fields.

## Why It Works

1. A flood fill from a non-fence cell reaches exactly one sector.
2. A sector touches the border when any of its cells lies on the outer ring.
3. Animals in a border sector escape and both counts survive.
4. In a closed sector, sheep win only with a strictly larger count.
5. Ties and wolf majorities leave wolves alive.

| term | meaning |
|---|---|
| `field` | the grid of characters read from input |
| `visitedCell` | marks cells already assigned to a sector |
| `reachesBorder` | reports whether the current sector opens outside |
| `sectorSheep` | sheep counted inside the current sector |

In the sample, the central closed sector holds one sheep and one wolf, so the wolf wins there. Other closed sectors hold sheep alone, and border animals escape. The totals are three sheep and one wolf.

The queue stores flat cell indexes, so a neighbor is found with one addition or subtraction of `columnCount`.

## Code

**Input and scanning.** The reader loads the grid as non-space characters after the two sizes.

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

let rowCount = nextInt(inputData, scanPos)
let columnCount = nextInt(inputData, scanPos)
let fieldSize = rowCount * columnCount
var field = newSeq[char](fieldSize)
for cellIndex in 0 .. fieldSize - 1:
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
  field[cellIndex] = inputData[scanPos]
  scanPos += 1
```

Grid characters are read without relying on line breaks.
Fence cells stay in the array but are never queued.
One pass fills all `N * M` cells.

**Sector flood fill.** Each unvisited open cell starts one queue-based flood fill.

```nim
var visitedCell = newSeq[bool](fieldSize)
var floodQueue = newSeq[int](fieldSize)
var survivingSheep = 0
var survivingWolves = 0

for startCell in 0 .. fieldSize - 1:
  if visitedCell[startCell] or field[startCell] == '#':
    continue
  var queueHead = 0
  var queueTail = 0
  floodQueue[queueTail] = startCell
  queueTail += 1
  visitedCell[startCell] = true
  var sectorSheep = 0
  var sectorWolves = 0
  var reachesBorder = false
  while queueHead < queueTail:
    let currentCell = floodQueue[queueHead]
    queueHead += 1
    let currentRow = currentCell div columnCount
    let currentColumn = currentCell mod columnCount
    if currentRow == 0 or currentRow == rowCount - 1 or
       currentColumn == 0 or currentColumn == columnCount - 1:
      reachesBorder = true
    if field[currentCell] == 'k':
      sectorSheep += 1
    elif field[currentCell] == 'v':
      sectorWolves += 1
    if currentRow > 0:
      let neighborCell = currentCell - columnCount
      if not visitedCell[neighborCell] and field[neighborCell] != '#':
        visitedCell[neighborCell] = true
        floodQueue[queueTail] = neighborCell
        queueTail += 1
    if currentRow < rowCount - 1:
      let neighborCell = currentCell + columnCount
      if not visitedCell[neighborCell] and field[neighborCell] != '#':
        visitedCell[neighborCell] = true
        floodQueue[queueTail] = neighborCell
        queueTail += 1
    if currentColumn > 0:
      let neighborCell = currentCell - 1
      if not visitedCell[neighborCell] and field[neighborCell] != '#':
        visitedCell[neighborCell] = true
        floodQueue[queueTail] = neighborCell
        queueTail += 1
    if currentColumn < columnCount - 1:
      let neighborCell = currentCell + 1
      if not visitedCell[neighborCell] and field[neighborCell] != '#':
        visitedCell[neighborCell] = true
        floodQueue[queueTail] = neighborCell
        queueTail += 1
  if reachesBorder:
    survivingSheep += sectorSheep
    survivingWolves += sectorWolves
  elif sectorSheep > sectorWolves:
    survivingSheep += sectorSheep
  else:
    survivingWolves += sectorWolves

appendOutput($survivingSheep & " " & $survivingWolves & "\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

Four neighbor checks cover vertical and horizontal moves.
Border sectors add both animal counts.
The result is written once after all sectors are processed.

## Complexity

| phase | time | space |
|---|---|---|
| input read | one pass over the grid | one character array |
| flood fill | one visit per cell | visited flags and one queue |
| output | one line | block buffer |

| measure | Big O |
|---|---|
| time | O(N * M) |
| space | O(N * M) |

Checking all cell pairs would grow quadratically, while the flood fill stays linear.

Every cell belongs to one sector, so the linear bound holds for any fence layout.
