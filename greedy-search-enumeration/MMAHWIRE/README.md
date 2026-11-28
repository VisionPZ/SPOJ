# MMAHWIRE — Manhattan Wire (SPOJ)

<https://www.spoj.com/problems/MMAHWIRE/>

## Problem

Draw two non-touching paths in a grid: one joins the two cells marked 2, and the other joins the two cells marked 3. Minimize the total number of cell borders crossed, or print 0 when no such pair exists.

The input holds several datasets. Each case starts with row count `n` and column count `m`. Then come `n` rows of `m` digits. Zero means empty, one means obstacle, and two and three mark cells. A line `0 0` ends the input. Output one minimum total per dataset.

| item | bound |
|---|---|
| rows n | 2 to 9 |
| columns m | 2 to 9 |
| datasets | until the `0 0` line |
| judge limit | 100 ms, 1536 MB |

A line may move only up, down, left, or right between non-obstacle cells, and no cell may carry more than one line.

Sample input:

```
5 5
0 0 0 0 0
0 0 0 3 0
2 0 2 0 0
1 0 1 1 1
0 0 0 0 3
2 3
2 2 0
0 3 3
6 5
2 0 0 0 0
0 3 0 0 0
0 0 0 0 0
1 1 1 0 0
0 0 0 0 0
0 0 2 3 0
0 0
```

Sample output:

```
18
2
17
```

## Idea

Grow one wire step by step. Let a shortest-path search finish the other wire. This is like laying one cable first, then routing the second around it. A length bound rises until a feasible pair appears.

The algorithm uses depth-first search for the first wire and breadth-first search for the second wire in the cells left free. Each first-wire step costs one recursive call, and each completed wire costs one breadth-first pass. Trying all pairs of full paths would multiply two large path lists.

The first feasible pair at the smallest bound gives the minimum total length.

## Why It Works

1. Both wires together occupy distinct cells, so removing the first wire leaves a valid grid for the second wire.
2. For any fixed first wire, breadth-first search finds the shortest possible second wire.
3. The sum of the shortest Manhattan distances is a lower bound for any pair of wires.
4. Iterative bounds from that lower bound upward test all totals in increasing order.
5. The first successful bound yields the smallest total, because shorter totals were already rejected.

| term | meaning |
|---|---|
| `blockedCells` | bit mask of cells used by the growing first wire |
| `lengthLimit` | current bound on the combined wire length |
| `searchFirstPath` | depth-first growth of the wire joining the 2 cells |
| `shortestSecondPath` | breadth-first search for the wire joining the 3 cells |

In the second sample the 2 cells are adjacent, so the first wire has length 1. The 3 cells are also adjacent, so the second wire has length 1 and the answer is 2.

The reported total counts borders crossed by both wires.

## Code

**Input and grid state.** The reader loads each dataset and records the four marked cells.

```nim
const flushBlockBytes = 1 shl 17
const unreachableDistance = 1000000000

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

var gridWidth = 0
var gridHeight = 0
var cellKinds: seq[int] = @[]
var firstTwo = 0
var secondTwo = 0
var firstThree = 0
var secondThree = 0
var blockedCells: uint64 = 0'u64
var lengthLimit = 0
var bestTotal = unreachableDistance

proc cellDistance(first: int, second: int): int =
  return abs(first div gridWidth - second div gridWidth) + abs(first mod gridWidth - second mod gridWidth)
```

A 64-bit mask fits all 81 cells.
Cell indices are row times width plus column.
The four marked cells are found while reading.

**Second-wire search.** Breadth-first search uses only cells still free after the first wire is placed.

```nim
proc shortestSecondPath(startCell: int, targetCell: int): int =
  var distances = newSeq[int](gridWidth * gridHeight)
  for index in 0 .. distances.high:
    distances[index] = -1
  var queue = newSeq[int](gridWidth * gridHeight)
  var queueHead = 0
  var queueTail = 0
  queue[queueTail] = startCell
  queueTail += 1
  distances[startCell] = 0
  while queueHead < queueTail:
    let current = queue[queueHead]
    queueHead += 1
    let row = current div gridWidth
    let column = current mod gridWidth
    for step in 0 .. 3:
      var nextRow = row
      var nextColumn = column
      if step == 0:
        nextRow -= 1
      elif step == 1:
        nextRow += 1
      elif step == 2:
        nextColumn -= 1
      else:
        nextColumn += 1
      if nextRow < 0 or nextRow >= gridHeight or nextColumn < 0 or nextColumn >= gridWidth:
        continue
      let nextCell = nextRow * gridWidth + nextColumn
      if cellKinds[nextCell] == 1:
        continue
      if cellKinds[nextCell] == 2:
        continue
      if (blockedCells and (1'u64 shl uint(nextCell))) != 0'u64:
        continue
      if distances[nextCell] >= 0:
        continue
      distances[nextCell] = distances[current] + 1
      if nextCell == targetCell:
        return distances[nextCell]
      queue[queueTail] = nextCell
      queueTail += 1
  return unreachableDistance
```

Obstacles, marked 2 cells, and used cells are skipped.
The queue visits each reachable cell once.
An unreachable target returns the sentinel value.

**First-wire growth and bound loop.** Depth first sets the mask, and the bound rises until a pair fits.

```nim
proc searchFirstPath(currentCell: int, walkedLength: int) =
  if bestTotal < unreachableDistance:
    return
  let remainingBound = cellDistance(currentCell, secondTwo) +
                       cellDistance(firstThree, secondThree)
  if walkedLength + remainingBound > lengthLimit:
    return
  if currentCell == secondTwo:
    let secondLength = shortestSecondPath(firstThree, secondThree)
    if secondLength < unreachableDistance and walkedLength + secondLength <= lengthLimit:
      bestTotal = walkedLength + secondLength
    return
  let row = currentCell div gridWidth
  let column = currentCell mod gridWidth
  for step in 0 .. 3:
    var nextRow = row
    var nextColumn = column
    if step == 0:
      nextRow -= 1
    elif step == 1:
      nextRow += 1
    elif step == 2:
      nextColumn -= 1
    else:
      nextColumn += 1
    if nextRow < 0 or nextRow >= gridHeight or nextColumn < 0 or nextColumn >= gridWidth:
      continue
    let nextCell = nextRow * gridWidth + nextColumn
    if cellKinds[nextCell] == 1 or cellKinds[nextCell] == 3:
      continue
    if (blockedCells and (1'u64 shl uint(nextCell))) != 0'u64:
      continue
    blockedCells = blockedCells or (1'u64 shl uint(nextCell))
    searchFirstPath(nextCell, walkedLength + 1)
    blockedCells = blockedCells and not (1'u64 shl uint(nextCell))

proc solveDataset(): int =
  let lowerBound = cellDistance(firstTwo, secondTwo) + cellDistance(firstThree, secondThree)
  let upperBound = 4 * gridWidth * gridHeight
  bestTotal = unreachableDistance
  for candidateLimit in lowerBound .. upperBound:
    lengthLimit = candidateLimit
    blockedCells = 1'u64 shl uint(firstTwo)
    searchFirstPath(firstTwo, 0)
    if bestTotal < unreachableDistance:
      return bestTotal
  return 0
```

The Manhattan bound prunes branches that cannot fit.
The mask is restored after each recursive branch.
The first accepted total ends the bound loop.

**Driver.** The reader solves datasets until the terminator and buffers answers.

```nim
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

while true:
  gridHeight = nextInt(inputData, scanPos)
  gridWidth = nextInt(inputData, scanPos)
  if gridHeight == 0 and gridWidth == 0:
    break
  if scanPos > inputData.len:
    break
  cellKinds = newSeq[int](gridWidth * gridHeight)
  var twoCount = 0
  var threeCount = 0
  for rowIndex in 0 .. gridHeight - 1:
    for columnIndex in 0 .. gridWidth - 1:
      let cellValue = nextInt(inputData, scanPos)
      let cellIndex = rowIndex * gridWidth + columnIndex
      cellKinds[cellIndex] = cellValue
      if cellValue == 2:
        if twoCount == 0:
          firstTwo = cellIndex
        else:
          secondTwo = cellIndex
        twoCount += 1
      elif cellValue == 3:
        if threeCount == 0:
          firstThree = cellIndex
        else:
          secondThree = cellIndex
        threeCount += 1
  if twoCount != 2 or threeCount != 2:
    appendOutput("0")
    outputBuffer.add '\n'
  else:
    appendOutput($(solveDataset()))
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

All input is read before solving starts.
Malformed marked counts produce a zero answer.
One buffered write emits every dataset result.

## Complexity

Each candidate bound enumerates first-wire paths and searches the remaining grid.

| phase | time | space |
|---|---|---|
| input read | one pass over all digits | one input string |
| first-wire search | one step per visited simple path | mask plus recursion depth |
| second-wire search | one breadth-first pass per completed first wire | two arrays of n·m integers |
| output | one buffered write | block buffer |

The first-wire search dominates on open grids.

| measure | Big O |
|---|---|
| time | exponential in the wire length in the worst case |
| space | O(n·m) |

A full pair enumeration would multiply two such path lists. The bound loop stops at the first feasible total.
