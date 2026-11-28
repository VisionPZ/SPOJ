# VPL1_AD — Autumn Leaves (SPOJ)

<https://www.spoj.com/problems/VPL1_AD/>

## Problem

Find the shortest straight-line walk from the house at the origin that visits every leaf, ending at a leaf. Walk segments may cross at most K sticks in total. Report the distance to three decimals and the leaf order, choosing the smallest order when distances tie.

Input starts with a test count. Each test gives the leaf count, stick count and jump limit, then the leaf positions, then the stick endpoints. Output one line with `Scenario #i: distance`, followed by the path line with zero for the house and leaf indices after it. Print only `Scenario #i: -1` when no walk exists.

| item | bound |
|---|---|
| tests | 1 to 10 |
| leaves N | 1 to 10 |
| sticks M | 0 to 10 |
| jump limit K | 1 to 10 |
| coordinates | -1000 to 1000 |
| judge limit | 1000 ms, 1536 MB |

Ten leaves make a subset mask small enough for dynamic programming.

Sample input:

```
2
6 3 1
1 6
2 2
5 1
5 5
5 9
10 2
2 5 4 3
3 7 8 7
6 0 8 3
4 3 2
-2 -2
2 2
5 -1
6 6
0 3 1 0
-2 -5 5 2
0 5 7 0
```

Sample output:

```
Scenario #1: 26.044
0 2 3 6 4 1 5
Scenario #2: -1
```

The winning route crosses one stick, which is the whole jump budget.

## Idea

Think of a delivery route where crossing a barricade spends a ticket. Keep the best remaining distance for each set of visited leaves, current leaf and tickets spent. Fill those states backwards, then walk forward choosing the smallest leaf index that still reaches the optimum. Checking every leaf order would test up to ten factorial routes, while the mask table tests only subsets. Precompute leg distances and stick crossings once, then let the table choose.

## Why It Works

1. A walk is fully described by the order of leaves after the house.
2. Each leg contributes one Euclidean distance and a fixed number of crossed sticks.
3. A state stores the set of visited leaves, the last leaf and the jumps used so far.
4. Backward dynamic programming gives the shortest remaining walk from every state.
5. Choosing the smallest feasible next leaf at each step yields the lexicographically smallest optimal path.
6. Sticks are counted by exact orientation tests, including collinear touches.

| term | meaning |
|---|---|
| `crossings` | number of sticks crossed on each leg |
| `distances` | Euclidean length of each leg |
| `suffixBest` | shortest remaining distance from a state |
| `jumpLimit` | total sticks the walk may cross |
| `pathLeaves` | reconstructed walk including the house |
| `tieTolerance` | tolerance for comparing floating point totals |

All leg values are computed once before any mask state is filled.

A trace of the first sample route:

```
0 -> 2 distance 2.8284 crossed 0 total 2.8284
2 -> 3 distance 3.1623 crossed 0 total 5.9907
3 -> 6 distance 5.0990 crossed 1 total 11.0897
6 -> 4 distance 5.8310 crossed 0 total 16.9207
4 -> 1 distance 4.1231 crossed 0 total 21.0438
1 -> 5 distance 5.0000 crossed 0 total 26.0438
```

The single jump fits the budget, and the rounded total is 26.044.

## Code

**Reader and geometry.** The reader keeps negative coordinates and builds exact crossing tests.

```nim
import math

const flushBlockBytes = 1 shl 17
const unreachableDistance = 1e100
const tieTolerance = 1e-8

type GridPoint = tuple[x: int, y: int]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var negativeValue = false
  if pos < data.len and data[pos] == '-':
    negativeValue = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negativeValue:
    return -value
  return value
```

The scanner keeps minus signs for negative coordinates.
One input string holds all tests before any work starts.
Square roots appear only in leg distances, never in crossing tests.

```nim
proc turnValue(first: GridPoint, second: GridPoint, third: GridPoint): int64 =
  return int64(second.x - first.x) * int64(third.y - first.y) -
         int64(second.y - first.y) * int64(third.x - first.x)

proc onSegment(first: GridPoint, second: GridPoint, point: GridPoint): bool =
  return point.x >= min(first.x, second.x) and point.x <= max(first.x, second.x) and
         point.y >= min(first.y, second.y) and point.y <= max(first.y, second.y)

proc segmentsCross(firstA: GridPoint, firstB: GridPoint,
                   secondA: GridPoint, secondB: GridPoint): bool =
  let firstTurnA = turnValue(firstA, firstB, secondA)
  let firstTurnB = turnValue(firstA, firstB, secondB)
  let secondTurnA = turnValue(secondA, secondB, firstA)
  let secondTurnB = turnValue(secondA, secondB, firstB)
  if ((firstTurnA > 0 and firstTurnB < 0) or
      (firstTurnA < 0 and firstTurnB > 0)) and
     ((secondTurnA > 0 and secondTurnB < 0) or
      (secondTurnA < 0 and secondTurnB > 0)):
    return true
  if firstTurnA == 0 and onSegment(firstA, firstB, secondA):
    return true
  if firstTurnB == 0 and onSegment(firstA, firstB, secondB):
    return true
  if secondTurnA == 0 and onSegment(secondA, secondB, firstA):
    return true
  if secondTurnB == 0 and onSegment(secondA, secondB, firstB):
    return true
  return false

proc pointDistance(first: GridPoint, second: GridPoint): float =
  let deltaX = float(second.x - first.x)
  let deltaY = float(second.y - first.y)
  return sqrt(deltaX * deltaX + deltaY * deltaY)

proc appendFraction(thousandths: int64) =
  if thousandths < 100:
    appendOutput("0")
  if thousandths < 10:
    appendOutput("0")
  appendOutput($thousandths)
```

Proper crossings and touching endpoints both count as jumps.
Integer orientations avoid rounding errors in the crossing test.
The distance printer pads the fractional part to three digits.

**Leg tables and backward table.** Each leg is measured once, then states are filled in reverse mask order.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let leafCount = nextInt(inputData, scanPos)
  let stickCount = nextInt(inputData, scanPos)
  let jumpLimit = nextInt(inputData, scanPos)
  var gardenPoints = newSeq[GridPoint](leafCount + 1)
  gardenPoints[0] = (x: 0, y: 0)
  for leafIndex in 1 .. leafCount:
    let pointX = nextInt(inputData, scanPos)
    let pointY = nextInt(inputData, scanPos)
    gardenPoints[leafIndex] = (x: pointX, y: pointY)
  var stickStarts = newSeq[GridPoint](stickCount)
  var stickEnds = newSeq[GridPoint](stickCount)
  for stickIndex in 0 .. stickCount - 1:
    let startX = nextInt(inputData, scanPos)
    let startY = nextInt(inputData, scanPos)
    let endX = nextInt(inputData, scanPos)
    let endY = nextInt(inputData, scanPos)
    stickStarts[stickIndex] = (x: startX, y: startY)
    stickEnds[stickIndex] = (x: endX, y: endY)
  var distances = newSeq[seq[float]](leafCount + 1)
  var crossings = newSeq[seq[int]](leafCount + 1)
  for firstPoint in 0 .. leafCount:
    distances[firstPoint] = newSeq[float](leafCount + 1)
    crossings[firstPoint] = newSeq[int](leafCount + 1)
    for secondPoint in 0 .. leafCount:
      distances[firstPoint][secondPoint] = pointDistance(gardenPoints[firstPoint],
                                                        gardenPoints[secondPoint])
      var crossedSticks = 0
      for stickIndex in 0 .. stickCount - 1:
        if segmentsCross(gardenPoints[firstPoint], gardenPoints[secondPoint],
                         stickStarts[stickIndex], stickEnds[stickIndex]):
          crossedSticks += 1
      crossings[firstPoint][secondPoint] = crossedSticks
  let fullMask = (1 shl leafCount) - 1
  let jumpWidth = jumpLimit + 1
  let stateStride = leafCount * jumpWidth
  let stateCount = (fullMask + 1) * stateStride
  var suffixBest = newSeq[float](stateCount)
  for stateIndex in 0 .. stateCount - 1:
    suffixBest[stateIndex] = unreachableDistance
  for lastLeaf in 0 .. leafCount - 1:
    for jumpCount in 0 .. jumpLimit:
      let completeIndex = fullMask * stateStride + lastLeaf * jumpWidth + jumpCount
      suffixBest[completeIndex] = 0.0
  for mask in countdown(fullMask - 1, 0):
    for lastLeaf in 0 .. leafCount - 1:
      for jumpCount in 0 .. jumpLimit:
        var bestDistance = unreachableDistance
        for nextLeaf in 0 .. leafCount - 1:
          if (mask and (1 shl nextLeaf)) != 0:
            continue
          let nextJumps = jumpCount + crossings[lastLeaf + 1][nextLeaf + 1]
          if nextJumps > jumpLimit:
            continue
          let nextMask = mask or (1 shl nextLeaf)
          let nextIndex = nextMask * stateStride + nextLeaf * jumpWidth + nextJumps
          let candidate = distances[lastLeaf + 1][nextLeaf + 1] + suffixBest[nextIndex]
          if candidate < bestDistance:
            bestDistance = candidate
        let currentIndex = mask * stateStride + lastLeaf * jumpWidth + jumpCount
        suffixBest[currentIndex] = bestDistance
```

Superset masks have larger numbers, so descending order fills them first.
A state with too many jumps stays unreachable.
The table holds at most 1024 masks times ten leaves times eleven jump counts.

**Reconstruction and output.** The optimum is read from the start state, then rebuilt greedily.

```nim
  var optimalDistance = unreachableDistance
  for firstLeaf in 0 .. leafCount - 1:
    let firstJumps = crossings[0][firstLeaf + 1]
    if firstJumps > jumpLimit:
      continue
    let firstIndex = (1 shl firstLeaf) * stateStride + firstLeaf * jumpWidth + firstJumps
    let candidate = distances[0][firstLeaf + 1] + suffixBest[firstIndex]
    if candidate < optimalDistance:
      optimalDistance = candidate
  appendOutput("Scenario #" & $(caseIndex + 1) & ": ")
  if optimalDistance >= unreachableDistance / 2:
    appendOutput("-1")
    outputBuffer.add '\n'
    continue
  let thousandths = int64(optimalDistance * 1000.0 + 0.5)
  appendOutput($int(thousandths div 1000))
  appendOutput(".")
  appendFraction(thousandths mod 1000)
  outputBuffer.add '\n'
  var pathLeaves = newSeq[int]()
  pathLeaves.add 0
  var currentMask = 0
  var currentPoint = 0
  var usedJumps = 0
  var walkedDistance = 0.0
  while currentMask != fullMask:
    var chosenLeaf = -1
    var chosenJumps = 0
    var chosenDistance = 0.0
    for nextLeaf in 0 .. leafCount - 1:
      if (currentMask and (1 shl nextLeaf)) != 0:
        continue
      let nextJumps = usedJumps + crossings[currentPoint][nextLeaf + 1]
      if nextJumps > jumpLimit:
        continue
      let nextMask = currentMask or (1 shl nextLeaf)
      let nextIndex = nextMask * stateStride + nextLeaf * jumpWidth + nextJumps
      let candidate = walkedDistance + distances[currentPoint][nextLeaf + 1] +
                      suffixBest[nextIndex]
      if abs(candidate - optimalDistance) < tieTolerance:
        chosenLeaf = nextLeaf
        chosenJumps = nextJumps
        chosenDistance = distances[currentPoint][nextLeaf + 1]
        break
    if chosenLeaf == -1:
      break
    walkedDistance += chosenDistance
    currentMask = currentMask or (1 shl chosenLeaf)
    currentPoint = chosenLeaf + 1
    usedJumps = chosenJumps
    pathLeaves.add chosenLeaf + 1
  for pathIndex in 0 .. pathLeaves.len - 1:
    if pathIndex > 0:
      outputBuffer.add ' '
    appendOutput($pathLeaves[pathIndex])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The smallest feasible leaf at each step gives the smallest optimal path.
A sentinel distance marks cases where no walk fits the jump budget.
One buffered write emits all scenario lines and paths.

## Complexity

Leg tables and mask states are the two main costs.

| phase | time | space |
|---|---|---|
| input read | one pass over leaves and sticks | one input string |
| leg tables | pairs of points times sticks | two small matrices |
| backward table | masks times leaves times jumps times leaves | one distance table |
| reconstruction | one pass over leaf indices | one path array |
| output | one buffered write per block | one output string |

Leg tables turn each state transition into two array reads.

| measure | Big O |
|---|---|
| time | O(n^2 m + 2^n n^2 k) per case |
| space | O(2^n n k) per case |

Testing all leaf permutations grows as n factorial and cannot handle ten leaves.
Precompute legs, fill masks backwards, then rebuild the smallest optimal route.
