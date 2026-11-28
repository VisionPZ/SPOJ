# MPOLSTAR — Star Polygon or Not (SPOJ)

<https://www.spoj.com/problems/MPOLSTAR/>

## Problem

Decide whether a simple polygon has one point that sees every part of it, and print 1 when it does. A point sees the whole polygon when the segment to every other point stays inside.

Each dataset gives the vertex count n, then n pairs of integer coordinates in counterclockwise order. A line holding 0 ends input. Each dataset produces one line holding 1 or 0.

| item | bound |
|---|---|
| vertices n | 4 to 50 |
| coordinates | 0 to 10000 |
| polygon | simple, no three edge lines concurrent |
| judge limit | 1000 ms, 1536 MB |

The vertex count drives the cubic pair-and-edge scan.

Sample input:

```
6
66 13
96 61
76 98
13 94
4 0
45 68
8
27 21
55 14
93 12
56 95
15 48
38 46
51 65
64 31
0
```

Sample output:

```
1
0
```

## Idea

Treat every edge as a fence that keeps allowed points on its left, like slicing a cake with straight cuts. The center exists exactly when all those half-planes share a point. If they do, their intersection has corners at crossings of edge lines, so testing every pair of lines finds a center. Each pair costs a scan of all edges. Scanning a dense grid of candidate points would miss narrow regions and cost far more.

| step | cost |
|---|---|
| pair edge lines | O(n squared) pairs |
| test one crossing | O(n) edge checks |
| total | O(n cubed) |

The pair count sets the cost for each dataset.

## Why It Works

1. For a counterclockwise polygon, the interior lies to the left of every directed edge.
2. A point sees the whole polygon when it lies to the left of every edge line, which is the kernel.
3. The kernel is the intersection of n half-planes, so it is convex and bounded.
4. A nonempty bounded convex region has a corner formed by two of its boundary lines.
5. Testing every pair of edge lines therefore finds a center whenever one exists.

| term | meaning |
|---|---|
| `denominator` | cross product of two edge directions |
| `lineParameter` | signed distance along the first edge line |
| `pointX` | rational center numerator times its denominator |
| `edgeSatisfied` | exact integer test for one half-plane |

The table names the exact-integer pieces of one line crossing.

A script-generated trace for the first sample polygon:

```
candidate center (45, 68)
edge 0 cross value  2658
edge 1 cross value  1747
edge 2 cross value  1766
edge 3 cross value  3242
edge 4 cross value     0
edge 5 cross value     0
all six values are nonnegative, so the answer is 1
```

The trace uses a real vertex as the center and matches the sample.

## Code

**Hand scanner and buffered output.** One read pass loads every dataset, and one string buffers the answers.

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

The scanner ignores all line breaks between coordinates.
The buffer flushes once per 131072 bytes.
A final flush ends the run.

**Exact half-plane test.** Cross products stay in integers, so no rounding decides an answer.

```nim
proc edgeSatisfied(edgeStartX: int64, edgeStartY: int64, edgeDeltaX: int64,
                   edgeDeltaY: int64, pointX: int64, pointY: int64,
                   denominator: int64): bool =
  let offsetX = pointX - edgeStartX * denominator
  let offsetY = pointY - edgeStartY * denominator
  let crossValue = edgeDeltaX * offsetY - edgeDeltaY * offsetX
  return crossValue >= 0

proc feasibleAtIntersection(verticesX: seq[int], verticesY: seq[int],
                            firstEdge: int, secondEdge: int): bool =
  let vertexCount = verticesX.len
  let firstStartX = int64(verticesX[firstEdge])
  let firstStartY = int64(verticesY[firstEdge])
  let firstEndIndex = (firstEdge + 1) mod vertexCount
  let firstDeltaX = int64(verticesX[firstEndIndex]) - firstStartX
  let firstDeltaY = int64(verticesY[firstEndIndex]) - firstStartY
  let secondStartX = int64(verticesX[secondEdge])
  let secondStartY = int64(verticesY[secondEdge])
  let secondEndIndex = (secondEdge + 1) mod vertexCount
  let secondDeltaX = int64(verticesX[secondEndIndex]) - secondStartX
  let secondDeltaY = int64(verticesY[secondEndIndex]) - secondStartY
  var denominator = firstDeltaX * secondDeltaY - firstDeltaY * secondDeltaX
  if denominator == 0:
    return false
  let startOffsetX = secondStartX - firstStartX
  let startOffsetY = secondStartY - firstStartY
  let lineParameter = startOffsetX * secondDeltaY - startOffsetY * secondDeltaX
  var pointX = firstStartX * denominator + lineParameter * firstDeltaX
  var pointY = firstStartY * denominator + lineParameter * firstDeltaY
  if denominator < 0:
    denominator = -denominator
    pointX = -pointX
    pointY = -pointY
  for edgeIndex in 0 .. vertexCount - 1:
    let edgeStartX = int64(verticesX[edgeIndex])
    let edgeStartY = int64(verticesY[edgeIndex])
    let nextIndex = (edgeIndex + 1) mod vertexCount
    let edgeDeltaX = int64(verticesX[nextIndex]) - edgeStartX
    let edgeDeltaY = int64(verticesY[nextIndex]) - edgeStartY
    if not edgeSatisfied(edgeStartX, edgeStartY, edgeDeltaX, edgeDeltaY,
                         pointX, pointY, denominator):
      return false
  return true
```

Parallel lines are skipped because they share no crossing.
A negative denominator is flipped before the sign tests.
Each tested crossing is held as a numerator over one shared positive denominator.

**Dataset loop.** Each polygon tests pairs until one crossing passes every edge.

```nim
proc isStarShaped(verticesX: seq[int], verticesY: seq[int]): bool =
  let vertexCount = verticesX.len
  for firstEdge in 0 .. vertexCount - 2:
    for secondEdge in firstEdge + 1 .. vertexCount - 1:
      if feasibleAtIntersection(verticesX, verticesY, firstEdge, secondEdge):
        return true
  return false

while true:
  let vertexCount = nextInt(inputData, scanPos)
  if vertexCount == 0:
    break
  var verticesX = newSeq[int](vertexCount)
  var verticesY = newSeq[int](vertexCount)
  for vertexIndex in 0 .. vertexCount - 1:
    verticesX[vertexIndex] = nextInt(inputData, scanPos)
    verticesY[vertexIndex] = nextInt(inputData, scanPos)
  if isStarShaped(verticesX, verticesY):
    appendOutput("1\n")
  else:
    appendOutput("0\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The search stops at the first feasible crossing.
Coordinates are stored in two arrays for direct indexing.
The zero vertex count ends input without producing output.

## Complexity

Each dataset examines every edge pair and checks every edge at each crossing.

| phase | time | space |
|---|---|---|
| input read | one pass over coordinate pairs | two arrays of n values |
| pair scan | up to n squared crossings | constant |
| edge checks | n per crossing | constant |
| output | one write per block | block buffer |

The cubic edge checks dominate the run.

| measure | Big O |
|---|---|
| time | O(n cubed) per dataset |
| space | O(n) |

Sampling a fine grid would still miss thin kernels, while the pair scan is exact.
