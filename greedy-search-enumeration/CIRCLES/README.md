# CIRCLES — Circles (SPOJ)

<https://www.spoj.com/problems/CIRCLES/>

## Problem

Circles appear and disappear on a screen. At each flash, report the largest number of circles a straight line can cross. A line crosses a circle when they share two points, so a tangent does not count.

The first line gives M events. A line `1 x y r` adds a circle, `2 i` removes the i-th circle that ever appeared, and `3` is a flash. Coordinates and radii have at most two decimals. Print one integer per flash.

| item | bound |
|---|---|
| events M | 1 to 1000 |
| circles on screen | at most 100 |
| coordinates and radius | -1000000 to 1000000, radius positive |
| judge limit | 7929 ms, 1536 MB |

No two on-screen circles share a point, and no line touches three circles.

Sample input:

```
9
1 3.00 0.00 1.00
1 -2.00 0.00 1.00
3
1 2.00 3.00 1.50
3
1 2.00 -4.00 1.00
3
2 3
3
```

Sample output:

```
2
2
3
2
```

## Idea

Rotate a line tangent to one circle and watch which other circles it crosses, like sweeping a ruler around a coin and counting the coins it touches. For a fixed circle, every other circle contributes a range of angles where the tangent crosses it. Sweeping those ranges finds the best line for that circle. Trying all pairs of common tangents misses nested circles; the angle sweep handles them. The takeaway is that tangency turns a 2D search into a 1D interval sweep.

## Why It Works

1. Any best line can be shifted until it becomes tangent to a circle without losing crossings.
2. A tangent to circle C has one angle parameter around its normal direction.
3. That tangent crosses circle i exactly when the center distance from the line is below i's radius.
4. The condition reduces to a cosine bound, which gives at most two angle intervals.
5. A nested circle gives either every angle or no angle, handled by the same bounds.
6. The deepest overlap of those intervals plus circle C is the answer for C.

| term | meaning |
|---|---|
| `centerDistance` | distance between the two circle centers |
| `lowRatio` | lower cosine bound from the two radii |
| `highRatio` | upper cosine bound from the two radii |
| `SweepEvent` | one interval start or end on the angle circle |
| `fullCount` | number of circles crossed at every angle |

Coordinates are scaled by 100, so all input values become integers before conversion to float.

A script trace of the third sample flash gives these numbers for the circle at (2,3):

```
other center (3,0)   radius 1.0  distance 3.162
other center (-2,0)  radius 1.0  distance 5.000
other center (2,-4)  radius 1.0  distance 7.000
best overlap of angle intervals plus this circle gives 3
```

The script value 3 matches the printed sample answer.

## Code

**Input and scanner.** Decimals are read as integers scaled by 100.

```nim
import algorithm
import math

const flushBlockBytes = 1 shl 17
const scaleFactor = 100
const fullTurn = 2.0 * PI
const angleTolerance = 1.0e-12

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

proc nextScaled(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var wholePart = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    wholePart = wholePart * 10 + int(data[pos]) - 48
    pos += 1
  var fractionPart = 0
  var fractionDigits = 0
  if pos < data.len and data[pos] == '.':
    pos += 1
    while pos < data.len and fractionDigits < 2 and data[pos] >= '0' and data[pos] <= '9':
      fractionPart = fractionPart * 10 + int(data[pos]) - 48
      fractionDigits += 1
      pos += 1
  while fractionDigits < 2:
    fractionPart = fractionPart * 10
    fractionDigits += 1
  let scaledValue = wholePart * scaleFactor + fractionPart
  if negative:
    return -scaledValue
  return scaledValue
```

The fraction reader pads one decimal digit with a zero.
The minus branch handles negative centers.
The event kind still uses the integer scanner.

**Output buffer and events.** Sorted events carry interval boundaries.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

type SweepEvent = tuple[angle: float, delta: int]

proc compareEvents(left: SweepEvent, right: SweepEvent): int =
  if left.angle < right.angle:
    return -1
  elif left.angle > right.angle:
    return 1
  return 0

proc addAngleInterval(startAngle: float, endAngle: float,
                      events: var seq[SweepEvent], fullCount: var int) =
  var startNormalized = startAngle mod fullTurn
  var endNormalized = endAngle mod fullTurn
  if startNormalized < 0:
    startNormalized = startNormalized + fullTurn
  if endNormalized < 0:
    endNormalized = endNormalized + fullTurn
  if startNormalized < endNormalized:
    events.add((startNormalized, 1))
    events.add((endNormalized, -1))
  elif startNormalized > endNormalized:
    events.add((0.0, 1))
    events.add((endNormalized, -1))
    events.add((startNormalized, 1))
    events.add((fullTurn, -1))
  else:
    fullCount += 1
```

Wrapping intervals split at zero.
Each event carries a start or an end.
The comparator sorts by angle only.

**Angle sweep.** Each circle contributes two intervals per other circle.

```nim
proc bestAtFlash(activeCircles: seq[int], circleXs: seq[int],
                 circleYs: seq[int], circleRs: seq[int]): int =
  let circleCount = activeCircles.len
  if circleCount == 0:
    return 0
  var bestTotal = 1
  for centerIndex in 0 .. circleCount - 1:
    let centerCircle = activeCircles[centerIndex]
    let centerX = float(circleXs[centerCircle])
    let centerY = float(circleYs[centerCircle])
    let centerRadius = float(circleRs[centerCircle])
    var events = newSeq[SweepEvent]()
    var fullCount = 0
    for otherIndex in 0 .. circleCount - 1:
      if otherIndex == centerIndex:
        continue
      let otherCircle = activeCircles[otherIndex]
      let deltaX = float(circleXs[otherCircle]) - centerX
      let deltaY = float(circleYs[otherCircle]) - centerY
      let centerDistance = sqrt(deltaX * deltaX + deltaY * deltaY)
      let otherRadius = float(circleRs[otherCircle])
      if centerDistance < angleTolerance:
        if otherRadius > centerRadius:
          fullCount += 1
        continue
      let lowRatio = (centerRadius - otherRadius) / centerDistance
      let highRatio = (centerRadius + otherRadius) / centerDistance
      if lowRatio > 1.0 + angleTolerance:
        continue
      if highRatio > 1.0 + angleTolerance:
        fullCount += 1
        continue
      let directionAngle = arctan2(deltaY, deltaX)
      let lowAngle = arccos(max(-1.0, min(1.0, lowRatio)))
      let highAngle = arccos(max(-1.0, min(1.0, highRatio)))
      addAngleInterval(directionAngle + highAngle, directionAngle + lowAngle, events, fullCount)
      addAngleInterval(directionAngle + fullTurn - lowAngle,
                       directionAngle + fullTurn - highAngle, events, fullCount)
    sort(events, compareEvents)
    var depth = fullCount
    var localBest = depth
    var eventIndex = 0
    while eventIndex < events.len:
      let eventAngle = events[eventIndex].angle
      while eventIndex < events.len and events[eventIndex].angle == eventAngle:
        depth = depth + events[eventIndex].delta
        eventIndex += 1
      if depth > localBest:
        localBest = depth
    let candidate = localBest + 1
    if candidate > bestTotal:
      bestTotal = candidate
  return bestTotal
```

The cosine bounds use the non-overlap guarantee.
Nested circles add a full interval or none.
The sweep reads depth after each group of equal angles.

**Event loop.** The driver maintains the active circles and answers flashes.

```nim
let eventCount = nextInt(inputData, scanPos)
var circleXs = newSeq[int]()
var circleYs = newSeq[int]()
var circleRs = newSeq[int]()
var activeFlags = newSeq[bool]()
for eventIndex in 0 .. eventCount - 1:
  let eventKind = nextInt(inputData, scanPos)
  if eventKind == 1:
    circleXs.add(nextScaled(inputData, scanPos))
    circleYs.add(nextScaled(inputData, scanPos))
    circleRs.add(nextScaled(inputData, scanPos))
    activeFlags.add(true)
  elif eventKind == 2:
    let circleIndex = nextInt(inputData, scanPos) - 1
    activeFlags[circleIndex] = false
  else:
    var activeCircles = newSeq[int]()
    for circleIndex in 0 .. activeFlags.len - 1:
      if activeFlags[circleIndex]:
        activeCircles.add(circleIndex)
    appendOutput($bestAtFlash(activeCircles, circleXs, circleYs, circleRs))
    outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Circle indexes follow the order of appearance.
Removed circles stay in the arrays with a cleared flag.
The final write emits the buffered answers.

## Complexity

Each flash sweeps angles for every active circle.

| phase | time | space |
|---|---|---|
| input read | one pass over events | one input string |
| circle state | one update per event | active flags and circle data |
| angle sweep | O(c squared log c) per flash | two events per circle pair |
| output | one buffered write per block | block buffer |

At most 100 circles are active, so each sweep stays small.

| measure | Big O |
|---|---|
| time | O(M times c squared log c) worst case |
| space | O(M + c) beyond the input string |

Enumerating all common tangents would take comparable time but misses nested circles.
The angle sweep covers both disjoint and nested sets.
