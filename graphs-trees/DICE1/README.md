# DICE1 — Dice Contest (SPOJ)
<https://www.spoj.com/problems/DICE1/>

## Problem

The input describes a die with a cost on each face and a start and target square on a four-row strip.
Compute the minimum total cost of rolls from start to target, where each roll costs the new top face's number.

Read `t` test cases.
Each case gives six face costs, then a start square and a target square.
The die starts with its 1-dot face on top and its 2-dot face facing the player.
Rolling to a side-adjacent square costs the value on the new top face.
Print the minimal total cost.

The first line of a case holds costs `l1` through `l6` for the sides originally showing 1 to 6 dots.
The second line holds `x1 y1 x2 y2`, the start and target columns and rows.

The judge bounds follow.

| Item | Bound |
| --- | --- |
| Face costs `li` | 1 to 50 |
| Columns | -10^9 to 10^9 |
| Rows | 1 to 4 |
| Time limit | 2569 ms |
| Memory limit | 1536 MB |

The huge column range rules out a plain grid search.

The sample input and expected output follow verbatim.

```
1
1 2 8 3 1 4
-1 1 0 2
```

```
7
```

The sample die reaches its target for a total cost of 7.

## Idea

Use Dijkstra's algorithm (shortest paths with non-negative costs) on a repeating pattern, like a strip of squares whose layout repeats every few columns.
A state is a column offset, a row, and one of 24 orientations (which face is on top and front).
The strip is periodic, so distant columns repeat an earlier distance table plus a fixed cost delta.

Precompute the orientation transitions once.
Expand columns with a heap (a priority queue ordered by current cost).
When two completed columns match up to a constant offset, lock the period and jump to the target.

Expanding one column costs constant work: 48 states times four moves.
Visiting every column up to 10^9 is impossible.
Find the period once, then jump.

## Why It Works

Four facts prove the method.

1. A roll changes the top and front faces deterministically.
   There are 24 orientations for the ordered pair.
2. Moving left swaps the two side face costs, so one horizontal direction suffices after that swap.
3. Each column has 4 rows times 24 orientations, but only 48 slots are reachable from a given start.
4. When two completed columns have matching distance profiles up to a constant delta, the pattern repeats.
   The far answer is the base cost plus whole periods times delta.

The main tables and their roles follow.

| Term | Meaning |
| --- | --- |
| `orientationNext` | new orientation after one of the four moves |
| `orientationCostFace` | face whose cost a move pays |
| `columnOffset` | shift that keeps column indices non-negative |
| `periodDelta` | cost added by one full period |

The jump turns a billion columns into a few thousand.

A script runs an independent shortest-path search for the sample case and prints the chosen rolls.

```
face costs 1..6: 1 2 8 3 1 4
start (-1,1), target (0,2)
roll to (-2,1)  top=4  cost=3
roll to (-2,2)  top=2  cost=2
roll to (-1,2)  top=1  cost=1
roll to ( 0,2)  top=5  cost=1
total = 7
```

## Code

**Constants and die tables.**

```nim
const
  positionsCount = 6
  moveCount = 4
  orientationsCount = 24
  rowsCount = 4
  statesPerColumn = 96
  reachablePerColumn = 48
  columnOffset = 4
  maxColumns = 8192
  flushBlockBytes = 1 shl 18
  infinite = high(int) div 4

  serializeGrid: array[positionsCount, array[positionsCount, int]] = [
    [-1, 0, 1, 2, 3, -1],
    [4, -1, 5, 6, -1, 7],
    [8, 9, -1, -1, 10, 11],
    [12, 13, -1, -1, 14, 15],
    [16, -1, 17, 18, -1, 19],
    [-1, 20, 21, 22, 23, -1]
  ]

  topFaceGrid: array[positionsCount, array[positionsCount, int]] = [
    [-1, 0, 0, 0, 0, -1],
    [1, -1, 2, 3, -1, 4],
    [1, 3, -1, -1, 2, 4],
    [1, 2, -1, -1, 3, 4],
    [1, -1, 3, 2, -1, 4],
    [-1, 5, 5, 5, 5, -1]
  ]

  rotationGrid: array[moveCount, array[positionsCount, int]] = [
    [1, 5, 2, 3, 0, 4],
    [4, 0, 2, 3, 5, 1],
    [2, 1, 5, 0, 4, 3],
    [3, 1, 0, 5, 4, 2]
  ]
```

The tables encode face positions, top faces, and rotations for four moves. A die has 24 orientations, and four rows give 96 states per column. The offset keeps negative columns inside an array.

**Types and global state.**

```nim
type
  Column = object
    distances: array[statesPerColumn, int]
    remaining: int
    generation: int

  SearchNode = object
    distance: int
    columnIndex: int
    rowIndex: int
    orientation: int

var
  orientationNext: array[orientationsCount, array[moveCount, int]]
  orientationCostFace: array[orientationsCount, array[moveCount, int]]
  initialOrientation = 0
  faceCosts: array[positionsCount, int]
  searchHeap: seq[SearchNode] = @[]
  columnPool: array[maxColumns, Column]
  columnCount = 0
  caseGeneration = 0
  inputData = ""
  outputBuffer = ""
  i = 0
```

Column stores one distance per state plus a lazy generation tag. The heap holds the frontier of the search. One pool of columns is reused across test cases.

**Signed scanner.**

```nim
proc nextInt(input: string, i: var int): int =
  while i < input.len and (input[i] < '0' or input[i] > '9') and input[i] != '-':
    inc i
  var sign = 1
  if i < input.len and input[i] == '-':
    sign = -1
    inc i
  var value = 0
  while i < input.len and input[i] >= '0' and input[i] <= '9':
    value = value * 10 + (int(input[i]) - 48)
    inc i
  result = sign * value
```

The scanner accepts a leading minus sign. It needs no token allocation. The cost is one pass over the input digits.

**Heap operations.**

```nim
proc heapPush(node: SearchNode) =
  searchHeap.add(node)
  var j = searchHeap.len - 1
  while j > 0:
    let k = (j - 1) div 2
    if searchHeap[j].distance < searchHeap[k].distance:
      swap searchHeap[j], searchHeap[k]
      j = k
    else:
      break

proc heapPop(): SearchNode =
  result = searchHeap[0]
  let lastNode = searchHeap[searchHeap.len - 1]
  searchHeap.setLen(searchHeap.len - 1)
  if searchHeap.len > 0:
    searchHeap[0] = lastNode
    var k = 0
    while true:
      let i = k * 2 + 1
      if i >= searchHeap.len:
        break
      let j = i + 1
      var l = i
      if j < searchHeap.len and searchHeap[j].distance < searchHeap[i].distance:
        l = j
      if searchHeap[l].distance < searchHeap[k].distance:
        swap searchHeap[l], searchHeap[k]
        k = l
      else:
        break
```

heapPush sifts a new node upward. heapPop replaces the root with the last node and sifts downward. Both cost O(log n) in the heap size.

**Lazy column setup.**

```nim
proc ensureColumn(i: int) =
  let j = i + columnOffset
  if j + 1 > columnCount:
    columnCount = j + 1
  if columnPool[j].generation != caseGeneration:
    for k in 0..<statesPerColumn:
      columnPool[j].distances[k] = infinite
    columnPool[j].remaining = reachablePerColumn
    columnPool[j].generation = caseGeneration
```

ensureColumn grows the pool and resets a column when the generation changes. Distances start at infinity. The remaining counter records unreached states.

**Orientation preparation.**

```nim
proc initializeOrientations() =
  for i in 0..<positionsCount:
    for j in 0..<positionsCount:
      let code = serializeGrid[i][j]
      if code < 0:
        continue
      for k in 0..<moveCount:
        let newTopPosition = rotationGrid[k][i]
        let newFrontPosition = rotationGrid[k][j]
        orientationNext[code][k] = serializeGrid[newTopPosition][newFrontPosition]
        orientationCostFace[code][k] = topFaceGrid[newTopPosition][newFrontPosition]
  initialOrientation = serializeGrid[0][1]
```

initializeOrientations fills the transition tables once. It records the next orientation and the paid face for each move. The initial orientation puts face 1 on top.

**Search one case.**

```nim
proc solveCase() =
  for k in 0..<positionsCount:
    faceCosts[k] = nextInt(inputData, i)
  let startX = nextInt(inputData, i)
  var startRow = nextInt(inputData, i)
  let targetX = nextInt(inputData, i)
  var targetRow = nextInt(inputData, i)

  var horizontalDistance: int
  if targetX < startX:
    swap faceCosts[2], faceCosts[3]
    horizontalDistance = startX - targetX
  else:
    horizontalDistance = targetX - startX
  dec startRow
  dec targetRow

  searchHeap.setLen(0)
  columnCount = 0
  inc caseGeneration
  ensureColumn(0)
  searchHeap.add(SearchNode(distance: 0, columnIndex: 0, rowIndex: startRow, orientation: initialOrientation))

  var leftEdge = 0
  var rightEdge = 0
  var periodLength = -1
  var periodDelta = 0
  var pendingColumns = 0
  var answer = -1

  while searchHeap.len > 0:
    let node = heapPop()
    if node.columnIndex == horizontalDistance and node.rowIndex == targetRow:
      answer = node.distance
      break

    ensureColumn(node.columnIndex)
    let i = node.columnIndex + columnOffset
    let j = orientationsCount * node.rowIndex + node.orientation
    if columnPool[i].distances[j] != infinite:
      continue
    columnPool[i].distances[j] = node.distance
    dec columnPool[i].remaining

    if columnPool[i].remaining == 0:
      if periodLength < 0:
        for j in 0..<columnCount:
          if j == i or columnPool[j].remaining != 0:
            continue
          var delta = infinite
          var matches = true
          for l in 0..<statesPerColumn:
            let currentDistance = columnPool[i].distances[l]
            if currentDistance == infinite:
              continue
            let earlierDistance = columnPool[j].distances[l]
            if earlierDistance == infinite:
              matches = false
              break
            if delta == infinite:
              delta = currentDistance - earlierDistance
            elif currentDistance - earlierDistance != delta:
              matches = false
              break
          if matches and delta > 0:
            periodLength = abs(node.columnIndex - (j - columnOffset))
            leftEdge = min(node.columnIndex, j - columnOffset)
            rightEdge = max(node.columnIndex, j - columnOffset)
            periodDelta = delta
            for k in leftEdge..rightEdge:
              ensureColumn(k)
              if columnPool[k + columnOffset].remaining > 0:
                inc pendingColumns
            break
      elif node.columnIndex >= leftEdge and node.columnIndex <= rightEdge:
        dec pendingColumns

      if periodLength > 0 and pendingColumns == 0 and horizontalDistance >= leftEdge:
        let blocks = (horizontalDistance - leftEdge) div periodLength
        let offset = (horizontalDistance - leftEdge) mod periodLength
        let baseColumn = columnPool[leftEdge + offset + columnOffset]
        var baseCost = infinite
        for l in 0..<orientationsCount:
          baseCost = min(baseCost, baseColumn.distances[orientationsCount * targetRow + l])
        answer = baseCost + blocks * periodDelta
        break

    for k in 0..<moveCount:
      var newColumn = node.columnIndex
      var newRow = node.rowIndex
      case k
      of 0:
        if node.rowIndex == 0:
          continue
        dec newRow
      of 1:
        if node.rowIndex == rowsCount - 1:
          continue
        inc newRow
      of 2:
        if node.columnIndex <= -columnOffset:
          continue
        dec newColumn
      else:
        inc newColumn
      let newOrientation = orientationNext[node.orientation][k]
      let moveCost = faceCosts[orientationCostFace[node.orientation][k]]
      heapPush(SearchNode(distance: node.distance + moveCost, columnIndex: newColumn, rowIndex: newRow, orientation: newOrientation))
```

solveCase mirrors left travel by swapping two face costs. The search locks a period when two columns match up to a delta. The four move branches stay inside rows 1 to 4. The answer then jumps straight to the target column.

**Write the answer.**

```nim
  outputBuffer.add($answer)
  outputBuffer.add('\n')
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen(0)

```

One answer is appended to the output buffer. A full block is flushed immediately. No write happens per state.

**Input and driver.**

```nim
while not stdin.endOfFile():
  var line = ""
  if readLine(stdin, line):
    inputData.add(line)
    inputData.add('\n')

initializeOrientations()
let testCount = nextInt(inputData, i)
for j in 0..<testCount:
  solveCase()
stdout.write outputBuffer
```

The driver reads every input line into one buffer. Orientations are prepared once before all cases. One final write emits the remaining output bytes.

## Complexity

The phases and their costs follow.

| Phase | Time | Space |
| --- | --- | --- |
| Orientation setup | O(24 * 4) | constant |
| Column expansion before the period | O(48 * 4) per column | O(48) per column |
| Period jump | O(1) | constant |
| Output | O(t) | one output block |

Only a few thousand columns expand before the period appears.

The Big O summary follows.

| Measure | Big O |
| --- | --- |
| Time | O(columns expanded * 48) per case |
| Space | O(columns expanded * 48) |

A plain search over every column up to 10^9 cannot finish.
