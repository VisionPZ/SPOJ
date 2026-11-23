## Problem

Read T town descriptions. Each town is a P by Q grid of terrain heights. Two base stations sit at given cells.

The technician walks between adjacent cells. Each step climbs at most one metre or descends at most three metres. After each step, at least one base station must be visible.

Print the shortest path length, or the failure sentence when no path exists.

The bounds are:

| Item | Bound |
| --- | --- |
| Test cases T | about 500 |
| Grid size P, Q | 1 to 200 |
| Cell height | 0 to 5000 metres |
| Time limit | 13000 ms |
| Memory limit | 1536 MB |

The grid size and height bounds keep all arithmetic in 64-bit integers.

## Idea

Compute visibility first, then find the path. For each base station, group all cells by the primitive direction from that station. March each ray outward once.

Two running values remember the steepest climb that passed cells require. An ascending ray uses the entry edge of each passed cell. A descending ray uses its exit edge.

Each cell center is tested against one value in constant time.

A breadth-first search then walks cells that see either station. The search obeys the height rule on every step. It uses four neighbours per cell, so it visits each cell once.

## Why It Works

A ray is blocked only when it enters the interior of a solid cube. Touching a face or an edge is allowed, so equality never blocks.

The ray height is linear. Its lowest point inside a cell sits at the entry edge for an ascent. For a descent, the lowest point sits at the exit edge.

Scaling ray time by stepX times stepY makes every edge crossing an integer cellCross. The term sourceHeight minus cellTop measures source clearance above the current cell. Multiplying by finalCross and adding slope times the crossing time keeps the test exact.

A cell blocks an ascending target when that sum is negative. Rearranging gives a required slope of leavingCandidate over cellCross for descents. The value enteringCandidate over previousCross is the requirement for ascents.

Here is a worked example for heights 0, 1, 2 in one row with the station on the first cell. The source height value is 1, stepX is 2, stepY is 1, and scale is 2.

At step 1 the crossing is 1. The requirement and the slope both equal 2 over 1. The second cell is visible.

At step 2 the crossing is 3. The requirement stays 2 over 1; the slope reaches 4 over 2. The third cell is visible.

Breadth-first search is correct because every rule is local to one step. The first time the search reaches the second station, the number of steps is minimal.

## Code

The input loop appends every line into one buffer. The scanner walks that buffer by index and never splits tokens.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const directionOffset = 200
const directionWidth = 401
const directionTableSize = directionWidth * directionWidth
const infiniteCross = 1 shl 60
const successSentence = "The shortest path is "
const failureSentence = "Mission impossible!"
const stepSuffix = " steps long."

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + (int(data[position]) - firstDigitValue)
    position += 1
  return value
```

The direction table holds the farthest cell center for each primitive direction. The table covers offsets from minus 199 to 199 on both axes. The ray loop stops after maxSteps crossings, and each crossing updates one running maximum.

```nim
proc greatestCommonDivisor(first: int, second: int): int =
  var left = first
  var right = second
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  return left

var directionMaxSteps = newSeq[int](directionTableSize)
var usedDirections: seq[int] = @[]

proc markVisibleFromSource(terrain: seq[int], rowCount: int, colCount: int,
                           sourceRow: int, sourceCol: int,
                           visible: var seq[bool]) =
  let sourceHeight = 2 * terrain[sourceRow * colCount + sourceCol] + 1
  usedDirections.setLen 0
  for row in 0..<rowCount:
    for col in 0..<colCount:
      if row == sourceRow and col == sourceCol:
        continue
      let colGap = col - sourceCol
      let rowGap = row - sourceRow
      let steps = greatestCommonDivisor(abs(colGap), abs(rowGap))
      let dirCol = colGap div steps
      let dirRow = rowGap div steps
      let dirIndex = (dirCol + directionOffset) * directionWidth + dirRow + directionOffset
      if directionMaxSteps[dirIndex] == 0:
        usedDirections.add dirIndex
      if steps > directionMaxSteps[dirIndex]:
        directionMaxSteps[dirIndex] = steps
  visible[sourceRow * colCount + sourceCol] = true
  for dirIndex in usedDirections:
    let dirCol = dirIndex div directionWidth - directionOffset
    let dirRow = dirIndex mod directionWidth - directionOffset
    let stepX = if dirCol == 0: 1 else: 2 * abs(dirCol)
    let stepY = if dirRow == 0: 1 else: 2 * abs(dirRow)
    let scale = stepX * stepY
    let maxSteps = directionMaxSteps[dirIndex]
    var nextCrossX = if dirCol == 0: infiniteCross else: stepY
    var nextCrossY = if dirRow == 0: infiniteCross else: stepX
    let advanceX = 2 * stepY
    let advanceY = 2 * stepX
    let signX = if dirCol > 0: 1 else: -1
    let signY = if dirRow > 0: 1 else: -1
    var currentRow = sourceRow
    var currentCol = sourceCol
    var previousCross = 0
    var hasAscending = false
    var hasDescending = false
    var ascendingNum = 0
    var ascendingDen = 1
    var descendingNum = 0
    var descendingDen = 1
    for step in 1..maxSteps:
      let centerCross = step * scale
      while nextCrossX < centerCross or nextCrossY < centerCross:
        let cellCross = min(nextCrossX, nextCrossY)
        let currentHeight = 2 * terrain[currentRow * colCount + currentCol] - sourceHeight
        let leavingCandidate = currentHeight * scale
        if not hasDescending or leavingCandidate * descendingDen > descendingNum * cellCross:
          hasDescending = true
          descendingNum = leavingCandidate
          descendingDen = cellCross
        if nextCrossX == cellCross:
          currentCol += signX
          nextCrossX += advanceX
        if nextCrossY == cellCross:
          currentRow += signY
          nextCrossY += advanceY
        previousCross = cellCross
        let nextHeight = 2 * terrain[currentRow * colCount + currentCol] - sourceHeight
        let enteringCandidate = nextHeight * scale
        if previousCross > 0 and (not hasAscending or
            enteringCandidate * ascendingDen > ascendingNum * previousCross):
          hasAscending = true
          ascendingNum = enteringCandidate
          ascendingDen = previousCross
      let targetRow = sourceRow + step * dirRow
      let targetCol = sourceCol + step * dirCol
      let targetHeight = 2 * terrain[targetRow * colCount + targetCol] + 1
      let targetSlope = targetHeight - sourceHeight
      var isVisible = false
      if targetSlope >= 0:
        isVisible = not hasAscending or
                    targetSlope * ascendingDen >= ascendingNum * step
      else:
        isVisible = not hasDescending or
                    targetSlope * descendingDen >= descendingNum * step
      if isVisible:
        visible[targetRow * colCount + targetCol] = true
    directionMaxSteps[dirIndex] = 0
```

The queue holds at most P times Q cell indices. Output is appended to one buffer and flushed in large blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for testIndex in 1..testCount:
  let rowCount = nextInt(inputData, scanPos)
  let colCount = nextInt(inputData, scanPos)
  var terrain = newSeq[int](rowCount * colCount)
  for cellIndex in 0..<rowCount * colCount:
    terrain[cellIndex] = nextInt(inputData, scanPos)
  let firstRow = nextInt(inputData, scanPos) - 1
  let firstCol = nextInt(inputData, scanPos) - 1
  let secondRow = nextInt(inputData, scanPos) - 1
  let secondCol = nextInt(inputData, scanPos) - 1
  let firstIndex = firstRow * colCount + firstCol
  let secondIndex = secondRow * colCount + secondCol
  var visible = newSeq[bool](rowCount * colCount)
  markVisibleFromSource(terrain, rowCount, colCount, firstRow, firstCol, visible)
  markVisibleFromSource(terrain, rowCount, colCount, secondRow, secondCol, visible)
  var distance = newSeq[int](rowCount * colCount)
  for cellIndex in 0..<rowCount * colCount:
    distance[cellIndex] = -1
  var queue = newSeq[int](rowCount * colCount)
  var queueHead = 0
  var queueTail = 0
  distance[firstIndex] = 0
  queue[queueTail] = firstIndex
  queueTail += 1
  while queueHead < queueTail and distance[secondIndex] == -1:
    let current = queue[queueHead]
    queueHead += 1
    let currentRow = current div colCount
    let currentCol = current mod colCount
    let currentHeight = terrain[current]
    for neighborIndex in 0..<4:
      var neighborRow = currentRow
      var neighborCol = currentCol
      case neighborIndex
      of 0: neighborRow -= 1
      of 1: neighborRow += 1
      of 2: neighborCol -= 1
      else: neighborCol += 1
      if neighborRow < 0 or neighborRow >= rowCount or neighborCol < 0 or neighborCol >= colCount:
        continue
      let neighbor = neighborRow * colCount + neighborCol
      if distance[neighbor] != -1 or not visible[neighbor]:
        continue
      let neighborHeight = terrain[neighbor]
      if neighborHeight - currentHeight > 1 or currentHeight - neighborHeight > 3:
        continue
      distance[neighbor] = distance[current] + 1
      queue[queueTail] = neighbor
      queueTail += 1
  if distance[secondIndex] == -1:
    appendOutput(failureSentence)
  else:
    appendOutput(successSentence)
    appendOutput($distance[secondIndex])
    appendOutput(stepSuffix)
  appendOutput("\n")

stdout.write outputBuffer
```

## Complexity

Reading input takes time linear in the number of heights. Grouping cells takes O(P*Q) greatest common divisor computations per base station.

Marching all rays takes at most O(P*Q*(P+Q)) cell crossings per station. Most rays are short. The breadth-first search takes O(P*Q) time and visits each cell once.

Terrain, visibility, distance and queue each use O(P*Q) space. The direction table uses 401 times 401 integers, independent of the grid size. A pairwise visibility check would take O(P*Q*(P+Q)) time per station and repeat work on shared rays; the ray grouping removes that repeat.
