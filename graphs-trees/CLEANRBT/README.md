<https://www.spoj.com/problems/CLEANRBT/>

## Problem

Given a tiled room with dirty tiles and obstacles, find the fewest moves for a robot to clean every dirty tile. Report minus one when some dirty tile cannot be reached.

Each map starts with `w h`, the width and height in tiles. Then `h` rows of `w` characters follow: `.` for clean, `*` for dirty, `x` for furniture, and `o` for the robot. A line `0 0` ends the input. Print one integer per map: the minimum move count or `-1`.

| item | bound |
|---|---|
| width and height | at most 20 |
| dirty tiles | at most 10 |
| robots | exactly one |
| judge limit | 1000 ms, 1536 MB |

The robot may revisit tiles, and each move crosses one side of a tile.

Sample input:

```
7 5
.......
.o...*.
.......
.*...*.
.......
15 13
.......x.......
...o...x....*..
.......x.......
.......x.......
.......x.......
...............
xxxxx.....xxxxx
...............
.......x.......
.......x.......
.......x.......
..*....x....*..
.......x.......
10 10
..........
..o.......
..........
..........
..........
.....xxxxx
.....x....
.....x.*..
.....x....
.....x....
0 0
```

Sample output:

```
8
49
-1
```

## Idea

Remember which dirty tiles are already clean while walking, like carrying a checklist through a building. Breadth-first search over position plus checklist states finds the first time every tile is clean. Each state stores one cell and one mask, and each move costs one step. This replaces a long permutation search over cleaning orders. The takeaway is that a small number of dirty tiles keeps the state graph small.

## Why It Works

1. A bit in `currentMask` marks one dirty tile as clean.
2. A state pairs a grid cell with a mask, so revisiting a cell with more clean tiles is a new state.
3. Every move adds one step, so breadth-first search returns the first complete mask at minimum cost.
4. Obstacles and grid edges remove moves, keeping unreachable tiles unmatched.
5. An empty mask target makes the starting state the answer with zero moves.

| term | meaning |
|---|---|
| `dirtyIndex` | mask bit assigned to each dirty tile |
| `fullMask` | mask with every dirty bit set |
| `distanceTable` | steps to each cell-and-mask state |
| `stateQueue` | states waiting for expansion |
| `bestMoves` | first step count that completes the mask |

States are enqueued once, so the search terminates after at most cell count times mask count expansions.

In the first sample map the start is row 1, column 1, with dirty tiles at `(1,5)`, `(3,1)`, and `(3,5)`. Distances from the start are `4`, `2`, and `6`. Walking start to `(3,1)` takes `2`, then to `(3,5)` takes `4`, then to `(1,5)` takes `2`, for `8` moves.

No rounding occurs because distances are integers.

## Code

**Input and scanning.** The reader loads input once and parses integers and map cells by hand.

```nim
const flushBlockBytes = 1 shl 17
const directionRows = [1, -1, 0, 0]
const directionColumns = [0, 0, 1, -1]

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

proc nextCellChar(data: string, pos: var int): char =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  result = data[pos]
  pos += 1
```

Map characters are read in row-major order.
Whitespace between rows is skipped automatically.
The zero map closes the input.

**Output helper.** One buffer holds every answer line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Writes happen in blocks rather than per map.
The final flush emits any remaining bytes.

**State search.** The map is converted to indices, then breadth-first search carries the mask.

```nim
while true:
  let widthCount = nextInt(inputData, scanPos)
  let heightCount = nextInt(inputData, scanPos)
  if widthCount == 0 and heightCount == 0:
    break
  let cellCount = widthCount * heightCount
  var blockedCells = newSeq[bool](cellCount)
  var dirtyIndex = newSeq[int](cellCount)
  for cellIndex in 0 .. cellCount - 1:
    dirtyIndex[cellIndex] = -1
  var dirtyCount = 0
  var startIndex = -1
  for cellIndex in 0 .. cellCount - 1:
    let cellChar = nextCellChar(inputData, scanPos)
    if cellChar == 'x':
      blockedCells[cellIndex] = true
    elif cellChar == '*':
      dirtyIndex[cellIndex] = dirtyCount
      dirtyCount += 1
    elif cellChar == 'o':
      startIndex = cellIndex
  let fullMask = (1 shl dirtyCount) - 1
  var bestMoves = -1
  if fullMask == 0:
    bestMoves = 0
  let stateCount = cellCount * (fullMask + 1)
  var distanceTable = newSeq[int](stateCount)
  for stateIndex in 0 .. stateCount - 1:
    distanceTable[stateIndex] = -1
  var stateQueue = newSeq[int](stateCount)
  var queueHead = 0
  var queueTail = 0
  let initialState = startIndex * (fullMask + 1)
  distanceTable[initialState] = 0
  stateQueue[queueTail] = initialState
  queueTail += 1
  while queueHead < queueTail and bestMoves == -1:
    let currentState = stateQueue[queueHead]
    queueHead += 1
    let currentCell = currentState div (fullMask + 1)
    let currentMask = currentState mod (fullMask + 1)
    let currentRow = currentCell div widthCount
    let currentColumn = currentCell mod widthCount
    for directionIndex in 0 .. 3:
      let nextRow = currentRow + directionRows[directionIndex]
      let nextColumn = currentColumn + directionColumns[directionIndex]
      if nextRow < 0 or nextRow >= heightCount:
        continue
      if nextColumn < 0 or nextColumn >= widthCount:
        continue
      let neighborCell = nextRow * widthCount + nextColumn
      if blockedCells[neighborCell]:
        continue
      var nextMask = currentMask
      if dirtyIndex[neighborCell] != -1:
        nextMask = currentMask or (1 shl dirtyIndex[neighborCell])
      let neighborState = neighborCell * (fullMask + 1) + nextMask
      if distanceTable[neighborState] != -1:
        continue
      distanceTable[neighborState] = distanceTable[currentState] + 1
      if nextMask == fullMask:
        bestMoves = distanceTable[neighborState]
        break
      stateQueue[queueTail] = neighborState
      queueTail += 1
  appendOutput($bestMoves)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

A missing dirty tile leaves `bestMoves` at minus one.
The queue uses one integer per state.
The search stops once the complete mask appears.

## Complexity

Each state enters the queue once, and four neighbors are tested per state.

| phase | time | space |
|---|---|---|
| input read | one pass over map cells | one input string |
| map setup | one pass over cells | obstacle and dirty arrays |
| state search | four moves per cell-and-mask state | distances and queue |
| output | one line per map | block buffer |

| measure | Big O |
|---|---|
| time per map | `O(w*h*2^k)` |
| space per map | `O(w*h*2^k)` |

An explicit search over cleaning orders would compare many permutations instead of one compact state graph.

The mask carries the checklist through every tile the robot visits.
