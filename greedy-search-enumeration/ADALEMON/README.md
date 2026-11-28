# ADALEMON — Ada and Lemon 1 (SPOJ)
<https://www.spoj.com/problems/ADALEMON/>

## Problem

Remove one leaf from an unlabelled tree and count how many different tree shapes can result. A leaf is a vertex of degree one. Two shapes are equal when some relabelling of vertices maps one onto the other. A tree with one vertex holds no lemon and gives answer zero.

The first input line gives `caseCount`. Each case gives `nodeCount`, then `nodeCount − 1` edges with endpoints from zero to `nodeCount − 1`. Print one answer per case.

| item | bound |
|---|---|
| cases | 1 to 100 |
| nodes per case | 1 to 3000, total at most 3000 |
| edge endpoints | 0 to `nodeCount − 1` |
| judge limit | 3000 ms, 1536 MB |

The input tree is always connected and acyclic.

Sample input:

```
5
4
0 1
0 2
0 3
4
0 1
1 3
3 2
6
0 2
1 2
2 3
3 5
3 4
7
1 2
0 1
2 3
2 4
3 5
6 5
9
0 1
1 2
2 3
3 4
4 5
2 6
3 7
4 8
```

Sample output:

```
1
1
1
3
4
```

## Idea

Two leaves leave the same tree exactly when a symmetry of the original tree can swap them, like matching folds on a paper snowflake. Root the tree at its center and give every rooted subtree a shape number by sorting child numbers. Then give every vertex an orbit number from the pair of its parent orbit and its own shape number. Leaves with equal orbit numbers produce equal trees, so count those numbers. Rebuilding a canonical tree for every leaf costs quadratic time, while this pass touches each vertex once. Root once, number once, and count leaf orbits.

## Why It Works

1. Removing a leaf deletes one degree-one vertex and keeps the rest of the tree.
2. For trees, two leaves give isomorphic remainders exactly when an automorphism maps one leaf to the other.
3. Every automorphism fixes the center or swaps the two central vertices, so a virtual root above the center captures all symmetries.
4. Sorting the child shape numbers gives a canonical number for each rooted subtree.
5. A vertex orbit follows from the parent orbit and the subtree shape; equal pairs give equal orbits.
6. Counting distinct leaf orbit numbers gives the answer.

These names carry the main values.

| term | meaning |
|---|---|
| `findCenters` | routine that locates one or two central vertices |
| `virtualRoot` | extra root above the center or above both centers |
| `subtreeIds` | canonical shape number of each rooted subtree |
| `orbitIds` | symmetry class number of each vertex |
| `leafOrbits` | set of orbit numbers held by leaves |

The virtual root lets one rooting cover both center cases.

A script-generated trace uses the seven-node sample tree with edges 1-2, 0-1, 2-3, 2-4, 3-5, 6-5:

| leaf | shape number | orbit number |
|---|---|---|
| 0 | 1 | 5 |
| 4 | 1 | 4 |
| 6 | 1 | 7 |

All three leaves have shape number 1, yet their parent orbits differ. Three orbit numbers remain, so three shapes survive.

Shape numbers start at one inside each case, and the sentinel −1 marks an unset parent. No floating point appears.

## Code

**Reader, comparators, and keys.** The parser reads digit tokens, and keys pack integers into bytes.

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

Each shape key holds four bytes per child number.
Each orbit key holds a parent orbit and one shape number.

**Adjacency storage.** Arrays hold directed edge slots for every case.

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

Two slots are stored per undirected edge.
The extra slots hold the virtual root edges.

**Center search.** A walk and subtree sizes locate the one or two centers.

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
Reverse walk order turns child sizes into subtree sizes.

**Shape and orbit numbering.** The main routine numbers shapes upward and orbits downward.

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

Sorted child numbers form one canonical shape per subtree.
Equal parent orbit and shape pairs merge two vertices into one orbit.

**Case loop.** Each case builds its tree and writes one answer.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
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

Each case reuses the same arrays with fresh sizes.
The final flush writes all answers.

## Complexity

Reading and numbering touch each vertex and edge once; sorting dominates at high-degree vertices.

| phase | time | space |
|---|---|---|
| input read | one pass over edges | one input string |
| center search | two walks over vertices | sizes and parents |
| shape numbering | sorted child lists | shape table |
| orbit numbering | one pair per vertex | orbit table |
| output | one line per case | block buffer |

The total vertex count bounds every phase across all cases.

| measure | Big O |
|---|---|
| time | O(N log N) per case |
| space | O(N) |

Rebuilding a canonical tree for every leaf costs O(N² log N) on a long path.

Number each subtree once and read leaf orbits directly.
