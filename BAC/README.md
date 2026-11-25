# BAC — Bacterial (SPOJ)
<https://www.spoj.com/problems/BAC/>

## Problem

Bacteria spread across a plate until neighbouring colonies meet, and a lab wants the area each colony claims.
A report must rank the colonies by their claimed area.

Each case gives plate width and height, then k, then k positions. A zero width or height ends the input, and blank lines separate cases. Print each sample id as three zero-padded digits and its area in fourteen columns with two decimals. List larger areas first and add a blank line after each case.

The bounds and judge limits are:

| Constraint | Value |
| --- | --- |
| Plate width and height | 1 to 1000 |
| Samples k | 1 to 100 |
| Cases | about 20000 |
| Judge time | 1.631 s |
| Judge memory | 1536 MB |

The report format is checked byte for byte, including trailing blanks.

The sample input and its expected output follow byte for byte.

```
10 10
2
5 5
0 0

0 0
```

```
001         87.50
002         12.50

```


## Idea

Clip the plate by each halfway boundary between two colonies, like cutting a cake with straight cuts. This is half-plane clipping (trimming a polygon to one side of a line).
The program starts every cell as the full plate polygon. For each rival site it clips the polygon with the perpendicular bisector, which keeps only points closer to the current site.
The shoelace formula then gives the area of the remaining convex polygon. Each case costs O(k squared) clipping steps, while a grid simulation over a million cells per case cannot meet the limit.
Half-plane clipping gives exact areas with a handful of vertices per cell.

## Why It Works

1. Points closer to site j than to site i lie on one side of their perpendicular bisector, which is a half-plane.
2. Clipping a convex polygon by a half-plane keeps it convex and crosses each edge at most once.
3. `clipToHalfPlane` emits kept vertices and crossing points in border order.
4. `polygonArea` sums edge cross products and halves the absolute value, the shoelace formula.
5. The skip test against four times the farthest radius avoids clipping by sites too distant to cut the cell.

Four terms carry the proof.

| Term | Meaning |
| --- | --- |
| bisector | line where two sites are equally distant |
| half-plane | one side of a bisector |
| clip | trim a polygon to a half-plane |
| shoelace formula | cross-product sum giving polygon area |

They explain how straight cuts replace a cell-by-cell simulation.

A script check of the sample uses a 10 by 10 plate with sites at (5,5) and (0,0).
The bisector is x plus y equals 5. The first cell keeps 87.50 units, and the second keeps 12.50 units.
The report prints 001 87.50 before 002 12.50, matching the sample.

## Code

**Half-plane clipper.**
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

The clipper walks polygon edges in order. It keeps vertices inside the half-plane and inserts crossing points. Convexity guarantees a clean ordered result.

**Area and radius helpers.**
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

`polygonArea` applies the shoelace sum to the clipped polygon. `farthestRadiusSquared` finds the distance to the farthest vertex. That radius drives the distant-site skip test.

**Report formatter.**
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

The formatter writes a three-digit zero-padded sample id. It scales the area and rounds with a tie rule. The area is right justified in fourteen columns.

**Case loop and ranking.**
```nim
while true:
  let plateWidth = nextInt(inputData, i)
  let plateHeight = nextInt(inputData, i)
  if plateWidth == 0 or plateHeight == 0:
    break
  let sampleCount = nextInt(inputData, i)
  var j = 0
  while j < sampleCount:
    siteXs[j] = float64(nextInt(inputData, i))
    siteYs[j] = float64(nextInt(inputData, i))
    inc j

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

  var k = 1
  while k < sampleCount:
    let heldArea = areas[k]
    let heldId = sampleIds[k]
    var l = k - 1
    while l >= 0 and areas[l] < heldArea:
      areas[l + 1] = areas[l]
      sampleIds[l + 1] = sampleIds[l]
      dec l
    areas[l + 1] = heldArea
    sampleIds[l + 1] = heldId
    inc k

  k = 0
  while k < sampleCount:
    appendResultLine(outputBuffer, sampleIds[k], areas[k])
    inc k
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

if outputBuffer.len > 0:
  stdout.write outputBuffer
```

Each site starts from the four plate corners. Every rival clips the current cell in turn. An insertion sort orders samples by descending area.


## Complexity

Each cell is clipped by at most k bisectors, and the polygon stays small.

| Phase | Time | Space |
| --- | --- | --- |
| input parse | O(k) | two coordinate arrays |
| clipping | O(k squared) | two polygon arrays |
| area and sort | O(k squared) worst | area and id arrays |

The distant-site skip avoids most clip operations when a cell is already small.

Big O uses sample count k.

| Measure | Big O |
| --- | --- |
| time | O(k squared) per case |
| space | O(k) |

A cell-by-cell grid simulation would touch the whole plate for every case.
