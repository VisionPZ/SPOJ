# BSHEEP — Build the Fence (SPOJ)
<https://www.spoj.com/problems/BSHEEP/>

## Problem

Each case gives point coordinates, possibly with repeated points. Find the shortest closed fence enclosing them, round its length to two decimals, and list its corner points by input index in counterclockwise order.

Input starts with a test count. Each case gives a sheep count n, then n lines of integer x and y coordinates. Sheep at the same spot count once, using the first index in input order. Print the length, then the corner indices starting at the bottommost and leftmost corner, then a blank line.

The judge limits are these:

| Input value | Maximum |
| --- | --- |
| Test cases | 100 |
| Sheep per case | 100,000 |
| Absolute coordinate | 10,000 |
| Time limit | 7000 ms |
| Memory limit | 1536 MB |

These bounds allow one sort per case.

The sample input and output:

```
8

5
0 0
0 5
10 5
3 3
10 0

1
0 0

3
0 0
1 0
2 0

4
0 0
0 0
0 1
1 0

3
0 0
0 1
1 0

6
0 0
-1 -1
1 1
2 2
3 3
4 4

2
10 0
0 0

7
-3 -4
2 -3
4 3
-4 2
0 5
2 -3
-1 4

```

```
30.00
1 5 3 2

0.00
1

4.00
1 3

3.41
1 4 3

3.41
1 3 2

14.14
2 6

20.00
2 1

26.98
1 2 3 5 4

```

The first case forms a 10 by 5 rectangle with a 30.00 perimeter.

## Idea

Build the convex hull with Andrew's monotone chain (a method that walks a sorted point list). Sort the points, walk forward for the lower half and backward for the upper half, and keep only points that turn left. Think of pulling a rubber band around the sheep: only the outermost ones touch it.

Sorting costs O(n log n) per case, and each walk costs O(n). Checking every triple or every subset for the smallest enclosing boundary would be far slower.

Takeaway: sort once, then two linear walks give the fence.

## Why It Works

1. The convex hull is the smallest convex polygon enclosing every point.
2. Its corners are exactly the points where the boundary turns left.
3. `crossProduct` gives a positive value for a left turn, zero for a straight line, and a negative value for a right turn.
4. The lower and upper walks pop the middle point whenever the turn is not left, which removes collinear and interior points.
5. A final scan rotates the bottommost-leftmost corner to the front and keeps the counterclockwise order.
6. Summing `distanceBetween` around the hull gives the circumference.

The turn test uses one integer product difference.

| Term | Meaning |
| --- | --- |
| `crossProduct` | signed area of the turn from origin through first to second |
| `lower` | hull half built from left to right |
| `upper` | hull half built from right to left |
| `uniqueCount` | number of points after duplicate removal |
| `hull[i].idx` | original 1-based sheep index |

Only corners survive both walks.

A script traced the first sample case:

| Step | Result |
| --- | --- |
| Sorted unique points | (0,0), (0,5), (3,3), (10,0), (10,5) |
| Lower hull indices | 1, 5 |
| Upper hull indices | 5, 3, 2 |
| Corner order | 1, 5, 3, 2 |
| Perimeter | 30.00 |

The sheep at (3,3) lies inside the rectangle, so no fence corner is needed there.

## Code

**Types and geometry helpers.**
```nim
import algorithm, math, strutils

const flushBlockBytes = 1 shl 18

type
  Point = object
    x: int
    y: int
    idx: int

proc comparePoint(left, right: Point): int =
  if left.x < right.x: return -1
  if left.x > right.x: return 1
  if left.y < right.y: return -1
  if left.y > right.y: return 1
  if left.idx < right.idx: return -1
  if left.idx > right.idx: return 1
  result = 0

proc crossProduct(origin, first, second: Point): int64 =
  result = int64(first.x - origin.x) * int64(second.y - origin.y) -
           int64(first.y - origin.y) * int64(second.x - origin.x)

proc distanceBetween(first, second: Point): float =
  var deltaX = int64(first.x) - int64(second.x)
  var deltaY = int64(first.y) - int64(second.y)
  result = sqrt(float(deltaX * deltaX + deltaY * deltaY))

proc nextInt(inputData: string, i: var int): int =
  var currentChar = ' '
  while i < inputData.len:
    currentChar = inputData[i]
    if (currentChar >= '0' and currentChar <= '9') or currentChar == '-': break
    i += 1
  var sign = 1
  if currentChar == '-':
    sign = -1
    i += 1
  var value = 0
  while i < inputData.len:
    currentChar = inputData[i]
    if currentChar < '0' or currentChar > '9': break
    value = value * 10 + (int(currentChar) - 48)
    i += 1
  result = sign * value
```
`Point` stores coordinates and the original index. `comparePoint` sorts by x, then y, then index. `crossProduct` and `distanceBetween` use 64-bit arithmetic to avoid overflow. `nextInt` handles the minus sign.

**Input and case loop.**
```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add(inputLine)
  inputData.add('\n')

var i = 0
var testCount = nextInt(inputData, i)
var outputBuffer = ""

for j in 0 ..< testCount:
  var sheepCount = nextInt(inputData, i)
  var points: seq[Point] = @[]
  points.setLen(sheepCount)
  for k in 0 ..< sheepCount:
    var pointX = nextInt(inputData, i)
    var pointY = nextInt(inputData, i)
    points[k] = Point(x: pointX, y: pointY, idx: k + 1)

  points.sort(comparePoint)
```
The buffer gathers all lines, and `testCount` sets the loop. Each case reads n and fills `points` with 1-based indices.

**Hull construction.**
```nim
  var uniqueCount = 0
  for k in 0 ..< sheepCount:
    if k == 0 or points[k].x != points[k - 1].x or
       points[k].y != points[k - 1].y:
      points[uniqueCount] = points[k]
      uniqueCount += 1
  points.setLen(uniqueCount)

  var hull: seq[Point] = @[]
  if uniqueCount == 1:
    hull.setLen(1)
    hull[0] = points[0]
  else:
    var lower: seq[Point] = @[]
    lower.setLen(uniqueCount + 1)
    var lowerSize = 0
    for k in 0 ..< uniqueCount:
      var currentPoint = points[k]
      while lowerSize >= 2 and
            crossProduct(lower[lowerSize - 2], lower[lowerSize - 1], currentPoint) <= 0:
        lowerSize -= 1
      lower[lowerSize] = currentPoint
      lowerSize += 1

    var upper: seq[Point] = @[]
    upper.setLen(uniqueCount + 1)
    var upperSize = 0
    for k in 0 ..< uniqueCount:
      var currentPoint = points[uniqueCount - 1 - k]
      while upperSize >= 2 and
            crossProduct(upper[upperSize - 2], upper[upperSize - 1], currentPoint) <= 0:
        upperSize -= 1
      upper[upperSize] = currentPoint
      upperSize += 1

    hull.setLen(lowerSize + upperSize - 2)
    var l = 0
    for k in 0 ..< (lowerSize - 1):
      hull[l] = lower[k]
      l += 1
    for k in 0 ..< (upperSize - 1):
      hull[l] = upper[k]
      l += 1

```
Duplicates are removed after sorting. `lower` and `upper` each pop points that fail the left-turn test, then the two halves are joined. Collinear points on a straight edge disappear.

**Perimeter and output.**
```nim
  var hullSize = hull.len
  var l = 0
  for k in 1 ..< hullSize:
    if hull[k].y < hull[l].y or
       (hull[k].y == hull[l].y and hull[k].x < hull[l].x):
      l = k

  var perimeter = 0.0
  for k in 0 ..< hullSize:
    var l = (k + 1) mod hullSize
    perimeter += distanceBetween(hull[k], hull[l])

  outputBuffer.add(formatFloat(perimeter, ffDecimal, 2))
  outputBuffer.add('\n')
  for k in 0 ..< hullSize:
    var i = (l + k) mod hullSize
    if k > 0: outputBuffer.add(' ')
    outputBuffer.add($hull[i].idx)
  outputBuffer.add('\n')
  outputBuffer.add('\n')

  if outputBuffer.len >= flushBlockBytes:
    stdout.write(outputBuffer)
    outputBuffer.setLen(0)

if outputBuffer.len > 0:
  stdout.write(outputBuffer)
```
The scan finds the bottommost-leftmost corner. Distances around the hull sum to the perimeter, printed with two decimals. The corner indices follow in counterclockwise order, with a blank line after each case.

## Complexity

Sorting dominates the hull work.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | one pass over input bytes | input bytes |
| Sort and dedupe | O(n log n) | n points |
| Monotone chain | O(n) | O(n) hull arrays |
| Perimeter and output | O(h) for h corners | O(h) |
| Output | one write per block | flushBlockBytes |

The two walks each visit every point once.

| Measure | Big O |
| --- | --- |
| Time per case | O(n log n) |
| Space per case | O(n) |

Testing every point subset for the hull would be exponential, while a single sort and two walks suffice.
