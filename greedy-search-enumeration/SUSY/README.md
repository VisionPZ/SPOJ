# SUSY — Helping Susy (SPOJ)

<https://www.spoj.com/problems/SUSY/>

## Problem

A player slides across a walled board until a wall stops each move. Find the fewest slides that pass through every magic stone, then give the alphabetically smallest move list among those shortest slides.

Input starts with two integers, the row count and the column count. The next rows give the board: a dot for open space, a hash for a wall, an `S` for the start, and a star for a stone. Output one line with the move count, then one line with the move names joined by hyphens. The names are Down, Left, Right and Up.

| item | bound |
|---|---|
| rows and columns | 2 to 20 each |
| stones | at most 13 |
| solution guarantee | at least one legal route |
| judge limit | 1000 ms, 1536 MB |

Thirteen stones make a bitmask small enough for a state graph.

Sample input:

```
5 6
*S....
....#.
.##...
**....
.#.*#.
```

Sample output:

```
7
Down-Right-Down-Left-Up-Left-Up
```

The sample collects four stones in seven slides.

## Idea

Treat each slide like a hockey puck that travels until it hits a rail, then count where it stops and which stones it crossed. Breadth-first search over pairs of a cell and a collected-stone mask finds the fewest slides, and visiting directions in alphabetical order gives the smallest move list. Precomputing each stop once makes a step constant time. Listing every move sequence would repeat the same slides many times. Search the paired state, not the raw sequence.

## Why It Works

1. A slide from a cell always ends at the same stop, whatever the earlier moves were.
2. That slide always collects the same set of stones along its path.
3. A state pairs the stopping cell with a mask of collected stones.
4. Breadth-first search reaches each state first with the fewest slides.
5. Expanding Down, Left, Right, Up in that order makes the queue alphabetical at each depth.
6. The first full-mask state dequeued therefore carries the smallest shortest move list.

| term | meaning |
|---|---|
| `stoneIndex` | stone number assigned to a board cell, or minus one |
| `slideDestination` | stopping cell for one cell and direction |
| `slideStones` | mask of stones crossed by that slide |
| `maskCount` | number of possible stone masks |
| `fullMask` | mask with every stone collected |
| `stateParent` | previous state used to rebuild the move list |

The precomputed slide tables turn a move into two array reads.

A trace of the sample uses cell numbers equal to row times six plus column:

```
start cell 1 mask 0
Down -> cell 7 mask 0
Right -> cell 9 mask 0
Down -> cell 27 mask 8
Left -> cell 26 mask 8
Up -> cell 20 mask 8
Left -> cell 18 mask 14
Up -> cell 0 mask 15
```

The last move reaches mask 15, so all four stones are collected in seven slides.

## Code

**Input and slide tables.** The reader keeps the board and precomputes every stopping move.

```nim
const flushBlockBytes = 1 shl 17
const directionNames = ["Down", "Left", "Right", "Up"]
const directionSteps = [(1, 0), (0, -1), (0, 1), (-1, 0)]

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

The hand scanner ignores stray spaces reported on this problem.
Each board row is padded with dots when its line is short.
The direction constants fix the alphabetical expansion order.

```nim
var stoneIndex = newSeq[int](rowCount * columnCount)
for cellIndex in 0 .. rowCount * columnCount - 1:
  stoneIndex[cellIndex] = -1
var stoneCount = 0
var startCell = 0
for rowIndex in 0 .. rowCount - 1:
  for columnIndex in 0 .. columnCount - 1:
    let cellIndex = rowIndex * columnCount + columnIndex
    let cellChar = mazeRows[rowIndex][columnIndex]
    if cellChar == '*':
      stoneIndex[cellIndex] = stoneCount
      stoneCount += 1
    elif cellChar == 'S':
      startCell = cellIndex

let maskCount = 1 shl stoneCount
let fullMask = maskCount - 1
var slideDestination = newSeq[int](rowCount * columnCount * 4)
var slideStones = newSeq[int](rowCount * columnCount * 4)
for cellIndex in 0 .. rowCount * columnCount - 1:
  let startRow = cellIndex div columnCount
  let startColumn = cellIndex mod columnCount
  for directionIndex in 0 .. 3:
    let stepRow = directionSteps[directionIndex][0]
    let stepColumn = directionSteps[directionIndex][1]
    var currentRow = startRow
    var currentColumn = startColumn
    var collectedMask = 0
    while true:
      let nextRow = currentRow + stepRow
      let nextColumn = currentColumn + stepColumn
      if nextRow < 0 or nextRow >= rowCount or nextColumn < 0 or nextColumn >= columnCount:
        break
      let nextCell = nextRow * columnCount + nextColumn
      if mazeRows[nextRow][nextColumn] == '#':
        break
      currentRow = nextRow
      currentColumn = nextColumn
      if stoneIndex[nextCell] >= 0:
        collectedMask = collectedMask or (1 shl stoneIndex[nextCell])
    let stateIndex = cellIndex * 4 + directionIndex
    slideDestination[stateIndex] = currentRow * columnCount + currentColumn
    slideStones[stateIndex] = collectedMask
```

Every cell gets four stop entries, one per direction.
A slide walks until it meets a wall or the board edge.
The table holds at most 3200 cells times four directions.

**Search and path output.** Breadth-first search finds the first full mask, then parents rebuild the move list.

```nim
var startMask = 0
if stoneIndex[startCell] >= 0:
  startMask = 1 shl stoneIndex[startCell]
let startState = startCell * maskCount + startMask
let stateTotal = rowCount * columnCount * maskCount
var stateSeen = newSeq[bool](stateTotal)
var stateParent = newSeq[int](stateTotal)
var stateDirection = newSeq[int](stateTotal)
for stateIndex in 0 .. stateTotal - 1:
  stateParent[stateIndex] = -1
  stateDirection[stateIndex] = -1
var searchQueue = newSeq[int](stateTotal)
var queueHead = 0
var queueTail = 0
searchQueue[queueTail] = startState
queueTail += 1
stateSeen[startState] = true
var goalState = -1
while queueHead < queueTail and goalState == -1:
  let currentState = searchQueue[queueHead]
  queueHead += 1
  let currentCell = currentState div maskCount
  let currentMask = currentState mod maskCount
  if currentMask == fullMask:
    goalState = currentState
    break
  for directionIndex in 0 .. 3:
    let moveIndex = currentCell * 4 + directionIndex
    let nextCell = slideDestination[moveIndex]
    let nextMask = currentMask or slideStones[moveIndex]
    let nextState = nextCell * maskCount + nextMask
    if not stateSeen[nextState]:
      stateSeen[nextState] = true
      stateParent[nextState] = currentState
      stateDirection[nextState] = directionIndex
      searchQueue[queueTail] = nextState
      queueTail += 1
```

The queue holds each paired state once.
The first full mask dequeued ends the search.
Direction order makes that state the smallest shortest answer.

```nim
var moveCount = 0
var traceState = goalState
while traceState != startState and traceState != -1:
  moveCount += 1
  traceState = stateParent[traceState]
var moveDirections = newSeq[int](moveCount)
traceState = goalState
for moveIndex in countdown(moveCount - 1, 0):
  if traceState == startState:
    break
  moveDirections[moveIndex] = stateDirection[traceState]
  traceState = stateParent[traceState]

appendOutput($moveCount)
outputBuffer.add '\n'
for moveIndex in 0 .. moveCount - 1:
  if moveIndex > 0:
    outputBuffer.add '-'
  outputBuffer.add directionNames[moveDirections[moveIndex]]
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Parent links turn the winning state back into a move list.
Hyphens join the names on the second output line.
One buffered write ends the program.

## Complexity

The slide tables are built once, then search visits paired states.

| phase | time | space |
|---|---|---|
| input read | one pass over the board | one input string |
| slide tables | four walks per cell | two tables of four entries per cell |
| search | one visit per paired state | parent and seen arrays |
| output | one buffered write | one output string |

The table pays for itself on every repeated visit to a cell.

| measure | Big O |
|---|---|
| time | O(cells × masks × 4) |
| space | O(cells × masks) |

Enumerating raw move sequences grows as four to the move count, while this search grows with cells times masks.
Precompute stops once and search paired states to keep the smallest shortest route.
