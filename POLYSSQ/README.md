# POLYSSQ — Polygon (SPOJ)

<https://www.spoj.com/problems/POLYSSQ/>

## Problem

Choose K given points that form a convex polygon of smallest area. Report the integer part of that area, or zero when no such polygon exists.

Input gives N and K, then N coordinate pairs. Output one line with the integer part of the minimum area.

| item | bound |
|---|---|
| points N | 1 to 49 |
| vertices K | 1 to 10 |
| coordinate | 0 to 9998 |
| collinear triples | none |
| judge limit | 1000 ms, 1536 MB |

The combination count drives the design: choosing ten from forty-nine is far too large to enumerate.

Sample input:

```
4 3
0 0
1 1
0 10
10 0
```

Sample output:

```
5
```

## Idea

Pick the lowest-leftmost corner, then grow two chains around it like closing a fan one rib at a time.

Every convex polygon has a unique lowest-leftmost vertex. Other vertices appear in increasing angle around that pivot. A dynamic program follows that order and keeps only left turns, which guarantees convexity.
A state records the last two chosen vertices and the doubled area so far. Each transition adds one vertex. Trying every subset costs binomial time and cannot finish.
The final doubled area is halved by integer division.

## Why It Works

1. No three points are collinear, so the lowest-leftmost vertex of a polygon is unique.
2. The remaining vertices of a convex polygon have increasing polar angle around that pivot.
3. A left turn at every triple keeps the chain convex.
4. The shoelace cross-product sum equals twice the polygon area.
5. Integer division by two gives the integer part of the area.

| term | meaning |
|---|---|
| `crossProduct` | signed area of the turn at three points |
| `crossPair` | shoelace cross term for a segment from the pivot |
| `dynamicTable` | best doubled area per pivot, previous and current vertex |
| `bestDoubledArea` | minimum doubled area found over all pivots |

The table names the geometric pieces used by the program.

Worked example on the sample triangle with pivot (0, 0):

```
cross terms: (0,0)->(10,0) = 0, (10,0)->(1,1) = 10, (1,1)->(0,0) = 0
doubled area = 10, integer part = 10 div 2 = 5
```

The traced area matches the sample output.

## Code

**Geometry helpers and point order.** These routines measure turns and sort points left to right.

```nim
proc crossProduct(first: PlanePoint, second: PlanePoint, third: PlanePoint): int64 =
  return (second.x - first.x) * (third.y - first.y) - (second.y - first.y) * (third.x - first.x)

proc crossPair(first: PlanePoint, second: PlanePoint): int64 =
  return first.x * second.y - second.x * first.y

let pointCount = nextInt(inputData, scanPos)
let vertexCount = nextInt(inputData, scanPos)
var points = newSeq[PlanePoint](pointCount)
for pointIndex in 0 .. pointCount - 1:
  points[pointIndex].x = int64(nextInt(inputData, scanPos))
  points[pointIndex].y = int64(nextInt(inputData, scanPos))
for pointIndex in 1 .. pointCount - 1:
  let currentPoint = points[pointIndex]
  var insertAt = pointIndex
  while insertAt > 0 and (points[insertAt - 1].x > currentPoint.x or
        (points[insertAt - 1].x == currentPoint.x and points[insertAt - 1].y > currentPoint.y)):
    points[insertAt] = points[insertAt - 1]
    insertAt -= 1
  points[insertAt] = currentPoint

```

Cross products stay exact with integer coordinates.
The insertion sort breaks x ties by y.
Both helpers run in constant time.

**Convex chain DP.** This loop tries each pivot and extends left-turning chains.

```nim
var bestDoubledArea = sentinelValue
if vertexCount >= 3 and pointCount >= vertexCount:
  var dynamicTable = newSeq[int64]((pointCount + 1) * pointCount * (vertexCount + 1))
  for pivotIndex in 0 .. pointCount - 1:
    let pivotPoint = points[pivotIndex]
    var candidates = newSeq[PlanePoint]()
    for pointIndex in 0 .. pointCount - 1:
      let candidatePoint = points[pointIndex]
      if candidatePoint.y > pivotPoint.y or
         (candidatePoint.y == pivotPoint.y and candidatePoint.x > pivotPoint.x):
        candidates.add candidatePoint
    let candidateCount = candidates.len
    if candidateCount < vertexCount - 1:
      continue
    for candidateIndex in 1 .. candidateCount - 1:
      let currentCandidate = candidates[candidateIndex]
      var insertAt = candidateIndex
      while insertAt > 0 and crossProduct(pivotPoint, candidates[insertAt - 1], currentCandidate) < 0:
        candidates[insertAt] = candidates[insertAt - 1]
        insertAt -= 1
      candidates[insertAt] = currentCandidate
    for tableIndex in 0 .. dynamicTable.len - 1:
      dynamicTable[tableIndex] = sentinelValue
    for candidateIndex in 0 .. candidateCount - 1:
      let tableIndex = ((candidateCount + 1 + candidateCount) * candidateCount + candidateIndex)
      dynamicTable[tableIndex] = crossPair(pivotPoint, candidates[candidateIndex])
    for chosenCount in 1 .. vertexCount - 2:
      for previousIndex in 0 .. candidateCount:
        let previousPoint = if previousIndex == candidateCount: pivotPoint else: candidates[previousIndex]
        for currentIndex in 0 .. candidateCount - 1:
          let sourceIndex = ((chosenCount * (candidateCount + 1) + previousIndex) * candidateCount + currentIndex)
          let sourceValue = dynamicTable[sourceIndex]
          if sourceValue == sentinelValue:
            continue
          let currentPoint = candidates[currentIndex]
          for nextIndex in currentIndex + 1 .. candidateCount - 1:
            let nextPoint = candidates[nextIndex]
            if crossProduct(previousPoint, currentPoint, nextPoint) <= 0:
              continue
            let targetIndex = (((chosenCount + 1) * (candidateCount + 1) + currentIndex) * candidateCount + nextIndex)
            let candidateValue = sourceValue + crossPair(currentPoint, nextPoint)
            if candidateValue < dynamicTable[targetIndex]:
              dynamicTable[targetIndex] = candidateValue
    for previousIndex in 0 .. candidateCount - 1:
      for currentIndex in previousIndex + 1 .. candidateCount - 1:
        let sourceIndex = (((vertexCount - 1) * (candidateCount + 1) + previousIndex) * candidateCount + currentIndex)
        let sourceValue = dynamicTable[sourceIndex]
        if sourceValue == sentinelValue:
          continue
        if crossProduct(candidates[previousIndex], candidates[currentIndex], pivotPoint) <= 0:
          continue
        let candidateValue = sourceValue + crossPair(candidates[currentIndex], pivotPoint)
        if candidateValue > 0 and candidateValue < bestDoubledArea:
          bestDoubledArea = candidateValue

```

Candidates are sorted by angle around the pivot.
The sentinel marks unreachable table entries.
Only a left turn allows an extension.

**Answer step.** This step closes each chain and halves the best doubled area.

```nim
var answer: int64 = 0
if bestDoubledArea < sentinelValue:
  answer = bestDoubledArea div 2
appendOutput($answer)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Closing requires one final left turn at the last chosen vertex.
A positive doubled area means a real polygon exists.
Zero is printed when no polygon was found.

## Complexity

Costs come from pivots, triples of vertices and the polygon size.

| phase | time | space |
|---|---|---|
| point sort | O(N^2) | O(N) |
| angle sorts | O(N^2 log N) | O(N) |
| chain DP | O(N^3 K) | O(N^2 K) |
| output | one line | block buffer |

The chain DP dominates the phase table.

| measure | Big O |
|---|---|
| time | O(N^4 K) |
| space | O(N^2 K) |

Checking all K-subsets would take binomial time in N and cannot reach N = 49.
The pivot DP turns the search into polynomial work.
