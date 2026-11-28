# GNY07G — Model Rocket Height (SPOJ)

<https://www.spoj.com/problems/GNY07G/>

## Problem

Two observers sight a smoke puff with an elevation angle and an azimuth angle. Use their sight lines to find the height of the puff above the launch platform, or reject the shot.

The first line holds the number of shots. The second line holds five decimal values: baseline distance D, platform distance L, device heights HA and HB, and distance limit ERRDIST. Each later line holds four angles: α, β, γ, δ in degrees. Each answer line holds the shot number and either `DISQUALIFIED`, `ERROR`, or the rounded height.

| item | bound |
|---|---|
| shots | 1 to 1000 |
| angles α, β, γ | strictly between 0 and 90 degrees |
| angle δ | strictly between 90 and 180 degrees |
| judge limit | 1000 ms, 1536 MB |

The platform distance L is read but does not enter the height formula.

Sample input:

```
4
100.0 300.0 5.25 2.92 5.00
40.1 36.2 35.3 151.6
64.9 71.1 15.7 160.1
44.9 41.2 33.1 152.5
44.9 41.2 33.1 52.5
```

Sample output:

```
1 50
2 ERROR
3 58
4 DISQUALIFIED
```

## Idea

Find where two vertical sight planes cross, then read the height of each ray at that crossing, like locating a flagpole from two compass bearings. Each sight line spans a vertical plane through its observer. Two planes cross in one vertical line. Each ray meets that line at its own height. Their gap must fit ERRDIST. The reported height is the midpoint of those two heights. Testing every point on a grid would be far slower than solving two lines directly.

## Why It Works

1. Put the origin midway between observers, with the baseline as the x axis.
2. The observers sit at x = -D/2 and x = +D/2, and both have y = 0.
3. A sight line has horizontal direction (cos α cos γ, cos α sin γ) for observer A.
4. Its vertical plane obeys x·dy - y·dx = xa·dy, so two such planes fix x and y.
5. The ray distance to (x, y) gives the height along each ray.
6. A gap above ERRDIST triggers `ERROR`; the mean height is rounded to the nearest foot.

| term | meaning |
|---|---|
| `directionXA`, `directionYA` | horizontal direction of the ray from A |
| `planeA` | right side of the vertical plane equation for A |
| `denominator` | determinant of the two plane equations |
| `sightHeightA` | height where ray A meets the crossing line |

The plane equations turn two angle pairs into one crossing point.

The generator traces the first sample shot with explicit numbers:

| quantity | value |
|---|---|
| crossing x | -6.7004 feet |
| crossing y | 30.6578 feet |
| ray A height | 49.9258 feet |
| ray B height | 50.0962 feet |
| height gap | 0.1703 feet |
| rounded midpoint | 50 feet |

The gap stays below 5 feet, so the printed answer is 50.

## Code

**Input and number parsing.** The reader loads all tokens and parses decimals by hand.

```nim
import math

const flushBlockBytes = 1 shl 17
const angleEpsilon = 0.01

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

proc nextFloat(data: string, pos: var int): float =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '.':
    pos += 1
  var value = 0.0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10.0 + float(int(data[pos]) - 48)
    pos += 1
  if pos < data.len and data[pos] == '.':
    pos += 1
    var place = 0.1
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      value = value + float(int(data[pos]) - 48) * place
      place = place * 0.1
      pos += 1
  return value
```

The scanner accepts digits and one decimal point.
All input values are positive, so no sign branch is needed.
Token parsing ignores line breaks and extra spaces.

**Setup and output buffer.** Global values are read once before the shots.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
let baselineSpan = nextFloat(inputData, scanPos)
let platformOffset = nextFloat(inputData, scanPos)
let deviceHeightA = nextFloat(inputData, scanPos)
let deviceHeightB = nextFloat(inputData, scanPos)
let errorLimit = nextFloat(inputData, scanPos)
let radiansPerDegree = arctan2(1.0, 1.0) / 45.0
let observerA = -baselineSpan * 0.5
let observerB = baselineSpan * 0.5
```

The angle scale is π divided by 180.
Observers are symmetric around the origin.
The buffer flushes in large blocks.

**Sight plane intersection.** Each shot becomes two plane equations and two heights.

```nim
for caseIndex in 1 .. caseCount:
  let elevationA = nextFloat(inputData, scanPos)
  let elevationB = nextFloat(inputData, scanPos)
  let azimuthA = nextFloat(inputData, scanPos)
  let azimuthB = nextFloat(inputData, scanPos)
  appendOutput($(caseIndex))
  outputBuffer.add ' '
  if elevationA <= 0.0 or elevationA >= 90.0 or elevationB <= 0.0 or elevationB >= 90.0 or azimuthA <= 0.0 or azimuthA >= 90.0 or azimuthB <= 90.0 or azimuthB >= 180.0:
    appendOutput("DISQUALIFIED")
    outputBuffer.add '\n'
    continue
  let cosElevationA = cos(radiansPerDegree * elevationA)
  let sinElevationA = sin(radiansPerDegree * elevationA)
  let cosElevationB = cos(radiansPerDegree * elevationB)
  let sinElevationB = sin(radiansPerDegree * elevationB)
  let cosAzimuthA = cos(radiansPerDegree * azimuthA)
  let sinAzimuthA = sin(radiansPerDegree * azimuthA)
  let cosAzimuthB = cos(radiansPerDegree * azimuthB)
  let sinAzimuthB = sin(radiansPerDegree * azimuthB)
```

Angles outside their open intervals are rejected first.
Trigonometric values are shared by both plane equations.
Rejected shots emit one short line.

**Heights and verdict.** The intersection heights decide the verdict and answer.

```nim
  let directionXA = cosElevationA * cosAzimuthA
  let directionYA = cosElevationA * sinAzimuthA
  let directionZA = sinElevationA
  let directionXB = cosElevationB * cosAzimuthB
  let directionYB = cosElevationB * sinAzimuthB
  let directionZB = sinElevationB
  let planeA = observerA * directionYA
  let planeB = observerB * directionYB
  let denominator = directionYB * directionXA - directionYA * directionXB
  if abs(denominator) < angleEpsilon:
    appendOutput("DIV BY ZERO")
    outputBuffer.add '\n'
    continue
  let crossX = (planeB * directionXA - planeA * directionXB) / denominator
  let crossY = (planeB * directionYA - planeA * directionYB) / denominator
  var reachA = 0.0
  var reachB = 0.0
  if abs(directionXA) >= abs(directionYA):
    reachA = (crossX - observerA) / directionXA
  else:
    reachA = crossY / directionYA
  if abs(directionXB) >= abs(directionYB):
    reachB = (crossX - observerB) / directionXB
  else:
    reachB = crossY / directionYB
  let sightHeightA = deviceHeightA + reachA * directionZA
  let sightHeightB = deviceHeightB + reachB * directionZB
  if abs(sightHeightA - sightHeightB) > errorLimit:
    appendOutput("ERROR")
  else:
    appendOutput($(int((sightHeightA + sightHeightB) * 0.5 + 0.5)))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The larger horizontal component avoids dividing by a tiny value.
The midpoint is rounded by adding 0.5 before the integer cast.
Every valid shot produces exactly one line.

## Complexity

Each shot needs a fixed number of trigonometric calls and arithmetic steps.

| phase | time | space |
|---|---|---|
| input read | one pass over all tokens | one input string |
| per shot | constant work | a few float values |
| output | one buffered line per shot | block buffer |

The cost grows linearly with the number of shots.

| measure | Big O |
|---|---|
| time | O(N) |
| space | O(N) for input text |

A grid search over candidate heights would take far longer than two plane equations. Solve once per shot and write the answer to the buffer.
