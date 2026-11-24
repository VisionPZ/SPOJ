## Problem

Read a polygon and a herd of sheep. The polygon vertices arrive in counter-clockwise order. The shepherd stands at the origin and sees the whole interior. Count the sheep inside the polygon, including sheep on the fence. Print one count per test case.

The judge bounds are:

| quantity | limit |
| --- | --- |
| vertices per case | 3 to 100000 |
| sheep per case | 0 to 100000 |
| coordinate range | -32000 to 32000 |
| time limit | 1064 ms |
| memory limit | 1536 MB |

One case may hold 100000 vertices and 100000 sheep.

## Idea

The origin sees the whole interior, so every ray from the origin leaves the polygon once. The vertices follow angular order, so one binary search replaces a scan of all n edges. A triangle test then settles each sheep in O(log n) work.

## Why It Works

The shepherd sees the whole interior, so the polygon is star-shaped around the origin. Joining the origin to each consecutive pair of vertices splits the polygon into triangles with disjoint interiors. Each triangle covers one angular gap between neighbouring vertices. A sheep in that gap lies inside the polygon exactly when it lies inside that triangle.

Some vertices may share one ray from the origin. Those vertices form a radial chain on the fence. The farthest vertex in the chain gives the boundary distance.

A sheep at that angle lies inside when its squared radius does not exceed that vertex's squared radius.

The index rules are:

- `halfPlane` splits the circle at the x-axis into two halves.
- `compareAngle` orders two vectors by half, then by the sign of the cross product.
- `lowerBound` stops at the first vertex whose angle passes the sheep's angle.
- `beforePos` and `afterPos` wrap with modulo to name the gap endpoints.
- `rayMaxSq` holds the largest squared radius on each ray.

The sample vertices sort as (5,1), (2,2), (4,4), (6,6), (-3,1), (-1,-1). The decisions are:

| sheep | sector or ray | crosses | result |
| --- | --- | --- | --- |
| (2,1) | (5,1) to (2,2) | 3, 2, 3 | inside |
| (3,2) | (5,1) to (2,2) | 7, 2, -1 | outside |
| (6,6) | ray of (6,6), radius 8 against 8 | none | inside |
| (3,3) | ray of (6,6), radius 4 against 8 | none | inside |
| (-3,0) | (-3,1) to (-1,-1) | 3, 3, -2 | outside |

Three sheep lie inside, which matches the sample output.

## Code

The input pass reads every line into one buffer, then scans integers by hand. The scanner accepts a minus sign before the digits.

```nim
import algorithm

{.checks: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and data[position] != '-' and (data[position] < '0' or data[position] > '9'):
    position += 1
  var sign = 1
  if position < data.len and data[position] == '-':
    sign = -1
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return sign * value
```

The read loop runs until `readLine` returns false. The minus branch keeps negative coordinates exact. The scan walks the buffer once with growing position.

Angle order uses integer cross products, so no floating point is needed. Equal angles break ties by input order. This keeps neighbouring vertices adjacent.

```nim
proc halfPlane(x: int, y: int): int =
  if y > 0 or (y == 0 and x > 0): 0 else: 1

proc compareAngle(ax: int, ay: int, bx: int, by: int): int =
  let firstHalf = halfPlane(ax, ay)
  let secondHalf = halfPlane(bx, by)
  if firstHalf < secondHalf: return -1
  if firstHalf > secondHalf: return 1
  let turn = ax * by - ay * bx
  if turn > 0: return -1
  if turn < 0: return 1
  return 0

proc crossProduct(ax: int, ay: int, bx: int, by: int): int =
  return ax * by - ay * bx

var vertexX: seq[int]
var vertexY: seq[int]
var radiusSq: seq[int64]
var rayMaxSq: seq[int64]
var vertexOrder: seq[int]

proc compareVertex(leftIndex: int, rightIndex: int): int =
  let angleOrder = compareAngle(vertexX[leftIndex], vertexY[leftIndex], vertexX[rightIndex], vertexY[rightIndex])
  if angleOrder != 0: return angleOrder
  if leftIndex < rightIndex: return -1
  if leftIndex > rightIndex: return 1
  return 0
```

The comparator returns one of three signs, which the sort needs. The cross product stays within 64-bit integers. This block costs one comparison per sort step.

Each case reads its vertices once and sorts their indices by angle.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let vertexCount = nextInt(inputData, scanPos)
  let sheepCount = nextInt(inputData, scanPos)
  vertexX.setLen(vertexCount)
  vertexY.setLen(vertexCount)
  radiusSq.setLen(vertexCount)
  rayMaxSq.setLen(vertexCount)
  vertexOrder.setLen(vertexCount)
  for k in 0..<vertexCount:
    vertexX[k] = nextInt(inputData, scanPos)
    vertexY[k] = nextInt(inputData, scanPos)
    radiusSq[k] = int64(vertexX[k]) * int64(vertexX[k]) + int64(vertexY[k]) * int64(vertexY[k])
    vertexOrder[k] = k
  vertexOrder.sort(compareVertex)
  for k in 0..<vertexCount:
    rayMaxSq[k] = radiusSq[vertexOrder[k]]
  for k in 1..<vertexCount:
    if compareAngle(vertexX[vertexOrder[k]], vertexY[vertexOrder[k]],
                    vertexX[vertexOrder[k - 1]], vertexY[vertexOrder[k - 1]]) == 0 and
       rayMaxSq[k] < rayMaxSq[k - 1]:
      rayMaxSq[k] = rayMaxSq[k - 1]
  var backPos = vertexCount - 2
  while backPos >= 0:
    if compareAngle(vertexX[vertexOrder[backPos]], vertexY[vertexOrder[backPos]],
                    vertexX[vertexOrder[backPos + 1]], vertexY[vertexOrder[backPos + 1]]) == 0 and
       rayMaxSq[backPos] < rayMaxSq[backPos + 1]:
      rayMaxSq[backPos] = rayMaxSq[backPos + 1]
    backPos -= 1
```

The vertex loop runs exactly `vertexCount` times. Squared radii use `int64` to avoid overflow. Two passes fill `rayMaxSq` with the largest squared radius on each ray. Reusing the sequences keeps allocation out of the loop.

The query loop finds the gap for each sheep and applies the containment test.

```nim
  var insideCount = 0
  for s in 0..<sheepCount:
    let sheepX = nextInt(inputData, scanPos)
    let sheepY = nextInt(inputData, scanPos)
    if sheepX == 0 and sheepY == 0:
      insideCount += 1
      continue
    var lowerBound = 0
    var upperBound = vertexCount
    while lowerBound < upperBound:
      let middle = (lowerBound + upperBound) div 2
      let vertexIndex = vertexOrder[middle]
      if compareAngle(vertexX[vertexIndex], vertexY[vertexIndex], sheepX, sheepY) <= 0:
        lowerBound = middle + 1
      else:
        upperBound = middle
    let firstGreater = lowerBound
    let beforePos = (firstGreater - 1 + vertexCount) mod vertexCount
    let afterPos = firstGreater mod vertexCount
    let beforeIndex = vertexOrder[beforePos]
    let afterIndex = vertexOrder[afterPos]
    if compareAngle(vertexX[beforeIndex], vertexY[beforeIndex], sheepX, sheepY) == 0:
      let sheepRadius = int64(sheepX) * int64(sheepX) + int64(sheepY) * int64(sheepY)
      if sheepRadius <= rayMaxSq[beforePos]:
        insideCount += 1
    else:
      let leftX = vertexX[beforeIndex]
      let leftY = vertexY[beforeIndex]
      let rightX = vertexX[afterIndex]
      let rightY = vertexY[afterIndex]
      if crossProduct(leftX, leftY, sheepX, sheepY) >= 0 and
         crossProduct(sheepX, sheepY, rightX, rightY) >= 0 and
         crossProduct(rightX - leftX, rightY - leftY, sheepX - leftX, sheepY - leftY) >= 0:
        insideCount += 1
  appendOutput($(insideCount))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The binary search halves the sorted index range each step, so it costs O(log n) comparisons. The modulo wraps the search ends around the circle. Non-negative cross products include sheep on the fence. The output buffer flushes in blocks of `flushBlockBytes`.

## Complexity

Reading all input costs O(T) time for T tokens. Sorting the vertices costs O(n log n) per case. Each sheep costs O(log n) time for the binary search and O(1) for the triangle test. The total is O(n log n + m log n) time per case.

The arrays hold O(n) integers per case. The input buffer and output block add O(T) and O(flushBlockBytes) space.

A full ray cast over every edge costs O(n m) time per case. The angular gap method removes that product.
