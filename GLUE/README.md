# GLUE — Johnny and the Glue (SPOJ)
<https://www.spoj.com/problems/GLUE/>

## Problem

The input gives points representing dabs of glue on a floor.
Count the rectangles that contain every point with at least two points on each of their four sides.

The first line holds a test count t. Each case gives a dab count n, then n lines with coordinates x and y. Coordinates run from -15000 to 15000. Print one integer per case, the number of qualifying rectangles, possibly zero.

The judge limits are:

| Item | Value |
| --- | --- |
| Dabs per case n | at most 10000 |
| Coordinates | -15000 to 15000 |
| Time limit | 1 s |
| Memory limit | 1536 MB |

The dab count drives the sort, and the answer stays finite on judge data.

The sample input reads:

```text
1
8
1 0
1 4
0 3
5 4
5 0
6 1
6 3
0 1
```

The sample output reads:

```text
2
```

## Idea

Treat the box as the bounding rectangle of all dabs in some orientation, like rotating a rectangle around the point set. Each side touches a supporting line of the convex hull (the smallest enclosing polygon). Such a line keeps all points on one side. A side holds two dabs when that line carries a hull edge or two dabs share the touched hull corner. One side lies on a hull edge on judge inputs, which pins the orientation to a quarter turn of one edge normal. Test those directions and divide the count by four. Each direction costs four binary searches over sorted normals. Trying every rectangle from dab pairs would cost cubic time. Takeaway: reduce rectangles to a few hull directions, then check each face.

## Why It Works

1. Every side of a qualifying box is a supporting line of the point set.
2. Dabs on one supporting line form a hull face, either an edge or a corner holding two dabs.
3. If all four faces were single corners, the box could turn freely and give infinitely many rectangles.
4. Judge inputs avoid that case, so some face lies on a hull edge and fixes the orientation.
5. Hull normals sorted by angle identify faces: an exact match gives an edge face, and a direction between neighbors touches their shared vertex.
6. Each rectangle appears under four quarter turns, so dividing the valid count by four removes repeats.

The table defines the terms.

| Term | Meaning |
| --- | --- |
| hull | convex polygon enclosing every dab |
| normal | outward direction perpendicular to a hull edge |
| endCounts | dab count at the far end of each hull edge |
| faceIsGood | test that one side touches two dabs |

These four terms drive the face test.

A script built the sample hull. Its eight edge normals are:

| Normal | Face passes |
| --- | --- |
| (-1, -1) | yes |
| (-1, 0) | yes |
| (-1, 1) | yes |
| (0, -1) | yes |
| (0, 1) | yes |
| (1, -1) | yes |
| (1, 0) | yes |
| (1, 1) | yes |

All eight orientations pass, so `8 div 4 = 2`, which matches the sample output.

## Code

**Setup and scanner.** The pragmas disable runtime checks, and the scanner keeps negative coordinates exact.

```nim
{.push checks: off.}
{.push overflowChecks: off.}
{.push rangeChecks: off.}
{.push boundChecks: off.}
{.push stackTrace: off.}

import algorithm

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

type Point = tuple[x: int, y: int]
type Direction = tuple[x: int, y: int]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9') and data[position] != '-':
    position += 1
  var sign = 1
  if position < data.len and data[position] == '-':
    sign = -1
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value * sign
```

The sign branch handles negative coordinates. The digit loop visits each character once, so parsing costs O(input bytes). `Point` and `Direction` name the two tuple roles. The pragmas remove checks from the hot geometry loops.

**Writer and geometry helpers.** Point order and cross products support both the hull and the face test.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc comparePoints(left, right: Point): int =
  if left.x < right.x: return -1
  if left.x > right.x: return 1
  if left.y < right.y: return -1
  if left.y > right.y: return 1
  return 0

proc findPoint(points: seq[Point], target: Point): int =
  var i = 0
  var j = points.len - 1
  while i <= j:
    let k = (i + j) div 2
    let order = comparePoints(points[k], target)
    if order == 0: return k
    if order < 0: i = k + 1
    else: j = k - 1
  return -1

proc crossAround(origin, first, second: Point): int64 =
  let firstX = int64(first.x - origin.x)
  let firstY = int64(first.y - origin.y)
  let secondX = int64(second.x - origin.x)
  let secondY = int64(second.y - origin.y)
  return firstX * secondY - firstY * secondX

proc crossDirections(left, right: Direction): int64 =
  return int64(left.x) * int64(right.y) - int64(left.y) * int64(right.x)
```

`findPoint` performs a binary search on sorted unique points. Cross products use `int64`, so differences of coordinates cannot overflow. Each comparison costs constant time. The output buffer flushes only after 256 KiB.

**Angle order and hull.** The code orders directions, then builds the hull with two monotone chains.

```nim
proc upperHalf(direction: Direction): bool =
  return direction.y > 0 or (direction.y == 0 and direction.x >= 0)

proc compareAngles(left, right: Direction): int =
  let leftUpper = upperHalf(left)
  let rightUpper = upperHalf(right)
  if leftUpper != rightUpper:
    if leftUpper: return -1
    return 1
  let turn = crossDirections(left, right)
  if turn > 0: return -1
  if turn < 0: return 1
  return 0

proc rotateQuarter(direction: Direction): Direction =
  return (-direction.y, direction.x)

proc greatestCommonDivisor(left, right: int): int =
  var first = left
  var second = right
  while second != 0:
    let remainder = first mod second
    first = second
    second = remainder
  return first

proc buildHull(uniquePoints: seq[Point]): seq[Point] =
  if uniquePoints.len <= 2:
    return uniquePoints
  var lower: seq[Point] = @[]
  for point in uniquePoints:
    while lower.len >= 2 and crossAround(lower[lower.len - 2], lower[lower.len - 1], point) <= 0:
      lower.setLen(lower.len - 1)
    lower.add point
  var upper: seq[Point] = @[]
  for i in countdown(uniquePoints.len - 1, 0):
    let point = uniquePoints[i]
    while upper.len >= 2 and crossAround(upper[upper.len - 2], upper[upper.len - 1], point) <= 0:
      upper.setLen(upper.len - 1)
    upper.add point
  result = lower
  result.setLen(lower.len - 1)
  for i in 0 ..< upper.len - 1:
    result.add upper[i]
  return result
```

`upperHalf` splits the circle, and `rotateQuarter` gives the four box orientations. `buildHull` drops collinear points with a non-left turn. Each chain walks the sorted points once, so the hull costs O(n) after the sort.

**Face test.** A binary search decides whether one side touches two dabs.

```nim
proc faceIsGood(target: Direction, normals: seq[Direction], endCounts: seq[int]): bool =
  var i = 0
  var j = normals.len
  while i < j:
    let k = (i + j) div 2
    if compareAngles(normals[k], target) < 0:
      i = k + 1
    else:
      j = k
  if i < normals.len and compareAngles(normals[i], target) == 0:
    return true
  var l = i - 1
  if l < 0:
    l = normals.len - 1
  return endCounts[l] >= 2
```

An exact match means the side lies on a hull edge. Otherwise the previous edge ends at the touched vertex, and `endCounts[l]` tells whether two dabs sit there. The search costs O(log h) for a hull of h vertices.

**Driver and normals.** The program sorts dabs, builds the hull, and records one normal per edge.

```nim
let caseCount = nextInt(inputData, scanPos)
for i in 0 ..< caseCount:
  let dabCount = nextInt(inputData, scanPos)
  var dabPoints = newSeq[Point](dabCount)
  for j in 0 ..< dabCount:
    dabPoints[j] = (nextInt(inputData, scanPos), nextInt(inputData, scanPos))
  dabPoints.sort(comparePoints)

  var uniquePoints: seq[Point] = @[]
  var pointCounts: seq[int] = @[]
  for point in dabPoints:
    if uniquePoints.len > 0 and comparePoints(uniquePoints[uniquePoints.len - 1], point) == 0:
      pointCounts[pointCounts.len - 1] += 1
    else:
      uniquePoints.add point
      pointCounts.add 1

  let hull = buildHull(uniquePoints)
  if hull.len < 3:
    appendOutput("0")
    outputBuffer.add '\n'
    continue

  let hullSize = hull.len
  var normals: seq[Direction] = @[]
  var endCounts: seq[int] = @[]
  for k in 0 ..< hullSize:
    let l = (k + 1) mod hullSize
    let deltaX = hull[l].x - hull[k].x
    let deltaY = hull[l].y - hull[k].y
    let divisor = greatestCommonDivisor(abs(deltaX), abs(deltaY))
    normals.add (deltaY div divisor, -(deltaX div divisor))
    endCounts.add pointCounts[findPoint(uniquePoints, hull[l])]

  var order = newSeq[int](hullSize)
  for k in 0 ..< hullSize:
    order[k] = k
  order.sort(proc(left, right: int): int = compareAngles(normals[left], normals[right]))

  var sortedNormals: seq[Direction] = @[]
  var sortedEndCounts: seq[int] = @[]
  for k in order:
    sortedNormals.add normals[k]
    sortedEndCounts.add endCounts[k]
```

Duplicate dabs collapse into one point plus a count, so a shared corner keeps its dab total. A hull with fewer than three points gives no rectangle. Each edge's normal is reduced by the greatest common divisor. Sorting the normals by angle prepares the binary search.

**Orientation check.** Four quarter turns of each normal form the candidate directions.

```nim
  var candidates: seq[Direction] = @[]
  for normal in sortedNormals:
    var current = normal
    for l in 0 ..< 4:
      candidates.add current
      current = rotateQuarter(current)
  candidates.sort(compareAngles)

  var orientations: seq[Direction] = @[]
  for candidate in candidates:
    if orientations.len == 0 or compareAngles(orientations[orientations.len - 1], candidate) != 0:
      orientations.add candidate

  var validCount = 0
  for orientation in orientations:
    var current = orientation
    var allGood = true
    for l in 0 ..< 4:
      if not faceIsGood(current, sortedNormals, sortedEndCounts):
        allGood = false
        break
      current = rotateQuarter(current)
    if allGood:
      validCount += 1

  appendOutput($(validCount div 4))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Sorting removes repeated directions. A valid orientation passes all four face checks. Dividing by four removes the quarter-turn repeats. The final write flushes the buffered answers.

## Complexity

| Phase | Time | Space |
| --- | --- | --- |
| Sort and dedupe dabs | O(n log n) | O(n) |
| Build hull and normals | O(n + h log h) | O(h) |
| Check orientations | O(h log h) | O(h) |

The hull size bounds the geometry work.

The hull size h never exceeds the dab count n.

| Measure | Bound |
| --- | --- |
| Per case | O(n log n + h log h) time |
| Per case | O(n) space |
| Face check | O(log h) each |

Enumerating rectangles from dab pairs would cost O(n^3) per case. The hull reduces the search to a few directions.
