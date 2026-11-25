# RUNAWAY — Run Away (SPOJ)

<https://www.spoj.com/problems/RUNAWAY/>

## Problem

A room has small holes that spew hot lava when triggered. An archaeologist must stand as far as possible from the nearest hole. Find the safest point and report its coordinates to one decimal.

Input: `T` cases. Each starts with `X Y M`, the room size and hole count, then `M` lines `U V`. Output: one line per case, `The safest point is (P, Q).` with exactly one digit after each decimal point.

The bounds from the statement:

| Item | Bound |
|---|---|
| Room size `X`, `Y` | 1 ≤ X, Y ≤ 10000 |
| Holes `M` | 1 ≤ M ≤ 1000 |
| Hole coordinates | 0 ≤ U ≤ X, 0 ≤ V ≤ Y; repeats allowed |
| Judge limit | 13000 ms, 1536 MB |

A value like 0.05 rounds up to 0.1, so the output needs careful rounding.

The sample input and output:

```
3
1000 50 1
10 10
100 100 4
10 10
10 90
90 10
90 90
3000 3000 4
1200 85
63 2500
2700 2650
2990 100
```

```
The safest point is (1000.0, 50.0).
The safest point is (50.0, 50.0).
The safest point is (1433.0, 1669.8).
```

## Idea

Grow a circle from a spot until it touches a hole. The largest such circle marks the safest spot. Think of balancing between several hazards so no single one is close.

The program builds a Delaunay triangulation (a mesh where no hole lies inside any triangle's circumcircle) of the holes plus three far enclosing points. The farthest point sits at a circumcenter, a room corner, or a point on an edge where the nearest hole changes.

For each edge it builds the lower envelope (the pointwise minimum) of distance-squared parabolas and tests their breakpoints. Each candidate's score is its minimum squared distance to any hole. The program keeps the best score, breaks ties by smaller x then y, and rounds to one decimal.

Each hole participates in a constant amount of mesh and envelope work on average, so a case runs in O(M²) worst case. Scanning a grid fine enough for 0.1 precision would need about 10^10 checks.

The farthest point lives on a small, finite set of geometric candidates.

## Why It Works

Four facts carry the geometry.

1. The distance to the nearest hole is piecewise smooth. Its maximum in the room occurs at a Voronoi vertex, a room corner, or a point where the nearest hole changes on a wall.
2. Delaunay circumcenters are the dual vertices of that nearest-hole diagram. Testing them covers interior candidates.
3. Along a room edge, squared distance to a hole is a parabola in the edge coordinate. Breakpoints of the lower envelope are exactly where the nearest hole changes.
4. Rounding scales by 10, adds 0.5 plus a small epsilon, then floors. That sends 0.05 up to 0.1 as the statement requires.

The structures the program uses:

| Term | Meaning |
|---|---|
| `buildTriangulation` | incremental Delaunay mesh with three far points |
| `circumCenter` | center of a triangle's circumcircle |
| `envelopeBreakpoints` | edge positions where the nearest hole changes |
| `bestDistanceSquared` | largest minimum squared distance found |

The epsilon constants guard against floating-point ties and near-degenerate triangles.

A script-traced example with the first two sample cases:

```
room 1000 x 50, hole (10,10):
  corner (1000,50): dx=990, dy=40, squared distance = 981700
  corner (1000,0):  dx=990, dy=10, squared distance = 980200
  farthest corner wins -> (1000.0, 50.0)

room 100 x 100, holes (10,10),(10,90),(90,10),(90,90):
  center (50,50) is 40 from every hole
  -> (50.0, 50.0)

the third sample case yields (1433.0, 1669.8)
```

## Code

**Constants and geometry types.** Epsilons and records set up the floating-point geometry.

```nim
import math, algorithm

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const invalidCoordinate = 1e30
const degenerateEpsilon = 1e-12
const circleEpsilon = 1e-10
const tieEpsilon = 1e-7
const roundingEpsilon = 1e-7

type
  HolePoint = object
    x: float
    y: float
  Triangle = object
    first: int
    second: int
    third: int
  MeshEdge = object
    first: int
    second: int
  EnvelopeLine = object
    slope: float
    intercept: float
    startAt: float

var roomWidth = 0.0
var roomHeight = 0.0
var bestDistanceSquared = -1.0
var bestX = 0.0
var bestY = 0.0
```

`degenerateEpsilon` guards near-collinear triangles. `tieEpsilon` orders nearly equal candidates by x then y. `roundingEpsilon` pushes borderline values up.

**Input and candidate scoring.** Each candidate is clamped to the room and compared with the best so far.

```nim
proc nextInt(inputData: string, i: var int): int =
  let inputLength = inputData.len
  while i < inputLength:
    let currentChar = inputData[i]
    if currentChar >= '0' and currentChar <= '9':
      break
    inc i
  var parsedValue = 0
  while i < inputLength:
    let currentChar = inputData[i]
    if currentChar < '0' or currentChar > '9':
      break
    parsedValue = parsedValue * 10 + (ord(currentChar) - firstDigitValue)
    inc i
  return parsedValue

proc compareHoles(left, right: HolePoint): int =
  if left.x < right.x: return -1
  if left.x > right.x: return 1
  if left.y < right.y: return -1
  if left.y > right.y: return 1
  return 0

proc considerCandidate(candidateX, candidateY: float, holes: seq[HolePoint]) =
  var clampedX = candidateX
  var clampedY = candidateY
  if clampedX < 0.0: clampedX = 0.0
  if clampedX > roomWidth: clampedX = roomWidth
  if clampedY < 0.0: clampedY = 0.0
  if clampedY > roomHeight: clampedY = roomHeight
  var nearestSquared = invalidCoordinate
  for hole in holes:
    let deltaX = clampedX - hole.x
    let deltaY = clampedY - hole.y
    let distanceSquared = deltaX * deltaX + deltaY * deltaY
    if distanceSquared < nearestSquared:
      nearestSquared = distanceSquared
  let clearlyBetter = nearestSquared > bestDistanceSquared + tieEpsilon
  let nearlyTied = abs(nearestSquared - bestDistanceSquared) <= tieEpsilon
  let smallerX = clampedX < bestX - tieEpsilon
  let smallerY = clampedY < bestY - tieEpsilon
  let sameX = abs(clampedX - bestX) <= tieEpsilon
  let tieBroken = nearlyTied and (smallerX or (sameX and smallerY))
  if clearlyBetter or tieBroken:
    bestDistanceSquared = nearestSquared
    bestX = clampedX
    bestY = clampedY

```

`nextInt` skips non-digits, which handles blank lines safely. `considerCandidate` clamps coordinates, finds the nearest hole, then applies the tie rules.

**Circumcircle helpers.** These decide which triangles to keep during insertion.

```nim
proc circumCenter(first, second, third: HolePoint): (float, float) =
  let deltaX21 = second.x - first.x
  let deltaY21 = second.y - first.y
  let deltaX31 = third.x - first.x
  let deltaY31 = third.y - first.y
  let denominator = 2.0 * (deltaX21 * deltaY31 - deltaX31 * deltaY21)
  if abs(denominator) < degenerateEpsilon:
    return (invalidCoordinate, invalidCoordinate)
  let firstPower = second.x * second.x + second.y * second.y - first.x * first.x - first.y * first.y
  let secondPower = third.x * third.x + third.y * third.y - first.x * first.x - first.y * first.y
  let centerX = (firstPower * deltaY31 - secondPower * deltaY21) / denominator
  let centerY = (deltaX21 * secondPower - deltaX31 * firstPower) / denominator
  return (centerX, centerY)

proc insideCircumcircle(first, second, third, probe: HolePoint): bool =
  var orientedSecond = second
  var orientedThird = third
  let orientation = (orientedSecond.x - first.x) * (orientedThird.y - first.y) -
                    (orientedSecond.y - first.y) * (orientedThird.x - first.x)
  if orientation < 0.0:
    let swapX = orientedSecond.x
    orientedSecond.x = orientedThird.x
    orientedThird.x = swapX
    let swapY = orientedSecond.y
    orientedSecond.y = orientedThird.y
    orientedThird.y = swapY
  if abs(orientation) < degenerateEpsilon:
    return false
  let firstX = first.x - probe.x
  let firstY = first.y - probe.y
  let secondX = orientedSecond.x - probe.x
  let secondY = orientedSecond.y - probe.y
  let thirdX = orientedThird.x - probe.x
  let thirdY = orientedThird.y - probe.y
  let firstNorm = firstX * firstX + firstY * firstY
  let secondNorm = secondX * secondX + secondY * secondY
  let thirdNorm = thirdX * thirdX + thirdY * thirdY
  let determinant = firstNorm * (secondX * thirdY - secondY * thirdX) -
                    secondNorm * (firstX * thirdY - firstY * thirdX) +
                    thirdNorm * (firstX * secondY - firstY * secondX)
  return determinant > circleEpsilon

```

`circumCenter` returns an invalid point for a degenerate triangle. `insideCircumcircle` uses the determinant test, with a swap to fix orientation. The epsilon guards avoid false positives from rounding.

**Delaunay triangulation.** Points are inserted one at a time, starting from three far enclosing points.

```nim
proc addMeshEdge(meshEdges: var seq[MeshEdge], endpointA, endpointB: int) =
  let edgeStart = min(endpointA, endpointB)
  let edgeEnd = max(endpointA, endpointB)
  for i in 0 ..< meshEdges.len:
    if meshEdges[i].first == edgeStart and meshEdges[i].second == edgeEnd:
      meshEdges.delete(i)
      return
  meshEdges.add(MeshEdge(first: edgeStart, second: edgeEnd))

proc buildTriangulation(holes: seq[HolePoint]): (seq[Triangle], seq[HolePoint]) =
  let pointCount = holes.len
  let minimumX = holes[0].x
  let maximumX = holes[pointCount - 1].x
  var minimumY = holes[0].y
  var maximumY = holes[0].y
  for hole in holes:
    if hole.y < minimumY: minimumY = hole.y
    if hole.y > maximumY: maximumY = hole.y
  let span = max(max(maximumX - minimumX, maximumY - minimumY), 1.0)
  let middleX = (minimumX + maximumX) / 2.0
  let middleY = (minimumY + maximumY) / 2.0
  var allPoints = holes
  allPoints.add(HolePoint(x: middleX - 20.0 * span, y: middleY - span))
  allPoints.add(HolePoint(x: middleX + 20.0 * span, y: middleY - span))
  allPoints.add(HolePoint(x: middleX, y: middleY + 20.0 * span))
  var triangles: seq[Triangle] = @[]
  triangles.add(Triangle(first: pointCount, second: pointCount + 1, third: pointCount + 2))
  for i in 0 ..< pointCount:
    let probe = allPoints[i]
    var meshEdges: seq[MeshEdge] = @[]
    var retained: seq[Triangle] = @[]
    for triangle in triangles:
      if insideCircumcircle(allPoints[triangle.first], allPoints[triangle.second], allPoints[triangle.third], probe):
        addMeshEdge(meshEdges, triangle.first, triangle.second)
        addMeshEdge(meshEdges, triangle.second, triangle.third)
        addMeshEdge(meshEdges, triangle.third, triangle.first)
      else:
        retained.add(triangle)
    triangles = retained
    for meshEdge in meshEdges:
      triangles.add(Triangle(first: meshEdge.first, second: meshEdge.second, third: i))
  var realTriangles: seq[Triangle] = @[]
  for triangle in triangles:
    if triangle.first < pointCount and triangle.second < pointCount and triangle.third < pointCount:
      realTriangles.add(triangle)
  return (realTriangles, allPoints)
```

`addMeshEdge` toggles triangle edges so cavity boundaries appear once. Bad triangles are removed, and new ones join their mesh edge to the new point. Only triangles made of real holes survive.

**Edge envelopes.** Distance parabolas are reduced to their lower envelope on each wall.

```nim
proc compareLinesDescending(left, right: EnvelopeLine): int =
  if left.slope > right.slope: return -1
  if left.slope < right.slope: return 1
  return 0

proc envelopeBreakpoints(lines: seq[EnvelopeLine], lowBound, highBound: float): seq[float] =
  var reduced: seq[EnvelopeLine] = @[]
  for line in lines:
    var matching = false
    for i in 0 ..< reduced.len:
      if abs(reduced[i].slope - line.slope) < degenerateEpsilon:
        if line.intercept < reduced[i].intercept:
          reduced[i].intercept = line.intercept
        matching = true
        break
    if not matching:
      reduced.add(EnvelopeLine(slope: line.slope, intercept: line.intercept, startAt: -invalidCoordinate))
  reduced.sort(compareLinesDescending)
  var crossings: seq[float] = @[]
  if reduced.len == 0:
    return crossings
  var stack: seq[EnvelopeLine] = @[]
  for line in reduced:
    while stack.len > 0:
      let lastLine = stack[stack.len - 1]
      let slopeGap = line.slope - lastLine.slope
      if abs(slopeGap) < degenerateEpsilon:
        break
      let crossing = (lastLine.intercept - line.intercept) / slopeGap
      if crossing <= lastLine.startAt + degenerateEpsilon:
        stack.setLen(stack.len - 1)
      else:
        break
    if stack.len == 0:
      stack.add(EnvelopeLine(slope: line.slope, intercept: line.intercept, startAt: -invalidCoordinate))
    else:
      let lastLine = stack[stack.len - 1]
      let slopeGap = line.slope - lastLine.slope
      if abs(slopeGap) < degenerateEpsilon:
        if line.intercept < lastLine.intercept:
          stack[stack.len - 1].intercept = line.intercept
      else:
        let crossing = (lastLine.intercept - line.intercept) / slopeGap
        stack.add(EnvelopeLine(slope: line.slope, intercept: line.intercept, startAt: crossing))
  for i in 1 ..< stack.len:
    let crossing = stack[i].startAt
    if crossing > lowBound and crossing < highBound:
      crossings.add(crossing)
  return crossings

proc considerEdgeCandidates(edgeValue: float, verticalEdge: bool, holes: seq[HolePoint]) =
  var lines: seq[EnvelopeLine] = @[]
  for hole in holes:
    var lineSlope: float
    var lineIntercept: float
    if verticalEdge:
      let offset = edgeValue - hole.x
      lineSlope = -2.0 * hole.y
      lineIntercept = hole.y * hole.y + offset * offset
    else:
      let offset = edgeValue - hole.y
      lineSlope = -2.0 * hole.x
      lineIntercept = hole.x * hole.x + offset * offset
    lines.add(EnvelopeLine(slope: lineSlope, intercept: lineIntercept, startAt: -invalidCoordinate))
  let highBound = if verticalEdge: roomHeight else: roomWidth
  let crossings = envelopeBreakpoints(lines, 0.0, highBound)
  for crossing in crossings:
    if verticalEdge:
      considerCandidate(edgeValue, crossing, holes)
    else:
      considerCandidate(crossing, edgeValue, holes)
```

`envelopeBreakpoints` sorts lines by descending slope and builds a stack of envelope pieces. `considerEdgeCandidates` turns each crossing into a candidate on the correct wall. Four calls cover all walls.

**Rounding.** One helper scales, rounds, and floors.

```nim
proc roundedTenths(value: float): int =
  let scaled = value * 10.0 + 0.5 + roundingEpsilon
  let rounded = int(floor(scaled))
  if rounded < 0: return 0
  return rounded
```

`roundingEpsilon` lifts values close to a half tick. Flooring then gives the required one-decimal result, and negative values clamp to zero.

**Input and driver.** Each case gathers candidates, then prints the best point.

```nim
var inputData = ""
var inputLine: string = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0
let testCount = nextInt(inputData, i)
var outputBuffer = ""

for j in 0 ..< testCount:
  roomWidth = float(nextInt(inputData, i))
  roomHeight = float(nextInt(inputData, i))
  let holeCount = nextInt(inputData, i)
  var inputHoles: seq[HolePoint] = @[]
  for k in 0 ..< holeCount:
    let holeX = float(nextInt(inputData, i))
    let holeY = float(nextInt(inputData, i))
    inputHoles.add(HolePoint(x: holeX, y: holeY))
  inputHoles.sort(compareHoles)
  var holes: seq[HolePoint] = @[]
  for hole in inputHoles:
    if holes.len == 0 or compareHoles(holes[holes.len - 1], hole) != 0:
      holes.add(hole)

  bestDistanceSquared = -1.0
  considerCandidate(0.0, 0.0, holes)
  considerCandidate(roomWidth, 0.0, holes)
  considerCandidate(0.0, roomHeight, holes)
  considerCandidate(roomWidth, roomHeight, holes)

  let triangulation = buildTriangulation(holes)
  let triangles = triangulation[0]
  let allPoints = triangulation[1]
  for triangle in triangles:
    let center = circumCenter(allPoints[triangle.first], allPoints[triangle.second], allPoints[triangle.third])
    if center[0] >= 0.0 and center[0] <= roomWidth and center[1] >= 0.0 and center[1] <= roomHeight:
      considerCandidate(center[0], center[1], holes)

  considerEdgeCandidates(0.0, true, holes)
  considerEdgeCandidates(roomWidth, true, holes)
  considerEdgeCandidates(0.0, false, holes)
  considerEdgeCandidates(roomHeight, false, holes)

  let outputX = roundedTenths(bestX)
  let outputY = roundedTenths(bestY)
  let wholeX = $(outputX div 10)
  let fractionX = $(outputX mod 10)
  let wholeY = $(outputY div 10)
  let fractionY = $(outputY mod 10)
  outputBuffer.add "The safest point is ("
  outputBuffer.add wholeX
  outputBuffer.add '.'
  outputBuffer.add fractionX
  outputBuffer.add ", "
  outputBuffer.add wholeY
  outputBuffer.add '.'
  outputBuffer.add fractionY
  outputBuffer.add ").\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
```

Holes are sorted and deduplicated first. Four corners, circumcenters, and four edge envelopes supply all candidates. `roundedTenths` formats both coordinates before the line goes into the output buffer.

## Complexity

Each case builds a mesh, tests centers, and scans four edges.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Sort and dedup holes | O(M log M) | O(M) |
| Delaunay build | O(M²) worst case | O(M) |
| Circumcenter tests | O(M) per triangle | O(1) |
| Edge envelopes | 4 × O(M log M) | O(M) |
| Output | one write per 256 KiB block | 256 KiB |
| Total per case | O(M²) worst case | O(M) |

With at most 1000 holes the mesh stays modest.

| Measure | Big O |
|---|---|
| Time | O(M²) worst case per case |
| Space | O(M) for holes, triangles, and envelope lines |

A grid search fine enough for 0.1 precision would need about 10^10 distance checks.

Sampling the room on a 0.1 grid takes billions of checks. Geometric candidates reach the same answer with a few thousand operations.
