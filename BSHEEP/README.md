## Problem

Each case lists sheep at integer coordinates. Find the shortest fence that surrounds them and print its length rounded to two decimals. Then print the 1-based indices of the fence corners in counterclockwise order. The first corner is the bottommost point, and the leftmost point breaks a tie. Sheep at the same position count once, using the first sheep in input order.

The judge limits are these.

| Input value | Maximum |
| --- | --- |
| Test cases | 100 |
| Sheep per case | 100000 |
| Absolute coordinate | 10000 |
| Time limit | 7 s |
| Memory limit | 1536 MB |

These bounds allow one sort per case.

## Idea

Andrew's monotone chain builds the convex hull from a sorted point list. It walks the list forward for the lower hull and backward for the upper hull. A cross product test drops every point that fails to turn left, so only corners remain.

Sorting costs O(n log n) per case, and each walk costs O(n).

## Why It Works

The convex hull is the smallest convex polygon that encloses every point. Its corners are the points where the boundary turns left. A point that turns right or lies straight on an edge never needs fence material.

The turn test uses one integer product difference, computed by `crossProduct`.

```nim
proc crossProduct(origin, first, second: Point): int64 =
  result = int64(first.x - origin.x) * int64(second.y - origin.y) -
           int64(first.y - origin.y) * int64(second.x - origin.x)
```

A positive result means a left turn. Zero means the three points are collinear. A negative result means a right turn.

The lower walk pops the middle point when the result is not positive. The upper walk applies the same rule on the reversed list. Collinear points on a straight edge therefore disappear, which keeps the corner count minimal. A final scan moves the bottommost-leftmost corner to the front and preserves the counterclockwise cycle.

Worked example from the first sample case:

| Step | Result |
| --- | --- |
| Sorted unique points | (0,0,#1) (0,5,#2) (3,3,#4) (10,0,#5) (10,5,#3) |
| Lower hull | #1 #5 #3 |
| Upper hull | #3 #2 #1 |
| Combined hull | #1 #5 #3 #2 |
| Printed order | #1 #5 #3 #2 |

Sheep #4 lies inside the hull and never enters either walk.

## Code

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
```

The `Point` type carries the input index beside each coordinate. The comparator sorts by x, then y, then index. The cross product uses int64, so products of the largest coordinates stay in range.

```nim
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

The scanner walks the input buffer by index and allocates nothing. It skips all non-digits except the minus sign. Negative coordinates therefore keep their sign.

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

  var uniqueCount = 0
  for k in 0 ..< sheepCount:
    if k == 0 or points[k].x != points[k - 1].x or
       points[k].y != points[k - 1].y:
      points[uniqueCount] = points[k]
      uniqueCount += 1
  points.setLen(uniqueCount)
```

Line reads append to one buffer before any parsing. Each case allocates n points, and sorting them costs O(n log n). The dedupe pass keeps the smallest index at each position.

```nim
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

Both walks visit the unique points once. Popping on a non-left turn removes right turns and collinear edge points. The two walks join into one counterclockwise hull.

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

The rotation scans at most h corners and keeps the cycle order. The perimeter adds h distances between adjacent corners. Output accumulates into one buffer and flushes every 256 KiB.

## Complexity

Per case, sorting takes O(n log n) time and the two hull walks take O(n). The start scan and the perimeter sum take O(h) time, where h is the corner count. Across all cases the total is O(t n log n) for t cases of n sheep.

Memory holds one case at a time. The point arrays use O(n) space and the hull uses O(h). The output buffer stays under 256 KiB because it flushes in blocks.

Checking every triple for hull membership would cost O(n^3) per case.
