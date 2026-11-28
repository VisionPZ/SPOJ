# SHAMAN — Shamans (SPOJ)
<https://www.spoj.com/problems/SHAMAN/>

## Problem

Four shamans choose peaks as the corners of a quadrangle, and the tribe wants the largest possible area. Print the maximum area with one decimal digit.

Input: an integer t, a blank line, then t cases separated by blank lines. Each case gives peak count n, followed by n lines with x and y. Output: one number per case with exactly one digit after the decimal point.

The statement sets these bounds.

| Item | Bound |
| --- | --- |
| Test cases | at most 80 |
| Peaks n | 4 to 2000 |
| Coordinates x and y | minus 20000 to 20000 |
| Output precision | exactly one decimal digit |
| Judge time limit | 1000 ms |
| Judge memory limit | 1536 MB |

A concave quadrangle counts as the area of its convex hull.

The sample input:

```
2

4
0 0
1 0
1 1
0 1

4
0 0
0 1
1 1
1 0

```

The sample output:

```
1.0
1.0
```

## Idea

Wrap a rubber band around all the peaks before choosing corners, like finding the outline of a cluster of dots. A point inside that outline never helps maximize area. So the best four corners lie on the outline itself.

The program builds the convex hull with a monotone chain sort. It then rotates two pairs of pointers around the hull with rotating calipers. For a fixed diagonal, the farthest points on each side give the largest area. Each pointer moves forward at most once around the hull, so the scan costs O(H), where H is the hull size. Sorting costs O(n log n). Trying every quadruple would cost O(n to the fourth).

The hull shrinks the search from thousands of peaks to tens.

## Why It Works

Four facts carry the program.

1. A convex hull encloses every peak. Moving a chosen corner outward onto the hull can only increase area, so an optimal quadrangle uses hull vertices.
2. For a fixed diagonal, the area is half a cross product. That product uses the diagonal and the spread between the other two corners. Maximizing area means maximizing the product.
3. Rotating calipers keep two pointers moving forward only. Cross products rise then fall as a pointer advances, so each best side point is found in one pass.
4. Coordinates are integers, so twice the area is an integer. The program keeps that doubled value and prints either a zero or a five as the decimal digit.

Each term has one job.

| Term | Meaning |
| --- | --- |
| `convexHull` | outline vertices in counter-clockwise order |
| `crossAt` | signed cross product at three points |
| `quadArea2` | doubled area of one quadrangle |
| `maxQuadArea2` | best doubled area from the rotating scan |

No floating point is used, so no rounding error enters the computation.

A script computes the doubled area for the first sample square.

```text
hull: (0,0) (1,0) (1,1) (0,1)
diagonal (0,0) -> (1,1): (1, 1)
spread (1,0) -> (0,1): (-1, 1)
cross = 1*1 - 1*(-1) = 2
doubled area 2, whole 2/2 = 1, digit 0
output 1.0
```

An odd doubled area prints a final 5, which gives exact halves.

## Code

**Point type and scanner.** Negative coordinates need a sign branch.

```nim
import algorithm

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

type
  Point = object
    x: int64
    y: int64

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

The scanner skips to a digit or a minus sign, then reads the magnitude. One value costs one pass over its digits.

**Hull construction.** Sorting and duplicate removal come first.

```nim
proc comparePoint(left, right: Point): int =
  if left.x < right.x: return -1
  if left.x > right.x: return 1
  if left.y < right.y: return -1
  if left.y > right.y: return 1
  return 0

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

The monotone chain builds a lower and an upper chain. A non-positive cross product pops the middle point. Sorting costs O(n log n), and each chain costs O(n).

**Area of one quadrangle.** The doubled value stays an integer.

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
```

The two diagonal vectors form a parallelogram. Its area equals twice the quadrangle area. The absolute value keeps the result positive.

**Rotating scan.** Four pointers advance only forward.

```nim
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

The scan starts from the lowest and highest hull vertices. The step count caps the loop, and the index match stops a full turn. Each pointer moves at most one lap, so the pass costs O(H).

**Driver.** One case prints one decimal digit.

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

A hull of three peaks is a triangle, so its cross product is the whole answer. The decimal digit is exact because doubled area is an integer. Blank lines need no special handling because the scanner skips them.

## Complexity

Sorting and the rotating scan set the cost.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | O(B) for B bytes | B bytes |
| Convex hull | O(n log n) | O(n) |
| Rotating calipers | O(H) | O(1) extra |
| Output | O(t) lines | one block |

H is the hull size, at most n.

| Measure | Big O |
| --- | --- |
| Time | O(n log n) per case |
| Space | O(n) per case |

Trying every quadruple would cost O(n to the fourth) time.
