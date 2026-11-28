# FN16ASGN — Branch Assignment (SPOJ)

<https://www.spoj.com/problems/FN16ASGN/>

## Problem

Branches in the same group exchange monthly messages through headquarters. A branch in a group of `t` branches sends and receives `t - 1` messages, so its courier cost is the round-trip distance to headquarters times `t - 1`. Split the `b` branches into `s` groups so the total courier distance is smallest.

Input holds several test cases until end of file. Each case starts with four integers `n`, `b`, `s`, and `r`. Intersections run from 1 to `n`, branches occupy intersections 1 through `b`, and headquarters sits at `b + 1`. Each of the next `r` lines gives a one-way road `u v l` with length `l`. The graph is strongly connected, and no ordered pair repeats. Output one line per case with the minimum total distance.

| item | bound |
|---|---|
| intersections n | 2 to 5000 |
| branches b | 1 to n - 1 |
| subprojects s | 1 to b |
| roads r | 1 to 50000 |
| road length | 0 to 10000 |
| judge limit | 60000 ms, 1536 MB |

Every branch must belong to one group, and every group receives at least one branch.

Sample input:

```
5 4 2 10
5 2 1
2 5 1
3 5 5
4 5 0
1 5 1
2 3 1
3 2 5
2 4 5
2 1 1
3 4 2
5 4 2 10
5 2 1
2 5 1
3 5 5
4 5 10
1 5 1
2 3 1
3 2 5
2 4 5
2 1 1
3 4 2
```

Sample output:

```
13
24
```

## Idea

Group cost uses one number per branch, like sorting parcels by weight before packing them into boxes. Dijkstra finds that round-trip number for every branch. Sorting lets us cut the list into contiguous blocks, and a dynamic program picks the cut sizes. Testing every assignment would try `s^b` groupings. Sorting removes the need to choose which branch goes where, leaving only the block sizes to decide. Short takeaway: sort once, then partition with dynamic programming.

## Why It Works

1. The courier path for one message goes from branch to headquarters and back to another branch.
2. For branch `i`, the total message distance is `(t - 1) (a_i + b_i)`, where `a_i` is the distance from headquarters to the branch and `b_i` is the distance back.
3. Define `c_i = a_i + b_i`. Only `c_i` affects the optimal grouping.
4. A branch with larger `c_i` belongs in a group no larger than a branch with smaller `c_i`.
5. After sorting `c` ascending, the last group holds `k` largest values and has size at most `j div g` for `j` branches in `g` groups.
6. The recurrence tries each last-group size and keeps the smallest total.

| term | meaning |
|---|---|
| `distanceFromHQ` | shortest path from headquarters to each branch |
| `distanceToHQ` | shortest path from each branch to headquarters |
| `costs` | sorted round-trip distances `c_i` |
| `prefixCosts` | running sum of sorted `c_i` |
| `best` | table of minimum costs by group count and branch count |

For the first sample case the sorted `c` values are 2, 3, 4, and 4. Two groups of size two cost `1 * (2 + 3) + 1 * (4 + 4) = 13`. In the second case one value becomes 14, and the best split puts that branch alone for a total of 24.

Dijkstra accumulates distances in 64-bit integers. The dynamic program only reads prefix sums, so every group cost stays exact.

## Code

**Input and scanning.** The hand reader loads every road and header value.

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

proc hasNextToken(data: string, pos: int): bool =
  var checkPos = pos
  while checkPos < data.len:
    if data[checkPos] >= '0' and data[checkPos] <= '9':
      return true
    checkPos += 1
  return false
```

The scanner skips whitespace between integers.
The token check ends after the last road of the last case.
Road ends are stored zero-based for direct array indexing.

**Shortest paths.** Two Dijkstra runs use a lazy min-heap.

```nim
type Road = tuple[to: int, length: int]

var pathKeys = newSeq[int64](0)
var pathNodes = newSeq[int](0)

proc pathLess(leftIndex: int, rightIndex: int): bool =
  if pathKeys[leftIndex] < pathKeys[rightIndex]:
    return true
  if pathKeys[leftIndex] > pathKeys[rightIndex]:
    return false
  return pathNodes[leftIndex] < pathNodes[rightIndex]

proc swapPath(leftIndex: int, rightIndex: int) =
  let savedKey = pathKeys[leftIndex]
  let savedNode = pathNodes[leftIndex]
  pathKeys[leftIndex] = pathKeys[rightIndex]
  pathNodes[leftIndex] = pathNodes[rightIndex]
  pathKeys[rightIndex] = savedKey
  pathNodes[rightIndex] = savedNode

proc siftUpPath(startIndex: int) =
  var childIndex = startIndex
  while childIndex > 0:
    let parentIndex = (childIndex - 1) div 2
    if pathLess(childIndex, parentIndex):
      swapPath(childIndex, parentIndex)
      childIndex = parentIndex
    else:
      break

proc siftDownPath(startIndex: int) =
  var parentIndex = startIndex
  while true:
    let leftIndex = parentIndex * 2 + 1
    if leftIndex >= pathKeys.len:
      break
    let rightIndex = leftIndex + 1
    var smallestIndex = leftIndex
    if rightIndex < pathKeys.len and pathLess(rightIndex, leftIndex):
      smallestIndex = rightIndex
    if pathLess(smallestIndex, parentIndex):
      swapPath(parentIndex, smallestIndex)
      parentIndex = smallestIndex
    else:
      break

proc pushPath(key: int64, nodeIndex: int) =
  pathKeys.add key
  pathNodes.add nodeIndex
  siftUpPath(pathKeys.len - 1)

proc popPath(key: var int64, nodeIndex: var int) =
  key = pathKeys[0]
  nodeIndex = pathNodes[0]
  let lastIndex = pathKeys.len - 1
  pathKeys[0] = pathKeys[lastIndex]
  pathNodes[0] = pathNodes[lastIndex]
  pathKeys.setLen(lastIndex)
  pathNodes.setLen(lastIndex)
  if pathKeys.len > 0:
    siftDownPath(0)

proc shortestFromSource(graph: seq[seq[Road]], source: int): seq[int64] =
  let nodeCount = graph.len
  var distances = newSeq[int64](nodeCount)
  for nodeIndex in 0 .. nodeCount - 1:
    distances[nodeIndex] = high(int64) div 4
  pathKeys.setLen(0)
  pathNodes.setLen(0)
  distances[source] = 0
  pushPath(0, source)
  while pathKeys.len > 0:
    var key: int64 = 0
    var nodeIndex = 0
    popPath(key, nodeIndex)
    if key != distances[nodeIndex]:
      continue
    for road in graph[nodeIndex]:
      let candidate = key + int64(road.length)
      if candidate < distances[road.to]:
        distances[road.to] = candidate
        pushPath(candidate, road.to)
  return distances
```

The graph and its reverse give both travel directions.
Lazy deletion skips heap entries with an outdated distance.
The queue is cleared at the start of each run.

**Sorting.** Insertion sort orders the round-trip costs.

```nim
proc sortCosts(costs: var seq[int64]) =
  for index in 1 .. costs.len - 1:
    let key = costs[index]
    var previousIndex = index - 1
    while previousIndex >= 0 and costs[previousIndex] > key:
      costs[previousIndex + 1] = costs[previousIndex]
      previousIndex -= 1
    costs[previousIndex + 1] = key
```

Small cases keep the code short.
The sort makes the largest costs sit at the end.
Prefix sums then give each block cost in constant time.

**Partition and output.** The dynamic program tries every legal last-group size.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while hasNextToken(inputData, scanPos):
  let nodeCount = nextInt(inputData, scanPos)
  let branchCount = nextInt(inputData, scanPos)
  let groupCount = nextInt(inputData, scanPos)
  let roadCount = nextInt(inputData, scanPos)
  var graph = newSeq[seq[Road]](nodeCount)
  var reverseGraph = newSeq[seq[Road]](nodeCount)
  for nodeIndex in 0 .. nodeCount - 1:
    graph[nodeIndex] = newSeq[Road](0)
    reverseGraph[nodeIndex] = newSeq[Road](0)
  for roadIndex in 0 .. roadCount - 1:
    let fromNode = nextInt(inputData, scanPos) - 1
    let toNode = nextInt(inputData, scanPos) - 1
    let roadLength = nextInt(inputData, scanPos)
    graph[fromNode].add((toNode, roadLength))
    reverseGraph[toNode].add((fromNode, roadLength))
  let headquarterNode = branchCount
  let distanceFromHQ = shortestFromSource(graph, headquarterNode)
  let distanceToHQ = shortestFromSource(reverseGraph, headquarterNode)
  var costs = newSeq[int64](branchCount)
  for branchIndex in 0 .. branchCount - 1:
    costs[branchIndex] = distanceFromHQ[branchIndex] + distanceToHQ[branchIndex]
  sortCosts(costs)
  var prefixCosts = newSeq[int64](branchCount + 1)
  for branchIndex in 0 .. branchCount - 1:
    prefixCosts[branchIndex + 1] = prefixCosts[branchIndex] + costs[branchIndex]
  var best = newSeq[seq[int64]](groupCount + 1)
  for groupIndex in 0 .. groupCount:
    best[groupIndex] = newSeq[int64](branchCount + 1)
  for branchTotal in 2 .. branchCount:
    best[1][branchTotal] = int64(branchTotal - 1) * prefixCosts[branchTotal]
  for groupTotal in 2 .. groupCount:
    for branchTotal in groupTotal + 1 .. branchCount:
      best[groupTotal][branchTotal] = best[groupTotal - 1][branchTotal - 1]
      let largestGroup = min(branchTotal div groupTotal, branchTotal - groupTotal + 1)
      for groupSize in 2 .. largestGroup:
        let candidate = best[groupTotal - 1][branchTotal - groupSize] +
          int64(groupSize - 1) * (prefixCosts[branchTotal] - prefixCosts[branchTotal - groupSize])
        if candidate < best[groupTotal][branchTotal]:
          best[groupTotal][branchTotal] = candidate
  appendOutput($best[groupCount][branchCount])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

One group puts every branch together.
The last group never holds more than `branchTotal div groupTotal` branches.
One final write sends all answers to standard output.

## Complexity

Dijkstra runs twice, and the table fills one cell for each group and branch pair.

| phase | time | space |
|---|---|---|
| input read | one pass over all roads | one input string |
| shortest paths | two Dijkstra runs over r roads | two adjacency lists |
| sorting | one insertion sort of b costs | array of b integers |
| partition | up to b^2 group-size trials | table of s times b entries |
| output | one line per test case | block buffer |

| measure | Big O |
|---|---|
| time per test case | O(r log n + b^2 log b) |
| space | O(r + s b) |

Enumerating all assignments would test `s^b` groupings. Sorting plus dynamic programming keeps only block sizes, so the search stays polynomial. Short takeaway: compute round trips once, then partition sorted costs.
