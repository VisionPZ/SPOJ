# MCLEAN — Cleaning Robot (SPOJ)

<https://www.spoj.com/problems/MCLEAN/>

## Problem

A robot moves one tile at a time on a gridded floor and cleans every dirty tile it visits. Find the fewest moves that clean all dirty tiles, or report that the task is impossible.

The input holds maps until a line with two zeros. Each map gives width and height, then one row of tile symbols per line. Symbols are `.` for clean, `*` for dirty, `x` for furniture, and `o` for the robot.

| item | bound |
|---|---|
| width and height | at most 20 |
| dirty tiles per map | at most 10 |
| robot | exactly one per map |
| judge limit | 1000 ms, 1536 MB |

The dirty-tile count drives the design, since it stays at most ten.

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

Turn the floor into a small graph, then take the shortest tour through the dirty tiles. This is a travelling-salesman sweep over at most ten targets.

Breadth-first search from the robot and from each dirty tile gives every leg length. Bitmask dynamic programming then chooses the visit order, like a delivery driver picking the next stop.

Enumerating all visit orders costs factorial time, while the bitmask table grows only with 2^10 states.

## Why It Works

1. Breadth-first search gives the move count between any two reachable tiles.
2. A dirty tile unreachable from the robot makes the whole map impossible.
3. Cleaning does not change tile costs, so every leg is independent.
4. A bitmask records which dirty tiles are already clean, and the last tile fixes the current position.
5. Relaxing one next target per state finds the shortest tour by dynamic programming.

| term | meaning |
|---|---|
| `fillDistances` | breadth-first leg lengths from one point of interest |
| `dirtyCells` | grid positions of the dirty tiles |
| `bestCosts` | shortest cost for each visited mask and last tile |
| `fullMask` | mask with every dirty tile marked clean |

The term table names the values that carry the graph and the tour.

A worked example from the generator uses the first sample map:

```
robot (1,1); dirty (5,1), (1,3), (5,3)
robot legs: 4, 2, 6 moves
dirty legs: (5,1) to (5,3) is 2, (1,3) to (5,3) is 4
tour via (5,1) first: 4 + 2 + 4 = 10
tour via (1,3) then (5,3): 2 + 4 + 2 = 8
```

The second tour wins, matching the sample answer of eight moves.

## Code

**Input and scanning.** One pass loads all maps, and two hand readers parse numbers and tile symbols.

```nim
const flushBlockBytes = 1 shl 17
const impassableCell = 'x'
const robotCell = 'o'
const dirtyCell = '*'
const unreachableCost = 1000000000

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

proc nextCell(data: string, pos: var int): char =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  result = data[pos]
  pos += 1
```

The grid symbol reader skips whitespace between rows.
The integer reader handles the map headers and terminator.
Both readers advance one shared scan position.

**Buffered output.** Answers collect in one string and flush in large blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer writes to the stream only when it grows large.
One final write drains any remaining bytes.

**Distance sweep.** A queue-based breadth-first pass measures one point of interest.

```nim
proc fillDistances(grid: seq[char], gridWidth: int, gridHeight: int, startCell: int): seq[int] =
  let cellCount = grid.len
  result = newSeq[int](cellCount)
  for cellIndex in 0 .. cellCount - 1:
    result[cellIndex] = -1
  var queue = newSeq[int](cellCount)
  var queueHead = 0
  var queueTail = 0
  result[startCell] = 0
  queue[queueTail] = startCell
  queueTail = queueTail + 1
  while queueHead < queueTail:
    let currentCell = queue[queueHead]
    queueHead = queueHead + 1
    let currentX = currentCell mod gridWidth
    let currentY = currentCell div gridWidth
    let currentDistance = result[currentCell] + 1
    if currentX > 0:
      let neighbour = currentCell - 1
      if grid[neighbour] != impassableCell and result[neighbour] == -1:
        result[neighbour] = currentDistance
        queue[queueTail] = neighbour
        queueTail = queueTail + 1
    if currentX + 1 < gridWidth:
      let neighbour = currentCell + 1
      if grid[neighbour] != impassableCell and result[neighbour] == -1:
        result[neighbour] = currentDistance
        queue[queueTail] = neighbour
        queueTail = queueTail + 1
    if currentY > 0:
      let neighbour = currentCell - gridWidth
      if grid[neighbour] != impassableCell and result[neighbour] == -1:
        result[neighbour] = currentDistance
        queue[queueTail] = neighbour
        queueTail = queueTail + 1
    if currentY + 1 < gridHeight:
      let neighbour = currentCell + gridWidth
      if grid[neighbour] != impassableCell and result[neighbour] == -1:
        result[neighbour] = currentDistance
        queue[queueTail] = neighbour
        queueTail = queueTail + 1
```

Unvisited cells start at minus one.
Furniture is never enqueued, so blocked tiles stay unreachable.
The queue holds each cell at most once.

**Map setup.** Each map finds the points of interest and checks reachability.

```nim
while true:
  let gridWidth = nextInt(inputData, scanPos)
  let gridHeight = nextInt(inputData, scanPos)
  if gridWidth == 0 and gridHeight == 0:
    break
  let cellCount = gridWidth * gridHeight
  var grid = newSeq[char](cellCount)
  var robotPosition = 0
  var dirtyCells = newSeq[int](0)
  for rowIndex in 0 .. gridHeight - 1:
    for columnIndex in 0 .. gridWidth - 1:
      let cellIndex = rowIndex * gridWidth + columnIndex
      let cellSymbol = nextCell(inputData, scanPos)
      grid[cellIndex] = cellSymbol
      if cellSymbol == robotCell:
        robotPosition = cellIndex
      elif cellSymbol == dirtyCell:
        dirtyCells.add cellIndex
  let dirtyCount = dirtyCells.len
  let pointCount = dirtyCount + 1
  var distances = newSeq[seq[int]](pointCount)
  distances[0] = fillDistances(grid, gridWidth, gridHeight, robotPosition)
  for dirtyIndex in 0 .. dirtyCount - 1:
    distances[dirtyIndex + 1] = fillDistances(grid, gridWidth, gridHeight, dirtyCells[dirtyIndex])
  var unreachable = false
  for dirtyIndex in 0 .. dirtyCount - 1:
    if distances[0][dirtyCells[dirtyIndex]] < 0:
      unreachable = true
  if unreachable:
    appendOutput("-1")
    outputBuffer.add '\n'
    continue
```

A zero-width map ends the input, and an empty dirty list needs no tour.
One breadth-first pass starts at the robot, and one starts at each dirty tile.
An unreachable dirty tile ends this map with a single `-1`.

**Tour table.** Bitmask states relax one next target at a time.

```nim
  let stateLimit = dirtyCount + 1
  let stateCount = (1 shl dirtyCount) * stateLimit
  var bestCosts = newSeq[int](stateCount)
  for stateIndex in 0 .. stateCount - 1:
    bestCosts[stateIndex] = unreachableCost
  bestCosts[dirtyCount] = 0
  let fullMask = (1 shl dirtyCount) - 1
  for mask in 0 .. fullMask:
    for lastPoint in 0 .. dirtyCount:
      let currentCost = bestCosts[mask * stateLimit + lastPoint]
      if currentCost >= unreachableCost:
        continue
      var sourcePoint = lastPoint + 1
      if lastPoint == dirtyCount:
        sourcePoint = 0
      for nextDirty in 0 .. dirtyCount - 1:
        if (mask and (1 shl nextDirty)) != 0:
          continue
        let stepDistance = distances[sourcePoint][dirtyCells[nextDirty]]
        if stepDistance < 0:
          continue
        let nextMask = mask or (1 shl nextDirty)
        let nextCost = currentCost + stepDistance
        let nextState = nextMask * stateLimit + nextDirty
        if nextCost < bestCosts[nextState]:
          bestCosts[nextState] = nextCost
  var minimumMoves = unreachableCost
  if dirtyCount == 0:
    minimumMoves = 0
  for lastPoint in 0 .. dirtyCount - 1:
    let candidate = bestCosts[fullMask * stateLimit + lastPoint]
    if candidate < minimumMoves:
      minimumMoves = candidate
  if minimumMoves >= unreachableCost:
    appendOutput("-1")
  else:
    appendOutput($minimumMoves)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The sentinel last point stands for the robot's starting tile.
Each transition adds one leg and marks one more dirty tile clean.
The smallest complete state is the answer, printed once per map.

## Complexity

Breadth-first passes and tour states both stay small.

| phase | time | space |
|---|---|---|
| input read | one pass over map symbols | input string |
| distance passes | at most 11 searches over 400 cells | distance table |
| tour table | 2^10 masks times 10 targets | state array |
| output | one block flush per 128 KiB | output buffer |

The phase table shows that the ten-dirty-tile limit controls the tour work.

| measure | Big O |
|---|---|
| time | O(d * w * h + 2^d * d^2) per map |
| space | O(d * w * h + 2^d * d) |

Listing visit orders costs O(d!) per map, while the bitmask table shares subproblems and stays small.
