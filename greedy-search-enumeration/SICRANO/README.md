# SICRANO — Sicrano (SPOJ)

<https://www.spoj.com/problems/SICRANO/>

## Problem

A set of points and a set of segments are given in the plane. For every segment, report how many points lie on that segment, endpoints included. Equal point coordinates count as separate points.

The first integer is the number of test cases. Each test case gives the point count and segment count, then the point coordinates, then four integers per segment. Print one count per segment on its own line.

| item | bound |
|---|---|
| test cases | 1 to 20 |
| points per case | 1 to 50 |
| segments per case | 1 to 50 |
| coordinates | 0 to 100 |
| judge limit | 1000 ms, 1536 MB |

Blank lines may appear in the input, so the scanner skips everything outside numbers.

Sample input:

```
1
4 3
1 1
2 2
3 3
4 4
0 0 5 5
3 3 4 4
0 0 1 0
```

Sample output:

```
4
2
0
```

## Idea

A point lies on a segment when it sits on the same line and between the two ends, like a bead located on a stretched string. The cross product tests the line in one multiplication, and a bounding-box test rules out points beyond the ends. Scanning all points for every segment costs at most 2500 checks per case, so no spatial index is needed.

## Why It Works

1. The segment direction is the vector from the start point to the end point.
2. A point on that line makes the cross product with the direction zero.
3. The bounding box keeps only points between the two ends.
4. The two tests together hold exactly for points on the closed segment.
5. Each duplicate point passes the tests separately, so it is counted twice.

| term | meaning |
|---|---|
| `deltaX` | horizontal component of the segment direction |
| `deltaY` | vertical component of the segment direction |
| `crossProduct` | signed area test for collinearity |
| `lowX`, `highX` | smallest and largest segment x coordinate |
| `pointsOnSegment` | number of points inside one segment |

The cross product and box agree on every segment.

Script-generated trace for the sample segment from `(0, 0)` to `(5, 5)`:

```
quantity | value
direction | (5, 5)
point (1, 1) cross | 1*5 - 1*5 = 0
point (2, 2) cross | 2*5 - 2*5 = 0
point (3, 3) cross | 3*5 - 3*5 = 0
point (4, 4) cross | 4*5 - 4*5 = 0
points on segment | 4
```

All four sample points lie on the diagonal, so the count is four.

## Code

**Bulk input and buffered output.** One shared string holds the whole input; one string holds the answers.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The integer scanner ignores blank lines and spaces.
The answer buffer flushes once it reaches 128 KiB.
Both use the same cursor through the input.

**Segment counting.** Each segment tests every point with exact integer arithmetic.

```nim
let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let pointCount = nextInt(inputData, scanPos)
  let segmentCount = nextInt(inputData, scanPos)
  var pointXs = newSeq[int](pointCount)
  var pointYs = newSeq[int](pointCount)
  for pointIndex in 0 .. pointCount - 1:
    pointXs[pointIndex] = nextInt(inputData, scanPos)
    pointYs[pointIndex] = nextInt(inputData, scanPos)
  for segmentIndex in 0 .. segmentCount - 1:
    let startX = nextInt(inputData, scanPos)
    let startY = nextInt(inputData, scanPos)
    let endX = nextInt(inputData, scanPos)
    let endY = nextInt(inputData, scanPos)
    let deltaX = int64(endX - startX)
    let deltaY = int64(endY - startY)
    var lowX = startX
    var highX = endX
    if lowX > highX:
      let swapValue = lowX
      lowX = highX
      highX = swapValue
    var lowY = startY
    var highY = endY
    if lowY > highY:
      let swapValue = lowY
      lowY = highY
      highY = swapValue
    var pointsOnSegment = 0
    for pointIndex in 0 .. pointCount - 1:
      let candidateX = pointXs[pointIndex]
      let candidateY = pointYs[pointIndex]
      if candidateX < lowX or candidateX > highX or candidateY < lowY or candidateY > highY:
        continue
      let crossProduct = int64(candidateX - startX) * deltaY - int64(candidateY - startY) * deltaX
      if crossProduct == 0:
        pointsOnSegment += 1
    appendOutput($pointsOnSegment)
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The bounding box is normalised before the point loop.
The cross product uses 64-bit math to avoid overflow.
Each segment writes one buffered line.

## Complexity

Each segment scans the full point list once.

| phase | time | space |
|---|---|---|
| input read | one pass over all integers | one input string |
| segment scan | one cross product per point and segment | two point arrays |
| output | one line per segment | block buffer |

No geometry structure is built.

| measure | Big O |
|---|---|
| time per case | O(points times segments) |
| space per case | O(points) |

Sorting points by coordinate would add work without reducing the 2500 worst-case checks.

The direct scan keeps the code short and exact.
