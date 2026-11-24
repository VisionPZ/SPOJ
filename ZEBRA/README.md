## Problem

Pedestrians wait along one edge of a street. Each walks a straight line to the far edge at a fixed time and angle. Pick a starting point, an angle, and a speed at most v to hit as many people as possible. Print one maximum per test case.

The bounds set the work per case.

| Quantity | Bound |
| --- | --- |
| Test cases | 100 |
| Pedestrians per case | 10000 |
| Street width | 1 to 100 m |
| Speed limit | 1 to 10000 m/s |
| Angle step | 1/60 degree, from -5000 to 5000 |
| Time limit | 17000 ms |
| Memory limit | 1536 MB |

A million pedestrians in one input forces one efficient pass per crossing-time group.

## Idea

Sort people into groups by crossing time. A hit above the pavement requires our crossing time to equal that person's time. Within one group, sweep our starting point and keep landing-point counts in a lazy segment tree.

Each person costs two range updates and one range maximum query, both logarithmic.

## Why It Works

Every person has a bottom position x and a far-side position p.

p = x + tan(a) * w, with a measured in sixtieths of a degree.

Our path runs from start a to finish b. It crosses that person when the ends sit on opposite sides.

(a - x) * (b - p) <= 0, and a never equals x.

The speed limit caps horizontal travel.

D = sqrt((v * t)^2 - w^2), and |b - a| <= D.

For a start inside the gap (x_left, x_right), a feasible finish obeying the cap lies in (x_left - D, x_right + D).

Landing values are split into point cells at each p and interval cells between them. Moving one person from the right set to the left set adds one to cells below p and subtracts one from cells above p. The cell at p stays unchanged.

The sample in gen.py gives this worked case. The street is 20 m wide and the speed cap is 2 m/s. Two people take 10 seconds, start at -20 and 20, and walk at 45 degrees in opposite directions, so both have p = 0. Their group has D = 0, so start and finish must match. Starting and finishing at 0 hits both at the far edge. The other three people need 20 m/s in one second and cannot be reached. The answer is 2.

## Code

```nim
{.push checks: off.}
{.push overflowChecks: off.}
{.push rangeChecks: off.}
{.push boundChecks: off.}
{.push stackTrace: off.}

import algorithm
import math

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const infinityValue = 1e100
const boundaryEpsilon = 1e-7
const topMergeEpsilon = 1e-6
const radiansPerMinute = 3.14159265358979323846 / 10800.0
const missingValue = -1000000000
const maximumCrossingTime = 10000

type RawPedestrian = tuple[bottom: int, angle: int]
type PlacedPedestrian = tuple[bottom: int, top: float, topRank: int]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9') and data[position] != '-':
    position += 1
  var sign = 1
  if position < data.len and data[position] == '-':
    sign = -1
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value * sign

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The input loop runs until readLine fails, so the whole stream becomes one buffer. The scanner walks by index and stops at data.len. It keeps the minus sign because positions and angles are negative. The output buffer flushes once it passes flushBlockBytes. That costs one write per 256 KiB instead of one write per answer.

```nim
proc compareFloat(left, right: float): int =
  if left < right: return -1
  if left > right: return 1
  return 0

proc comparePedestrian(left, right: PlacedPedestrian): int =
  if left.bottom < right.bottom: return -1
  if left.bottom > right.bottom: return 1
  return compareFloat(left.top, right.top)

proc lowerBound(values: seq[float], target: float): int =
  var lo = 0
  var hi = values.len
  while lo < hi:
    let mid = (lo + hi) div 2
    if values[mid] < target: lo = mid + 1
    else: hi = mid
  return lo

proc upperBound(values: seq[float], target: float): int =
  var lo = 0
  var hi = values.len
  while lo < hi:
    let mid = (lo + hi) div 2
    if values[mid] <= target: lo = mid + 1
    else: hi = mid
  return lo
```

Each binary search halves its slice, so it takes log2 of the cell count steps. lowerBound uses a strict comparison and upperBound uses a non-strict one. That difference decides whether a cell at the boundary enters the query range.

```nim
var treeMax: seq[int] = @[]
var treeLazy: seq[int] = @[]
var treeSize = 0

proc applyTree(node, delta: int) =
  treeMax[node] += delta
  treeLazy[node] += delta

proc pushTree(node: int) =
  if treeLazy[node] != 0 and node < treeSize:
    applyTree(node * 2, treeLazy[node])
    applyTree(node * 2 + 1, treeLazy[node])
    treeLazy[node] = 0

proc addTree(node, low, high, fromIndex, toIndex, delta: int) =
  if fromIndex <= low and high <= toIndex:
    applyTree(node, delta)
    return
  pushTree(node)
  let middle = (low + high) div 2
  if fromIndex <= middle: addTree(node * 2, low, middle, fromIndex, toIndex, delta)
  if toIndex > middle: addTree(node * 2 + 1, middle + 1, high, fromIndex, toIndex, delta)
  treeMax[node] = max(treeMax[node * 2], treeMax[node * 2 + 1])

proc queryTree(node, low, high, fromIndex, toIndex: int): int =
  if fromIndex <= low and high <= toIndex: return treeMax[node]
  pushTree(node)
  let middle = (low + high) div 2
  var bestValue = missingValue
  if fromIndex <= middle: bestValue = max(bestValue, queryTree(node * 2, low, middle, fromIndex, toIndex))
  if toIndex > middle: bestValue = max(bestValue, queryTree(node * 2 + 1, middle + 1, high, fromIndex, toIndex))
  return bestValue
```

The tree covers leaf indexes from zero to treeSize minus one. addTree and queryTree recurse at most log2 of treeSize levels. pushTree ignores leaf nodes, which avoids writing past the packed arrays.

```nim
proc buildTree(values: seq[int], count: int) =
  treeSize = 1
  while treeSize < count: treeSize *= 2
  treeMax.setLen(treeSize * 2)
  treeLazy.setLen(treeSize * 2)
  for i in 0 ..< treeSize * 2: treeLazy[i] = 0
  for i in 0 ..< treeSize:
    if i < count: treeMax[treeSize + i] = values[i]
    else: treeMax[treeSize + i] = missingValue
  for i in countdown(treeSize - 1, 1):
    treeMax[i] = max(treeMax[i * 2], treeMax[i * 2 + 1])
```

The loop runs until treeSize reaches the next power of two above the cell count. Padding leaves receive missingValue so they never win a range maximum. Building the tree costs time linear in the cell count.

```nim
proc solveGroup(width, maxSpeed, crossingTime: int, raws: seq[RawPedestrian]): int =
  let speedTime = int64(maxSpeed) * int64(crossingTime)
  if speedTime < int64(width): return 0
  let widthSquared = int64(width) * int64(width)
  let displacement = sqrt(float(speedTime * speedTime - widthSquared))
  var items: seq[PlacedPedestrian] = @[]
  for raw in raws:
    let top = float(raw.bottom) + tan(float(raw.angle) * radiansPerMinute) * float(width)
    items.add (raw.bottom, top, 0)
  items.sort(comparePedestrian)
  var tops: seq[float] = @[]
  for item in items: tops.add item.top
  tops.sort(compareFloat)
  var distinctTops: seq[float] = @[]
  var ranksOfTops = newSeq[int](tops.len)
  var rankCounter = -1
  for i in 0 ..< tops.len:
    if i == 0 or tops[i] > tops[i - 1] + topMergeEpsilon:
      rankCounter += 1
      distinctTops.add tops[i]
    ranksOfTops[i] = rankCounter
  for i in 0 ..< items.len:
    items[i].topRank = ranksOfTops[lowerBound(tops, items[i].top)]
  let atomCount = distinctTops.len * 2 + 1
  var rankCounts = newSeq[int](distinctTops.len)
  for item in items: rankCounts[item.topRank] += 1
  var atomLow = newSeq[float](atomCount)
  var atomHigh = newSeq[float](atomCount)
  var initial = newSeq[int](atomCount)
  atomLow[0] = -infinityValue
  atomHigh[0] = distinctTops[0]
  var running = 0
  for rank in 0 ..< distinctTops.len:
    running += rankCounts[rank]
    let pointIndex = rank * 2 + 1
    atomLow[pointIndex] = distinctTops[rank]
    atomHigh[pointIndex] = distinctTops[rank]
    initial[pointIndex] = running
    let intervalIndex = rank * 2 + 2
    atomLow[intervalIndex] = distinctTops[rank]
    if rank + 1 < distinctTops.len: atomHigh[intervalIndex] = distinctTops[rank + 1]
    else: atomHigh[intervalIndex] = infinityValue
    initial[intervalIndex] = running
  buildTree(initial, atomCount)
  var best = 0
  for k in 0 .. items.len:
    let gapLow = if k == 0: -infinityValue else: float(items[k - 1].bottom)
    let gapHigh = if k == items.len: infinityValue else: float(items[k].bottom)
    if k > 0 and k < items.len and gapLow == gapHigh:
      discard
    else:
      let lowBound = if k == 0: -infinityValue else: gapLow - displacement
      let highBound = if k == items.len: infinityValue else: gapHigh + displacement
      let firstIndex = upperBound(atomHigh, lowBound + boundaryEpsilon)
      var lastIndex = lowerBound(atomLow, highBound - boundaryEpsilon) - 1
      if lastIndex >= atomCount: lastIndex = atomCount - 1
      if firstIndex <= lastIndex:
        let value = queryTree(1, 0, treeSize - 1, firstIndex, lastIndex)
        if value > best: best = value
    if k < items.len:
      let rank = items[k].topRank
      addTree(1, 0, treeSize - 1, 0, rank * 2, 1)
      addTree(1, 0, treeSize - 1, rank * 2 + 2, atomCount - 1, -1)
  return best
```

k runs from zero to items.len and splits the sorted people at index k. Tops within topMergeEpsilon share one cell, which removes rounding noise from angles such as 45 degrees. Empty gaps are skipped, and boundary cells use boundaryEpsilon. Each step costs two updates and one query, all logarithmic.

```nim
var groups = newSeq[seq[RawPedestrian]](maximumCrossingTime + 1)

let caseCount = nextInt(inputData, scanPos)
for j in 0 ..< caseCount:
  let peopleCount = nextInt(inputData, scanPos)
  let streetWidth = nextInt(inputData, scanPos)
  let speedLimit = nextInt(inputData, scanPos)
  var usedTimes: seq[int] = @[]
  for k in 0 ..< peopleCount:
    let position = nextInt(inputData, scanPos)
    let crossing = nextInt(inputData, scanPos)
    let angle = nextInt(inputData, scanPos)
    if groups[crossing].len == 0: usedTimes.add crossing
    groups[crossing].add (position, angle)
  var best = 0
  for crossing in usedTimes:
    let value = solveGroup(streetWidth, speedLimit, crossing, groups[crossing])
    if value > best: best = value
  for crossing in usedTimes: groups[crossing].setLen 0
  appendOutput($(best))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

j runs from zero to caseCount minus one. Pedestrians are bucketed by crossing time, and each bucket is cleared after its case. The scanner and the output buffer each touch their data once per value.

## Complexity

Reading and scanning the input takes O(total integers) time and O(input bytes) space. Building one group costs O(n) for the tops and O(n log n) for the sort. The sweep costs O(n log n): two updates and one query per person. The tree uses O(n) space for a group of n people.

Total time is O(N log n) for N pedestrians with the largest group of n. Total extra space is O(n) beyond the input buffer. Trying every start and finish pair would cost O(n^3) per group, so it cannot handle a full case.
