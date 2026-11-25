# BIA — Bytelandian Information Agency (SPOJ)
<https://www.spoj.com/problems/BIA/>

## Problem

A network must keep every computer reachable from the server, and one broken relay can cut off a whole branch.
The agency needs a list of the relays that matter.

The input holds ten cases one after another with no count line. Each case gives n and m, then m directed channel pairs. Print the number of critical computers, then their numbers in increasing order.

The bounds and judge limits are:

| Constraint | Value |
| --- | --- |
| Cases | ten, given back to back |
| Computers n | 2 to 5000 |
| Channels m | n-1 to 200000 |
| Judge time | 7 s |
| Judge memory | 1536 MB |

A near-linear dominator algorithm is required at the largest channel count.

The sample input and its expected output follow byte for byte.

```
4 5
1 2
1 4
2 3
3 4
4 2
```

```
2
1 2
```


## Idea

A computer is critical when it has a child in the dominator tree (tree of forced relays), like a junction guarding a whole branch.
The program numbers vertices with a depth-first walk from the server. It computes semidominators (candidate forced relays from DFS predecessors) by scanning predecessors in reverse number order. Path compression keeps each edge close to constant work.
Once immediate dominators are known, a child count per dominator identifies every critical computer. Removing each vertex and rerunning reachability would cost O(nm) per case.
Dominator tree counts turn reachability tests into one linear pass.

## Why It Works

1. A vertex is critical when removing it disconnects some other vertex from the server.
2. That is the same as having at least one child in the dominator tree rooted at the server.
3. DFS numbers give the preorder used by the semidominator scan in reverse order.
4. `evaluateVertex` compresses paths, so each predecessor edge costs near constant amortized work.
5. Counting children of every immediate dominator gives the answer directly, in original vertex order.

Four terms carry the proof.

| Term | Meaning |
| --- | --- |
| dominator | vertex every path from the server passes through |
| dominator tree | tree of immediate dominator links |
| semidominator | candidate from the DFS predecessor scan |
| critical vertex | dominator with at least one child |

They explain why one tree count answers every removal question.

A script check of the sample uses edges 1 to 2, 1 to 4, 2 to 3, 3 to 4, and 4 to 2.
The dominator tree links 1 to 2, 1 to 4, and 2 to 3.
Vertex 1 has two children and vertex 2 has one, so the report is 2, then 1 2.

## Code

**Path compression helpers.**
```nim
proc compressPath(k: int) =
  let parentNumber = ancestorNumber[k]
  if ancestorNumber[parentNumber] != 0:
    compressPath(parentNumber)
    if semiNumber[labelNumber[parentNumber]] < semiNumber[labelNumber[k]]:
      labelNumber[k] = labelNumber[parentNumber]
    ancestorNumber[k] = ancestorNumber[parentNumber]

proc evaluateVertex(k: int): int =
  if ancestorNumber[k] == 0:
    return k
  compressPath(k)
  return labelNumber[k]

proc linkVertex(parentNumber: int, childNumber: int) =
  ancestorNumber[childNumber] = parentNumber

```

`compressPath` walks ancestors and lowers labels. `evaluateVertex` returns the smallest semi number on a path. `linkVertex` attaches a vertex to its DFS parent.

**Forward graph build.**
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
  for l in 0 .. vertexCount:
    forwardHead[l] = 0
  for i in 0 ..< edgeCount:
    let sourceVertex = scanInt()
    let targetVertex = scanInt()
    let j = i + 1
    edgeFrom[i] = sourceVertex
    edgeTo[i] = targetVertex
    forwardTo[j] = targetVertex
    forwardNext[j] = forwardHead[sourceVertex]
    forwardHead[sourceVertex] = j
```

The code stores each channel in forward adjacency arrays. Original endpoints are saved for the later predecessor scan. All arrays are sized from n and m.

**Depth-first numbering.**
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
  for l in 0 .. vertexCount:
    dfsNumber[l] = 0
  var numberCount = 1
  dfsNumber[1] = numberCount
  vertexAtNumber[numberCount] = 1
  parentNumber[numberCount] = 0
  var depth = 0
  stackVertex[0] = 1
  stackEdge[0] = forwardHead[1]
  while depth >= 0:
    let currentVertex = stackVertex[depth]
    var i = stackEdge[depth]
    while i != 0 and dfsNumber[forwardTo[i]] != 0:
      i = forwardNext[i]
    if i == 0:
      depth.dec
    else:
      stackEdge[depth] = forwardNext[i]
      let nextVertex = forwardTo[i]
      numberCount.inc
      dfsNumber[nextVertex] = numberCount
      vertexAtNumber[numberCount] = nextVertex
      parentNumber[numberCount] = dfsNumber[currentVertex]
      depth.inc
      stackVertex[depth] = nextVertex
      stackEdge[depth] = forwardHead[nextVertex]
```

An explicit stack avoids recursion at 5000 vertices. Each discovered vertex receives the next DFS number. The parent number is kept for the dominator pass.

**Semidominator pass.**
```nim
  var predHead: seq[int] = @[]
  var predSource: seq[int] = @[]
  var predNext: seq[int] = @[]
  predHead.setLen(numberCount + 1)
  predSource.setLen(edgeCount + 1)
  predNext.setLen(edgeCount + 1)
  for k in 0 .. numberCount:
    predHead[k] = 0
  for i in 0 ..< edgeCount:
    let j = i + 1
    let fromNumber = dfsNumber[edgeFrom[i]]
    let toNumber = dfsNumber[edgeTo[i]]
    predSource[j] = fromNumber
    predNext[j] = predHead[toNumber]
    predHead[toNumber] = j

  semiNumber.setLen(numberCount + 1)
  labelNumber.setLen(numberCount + 1)
  ancestorNumber.setLen(numberCount + 1)
  immediateDominator.setLen(numberCount + 1)
  var bucketHead: seq[int] = @[]
  var bucketNext: seq[int] = @[]
  bucketHead.setLen(numberCount + 1)
  bucketNext.setLen(numberCount + 1)
  for k in 0 .. numberCount:
    semiNumber[k] = k
    labelNumber[k] = k
    ancestorNumber[k] = 0
    immediateDominator[k] = 0
    bucketHead[k] = 0
    bucketNext[k] = 0

  for k in countdown(numberCount, 2):
    var i = predHead[k]
    while i != 0:
      let candidate = evaluateVertex(predSource[i])
      if semiNumber[candidate] < semiNumber[k]:
        semiNumber[k] = semiNumber[candidate]
      i = predNext[i]
    bucketNext[k] = bucketHead[semiNumber[k]]
    bucketHead[semiNumber[k]] = k
    let parent = parentNumber[k]
    linkVertex(parent, k)
    var bucketVertex = bucketHead[parent]
    while bucketVertex != 0:
      let candidate = evaluateVertex(bucketVertex)
      if semiNumber[candidate] < semiNumber[bucketVertex]:
        immediateDominator[bucketVertex] = candidate
      else:
        immediateDominator[bucketVertex] = parent
      bucketVertex = bucketNext[bucketVertex]
    bucketHead[parent] = 0

  for k in 2 .. numberCount:
    if immediateDominator[k] != semiNumber[k]:
      immediateDominator[k] = immediateDominator[immediateDominator[k]]
```

The loop visits DFS numbers from the largest down to two. Bucket lists delay dominator decisions until the parent is ready. A second loop resolves remaining immediate dominators.

**Critical count and driver.**
```nim
  var childCount: seq[int] = @[]
  childCount.setLen(numberCount + 1)
  for k in 0 .. numberCount:
    childCount[k] = 0
  for k in 2 .. numberCount:
    childCount[immediateDominator[k]].inc

  var criticalCount = 0
  var criticalList: seq[int] = @[]
  for originalVertex in 1 .. vertexCount:
    let k = dfsNumber[originalVertex]
    if childCount[k] >= 1:
      criticalCount.inc
      criticalList.add originalVertex

  emitInt(criticalCount)
  emitChar('\n')
  for i in 0 ..< criticalList.len:
    if i > 0:
      emitChar(' ')
    emitInt(criticalList[i])
  emitChar('\n')

while moreInput():
  let vertexCount = scanInt()
  let edgeCount = scanInt()
  solveCase(vertexCount, edgeCount)

stdout.write outputBuffer
```

The code counts children of each immediate dominator. Vertices with at least one child are printed in number order. The driver processes all ten cases from one buffer.


## Complexity

The dominator pass touches each edge a near-constant number of times.

| Phase | Time | Space |
| --- | --- | --- |
| graph build | O(m) | forward arrays |
| DFS numbering | O(n+m) | stack and number arrays |
| dominator pass | O(m alpha(n)) | buckets and labels |
| critical count | O(n) | child counts |

No reachability search is repeated per computer.

Big O uses computer count n and channel count m.

| Measure | Big O |
| --- | --- |
| time | O(m alpha(n)) per case |
| space | O(n+m) |

Remove-and-recheck would cost O(nm) per case, far above this bound.
