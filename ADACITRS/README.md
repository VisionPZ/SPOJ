# ADACITRS — Ada and Lemon 2 (SPOJ)
<https://www.spoj.com/problems/ADACITRS/>

## Problem

Remove one leaf from a large unlabelled tree and count the number of different tree shapes that can result. A leaf has degree one. Two shapes match when a relabelling of vertices maps one onto the other.

The input gives one integer `nodeCount`, then `nodeCount − 1` edges with endpoints from zero to `nodeCount − 1`. Print one integer: the number of distinct shapes after one leaf is removed.

| item | bound |
|---|---|
| nodes | 25 to 300000 |
| edge endpoints | 0 to `nodeCount − 1` |
| judge limit | 2000 ms, 1536 MB |

The tree is connected and acyclic.

Sample input:

```
25
18 7
16 18
15 18
8 7
1 8
13 15
22 8
14 18
3 18
23 7
10 8
20 1
21 14
19 3
6 3
9 6
11 7
5 15
17 16
12 22
4 10
24 17
0 8
2 19
```

Sample output:

```
7
```

## Idea

Two leaves leave the same tree exactly when a symmetry of the tree can swap them, like matching folds on a paper snowflake. Root at the center and give each rooted subtree a shape number by sorting child numbers. Give each vertex an orbit number from its parent orbit and its own shape number. Count the orbit numbers held by leaves. Recomputing a whole tree shape for every leaf costs quadratic time; this pass numbers every vertex once. One center pass and two numbering passes finish the tree.

## Why It Works

1. Deleting a leaf removes one degree-one vertex and nothing else.
2. For trees, two leaves give isomorphic remainders exactly when an automorphism maps one leaf to the other.
3. An automorphism fixes the center or swaps the two central vertices, so a virtual root models every symmetry.
4. Sorting child shape numbers gives a canonical number for each rooted subtree.
5. The pair of parent orbit and subtree shape determines the orbit of a vertex.
6. The number of distinct leaf orbit numbers is the required answer.

These names carry the main values.

| term | meaning |
|---|---|
| `findCenters` | routine that finds one or two central vertices |
| `virtualRoot` | extra root above the center or both centers |
| `subtreeIds` | canonical shape number of each rooted subtree |
| `orbitIds` | symmetry class number of each vertex |
| `leafOrbits` | set of orbit numbers held by leaves |

The virtual root handles both center cases with one numbering pass.

A script-generated trace of the sample tree has center 18 and twelve leaves with these orbit numbers:

| leaf | orbit number |
|---|---|
| 0 | 14 |
| 2 | 16 |
| 4 | 17 |
| 5 | 10 |
| 9 | 16 |
| 11 | 8 |
| 12 | 17 |
| 13 | 10 |
| 20 | 17 |
| 21 | 11 |
| 23 | 8 |
| 24 | 15 |

Seven numbers occur: 8, 10, 11, 14, 15, 16, 17. The sample answer is 7.

Keys use four bytes per integer, so a vertex count of 300000 fits without widening. The sentinel −1 marks unset parents.

## Code

**Reader, comparators, and keys.** The parser reads digit tokens and packs integers into byte keys.

```nim
import algorithm
import tables

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

proc compareIds(leftValue, rightValue: int): int =
  if leftValue < rightValue: return -1
  if leftValue > rightValue: return 1
  return 0

proc encodeNumbers(values: seq[int]): string =
  var key = newString(values.len * 4)
  for index in 0 .. values.len - 1:
    let value = values[index]
    let offset = index * 4
    key[offset] = chr(value and 255)
    key[offset + 1] = chr((value shr 8) and 255)
    key[offset + 2] = chr((value shr 16) and 255)
    key[offset + 3] = chr((value shr 24) and 255)
  return key

proc encodePair(firstValue, secondValue: int): string =
  var key = newString(8)
  key[0] = chr(firstValue and 255)
  key[1] = chr((firstValue shr 8) and 255)
  key[2] = chr((firstValue shr 16) and 255)
  key[3] = chr((firstValue shr 24) and 255)
  key[4] = chr(secondValue and 255)
  key[5] = chr((secondValue shr 8) and 255)
  key[6] = chr((secondValue shr 16) and 255)
  key[7] = chr((secondValue shr 24) and 255)
  return key

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Each shape key stores four bytes per child number.
Each orbit key stores a parent orbit and one shape number.

**Adjacency storage.** Arrays hold directed edge slots and reuse them for the virtual root.

```nim
var edgeTarget: seq[int]
var edgeLink: seq[int]
var nodeHead: seq[int]
var edgeCursor = 0

proc resetEdges(nodeTotal: int) =
  edgeTarget = newSeq[int](2 * nodeTotal + 4)
  edgeLink = newSeq[int](2 * nodeTotal + 4)
  nodeHead = newSeq[int](nodeTotal + 1)
  for node in 0 .. nodeTotal:
    nodeHead[node] = -1
  edgeCursor = 0

proc addEdge(sourceNode, targetNode: int) =
  edgeTarget[edgeCursor] = targetNode
  edgeLink[edgeCursor] = nodeHead[sourceNode]
  nodeHead[sourceNode] = edgeCursor
  edgeCursor += 1
```

Two slots serve each undirected edge.
The spare slots hold the virtual root edges.

**Center search.** A forward walk and a reverse pass compute subtree sizes and centers.

```nim
proc findCenters(nodeTotal: int): seq[int] =
  var walkParent = newSeq[int](nodeTotal)
  for node in 0 .. nodeTotal - 1:
    walkParent[node] = -1
  var walkOrder = newSeq[int]()
  walkParent[0] = -2
  walkOrder.add 0
  var walkCursor = 0
  while walkCursor < walkOrder.len:
    let node = walkOrder[walkCursor]
    var edgeIndex = nodeHead[node]
    while edgeIndex != -1:
      let neighbor = edgeTarget[edgeIndex]
      if walkParent[neighbor] == -1:
        walkParent[neighbor] = node
        walkOrder.add neighbor
      edgeIndex = edgeLink[edgeIndex]
    walkCursor += 1
  var subtreeSizes = newSeq[int](nodeTotal)
  for node in 0 .. nodeTotal - 1:
    subtreeSizes[node] = 1
  for orderPos in countdown(walkOrder.len - 1, 0):
    let node = walkOrder[orderPos]
    var edgeIndex = nodeHead[node]
    while edgeIndex != -1:
      let neighbor = edgeTarget[edgeIndex]
      if walkParent[neighbor] == node:
        subtreeSizes[node] += subtreeSizes[neighbor]
      edgeIndex = edgeLink[edgeIndex]
  var centers = newSeq[int]()
  for node in 0 .. nodeTotal - 1:
    var largestPart = nodeTotal - subtreeSizes[node]
    var edgeIndex = nodeHead[node]
    while edgeIndex != -1:
      let neighbor = edgeTarget[edgeIndex]
      if walkParent[neighbor] == node and subtreeSizes[neighbor] > largestPart:
        largestPart = subtreeSizes[neighbor]
      edgeIndex = edgeLink[edgeIndex]
    if largestPart <= nodeTotal div 2:
      centers.add node
  return centers
```

A center has no component larger than half the tree.
Reverse walk order accumulates child sizes.

**Numbering pass.** Shapes are numbered upward, then orbits downward from the virtual root.

```nim
proc countLeafShapes(nodeTotal: int): int =
  if nodeTotal == 1:
    return 0
  let centers = findCenters(nodeTotal)
  let virtualRoot = nodeTotal
  addEdge(virtualRoot, centers[0])
  if centers.len == 2:
    addEdge(virtualRoot, centers[1])
  var rootedParent = newSeq[int](nodeTotal + 1)
  for node in 0 .. nodeTotal:
    rootedParent[node] = -1
  var rootedOrder = newSeq[int]()
  rootedParent[virtualRoot] = -2
  rootedOrder.add virtualRoot
  var orderCursor = 0
  while orderCursor < rootedOrder.len:
    let node = rootedOrder[orderCursor]
    var edgeIndex = nodeHead[node]
    while edgeIndex != -1:
      let neighbor = edgeTarget[edgeIndex]
      if rootedParent[neighbor] == -1:
        rootedParent[neighbor] = node
        rootedOrder.add neighbor
      edgeIndex = edgeLink[edgeIndex]
    orderCursor += 1
  var subtreeIds = newSeq[int](nodeTotal + 1)
  var shapeTable = initTable[string, int]()
  var childIds = newSeq[int]()
  for orderPos in countdown(rootedOrder.len - 1, 0):
    let node = rootedOrder[orderPos]
    childIds.setLen 0
    var edgeIndex = nodeHead[node]
    while edgeIndex != -1:
      let neighbor = edgeTarget[edgeIndex]
      if rootedParent[neighbor] == node:
        childIds.add subtreeIds[neighbor]
      edgeIndex = edgeLink[edgeIndex]
    childIds.sort(compareIds)
    let shapeKey = encodeNumbers(childIds)
    if shapeTable.hasKey(shapeKey):
      subtreeIds[node] = shapeTable[shapeKey]
    else:
      let assignedId = shapeTable.len + 1
      shapeTable[shapeKey] = assignedId
      subtreeIds[node] = assignedId
  var orbitIds = newSeq[int](nodeTotal + 1)
  var pairTable = initTable[string, int]()
  orbitIds[virtualRoot] = 0
  var nextOrbit = 1
  for orderPos in 1 .. rootedOrder.len - 1:
    let node = rootedOrder[orderPos]
    let parentOrbit = orbitIds[rootedParent[node]]
    let shapeId = subtreeIds[node]
    let pairKey = encodePair(parentOrbit, shapeId)
    if pairTable.hasKey(pairKey):
      orbitIds[node] = pairTable[pairKey]
    else:
      orbitIds[node] = nextOrbit
      pairTable[pairKey] = nextOrbit
      nextOrbit += 1
  var leafOrbits = initTable[int, bool]()
  for node in 0 .. nodeTotal - 1:
    var hasChild = false
    var edgeIndex = nodeHead[node]
    while edgeIndex != -1:
      let neighbor = edgeTarget[edgeIndex]
      if rootedParent[neighbor] == node:
        hasChild = true
      edgeIndex = edgeLink[edgeIndex]
    if not hasChild:
      leafOrbits[orbitIds[node]] = true
  return leafOrbits.len
```

Sorted child numbers form one shape number per subtree.
Equal parent orbit and shape pairs share one orbit number.

**Driver.** The driver reads one tree and writes one line.

```nim
let nodeCount = nextInt(inputData, scanPos)
resetEdges(nodeCount)
for edgeIndex in 0 .. nodeCount - 2:
  let firstNode = nextInt(inputData, scanPos)
  let secondNode = nextInt(inputData, scanPos)
  addEdge(firstNode, secondNode)
  addEdge(secondNode, firstNode)
let shapeCount = countLeafShapes(nodeCount)
appendOutput($shapeCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Both directions of every edge are stored.
The buffer flush writes the single answer.

## Complexity

Every phase walks each vertex or edge a constant number of times; sorting dominates at the center.

| phase | time | space |
|---|---|---|
| input read | one pass over edges | one input string |
| center search | two walks over vertices | sizes and parents |
| shape numbering | sorted child lists | shape table |
| orbit numbering | one pair per vertex | orbit table |
| output | one integer | block buffer |

The vertex count sets the space and time bounds.

| measure | Big O |
|---|---|
| time | O(N log N) |
| space | O(N) |

Trying a fresh canonical tree for each leaf costs O(N² log N) on a long path.

Number each subtree once and count distinct leaf orbits.
