# FUKU11J — Round Trip (SPOJ)

<https://www.spoj.com/problems/FUKU11J/>

## Problem

A round trip goes from town `1` to town `n` and back, paying each town's visa fee only on its first visit. Roads used on the outward leg never descend, and roads used on the return leg never ascend. Report the least total road and fee cost, or `-1` when no trip exists.

Input holds several datasets. Each starts with `n` and `m`, then `n-2` fee and altitude pairs for towns `2` through `n-1`, then `m` directed roads with costs. The line `0 0` ends the input. Output one answer per dataset.

| item | bound |
|---|---|
| towns `n` | 2 to 50 |
| roads `m` | 0 to `n(n-1)` |
| fee `d_i` | 1 to 1000 |
| altitude `e_i` | 1 to 999 |
| towns per altitude | at most 10 |
| road cost `c_j` | 1 to 1000 |
| judge limit | 100 ms, 1536 MB |

Town `1` has altitude `0`, town `n` has altitude `1000`, and neither charges a fee. Math spans `d_i`, `e_i`, and `c_j` index towns and roads, and `2^n` denotes two to the n.

Sample input:

```
3 6
3 1
1 2 1
2 3 1
3 2 1
2 1 1
1 3 4
3 1 4
3 6
5 1
1 2 1
2 3 1
3 2 1
2 1 1
1 3 4
3 1 4
4 5
3 1
3 1
1 2 5
2 3 5
3 4 5
4 2 5
3 1 5
2 1
2 1 1
0 0
```

Sample output:

```
7
8
36
-1
```

## Idea

Reverse the return leg so both legs climb uphill, then walk them together like two hikers who take turns moving forward. The lower hiker always moves first, so only towns at one altitude can still be paid twice. A ten-bit mask records which towns at that altitude already paid their fee, and Dijkstra finds the cheapest combined state.

A shortest path on towns alone loses information, because the second visit to a town is free. Keeping both hiker positions and the small mask preserves the fee state without storing all visited towns.

## Why It Works

1. Reversing the return leg turns both legs into paths with nondecreasing altitude.
2. Moving only the lower hiker keeps both hikers within one altitude group at a time.
3. Once a hiker leaves an altitude, no later move can return to that group.
4. The mask marks towns in the current group whose fee was paid already.
5. A move to a new town adds its fee unless its mask bit is set.
6. When both hikers stand on town `n`, the accumulated cost is the answer.

| term | meaning |
|---|---|
| `goEdges` | forward roads usable when the first hiker moves |
| `returnEdges` | reversed roads usable when the second hiker moves |
| `groupIndexes` | position of a town inside its altitude group |
| `paidMask` | ten-bit fee record for the current group |

A script added the road and fee costs for the sample datasets.

| case | outward leg | outward roads | return leg | return roads | fees | total |
|---|---|---|---|---|---|---|
| 1 | 1-2-3 | 2 | 3-2-1 | 2 | 3 | 7 |
| 2 | 1-3 | 4 | 3-1 | 4 | 0 | 8 |
| 3 | 1-2-3-4 | 15 | 4-2-3-1 | 15 | 6 | 36 |

The fourth case has no return road into town `1`, so it yields `-1`.

## Code

**Input and scanning.** The reader loads all datasets and scans integers by hand.

```nim
const flushBlockBytes = 1 shl 17
const maskCount = 1 shl 10
const altitudeLevels = 1001

type HeapItem = tuple[costValue: int64, firstTown: int, secondTown: int, paidMask: int]

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
```

The mask constant matches the ten-town limit.
The item type holds one queued search state.
The scanner ignores line breaks and spaces.

**Output buffering.** One buffer collects the dataset answers.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Each answer is a single line.
The buffer flushes in large blocks.
A final flush closes the stream.

**Priority queue.** A binary heap orders states by accumulated cost.

```nim
var heapCosts = newSeq[int64]()
var heapFirsts = newSeq[int]()
var heapSeconds = newSeq[int]()
var heapMasks = newSeq[int]()

proc heapPush(item: HeapItem) =
  heapCosts.add item.costValue
  heapFirsts.add item.firstTown
  heapSeconds.add item.secondTown
  heapMasks.add item.paidMask
  var childIndex = heapCosts.len - 1
  while childIndex > 0:
    let parentIndex = (childIndex - 1) div 2
    if heapCosts[parentIndex] <= heapCosts[childIndex]:
      break
    swap heapCosts[parentIndex], heapCosts[childIndex]
    swap heapFirsts[parentIndex], heapFirsts[childIndex]
    swap heapSeconds[parentIndex], heapSeconds[childIndex]
    swap heapMasks[parentIndex], heapMasks[childIndex]
    childIndex = parentIndex

proc heapPop(): HeapItem =
  result = (heapCosts[0], heapFirsts[0], heapSeconds[0], heapMasks[0])
  let lastIndex = heapCosts.len - 1
  heapCosts[0] = heapCosts[lastIndex]
  heapFirsts[0] = heapFirsts[lastIndex]
  heapSeconds[0] = heapSeconds[lastIndex]
  heapMasks[0] = heapMasks[lastIndex]
  heapCosts.setLen lastIndex
  heapFirsts.setLen lastIndex
  heapSeconds.setLen lastIndex
  heapMasks.setLen lastIndex
  var parentIndex = 0
  while true:
    let leftIndex = 2 * parentIndex + 1
    if leftIndex >= heapCosts.len:
      break
    let rightIndex = leftIndex + 1
    var smallerIndex = leftIndex
    if rightIndex < heapCosts.len and heapCosts[rightIndex] < heapCosts[leftIndex]:
      smallerIndex = rightIndex
    if heapCosts[parentIndex] <= heapCosts[smallerIndex]:
      break
    swap heapCosts[parentIndex], heapCosts[smallerIndex]
    swap heapFirsts[parentIndex], heapFirsts[smallerIndex]
    swap heapSeconds[parentIndex], heapSeconds[smallerIndex]
    swap heapMasks[parentIndex], heapMasks[smallerIndex]
    parentIndex = smallerIndex
```

Four parallel arrays store one heap field each.
Sift up after a push and sift down after a pop.
The smallest cost always comes out first.

**Two-hiker search.** The solver builds both road sets and runs Dijkstra.

```nim
proc solveDataset(townCount, roadCount: int, visaFees: seq[int], altitudes: seq[int], roads: seq[tuple[first: int, second: int, cost: int]]): int64 =
  var goEdges = newSeq[seq[tuple[target: int, cost: int]]](townCount)
  var returnEdges = newSeq[seq[tuple[target: int, cost: int]]](townCount)
  for road in roads:
    if altitudes[road.first] <= altitudes[road.second]:
      goEdges[road.first].add (road.second, road.cost)
    if altitudes[road.first] >= altitudes[road.second]:
      returnEdges[road.second].add (road.first, road.cost)
  var groupIndexes = newSeq[int](townCount)
  for altitudeValue in 0 .. altitudeLevels - 1:
    var memberCount = 0
    for townIndex in 0 .. townCount - 1:
      if altitudes[townIndex] == altitudeValue:
        groupIndexes[townIndex] = memberCount
        memberCount += 1
  let stateCount = townCount * townCount * maskCount
  var distances = newSeq[int64]()
  distances.setLen 0
  distances.setLen stateCount
  heapCosts.setLen 0
  heapFirsts.setLen 0
  heapSeconds.setLen 0
  heapMasks.setLen 0
  distances[0] = 1
  heapPush((0.int64, 0, 0, 0))
  let destinationTown = townCount - 1
  while heapCosts.len > 0:
    let current = heapPop()
    let currentCost = current.costValue
    let firstTown = current.firstTown
    let secondTown = current.secondTown
    let currentMask = current.paidMask
    let currentIndex = (firstTown * townCount + secondTown) * maskCount + currentMask
    if distances[currentIndex] != currentCost + 1:
      continue
    if firstTown == destinationTown and secondTown == destinationTown:
      return currentCost
```

Uphill roads feed the first hiker, and reversed roads feed the second.
Group indexes turn a town into one of at most ten mask bits.
A zero distance means the state has not been reached.

```nim
    if altitudes[firstTown] < altitudes[secondTown]:
      for edge in goEdges[firstTown]:
        let nextTown = edge.target
        var addedCost = int64(edge.cost) + int64(visaFees[nextTown])
        var nextMask = 0
        if altitudes[nextTown] > altitudes[firstTown]:
          if altitudes[nextTown] >= altitudes[secondTown]:
            nextMask = 1 shl groupIndexes[secondTown]
            if altitudes[nextTown] == altitudes[secondTown]:
              nextMask = nextMask or (1 shl groupIndexes[nextTown])
            if nextTown == secondTown:
              addedCost -= int64(visaFees[nextTown])
          else:
            nextMask = 1 shl groupIndexes[nextTown]
        else:
          if (currentMask and (1 shl groupIndexes[nextTown])) != 0:
            addedCost -= int64(visaFees[nextTown])
          nextMask = currentMask or (1 shl groupIndexes[nextTown])
        let nextCost = currentCost + addedCost
        let nextIndex = (nextTown * townCount + secondTown) * maskCount + nextMask
        if distances[nextIndex] == 0 or nextCost + 1 < distances[nextIndex]:
          distances[nextIndex] = nextCost + 1
          heapPush((nextCost, nextTown, secondTown, nextMask))
```

The lower hiker moves along a forward road.
Leaving the altitude group resets the fee mask.
A return to the same town skips its fee.

```nim
    else:
      for edge in returnEdges[secondTown]:
        let nextTown = edge.target
        var addedCost = int64(edge.cost) + int64(visaFees[nextTown])
        var nextMask = if altitudes[firstTown] == altitudes[secondTown]: currentMask else: 0
        if altitudes[nextTown] > altitudes[secondTown]:
          if altitudes[nextTown] >= altitudes[firstTown]:
            nextMask = nextMask or (1 shl groupIndexes[firstTown])
            if altitudes[nextTown] == altitudes[firstTown]:
              nextMask = nextMask or (1 shl groupIndexes[nextTown])
            if nextTown == firstTown:
              addedCost -= int64(visaFees[nextTown])
          else:
            nextMask = nextMask or (1 shl groupIndexes[nextTown])
        else:
          if (currentMask and (1 shl groupIndexes[nextTown])) != 0:
            addedCost -= int64(visaFees[nextTown])
          nextMask = currentMask or (1 shl groupIndexes[nextTown])
        let nextCost = currentCost + addedCost
        let nextIndex = (firstTown * townCount + nextTown) * maskCount + nextMask
        if distances[nextIndex] == 0 or nextCost + 1 < distances[nextIndex]:
          distances[nextIndex] = nextCost + 1
          heapPush((nextCost, firstTown, nextTown, nextMask))
  return -1
```

The second hiker moves along a reversed road.
The same mask rules apply in this branch.
An empty queue with no goal yields `-1`.

**Dataset driver.** The loop parses one dataset and prints its answer.

```nim
while true:
  let townCount = nextInt(inputData, scanPos)
  let roadCount = nextInt(inputData, scanPos)
  if townCount == 0 and roadCount == 0:
    break
  var visaFees = newSeq[int](townCount)
  var altitudes = newSeq[int](townCount)
  altitudes[0] = 0
  altitudes[townCount - 1] = 1000
  for townIndex in 1 .. townCount - 2:
    visaFees[townIndex] = nextInt(inputData, scanPos)
    altitudes[townIndex] = nextInt(inputData, scanPos)
  var roads = newSeq[tuple[first: int, second: int, cost: int]]()
  for roadIndex in 0 .. roadCount - 1:
    let startingTown = nextInt(inputData, scanPos) - 1
    let endingTown = nextInt(inputData, scanPos) - 1
    let travelCost = nextInt(inputData, scanPos)
    roads.add (startingTown, endingTown, travelCost)
  let bestCost = solveDataset(townCount, roadCount, visaFees, altitudes, roads)
  appendOutput($bestCost)
  appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

The sentinel ends the loop.
Town numbers shift to zero-based indexes.
Each dataset writes one line.

## Complexity

Each state stores two town positions and one ten-bit mask.

| phase | time | space |
|---|---|---|
| edge build | one pass over `m` roads | two adjacency lists |
| search | one pop per reached state | distance table and heap |
| output | one line per dataset | block buffer |

| measure | Big O |
|---|---|
| time | O(n² × 1024 × log states) worst case |
| space | O(n² × 1024) |

Searching over every subset of visited towns would need `2^n` states and would not fit even for fifty towns.

The altitude limit reduces that set to ten bits per altitude group.
