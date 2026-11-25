# MTRIAREA — Maximum Triangle Area (SPOJ)

<https://www.spoj.com/problems/MTRIAREA/>

## Problem

Pick three of the given points whose triangle has the largest area and print that area with two digits after the decimal point.

The first line of each case holds n. The next n lines hold integer coordinates x and y. A line with -1 ends the input. Print one area per case.

| Item | Bound |
|---|---|
| Points n | 1 to 50000 |
| Coordinates x and y | -10000 to 10000 |
| Input lines | until a line with -1 |
| Judge limit | 1000 ms, 1536 MB |

The largest triangle always uses hull vertices, so interior points do not affect the answer.

Sample input:

```
3
3 4
2 6
2 7
5
2 6
3 9
2 0
8 0
6 5
-1
```

Sample output:

```
0.50
27.00
```

## Idea

Discarding interior points works like trimming the extra pins from a shape before measuring its widest span.

Build the convex hull with Andrew's monotonic chain, then rotate two inner indices along the hull for each first vertex. The cross product gives twice the area as an integer. Checking every triple of all n points would take cubic time. The hull scan touches far fewer points and uses exact integer arithmetic.

## Why It Works

1. Moving a triangle vertex to a hull vertex never shrinks its area.
2. A monotonic chain builds the hull in counterclockwise order.
3. For fixed first and second vertices, area grows then falls as the third vertex advances.
4. That shape lets the third index advance monotonically instead of restarting.
5. Twice the area is an integer cross product, so the printed part is either .00 or .50.

| Term | Meaning |
|---|---|
| `crossProduct` | signed doubled area of three points |
| `hullPoints` | convex hull vertices in counterclockwise order |
| `bestDoubleArea` | largest doubled area seen so far |
| `lowerSize` | hull size after the lower chain is built |

The table names the values that decide the final area.

A script trace for the first sample case:

```
points (3,4), (2,6), (2,7)
cross product = |(2-3)*(7-4) - (6-4)*(2-3)| = 1
twice area 1 is odd -> print 0.50
```

The trace matches the first sample line.

## Code

**Input and geometry helpers.** The scanner accepts negative coordinates, and the cross product stays in int64.

```nim
import algorithm

const flushBlockBytes = 1 shl 17

type Point = object
  x: int64
  y: int64

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] != '-' and (data[pos] < '0' or data[pos] > '9')):
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * value

proc comparePoints(leftPoint: Point, rightPoint: Point): int =
  if leftPoint.x < rightPoint.x:
    return -1
  if leftPoint.x > rightPoint.x:
    return 1
  if leftPoint.y < rightPoint.y:
    return -1
  if leftPoint.y > rightPoint.y:
    return 1
  return 0

proc crossProduct(originPoint: Point, firstPoint: Point, secondPoint: Point): int64 =
  return (firstPoint.x - originPoint.x) * (secondPoint.y - originPoint.y) - (firstPoint.y - originPoint.y) * (secondPoint.x - originPoint.x)

proc formatArea(doubleArea: int64): string =
  result = $(doubleArea div 2)
  if (doubleArea mod 2) == 0:
    result.add ".00\n"
  else:
    result.add ".50\n"
```

The minus branch reads negative coordinates and the -1 sentinel.
Sorting by x then y prepares the monotonic chain.
Doubled area avoids floating-point rounding.

**Hull construction.** The lower and upper chains drop every clockwise or collinear turn.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while scanPos < inputData.len:
  let pointCount = nextInt(inputData, scanPos)
  if pointCount == -1:
    break
  var sortedPoints = newSeq[Point](pointCount)
  for pointIndex in 0 .. pointCount - 1:
    sortedPoints[pointIndex].x = int64(nextInt(inputData, scanPos))
    sortedPoints[pointIndex].y = int64(nextInt(inputData, scanPos))
  sortedPoints.sort(comparePoints)
  var hullPoints = newSeq[Point](pointCount * 2)
  var hullSize = 0
  for pointIndex in 0 .. pointCount - 1:
    while hullSize >= 2 and crossProduct(hullPoints[hullSize - 2], hullPoints[hullSize - 1], sortedPoints[pointIndex]) <= 0:
      hullSize -= 1
    hullPoints[hullSize] = sortedPoints[pointIndex]
    hullSize += 1
  let lowerSize = hullSize
  for pointIndex in countDown(pointCount - 2, 0):
    while hullSize > lowerSize and crossProduct(hullPoints[hullSize - 2], hullPoints[hullSize - 1], sortedPoints[pointIndex]) <= 0:
      hullSize -= 1
    hullPoints[hullSize] = sortedPoints[pointIndex]
    hullSize += 1
  hullSize -= 1
```

Collinear points on an edge are removed for a strict hull.
The upper chain runs backward from the last sorted point.
The final duplicate corner is removed after both chains finish.

**Rotating scan.** For each first vertex, the third index only moves forward.

```nim
  var bestDoubleArea: int64 = 0
  if hullSize >= 3:
    var firstIndex = 0
    while firstIndex <= hullSize - 3:
      var secondIndex = firstIndex + 1
      var thirdIndex = firstIndex + 2
      while secondIndex <= hullSize - 2:
        while thirdIndex + 1 <= hullSize - 1 and crossProduct(hullPoints[firstIndex], hullPoints[secondIndex], hullPoints[thirdIndex + 1]) > crossProduct(hullPoints[firstIndex], hullPoints[secondIndex], hullPoints[thirdIndex]):
          thirdIndex += 1
        let areaValue = crossProduct(hullPoints[firstIndex], hullPoints[secondIndex], hullPoints[thirdIndex])
        if areaValue > bestDoubleArea:
          bestDoubleArea = areaValue
        secondIndex += 1
      firstIndex += 1
  appendOutput(formatArea(bestDoubleArea))

stdout.write outputBuffer
outputBuffer.setLen 0
```

The third index is reused across second vertices.
The largest doubled area becomes the printed answer.
One buffered write handles all result lines.

## Complexity

Sorting dominates small hulls; the hull scan dominates large ones.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over coordinate lines | one input string |
| Sort and hull | n log n comparisons | two point arrays |
| Rotating scan | quadratic in hull size | constant |
| Output | buffered writes | block buffer |

The table shows that hull size drives the geometry cost.

| Measure | Big O |
|---|---|
| Time | O(n log n + h^2), h hull vertices |
| Space | O(n) |

Testing all triples of all n points would cost O(n^3) time.
