# DIRVS — Direct Visibility (SPOJ)
<https://www.spoj.com/problems/DIRVS/>

## Problem

The input describes a grid of terrain heights and two base station cells.
Find the shortest walk between the stations where, after each step, at least one station is visible and height limits hold.

Read `T` towns.
Each town is a `P` by `Q` grid of terrain heights, followed by two base station cells.
The technician moves between side-adjacent cells.
Each step may climb at most 1 metre or descend at most 3 metres.
After every step, at least one station must be visible.

Print the shortest path length, or `Mission impossible!` when no path exists.
A success line reads `The shortest path is L steps long.`

The judge bounds follow.

| Item | Bound |
| --- | --- |
| Test cases `T` | about 500 |
| Grid size `P`, `Q` | 1 to 200 |
| Cell height | 0 to 5000 metres |
| Time limit | 13000 ms |
| Memory limit | 1536 MB |

The grid bounds keep every cross product in 64-bit integers.

The sample input and expected output follow verbatim.

```
4
5 5
8 7 6 5 4
2 2 2 2 2
2 2 2 2 2
2 2 2 2 2
2 2 2 2 2
1 1 5 1
5 8
2 2 2 2 2 2 2 2
2 2 2 2 2 2 2 2
2 2 2 2 2 2 2 2
9 9 9 9 9 9 9 2
2 2 2 2 2 2 2 2
1 2 5 1
5 8
2 2 2 2 2 2 2 2
2 2 2 2 2 2 2 2
2 2 2 2 2 2 2 2
9 9 9 9 9 9 9 2
2 2 2 2 2 2 2 2
1 5 5 1
6 12
5 5 5 5 1 5 5 5 5 5 5 5
5 5 5 5 1 5 5 5 5 5 5 5
5 5 5 5 9 5 5 5 5 5 5 5
5 9 1 5 5 5 5 5 5 5 5 5
5 5 9 5 5 5 5 5 5 5 5 5
5 5 9 5 5 5 5 5 5 5 5 5
6 1 3 12
```

```
The shortest path is 10 steps long.
Mission impossible!
The shortest path is 14 steps long.
The shortest path is 18 steps long.
```

The four towns print two successes and two failures.

## Idea

Check sightlines first, then draw the route, like checking which stations are in view before choosing a path.
For each station, group other cells by primitive direction, a direction divided by the gcd (greatest common divisor) of its offsets.
March each ray outward once.

Two running fractions remember the steepest climb and the steepest descent that passed cells require.
A cell center is tested in constant time against those fractions.
Breadth-first search (shortest paths on an unweighted grid) then visits cells that see either station.
It checks four neighbours per cell and the climb and descent limits.

Cost per station is one gcd per cell plus one march per ray.
Checking every cell pair would repeat work on shared rays.
Group rays first, then run one breadth-first search.

## Why It Works

Four facts prove the method.

1. A ray is blocked only when it enters the interior of a solid cube.
   Touching a face or an edge is allowed, so equality never blocks.
2. The ray height is linear.
   The lowest point inside a passed cell sits at the entry edge for an ascent and at the exit edge for a descent.
3. Scaling ray time by `stepX` times `stepY` makes each cell crossing an integer `cellCross`.
   Cross multiplication (comparing fractions without division) keeps every test exact.
4. Breadth-first search is correct because each rule is local to one step.
   The first time the search reaches the second station gives the minimum length.

The running values and their roles follow.

| Term | Meaning |
| --- | --- |
| `steps` | gcd of the row and column gaps from the station |
| `dirCol`, `dirRow` | primitive direction components |
| `ascendingNum / ascendingDen` | steepest required climb seen so far |
| `descendingNum / descendingDen` | steepest required descent seen so far |

All visibility tests stay in 64-bit integer arithmetic.

A script checks the first three heights of the sample row 8 7 6 5 4.
The station sits on the cell of height 8 with center height 17, and `stepX = 2` and `stepY = 1`.

```
step 1: cross=1, requirement 2/1, ray slope 2/1 -> visible
step 2: cross=3, requirement 2/1, ray slope 4/2 -> visible
```

The equality passes, so both cells see the station.

## Code

**Constants.**

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
```

directionWidth covers offsets from minus 199 to 199. infiniteCross marks an axis with no cell crossings. The three output phrases are fixed strings.

**Input and scanner.**

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + (int(data[i]) - firstDigitValue)
    i += 1
  return value
```

Every input line is copied into one buffer. nextInt skips non-digits and builds values digit by digit. The scanner allocates no token strings.

**Direction grouping.**

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
```

greatestCommonDivisor reduces a gap pair to a primitive direction. directionMaxSteps keeps the farthest cell on each direction. The 401 by 401 table is reused after every ray march.

**March all rays from one station.**

```nim
proc markVisibleFromSource(terrain: seq[int], rowCount: int, colCount: int,
                           sourceRow: int, sourceCol: int,
                           visible: var seq[bool]) =
  let sourceHeight = 2 * terrain[sourceRow * colCount + sourceCol] + 1
  usedDirections.setLen 0
  for i in 0..<rowCount:
    for j in 0..<colCount:
      if i == sourceRow and j == sourceCol:
        continue
      let colGap = j - sourceCol
      let rowGap = i - sourceRow
      let steps = greatestCommonDivisor(abs(colGap), abs(rowGap))
      let dirCol = colGap div steps
      let dirRow = rowGap div steps
      let k = (dirCol + directionOffset) * directionWidth + dirRow + directionOffset
      if directionMaxSteps[k] == 0:
        usedDirections.add k
      if steps > directionMaxSteps[k]:
        directionMaxSteps[k] = steps
  visible[sourceRow * colCount + sourceCol] = true
  for k in usedDirections:
    let dirCol = k div directionWidth - directionOffset
    let dirRow = k mod directionWidth - directionOffset
    let stepX = if dirCol == 0: 1 else: 2 * abs(dirCol)
    let stepY = if dirRow == 0: 1 else: 2 * abs(dirRow)
    let scale = stepX * stepY
    let maxSteps = directionMaxSteps[k]
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
    for l in 1..maxSteps:
      let centerCross = l * scale
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
      let targetRow = sourceRow + l * dirRow
      let targetCol = sourceCol + l * dirCol
      let targetHeight = 2 * terrain[targetRow * colCount + targetCol] + 1
      let targetSlope = targetHeight - sourceHeight
      var isVisible = false
      if targetSlope >= 0:
        isVisible = not hasAscending or
                    targetSlope * ascendingDen >= ascendingNum * l
      else:
        isVisible = not hasDescending or
                    targetSlope * descendingDen >= descendingNum * l
      if isVisible:
        visible[targetRow * colCount + targetCol] = true
    directionMaxSteps[k] = 0
```

The first double loop bins every cell into a primitive direction. The second loop marches each used ray once. Ascending and descending requirements are updated with cross multiplication. directionMaxSteps is reset after each direction.

**Output buffer.**

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

appendOutput flushes at 256 KiB. All result lines share one buffer. The write layer is independent of the ray logic.

**Breadth-first search and answer.**

```nim
let testCount = nextInt(inputData, i)
for j in 1..testCount:
  let rowCount = nextInt(inputData, i)
  let colCount = nextInt(inputData, i)
  var terrain = newSeq[int](rowCount * colCount)
  for k in 0..<rowCount * colCount:
    terrain[k] = nextInt(inputData, i)
  let firstRow = nextInt(inputData, i) - 1
  let firstCol = nextInt(inputData, i) - 1
  let secondRow = nextInt(inputData, i) - 1
  let secondCol = nextInt(inputData, i) - 1
  let firstIndex = firstRow * colCount + firstCol
  let secondIndex = secondRow * colCount + secondCol
  var visible = newSeq[bool](rowCount * colCount)
  markVisibleFromSource(terrain, rowCount, colCount, firstRow, firstCol, visible)
  markVisibleFromSource(terrain, rowCount, colCount, secondRow, secondCol, visible)
  var distance = newSeq[int](rowCount * colCount)
  for k in 0..<rowCount * colCount:
    distance[k] = -1
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
    for l in 0..<4:
      var neighborRow = currentRow
      var neighborCol = currentCol
      case l
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

The case loop reads the grid and both station cells. Two visibility calls mark the cells that see a station. The queue visits four neighbours and checks the height rule. The first arrival at the second station gives the minimum length.

## Complexity

The phases and their costs for one town follow.

| Phase | Time | Space |
| --- | --- | --- |
| Read and bin cells | O(P*Q) gcd calls | O(P*Q) terrain |
| March all rays | O(P*Q*(P+Q)) crossings | O(401²) direction table |
| Breadth-first search | O(P*Q) | O(P*Q) |
| Output | O(1) per town | one output block |

Most rays are short, so the march stays well below its bound.

The Big O summary follows.

| Measure | Big O |
| --- | --- |
| Time | O(P*Q*(P+Q)) per town worst case |
| Space | O(P*Q) plus the fixed direction table |

A pairwise visibility check repeats the same ray work for every cell pair.
