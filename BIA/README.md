## Problem

Computer 1 is the server of a one-way network. Every other computer receives information from it through directed channels. A computer is critical when breaking it cuts information off from at least one other computer. Print the count of critical computers, then their numbers in increasing order.

Each input holds ten test cases. The table gives the bounds.

| Quantity | Limit |
| --- | --- |
| Computers | 2 to 5000 |
| Channels | n-1 to 200000 |
| Test cases | 10 |
| Time limit | 7 s |
| Memory limit | 1536 MB |

The server reaches every computer in each test case.

## Idea

A computer is critical when it has a child in the dominator tree. That tree places each computer under the last computer that every path to it shares. The program builds the tree with the Lengauer-Tarjan algorithm. That method numbers vertices by depth-first search and joins sets with path compression. A fixpoint method would rebuild dominator sets for every vertex on each round.

Cost per item: one set lookup for each channel, plus one pass over the buckets.

## Why It Works

Breaking a computer cuts information only when that computer lies on every path to another computer. The "every path" test is the dominator relation.

The program numbers vertices in depth-first order. The marker semi[w] is the smallest number that reaches w along a path whose inner vertices all have larger numbers. The formula has three terms.

| Term | Meaning |
| --- | --- |
| DFS number | The order in which the search first reaches a vertex. |
| semi[w] | Smallest number reaching w with inner numbers above w. |
| idom[w] | The parent of w in the dominator tree. |

Each term is a DFS number, so the arrays stay flat and small.

The program visits vertices from the largest number down to two. It reads each predecessor through a set lookup and keeps the smallest marker. Then it clears the bucket of the DFS parent and stores a parent for that bucket. A final pass replaces short links with their own parents.

| Step | Effect |
| --- | --- |
| Descending pass | Turns markers into direct tree parents. |
| Ascending pass | Extends short parents to their own parents. |
| Child count | Marks every vertex with at least one tree child. |

The child count gives the answer, because only a tree parent cuts information.

A script printed the table below for the sample graph. The idom column holds DFS numbers, so the value 3 for vertex 3 means vertex 2.

| Vertex | DFS number | DFS parent | semi | idom | Children |
| --- | --- | --- | --- | --- | --- |
| 1 | 1 | 0 | 1 | 0 | 2 |
| 2 | 3 | 2 | 1 | 1 | 1 |
| 3 | 4 | 3 | 3 | 3 | 0 |
| 4 | 2 | 1 | 1 | 1 | 0 |

Vertex 1 and vertex 2 have children, so they are the critical ones.

## Code

The blocks below come from the program without edits.

```nim
const flushBlockBytes = 1 shl 18
const firstDigitValue = 48

var inputData = readAll(stdin)
var scanPos = 0

proc moreInput(): bool =
  let dataLength = inputData.len
  while scanPos < dataLength and inputData[scanPos] <= ' ':
    scanPos.inc
  return scanPos < dataLength

proc scanInt(): int =
  let dataLength = inputData.len
  while scanPos < dataLength and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos.inc
  result = 0
  while scanPos < dataLength and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    result = result * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos.inc

var outputBuffer = ""

proc emitInt(value: int) =
  outputBuffer.add $value
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc emitChar(value: char) =
  outputBuffer.add value
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The read call loads the whole stream once. The scanner walks inputData by index and builds no token objects. Each emit flushes at flushBlockBytes, so output never writes per number.

```nim
var semiNumber: seq[int] = @[]
var labelNumber: seq[int] = @[]
var ancestorNumber: seq[int] = @[]
var immediateDominator: seq[int] = @[]

proc compressPath(vertexNumber: int) =
  let parentNumber = ancestorNumber[vertexNumber]
  if ancestorNumber[parentNumber] != 0:
    compressPath(parentNumber)
    if semiNumber[labelNumber[parentNumber]] < semiNumber[labelNumber[vertexNumber]]:
      labelNumber[vertexNumber] = labelNumber[parentNumber]
    ancestorNumber[vertexNumber] = ancestorNumber[parentNumber]

proc evaluateVertex(vertexNumber: int): int =
  if ancestorNumber[vertexNumber] == 0:
    return vertexNumber
  compressPath(vertexNumber)
  return labelNumber[vertexNumber]

proc linkVertex(parentNumber: int, childNumber: int) =
  ancestorNumber[childNumber] = parentNumber
```

Zero marks an unlinked vertex, so no array entry holds a nil pointer. Compression shortens one path and carries the smallest marker upward. One lookup costs the length of that path after compression.

```nim
proc solveCase(vertexCount: int, edgeCount: int) =
  var forwardHead: seq[int] = @[]
  var forwardTo: seq[int] = @[]
  var forwardNext: seq[int] = @[]
  var edgeFrom: seq[int] = @[]
  var edgeTo: seq[int] = @[]
  forwardHead.setLen(vertexCount + 1)
  forwardTo.setLen(edgeCount + 1)
  forwardNext.setLen(edgeCount + 1)
  edgeFrom.setLen(edgeCount)
  edgeTo.setLen(edgeCount)
  for vertexId in 0 .. vertexCount:
    forwardHead[vertexId] = 0
  for edgeIndex in 0 ..< edgeCount:
    let sourceVertex = scanInt()
    let targetVertex = scanInt()
    let storeIndex = edgeIndex + 1
    edgeFrom[edgeIndex] = sourceVertex
    edgeTo[edgeIndex] = targetVertex
    forwardTo[storeIndex] = targetVertex
    forwardNext[storeIndex] = forwardHead[sourceVertex]
    forwardHead[sourceVertex] = storeIndex
```

The loop reads exactly edgeCount pairs. Storing at edgeIndex + 1 keeps zero free as the list end marker. Zero as an edge slot would silently drop the first channel. This block costs one scan and two array writes per channel.

```nim
  var dfsNumber: seq[int] = @[]
  var vertexAtNumber: seq[int] = @[]
  var parentNumber: seq[int] = @[]
  var stackVertex: seq[int] = @[]
  var stackEdge: seq[int] = @[]
  dfsNumber.setLen(vertexCount + 1)
  vertexAtNumber.setLen(vertexCount + 1)
  parentNumber.setLen(vertexCount + 1)
  stackVertex.setLen(vertexCount + 1)
  stackEdge.setLen(vertexCount + 1)
  for vertexId in 0 .. vertexCount:
    dfsNumber[vertexId] = 0
  var numberCount = 1
  dfsNumber[1] = numberCount
  vertexAtNumber[numberCount] = 1
  parentNumber[numberCount] = 0
  var depth = 0
  stackVertex[0] = 1
  stackEdge[0] = forwardHead[1]
  while depth >= 0:
    let currentVertex = stackVertex[depth]
    var edgeIndex = stackEdge[depth]
    while edgeIndex != 0 and dfsNumber[forwardTo[edgeIndex]] != 0:
      edgeIndex = forwardNext[edgeIndex]
    if edgeIndex == 0:
      depth.dec
    else:
      stackEdge[depth] = forwardNext[edgeIndex]
      let nextVertex = forwardTo[edgeIndex]
      numberCount.inc
      dfsNumber[nextVertex] = numberCount
      vertexAtNumber[numberCount] = nextVertex
      parentNumber[numberCount] = dfsNumber[currentVertex]
      depth.inc
      stackVertex[depth] = nextVertex
      stackEdge[depth] = forwardHead[nextVertex]
```

Each stack slot holds one vertex and its next edge, so the search never recurses. The inner loop skips edges that already have a number. A vertex receives its number once, so the whole walk costs one pass over the channels.

```nim
  var predHead: seq[int] = @[]
  var predSource: seq[int] = @[]
  var predNext: seq[int] = @[]
  predHead.setLen(numberCount + 1)
  predSource.setLen(edgeCount + 1)
  predNext.setLen(edgeCount + 1)
  for vertexNumber in 0 .. numberCount:
    predHead[vertexNumber] = 0
  for edgeIndex in 0 ..< edgeCount:
    let storeIndex = edgeIndex + 1
    let fromNumber = dfsNumber[edgeFrom[edgeIndex]]
    let toNumber = dfsNumber[edgeTo[edgeIndex]]
    predSource[storeIndex] = fromNumber
    predNext[storeIndex] = predHead[toNumber]
    predHead[toNumber] = storeIndex
```

This pass rewrites each channel end into a DFS number. The lists then live in number space, so the dominator arrays need no vertex-id translation. Rebuilding them per case keeps memory inside one test case.

```nim
  semiNumber.setLen(numberCount + 1)
  labelNumber.setLen(numberCount + 1)
  ancestorNumber.setLen(numberCount + 1)
  immediateDominator.setLen(numberCount + 1)
  var bucketHead: seq[int] = @[]
  var bucketNext: seq[int] = @[]
  bucketHead.setLen(numberCount + 1)
  bucketNext.setLen(numberCount + 1)
  for vertexNumber in 0 .. numberCount:
    semiNumber[vertexNumber] = vertexNumber
    labelNumber[vertexNumber] = vertexNumber
    ancestorNumber[vertexNumber] = 0
    immediateDominator[vertexNumber] = 0
    bucketHead[vertexNumber] = 0
    bucketNext[vertexNumber] = 0

  for vertexNumber in countdown(numberCount, 2):
    var edgeIndex = predHead[vertexNumber]
    while edgeIndex != 0:
      let candidate = evaluateVertex(predSource[edgeIndex])
      if semiNumber[candidate] < semiNumber[vertexNumber]:
        semiNumber[vertexNumber] = semiNumber[candidate]
      edgeIndex = predNext[edgeIndex]
    bucketNext[vertexNumber] = bucketHead[semiNumber[vertexNumber]]
    bucketHead[semiNumber[vertexNumber]] = vertexNumber
    let parent = parentNumber[vertexNumber]
    linkVertex(parent, vertexNumber)
    var bucketVertex = bucketHead[parent]
    while bucketVertex != 0:
      let candidate = evaluateVertex(bucketVertex)
      if semiNumber[candidate] < semiNumber[bucketVertex]:
        immediateDominator[bucketVertex] = candidate
      else:
        immediateDominator[bucketVertex] = parent
      bucketVertex = bucketNext[bucketVertex]
    bucketHead[parent] = 0
```

The countdown visits numberCount minus one vertices, from the last number down to two. Each vertex enters one bucket, and each bucket empties once. Path compression keeps the set work near linear. A self-loop gives a candidate with the same marker and changes nothing.

```nim
  for vertexNumber in 2 .. numberCount:
    if immediateDominator[vertexNumber] != semiNumber[vertexNumber]:
      immediateDominator[vertexNumber] = immediateDominator[immediateDominator[vertexNumber]]

  var childCount: seq[int] = @[]
  childCount.setLen(numberCount + 1)
  for vertexNumber in 0 .. numberCount:
    childCount[vertexNumber] = 0
  for vertexNumber in 2 .. numberCount:
    childCount[immediateDominator[vertexNumber]].inc

  var criticalCount = 0
  var criticalList: seq[int] = @[]
  for originalVertex in 1 .. vertexCount:
    let vertexNumber = dfsNumber[originalVertex]
    if childCount[vertexNumber] >= 1:
      criticalCount.inc
      criticalList.add originalVertex

  emitInt(criticalCount)
  emitChar('\n')
  for listIndex in 0 ..< criticalList.len:
    if listIndex > 0:
      emitChar(' ')
    emitInt(criticalList[listIndex])
  emitChar('\n')

while moreInput():
  let vertexCount = scanInt()
  let edgeCount = scanInt()
  solveCase(vertexCount, edgeCount)

stdout.write outputBuffer
```

The ascending loop covers numberCount minus one vertices again. Counting children needs one visit per non-root vertex. The output loop walks original ids in order, so the list is already sorted. The driver reads cases until input ends, which also accepts a single sample case.

## Complexity

Reading and scanning take time linear in the input size and use one buffer.

The depth-first walk and the predecessor rewrite each touch every channel once. They use O(n + m) space for the forward and backward lists.

The dominator pass costs O(m) set lookups plus path compression. The bucket work and the counting pass each cost O(n). The whole solver runs in O((n + m) alpha(n)) time and O(n + m) space per case.

A naive method removes each computer and searches the network again. That costs O(n times (n + m)) per case, which is far above the limit at the largest bounds.
