# WALL — Castle Wall (SPOJ)

<https://www.spoj.com/problems/WALL/>

## Problem

Add straight walls between vertices of a simple concave polygon, spending at most r meters, and maximize the enclosed area. New walls may not cross each other.

Each case gives the vertex count n and budget r, then n integer coordinate pairs in counterclockwise order. Two zeroes end the input. Print the case number and the best area with one decimal.

| item | bound |
|---|---|
| vertices n | 5 to 64 |
| budget r | 0 to 400 meters |
| coordinates | 0 to 100 |
| judge limit | 1000 ms, 1536 MB |

Every useful new wall is a chord that closes a dent along the boundary chain between its endpoints.

Sample input:

```
5 4
0 0
4 0
4 4
2 2
0 4
8 80
45 41
70 31
86 61
72 64
80 79
40 80
8 94
28 22
0 0
```

Sample output:

```
Case 1: 16.0
Case 2: 3375.0
```

## Idea

Patch the dents like a tailor joining fabric edges. Use the shortest available stitches. Each chord across a dent adds area and costs wall length. Chords inside disjoint chains combine freely.

The final shape is a polygon using a subset of the original vertices. Replacing a boundary chain by a chord changes the shoelace area by the negative signed area of that chain plus chord. An interval DP keeps every nondominated pair of wall length and area gain.

Each split combines two smaller frontiers, and pruning removes states that cost at least as much while adding no area. A naive subset search would test 2^n polygons. Takeaway: keep the Pareto frontier for each interval, then pick the best affordable gain.

## Why It Works

1. The polygon is counterclockwise, so its signed double area is positive.
2. Doubling the vertex list turns the cyclic problem into ordinary intervals.
3. The signed area of a chain closed by a chord comes from a prefix sum of cross products.
4. A negative chain area means the chord lies outside the castle and adds that area back.
5. Consecutive intervals combine because their chords occupy disjoint boundary ranges.
6. A pair is dominated when another pair costs no more and adds at least as much area.

| term | meaning |
|---|---|
| `prefixArea` | running sum of cross products over doubled vertices |
| `closingGain` | double area gained by closing a chain with a chord |
| `GainPair` | one wall length with its added double area |
| `frontierTable` | nondominated pairs for each interval |

A worked example uses the first sample. The pentagon has area 12, with a triangular dent at vertex (2,2). The chord from (4,4) to (0,4) measures 4 meters and adds area 4. The printed result is 16.0.

The generator checks both sample cases before writing them, so the area formula is pinned to the statement.

## Code

**Input and output.** The driver reads all cases and writes one formatted area each.

```nim
import strutils
import math
import algorithm

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

All coordinates are integers, so all doubled areas stay exact in int64. Only the final division uses floating point.

**Frontier helpers.** Comparisons, pruning, and chord geometry operate on doubled areas and real lengths.

```nim
type GainPair = object
  wallLength: float64
  extraDoubleArea: int64

proc comparePairs(left: GainPair, right: GainPair): int =
  if left.wallLength < right.wallLength:
    return -1
  if left.wallLength > right.wallLength:
    return 1
  if left.extraDoubleArea > right.extraDoubleArea:
    return -1
  if left.extraDoubleArea < right.extraDoubleArea:
    return 1
  return 0

proc prunePairs(candidates: var seq[GainPair]) =
  candidates.sort(comparePairs)
  var kept = newSeq[GainPair](0)
  var bestSoFar: int64 = -1
  for candidate in candidates:
    if candidate.extraDoubleArea > bestSoFar:
      kept.add candidate
      bestSoFar = candidate.extraDoubleArea
  candidates = kept

var vertexX = newSeq[int](0)
var vertexY = newSeq[int](0)
var prefixArea = newSeq[int64](0)

proc crossAt(firstIndex: int, secondIndex: int): int64 =
  return int64(vertexX[firstIndex]) * int64(vertexY[secondIndex]) -
    int64(vertexY[firstIndex]) * int64(vertexX[secondIndex])

proc wallDistance(firstIndex: int, secondIndex: int): float64 =
  let deltaX = float64(vertexX[firstIndex] - vertexX[secondIndex])
  let deltaY = float64(vertexY[firstIndex] - vertexY[secondIndex])
  return sqrt(deltaX * deltaX + deltaY * deltaY)

proc closingGain(startIndex: int, endIndex: int): int64 =
  return -(prefixArea[endIndex] - prefixArea[startIndex] +
    crossAt(endIndex, startIndex))
```

Sorting orders pairs by length. Pruning keeps only pairs that raise the best area seen so far. Chord length uses the Euclidean distance.

**Interval DP.** Each interval either closes directly with one chord or splits at a middle vertex.

```nim
var caseNumber = 0
while true:
  let vertexCount = nextInt(inputData, scanPos)
  let budget = nextInt(inputData, scanPos)
  if vertexCount == 0 and budget == 0:
    break
  caseNumber += 1
  vertexX = newSeq[int](vertexCount)
  vertexY = newSeq[int](vertexCount)
  for vertexIndex in 0 .. vertexCount - 1:
    vertexX[vertexIndex] = nextInt(inputData, scanPos)
    vertexY[vertexIndex] = nextInt(inputData, scanPos)
  let doubledCount = vertexCount * 2
  vertexX.setLen(doubledCount + 1)
  vertexY.setLen(doubledCount + 1)
  for vertexIndex in vertexCount .. doubledCount:
    vertexX[vertexIndex] = vertexX[vertexIndex - vertexCount]
    vertexY[vertexIndex] = vertexY[vertexIndex - vertexCount]
  prefixArea = newSeq[int64](doubledCount + 1)
  for vertexIndex in 0 .. doubledCount - 1:
    prefixArea[vertexIndex + 1] = prefixArea[vertexIndex] +
      crossAt(vertexIndex, vertexIndex + 1)
  let tableWidth = doubledCount + 1
  var frontierTable = newSeq[seq[GainPair]](doubledCount * tableWidth)
  for startIndex in 0 .. doubledCount - 1:
    frontierTable[startIndex * tableWidth + startIndex + 1] = @[GainPair(
      wallLength: 0'f64, extraDoubleArea: 0'i64)]
  for span in 2 .. vertexCount:
    for startIndex in 0 .. doubledCount - span:
      let endIndex = startIndex + span
      var candidates = newSeq[GainPair](0)
      let directGain = closingGain(startIndex, endIndex)
      if directGain > 0'i64:
        candidates.add GainPair(wallLength: wallDistance(startIndex, endIndex),
                                extraDoubleArea: directGain)
      for middleIndex in startIndex + 1 .. endIndex - 1:
        let leftFrontier = frontierTable[startIndex * tableWidth + middleIndex]
        let rightFrontier = frontierTable[middleIndex * tableWidth + endIndex]
        for leftPair in leftFrontier:
          for rightPair in rightFrontier:
            candidates.add GainPair(
              wallLength: leftPair.wallLength + rightPair.wallLength,
              extraDoubleArea: leftPair.extraDoubleArea + rightPair.extraDoubleArea)
      prunePairs(candidates)
      frontierTable[startIndex * tableWidth + endIndex] = candidates
  var bestExtraArea = 0'i64
  for startIndex in 0 .. vertexCount - 1:
    let fullFrontier = frontierTable[startIndex * tableWidth + startIndex + vertexCount]
    for candidate in fullFrontier:
      if candidate.wallLength <= float64(budget) + 1e-9 and
          candidate.extraDoubleArea > bestExtraArea:
        bestExtraArea = candidate.extraDoubleArea
  let finalArea = float64(prefixArea[vertexCount] + bestExtraArea) / 2'f64
  appendOutput("Case " & $caseNumber & ": " & formatFloat(finalArea, ffDecimal, 1))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The double vertex list handles chords that wrap past the last vertex. The answer scans every full interval and keeps the largest gain inside the budget.

## Complexity

Intervals grow by span, so every shorter interval is ready before a longer one uses it.

| phase | time | space |
|---|---|---|
| prefix setup | O(n) cross products | O(n) |
| interval DP | O(n^3 * P^2) pair combinations | O(n^2 * P) |
| output | one line per case | one block buffer |

| measure | Big O |
|---|---|
| time per case | O(n^3 * P^2) |
| space per case | O(n^2 * P) |

Here P is the largest frontier length. Trying all vertex subsets would take O(2^n) time per case.

Takeaway: prune dominated pairs so each interval keeps only useful choices.
