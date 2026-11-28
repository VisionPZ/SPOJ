# GRAPHCUT — Graph Cut (SPOJ)
<https://www.spoj.com/problems/GRAPHCUT/>

## Problem

Decide whether the first K edges of a graph are exactly the edges crossing between some two groups of vertices. Print `YES` when such a split exists and `NO` otherwise.

Input begins with the test count. Each test gives `N E K`, then `E` lines `u v`. The first `K` lines form the requested edge subset.

| item | bound |
|---|---|
| tests | 1 to 40 |
| vertices N | 2 to 500 |
| edges E | 1 to 10000 |
| requested edges K | 1 to E |
| judge limit | 1000 ms, 1536 MB |

An edge belongs to the cut when exactly one of its endpoints lies in the chosen group.

Sample input:

```
2
3 3 1
1 2
2 3
1 3
12 17 6
3 4
5 6
10 11
1 5
6 10
4 8
1 2
2 3
6 7
7 8
9 10
11 12
5 9
2 6
3 7
7 11
8 12
```

Sample output:

```
NO
YES
```

## Idea

Give each edge a mark: one for the requested subset and zero for the rest. Then try to give every vertex a side, like coloring a map so each marked road crosses a border and each unmarked road stays inside. Walking the graph with parity does this in one pass.

A triangle with a single marked edge fails, because going around the triangle would flip the side an odd number of times and return to the start. A breadth-first walk detects that conflict immediately.

## Why It Works

1. Let side be 0 or 1 for each vertex.
2. An edge crosses the cut exactly when its endpoint sides differ.
3. So every edge imposes `side[u] xor side[v] = mark`.
4. A vertex reached along a marked edge must switch side; an unmarked edge keeps it.
5. Two different side assignments for one vertex mean no cut exists.

| term | meaning |
|---|---|
| `edgeMark` | 1 for a requested edge, 0 otherwise |
| `vertexSide` | the deduced 0 or 1 side of a vertex |
| `wantedSide` | side forced by the current edge |
| `adjacencyHead` | first edge stored for a vertex |

In the first sample test the edges form a triangle and only `(1, 2)` is requested. Vertex 1 gets side 0, vertex 2 gets side 1, vertex 3 gets side 0, and the last edge then demands side 1 for vertex 3. That conflict gives `NO`.

## Code

**Input and scan helpers.** The whole input is buffered and parsed by a digit scanner.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Line breaks and spacing do not matter to the scanner.
Each answer waits in the output buffer.
The buffer flushes when it grows past the block size.

**Store the edges.** Both directions of each edge enter one adjacency list.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseNumber in 0 .. caseCount - 1:
  let vertexCount = nextInt(inputData, scanPos)
  let edgeCount = nextInt(inputData, scanPos)
  let cutEdgeCount = nextInt(inputData, scanPos)
  var adjacencyHead = newSeq[int](vertexCount + 1)
  var edgeTarget = newSeq[int](2 * edgeCount + 1)
  var edgeNext = newSeq[int](2 * edgeCount + 1)
  var edgeMark = newSeq[int](2 * edgeCount + 1)
  for edgeIndex in 1 .. edgeCount:
    let fromVertex = nextInt(inputData, scanPos)
    let toVertex = nextInt(inputData, scanPos)
    edgeTarget[edgeIndex] = toVertex
    edgeMark[edgeIndex] = 0
    if edgeIndex <= cutEdgeCount:
      edgeMark[edgeIndex] = 1
    edgeNext[edgeIndex] = adjacencyHead[fromVertex]
    adjacencyHead[fromVertex] = edgeIndex
    edgeTarget[edgeIndex + edgeCount] = fromVertex
    edgeNext[edgeIndex + edgeCount] = adjacencyHead[toVertex]
    adjacencyHead[toVertex] = edgeIndex + edgeCount
    edgeMark[edgeIndex + edgeCount] = edgeMark[edgeIndex]
```

The first K input edges receive mark 1.
The reverse copy keeps the same mark.
Head and next arrays form a linked adjacency list without sorting.

**Parity walk.** Each component starts at side zero and spreads along its edges.

```nim
  var vertexSide = newSeq[int](vertexCount + 1)
  for vertexIndex in 1 .. vertexCount:
    vertexSide[vertexIndex] = -1
  var queue = newSeq[int](vertexCount)
  var isCut = true
  for rootVertex in 1 .. vertexCount:
    if vertexSide[rootVertex] != -1:
      continue
    vertexSide[rootVertex] = 0
    var queueHead = 0
    var queueTail = 0
    queue[queueTail] = rootVertex
    queueTail += 1
    while queueHead < queueTail:
      let currentVertex = queue[queueHead]
      queueHead += 1
      var edgeCursor = adjacencyHead[currentVertex]
      while edgeCursor != 0:
        let neighborVertex = edgeTarget[edgeCursor]
        let wantedSide = vertexSide[currentVertex] xor edgeMark[edgeCursor]
        if vertexSide[neighborVertex] == -1:
          vertexSide[neighborVertex] = wantedSide
          queue[queueTail] = neighborVertex
          queueTail += 1
        elif vertexSide[neighborVertex] != wantedSide:
          isCut = false
        edgeCursor = edgeNext[edgeCursor]
```

Value -1 means the vertex has no side yet.
A marked edge flips the side; an unmarked edge keeps it.
A mismatch proves that no valid split exists.

**Answer.** The accumulated flag becomes one output line.

```nim
  if isCut:
    appendOutput("YES")
  else:
    appendOutput("NO")
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Every test contributes exactly one line.
Disconnected components are handled by the outer loop.
The final write happens after the last test.

## Complexity

Each directed edge is visited once by the walk.

| phase | time | space |
|---|---|---|
| edge reading | one pass over E lines | two arrays of 2E entries |
| parity walk | one visit per vertex and edge | side array and queue |
| output | one line per test | block buffer |

| measure | Big O |
|---|---|
| time per test | O(N + E) |
| space per test | O(N + E) |

Trying all 2^N vertex subsets would be exponential.
The parity walk settles the same question in linear time.
