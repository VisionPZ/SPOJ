# ULASER — Union Laser (SPOJ)

<https://www.spoj.com/problems/ULASER/>

## Problem

Trace a 45-degree laser inside a union of rectangles and report its first self-collision. The beam starts at an integer point inside the union and points down and right. It bounces off the union boundary until it meets an earlier point on its path.

The first line holds N, the number of boxes. The second line holds the laser coordinates A and B. Each following line holds x1, y1, x2, y2, the opposite corners of one axis-aligned rectangle. N ranges from 1 to 10000, and every coordinate has absolute value at most 3000.

If the beam meets the laser itself, print the time and “Broken equipment” on two lines. Otherwise print the time and the x and y coordinates of the first self-collision. If no collision occurs, print “Time limit exceeded”. Round each number to one decimal place.

| item | bound |
|---|---|
| boxes N | 1 to 10000 |
| coordinates | −3000 to 3000 |
| speed | √2 units per second |
| judge limit | 3000 ms, 1536 MB |

One diagonal crossing takes one second, so time is an integer or a half integer.

Sample input:

```
7
0 4
-1 5 1 -1
0 -2 4 2
0 -4 1 2
2 -4 5 -1
5 2 7 4
3 -5 4 -4
0 -6 3 -4
```

Sample output:

```
12.0
0.0 0.0
```

## Idea

Picture the beam walking diagonally across square floor tiles, one tile per second. Mark each tile by the direction of the diagonal it used, so a later crossing catches the earlier path.

The algorithm is a discrete billiard simulation on integer lattice points. Each step checks the three cells around the current corner to choose a straight move, a reflection, or a head-on stop. Two visited diagonals of the same tile cross at its center, which gives a half-second collision. Revisiting a lattice point gives an integer-time collision. A naive check of every earlier segment for every new step costs quadratic time, while the orientation marks make each step constant.

## Why It Works

1. A rectangle covers unit cells with x from min(x1, x2) to max(x1, x2) − 1, and similarly for y.
2. From corner (x, y) with step (dx, dy), the beam crosses the cell (x + min(0, dx), y + min(0, dy)).
3. Moving one diagonal takes √2 units at speed √2, so it takes exactly one second.
4. At a corner, the beam continues only when the forward cell and both side cells lie in the union.
5. One missing side cell reflects the matching component: stepX flips for a vertical edge, stepY for a horizontal edge.
6. Two missing side cells, or a missing forward cell with both sides present, make a head-on corner and stop the beam.
7. Opposite diagonals of one cell cross at its center, at time t + 0.5 and coordinates (cellX + 0.5, cellY + 0.5).
8. Reaching a marked lattice point at time t ends the trace at that point.

| term | meaning |
|---|---|
| `occupiedCells` | one byte per unit cell, set when a box covers it |
| `visitedPoints` | marks lattice points already reached by the beam |
| `visitedOrientations` | two bits per cell, one for each diagonal direction |
| `headOn` | true when the corner reverses the beam and ends the trace |
| `formatHalf` | prints twice an integer as a one-decimal string |

Storing times and coordinates doubled keeps every printed value exact.

The script trace for the sample gives:

```
t=0  ( 0, 4) step ( 1,-1)
t=1  ( 1, 3) vertical edge, flip stepX
t=4  ( 0, 0) first visit
t=6  ( 2,-2) horizontal edge, flip stepY
t=12 ( 0, 0) revisited
```

The trace ends at the first revisit, so the output is 12.0 and 0.0 0.0.

The step cap returns “Time limit exceeded” when no collision appears within the simulation budget. Every collision coordinate uses doubled integers, so the printed decimal never rounds incorrectly.

## Code

**Input and formatting.** The scanner accepts negative coordinates and the formatter prints halves exactly.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const initialStepX = 1
const initialStepY = -1
const maxSimulationSteps = 12000000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc formatHalf(doubledValue: int): string =
  var negative = false
  var magnitude = doubledValue
  if magnitude < 0:
    negative = true
    magnitude = -magnitude
  let wholePart = magnitude div 2
  let halfPart = magnitude mod 2
  result = (if negative: "-" else: "") & $wholePart & (if halfPart == 1: ".5" else: ".0")
```

The scanner reads a leading minus before the digits.
The buffer writes in large blocks.
Doubled values make the decimal output exact.

**Union grid.** Box corners define a tight grid, and occupied cells are marked once.

```nim
let boxCount = nextInt(inputData, scanPos)
let laserX = nextInt(inputData, scanPos)
let laserY = nextInt(inputData, scanPos)
var boxCorners = newSeq[int](boxCount * 4)
var minCellX = 0
var maxCellX = 0
var minCellY = 0
var maxCellY = 0
for boxIndex in 0 .. boxCount - 1:
  let firstX = nextInt(inputData, scanPos)
  let firstY = nextInt(inputData, scanPos)
  let secondX = nextInt(inputData, scanPos)
  let secondY = nextInt(inputData, scanPos)
  boxCorners[boxIndex * 4] = firstX
  boxCorners[boxIndex * 4 + 1] = firstY
  boxCorners[boxIndex * 4 + 2] = secondX
  boxCorners[boxIndex * 4 + 3] = secondY
  let lowerX = min(firstX, secondX)
  let upperX = max(firstX, secondX)
  let lowerY = min(firstY, secondY)
  let upperY = max(firstY, secondY)
  if boxIndex == 0:
    minCellX = lowerX
    maxCellX = upperX
    minCellY = lowerY
    maxCellY = upperY
  else:
    if lowerX < minCellX: minCellX = lowerX
    if upperX > maxCellX: maxCellX = upperX
    if lowerY < minCellY: minCellY = lowerY
    if upperY > maxCellY: maxCellY = upperY

let gridWidth = maxCellX - minCellX + 1
let gridHeight = maxCellY - minCellY + 1
let gridSize = gridWidth * gridHeight
var occupiedCells = newSeq[int8](gridSize)
var visitedPoints = newSeq[int8](gridSize)
var visitedOrientations = newSeq[int8](gridSize)

proc cellIndex(cellX, cellY: int): int =
  return (cellY - minCellY) * gridWidth + (cellX - minCellX)

proc isOccupied(cellX, cellY: int): bool =
  if cellX < minCellX or cellX >= maxCellX or cellY < minCellY or cellY >= maxCellY:
    return false
  return occupiedCells[cellIndex(cellX, cellY)] == 1

for boxIndex in 0 .. boxCount - 1:
  let lowerX = min(boxCorners[boxIndex * 4], boxCorners[boxIndex * 4 + 2])
  let upperX = max(boxCorners[boxIndex * 4], boxCorners[boxIndex * 4 + 2])
  let lowerY = min(boxCorners[boxIndex * 4 + 1], boxCorners[boxIndex * 4 + 3])
  let upperY = max(boxCorners[boxIndex * 4 + 1], boxCorners[boxIndex * 4 + 3])
  var cellX = lowerX
  while cellX < upperX:
    var cellY = lowerY
    while cellY < upperY:
      occupiedCells[cellIndex(cellX, cellY)] = 1
      cellY += 1
    cellX += 1
```

The grid spans only the box bounding rectangle.
Overlapping boxes set the same cell byte more than once.
Cell lookup rejects indices outside that rectangle.

**Reflection choice.** Three neighboring cells decide the next step direction.

```nim
visitedPoints[cellIndex(laserX, laserY)] = 1
var currentX = laserX
var currentY = laserY
var stepX = initialStepX
var stepY = initialStepY
var timeValue = 0
var simulationStep = 0
var finished = false

while simulationStep < maxSimulationSteps and not finished:
  let forwardX = currentX + min(0, stepX)
  let forwardY = currentY + min(0, stepY)
  let sideBelowX = currentX + min(0, -stepX)
  let sideBelowY = currentY + min(0, stepY)
  let sideAsideX = currentX + min(0, stepX)
  let sideAsideY = currentY + min(0, -stepY)
  let forwardInside = isOccupied(forwardX, forwardY)
  let sideBelowInside = isOccupied(sideBelowX, sideBelowY)
  let sideAsideInside = isOccupied(sideAsideX, sideAsideY)
  var headOn = false
  if not (forwardInside and sideBelowInside and sideAsideInside):
    if sideBelowInside and not sideAsideInside:
      stepX = -stepX
    elif sideAsideInside and not sideBelowInside:
      stepY = -stepY
    else:
      stepX = -stepX
      stepY = -stepY
      headOn = true
    if headOn:
      appendOutput(formatHalf(timeValue * 2))
      appendOutput("\n")
      appendOutput(formatHalf(currentX * 2))
      appendOutput(" ")
      appendOutput(formatHalf(currentY * 2))
      appendOutput("\n")
      finished = true
      break
```

The laser point is marked before the first step.
A missing side cell flips one step component.
A corner that reverses the beam ends the trace at that corner.

**Collision checks.** Cell diagonals and lattice points reveal the first meeting.

```nim
  let travelledX = currentX + min(0, stepX)
  let travelledY = currentY + min(0, stepY)
  let orientation = if stepX == stepY: 0 else: 1
  let travelledIndex = cellIndex(travelledX, travelledY)
  let previousMask = visitedOrientations[travelledIndex]
  let oppositeMask: int8 = int8(1 shl (1 - orientation))
  if (previousMask and oppositeMask) != 0:
    appendOutput(formatHalf(timeValue * 2 + 1))
    appendOutput("\n")
    appendOutput(formatHalf(travelledX * 2 + 1))
    appendOutput(" ")
    appendOutput(formatHalf(travelledY * 2 + 1))
    appendOutput("\n")
    finished = true
    break
  visitedOrientations[travelledIndex] = previousMask or int8(1 shl orientation)
  let nextX = currentX + stepX
  let nextY = currentY + stepY
  let nextTime = timeValue + 1
  if nextX == laserX and nextY == laserY:
    appendOutput(formatHalf(nextTime * 2))
    appendOutput("\n")
    appendOutput("Broken equipment")
    appendOutput("\n")
    finished = true
    break
  let nextIndex = cellIndex(nextX, nextY)
  if visitedPoints[nextIndex] == 1:
    appendOutput(formatHalf(nextTime * 2))
    appendOutput("\n")
    appendOutput(formatHalf(nextX * 2))
    appendOutput(" ")
    appendOutput(formatHalf(nextY * 2))
    appendOutput("\n")
    finished = true
    break
  visitedPoints[nextIndex] = 1
  currentX = nextX
  currentY = nextY
  timeValue = nextTime
  simulationStep += 1

if not finished:
  appendOutput("Time limit exceeded")
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

Opposite diagonal bits mean the two segments cross at the tile center.
A revisited lattice point ends the trace at integer time.
The final flush writes the one or two output lines.

## Complexity

Each step reads three neighboring cells and updates two marks.

| phase | time | space |
|---|---|---|
| input read | one pass over box corners | one input string |
| grid build | one write per covered unit cell | three byte grids |
| beam trace | constant work per step | same three grids |
| output | one or two lines | block buffer |

The three grids are the only large allocations, and each holds one byte per lattice point.

| measure | Big O |
|---|---|
| time | O(N × area + steps) |
| space | O(width × height) |

Here width and height span the box bounding rectangle, each at most 6001.
Checking every earlier segment at every step would cost O(steps^2) time instead of constant time per step.
