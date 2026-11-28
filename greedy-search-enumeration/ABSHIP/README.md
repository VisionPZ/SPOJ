# ABSHIP — Advanced Battleships (SPOJ)

<https://www.spoj.com/problems/ABSHIP/>

## Problem

A random square is placed on a grid where ships are connected groups of marked cells. Report the average number of distinct ships touched by that square, rounded to six decimal places.

Input starts with `rowCount`, `columnCount`, and `squareSize`. The next `rowCount` lines hold grid characters, with X for a ship cell and a dot for empty space. Output one decimal number with exactly six digits after the point.

The bounds from the statement:

| Item | Bound |
|---|---|
| Rows M | 1 to 500 |
| Columns N | 1 to 500 |
| Square side S | 1 to min(M, N) |
| Judge limit | 4000 ms, 1536 MB |

Ships can be large and oddly shaped, so the count must be done per ship rather than per cell.

The sample input:

```
5 5 2
XXXX.
X..X.
X..X.
X....
.XX..
```

The sample output:

```
0.875000
```

Fourteen ship hits across sixteen squares give the sample average.

## Idea

One ship is caught by a square that touches any of its cells. This is like a net catching a tangled rope at any point.

The algorithm first labels connected ship cells with a flood fill. For one ship, each cell maps to a rectangle of legal square positions. The hit count is the union area of those rectangles. A sweep line over square top rows maintains covered columns with a lazy segment tree that tracks minimum coverage. Each cell adds two events, and each sweep row costs one root query. Checking every square and its cells would repeat work heavily for large ships. The takeaway is to count square positions per ship and sweep their union once.

## Why It Works

1. Two cells belong to one ship exactly when a path of side-adjacent X cells joins them.
2. A square with top-left position (r, c) contains cell (i, j) when r runs from i - S + 1 to i. The column c runs from j - S + 1 to j, clipped to legal positions.
3. Those row and column ranges form one rectangle of square positions for each ship cell.
4. A square hits a ship when it lies in at least one of the ship's rectangles, so the hit count is their union area.
5. Sweeping top rows and adding or removing column intervals at event rows keeps the covered column count current.
6. A segment tree with coverage minimums reports the number of columns with positive coverage in constant time at its root.
7. Summing union areas over ships and dividing by the square count gives the expected number.

The main terms:

| Term | Meaning |
|---|---|
| `componentOf` | ship label assigned to each X cell |
| `firstInComponent` | head of the cell list for one ship |
| `treeMinimum` | smallest coverage in a segment tree node |
| `shipTotal` | total squares that hit any ship |

The table shows that the flood fill supplies the ship lists and the tree supplies union areas.

The generator trace for the sample uses these visible values:

```
ship one:  9 connected cells, 11 square positions hit
ship two:  2 connected cells,  3 square positions hit
hits:      11 + 3 = 14
squares:   (5-2+1) * (5-2+1) = 4 * 4 = 16
14 / 16 = 0.875000
```

The trace matches the sample output.

## Code

**Input and scanning.** The reader loads the header and every grid character.

```nim
const flushBlockBytes = 1 shl 17
const decimalPlaces = 1000000
const absentCell = -1

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
let squareSize = nextInt(inputData, scanPos)
let cellCount = rowCount * columnCount
while scanPos < inputData.len and inputData[scanPos] <= ' ':
  scanPos += 1

var grid = newSeq[char](cellCount)
for rowIndex in 0 .. rowCount - 1:
  for columnIndex in 0 .. columnCount - 1:
    grid[rowIndex * columnCount + columnIndex] = inputData[scanPos]
    scanPos += 1
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
```

Grid lines enter one input string before parsing.
Each row is read character by character from that string.
Line endings are skipped between rows.

**Flood fill.** An iterative stack labels each ship and links its cells into a list.

```nim
var componentOf = newSeq[int](cellCount)
var firstInComponent = newSeq[int](cellCount)
var nextInComponent = newSeq[int](cellCount)
var stackCells = newSeq[int](cellCount)
for index in 0 .. cellCount - 1:
  componentOf[index] = absentCell
  firstInComponent[index] = absentCell

proc pushNeighbor(neighborRow: int, neighborColumn: int, componentIndex: int, stackCells: var seq[int], stackSize: var int) =
  if neighborRow < 0 or neighborRow >= rowCount:
    return
  if neighborColumn < 0 or neighborColumn >= columnCount:
    return
  let neighbor = neighborRow * columnCount + neighborColumn
  if grid[neighbor] == 'X' and componentOf[neighbor] == absentCell:
    componentOf[neighbor] = componentIndex
    stackCells[stackSize] = neighbor
    stackSize += 1

var componentCount = 0
for cellIndex in 0 .. cellCount - 1:
  if grid[cellIndex] != 'X' or componentOf[cellIndex] != absentCell:
    continue
  let componentIndex = componentCount
  componentCount += 1
  componentOf[cellIndex] = componentIndex
  var stackSize = 1
  stackCells[0] = cellIndex
  while stackSize > 0:
    stackSize -= 1
    let cell = stackCells[stackSize]
    nextInComponent[cell] = firstInComponent[componentIndex]
    firstInComponent[componentIndex] = cell
    let rowIndex = cell div columnCount
    let columnIndex = cell mod columnCount
    pushNeighbor(rowIndex - 1, columnIndex, componentIndex, stackCells, stackSize)
    pushNeighbor(rowIndex + 1, columnIndex, componentIndex, stackCells, stackSize)
    pushNeighbor(rowIndex, columnIndex - 1, componentIndex, stackCells, stackSize)
    pushNeighbor(rowIndex, columnIndex + 1, componentIndex, stackCells, stackSize)
```

The stack is iterative, so no recursion depth limit applies.
Each X cell enters exactly one ship list.
The single-cell square case skips the tree entirely.

**Coverage tree.** The segment tree tracks how many active cells cover each square column.

```nim
  let treeSize = 4 * topColumns + 4
  var treeMinimum = newSeq[int](treeSize)
  var treeMinimumCount = newSeq[int](treeSize)
  var treeLazy = newSeq[int](treeSize)
  var segmentLength = newSeq[int](treeSize)

  proc buildSegments(node: int, left: int, right: int) =
    segmentLength[node] = right - left + 1
    treeMinimumCount[node] = segmentLength[node]
    if left < right:
      let middle = (left + right) div 2
      buildSegments(node * 2, left, middle)
      buildSegments(node * 2 + 1, middle + 1, right)

  buildSegments(1, 0, topColumns - 1)

  var visitStamp = newSeq[int](treeSize)
  var touchedNodes = newSeq[int](treeSize)
  var touchedCount = 0
  var eventStamp = newSeq[int](topRows + 1)
  var eventHead = newSeq[int](topRows + 1)
  var eventNext = newSeq[int](cellCount * 2 + 2)
  var eventLeft = newSeq[int](cellCount * 2 + 2)
  var eventRight = newSeq[int](cellCount * 2 + 2)
  var eventDelta = newSeq[int](cellCount * 2 + 2)
  var eventCount = 0

  proc markNode(node: int, stamp: int) =
    if visitStamp[node] != stamp:
      visitStamp[node] = stamp
      touchedNodes[touchedCount] = node
      touchedCount += 1
      treeMinimum[node] = 0
      treeMinimumCount[node] = segmentLength[node]
      treeLazy[node] = 0

  proc pushDown(node: int, stamp: int) =
    if treeLazy[node] != 0:
      let leftNode = node * 2
      let rightNode = node * 2 + 1
      markNode(leftNode, stamp)
      markNode(rightNode, stamp)
      treeMinimum[leftNode] += treeLazy[node]
      treeMinimum[rightNode] += treeLazy[node]
      treeLazy[leftNode] += treeLazy[node]
      treeLazy[rightNode] += treeLazy[node]
      treeLazy[node] = 0

  proc rangeAdd(node: int, left: int, right: int, queryLeft: int, queryRight: int, delta: int, stamp: int) =
    markNode(node, stamp)
    if queryLeft <= left and right <= queryRight:
      treeMinimum[node] += delta
      treeLazy[node] += delta
      return
    pushDown(node, stamp)
    let middle = (left + right) div 2
    let leftNode = node * 2
    let rightNode = node * 2 + 1
    if queryLeft <= middle:
      rangeAdd(leftNode, left, middle, queryLeft, queryRight, delta, stamp)
    if queryRight > middle:
      rangeAdd(rightNode, middle + 1, right, queryLeft, queryRight, delta, stamp)
    markNode(leftNode, stamp)
    markNode(rightNode, stamp)
    if treeMinimum[leftNode] < treeMinimum[rightNode]:
      treeMinimum[node] = treeMinimum[leftNode]
      treeMinimumCount[node] = treeMinimumCount[leftNode]
    elif treeMinimum[leftNode] > treeMinimum[rightNode]:
      treeMinimum[node] = treeMinimum[rightNode]
      treeMinimumCount[node] = treeMinimumCount[rightNode]
    else:
      treeMinimum[node] = treeMinimum[leftNode]
      treeMinimumCount[node] = treeMinimumCount[leftNode] + treeMinimumCount[rightNode]
```

Stamps reset tree nodes lazily for each ship.
Marking both children before a merge avoids stale values.
The root reports all covered columns with one lookup.

**Sweep and output.** Events add and remove cell intervals as the top row advances.

```nim
  proc addEvent(eventRow: int, leftBound: int, rightBound: int, eventChange: int, stamp: int) =
    if eventStamp[eventRow] != stamp:
      eventStamp[eventRow] = stamp
      eventHead[eventRow] = absentCell
    eventNext[eventCount] = eventHead[eventRow]
    eventLeft[eventCount] = leftBound
    eventRight[eventCount] = rightBound
    eventDelta[eventCount] = eventChange
    eventHead[eventRow] = eventCount
    eventCount += 1

  for componentIndex in 0 .. componentCount - 1:
    let stamp = componentIndex + 1
    eventCount = 0
    touchedCount = 0
    markNode(1, stamp)
    var cell = firstInComponent[componentIndex]
    while cell != absentCell:
      let rowIndex = cell div columnCount
      let columnIndex = cell mod columnCount
      let firstRow = max(0, rowIndex - squareSize + 1)
      let lastRow = min(rowIndex, topRows - 1)
      let firstColumn = max(0, columnIndex - squareSize + 1)
      let lastColumn = min(columnIndex, topColumns - 1)
      addEvent(firstRow, firstColumn, lastColumn, 1, stamp)
      addEvent(lastRow + 1, firstColumn, lastColumn, -1, stamp)
      cell = nextInComponent[cell]
    for topRow in 0 .. topRows - 1:
      var eventIndex = eventHead[topRow]
      if eventStamp[topRow] == stamp:
        while eventIndex != absentCell:
          rangeAdd(1, 0, topColumns - 1, eventLeft[eventIndex], eventRight[eventIndex], eventDelta[eventIndex], stamp)
          eventIndex = eventNext[eventIndex]
      let coveredColumns = if treeMinimum[1] > 0: segmentLength[1] else: segmentLength[1] - treeMinimumCount[1]
      shipTotal = shipTotal + int64(coveredColumns)

let squareCount = int64(rowCount - squareSize + 1) * int64(columnCount - squareSize + 1)
var wholePart = shipTotal div squareCount
let remainder = shipTotal mod squareCount
var fractionalPart = (2 * remainder * int64(decimalPlaces) + squareCount) div (2 * squareCount)
if fractionalPart >= int64(decimalPlaces):
  fractionalPart = 0
  wholePart += 1

appendOutput($wholePart)
appendOutput(".")
var digitDivisor = decimalPlaces div 10
while digitDivisor > 0:
  appendOutput($(fractionalPart div int64(digitDivisor) mod 10))
  digitDivisor = digitDivisor div 10
appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

Each cell contributes one start event and one end event.
The root is reset before each ship to clear old coverage.
Integer rounding avoids floating-point drift in the answer.

## Complexity

Flood fill and event creation are linear in the grid, and each sweep row costs a tree query.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over MN characters | input string |
| Flood fill | one visit per grid cell | label and list arrays |
| Sweep tree | two events per ship cell plus one query per row | segment tree arrays |
| Output | six digits and one line | block buffer |

The table shows that the event count matches the number of ship cells.

| Measure | Big O |
|---|---|
| Time | O(MN log N) |
| Space | O(MN) |

Scanning every square and every cell inside it costs O(S squared MN) in the worst case. Union areas per ship reduce that to one logarithmic update per cell.
