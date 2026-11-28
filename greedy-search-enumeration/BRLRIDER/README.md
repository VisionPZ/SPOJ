# BRLRIDER — Barrelrider (SPOJ)

<https://www.spoj.com/problems/BRLRIDER/>

## Problem

Compute the share of viewing directions blocked by circular obstacles around a point, then round that share to the nearest whole percent. Each obstacle hides a wedge of angles whose size depends on its radius and distance.

The first line gives N, the number of obstacles. Each next line gives three integers: the center coordinates X and Y, and the radius R. Bilbo stands at the origin. Print the total concealment as a percentage with a percent sign.

| item | bound |
|---|---|
| obstacles N | between 0 and 1000 |
| center coordinates | between -5000 and 5000 |
| radius R | between 1 and 1000 |
| judge limit | 1000 ms, 1536 MB |

Obstacles may overlap, and their hidden wedges must be counted once.

The sample input:

```
1
2 2 2
```

The sample output:

```
25%
```

## Idea

Turn each circle into an angle interval and union the intervals like merging overlapping shifts in a schedule. The two tangent lines from the origin define the wedge; if the origin lies inside the circle, every direction is hidden.

The algorithm computes a half angle with arcsin of radius over distance. It centers that wedge at the polar angle of the circle, splits wedges that cross zero, sorts them, and sweeps once to measure their union. A ray-by-ray scan would check thousands of directions against every circle, while one sweep handles all circles in one sort.

One angular sweep gives the exact rounded percentage.

## Why It Works

1. A circle at distance d with radius r hides the wedge between its two tangent rays from the origin.
2. When d is below r, the origin sits inside the circle and all 360 degrees are hidden.
3. When d equals r, the half angle is 90 degrees, so the wedge spans 180 degrees.
4. The tangent half angle is arcsin(r/d), centered at the polar angle of the circle.
5. Sorting intervals and merging overlapping ones measures the union once, so overlaps add no extra concealment.

| term | meaning |
|---|---|
| `AngularInterval` | one hidden angular wedge |
| `halfAngle` | half of one circle's hidden wedge |
| `normalizedAngle` | angle wrapped into the range from zero to a full circle |
| `coveredAngle` | total radians hidden after merging |
| `fullyHidden` | flag set when the origin lies inside a circle |

Rounding uses an added half before truncation, plus a small guard for binary error.

A script trace for single-circle cases:

```
(2,2) r=2 d=2.828 half=45.0 deg width=90.0 deg pct=25
(2,0) r=2 d=2.000 half=90.0 deg width=180.0 deg pct=50
(1,0) r=2 d=1.000 inside full=360 deg pct=100
(0,5) r=2 d=5.000 half=23.6 deg width=47.2 deg pct=13
```

The first row matches the sample output of 25 percent.

## Code

**Input, angle helpers, and sorting.** The scanner keeps the minus sign needed by negative coordinates.

```nim
import algorithm
import math

const flushBlockBytes = 1 shl 17
const fullCircle = 2 * PI

type AngularInterval = object
  startAngle: float
  endAngle: float

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  var numberSign = 1
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    if data[pos] == '-':
      numberSign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return numberSign * value

proc normalizedAngle(angle: float): float =
  var wrappedAngle = angle mod fullCircle
  if wrappedAngle < 0:
    wrappedAngle += fullCircle
  return wrappedAngle

proc compareIntervals(left, right: AngularInterval): int =
  if left.startAngle < right.startAngle:
    return -1
  if left.startAngle > right.startAngle:
    return 1
  if left.endAngle < right.endAngle:
    return -1
  if left.endAngle > right.endAngle:
    return 1
  return 0
```

`numberSign` preserves negative centers, which flip the obstacle's polar angle.
`normalizedAngle` wraps a wedge that crosses the zero direction.
`compareIntervals` gives the sort the order needed by the sweep.

**Wedge construction and union sweep.** Each circle adds one or two intervals, then one pass measures the union.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let obstacleCount = nextInt(inputData, scanPos)
var intervals = newSeq[AngularInterval]()
var fullyHidden = false
for obstacleIndex in 0 .. obstacleCount - 1:
  let centerX = nextInt(inputData, scanPos)
  let centerY = nextInt(inputData, scanPos)
  let radius = nextInt(inputData, scanPos)
  let distanceSquared = centerX * centerX + centerY * centerY
  let distance = sqrt(float(distanceSquared))
  if distance < float(radius):
    fullyHidden = true
    break
  let ratio = float(radius) / distance
  let halfAngle = arcsin(ratio)
  let middleAngle = arctan2(float(centerY), float(centerX))
  let leftAngle = normalizedAngle(middleAngle - halfAngle)
  let rightAngle = normalizedAngle(middleAngle + halfAngle)
  if leftAngle <= rightAngle:
    intervals.add(AngularInterval(startAngle: leftAngle, endAngle: rightAngle))
  else:
    intervals.add(AngularInterval(startAngle: 0.0, endAngle: rightAngle))
    intervals.add(AngularInterval(startAngle: leftAngle, endAngle: fullCircle))

if fullyHidden:
  appendOutput("100%\n")
else:
  intervals.sort(compareIntervals)
  var coveredAngle = 0.0
  if intervals.len > 0:
    var currentStart = intervals[0].startAngle
    var currentEnd = intervals[0].endAngle
    for intervalIndex in 1 .. intervals.len - 1:
      let interval = intervals[intervalIndex]
      if interval.startAngle <= currentEnd:
        if interval.endAngle > currentEnd:
          currentEnd = interval.endAngle
      else:
        coveredAngle += currentEnd - currentStart
        currentStart = interval.startAngle
        currentEnd = interval.endAngle
    coveredAngle += currentEnd - currentStart
  let percentage = int(coveredAngle / fullCircle * 100.0 + 0.5 + 1e-9)
  appendOutput($percentage & "%\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

A circle containing the origin ends the loop with full concealment.
A wedge crossing zero becomes two intervals at the range ends.
The sweep adds each merged interval once, so overlaps count once.

## Complexity

One wedge per obstacle enters one sort and one sweep.

| phase | time | space |
|---|---|---|
| input read | one pass over N triples | one input string |
| wedge build | one arcsin and one atan2 per obstacle | one interval per wedge |
| union | one sort and one sweep | interval array |
| output | one line | block buffer |

The sort dominates for large N.

| measure | Big O |
|---|---|
| time | O(N log N) |
| space | O(N) |

A ray sweep with many directions would multiply N by thousands of angles and lose precision at the rounding boundary.
