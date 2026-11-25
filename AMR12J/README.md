<https://www.spoj.com/problems/AMR12J/>

## Problem

Given axis-aligned rooms where no two borders touch, find the smallest room containing each one; an uncovered room reports -1. Input gives the room count and four integer edges per room. Output one parent room number per line in input order.
| item | bound |
|---|---|
| rooms | 1 to 100000 |
| each coordinate | 0 to 1000000000 |
| borders shared by two rooms | none |
| judge limit | 4000 ms, 1536 MB |

No two borders touch, so two rooms are nested or fully apart.

Sample input:

```
4
0 0 10 10
2 3 7 8
3 4 5 6
12 10 13 15
```

Sample output:

```
-1
0
1
-1
```

## Idea

Sweep rooms left to right and keep the nested rooms open, like tracking which nested boxes a new box drops into. A segment tree over compressed y values holds a stack per node. The deepest open room covering a horizontal probe directly above a room's bottom is its parent.

Each room enters once, leaves once, and answers one point query. Each operation costs logarithmic time. Testing every pair instead costs quadratic time.

The sweep turns a two-dimensional containment question into one point query.

## Why It Works

1. Sweep position `sweepX` equals a room's west edge.
2. An open room has west edge below `sweepX` and east edge above it.
3. An open room covering a probe inside the new room's y range must contain the new room.
4. Contained open rooms form a chain, so the deepest one is the parent.
5. Rooms with equal west edges cannot contain each other, so queries run before insertions.
6. Closing a room at its east edge pops it from every stack node it owns.

| term | meaning |
|---|---|
| `sweepX` | current west edge in the sorted sweep |
| `nodeStacks` | stacks of open rooms covering each segment tree node |
| `yIndices` | compressed index of a room's south edge |
| `findContainer` | returns the deepest open room covering the probe |
| `parents` | parent room number for each input room |

For the sample, room 0 opens at x=0. Room 1 queries at x=2 and finds room 0. Room 2 queries at x=3 and finds room 1. At x=12, rooms 0, 1 and 2 close, so room 3 finds nothing.

Coordinates are integers, so comparisons are exact. No rounding applies here.

## Code

**Input and compression.** The reader loads four edges per room and compresses all y values.

```nim
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

let roomCount = nextInt(inputData, scanPos)
var westEdges = newSeq[int](roomCount)
var southEdges = newSeq[int](roomCount)
var eastEdges = newSeq[int](roomCount)
var northEdges = newSeq[int](roomCount)
var allYValues = newSeq[int](2 * roomCount)
for roomIndex in 0 .. roomCount - 1:
  westEdges[roomIndex] = nextInt(inputData, scanPos)
  southEdges[roomIndex] = nextInt(inputData, scanPos)
  eastEdges[roomIndex] = nextInt(inputData, scanPos)
  northEdges[roomIndex] = nextInt(inputData, scanPos)
  allYValues[2 * roomIndex] = southEdges[roomIndex]
  allYValues[2 * roomIndex + 1] = northEdges[roomIndex]

proc compareNumbers(first: int, second: int): int =
  if first < second: return -1
  if first > second: return 1
  return 0

allYValues.sort(compareNumbers)
var distinctYValues = newSeq[int](0)
for value in allYValues:
  if distinctYValues.len == 0 or distinctYValues[distinctYValues.len - 1] != value:
    distinctYValues.add value

proc findValueIndex(values: seq[int], target: int): int =
  var lowIndex = 0
  var highIndex = values.len - 1
  while lowIndex <= highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if values[middleIndex] < target:
      lowIndex = middleIndex + 1
    elif values[middleIndex] > target:
      highIndex = middleIndex - 1
    else:
      return middleIndex
  return -1

var yIndices = newSeq[int](roomCount)
for roomIndex in 0 .. roomCount - 1:
  yIndices[roomIndex] = findValueIndex(distinctYValues, southEdges[roomIndex])
  discard findValueIndex(distinctYValues, northEdges[roomIndex])
```

Four edge arrays keep the input order stable.
Binary search maps each south edge to a compressed index.
Duplicate y values collapse into one elementary interval.

**Segment tree operations.** Stacks record which open rooms cover each node range.

```nim
var leafCount = distinctYValues.len - 1
var treeSize = 1
while treeSize < leafCount:
  treeSize = treeSize * 2
var nodeStacks = newSeq[seq[int]](2 * treeSize)

proc pushRange(roomIndex: int) =
  var leftLeaf = treeSize + yIndices[roomIndex]
  var rightLeaf = treeSize + findValueIndex(distinctYValues, northEdges[roomIndex]) - 1
  while leftLeaf <= rightLeaf:
    if (leftLeaf and 1) == 1:
      nodeStacks[leftLeaf].add roomIndex
      leftLeaf += 1
    if (rightLeaf and 1) == 0:
      nodeStacks[rightLeaf].add roomIndex
      rightLeaf -= 1
    leftLeaf = leftLeaf div 2
    rightLeaf = rightLeaf div 2

proc popRange(roomIndex: int) =
  var leftLeaf = treeSize + yIndices[roomIndex]
  var rightLeaf = treeSize + findValueIndex(distinctYValues, northEdges[roomIndex]) - 1
  while leftLeaf <= rightLeaf:
    if (leftLeaf and 1) == 1:
      nodeStacks[leftLeaf].setLen(nodeStacks[leftLeaf].len - 1)
      leftLeaf += 1
    if (rightLeaf and 1) == 0:
      nodeStacks[rightLeaf].setLen(nodeStacks[rightLeaf].len - 1)
      rightLeaf -= 1
    leftLeaf = leftLeaf div 2
    rightLeaf = rightLeaf div 2

proc findContainer(roomIndex: int): int =
  var nodePos = treeSize + yIndices[roomIndex]
  var bestRoom = -1
  var bestWest = -1
  while nodePos >= 1:
    let stackAtNode = nodeStacks[nodePos]
    if stackAtNode.len > 0:
      let topRoom = stackAtNode[stackAtNode.len - 1]
      if westEdges[topRoom] > bestWest:
        bestWest = westEdges[topRoom]
        bestRoom = topRoom
    nodePos = nodePos div 2
  return bestRoom
```

A push walks the canonical nodes of the y range.
A pop walks the same nodes when the east edge passes.
The query takes the largest west edge among stack tops on the leaf path.

**Sweep and output.** Rooms close, answer and open in one left-to-right pass.

```nim
var roomOrder = newSeq[int](roomCount)
for roomIndex in 0 .. roomCount - 1:
  roomOrder[roomIndex] = roomIndex

proc compareRooms(firstRoom: int, secondRoom: int): int =
  if westEdges[firstRoom] < westEdges[secondRoom]: return -1
  if westEdges[firstRoom] > westEdges[secondRoom]: return 1
  if firstRoom < secondRoom: return -1
  if firstRoom > secondRoom: return 1
  return 0

roomOrder.sort(compareRooms)
var removalOrder = newSeq[int](roomCount)
for roomIndex in 0 .. roomCount - 1:
  removalOrder[roomIndex] = roomIndex

proc compareRemovals(firstRoom: int, secondRoom: int): int =
  if eastEdges[firstRoom] < eastEdges[secondRoom]: return -1
  if eastEdges[firstRoom] > eastEdges[secondRoom]: return 1
  if firstRoom < secondRoom: return -1
  if firstRoom > secondRoom: return 1
  return 0

removalOrder.sort(compareRemovals)
var parents = newSeq[int](roomCount)
for roomIndex in 0 .. roomCount - 1:
  parents[roomIndex] = -1

var removalPos = 0
var groupStart = 0
while groupStart < roomCount:
  let sweepX = westEdges[roomOrder[groupStart]]
  while removalPos < roomCount and eastEdges[removalOrder[removalPos]] <= sweepX:
    popRange(removalOrder[removalPos])
    removalPos += 1
  var groupEnd = groupStart + 1
  while groupEnd < roomCount and westEdges[roomOrder[groupEnd]] == sweepX:
    groupEnd += 1
  for groupIndex in groupStart .. groupEnd - 1:
    let roomIndex = roomOrder[groupIndex]
    parents[roomIndex] = findContainer(roomIndex)
  for groupIndex in groupStart .. groupEnd - 1:
    pushRange(roomOrder[groupIndex])
  groupStart = groupEnd

for roomIndex in 0 .. roomCount - 1:
  appendOutput($parents[roomIndex])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Removals run before queries at the same x.
Insertions run after all queries in the group.
One buffered write emits all parent numbers.

## Complexity

The sweep touches each room a constant number of times.

| phase | time | space |
|---|---|---|
| sort by edges | two sorts of n rooms | two order arrays |
| sweep updates | n pushes and n pops | stack nodes |
| queries | n point queries | one parent array |
| output | n lines | block buffer |

| measure | Big O |
|---|---|
| time | O(n log n) |
| space | O(n log n) worst case |

A pairwise containment test would need O(n^2) comparisons and miss the limit.

The sweep answers every room in logarithmic time.
