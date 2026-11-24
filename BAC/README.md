## Problem

Each test case gives a rectangle plate and several bacterial samples at integer positions. All colonies grow at the same speed and stop where their fronts meet. A colony owns every point closer to its seed than to any other seed. Print each sample's id and owned area, ordered from largest area to smallest, with a blank line after each case.

| Quantity | Value |
| --- | --- |
| Plate width and height | 1 to 1000 |
| Samples per case | 1 to 100 |
| Test cases | about 20000 |
| Time limit | 1631 ms |
| Memory limit | 1536 MB |

## Idea

A colony's territory is its Voronoi cell, the region of points nearest to its seed. Start with the whole rectangle and cut it by each perpendicular bisector between the current seed and another seed. The remaining polygon is the cell. The shoelace formula turns that polygon into an area. Each cut reads only the current polygon's vertices, usually about six.

## Why It Works

The perpendicular bisector of two seeds is the line where their distances are equal. For seeds at `s` and `q`, the points owned by `s` satisfy `2p·(q−s) ≤ |q|² − |s|²`. Write this as `a*x + b*y ≤ c` with `a = 2(xq−xs)`, `b = 2(yq−ys)`, and `c = xq²+yq²−xs²−ys²`. Intersecting all these half-planes with the rectangle gives the cell exactly.

The program skips a bisector when the other seed lies beyond twice the cell's farthest vertex distance. If `|s−q| > 2R`, every point in the cell stays closer to `s`, so that bisector cannot cut.

A worked example uses the sample plate 10 by 10 with seeds at (5,5) and (0,0). For seed (0,0) the cut is `x+y ≤ 5`, leaving triangle (0,0), (5,0), (0,5) with area 12.50. For seed (5,5) the cut is `x+y ≥ 5`, leaving the square minus that triangle with area 87.50. The two areas add to 100, the plate area.

## Code

```nim
const
  maxSamples = 100
  maxPolygonVertices = maxSamples + 8
  flushBlockBytes = 1 shl 18

type
  Point = object
    x: float64
    y: float64

proc nextInt(inputData: string, i: var int): int =
  var value = 0
  while i < inputData.len and (inputData[i] < '0' or inputData[i] > '9'):
    inc i
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + (ord(inputData[i]) - 48)
    inc i
  value
```

The scanner skips blank lines and each non-digit byte between cases. It walks one buffer and allocates nothing. The loop ends at the first non-digit byte.

```nim
proc clipToHalfPlane(sourcePoly: array[maxPolygonVertices, Point], sourceCount: int,
                     destPoly: var array[maxPolygonVertices, Point], coefA: float64,
                     coefB: float64, coefC: float64): int =
  var outCount = 0
  var i = 0
  while i < sourceCount:
    let curPoint = sourcePoly[i]
    let nextPoint = sourcePoly[(i + 1) mod sourceCount]
    let curSide = coefC - (coefA * curPoint.x + coefB * curPoint.y)
    let nextSide = coefC - (coefA * nextPoint.x + coefB * nextPoint.y)
    if curSide >= 0:
      destPoly[outCount] = curPoint
      inc outCount
    if (curSide >= 0) != (nextSide >= 0):
      let ratio = curSide / (curSide - nextSide)
      destPoly[outCount].x = curPoint.x + ratio * (nextPoint.x - curPoint.x)
      destPoly[outCount].y = curPoint.y + ratio * (nextPoint.y - curPoint.y)
      inc outCount
    inc i
  outCount
```

The loop runs exactly `sourceCount` times, once per directed edge. It copies inside vertices and appends one crossing point where the edge switches side. That keeps the polygon convex and ordered.

```nim
proc polygonArea(poly: array[maxPolygonVertices, Point], vertexCount: int): float64 =
  if vertexCount < 3:
    return 0.0
  var doubled = 0.0
  var i = 0
  while i < vertexCount:
    let curPoint = poly[i]
    let nextPoint = poly[(i + 1) mod vertexCount]
    doubled += curPoint.x * nextPoint.y - nextPoint.x * curPoint.y
    inc i
  if doubled < 0:
    doubled = -doubled
  doubled * 0.5
```

The shoelace sum closes the ring with the modular index. Taking the absolute value handles either vertex winding. A polygon with fewer than three vertices has zero area.

```nim
proc farthestRadiusSquared(poly: array[maxPolygonVertices, Point], vertexCount: int,
                           siteX: float64, siteY: float64): float64 =
  var biggest = 0.0
  var i = 0
  while i < vertexCount:
    let deltaX = poly[i].x - siteX
    let deltaY = poly[i].y - siteY
    let distanceSquared = deltaX * deltaX + deltaY * deltaY
    if distanceSquared > biggest:
      biggest = distanceSquared
    inc i
  biggest
```

A convex polygon reaches its farthest point at a vertex. The loop scans all `vertexCount` vertices and stores the largest squared distance. The squared form avoids a square root.

```nim
proc appendResultLine(outBuf: var string, sampleId: int, areaValue: float64) =
  outBuf.add char(48 + sampleId div 100)
  outBuf.add char(48 + (sampleId div 10) mod 10)
  outBuf.add char(48 + sampleId mod 10)
  let scaledArea = areaValue * 100.0
  var hundredths = int64(scaledArea)
  let remainder = scaledArea - float64(hundredths)
  if remainder > 0.5 + 1e-6:
    inc hundredths
  elif remainder >= 0.5 - 1e-6 and (hundredths and 1) == 1:
    inc hundredths
  var wholePart = hundredths div 100
  let fracPart = hundredths mod 100
  var digitStore: array[16, char]
  var digitCount = 0
  if wholePart == 0:
    digitStore[digitCount] = '0'
    inc digitCount
  else:
    while wholePart > 0:
      digitStore[digitCount] = char(48 + int(wholePart mod 10))
      inc digitCount
      wholePart = wholePart div 10
  var padCount = 14 - digitCount - 3
  while padCount > 0:
    outBuf.add ' '
    dec padCount
  var i = digitCount - 1
  while i >= 0:
    outBuf.add digitStore[i]
    dec i
  outBuf.add '.'
  outBuf.add char(48 + int(fracPart div 10))
  outBuf.add char(48 + int(fracPart mod 10))
  outBuf.add '\n'
```

The id always writes three zero-padded digits because it ranges from 1 to 100. The area writes into a 14-column field with two fractional digits. An exact halfway value rounds to the nearest even hundredth. Both values go straight into the shared output buffer.

```nim
  j = 0
  while j < sampleCount:
    let currentX = siteXs[j]
    let currentY = siteYs[j]
    poly[0].x = 0.0
    poly[0].y = 0.0
    poly[1].x = float64(plateWidth)
    poly[1].y = 0.0
    poly[2].x = float64(plateWidth)
    poly[2].y = float64(plateHeight)
    poly[3].x = 0.0
    poly[3].y = float64(plateHeight)
    var polyCount = 4
    var maxRadiusSq = farthestRadiusSquared(poly, polyCount, currentX, currentY)
    var k = 0
    while k < sampleCount:
      if k != j and polyCount >= 3:
        let deltaX = siteXs[k] - currentX
        let deltaY = siteYs[k] - currentY
        let distanceSquared = deltaX * deltaX + deltaY * deltaY
        if distanceSquared <= 4.0 * maxRadiusSq:
          let coefA = 2.0 * deltaX
          let coefB = 2.0 * deltaY
          let coefC = siteXs[k] * siteXs[k] +
                      siteYs[k] * siteYs[k] -
                      currentX * currentX - currentY * currentY
          polyCount = clipToHalfPlane(poly, polyCount, nextPoly, coefA, coefB, coefC)
          var l = 0
          while l < polyCount:
            poly[l] = nextPoly[l]
            inc l
          if polyCount >= 3:
            maxRadiusSq = farthestRadiusSquared(poly, polyCount, currentX, currentY)
      inc k
    areas[j] = polygonArea(poly, polyCount)
    sampleIds[j] = j + 1
    inc j
```

The outer loop runs `sampleCount` times, once for each seed. The rectangle starts as four counter-clockwise vertices. The inner loop tries every other seed and skips distant ones with the `4.0 * maxRadiusSq` test. Each surviving seed shrinks the cell and updates the farthest radius.

## Complexity

For one cell, the cut loop makes `sampleCount` distance tests and at most that many polygon clips. Each clip scans the current polygon, which holds few vertices. One case therefore costs about O(k²) for k samples, with a small constant. Sorting the k results by insertion sort also costs O(k²). The program stores seeds, areas, and two polygons, so space is O(k). A grid sampler would need millions of probes per cell and still miss the required two decimals.
