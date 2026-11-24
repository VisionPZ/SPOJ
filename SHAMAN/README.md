## Problem

Read several test cases. Each case gives n peaks with integer coordinates. Print the largest area any four peaks can cover, with exactly one digit after the decimal point. A concave choice counts as the area of its convex hull.

The judge bounds are:

| Quantity | Bound |
| --- | --- |
| Test cases | at most 80 |
| Peaks per case | 4 to 2000 |
| Coordinate range | -20000 to 20000 |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

The peak count makes a search over every group of four peaks too slow.

## Idea

Keep only the peaks on the convex hull. The corners of a largest shape always lie on that hull. Sweep a diagonal, a segment joining two hull vertices, through its antipodal positions. For each diagonal, take the farthest hull vertex on each side. Every index moves forward at most once around the hull.

Cost per hull vertex: constant time.

## Why It Works

A hull corner can replace an interior corner without shrinking the covered area. The area of a quadrilateral is half the cross product of its two diagonals, so doubled area is an integer. The largest quadrilateral for a fixed diagonal uses the farthest vertex on each side of that diagonal.

The calipers visit antipodal diagonal pairs in order. The two diagonal endpoints advance one hull edge at a time. The two farthest vertices also advance forward, never backward. Each index crosses the hull once, so the sweep is linear.

These terms drive the program:

- `hull`: boundary peaks in counterclockwise order.
- `leftIndex`, `rightIndex`: endpoints of the current diagonal.
- `lowerIndex`, `upperIndex`: farthest vertices on the two sides of that diagonal.
- `crossAt`: signed cross product of two vectors from one point.
- `quadArea2`: doubled area from the diagonal and the spread between the farthest vertices.

The generator prints this worked example:

```
points [(0, 0), (6, 0), (6, 4), (0, 4), (2, 2), (3, 1)]
hull [(0, 0), (6, 0), (6, 4), (0, 4)]
doubled area 48
answer 24.0
```

The two interior peaks drop out and the answer stays 24.0.

## Code

The scanner reads signed integers from one input buffer.

```nim
proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  if negative:
    return -value
  return value
```

The minus branch keeps negative coordinates intact. The loop ends at the buffer end, so it reads at most one token per call. The scan costs one pass over the input bytes.

Cross products use 64-bit integers and the hull uses a monotone chain.

```nim
proc crossAt(origin, first, second: Point): int64 =
  let deltaX = first.x - origin.x
  let deltaY = first.y - origin.y
  let spanX = second.x - origin.x
  let spanY = second.y - origin.y
  return deltaX * spanY - deltaY * spanX

proc convexHull(points: var seq[Point]): seq[Point] =
  points.sort(comparePoint)
  var uniquePoints: seq[Point] = @[]
  for i in 0..<points.len:
    if i == 0 or points[i].x != points[i - 1].x or points[i].y != points[i - 1].y:
      uniquePoints.add points[i]
  if uniquePoints.len <= 1:
    return uniquePoints
  var lower: seq[Point] = @[]
  for i in 0..<uniquePoints.len:
    let current = uniquePoints[i]
    while lower.len >= 2 and crossAt(lower[lower.len - 2], lower[lower.len - 1], current) <= 0:
      lower.setLen(lower.len - 1)
    lower.add current
  var upper: seq[Point] = @[]
  var j = uniquePoints.len - 1
  while j >= 0:
    let current = uniquePoints[j]
    while upper.len >= 2 and crossAt(upper[upper.len - 2], upper[upper.len - 1], current) <= 0:
      upper.setLen(upper.len - 1)
    upper.add current
    j -= 1
  result = @[]
  for i in 0..<lower.len - 1:
    result.add lower[i]
  for i in 0..<upper.len - 1:
    result.add upper[i]
```

Each point enters and leaves a chain once. A nonpositive turn drops the middle point and keeps only extreme corners. Sorting dominates this block at O(n log n).

The sweep advances four indexes and records the best doubled area.

```nim
proc quadArea2(hull: seq[Point], leftIndex, lowerIndex, rightIndex, upperIndex: int): int64 =
  let diagonalX = hull[rightIndex].x - hull[leftIndex].x
  let diagonalY = hull[rightIndex].y - hull[leftIndex].y
  let spreadX = hull[upperIndex].x - hull[lowerIndex].x
  let spreadY = hull[upperIndex].y - hull[lowerIndex].y
  let value = diagonalX * spreadY - diagonalY * spreadX
  if value < 0:
    return -value
  return value

proc maxQuadArea2(hull: seq[Point]): int64 =
  let hullSize = hull.len
  var lowest = hull[0].y
  var highest = hull[0].y
  for i in 1..<hullSize:
    if hull[i].y < lowest: lowest = hull[i].y
    if hull[i].y > highest: highest = hull[i].y
  var firstIndex = -1
  var lastIndex = -1
  for i in 0..<hullSize:
    if hull[i].y == lowest:
      if firstIndex < 0 or hull[i].x < hull[firstIndex].x: firstIndex = i
    if hull[i].y == highest:
      if lastIndex < 0 or hull[i].x > hull[lastIndex].x: lastIndex = i
  var leftIndex = firstIndex
  var lowerIndex = firstIndex
  var rightIndex = lastIndex
  var upperIndex = lastIndex
  var best = 0.int64
  var steps = 0
  while true:
    while true:
      let nextLower = (lowerIndex + 1) mod hullSize
      if crossAt(hull[rightIndex], hull[leftIndex], hull[nextLower]) >
         crossAt(hull[rightIndex], hull[leftIndex], hull[lowerIndex]):
        lowerIndex = nextLower
      else:
        break
    while true:
      let nextUpper = (upperIndex + 1) mod hullSize
      if crossAt(hull[leftIndex], hull[rightIndex], hull[nextUpper]) >
         crossAt(hull[leftIndex], hull[rightIndex], hull[upperIndex]):
        upperIndex = nextUpper
      else:
        break
    let current = quadArea2(hull, leftIndex, lowerIndex, rightIndex, upperIndex)
    if current > best: best = current
    let nextLeft = (leftIndex + 1) mod hullSize
    let nextRight = (rightIndex + 1) mod hullSize
    if crossAt(hull[leftIndex], hull[nextLeft], hull[nextRight]) <=
       crossAt(hull[leftIndex], hull[nextLeft], hull[rightIndex]):
      leftIndex = nextLeft
    else:
      rightIndex = nextRight
    steps += 1
    if steps > hullSize + 2: break
    if leftIndex == lastIndex and rightIndex == firstIndex: break
  return best
```

The outer loop stops after the diagonal makes one half turn. The lowest and highest vertices give the first antipodal pair. The step guard prevents an endless loop on degenerate input. The whole sweep costs O(h).

The driver writes one answer per case into one output buffer.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let peakCount = nextInt(inputData, scanPos)
  var points: seq[Point] = @[]
  for i in 0..<peakCount:
    let peakX = nextInt(inputData, scanPos)
    let peakY = nextInt(inputData, scanPos)
    points.add Point(x: peakX.int64, y: peakY.int64)
  var hull = convexHull(points)
  let hullSize = hull.len
  var area2 = 0.int64
  if hullSize == 3:
    area2 = crossAt(hull[0], hull[1], hull[2])
    if area2 < 0: area2 = -area2
  elif hullSize > 3:
    area2 = maxQuadArea2(hull)
  let wholePart = area2 div 2
  let digitPart = if area2 mod 2 == 0: '0' else: '5'
  outputBuffer.add $(wholePart)
  outputBuffer.add '.'
  outputBuffer.add digitPart
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
```

A doubled area is even or odd, so the only decimal digits are 0 and 5. The buffer flushes in blocks and once more after the loop. Reading input once avoids a syscall per line.

## Complexity

Input scanning costs O(n) per case. Sorting for the hull costs O(n log n) per case. The calipers sweep costs O(h) per case, where h is the hull size.

Total time is O(n log n + h) per case and O(T n log n) for T cases. Space is O(n) per case. A search over all groups of four peaks costs O(n^4) per case.
