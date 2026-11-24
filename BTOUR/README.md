## Problem

Read a weighted undirected graph for each test case. The input gives intersections and street segments. Print the total length of the shortest simple loop and the number of distinct loops with that length. Print `0 0` when the graph has no loop.

The judge bounds are listed below.

| Quantity | Bound |
| --- | --- |
| Test cases | at most 200 |
| Intersections | 1 to 1000 |
| Street segments per intersection | 0 to 4 |
| Street length | 1 to 1000000 |
| Time limit | 17000 ms |
| Memory limit | 1536 MB |

At most four streets meet at an intersection, so every graph stays sparse.

## Idea

Anchor each loop at its lowest numbered intersection. For each street out of the anchor, run Dijkstra on the subgraph of higher numbered intersections. Distances give loop lengths and path counts give loop counts, so every loop is counted once without enumerating them all.

Cost per street: one Dijkstra run over the remaining graph, O(m log n) time.

## Why It Works

A simple loop through an anchor uses exactly two streets at that anchor. Every other intersection on the loop has a higher number than the anchor. The rest of the loop is a shortest path between those two neighbours inside the restricted subgraph. Dijkstra adds the path counts of equal-distance predecessors, so it counts all shortest paths.

The loop length has three terms.

loop length = w(s, a) + dist(a, b) + w(s, b)

w(s, a) is the weight of the first street from the anchor s.
dist(a, b) is the shortest path length with intersections at or below s removed.
w(s, b) is the weight of the second street back to the anchor.
ways(a, b) is the number of shortest paths, which is the number of loops for this pair.

The generator writes the statement sample, and the program prints this output.

    0 0
    14 2

The second graph has two loops of length 14, through intersections 1-2-3 and 2-3-4.

## Code

The input is read once into one buffer, and the output is flushed in blocks.

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

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The read loop runs once per input line, so stdin is read once.
nextInt skips non-digits and builds each value one digit at a time.
appendOutput writes a block only after the buffer reaches the flush size.
Parsing costs O(total input bytes).

The search keeps distances and path counts in flat arrays.

```nim
proc runDijkstra(startVert, restrictAbove: int, pruneLimit: int64) =
  for i in 0 .. nodeCount - 1:
    distArr[i] = infinity
    waysArr[i] = 0
  heapSize = 0
  distArr[startVert] = 0
  waysArr[startVert] = 1
  heapPush(0, startVert)
  while heapSize > 0:
    let cur = heapPop()
    let d = cur.d
    let u = cur.v
    if d > distArr[u]: continue
    if d > pruneLimit: break
    var e = adjHead[u]
    while e != -1:
      let t = adjTo[e]
      if t > restrictAbove:
        let nd = d + int64(adjW[e])
        if nd < distArr[t]:
          distArr[t] = nd
          waysArr[t] = waysArr[u]
          heapPush(nd, t)
        elif nd == distArr[t]:
          waysArr[t] += waysArr[u]
      e = adjNext[e]
```

The heap loop ends when no node is left or the distance passes pruneLimit.
restrictAbove removes the anchor and every lower intersection from the search.
Equal-distance relaxations add to waysArr and count every shortest path.
One run costs O(m log n) time and O(n) space.

The main loop anchors the loops and updates the best answer.

```nim
  for s in 0 .. nodeCount - 1:
    var neighborVert: array[8, int]
    var neighborW: array[8, int]
    var neighborCount = 0
    var e = adjHead[s]
    while e != -1:
      let t = adjTo[e]
      if t > s and neighborCount < 8:
        neighborVert[neighborCount] = t
        neighborW[neighborCount] = adjW[e]
        neighborCount += 1
      e = adjNext[e]
    if neighborCount < 2: continue
    for i in 0 .. neighborCount - 1:
      if i == neighborCount - 1: continue
      let startVert = neighborVert[i]
      let startW = neighborW[i]
      var minEndW = 1000000000
      for j in i + 1 .. neighborCount - 1:
        if neighborW[j] < minEndW: minEndW = neighborW[j]
      var pruneLimit = infinity
      if bestLen < infinity:
        if int64(startW + minEndW + 1) > bestLen: continue
        pruneLimit = bestLen - int64(startW) - int64(minEndW)
      runDijkstra(startVert, s, pruneLimit)
      for j in i + 1 .. neighborCount - 1:
        let endVert = neighborVert[j]
        if distArr[endVert] >= infinity div 2: continue
        let cycleLen = int64(startW) + distArr[endVert] + int64(neighborW[j])
        if cycleLen < bestLen:
          bestLen = cycleLen
          bestCount = waysArr[endVert]
        elif cycleLen == bestLen:
          bestCount += waysArr[endVert]
```

The outer loop runs once per intersection, and the two inner loops cover each neighbour pair once.
pruneLimit skips searches that cannot reach the current best loop.
bestCount resets for a shorter loop and grows for an equal loop.
This loop starts one Dijkstra run per street with a higher numbered neighbour.

## Complexity

Reading and parsing cost O(total input bytes). Each undirected street starts one Dijkstra run, and each run costs O(m log n) time with O(n) space. The arrays are reused across runs, so a test case takes O(m² log n) time and O(n + m) space. Enumerating every simple loop instead would take exponential time.
