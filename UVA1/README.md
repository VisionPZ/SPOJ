# UVA1 — Radiation (SPOJ)

<https://www.spoj.com/problems/UVA1/>

## Problem

Count houses that lie inside both radiation circles, for many pairs of radii. Each query gives one radius for each plant, and the answer is the size of the intersection.

The input holds at most three test cases. Each case starts with N, the number of houses, followed by N coordinate pairs. A line then gives ax, ay, bx, by and q. Each of the next q lines gives radii R1 and R2. A line containing a single zero ends the input. Print "Case k:" followed by one answer line per query.

| item | bound |
|---|---|
| test cases | at most 3 |
| houses N | 0 < N <= 200000 |
| coordinates | 0 <= x, y <= 20000 |
| queries q | 0 < q <= 20000 |
| radii | 0 < R1, R2 <= 13000 |
| judge limit | 3000 ms, 1536 MB |

A house counts when its squared distance to each center is at most the matching squared radius.

Sample input:

```
11
95 75
27 6
93 5
124 13
34 49
65 61
81 49
77 33
110 50
91 22
110 25
57 42 97 36 1
31 25
0
```

Sample output:

```
Case 1:
2
```

## Idea

Sort the queries by first radius and turn on houses as they enter, like opening a gate and counting everyone already inside a second gate. Squared distances keep the comparison exact without square roots. A Fenwick tree over second-distance ranks reports the active houses within the second radius. Checking every house for every query costs N times q steps and grows too large. Sweep the queries once and use logarithmic updates.

## Why It Works

1. Comparing squared distances to squared radii gives the same result as comparing distances.
2. Sorting houses by second distance assigns each house a rank from one to N.
3. Sorting queries by first radius lets one sweep add each house exactly once.
4. The Fenwick tree holds a one at the rank of every house already inside the first circle.
5. A binary search over sorted second distances gives the rank limit for the second radius.
6. The tree prefix sum at that limit equals the number of houses inside both circles.
7. Storing the original query index restores the input order of the answers.

| term | meaning |
|---|---|
| `distanceFirst` | squared distance to the first plant |
| `distanceSecond` | squared distance to the second plant |
| `secondRank` | position of a house in the second-distance order |
| `fenwickTree` | active-house counts over second-distance ranks |
| `secondCount` | number of houses within the second radius in the full set |

For the sample, centers are (57,42) and (97,36) with radii 31 and 25. The house at (81,49) has squared distances 625 and 425, both under 961 and 625. The house at (77,33) has squared distances 481 and 409. No other house passes both tests, so the answer is 2.

Radii stay below 13001 and coordinates below 20001, so every square fits an int64.

## Code

**Input, ordering, and tree helpers.** The program defines house and query records plus the sweep tools.

```nim
import algorithm

const flushBlockBytes = 1 shl 17

type
  House = object
    distanceFirst: int64
    distanceSecond: int64
    secondRank: int

  Query = object
    radiusFirstSq: int64
    radiusSecondSq: int64
    originalIndex: int
    answer: int

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

proc compareBySecond(left: House, right: House): int =
  if left.distanceSecond < right.distanceSecond:
    return -1
  if left.distanceSecond > right.distanceSecond:
    return 1
  return 0

proc compareByFirst(left: House, right: House): int =
  if left.distanceFirst < right.distanceFirst:
    return -1
  if left.distanceFirst > right.distanceFirst:
    return 1
  return 0

proc compareByRadius(left: Query, right: Query): int =
  if left.radiusFirstSq < right.radiusFirstSq:
    return -1
  if left.radiusFirstSq > right.radiusFirstSq:
    return 1
  return 0

proc upperBound(values: seq[int64], target: int64): int =
  var low = 0
  var high = values.len
  while low < high:
    let middle = (low + high) div 2
    if values[middle] <= target:
      low = middle + 1
    else:
      high = middle
  return low

proc fenwickAdd(tree: var seq[int], index: int) =
  var position = index
  while position < tree.len:
    tree[position] += 1
    position += position and (-position)

proc fenwickSum(tree: var seq[int], index: int): int =
  var total = 0
  var position = index
  while position > 0:
    total += tree[position]
    position -= position and (-position)
  return total
```

Comparators give the explicit ordering Nim 0.19.4 needs.
`upperBound` counts second distances at or below a radius.
The Fenwick tree updates and queries in logarithmic steps.

**Sweep and report.** Each case sorts twice, sweeps once, and writes answers in input order.

```nim
var caseNumber = 0
while true:
  let houseCount = nextInt(inputData, scanPos)
  if houseCount == 0:
    break
  caseNumber += 1
  var houseX = newSeq[int](houseCount)
  var houseY = newSeq[int](houseCount)
  for houseIndex in 0 .. houseCount - 1:
    houseX[houseIndex] = nextInt(inputData, scanPos)
    houseY[houseIndex] = nextInt(inputData, scanPos)
  let centerAx = nextInt(inputData, scanPos)
  let centerAy = nextInt(inputData, scanPos)
  let centerBx = nextInt(inputData, scanPos)
  let centerBy = nextInt(inputData, scanPos)
  let queryCount = nextInt(inputData, scanPos)
  var houses = newSeq[House](houseCount)
  for houseIndex in 0 .. houseCount - 1:
    let deltaAx = int64(houseX[houseIndex] - centerAx)
    let deltaAy = int64(houseY[houseIndex] - centerAy)
    let deltaBx = int64(houseX[houseIndex] - centerBx)
    let deltaBy = int64(houseY[houseIndex] - centerBy)
    houses[houseIndex].distanceFirst = deltaAx * deltaAx + deltaAy * deltaAy
    houses[houseIndex].distanceSecond = deltaBx * deltaBx + deltaBy * deltaBy
  houses.sort(compareBySecond)
  var sortedSecond = newSeq[int64](houseCount)
  for houseIndex in 0 .. houseCount - 1:
    houses[houseIndex].secondRank = houseIndex + 1
    sortedSecond[houseIndex] = houses[houseIndex].distanceSecond
  var queries = newSeq[Query](queryCount)
  for queryIndex in 0 .. queryCount - 1:
    let radiusFirst = int64(nextInt(inputData, scanPos))
    let radiusSecond = int64(nextInt(inputData, scanPos))
    queries[queryIndex].radiusFirstSq = radiusFirst * radiusFirst
    queries[queryIndex].radiusSecondSq = radiusSecond * radiusSecond
    queries[queryIndex].originalIndex = queryIndex
  var sortedQueries = queries
  sortedQueries.sort(compareByRadius)
  houses.sort(compareByFirst)
  var fenwickTree = newSeq[int](houseCount + 1)
  var nextHouse = 0
  for queryItem in sortedQueries:
    while nextHouse < houseCount and houses[nextHouse].distanceFirst <= queryItem.radiusFirstSq:
      fenwickAdd(fenwickTree, houses[nextHouse].secondRank)
      nextHouse += 1
    let secondCount = upperBound(sortedSecond, queryItem.radiusSecondSq)
    queries[queryItem.originalIndex].answer = fenwickSum(fenwickTree, secondCount)
  appendOutput("Case " & $caseNumber & ":\n")
  for queryIndex in 0 .. queryCount - 1:
    appendOutput($queries[queryIndex].answer)
    outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The zero house count ends the input loop.
Each house enters the tree once during the sweep.
Original indices keep the printed answers in query order.

## Complexity

Sorting dominates each case, and the sweep adds logarithmic work per house and query.

| phase | time | space |
|---|---|---|
| input read | one pass over houses and queries | one input string |
| sorting | two house sorts and one query sort | arrays of records |
| sweep | N updates and q prefix sums | Fenwick tree of size N |
| output | q + 1 lines per case | block buffer |

| measure | Big O |
|---|---|
| time per case | O((N + q) log N) |
| space | O(N + q) |

Checking every house for every query costs O(N q), which reaches four billion steps at the largest bounds. The sweep reduces that to logarithmic work per item.
