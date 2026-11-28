# CERC07C — Cell Phone (SPOJ)

<https://www.spoj.com/problems/CERC07C/>

## Problem

Place one circle of radius `R` to cover as many given points of interest as possible. The center may sit anywhere, including between points; report the largest covered count per scenario.

Each scenario starts with `N` and `R`, where `1 <= N <= 2000` and `0 <= R < 10000`, followed by `N` distinct coordinate pairs with `|X|, |Y| < 10000`. A blank line follows each scenario, and `0 0` ends the input. Print `It is possible to cover M points.` for each scenario.

| item | bound |
|---|---|
| points N | 1 to 2000 |
| radius R | 0 to 9999 |
| coordinates | -9999 to 9999 |
| judge limit | 3196 ms, 1536 MB |

Points exactly on the circle boundary count as covered, and the input avoids borderline floating cases.

Sample input:

```
8 2
1 2
5 3
5 4
1 4
8 2
4 5
7 5
3 3

2 100
0 100
0 -100

0 0
```

Sample output:

```
It is possible to cover 4 points.
It is possible to cover 2 points.
```

## Idea

Keep one point pinned on the circle edge and swing the center around it, like rotating a door hinge. A second point stays inside for a range of swing angles, so it becomes an angular interval. Finding the best circle through the pinned point is then finding the deepest overlap of intervals. Try all pins and keep the best count. Checking every possible center would be continuous and unbounded; the pinned-point rule reduces the search to a sort of intervals.

## Why It Works

1. Any optimal circle can be moved until a covered point lies on its boundary.
2. Fixing that boundary point leaves a circle of possible centers at distance `R` from it.
3. A second point at distance `d` from the pin is covered when the center angle stays within `arccos(d / (2R))` of its direction.
4. That condition is one angle interval, no longer than 180 degrees.
5. The most overlapped interval point gives the most covered points for the pin.
6. Checking every pin covers every optimal circle.

| term | meaning |
|---|---|
| `anchorIndex` | point pinned on the circle boundary |
| `spread` | half-width of one center-angle interval |
| `direction` | angle from the anchor to another point, shifted positive |
| `AngleEvent` | interval start or end at one angle |
| `bestCoverage` | largest count found over all anchors |

The angle shift keeps all intervals on one positive scale for sorting.

Intervals around anchor `(1, 2)` with `R = 2`:

```
point (1, 4)   distance 2    spread 60 degrees   interval 30 to 150
point (3, 3)   distance 2.24 spread 63 degrees   interval -18 to 108
deepest overlap   3 other points
covered total     3 + anchor = 4
```

The trace matches the first sample answer.

## Code

**Input and event order.** A signed scanner reads coordinates, and starts sort before ends.

```nim
import algorithm
import math

const flushBlockBytes = 1 shl 17
const turn = 6.283185307179586476925

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextSigned(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value

type AngleEvent = tuple[angle: float64, kind: int]

proc compareEvents(left: AngleEvent, right: AngleEvent): int =
  if left.angle < right.angle:
    return -1
  if left.angle > right.angle:
    return 1
  if left.kind > right.kind:
    return -1
  if left.kind < right.kind:
    return 1
  return 0

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Negative coordinates need the minus branch in the scanner.
A start event wins a tie so a boundary point is counted.
The small radius epsilon absorbs rounding at the boundary.

**Angular sweep.** Each anchor produces four events per nearby point.

```nim
while true:
  let pointCount = nextSigned(inputData, scanPos)
  let reach = nextSigned(inputData, scanPos)
  if pointCount == 0 and reach == 0:
    break
  var pointXs = newSeq[int](pointCount)
  var pointYs = newSeq[int](pointCount)
  for pointIndex in 0 .. pointCount - 1:
    pointXs[pointIndex] = nextSigned(inputData, scanPos)
    pointYs[pointIndex] = nextSigned(inputData, scanPos)
  let effectiveRadius = float64(reach) + 0.0000001
  let reachLimit = 2.0 * effectiveRadius
  let reachLimitSquared = reachLimit * reachLimit
  var bestCoverage = 1
  for anchorIndex in 0 .. pointCount - 1:
    var events: seq[AngleEvent] = @[]
    for otherIndex in 0 .. pointCount - 1:
      if otherIndex == anchorIndex:
        continue
      let deltaX = float64(pointXs[otherIndex] - pointXs[anchorIndex])
      let deltaY = float64(pointYs[otherIndex] - pointYs[anchorIndex])
      let distanceSquared = deltaX * deltaX + deltaY * deltaY
      if distanceSquared > reachLimitSquared:
        continue
      let distance = sqrt(distanceSquared)
      var ratio = distance / reachLimit
      if ratio > 1.0:
        ratio = 1.0
      let spread = arccos(ratio)
      let direction = arctan2(deltaY, deltaX) + turn
      let leftAngle = direction - spread
      let rightAngle = direction + spread
      events.add (leftAngle, 1)
      events.add (rightAngle, 0)
      events.add (leftAngle + turn, 1)
      events.add (rightAngle + turn, 0)
    events.sort(compareEvents)
    var activeCoverage = 0
    var bestHere = 0
    for event in events:
      if event.kind == 1:
        activeCoverage += 1
        if activeCoverage > bestHere:
          bestHere = activeCoverage
      else:
        activeCoverage -= 1
    let totalCoverage = bestHere + 1
    if totalCoverage > bestCoverage:
      bestCoverage = totalCoverage
  appendOutput("It is possible to cover " & $bestCoverage & " points.")
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Points farther than twice the radius cannot share a circle with the anchor.
Duplicated events shifted by one turn handle wraparound at angle zero.
The sweep adds the anchor to the deepest overlap.

## Complexity

Each anchor sorts at most twice the number of points.

| phase | time | space |
|---|---|---|
| input read | one pass over coordinate text | one input string |
| interval build | one pair check per point pair | event list per anchor |
| sweep | one sort and one pass per anchor | event list |
| output | one write per block | block buffer |

Sorting dominates, and it repeats once for each anchor.

| measure | Big O |
|---|---|
| time per scenario | O(N^2 log N) |
| space | O(N) |

Checking candidate centers without angular intervals would need a pass over every point for every candidate. The sweep turns those checks into a sort of short intervals.
