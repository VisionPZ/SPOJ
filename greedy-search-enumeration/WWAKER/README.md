# WWAKER — The Wind Waker (SPOJ)
<https://www.spoj.com/problems/WWAKER/>

## Problem

Link starts at one point with no wind and must reach another point and stop. Each baton use sets a new compass direction, and the boat travels along that direction until the next use. Find a trajectory with the fewest uses, then the shortest distance, then the lexicographically smallest direction sequence.

Input holds test cases until end of file. Each line gives four integers x1, y1, x2, y2 with absolute values up to 50000 and different start and target points.

Output gives K, then K event lines with a coordinate pair and a direction letter. The last line holds the total distance to three decimals, followed by a blank line. Direction order is E, N, NE, NW, S, SE, SW, W, X.

The input bounds are:

| item | bound |
|---|---|
| coordinates | -50000 to 50000 |
| test cases | until end of file |
| wind directions | 8 directions plus X |
| judge limit | 1000 ms, 1536 MB |

The final event always sets X at the target, so an aligned trip uses two events and a general trip uses three.

Sample input:

```
0 0 0 1
0 0 3 2
```

Sample output:

```
2
0.00 0.00 N
0.00 1.00 X
1.000

3
0.00 0.00 E
1.00 0.00 NE
3.00 2.00 X
3.828

```

## Idea

Reach the target by joining at most two arrows, like walking one street then a diagonal shortcut. An aligned displacement needs one direction plus the stop. Any other displacement needs two directions plus the stop.

The algorithm enumerates all ordered pairs of the eight directions, solves a two-by-two integer system, and compares costs exactly with integer parts and square-root parts. Each pair costs constant work.

Searching split points on a coordinate grid would be far larger. A small ordered scan finds the best pair and settles ties by direction order.

## Why It Works

1. The boat travels in a straight line while the wind holds one direction.
2. A single direction reaches the target only when the displacement is parallel to it.
3. The eight directions surround the plane, so two adjacent directions span every displacement with positive coefficients.
4. For directions u and v, solving displacement = s u + t v gives the split point and the two leg lengths.
5. Axial legs cost s or t, and diagonal legs cost s sqrt(2) or t sqrt(2).
6. Determinants are 1 or 2, so s and t are integers or half integers and coordinates print exactly with two decimals.
7. Comparing p + q sqrt(2) with p' + q' sqrt(2) by squaring integers avoids rounding errors in the choice.
8. Among equal costs, the smallest first direction and then the smallest second direction win.

The main terms are:

| term | meaning |
|---|---|
| `directionX`, `directionY` | integer components of the eight directions |
| `firstSteps`, `secondSteps` | numerators of the two leg lengths |
| `determinant` | cross product of the chosen direction pair |
| `bestLinear`, `bestDiagonal` | cost parts before dividing by two |
| `splitHalfX`, `splitHalfY` | turning point coordinates in half units |

A short script over the second sample gives these candidates:

| first direction | second direction | leg lengths | total distance |
|---|---|---|---|
| E | NE | 1, 2 | 1 + 2 sqrt(2) = 3.828 |
| NE | E | 2, 1 | 2 sqrt(2) + 1 = 3.828 |
| E | N | 3, 2 | 5.000 |

The first two candidates tie, and E comes before NE in the required order.
The printed trajectory uses E then NE and reports 3.828, matching the sample.
The integer comparison keeps this tie exact even for large coordinates.

## Code

**Input and helpers.** The hand reader accepts signed coordinates and defines the direction order.

```nim
import math
import strutils

const flushBlockBytes = 1 shl 17
const directionX = [1, 0, 1, -1, 0, 1, -1, -1]
const directionY = [0, 1, 1, 1, -1, -1, -1, 0]
const directionName = ["E", "N", "NE", "NW", "S", "SE", "SW", "W"]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The direction tables follow the required lexicographic order.
The scanner accepts negative coordinates.
The output helpers come from the standard library.

**Exact comparison.** Costs are integers plus an integer multiple of sqrt(2).

```nim
proc costLess(firstLinear, firstDiagonal, secondLinear, secondDiagonal: int64): bool =
  let linearDifference = firstLinear - secondLinear
  let diagonalDifference = firstDiagonal - secondDiagonal
  if linearDifference == 0 and diagonalDifference == 0:
    return false
  if diagonalDifference == 0:
    return linearDifference < 0
  if linearDifference == 0:
    return diagonalDifference < 0
  if linearDifference > 0 and diagonalDifference > 0:
    return false
  if linearDifference < 0 and diagonalDifference < 0:
    return true
  if linearDifference > 0:
    return linearDifference * linearDifference < 2 * diagonalDifference * diagonalDifference
  return linearDifference * linearDifference > 2 * diagonalDifference * diagonalDifference

proc appendCoordinate(halfValue: int) =
  var magnitude = halfValue
  if magnitude < 0:
    appendOutput("-")
    magnitude = -magnitude
  appendOutput($(magnitude div 2))
  if magnitude mod 2 == 0:
    appendOutput(".00 ")
  else:
    appendOutput(".50 ")
```

Opposite signs are compared by squaring the integer parts.
Half-unit coordinates print as whole or .50 values.
The minus sign is written before the magnitude.

**Aligned case.** A parallel displacement uses one direction and the stop.

```nim
while true:
  var hasNextCase = false
  var checkPos = scanPos
  while checkPos < inputData.len:
    if (inputData[checkPos] >= '0' and inputData[checkPos] <= '9') or inputData[checkPos] == '-':
      hasNextCase = true
      break
    checkPos += 1
  if not hasNextCase:
    break
  let startX = nextInt(inputData, scanPos)
  let startY = nextInt(inputData, scanPos)
  let targetX = nextInt(inputData, scanPos)
  let targetY = nextInt(inputData, scanPos)
  let deltaX = targetX - startX
  let deltaY = targetY - startY
  var bestFirst = -1
  var bestSecond = -1
  var bestLinear: int64 = 0
  var bestDiagonal: int64 = 0
  var splitHalfX = 0
  var splitHalfY = 0
  var eventCount = 0

  for firstDirection in 0 .. 7:
    let cross = deltaX * directionY[firstDirection] - deltaY * directionX[firstDirection]
    let dot = deltaX * directionX[firstDirection] + deltaY * directionY[firstDirection]
    if cross != 0 or dot <= 0:
      continue
    let steps = if directionX[firstDirection] != 0: deltaX div directionX[firstDirection] else: deltaY div directionY[firstDirection]
    let candidateLinear = if directionX[firstDirection] == 0 or directionY[firstDirection] == 0: int64(2 * steps) else: 0'i64
    let candidateDiagonal = if directionX[firstDirection] == 0 or directionY[firstDirection] == 0: 0'i64 else: int64(2 * steps)
    if bestFirst == -1 or costLess(candidateLinear, candidateDiagonal, bestLinear, bestDiagonal):
      bestFirst = firstDirection
      bestSecond = -1
      bestLinear = candidateLinear
      bestDiagonal = candidateDiagonal
      eventCount = 2
```

The loop stops when no digit remains in the input.
A zero cross product marks a parallel direction.
A positive dot product fixes the forward sense.

**General case.** Every ordered direction pair gives one candidate trajectory.

```nim
  if bestFirst == -1:
    for firstDirection in 0 .. 7:
      for secondDirection in 0 .. 7:
        if firstDirection == secondDirection:
          continue
        var determinant = directionX[firstDirection] * directionY[secondDirection] - directionY[firstDirection] * directionX[secondDirection]
        if determinant == 0:
          continue
        var firstSteps = deltaX * directionY[secondDirection] - deltaY * directionX[secondDirection]
        var secondSteps = directionX[firstDirection] * deltaY - directionY[firstDirection] * deltaX
        if determinant < 0:
          determinant = -determinant
          firstSteps = -firstSteps
          secondSteps = -secondSteps
        if firstSteps <= 0 or secondSteps <= 0:
          continue
        let scale = 2 div determinant
        var candidateLinear: int64 = 0
        var candidateDiagonal: int64 = 0
        if directionX[firstDirection] == 0 or directionY[firstDirection] == 0:
          candidateLinear += int64(firstSteps * scale)
        else:
          candidateDiagonal += int64(firstSteps * scale)
        if directionX[secondDirection] == 0 or directionY[secondDirection] == 0:
          candidateLinear += int64(secondSteps * scale)
        else:
          candidateDiagonal += int64(secondSteps * scale)
        let better = costLess(candidateLinear, candidateDiagonal, bestLinear, bestDiagonal)
        let tied = (not better) and (not costLess(bestLinear, bestDiagonal, candidateLinear, candidateDiagonal))
        if bestFirst == -1 or better or (tied and (firstDirection < bestFirst or (firstDirection == bestFirst and secondDirection < bestSecond))):
          bestFirst = firstDirection
          bestSecond = secondDirection
          bestLinear = candidateLinear
          bestDiagonal = candidateDiagonal
          splitHalfX = startX * 2 + firstSteps * directionX[firstDirection] * scale
          splitHalfY = startY * 2 + firstSteps * directionY[firstDirection] * scale
          eventCount = 3
```

Cramer's rule gives the two numerators.
A negative determinant flips all signs to keep steps positive.
Ties go to the pair with the smaller direction index.

**Final write.** Events and distance are emitted for the winning trajectory.

```nim
  appendOutput($eventCount)
  outputBuffer.add '\n'
  appendCoordinate(startX * 2)
  appendCoordinate(startY * 2)
  appendOutput(directionName[bestFirst])
  outputBuffer.add '\n'
  if bestSecond >= 0:
    appendCoordinate(splitHalfX)
    appendCoordinate(splitHalfY)
    appendOutput(directionName[bestSecond])
    outputBuffer.add '\n'
  appendCoordinate(targetX * 2)
  appendCoordinate(targetY * 2)
  appendOutput("X")
  outputBuffer.add '\n'
  let distance = (float(bestLinear) + float(bestDiagonal) * sqrt(2.0)) / 2.0
  appendOutput(formatFloat(distance, ffDecimal, 3))
  outputBuffer.add '\n'
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The start and target are printed with whole coordinates.
An aligned trip omits the middle event.
The distance uses floating output only after the exact choice is made.

## Complexity

Direction enumeration dominates each test case.

| phase | time | space |
|---|---|---|
| input read | one pass over coordinate lines | one input string |
| aligned check | eight cross products | constant |
| pair scan | at most 56 direction pairs | constant |
| output | up to four lines per case | block buffer |

Every case performs a fixed number of integer operations.

| measure | Big O |
|---|---|
| time | O(1) per test case |
| space | O(1) besides input and output buffers |

A grid search over split points would scale with the coordinate range.
Eight directions and one pair scan finish each case, and that ends the work.
