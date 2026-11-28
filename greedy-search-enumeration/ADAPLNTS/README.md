# ADAPLNTS — Ada and Plants 2 (SPOJ)

<https://www.spoj.com/problems/ADAPLNTS/>

## Problem

Two furrows contain plants, and a plant in one furrow kills a plant in the other when their kind numbers share a factor above one. Remove as few plants as possible so every remaining plant survives. Report how many plants remain.

The input has one case. The first line gives the two furrow sizes, `N` and `M`. The next two lines hold the kind numbers of the first and second furrow. Print one integer, the largest surviving plant count.

| Item | Bound |
|---|---|
| First furrow N | 1 to 800 |
| Second furrow M | 1 to 800 |
| Kind number | 1 to 1000000 |
| Judge limit | 3000 ms, 1536 MB |

Plants inside one furrow never conflict with each other.

The first sample case is:

```
3 4
3 4 5
6 30 1 7
```

The expected output is:

```
5
```

## Idea

Pair each conflict like matching dancers, then let everyone without a pair stay on the floor. Build a bipartite graph whose edges are the killing pairs. By Konig's theorem, the smallest set of plants to remove has the same size as a largest matching. Use Hopcroft-Karp to find that matching quickly.

## Why It Works

1. A conflict joins one plant from the first furrow to one plant from the second furrow.
2. Keeping a surviving set means no edge may join two kept plants.
3. Removing an endpoint of every edge leaves an independent set.
4. Konig's theorem says the minimum endpoint set equals the maximum number of disjoint edges.
5. Therefore the survivors equal both furrow sizes minus the matching size.
6. Hopcroft-Karp finds that matching with layered searches and depth-first augmentations.

| Term | Meaning |
|---|---|
| `headLeft` | first conflict edge for each plant in the first furrow |
| `pairLeft` | matched second-furrow plant, or minus one |
| `pairRight` | matched first-furrow plant, or minus one |
| `distance` | BFS layer of each unmatched first-furrow plant |
| `matching` | number of disjoint conflict pairs found |

The graph is built once, with one edge per conflicting pair.

A short trace with the sample plants:

```
conflicts: 3-6, 3-30, 4-6, 4-30, 5-30
largest matching: two pairs, for example 3-6 and 4-30
plant count: 3 + 4 = 7
survivors: 7 - 2 = 5, keeping 3, 4, 5, 1, 7
```

The trace matches the sample output.

## Code

**Input and scanning.** The reader loads both kind lists, and the sentinel permits extra cases.

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

proc hasNextNumber(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len and (data[cursor] < '0' or data[cursor] > '9'):
    cursor += 1
  return cursor < data.len

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc greatestCommonDivisor(firstValue: int, secondValue: int): int =
  var larger = firstValue
  var smaller = secondValue
  while smaller != 0:
    let remainder = larger mod smaller
    larger = smaller
    smaller = remainder
  return larger
```

The scanner reads all header values and kind numbers.
Euclid's loop decides whether two plants conflict.
One output buffer serves every case in the file.

**Layered search.** The breadth pass assigns layers to unmatched first-furrow plants.

```nim
proc breadthFirst(leftCount: int, headLeft: seq[int], edgeTo: seq[int], edgeNext: seq[int],
                   pairLeft: seq[int], pairRight: seq[int], distance: var seq[int], queue: var seq[int]): bool =
  var queueHead = 0
  var queueTail = 0
  for leftNode in 0 .. leftCount - 1:
    if pairLeft[leftNode] == -1:
      distance[leftNode] = 0
      queue[queueTail] = leftNode
      queueTail += 1
    else:
      distance[leftNode] = -1
  var foundFreeRight = false
  while queueHead < queueTail:
    let leftNode = queue[queueHead]
    queueHead += 1
    var edgeLink = headLeft[leftNode]
    while edgeLink != -1:
      let rightNode = edgeTo[edgeLink]
      let matchedLeft = pairRight[rightNode]
      if matchedLeft == -1:
        foundFreeRight = true
      elif distance[matchedLeft] == -1:
        distance[matchedLeft] = distance[leftNode] + 1
        queue[queueTail] = matchedLeft
        queueTail += 1
      edgeLink = edgeNext[edgeLink]
  return foundFreeRight
```

Every unmatched plant starts a layer at distance zero.
Matched edges lead to the next layer across the matching.
The queue visits each layered plant once.

**Augmenting walk.** The depth pass follows edges that advance one layer.

```nim
proc depthFirstSearch(leftNode: int, headLeft: seq[int], edgeTo: seq[int], edgeNext: seq[int],
                      pairLeft: var seq[int], pairRight: var seq[int], distance: var seq[int]): bool =
  var edgeLink = headLeft[leftNode]
  while edgeLink != -1:
    let rightNode = edgeTo[edgeLink]
    let matchedLeft = pairRight[rightNode]
    if matchedLeft == -1:
      pairLeft[leftNode] = rightNode
      pairRight[rightNode] = leftNode
      return true
    if distance[matchedLeft] == distance[leftNode] + 1:
      if depthFirstSearch(matchedLeft, headLeft, edgeTo, edgeNext, pairLeft, pairRight, distance):
        pairLeft[leftNode] = rightNode
        pairRight[rightNode] = leftNode
        return true
    edgeLink = edgeNext[edgeLink]
  distance[leftNode] = -1
  return false
```

A free right end completes one augmenting path.
A failed branch is dropped from later searches in the phase.
Pair arrays are rewritten only when a path succeeds.

**Graph build and answer.** Conflict pairs are stored once, then matching size gives the survivors.

```nim
while hasNextNumber(inputData, scanPos):
  let leftCount = nextInt(inputData, scanPos)
  let rightCount = nextInt(inputData, scanPos)
  var leftKinds = newSeq[int](leftCount)
  var rightKinds = newSeq[int](rightCount)
  for leftIndex in 0 .. leftCount - 1:
    leftKinds[leftIndex] = nextInt(inputData, scanPos)
  for rightIndex in 0 .. rightCount - 1:
    rightKinds[rightIndex] = nextInt(inputData, scanPos)
  var headLeft = newSeq[int](leftCount)
  var edgeTo = newSeq[int](leftCount * rightCount)
  var edgeNext = newSeq[int](leftCount * rightCount)
  var edgeCount = 0
  for leftIndex in 0 .. leftCount - 1:
    headLeft[leftIndex] = -1
    for rightIndex in 0 .. rightCount - 1:
      if greatestCommonDivisor(leftKinds[leftIndex], rightKinds[rightIndex]) > 1:
        edgeTo[edgeCount] = rightIndex
        edgeNext[edgeCount] = headLeft[leftIndex]
        headLeft[leftIndex] = edgeCount
        edgeCount += 1
  var pairLeft = newSeq[int](leftCount)
  var pairRight = newSeq[int](rightCount)
  var distance = newSeq[int](leftCount)
  var queue = newSeq[int](leftCount)
  for leftIndex in 0 .. leftCount - 1:
    pairLeft[leftIndex] = -1
  for rightIndex in 0 .. rightCount - 1:
    pairRight[rightIndex] = -1
  var matching = 0
  while breadthFirst(leftCount, headLeft, edgeTo, edgeNext, pairLeft, pairRight, distance, queue):
    for leftIndex in 0 .. leftCount - 1:
      if pairLeft[leftIndex] == -1:
        if depthFirstSearch(leftIndex, headLeft, edgeTo, edgeNext, pairLeft, pairRight, distance):
          matching += 1
  appendOutput($(leftCount + rightCount - matching))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Adjacency arrays hold at most one slot per plant pair.
Minus one marks an unmatched plant on either side.
The answer is the plant count minus the matching size.

## Complexity

The graph has at most one edge per pair of plants, and layered search visits each edge once per phase.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over both kind lists | one input string |
| Graph build | O(N × M) gcd checks | one slot per possible edge |
| Hopcroft-Karp | O(E × sqrt(V)) | pair and layer arrays |
| Output | one line per case | block buffer |

`V` is `N + M` and `E` is the number of conflict pairs.

| Measure | Big O |
|---|---|
| Time | O(E × sqrt(V) + N × M) |
| Space | O(N × M) |

A plain augmenting search can revisit every edge for each plant, while Hopcroft-Karp batches those searches into phases.
