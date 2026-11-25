# SPIRALGR — A Famous Grid (SPOJ)

<https://www.spoj.com/problems/SPIRALGR/>

## Problem

Numbers are placed in an outward square spiral starting at 1. Travel is allowed through 1 and composite numbers, while prime cells are walls. Report the shortest four-direction path length between two given numbers, or `impossible`.

Each input line contains two nonprime integers `x` and `y`, both from 1 to 10000. There is no leading test count, so read pairs until end of input. Print `Case k: ` followed by the distance or `impossible`.

| item | bound |
|---|---|
| each endpoint | 1 to 10000, nonprime |
| spiral radius precomputed | 70 cells around 1 |
| cells precomputed | 141 by 141 |
| judge limit | 1000 ms, 1536 MB |

Numbers at most 10000 lie within 50 steps of the centre; the extra radius leaves room to detour around prime walls.

Sample input:

```
1 4
9 32
10 12
```

Sample output:

```
Case 1: 1
Case 2: 7
Case 3: impossible
```

## Idea

Lay the spiral out once, mark walls, then walk the shortest route like a pedestrian avoiding blocked streets.

The spiral is a square walk: move right, up, left, down, and grow each straight run after two turns. Walking that pattern once fills a grid and records the coordinates of every number. A sieve marks prime cells as blocked. A flood fill labels connected regions, so pairs in different regions get `impossible` without any search.

For the rest, group queries by their start cell and run one breadth-first search per distinct start. The search stops as soon as every target for that start is reached. A fresh search for each line would repeat the same work many times. One search per start answers all its queries at once.

## Why It Works

1. The spiral puts consecutive numbers on adjacent cells, so consecutive integers are always neighbours.
2. Two turns share each run length, giving the sequence 1, 1, 2, 2, 3, 3, and so on.
3. A sieve marks exactly the prime numbers, which are the blocked cells.
4. A flood fill labels connected components, so different labels prove no path exists.
5. Breadth-first search visits cells in increasing distance, so the first visit of a target gives the shortest length.
6. Grouping queries by start cell turns repeated walks into one walk with many targets.

| term | meaning |
|---|---|
| `numberX`, `numberY` | spiral coordinates recorded for each integer |
| `passable` | true for 1 and for composite cells |
| `componentId` | connected region label of each cell |
| `sourceHead` | first query whose start is a given cell |
| `distance` | current breadth-first depth of a cell |
| `pendingTargets` | targets of the current group still unanswered |

The table names the arrays that drive the search.

A script-traced example for the sample pairs:

| pair | coordinates | result |
|---|---|---|
| `1 4` | `(0,0)` and `(0,1)` | adjacent cells, distance `1` |
| `9 32` | `(1,-1)` and `(2,3)` | seven steps around prime walls |
| `10 12` | `(2,-1)` and `(2,1)` | 12 is enclosed by 11, 13, 3, and 29 |

The trace explains all three sample lines.

Breadth-first depth is reset for touched cells only, which keeps repeated searches cheap. A grid radius of 70 covers every path measured on pairs up to 10000, whose widest route stays near radius 51.

## Code

**Shared input and output helpers.** The reader consumes stdin once, and the writer flushes in blocks.

```nim
const flushBlockBytes = 1 shl 17
const gridRadius = 70
const gridSide = 2 * gridRadius + 1
const cellCount = gridSide * gridSide
const largestNumber = cellCount
const deltaX = [1, 0, -1, 0]
const deltaY = [0, 1, 0, -1]

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

proc hasMoreTokens(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len:
    if data[cursor] >= '0' and data[cursor] <= '9':
      return true
    cursor += 1
  return false

proc flatIndex(gridX: int, gridY: int): int =
  return (gridY + gridRadius) * gridSide + gridX + gridRadius

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The EOF check finds the next digit after any whitespace.
The flat index maps grid coordinates into one array.
Four direction arrays keep the spiral and the searches consistent.

**Sieve and spiral.** One walk records every number's cell and marks walls.

```nim
var isPrime = newSeq[bool](largestNumber + 1)
for numberValue in 2 .. largestNumber:
  isPrime[numberValue] = true
var factorValue = 2
while factorValue * factorValue <= largestNumber:
  if isPrime[factorValue]:
    var multipleValue = factorValue * factorValue
    while multipleValue <= largestNumber:
      isPrime[multipleValue] = false
      multipleValue += factorValue
  factorValue += 1

var numberX = newSeq[int](largestNumber + 1)
var numberY = newSeq[int](largestNumber + 1)
var currentX = 0
var currentY = 0
var directionIndex = 0
var stepLength = 1
var stepsTaken = 0
var directionRepeat = 0
var numberValue = 1
while numberValue < largestNumber:
  currentX += deltaX[directionIndex]
  currentY += deltaY[directionIndex]
  numberValue += 1
  numberX[numberValue] = currentX
  numberY[numberValue] = currentY
  stepsTaken += 1
  if stepsTaken == stepLength:
    stepsTaken = 0
    directionIndex = (directionIndex + 1) mod 4
    if directionRepeat == 0:
      directionRepeat = 1
    else:
      directionRepeat = 0
      stepLength += 1

var passable = newSeq[bool](cellCount)
for spiralNumber in 1 .. largestNumber:
  let cell = flatIndex(numberX[spiralNumber], numberY[spiralNumber])
  passable[cell] = spiralNumber == 1 or not isPrime[spiralNumber]
```

The sieve crosses out multiples starting at each factor's square.
Two turns share a run length, as the spiral requires.
The passable flag excludes primes and keeps 1 open.

**Components and query grouping.** Regions are labelled once, and queries share a start list.

```nim
var componentId = newSeq[int](cellCount)
for cell in 0 .. cellCount - 1:
  componentId[cell] = -1
var floodStack = newSeq[int](cellCount)
var componentCount = 0
for startCell in 0 .. cellCount - 1:
  if not passable[startCell] or componentId[startCell] != -1:
    continue
  var stackSize = 0
  floodStack[stackSize] = startCell
  stackSize += 1
  componentId[startCell] = componentCount
  while stackSize > 0:
    stackSize -= 1
    let currentCell = floodStack[stackSize]
    let currentY = currentCell div gridSide
    let currentX = currentCell mod gridSide
    for direction in 0 .. 3:
      let neighborX = currentX + deltaX[direction]
      let neighborY = currentY + deltaY[direction]
      if neighborX < 0 or neighborX >= gridSide or neighborY < 0 or neighborY >= gridSide:
        continue
      let neighborCell = neighborY * gridSide + neighborX
      if not passable[neighborCell] or componentId[neighborCell] != -1:
        continue
      componentId[neighborCell] = componentCount
      floodStack[stackSize] = neighborCell
      stackSize += 1
  componentCount += 1

var queryStarts = newSeq[int]()
var queryEnds = newSeq[int]()
while hasMoreTokens(inputData, scanPos):
  queryStarts.add nextInt(inputData, scanPos)
  queryEnds.add nextInt(inputData, scanPos)
let queryCount = queryStarts.len

var sourceHead = newSeq[int](cellCount)
var nextInSource = newSeq[int](queryCount)
var answerForQuery = newSeq[int](queryCount)
for cell in 0 .. cellCount - 1:
  sourceHead[cell] = -1
for queryIndex in 0 .. queryCount - 1:
  let startCell = flatIndex(numberX[queryStarts[queryIndex]], numberY[queryStarts[queryIndex]])
  nextInSource[queryIndex] = sourceHead[startCell]
  sourceHead[startCell] = queryIndex
  answerForQuery[queryIndex] = -1

var distance = newSeq[int](cellCount)
for cell in 0 .. cellCount - 1:
  distance[cell] = -1
var searchQueue = newSeq[int](cellCount)
var touchedCells = newSeq[int](cellCount)
var targetHead = newSeq[int](cellCount)
var targetNext = newSeq[int](queryCount)
for cell in 0 .. cellCount - 1:
  targetHead[cell] = -1
```

The flood fill visits each passable cell once.
Linked lists collect queries that share a start or a target.
Arrays for the search are allocated once and reused.

**Grouped search and output.** One breadth-first search answers every query with the same start.

```nim
for startCell in 0 .. cellCount - 1:
  if sourceHead[startCell] == -1:
    continue
  var pendingTargets = 0
  var groupQuery = sourceHead[startCell]
  while groupQuery != -1:
    let endCell = flatIndex(numberX[queryEnds[groupQuery]], numberY[queryEnds[groupQuery]])
    if componentId[endCell] == componentId[startCell]:
      targetNext[groupQuery] = targetHead[endCell]
      targetHead[endCell] = groupQuery
      pendingTargets += 1
    else:
      targetNext[groupQuery] = -1
    groupQuery = nextInSource[groupQuery]
  if pendingTargets == 0:
    groupQuery = sourceHead[startCell]
    while groupQuery != -1:
      let endCell = flatIndex(numberX[queryEnds[groupQuery]], numberY[queryEnds[groupQuery]])
      targetHead[endCell] = -1
      groupQuery = nextInSource[groupQuery]
    continue

  var queueStart = 0
  var queueEnd = 0
  searchQueue[queueEnd] = startCell
  queueEnd += 1
  distance[startCell] = 0
  var touchedCount = 0
  touchedCells[touchedCount] = startCell
  touchedCount += 1

  while queueStart < queueEnd and pendingTargets > 0:
    let currentCell = searchQueue[queueStart]
    queueStart += 1
    let currentDistance = distance[currentCell]
    var matchingQuery = targetHead[currentCell]
    while matchingQuery != -1:
      let followingQuery = targetNext[matchingQuery]
      if answerForQuery[matchingQuery] == -1:
        answerForQuery[matchingQuery] = currentDistance
        pendingTargets -= 1
      matchingQuery = followingQuery
    let currentY = currentCell div gridSide
    let currentX = currentCell mod gridSide
    for direction in 0 .. 3:
      let neighborX = currentX + deltaX[direction]
      let neighborY = currentY + deltaY[direction]
      if neighborX < 0 or neighborX >= gridSide or neighborY < 0 or neighborY >= gridSide:
        continue
      let neighborCell = neighborY * gridSide + neighborX
      if not passable[neighborCell] or distance[neighborCell] != -1:
        continue
      distance[neighborCell] = currentDistance + 1
      searchQueue[queueEnd] = neighborCell
      queueEnd += 1
      touchedCells[touchedCount] = neighborCell
      touchedCount += 1

  for touchedIndex in 0 .. touchedCount - 1:
    distance[touchedCells[touchedIndex]] = -1
  groupQuery = sourceHead[startCell]
  while groupQuery != -1:
    let endCell = flatIndex(numberX[queryEnds[groupQuery]], numberY[queryEnds[groupQuery]])
    targetHead[endCell] = -1
    groupQuery = nextInSource[groupQuery]

for queryIndex in 0 .. queryCount - 1:
  appendOutput("Case " & $(queryIndex + 1) & ": ")
  if answerForQuery[queryIndex] == -1:
    appendOutput("impossible\n")
  else:
    appendOutput($answerForQuery[queryIndex])
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Targets in other components never enter the search.
The walk stops when the last target of the group is reached.
Only touched cells need their distance reset before the next group.

## Complexity

The grid and component labels are built once; each distinct start gets one search.

| phase | time | space |
|---|---|---|
| sieve and spiral | one pass up to 19881 numbers | coordinate arrays |
| flood fill | one visit per passable cell | component labels |
| grouped search | one breadth-first walk per distinct start | queue and distance arrays |
| output | one buffered write per block | one output string |

The phase table separates one-time setup from per-query work.

| measure | Big O |
|---|---|
| setup | O(G), where G is the cell count |
| queries | O(S * G) worst case, for S distinct starts |
| space | O(G + Q) |

Running a separate search for every line would cost O(Q * G) instead of sharing work by start cell.
