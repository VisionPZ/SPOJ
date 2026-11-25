# FSHEEP — Fencing in the Sheep (SPOJ)
<https://www.spoj.com/problems/FSHEEP/>

## Problem

The input gives a polygon and a set of points representing sheep, with the observation point at the origin.
Count how many sheep lie inside the polygon or on its boundary.

The first line holds a test count t. Each case starts with a vertex count n and a sheep count m. Next come n vertex coordinates in counter-clockwise order, then m sheep coordinates. The shepherd stands at (0, 0). Print one integer per case, the number of sheep inside or on the fence.

The judge limits are:

| Item | Value |
| --- | --- |
| Vertices per case n | 3 to 100000 |
| Sheep per case m | 0 to 100000 |
| Coordinates | -32000 to 32000 |
| Time limit | 1064 ms |
| Memory limit | 1536 MB |

One case may hold 100000 vertices and 100000 sheep.

The sample input reads:

```text
1
6 5
2 2
4 4
6 6
-3 1
-1 -1
5 1
2 1
3 2
6 6
3 3
-3 0
```

The sample output reads:

```text
3
```

## Idea

The shepherd sees every corner from the origin, like rays spreading from a single point. Each ray from the origin crosses the fence once, so the vertices already lie in angular order. Sort them by angle (the direction of a vector around the circle), then binary search the gap that contains each sheep. A triangle test using cross products (signed area of a parallelogram) settles containment in constant time. Each sheep costs O(log n) comparisons. Casting a ray against every edge would cost O(n) per sheep. Takeaway: find the angular wedge first, then test one triangle.

## Why It Works

1. The origin sees the whole pen, so joining it to consecutive vertices splits the pen into triangles with disjoint interiors.
2. Each triangle covers one angular gap between neighboring vertices.
3. A sheep in that gap lies inside the pen exactly when it lies inside that triangle.
4. Vertices on the same ray form a radial chain, and the farthest one sets the boundary distance.
5. `halfPlane` splits the circle at the x-axis, and `compareAngle` orders vectors by half, then by cross-product sign.
6. Binary search stops at the first vertex whose angle passes the sheep's angle; modulo wraps the gap endpoints around the circle.
7. Non-negative cross products include sheep sitting on the fence.

The table defines each term.

| Term | Meaning |
| --- | --- |
| `vertexOrder` | vertex indices sorted by angle |
| `rayMaxSq` | largest squared radius on each ray |
| `crossProduct` | signed area between two vectors |
| `beforeIndex`, `afterIndex` | vertices bracketing the sheep's angle |

These five terms drive the angle search.

A script replayed the sample decisions.

| Sheep | Sector or ray | Cross products | Result |
| --- | --- | --- | --- |
| (2, 1) | (5, 1) to (2, 2) | 3, 2, 3 | inside |
| (3, 2) | (5, 1) to (2, 2) | 7, 2, -1 | outside |
| (6, 6) | ray of (6, 6), radius 8 against 8 | none | inside |
| (3, 3) | ray of (6, 6), radius 4 against 8 | none | inside |
| (-3, 0) | (-3, 1) to (-1, -1) | 3, 3, -2 | outside |

Three sheep lie inside, which matches the sample output.

## Code

**Input and angles.** The code reads once and compares directions with integer arithmetic.

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

The minus branch keeps negative coordinates exact. The scan walks the buffer once with a growing position. `checks: off` removes redundant bounds checks on the hot arrays. Each token costs one pass over its digits.

**Comparators and arrays.** Angle order uses cross products, so no floating point is needed.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

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

`compareVertex` breaks equal-angle ties by input index, which keeps neighbors adjacent. `leftIndex` and `rightIndex` name positions in the sorted index array. Each comparison costs constant time.

**Vertex setup.** Each case reads its vertices once and fills the farthest-radius table.

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

**Sheep queries.** A binary search finds the wedge, then a triangle test decides containment.

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

The binary search halves the sorted range each step, so it costs O(log n) comparisons. `beforePos` and `afterPos` wrap around the circle. Non-negative cross products include sheep on the fence. The final write flushes the buffered answer lines.

## Complexity

| Phase | Time | Space |
| --- | --- | --- |
| Read and sort vertices | O(n log n) | O(n) |
| Fill farthest radii | O(n) | O(n) |
| Query one sheep | O(log n) | O(1) |

The binary search keeps each sheep cheap.

The angular sort and the sheep queries both carry a logarithm.

| Measure | Bound |
| --- | --- |
| Per case | O(n log n + m log n) time |
| Per case | O(n) space |
| Total | linear in input bytes plus the sort and query terms |

A full ray cast over every edge costs O(n m) time per case. The angular gap method removes that product.
