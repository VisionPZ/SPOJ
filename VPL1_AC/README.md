# VPL1_AC — Late Summer Searching (SPOJ)

<https://www.spoj.com/problems/VPL1_AC/>

## Problem

Decide whether every antenna can see every other antenna, ignoring interference disks of radius R around all other antennas. If the system works, report the smallest area that encloses the antennas and their lines of sight, rounded to two decimals. Otherwise report the words NO CONTEST.

Input starts with a test count. Each test gives the antenna count N and the radius R, followed by N minus one coordinate pairs. The first antenna sits at the origin. Output one line per test with the area or NO CONTEST.

| item | bound |
|---|---|
| tests | 1 to 100 |
| antennas N | 3 to 100 |
| radius R | 1 to 10 |
| coordinates | -500 to 500 |
| judge limit | 1000 ms, 1536 MB |

Cubic visibility checks and a small convex hull fit these bounds.

Sample input:

```
2
4 1
2 0
2 2
0 2
5 1
2 0
2 2
0 2
1 1
```

Sample output:

```
4.00
NO CONTEST
```

The center antenna in the second case sits on both diagonals and blocks them.

## Idea

Think of a laser between two antennas and a hula hoop of radius R around each other antenna. The link works only when no hoop touches the laser. Test every ordered pair of antennas against every third antenna using an exact squared-distance test. When all links work, the smallest enclosing region is the convex hull of the antenna positions. Testing pairs with floating point geometry is slower and less stable than integer squared distances. Keep the visibility test exact, then take the hull area.

## Why It Works

1. A third antenna blocks a link when its distance to the link segment is below R.
2. Squaring both sides removes square roots from the comparison.
3. The nearest point on a segment is an endpoint when the projection falls outside it.
4. Inside the segment, the perpendicular distance uses the cross product divided by the segment length.
5. Every line of sight lies inside the convex hull of the antenna points.
6. The shoelace sum of the hull gives twice the area as an integer, so two decimals are exact.

| term | meaning |
|---|---|
| `blocksView` | exact test for one antenna blocking one link |
| `radiusSquared` | interference radius squared |
| `turnValue` | cross product used by the hull |
| `lowerHull` | bottom chain of the hull |
| `upperHull` | top chain of the hull |
| `doubledArea` | absolute shoelace sum, twice the area |

Integer arithmetic keeps the visibility decision stable at tangency.

A trace of the first sample case:

```
pair (0,0)-(2,2), third (2,0) distance squared 2, radius squared 1
pair (0,0)-(2,2), third (0,2) distance squared 2, radius squared 1
pair (2,0)-(0,2), third (0,0) distance squared 2, radius squared 1
shoelace sum 8, doubled area 8
area 8 / 2 = 4.00
```

All links survive, and the hull of the square has area four.

## Code

**Reader and geometry helpers.** The reader places the first antenna at the origin and defines exact predicates.

```nim
const flushBlockBytes = 1 shl 17

type GridPoint = tuple[x: int, y: int]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var negativeValue = false
  if pos < data.len and data[pos] == '-':
    negativeValue = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negativeValue:
    return -value
  return value
```

The hand scanner keeps the minus sign for negative coordinates.
Only N minus one positions are read from the input.
All geometry below stays in integer arithmetic.

```nim
proc turnValue(first: GridPoint, second: GridPoint, third: GridPoint): int64 =
  return int64(second.x - first.x) * int64(third.y - first.y) -
         int64(second.y - first.y) * int64(third.x - first.x)

proc squaredDistance(first: GridPoint, second: GridPoint): int64 =
  let deltaX = int64(second.x - first.x)
  let deltaY = int64(second.y - first.y)
  return deltaX * deltaX + deltaY * deltaY

proc blocksView(observer: GridPoint, first: GridPoint, second: GridPoint,
                radiusSquared: int64): bool =
  let deltaX = int64(second.x - first.x)
  let deltaY = int64(second.y - first.y)
  let lengthSquared = deltaX * deltaX + deltaY * deltaY
  if lengthSquared == 0:
    return true
  let observerX = int64(observer.x - first.x)
  let observerY = int64(observer.y - first.y)
  let projection = observerX * deltaX + observerY * deltaY
  if projection <= 0:
    return squaredDistance(observer, first) < radiusSquared
  if projection >= lengthSquared:
    return squaredDistance(observer, second) < radiusSquared
  let crossProduct = deltaX * observerY - deltaY * observerX
  return crossProduct * crossProduct < radiusSquared * lengthSquared

proc appendArea(hundredths: int64) =
  appendOutput($int(hundredths div 100))
  appendOutput(".")
  let fractionPart = hundredths mod 100
  if fractionPart < 10:
    appendOutput("0")
  appendOutput($fractionPart)
  outputBuffer.add '\n'
```

Projection outside the segment uses the nearer endpoint.
Projection inside uses the cross product squared.
The area printer writes exact hundredths with no float rounding.

**Visibility loop.** Every pair is checked against every third antenna.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let antennaCount = nextInt(inputData, scanPos)
  let radius = nextInt(inputData, scanPos)
  var antennaPoints = newSeq[GridPoint](antennaCount)
  antennaPoints[0] = (x: 0, y: 0)
  for antennaIndex in 1 .. antennaCount - 1:
    let pointX = nextInt(inputData, scanPos)
    let pointY = nextInt(inputData, scanPos)
    antennaPoints[antennaIndex] = (x: pointX, y: pointY)
  let radiusSquared = int64(radius) * int64(radius)
  var visibilityFails = false
  for firstAntenna in 0 .. antennaCount - 1:
    for secondAntenna in firstAntenna + 1 .. antennaCount - 1:
      for thirdAntenna in 0 .. antennaCount - 1:
        if thirdAntenna == firstAntenna or thirdAntenna == secondAntenna:
          continue
        if blocksView(antennaPoints[thirdAntenna], antennaPoints[firstAntenna],
                      antennaPoints[secondAntenna], radiusSquared):
          visibilityFails = true
          break
      if visibilityFails:
        break
    if visibilityFails:
      break
  if visibilityFails:
    appendOutput("NO CONTEST")
    outputBuffer.add '\n'
    continue
```

The first failing link ends the case early.
Endpoints of a link are excluded as observers.
One blocked pair is enough to reject the whole system.

**Hull area.** A monotone chain builds the hull, then the shoelace sum gives the area.

```nim
  for outerIndex in 1 .. antennaCount - 1:
    let heldPoint = antennaPoints[outerIndex]
    var innerIndex = outerIndex
    while innerIndex > 0:
      let previousPoint = antennaPoints[innerIndex - 1]
      if previousPoint.x < heldPoint.x or
         (previousPoint.x == heldPoint.x and previousPoint.y < heldPoint.y):
        break
      antennaPoints[innerIndex] = previousPoint
      innerIndex -= 1
    antennaPoints[innerIndex] = heldPoint
  var lowerHull = newSeq[GridPoint]()
  for pointIndex in 0 .. antennaCount - 1:
    let currentPoint = antennaPoints[pointIndex]
    while lowerHull.len >= 2:
      let secondLast = lowerHull[lowerHull.len - 2]
      let lastPoint = lowerHull[lowerHull.len - 1]
      if turnValue(secondLast, lastPoint, currentPoint) > 0:
        break
      lowerHull.setLen(lowerHull.len - 1)
    lowerHull.add currentPoint
  var upperHull = newSeq[GridPoint]()
  for pointIndex in countdown(antennaCount - 1, 0):
    let currentPoint = antennaPoints[pointIndex]
    while upperHull.len >= 2:
      let secondLast = upperHull[upperHull.len - 2]
      let lastPoint = upperHull[upperHull.len - 1]
      if turnValue(secondLast, lastPoint, currentPoint) > 0:
        break
      upperHull.setLen(upperHull.len - 1)
    upperHull.add currentPoint
  lowerHull.setLen(lowerHull.len - 1)
  upperHull.setLen(upperHull.len - 1)
  lowerHull.add upperHull
  var doubledArea: int64 = 0
  for hullIndex in 0 .. lowerHull.len - 1:
    let currentPoint = lowerHull[hullIndex]
    let nextPoint = lowerHull[(hullIndex + 1) mod lowerHull.len]
    doubledArea += int64(currentPoint.x) * int64(nextPoint.y) -
                   int64(nextPoint.x) * int64(currentPoint.y)
  if doubledArea < 0:
    doubledArea = -doubledArea
  appendArea(doubledArea * 50)
stdout.write outputBuffer
outputBuffer.setLen 0
```

An insertion sort orders points by x, then y.
Collinear middle points are dropped from both chains.
Doubled area times fifty gives exact hundredths.

## Complexity

Visibility dominates the work; the hull is cheap for one hundred points.

| phase | time | space |
|---|---|---|
| input read | one pass over coordinates | one input string |
| visibility | one distance test per ordered triple | point array |
| hull | one sort and two chains | two hull arrays |
| output | one buffered write per block | one output string |

A blocked link skips the hull work for that case.

| measure | Big O |
|---|---|
| time | O(n^3) per case |
| space | O(n) |

Using floating point distances for every triple would cost more and risk boundary errors.
Keep the visibility test in squared integers, then compute the hull area exactly.
