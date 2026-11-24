## Problem

Read a grid of cuboid heights for each test case. Water gathers above a field when every path to the grid edge rises higher than that field. Print the total water volume for each case. A blank line separates the cases.

The statement and judge page give these bounds.

| Quantity | Bound |
| --- | --- |
| Test cases t | not specified |
| Rows n | 1 ≤ n ≤ 100 |
| Columns m | 1 ≤ m ≤ 100 |
| Field height | 1 ≤ h ≤ 10000 |
| Time limit | 7000 ms |
| Memory limit | 1536 MB |

The 100 × 100 grid caps the work at 10000 fields per case.

## Idea

Grow a flood from the grid edge with a min-heap, a queue that always returns the lowest stored level. The edge cells start in the heap at their own heights. Popping the lowest cell gives the best wall seen along a path from the edge. Each new neighbor takes that wall or its own height, whichever is larger.

Trying every path to the edge is exponential. The heap visits each field once and spends logarithmic time per heap step.

Cost per field: O(log 10000) heap work. Cost per case: O(nm log(nm)) time and O(nm) space.

## Why It Works

Water escapes along the path with the lowest highest wall. A field holds water up to that wall, minus its own height. Edge fields hold none because the outside starts at their height.

The heap pops fields in increasing wall order. The first path that reaches a field therefore uses the smallest possible wall for that field.

`waterLine = if barrier > neighborHeight: barrier else: neighborHeight` sets the new wall. `waterTotal += int64(waterLine - neighborHeight)` adds the water above that field. `heapPush(waterLine, neighbor)` lets the flood continue.

The generator prints this trace for the sample:

```
water line:
3 3 4 4 4 2
3 3 3 3 3 4
7 3 1 6 4 1
depth:
0 0 0 0 0 0
0 2 0 1 2 0
0 0 0 0 0 0
total 5
```

The four interior depths are 2, 0, 1 and 2. They add to the sample answer, 5.

## Code

```nim
{.passC: "-O2".}
{.push checks: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxCellCount = 10000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, scanPos: var int): int =
  while scanPos < data.len and (data[scanPos] < '0' or data[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < data.len and data[scanPos] >= '0' and data[scanPos] <= '9':
    value = value * 10 + int(data[scanPos]) - firstDigitValue
    scanPos += 1
  return value
```

The read loop runs once per input line and fills one buffer. The scanner skips spaces and blank lines, so the empty line between cases needs no branch. Parsing walks the buffer once.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The flush fires once per 256 KiB of answer text, not once per case. Output stays in one buffer until a block fills. The cost is one write per full block.

```nim
var heights: array[0..maxCellCount, int]
var visited: array[0..maxCellCount, bool]
var heapLevel: array[0..maxCellCount, int]
var heapCell: array[0..maxCellCount, int]
var heapSize = 0
var poppedLevel = 0
var poppedCell = 0
var waterTotal: int64 = 0
var rowCount = 0
var colCount = 0

proc heapPush(level, cell: int) =
  var child = heapSize
  heapSize += 1
  while child > 0:
    let parent = (child - 1) div 2
    if heapLevel[parent] <= level: break
    heapLevel[child] = heapLevel[parent]
    heapCell[child] = heapCell[parent]
    child = parent
  heapLevel[child] = level
  heapCell[child] = cell

proc heapPop() =
  let topLevel = heapLevel[0]
  let topCell = heapCell[0]
  heapSize -= 1
  if heapSize > 0:
    let lastLevel = heapLevel[heapSize]
    let lastCell = heapCell[heapSize]
    var parent = 0
    while true:
      let leftChild = parent * 2 + 1
      if leftChild >= heapSize: break
      var smallerChild = leftChild
      let rightChild = leftChild + 1
      if rightChild < heapSize and heapLevel[rightChild] < heapLevel[leftChild]:
        smallerChild = rightChild
      if heapLevel[smallerChild] >= lastLevel: break
      heapLevel[parent] = heapLevel[smallerChild]
      heapCell[parent] = heapCell[smallerChild]
      parent = smallerChild
    heapLevel[parent] = lastLevel
    heapCell[parent] = lastCell
  poppedLevel = topLevel
  poppedCell = topCell
```

`heapPush` and `heapPop` keep the smallest wall at index zero. Each step moves one entry along a single parent or child path, so both cost logarithmic time. Two flat arrays hold the heap without a node object per field.

```nim
proc relaxNeighbor(neighbor: int, barrier: int) =
  if visited[neighbor]: return
  visited[neighbor] = true
  let neighborHeight = heights[neighbor]
  let waterLine = if barrier > neighborHeight: barrier else: neighborHeight
  if waterLine > neighborHeight:
    waterTotal += int64(waterLine - neighborHeight)
  heapPush(waterLine, neighbor)
```

`relaxNeighbor` marks a field before pushing it, so each field enters the heap once. The depth is the wall minus the field height, and zero when the field stands higher. The sum stays in `waterTotal`.

```nim
let caseCount = nextInt(inputData, scanPos)
for i in 0..<caseCount:
  rowCount = nextInt(inputData, scanPos)
  colCount = nextInt(inputData, scanPos)
  let cellCount = rowCount * colCount
  for j in 0..<cellCount:
    heights[j] = nextInt(inputData, scanPos)
    visited[j] = false
  heapSize = 0
  waterTotal = 0
  for j in 0..<cellCount:
    let rowIndex = j div colCount
    let colIndex = j mod colCount
    if rowIndex == 0 or rowIndex == rowCount - 1 or colIndex == 0 or colIndex == colCount - 1:
      visited[j] = true
      heapPush(heights[j], j)
  while heapSize > 0:
    heapPop()
    let cell = poppedCell
    let barrier = poppedLevel
    let rowIndex = cell div colCount
    let colIndex = cell mod colCount
    if rowIndex > 0: relaxNeighbor(cell - colCount, barrier)
    if rowIndex + 1 < rowCount: relaxNeighbor(cell + colCount, barrier)
    if colIndex > 0: relaxNeighbor(cell - 1, barrier)
    if colIndex + 1 < colCount: relaxNeighbor(cell + 1, barrier)
  appendOutput($(waterTotal))
  outputBuffer.add '\n'
```

`i` walks the cases and `j` walks the fields. The `rowIndex` and `colIndex` tests find the edge, and the four neighbor calls skip positions outside the grid. Each case clears only the fields it uses.

```nim
stdout.write outputBuffer
outputBuffer.setLen 0
{.pop.}
```

One final write emits the bytes left under `flushBlockBytes`. Without it the last answer would stay in memory. The cost is one write.

## Complexity

Reading and parsing cost O(total input size). Each case pushes and pops at most nm fields, so the flood costs O(nm log(nm)) time. The flat arrays hold one entry per field, so space is O(nm).

Total time is O(t · nm log(nm)) and total space is O(nm). Testing every path to the edge instead costs exponential time.
