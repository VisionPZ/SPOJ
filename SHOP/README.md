## Problem

Read many grids from one input stream. Each case starts with a width and a height, followed by one row of characters per line. A cell holds a shelf (`X`), the start (`S`), the destination (`D`), or a digit from 1 to 9. Print the least time to reach the destination, one answer per line. A case with width and height `0 0` ends the input. We write `O(n)` for work that grows linearly with n.

The statement and judge table give these bounds.

| item | bound |
|---|---|
| grid width | at most 25 |
| grid height | at most 25 |
| pass cost | 1 to 9 per digit cell |
| test cases | any count, ended by `0 0` |
| judge limit | 3000 ms, 1536 MB |

The small grid and the small digit range shape the algorithm.

## Idea

Treat every open cell as a node and every step as an edge, then settle cells in increasing cost with Dijkstra's algorithm. A bucket queue (one slot per distance) replaces the heap because costs are small integers. Cost per settled cell is one bucket pop plus four neighbour checks, while a heap pays a logarithm per push.

## Why It Works

Every step costs zero or more, so Dijkstra settles cells in nondecreasing distance. The first pop of the destination gives its final cost. A shortest path never repeats a cell, since each repeated step adds cost. The path uses at most 624 moves, so its cost stays below 624 * 9. `bucketTotal` gives every distance one slot.

The grid is stored row by row in one array.

| term | meaning |
|---|---|
| `rowStart + col` | flat index of a cell in the current row |
| `settledCell div width` | row of a settled cell |
| `settledCell mod width` | column of a settled cell |
| `currentDistance + stepCost` | candidate distance of a neighbour |
| `bucketTotal` | one slot for each possible distance |

These expressions turn a flat index back into a row and column.

The destination costs zero, so a neighbour can add it at the current distance. The inner loop reads the bucket head on each pass, so it also sees nodes added while that distance is processed. `resetBuckets` clears only the slots used by the previous case.

The first sample grid has twelve cells, numbered row by row.

| cell | index (row, col) | content |
|---|---|---|
| 0 | (0, 0) | X |
| 1 | (0, 1) | 1 |
| 2 | (0, 2) | S |
| 3 | (0, 3) | 3 |
| 4 | (1, 0) | 4 |
| 5 | (1, 1) | 2 |
| 6 | (1, 2) | X |
| 7 | (1, 3) | 4 |
| 8 | (2, 0) | X |
| 9 | (2, 1) | 1 |
| 10 | (2, 2) | D |
| 11 | (2, 3) | 2 |

The start is cell 2 and the destination is cell 10.

These cells settle in this order.

| distance settled | cell index | content |
|---|---|---|
| 0 | 2 | S |
| 1 | 1 | 1 |
| 3 | 3 | 3 |
| 3 | 5 | 2 |
| 4 | 9 | 1 |
| 4 | 10 | D |

Cell 10 settles at distance 4, which matches the sample output.

## Code

**Input and constants.**

```nim
import sequtils

const flushBlockBytes = 1 shl 18
const firstDigitValue = 48
const maxGridCells = 25 * 25
const maxStepCost = 9
const bucketTotal = maxGridCells * maxStepCost + 2
const nodeCapacity = maxGridCells * 4 + 32
const unreachableCost = 1000000000

var inputData: string
var inputLine: string
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc skipWhitespace() =
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos = scanPos + 1

proc readInteger(): int =
  skipWhitespace()
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + (int(inputData[scanPos]) - firstDigitValue)
    scanPos = scanPos + 1
  return value
```

`inputData` holds the whole input, and `scanPos` walks it by index. The read loop ends when `readLine` returns false. `readInteger` skips blank lines between cases and costs one pass over the digits.

**Shared arrays and enqueue.**

```nim
var gridCells: seq[char]
var distanceValue: seq[int]
var bucketHead = repeat(-1, bucketTotal)
var bucketVertex = newSeq[int](nodeCapacity)
var bucketNext = newSeq[int](nodeCapacity)
var touchedBuckets: seq[int]
var nodeTotal = 0

proc enqueueNode(distanceIndex: int, cellIndex: int) =
  if distanceIndex >= bucketTotal or nodeTotal >= nodeCapacity:
    return
  if bucketHead[distanceIndex] == -1:
    touchedBuckets.add distanceIndex
  bucketNext[nodeTotal] = bucketHead[distanceIndex]
  bucketHead[distanceIndex] = nodeTotal
  bucketVertex[nodeTotal] = cellIndex
  nodeTotal = nodeTotal + 1

proc resetBuckets() =
  for distanceIndex in touchedBuckets:
    bucketHead[distanceIndex] = -1
  touchedBuckets.setLen 0

proc tryRelax(neighborCell: int, currentDistance: int) =
  let cellChar = gridCells[neighborCell]
  if cellChar == 'X':
    return
  var stepCost = 0
  if cellChar >= '1' and cellChar <= '9':
    stepCost = int(cellChar) - firstDigitValue
  let candidateDistance = currentDistance + stepCost
  if candidateDistance < distanceValue[neighborCell]:
    distanceValue[neighborCell] = candidateDistance
    enqueueNode(candidateDistance, neighborCell)
```

`bucketHead` starts at -1 for every distance. `enqueueNode` links a cell into its distance slot and records the slot in `touchedBuckets`. `resetBuckets` clears only those slots, so stale links never survive a case. Cost: constant time per enqueue.

**One search.**

```nim
proc shortestPathCost(width: int, height: int, startCell: int, targetCell: int): int =
  let cellCount = width * height
  distanceValue.setLen(cellCount)
  for cellIndex in 0 .. cellCount - 1:
    distanceValue[cellIndex] = unreachableCost
  nodeTotal = 0
  resetBuckets()
  distanceValue[startCell] = 0
  enqueueNode(0, startCell)
  var currentDistance = 0
  while true:
    while true:
      let nodeIndex = bucketHead[currentDistance]
      if nodeIndex < 0:
        break
      bucketHead[currentDistance] = bucketNext[nodeIndex]
      let settledCell = bucketVertex[nodeIndex]
      if distanceValue[settledCell] != currentDistance:
        continue
      if settledCell == targetCell:
        return currentDistance
      let row = settledCell div width
      let col = settledCell mod width
      if row > 0:
        tryRelax(settledCell - width, currentDistance)
      if row < height - 1:
        tryRelax(settledCell + width, currentDistance)
      if col > 0:
        tryRelax(settledCell - 1, currentDistance)
      if col < width - 1:
        tryRelax(settledCell + 1, currentDistance)
    currentDistance = currentDistance + 1
    while currentDistance < bucketTotal and bucketHead[currentDistance] == -1:
      currentDistance = currentDistance + 1
    if currentDistance >= bucketTotal:
      return unreachableCost
```

The inner loop pops from the bucket head on each pass. This trap avoids losing cells added at the current distance, which happens when the destination is reached. The distance loop runs at most `bucketTotal` times. Cost: one pop and four neighbour checks per settled cell.

**Main loop.**

```nim
var outputBuffer: string
var width = readInteger()
var height = readInteger()
while width != 0 or height != 0:
  let cellCount = width * height
  gridCells.setLen(cellCount)
  var startCell = -1
  var targetCell = -1
  for row in 0 .. height - 1:
    let rowStart = row * width
    skipWhitespace()
    for col in 0 .. width - 1:
      let cellChar = inputData[scanPos]
      scanPos = scanPos + 1
      gridCells[rowStart + col] = cellChar
      if cellChar == 'S':
        startCell = rowStart + col
      if cellChar == 'D':
        targetCell = rowStart + col
  let answer = shortestPathCost(width, height, startCell, targetCell)
  outputBuffer.add $answer
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
  width = readInteger()
  height = readInteger()
stdout.write outputBuffer
```

The row loop runs `height` times and the column loop runs `width` times. `outputBuffer` flushes at `flushBlockBytes`, so answers never write one line at a time. Cost: one line per case.

## Complexity

Costs by phase:

| phase | time | space |
|---|---|---|
| input read | one pass over all bytes | input bytes |
| grid build | linear in cells | cells in the grid |
| each search | one pop and four checks per settled cell | fixed bucket array |
| output | one write per 256 KiB block | 256 KiB |

The search settles each cell at most once and relaxes at most four neighbours per settled cell.

Big O terms:

| measure | form |
|---|---|
| time | O(n) per grid, n = cell count |
| space | O(n) plus the fixed bucket array |

Each grid adds one answer line and no growing state.

A full scan of all cell pairs costs quadratic time per grid. A heap Dijkstra costs O(n) with a logarithmic factor per push. The bucket queue removes that factor because every cost is a small integer.
