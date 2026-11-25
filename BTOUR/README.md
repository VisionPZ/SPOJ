# BTOUR — Tour de Byteland (SPOJ)
<https://www.spoj.com/problems/BTOUR/>

## Problem

The mayor wants the shortest bicycle loop through Byteland's streets, plus a count of how many loops tie for shortest. Print both numbers for each street map, or `0 0` when no loop exists.

Input starts with a case count t. Each case gives n intersections and m streets, then m lines of form u v d with u at most v. Output the loop length and the number of shortest loops.

The judge bounds are listed below.

| Quantity | Bound |
| --- | --- |
| Test cases | at most 200 |
| Intersections | 1 to 1000 |
| Streets per intersection | 0 to 4 |
| Street length | 1 to 1,000,000 |
| Time limit | 17,000 ms |
| Memory limit | 1536 MB |

At most four streets meet at an intersection, so every graph stays sparse.

The sample input and output:

```
2
3 2
1 2 1
1 3 2
4 6
1 2 5
1 4 5
2 3 4
2 4 5
3 4 5
3 1 5
```

```
0 0
14 2
```

The second graph has two shortest loops of length 14.

## Idea

Anchor every loop at its lowest numbered intersection. Self-loops are counted directly. For each anchor, take pairs of streets leading to higher numbered intersections. Run Dijkstra (a shortest path method) on the subgraph of those higher intersections. The distance gives the loop length, and the path count gives the number of loops.

Each street pair costs one Dijkstra run over the remaining graph, O(m log n). Enumerating every simple loop would be exponential.

Takeaway: anchor at the smallest vertex, then count shortest paths between its neighbours.

## Why It Works

1. A simple loop through an anchor uses exactly two streets at that anchor.
2. Every other intersection on that loop has a higher number than the anchor, by the anchor choice.
3. Removing intersections at or below the anchor cannot create a shorter route between the two neighbours, so the restricted subgraph is exact.
4. Dijkstra adds the path counts of equal-distance predecessors, so it counts all shortest paths.
5. A self-loop is already a simple loop of length d, so it is handled before the main search.

The loop length has three terms.

| Term | Meaning |
| --- | --- |
| w(s, a) | weight of the first street from anchor s |
| dist(a, b) | shortest path inside the subgraph above s |
| w(s, b) | weight of the second street back to s |
| ways(a, b) | number of shortest paths, which is the loop count |

The three weights and one path count give both outputs.

The generator wrote the statement sample, and the program prints this output:

```
0 0
14 2
```

The first graph is a tree with no loop. The second has two loops of length 14:

| Loop | Streets | Total |
| --- | --- | --- |
| 1-2-3-1 | 5 + 4 + 5 | 14 |
| 2-3-4-2 | 4 + 5 + 5 | 14 |

Each loop is anchored once, so it is counted once.

## Code

**Constants, scanner, and output helper.**
```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const infinity = high(int64) div 4

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```
The buffer gathers every line, and `nextInt` walks the digits. `appendOutput` flushes in blocks. `infinity` stays far below the int64 maximum so additions cannot overflow.

**Graph arrays and heap.**
```nim
var nodeCount = 0
var adjHead = newSeq[int](1005)
var adjTo = newSeq[int](8200)
var adjWeight = newSeq[int](8200)
var adjNext = newSeq[int](8200)
var bestDist = newSeq[int64](1005)
var pathWays = newSeq[int64](1005)
var heapDist = newSeq[int64](8200)
var heapVert = newSeq[int](8200)
var heapSize = 0

proc heapPush(distValue: int64, vertex: int) =
  var idx = heapSize
  heapSize += 1
  heapDist[idx] = distValue
  heapVert[idx] = vertex
  while idx > 0:
    let parentIdx = (idx - 1) div 2
    if heapDist[parentIdx] <= heapDist[idx]: break
    swap heapDist[parentIdx], heapDist[idx]
    swap heapVert[parentIdx], heapVert[idx]
    idx = parentIdx

proc heapPop(): tuple[dist: int64, vertex: int] =
  result = (heapDist[0], heapVert[0])
  heapSize -= 1
  if heapSize > 0:
    heapDist[0] = heapDist[heapSize]
    heapVert[0] = heapVert[heapSize]
    var idx = 0
    while true:
      let leftIdx = 2 * idx + 1
      let rightIdx = 2 * idx + 2
      var smallest = idx
      if leftIdx < heapSize and heapDist[leftIdx] < heapDist[smallest]: smallest = leftIdx
      if rightIdx < heapSize and heapDist[rightIdx] < heapDist[smallest]: smallest = rightIdx
      if smallest == idx: break
      swap heapDist[smallest], heapDist[idx]
      swap heapVert[smallest], heapVert[idx]
      idx = smallest

```
Adjacency uses one flat array of edge slots. `heapPush` and `heapPop` maintain a min-heap of distances, with each swap moving distance and vertex together.

**Dijkstra with path counts.**
```nim
proc runDijkstra(startVert, restrictAbove: int, pruneLimit: int64) =
  for nodeIdx in 0 .. nodeCount - 1:
    bestDist[nodeIdx] = infinity
    pathWays[nodeIdx] = 0
  heapSize = 0
  bestDist[startVert] = 0
  pathWays[startVert] = 1
  heapPush(0, startVert)
  while heapSize > 0:
    let topItem = heapPop()
    let curDist = topItem.dist
    let vertex = topItem.vertex
    if curDist > bestDist[vertex]: continue
    if curDist > pruneLimit: break
    var edgeIdx = adjHead[vertex]
    while edgeIdx != -1:
      let neighbor = adjTo[edgeIdx]
      if neighbor > restrictAbove:
        let nextDist = curDist + int64(adjWeight[edgeIdx])
        if nextDist < bestDist[neighbor]:
          bestDist[neighbor] = nextDist
          pathWays[neighbor] = pathWays[vertex]
          heapPush(nextDist, neighbor)
        elif nextDist == bestDist[neighbor]:
          pathWays[neighbor] += pathWays[vertex]
      edgeIdx = adjNext[edgeIdx]
```
The run resets `bestDist` and `pathWays`, then relaxes edges to neighbours above `restrictAbove`. Equal-distance relaxations add `pathWays` instead of replacing it. `pruneLimit` stops work that cannot beat the current best.

**Case input and self-loops.**
```nim
let caseCount = nextInt(inputData, scanPos)
for caseIdx in 0 .. caseCount - 1:
  nodeCount = nextInt(inputData, scanPos)
  let edgeCount = nextInt(inputData, scanPos)
  for i in 0 .. nodeCount - 1: adjHead[i] = -1
  var edgeSlot = 0
  var bestLen = infinity
  var bestCount: int64 = 0
  for edgeIdx in 0 .. edgeCount - 1:
    let fromVert = nextInt(inputData, scanPos) - 1
    let toVert = nextInt(inputData, scanPos) - 1
    let weight = nextInt(inputData, scanPos)
    if fromVert == toVert:
      let selfLen = int64(weight)
      if selfLen < bestLen:
        bestLen = selfLen
        bestCount = 1
      elif selfLen == bestLen:
        bestCount += 1
    else:
      adjTo[edgeSlot] = toVert
      adjWeight[edgeSlot] = weight
      adjNext[edgeSlot] = adjHead[fromVert]
      adjHead[fromVert] = edgeSlot
      edgeSlot += 1
      adjTo[edgeSlot] = fromVert
      adjWeight[edgeSlot] = weight
      adjNext[edgeSlot] = adjHead[toVert]
      adjHead[toVert] = edgeSlot
      edgeSlot += 1
```
The code reads each street into the adjacency arrays. A street with equal ends updates `bestLen` and `bestCount` directly. Other streets are stored in both directions.

**Anchor loop and answer.**
```nim
  for rootVert in 0 .. nodeCount - 1:
    var neighborVert: array[8, int]
    var neighborWeight: array[8, int]
    var neighborCount = 0
    var edgeIdx = adjHead[rootVert]
    while edgeIdx != -1:
      let neighbor = adjTo[edgeIdx]
      if neighbor > rootVert and neighborCount < 8:
        neighborVert[neighborCount] = neighbor
        neighborWeight[neighborCount] = adjWeight[edgeIdx]
        neighborCount += 1
      edgeIdx = adjNext[edgeIdx]
    if neighborCount < 2: continue
    for firstIdx in 0 .. neighborCount - 1:
      if firstIdx == neighborCount - 1: continue
      let startVert = neighborVert[firstIdx]
      let startWeight = neighborWeight[firstIdx]
      var minEndWeight = 1000000000
      for secondIdx in firstIdx + 1 .. neighborCount - 1:
        if neighborWeight[secondIdx] < minEndWeight: minEndWeight = neighborWeight[secondIdx]
      var pruneLimit = infinity
      if bestLen < infinity:
        if int64(startWeight + minEndWeight + 1) > bestLen: continue
        pruneLimit = bestLen - int64(startWeight) - int64(minEndWeight)
      runDijkstra(startVert, rootVert, pruneLimit)
      for secondIdx in firstIdx + 1 .. neighborCount - 1:
        let endVert = neighborVert[secondIdx]
        if bestDist[endVert] >= infinity div 2: continue
        let cycleLen = int64(startWeight) + bestDist[endVert] + int64(neighborWeight[secondIdx])
        if cycleLen < bestLen:
          bestLen = cycleLen
          bestCount = pathWays[endVert]
        elif cycleLen == bestLen:
          bestCount += pathWays[endVert]
  if bestLen == infinity:
    appendOutput("0 0")
  else:
    appendOutput($bestLen)
    outputBuffer.add ' '
    appendOutput($bestCount)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```
For each anchor, the code collects at most eight higher neighbours. Each neighbour pair triggers a Dijkstra run, and the three-part length updates the best loop and its count. The final line prints `0 0` when no loop was found.

## Complexity

Degree at most four bounds the work per anchor.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | one pass over input bytes | input bytes |
| Graph build | O(m) | O(m) edge slots |
| Dijkstra runs | O(n times m log n) worst case | O(n) per run |
| Answer selection | O(n) | O(n) |
| Output | one write per block | flushBlockBytes |

Sparse streets and the anchor rule keep the run count low.

| Measure | Big O |
| --- | --- |
| Time per case | O(n m log n) worst case |
| Space per case | O(n + m) |

Listing every simple loop would be exponential, while anchored shortest paths count them all in polynomial time.
