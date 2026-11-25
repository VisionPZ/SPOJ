# TREEOI14 — Trees (SPOJ)

<https://www.spoj.com/problems/TREEOI14/>

## Problem

For every tree in a row, find the smallest disorder coefficient after swapping it with any other tree, or after leaving the row unchanged. Disorder is the sum of absolute height differences between neighbours.

Input gives n, then n heights from 1 to 100000000. Output gives n lines, one minimum disorder per tree position.

| item | bound |
|---|---|
| trees n | 2 to 50000 |
| height h_i | 1 to 100000000 |
| judge limit | 1000 ms, 1536 MB |

The fixed two-neighbour cost shape allows a height sweep instead of testing every pair.

Sample input and output:

```
5
7 4 5 2 5
```

```
7
7
8
7
7
```

The two blocks come from the statement and drive the checks.

## Idea

Think of replacing one tile in a mosaic: only its two neighbours and the other tile's two neighbours change. Write each candidate's cost as a V-shaped function of height, then sweep heights with nine range-minimum trees to find the best partner.

The program sorts inner trees by height and moves each tree through three cost states as the sweep passes its neighbours. Each event and each query costs O(log n). Testing all pairs directly costs O(n^2).

A few range-minimum trees replace the quadratic pair search.

## Why It Works

1. For an inner tree, replacing height x costs a constant plus twice the distance from x to its neighbour interval.
2. The constants cancel in a swap, leaving twice the sum of two distance changes.
3. Each candidate's contribution changes slope only at its neighbour interval bounds.
4. Sorting candidates by height lets one sweep move each tree through three states.
5. Range queries on height splits the best partner into below, inside and above cases.
6. Three states times three height offsets give nine trees with constant query work.
7. End trees and neighbour positions use a direct O(1) swap check.

| term | meaning |
|---|---|
| `distanceValue` | distance from a height to its neighbour interval |
| `stateTrees` | nine range-minimum trees for states and offsets |
| `moveEvents` | neighbour-boundary crossings in sweep order |
| `swapDelta` | direct cost change for one pair |

The sweep finds the best inner partner while direct checks cover the boundary cases.

A traced example uses the sample row:

```
heights: 7 4 5 2 5, base disorder = 3 + 1 + 3 + 3 = 10
swap tree 2 with tree 5: row becomes 7 5 5 2 4
new disorder = 2 + 0 + 3 + 2 = 7
best answer for tree 2 = 7, matching the sample
```

The sample reports the same minimum for each position.

## Code

**Input reader, output buffer and numeric helpers.**

```nim
import algorithm

const flushBlockBytes = 1 shl 17
const treeInfinity: int64 = 1000000000000000000

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

magnitude avoids signed overflow in differences.
distanceToRange measures distance to a neighbour interval.

**Range-minimum tree and sweep helpers.**

```nim
proc magnitude(value: int64): int64 =
  if value < 0:
    return -value
  return value

proc distanceToRange(value: int64, low: int64, high: int64): int64 =
  if value < low:
    return low - value
  if value > high:
    return value - high
  return 0

type MinTree = object
  size: int
  nodes: seq[int64]

proc newMinTree(count: int): MinTree =
  var size = 1
  while size < count:
    size = size * 2
  var nodes = newSeq[int64](2 * size)
  for nodeIndex in 0 .. nodes.len - 1:
    nodes[nodeIndex] = treeInfinity
  return MinTree(size: size, nodes: nodes)

proc setLeaf(tree: var MinTree, index: int, value: int64) =
  var position = index + tree.size
  tree.nodes[position] = value
  position = position div 2
  while position >= 1:
    tree.nodes[position] = min(tree.nodes[position * 2], tree.nodes[position * 2 + 1])
    position = position div 2

proc queryRange(tree: MinTree, left: int, right: int): int64 =
  if left > right:
    return treeInfinity
  var lowCursor = left + tree.size
  var highCursor = right + tree.size
  var best = treeInfinity
  while lowCursor <= highCursor:
    if (lowCursor mod 2) == 1:
      best = min(best, tree.nodes[lowCursor])
      lowCursor += 1
    if (highCursor mod 2) == 0:
      best = min(best, tree.nodes[highCursor])
      highCursor -= 1
    lowCursor = lowCursor div 2
    highCursor = highCursor div 2
  return best

type MoveEvent = object
  coordinate: int64
  treeIndex: int
  targetState: int

proc byCoordinate(left: MoveEvent, right: MoveEvent): int =
  if left.coordinate < right.coordinate:
    return -1
  if left.coordinate > right.coordinate:
    return 1
  return 0

proc ascendingHeight(heights: seq[int64], left: int, right: int): int =
  if heights[left] < heights[right]:
    return -1
  if heights[left] > heights[right]:
    return 1
  return 0

proc lowerBound(values: seq[int64], target: int64): int =
  var low = 0
  var high = values.len
  while low < high:
    let middle = (low + high) div 2
    if values[middle] < target:
      low = middle + 1
    else:
      high = middle
  return low

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

```

Each tree stores minima over a power-of-two node array.
Events carry a coordinate, a tree rank and a target state.
lowerBound and upperBound split candidates by height.

**Base disorder and local swap cost.**

```nim
let treeCount = nextInt(inputData, scanPos)
var heights = newSeq[int64](treeCount + 1)
for position in 1 .. treeCount:
  heights[position] = int64(nextInt(inputData, scanPos))
var baseDisorder: int64 = 0
for position in 1 .. treeCount - 1:
  baseDisorder = baseDisorder + magnitude(heights[position] - heights[position + 1])
var answers = newSeq[int64](treeCount + 1)
for position in 1 .. treeCount:
  answers[position] = baseDisorder

var lowNeighbor = newSeq[int64](treeCount + 1)
var highNeighbor = newSeq[int64](treeCount + 1)
var distanceValue = newSeq[int64](treeCount + 1)
for position in 2 .. treeCount - 1:
  lowNeighbor[position] = min(heights[position - 1], heights[position + 1])
  highNeighbor[position] = max(heights[position - 1], heights[position + 1])
  distanceValue[position] = distanceToRange(heights[position], lowNeighbor[position], highNeighbor[position])

proc localCost(position: int, replacement: int64): int64 =
  if position == 1:
    return magnitude(replacement - heights[2])
  if position == treeCount:
    return magnitude(heights[treeCount - 1] - replacement)
  return magnitude(heights[position - 1] - heights[position + 1]) +
         2 * distanceToRange(replacement, lowNeighbor[position], highNeighbor[position])

proc swapDelta(leftIndex: int, rightIndex: int): int64 =
  if rightIndex == leftIndex + 1:
    var change: int64 = 0
    if leftIndex > 1:
      change = change + magnitude(heights[leftIndex - 1] - heights[rightIndex]) -
                       magnitude(heights[leftIndex - 1] - heights[leftIndex])
    if rightIndex < treeCount:
      change = change + magnitude(heights[leftIndex] - heights[rightIndex + 1]) -
                        magnitude(heights[rightIndex] - heights[rightIndex + 1])
    return change
  return localCost(leftIndex, heights[rightIndex]) - localCost(leftIndex, heights[leftIndex]) +
         localCost(rightIndex, heights[leftIndex]) - localCost(rightIndex, heights[rightIndex])

for position in [1, treeCount]:
  for other in 1 .. treeCount:
    if other != position:
      let change = if position < other: swapDelta(position, other) else: swapDelta(other, position)
      answers[position] = min(answers[position], baseDisorder + change)

var interiorPositions = newSeq[int](treeCount - 2)
```

Inner trees use a neighbour interval and twice its distance.
Adjacent swaps recompute only the three touched edges.

**Height sweep and final answers.**

```nim
for position in 2 .. treeCount - 1:
  interiorPositions[position - 2] = position
interiorPositions.sort(proc(left: int, right: int): int = ascendingHeight(heights, left, right))
var heightAtRank = newSeq[int64](treeCount - 2)
var rankOfPosition = newSeq[int](treeCount + 1)
for rank in 0 .. interiorPositions.len - 1:
  let position = interiorPositions[rank]
  heightAtRank[rank] = heights[position]
  rankOfPosition[position] = rank

var stateTrees: array[0 .. 2, array[0 .. 2, MinTree]]
for state in 0 .. 2:
  for offset in 0 .. 2:
    stateTrees[state][offset] = newMinTree(interiorPositions.len)

for position in 2 .. treeCount - 1:
  let rank = rankOfPosition[position]
  let firstValue = lowNeighbor[position] - distanceValue[position]
  stateTrees[0][0].setLeaf(rank, firstValue - heights[position])
  stateTrees[0][1].setLeaf(rank, firstValue)
  stateTrees[0][2].setLeaf(rank, firstValue + heights[position])

var moveEvents = newSeq[MoveEvent](2 * interiorPositions.len)
var eventCount = 0
for position in 2 .. treeCount - 1:
  moveEvents[eventCount] = MoveEvent(coordinate: lowNeighbor[position],
                                     treeIndex: rankOfPosition[position], targetState: 1)
  eventCount += 1
  moveEvents[eventCount] = MoveEvent(coordinate: highNeighbor[position] + 1,
                                     treeIndex: rankOfPosition[position], targetState: 2)
  eventCount += 1
moveEvents.setLen eventCount
moveEvents.sort(byCoordinate)

var eventCursor = 0
for queryIndex in 0 .. interiorPositions.len - 1:
  let position = interiorPositions[queryIndex]
  let currentHeight = heights[position]
  while eventCursor < moveEvents.len and moveEvents[eventCursor].coordinate <= currentHeight:
    let moveEvent = moveEvents[eventCursor]
    let movedPosition = interiorPositions[moveEvent.treeIndex]
    let target = moveEvent.targetState
    var baseValue: int64 = 0
    if target == 1:
      baseValue = -distanceValue[movedPosition]
    else:
      baseValue = -highNeighbor[movedPosition] - distanceValue[movedPosition]
    var offsetValues = [-heights[movedPosition], 0, heights[movedPosition]]
    for offset in 0 .. 2:
      stateTrees[target][offset].setLeaf(moveEvent.treeIndex, baseValue + offsetValues[offset])
      stateTrees[target - 1][offset].setLeaf(moveEvent.treeIndex, treeInfinity)
    eventCursor += 1

  var excludedCount = 0
  var excludedStates = newSeq[int](3)
  var excludedRanks = newSeq[int](3)
  var excludedPositions = newSeq[int](3)
  var candidatePosition = position - 1
  while candidatePosition <= position + 1:
    if candidatePosition >= 2 and candidatePosition <= treeCount - 1:
      var currentState = 0
      if currentHeight >= lowNeighbor[candidatePosition] and currentHeight <= highNeighbor[candidatePosition]:
        currentState = 1
      elif currentHeight > highNeighbor[candidatePosition]:
        currentState = 2
      let rank = rankOfPosition[candidatePosition]
      excludedStates[excludedCount] = currentState
      excludedRanks[excludedCount] = rank
      excludedPositions[excludedCount] = candidatePosition
      excludedCount += 1
      for offset in 0 .. 2:
        stateTrees[currentState][offset].setLeaf(rank, treeInfinity)
    candidatePosition += 1

  let lowEnd = lowerBound(heightAtRank, lowNeighbor[position]) - 1
  let middleStart = lowEnd + 1
  let middleEnd = upperBound(heightAtRank, highNeighbor[position]) - 1
  let highStart = middleEnd + 1
  var bestCross = treeInfinity
  for state in 0 .. 2:
    var common: int64 = 0
    if state == 0:
      common = -currentHeight
    elif state == 2:
      common = currentHeight
    let lowValue = stateTrees[state][0].queryRange(0, lowEnd) + common +
                   lowNeighbor[position] - distanceValue[position]
    let middleValue = stateTrees[state][1].queryRange(middleStart, middleEnd) + common -
                      distanceValue[position]
    let highValue = stateTrees[state][2].queryRange(highStart, heightAtRank.len - 1) + common -
                    highNeighbor[position] - distanceValue[position]
    bestCross = min(bestCross, min(lowValue, min(middleValue, highValue)))
  if bestCross < treeInfinity div 2:
    answers[position] = min(answers[position], baseDisorder + 2 * bestCross)

  if position > 1:
    answers[position] = min(answers[position], baseDisorder + swapDelta(position - 1, position))
  if position < treeCount:
    answers[position] = min(answers[position], baseDisorder + swapDelta(position, position + 1))
  answers[position] = min(answers[position], baseDisorder + swapDelta(1, position))
  answers[position] = min(answers[position], baseDisorder + swapDelta(position, treeCount))

  for excludedIndex in 0 .. excludedCount - 1:
    let excludedPosition = excludedPositions[excludedIndex]
    let excludedState = excludedStates[excludedIndex]
    let rank = excludedRanks[excludedIndex]
    var baseValue: int64 = 0
    if excludedState == 0:
      baseValue = lowNeighbor[excludedPosition] - distanceValue[excludedPosition]
    elif excludedState == 1:
      baseValue = -distanceValue[excludedPosition]
    else:
      baseValue = -highNeighbor[excludedPosition] - distanceValue[excludedPosition]
    var offsetValues = [-heights[excludedPosition], 0, heights[excludedPosition]]
    for offset in 0 .. 2:
      stateTrees[excludedState][offset].setLeaf(rank, baseValue + offsetValues[offset])

for position in 1 .. treeCount:
  appendOutput($answers[position])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Nine trees hold candidate values for the three offsets.
Events move a tree into its next state at each boundary.
Excluded neighbours are removed, queried, then restored.

## Complexity

The sweep processes each tree once and each query once.

| phase | time | space |
|---|---|---|
| input read | one pass over n heights | one input string |
| setup | sort inner trees and build events | arrays of n values |
| height sweep | n events and n queries | nine trees of size n |
| direct checks | O(1) per boundary pair | none extra |
| output | one buffered line per tree | block buffer |

The nine range-minimum trees dominate the phase table.

| measure | Big O |
|---|---|
| time | O(n log n) |
| space | O(n) |

Checking every pair would cost O(n^2) time.
