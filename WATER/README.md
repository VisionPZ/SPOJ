# WATER — Water among Cubes (SPOJ)

<https://www.spoj.com/problems/WATER/>

## Problem

Rain falls on a rectangular field of cuboids. Water collects above a field when every escape path to the field edge climbs higher than that field. Compute the total trapped volume in cubic inches.

Input starts with `t`, then `t` cases separated by a blank line. Each case starts with `n m`, followed by `n` lines of `m` heights in inches. Output one integer per case: the maximum water volume.

The statement and judge page give these bounds.

| Quantity | Bound |
| --- | --- |
| Test cases `t` | not specified |
| Rows `n` | 1 to 100 |
| Columns `m` | 1 to 100 |
| Field height | 1 to 10000 |
| Time limit | 7000 ms |
| Memory limit | 1536 MB |

The 100 by 100 grid caps each case at 10000 fields.

The sample input and output follow verbatim.

```
1
3 6
3 3 4 4 4 2
3 1 3 2 1 4
7 3 1 6 4 1
```

```
5
```

## Idea

Flood the grid from the outside, always expanding the field with the lowest wall first. Think of water seeping in through the lowest crack in a dam wall, then spreading inward.

The program seeds a min-heap with every edge cell at its own height. It pops the lowest barrier, then visits each neighbor. A neighbor's new wall is the larger of that barrier and its own height. Any excess becomes trapped water. Each field enters the heap once.

Trying every escape path per field takes exponential time. The heap visits each field once and spends logarithmic time per push and pop.

A lowest-first flood finds each field's best escape in one visit.

## Why It Works

Three facts prove the flood.

1. Water escapes along the path whose highest wall is smallest. A field holds water up to that wall, minus its own height. Edge fields hold none, because the outside starts at their height.
2. The heap pops fields in increasing barrier order. The first path reaching a field therefore uses the smallest possible wall for it.
3. Marking a field before pushing it keeps each field in the heap once. The water line is `max(barrier, neighborHeight)`, and the trapped depth is the line minus the height.

The table names the flood values.

| Term | Meaning |
| --- | --- |
| `heights` | cuboid height of each field |
| `heapLevel` | best escape wall for a queued field |
| `heapCell` | field index stored beside its wall |
| `barrier` | wall carried by the popped field |
| `waterTotal` | accumulated trapped volume |

The generator prints this trace for the sample.

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

The four interior depths are 2, 0, 1, and 2. They sum to the sample answer, 5.

## Code

**Input setup.** Compiler directives, constants, bulk input, and the scanner set up the run.

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

The read loop runs once per input line and fills one buffer. The scanner skips spaces and blank lines. Parsing walks the buffer once.

**Output buffer.** The output buffer flushes in blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The flush fires once per 256 KiB of answer text, not once per case. Output stays in one buffer until a block fills.

**Min-heap.** Flat arrays hold the heap without one object per field.

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

`heapPush` and `heapPop` keep the smallest wall at index zero. Each step follows one parent or child path, so both cost logarithmic time. Two flat arrays hold the heap entries.

**Neighbor relaxation.** Relaxing a neighbor adds water and continues the flood.

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

The mark happens before the push, so each field enters once. The depth is the wall minus the field height, and zero when the field stands higher. The sum stays in `waterTotal`.

**Flood driver.** The driver seeds the border and floods inward.

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

`i` walks the cases and `j` walks the fields. Two index tests find the border, and four neighbor calls skip positions outside the grid. Each case clears only the fields it uses.

**Final write.** The final write emits the remaining bytes.

```nim
stdout.write outputBuffer
outputBuffer.setLen 0
{.pop.}
```

One final write emits the bytes left under `flushBlockBytes`. Without it the last answer would stay in memory. The cost is one write.

## Complexity

The flood dominates each case, and the grid bounds its size.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | O(total input size) | one input string |
| Border seed | O(nm) | heap arrays |
| Flood | O(nm log(nm)) | one entry per field |
| Output | one flush per 256 KiB | one flush block |

The flat arrays hold at most 10000 entries.

The totals use the grid dimensions.

| Measure | Big O |
| --- | --- |
| Time | O(t · nm log(nm)) |
| Space | O(nm) |

Testing every escape path per field instead takes exponential time.
