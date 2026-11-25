# FLATAND — A Classic Myth - Flatland Superhero (SPOJ)

<https://www.spoj.com/problems/FLATAND/>

## Problem

Find the smallest-area parallelogram that contains every point in a swarm, and print its area to four decimals. Each swarm is independent, and points sit on a plane with four decimal digits.

Input starts with the swarm count. Each swarm gives a point count and then one x and y per point. Coordinates lie between minus 1000 and 1000, and each point is unique in its swarm. Print Swarm i Parallelogram Area: X.XXXX for each swarm.

| item | bound |
|---|---|
| swarms | 1 to 20 |
| points per swarm | 4 to 1000 |
| coordinate range | -1000 to 1000, four decimals |
| judge limit | 100 ms, 1536 MB |

The point count sets the hull cost, and four decimals set the integer scale.

Sample input:

```
2
6
0.0000 0.0000
-0.5000 -0.5000
-1.0000 0.0000
-0.7000 -7.0000
-1.0000 -1.0000
0.0000 -1.0000
5
2.0000 2.0000
0.0000 0.0000
0.5000 2.0000
1.0000 1.0000
1.5000 0.0000
```

Sample output:

```
Swarm 1 Parallelogram Area: 7.0000
Swarm 2 Parallelogram Area: 3.0000
```

## Idea

Interior points never affect the answer, like loose ants inside a tight fence. Build the convex hull, then test side directions taken from hull edges. An optimal parallelogram has both pairs of sides parallel to hull edges, so a finite list of pairs covers every case.

Each pair costs a scan over hull vertices for two widths. Naive angular search samples infinitely many directions, while the hull list is short and exact.

Integer scaling keeps the hull stable before the final floating-point division.

## Why It Works

1. Scaling by 10000 turns every coordinate into an exact integer.
2. Points inside the convex hull cannot change any enclosing strip width.
3. A parallelogram is the intersection of two strips, one per pair of sides.
4. For normals `n` and `m`, its area is range(n) * range(m) / |det(n,m)|.
5. Moving an optimal side until it touches a vertex keeps the hull enclosed, so both side directions match hull edges.

| term | meaning |
|---|---|
| `convexHull` | outer vertices of the point set |
| `normalVectors` | vectors perpendicular to hull edges |
| `widths` | projection ranges of the hull along each normal |
| `areaScale` | factor that converts scaled area back to units |

The normals are not normalised; their lengths cancel in the area ratio.

The first sample swarm has area 7.0000, and the second has area 3.0000 from the oracle trace.

```
swarm 1 -> best edge pair -> area 7.0000
swarm 2 -> best edge pair -> area 3.0000
```

The trace matches both sample output lines.

## Code

**Input and scaling.** All input is read once, and fixed-point numbers become integers.

```nim
import algorithm
import strutils

const flushBlockBytes = 1 shl 17
const scaleFactor = 10000
const areaScale = 100000000.0
```

`nextInt` reads swarm and point counts.

`nextScaled` keeps four fractional digits as an integer remainder.

**Convex hull.** A monotone chain builds the outer vertices in order.

```nim
type
  Point = object
    x: int64
    y: int64

proc pointCompare(firstPoint, secondPoint: Point): int =
  if firstPoint.x < secondPoint.x:
    return -1
  if firstPoint.x > secondPoint.x:
    return 1
  if firstPoint.y < secondPoint.y:
    return -1
  if firstPoint.y > secondPoint.y:
    return 1
  return 0

proc crossProduct(originPoint, firstPoint, secondPoint: Point): int64 =
  return (firstPoint.x - originPoint.x) * (secondPoint.y - originPoint.y) -
         (firstPoint.y - originPoint.y) * (secondPoint.x - originPoint.x)
```

Cross products fit in 64 bits after scaling.

The comparator gives a stable order for equal coordinates.

```nim
proc convexHull(points: seq[Point]): seq[Point] =
  var sortedPoints = points
  sort(sortedPoints, pointCompare)
  var lowerHull = newSeq[Point]()
  for pointValue in sortedPoints:
    while lowerHull.len >= 2 and
          crossProduct(lowerHull[lowerHull.len - 2], lowerHull[lowerHull.len - 1],
                       pointValue) <= 0:
      lowerHull.setLen(lowerHull.len - 1)
    lowerHull.add pointValue
  var upperHull = newSeq[Point]()
  var pointIndex = sortedPoints.len - 1
  while pointIndex >= 0:
    let pointValue = sortedPoints[pointIndex]
    while upperHull.len >= 2 and
          crossProduct(upperHull[upperHull.len - 2], upperHull[upperHull.len - 1],
                       pointValue) <= 0:
      upperHull.setLen(upperHull.len - 1)
    upperHull.add pointValue
    pointIndex -= 1
  result = lowerHull
  for upperIndex in 1 .. upperHull.len - 2:
    result.add upperHull[upperIndex]
```

Lower and upper chains meet at the extreme points.

Collinear interior points are dropped during the chain build.

**Edge-pair scan.** Each pair of hull normals gives one candidate area.

```nim
  var normalVectors = newSeq[Point](hullSize)
  var widths = newSeq[int64](hullSize)
  for edgeIndex in 0 .. hullSize - 1:
    let firstPoint = hullPoints[edgeIndex]
    let secondPoint = hullPoints[(edgeIndex + 1) mod hullSize]
    let normalX = secondPoint.y - firstPoint.y
    let normalY = firstPoint.x - secondPoint.x
    normalVectors[edgeIndex].x = -normalX
    normalVectors[edgeIndex].y = -normalY
```

Each normal is perpendicular to one hull edge.

The sign of a normal does not change a projection range.

```nim
  var bestArea = 1e300
  for firstEdge in 0 .. hullSize - 1:
    for secondEdge in firstEdge + 1 .. hullSize - 1:
      let determinant = normalVectors[firstEdge].x * normalVectors[secondEdge].y -
                        normalVectors[firstEdge].y * normalVectors[secondEdge].x
      if determinant == 0:
        continue
      let candidateArea = float(widths[firstEdge]) * float(widths[secondEdge]) /
                          float(abs(determinant)) / areaScale
      if candidateArea < bestArea:
        bestArea = candidateArea
  return bestArea
```

Parallel normals cannot form a parallelogram.

The product is taken in floating point to avoid integer overflow.

## Complexity

The hull removes interior points before any pair is tested.

| phase | time | space |
|---|---|---|
| input read | one pass over all coordinates | input string |
| convex hull | one sort and two chains per swarm | hull array |
| edge-pair scan | one area per pair of hull edges | normal and width arrays |

The hull size, not the point count, drives the pair scan.

| measure | Big O |
|---|---|
| time | O(n log n + h^2) per swarm |
| space | O(n) per swarm |

Here n is the point count and h is the hull vertex count.

Sampling arbitrary angles cannot prove a minimum, while edge pairs give a finite exact list.
