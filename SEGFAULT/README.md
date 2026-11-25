# SEGFAULT — Segfault (SPOJ)

<https://www.spoj.com/problems/SEGFAULT/>

## Problem

Petar launches any number of programs from one start cell in a character grid. Each program steps to a neighbouring cell and captures free cells. Nikolaj launches straight-line programs that capture cells along a fixed direction. A tie over a free cell goes to Nikolaj. Find how many cells Petar can capture with the best plan.

The input gives `rowCount` and `columnCount`, then one string per row using `.`, `#`, and `S`. Next comes `programCount`, then one `X Y DIR` line per program with one-based coordinates. Print a single integer.

| item | bound |
|---|---|
| `rowCount`, `columnCount` | 1 to 1000 |
| `programCount` | 1 to 500000 |
| direction | `U`, `D`, `L`, `R` |
| judge limit | 300 ms, 1536 MB |

The product of rows and columns and the program count both drive the design, so each sweep must be linear.

Sample input:

```
6 5
#.S.#
.....
.....
...##
##...
...##
2
2 1 R
3 5 L
```

Sample output:

```
18
```

## Idea

Treat every free cell as a race between two runners, like two people reaching the same doorway. Nikolaj reaches a cell one step after his program enters its distance from the start, while Petar reaches it in his shortest path length. Cells Petar cannot reach before that deadline belong to Nikolaj, and they also wall off cells behind them. Sweep rows and columns once to find every deadline, then run two breadth-first searches. The first search finds Petar's shortest paths, and the second avoids the cells that Nikolaj wins. A per-step simulation would multiply work by the path length; the two sweeps avoid that.

## Why It Works

1. A Nikolaj program starting on a free cell captures that cell at time one, then one cell per step along its direction.
2. Obstacles `#` and `S` stop every program, so a deadline never crosses them.
3. For each row, a left-to-right sweep and a right-to-left sweep give the earliest right-moving and left-moving deadlines. Column sweeps do the same for the other two directions.
4. Petar's program reaches a cell at its breadth-first distance from `S`. It wins the cell exactly when that distance is strictly below the earliest deadline.
5. Once Petar wins a cell on a ray, that ray stops there, so all later cells on the ray have no deadline. Along a ray, distances rise by one per step, so every later cell also wins its race.
6. Removing the lost cells and searching again gives every cell Petar can reach, including cells freed by earlier blocks.

| term | meaning |
|---|---|
| `programFlags` | direction bits attached to program start cells |
| `nikolajTimes` | earliest Nikolaj capture time for each cell |
| `petarDistances` | breadth-first distance from `S` |
| `considerBlocks` | flag that activates the deadline check in the second search |
| `capturedCount` | number of cells Petar finally owns |

A worked trace from the sample follows.

```
cell        (2,1) (2,2) (2,3) (3,3) (3,4) (3,5)
petarDist     3     2     1     2     3     4
nikolajTime   1     2     3     3     2     1
outcome       lost  lost  won   won   lost  lost
```

The four lost cells stop both programs, and the second search counts the other 18 free cells.

## Code

**Input and hand scanner.** The reader loads stdin once and parses integers and directions.

```nim
const flushBlockBytes = 1 shl 17
const infDistance = 1 shl 28

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

`infDistance` stands for a cell with no Nikolaj deadline.
Grid strings are copied one character at a time into `cellKinds`.
Directions are read as single characters after the two coordinates.

**Buffered output.** A single line goes through the shared block buffer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The answer is appended once as text.
A write happens only after `flushBlockBytes` is reached.
The final flush prints the answer line.

**Bounded breadth-first search.** The second search skips cells that Nikolaj wins.

```nim
proc tryVisit(neighborIndex: int, cellKinds: seq[uint8], nikolajTimes: seq[int],
              petarDistances: var seq[int], visitQueue: var seq[int],
              queueTail: var int, nextDistance: int, considerBlocks: bool) =
  if cellKinds[neighborIndex] == 1:
    return
  if petarDistances[neighborIndex] != infDistance:
    return
  if considerBlocks and nikolajTimes[neighborIndex] != infDistance and
     nextDistance >= nikolajTimes[neighborIndex]:
    return
  petarDistances[neighborIndex] = nextDistance
  visitQueue[queueTail] = neighborIndex
  queueTail += 1
```

`cellKinds` value one marks an obstacle.
The deadline check is skipped in the first search.
The returned queue tail is the count of reached cells.

```nim
proc bfsDistances(cellKinds: seq[uint8], nikolajTimes: seq[int],
                  petarDistances: var seq[int], visitQueue: var seq[int],
                  startIndex: int, rowCount: int, columnCount: int,
                  considerBlocks: bool): int =
  for cellIndex in 0 .. rowCount * columnCount - 1:
    petarDistances[cellIndex] = infDistance
  var queueHead = 0
  var queueTail = 0
  petarDistances[startIndex] = 0
  visitQueue[queueTail] = startIndex
  queueTail += 1
  while queueHead < queueTail:
    let currentIndex = visitQueue[queueHead]
    queueHead += 1
    let nextDistance = petarDistances[currentIndex] + 1
    let currentRow = currentIndex div columnCount
    let currentColumn = currentIndex mod columnCount
    if currentRow > 0:
      tryVisit(currentIndex - columnCount, cellKinds, nikolajTimes, petarDistances,
               visitQueue, queueTail, nextDistance, considerBlocks)
    if currentRow < rowCount - 1:
      tryVisit(currentIndex + columnCount, cellKinds, nikolajTimes, petarDistances,
               visitQueue, queueTail, nextDistance, considerBlocks)
    if currentColumn > 0:
      tryVisit(currentIndex - 1, cellKinds, nikolajTimes, petarDistances,
               visitQueue, queueTail, nextDistance, considerBlocks)
    if currentColumn < columnCount - 1:
      tryVisit(currentIndex + 1, cellKinds, nikolajTimes, petarDistances,
               visitQueue, queueTail, nextDistance, considerBlocks)
  return queueTail
```

Four neighbours are checked for every popped cell.
Each cell enters the queue at most once.
The queue array is reused by both searches.

**Grid and program start flags.** Each start cell stores its direction as one bit.

```nim
let rowCount = nextInt(inputData, scanPos)
let columnCount = nextInt(inputData, scanPos)
while scanPos < inputData.len and inputData[scanPos] != '\n':
  scanPos += 1
scanPos += 1

var cellKinds = newSeq[uint8](rowCount * columnCount)
var startIndex = 0
for rowIndex in 0 .. rowCount - 1:
  for columnIndex in 0 .. columnCount - 1:
    let cellIndex = rowIndex * columnCount + columnIndex
    let cellChar = inputData[scanPos + columnIndex]
    if cellChar == '#':
      cellKinds[cellIndex] = 1
    elif cellChar == 'S':
      cellKinds[cellIndex] = 2
      startIndex = cellIndex
    else:
      cellKinds[cellIndex] = 0
  scanPos += columnCount + 1

var programFlags = newSeq[uint8](rowCount * columnCount)
let programCount = nextInt(inputData, scanPos)
for programIndex in 0 .. programCount - 1:
  let startRow = nextInt(inputData, scanPos) - 1
  let startColumn = nextInt(inputData, scanPos) - 1
  while scanPos < inputData.len and (inputData[scanPos] == ' ' or
        inputData[scanPos] == '\n' or inputData[scanPos] == '\r'):
    scanPos += 1
  let directionChar = inputData[scanPos]
  scanPos += 1
  let programIndexFlat = startRow * columnCount + startColumn
  if cellKinds[programIndexFlat] != 0:
    continue
  case directionChar
  of 'R':
    programFlags[programIndexFlat] = programFlags[programIndexFlat] or 1'u8
  of 'L':
    programFlags[programIndexFlat] = programFlags[programIndexFlat] or 2'u8
  of 'D':
    programFlags[programIndexFlat] = programFlags[programIndexFlat] or 4'u8
  of 'U':
    programFlags[programIndexFlat] = programFlags[programIndexFlat] or 8'u8
  else:
    discard
```

A start on `S` or `#` produces no captured cells.
Several programs may share one start cell and direction.
All coordinates become zero-based indexes.

**Row and column deadline sweeps.** Each sweep tracks the best start since the last obstacle.

```nim
var nikolajTimes = newSeq[int](rowCount * columnCount)
for cellIndex in 0 .. rowCount * columnCount - 1:
  nikolajTimes[cellIndex] = infDistance

for rowIndex in 0 .. rowCount - 1:
  var bestStart = -1
  var columnIndex = 0
  while columnIndex < columnCount:
    let cellIndex = rowIndex * columnCount + columnIndex
    if cellKinds[cellIndex] != 0:
      bestStart = -1
    else:
      if (programFlags[cellIndex] and 1'u8) != 0:
        bestStart = columnIndex
      if bestStart >= 0:
        let arrival = columnIndex - bestStart + 1
        if arrival < nikolajTimes[cellIndex]:
          nikolajTimes[cellIndex] = arrival
    columnIndex += 1
  bestStart = columnCount
  columnIndex = columnCount - 1
  while columnIndex >= 0:
    let cellIndex = rowIndex * columnCount + columnIndex
    if cellKinds[cellIndex] != 0:
      bestStart = columnCount
    else:
      if (programFlags[cellIndex] and 2'u8) != 0:
        bestStart = columnIndex
      if bestStart < columnCount:
        let arrival = bestStart - columnIndex + 1
        if arrival < nikolajTimes[cellIndex]:
          nikolajTimes[cellIndex] = arrival
    columnIndex -= 1
```

An obstacle resets `bestStart`, so no deadline crosses it.
`arrival` is the step on which the ray reaches the cell.
The minimum over all four directions wins.

```nim
for columnIndex in 0 .. columnCount - 1:
  var bestStart = -1
  var rowIndex = 0
  while rowIndex < rowCount:
    let cellIndex = rowIndex * columnCount + columnIndex
    if cellKinds[cellIndex] != 0:
      bestStart = -1
    else:
      if (programFlags[cellIndex] and 4'u8) != 0:
        bestStart = rowIndex
      if bestStart >= 0:
        let arrival = rowIndex - bestStart + 1
        if arrival < nikolajTimes[cellIndex]:
          nikolajTimes[cellIndex] = arrival
    rowIndex += 1
  bestStart = rowCount
  rowIndex = rowCount - 1
  while rowIndex >= 0:
    let cellIndex = rowIndex * columnCount + columnIndex
    if cellKinds[cellIndex] != 0:
      bestStart = rowCount
    else:
      if (programFlags[cellIndex] and 8'u8) != 0:
        bestStart = rowIndex
      if bestStart < rowCount:
        let arrival = bestStart - rowIndex + 1
        if arrival < nikolajTimes[cellIndex]:
          nikolajTimes[cellIndex] = arrival
    rowIndex -= 1
```

Column sweeps mirror the row sweeps.
Each cell receives at most one deadline per direction.
The whole sweep costs one pass over the grid.

**Two searches and output.** The first search measures races; the second counts captures.

```nim
var petarDistances = newSeq[int](rowCount * columnCount)
var visitQueue = newSeq[int](rowCount * columnCount)
discard bfsDistances(cellKinds, nikolajTimes, petarDistances, visitQueue,
                     startIndex, rowCount, columnCount, false)
let capturedCount = bfsDistances(cellKinds, nikolajTimes, petarDistances, visitQueue,
                                 startIndex, rowCount, columnCount, true)
appendOutput($capturedCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The first search ignores deadlines and records shortest distances.
The second search rejects any cell whose distance reaches its deadline.
`capturedCount` is the queue size from the second search.

## Complexity

Sweeps and searches process each cell a constant number of times.

| phase | time | space |
|---|---|---|
| input read | one pass over stdin bytes | one input string |
| deadline sweeps | four passes over the grid | time and flag arrays |
| breadth-first searches | two passes over the grid | distance and queue arrays |
| output | one line | block buffer |

| measure | Big O |
|---|---|
| time | O(rows · columns + programCount) |
| space | O(rows · columns) |

Simulating every step of every program multiplies work by the longest path, while the four sweeps settle all deadlines in linear time. The two searches then resolve every race without revisiting cells.
