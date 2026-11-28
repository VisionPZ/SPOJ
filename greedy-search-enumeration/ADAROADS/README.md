# ADAROADS — Ada and Roads (SPOJ)

<https://www.spoj.com/problems/ADAROADS/>

## Problem

Roads arrive one at a time between two vegetables. After each arrival, keep a minimum-cost forest with no cycles and report its total maintenance cost. The arriving road is given XORed with the previous answer, so each query depends on the last total.

Input starts with N and M, then M lines with encoded a, b and c. Decode them with `lastAnswer`, which starts at zero. Output one line per road: the forest total after that road is processed.

| item | bound |
|---|---|
| vegetables N | 1 to 200000 |
| roads M | 0 to 500000 |
| maintenance cost c | 0 to 1000000000 |
| judge limit | 3000 ms, 1536 MB |

The online XOR dependency rules out offline reordering, so each road needs a real-time forest update.

Verbatim sample input:

```
5 5
4 3 6
6 7 4
8 9 10
8 12 9
8 10 11
```

Verbatim sample output:

```
6
8
8
9
5
```

## Idea

Think of the forest as a set of strings tied into knots: a new road either ties two loose pieces or replaces the most expensive string already on the path. A link-cut tree maintains those strings under ties and cuts, like a knot that can be rerouted without untying everything. Each road becomes a node with its cost, linked to its two endpoints.

A path query finds the heaviest road in O(log N) amortized time, so each insertion costs O(log N). Rebuilding a spanning forest by sorting all roads from scratch costs O(M^2 log M), which cannot handle 5e5 roads. Takeaway: keep the forest dynamic, and query the path before accepting a road.

## Why It Works

1. A minimum spanning forest has exactly one path between any two vertices in the same component.
2. If a new road joins two components, the cycle rule makes it part of every optimal forest, so add its cost.
3. If the endpoints are already connected, the new road helps only when it is lighter than the heaviest road on that path.
4. Replacing the heaviest road removes the only edge that makes the new road useful, so the result stays minimum.
5. A link-cut tree exposes any path as one splay tree, whose aggregated maximum gives the heaviest road and its node id.
6. Vertex ids start at one because zero is the link-cut tree's null sentinel; `vertexOffset` performs that shift.

The main terms and formulas:

| term | meaning |
|---|---|
| `nodeValue` | cost stored on a node, minus one for a vegetable node |
| `nodeMaxValue` | heaviest cost in a splay subtree |
| `nodeMaxIndex` | node holding that heaviest cost |
| `edgeLeftEndpoint` | first vegetable linked by an edge node |
| `edgeRightEndpoint` | second vegetable linked by an edge node |
| `lastAnswer` | previous forest total, used to undo the XOR encoding |

Vegetable nodes carry cost minus one, so any real road wins a tie against them.

A script-generated trace for the sample case:

```
road 1: 4-3 cost 6, new component, total 6
road 2: 0-1 cost 2, new component, total 8
road 3: 0-1 cost 2, heaviest on path is 2, keep 8
road 4: 0-4 cost 1, new component, total 9
road 5: 1-3 cost 2, path 1-0(2),0-4(1),4-3(6), replace 6 by 2, total 5
```

The trace matches all five sample output lines.

All totals fit in int64, since at most N - 1 roads of cost up to 1e9 are kept.

## Code

**Input and scanner.** One read loads stdin and a digit scanner parses the encoded integers.

```nim
const flushBlockBytes = 1 shl 17
const vertexOffset = 1

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

All encoded values are nonnegative, so the scanner needs no sign branch.
Output uses a single buffer, defined next.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

One final write flushes any remaining bytes.

**Tree storage.** Parallel arrays hold the splay children, parents, reversal flags and cost maxima.

```nim
var nodeCount = 0
var childLeft = newSeq[int](0)
var childRight = newSeq[int](0)
var parentNode = newSeq[int](0)
var reversedFlag = newSeq[bool](0)
var nodeValue = newSeq[int64](0)
var nodeMaxValue = newSeq[int64](0)
var nodeMaxIndex = newSeq[int](0)
var edgeLeftEndpoint = newSeq[int](0)
var edgeRightEndpoint = newSeq[int](0)
var splayStack = newSeq[int](0)
var splayTop = 0

proc pushUp(node: int) =
  var bestValue = nodeValue[node]
  var bestIndex = node
  let leftChild = childLeft[node]
  if leftChild != 0 and nodeMaxValue[leftChild] > bestValue:
    bestValue = nodeMaxValue[leftChild]
    bestIndex = nodeMaxIndex[leftChild]
  let rightChild = childRight[node]
  if rightChild != 0 and nodeMaxValue[rightChild] > bestValue:
    bestValue = nodeMaxValue[rightChild]
    bestIndex = nodeMaxIndex[rightChild]
  nodeMaxValue[node] = bestValue
  nodeMaxIndex[node] = bestIndex
```

`pushUp` refreshes the aggregate after every structural change.
The maximum carries the node id needed for a later cut.

**Lazy reversal and rotations.** Reversal marks flip a whole splay subtree in constant time.

```nim
proc reverseNode(node: int) =
  if node == 0:
    return
  let oldLeft = childLeft[node]
  childLeft[node] = childRight[node]
  childRight[node] = oldLeft
  reversedFlag[node] = not reversedFlag[node]

proc pushDown(node: int) =
  if reversedFlag[node]:
    reverseNode(childLeft[node])
    reverseNode(childRight[node])
    reversedFlag[node] = false

proc isSplayRoot(node: int): bool =
  let parent = parentNode[node]
  return parent == 0 or (childLeft[parent] != node and childRight[parent] != node)

proc rotateNode(node: int) =
  let parent = parentNode[node]
  let grandparent = parentNode[parent]
  if childLeft[parent] == node:
    let middle = childRight[node]
    childLeft[parent] = middle
    if middle != 0:
      parentNode[middle] = parent
    childRight[node] = parent
  else:
    let middle = childLeft[node]
    childRight[parent] = middle
    if middle != 0:
      parentNode[middle] = parent
    childLeft[node] = parent
  parentNode[parent] = node
  parentNode[node] = grandparent
  if grandparent != 0:
    if childLeft[grandparent] == parent:
      childLeft[grandparent] = node
    elif childRight[grandparent] == parent:
      childRight[grandparent] = node
  pushUp(parent)
  pushUp(node)
```

`isSplayRoot` treats virtual parents as tree roots.
A rotation preserves in-order order and updates both aggregates.

**Splaying and access.** A stack of ancestors pushes lazy flags down before each rotation.

```nim
proc splayNode(node: int) =
  splayTop = 0
  var current = node
  splayStack[splayTop] = current
  splayTop += 1
  while not isSplayRoot(current):
    current = parentNode[current]
    splayStack[splayTop] = current
    splayTop += 1
  while splayTop > 0:
    splayTop -= 1
    pushDown(splayStack[splayTop])
  while not isSplayRoot(node):
    current = parentNode[node]
    if not isSplayRoot(current):
      if (childLeft[current] == node) == (childLeft[parentNode[current]] == current):
        rotateNode(current)
      else:
        rotateNode(node)
    rotateNode(node)

proc accessNode(node: int) =
  var lastNode = 0
  var current = node
  while current != 0:
    splayNode(current)
    childRight[current] = lastNode
    pushUp(current)
    lastNode = current
    current = parentNode[current]
```

The zig-zig test compares which side of the parent both nodes occupy.
`accessNode` makes the root-to-node path preferred.

**Path primitives.** Rooting, searching, splitting, linking and cutting build on access.

```nim
proc makeRoot(node: int) =
  accessNode(node)
  splayNode(node)
  reverseNode(node)

proc findRoot(node: int): int =
  accessNode(node)
  splayNode(node)
  var current = node
  pushDown(current)
  while childLeft[current] != 0:
    current = childLeft[current]
    pushDown(current)
  splayNode(current)
  return current

proc splitPath(firstNode: int, secondNode: int) =
  makeRoot(firstNode)
  accessNode(secondNode)
  splayNode(secondNode)

proc linkNodes(firstNode: int, secondNode: int) =
  makeRoot(firstNode)
  if findRoot(secondNode) != firstNode:
    parentNode[firstNode] = secondNode

proc cutNodes(firstNode: int, secondNode: int) =
  makeRoot(firstNode)
  accessNode(secondNode)
  splayNode(secondNode)
  if childLeft[secondNode] == firstNode and childRight[firstNode] == 0:
    childLeft[secondNode] = 0
    parentNode[firstNode] = 0
    pushUp(secondNode)
```

`splitPath` leaves the whole path in the splay tree rooted at the second node.
`findRoot` pushes lazy flags down while descending to the leftmost node.

**Driver.** Each road is decoded, then kept or swapped by the cycle rule.

```nim
let vertexCount = nextInt(inputData, scanPos)
let roadCount = nextInt(inputData, scanPos)
nodeCount = vertexCount + roadCount + 2
childLeft = newSeq[int](nodeCount)
childRight = newSeq[int](nodeCount)
parentNode = newSeq[int](nodeCount)
reversedFlag = newSeq[bool](nodeCount)
nodeValue = newSeq[int64](nodeCount)
nodeMaxValue = newSeq[int64](nodeCount)
nodeMaxIndex = newSeq[int](nodeCount)
edgeLeftEndpoint = newSeq[int](nodeCount)
edgeRightEndpoint = newSeq[int](nodeCount)
splayStack = newSeq[int](nodeCount)
for node in 0 .. nodeCount - 1:
  nodeValue[node] = -1
  nodeMaxValue[node] = -1
  nodeMaxIndex[node] = node
```

One node per vegetable plus one per road gives room for every possible swap.
The minus-one value keeps vegetable nodes out of maximum comparisons.

```nim
var lastAnswer: int64 = 0
var totalCost: int64 = 0
for roadIndex in 0 .. roadCount - 1:
  let encodedA = nextInt(inputData, scanPos)
  let encodedB = nextInt(inputData, scanPos)
  let encodedC = nextInt(inputData, scanPos)
  let realA = int64(encodedA) xor lastAnswer
  let realB = int64(encodedB) xor lastAnswer
  let realC = int64(encodedC) xor lastAnswer
  let edgeNode = vertexCount + roadIndex + vertexOffset
  let nodeA = int(realA) + vertexOffset
  let nodeB = int(realB) + vertexOffset
  childLeft[edgeNode] = 0
  childRight[edgeNode] = 0
  parentNode[edgeNode] = 0
  reversedFlag[edgeNode] = false
  nodeValue[edgeNode] = realC
  nodeMaxValue[edgeNode] = realC
  nodeMaxIndex[edgeNode] = edgeNode
  edgeLeftEndpoint[edgeNode] = nodeA
  edgeRightEndpoint[edgeNode] = nodeB
  if findRoot(nodeA) != findRoot(nodeB):
    linkNodes(edgeNode, nodeA)
    linkNodes(edgeNode, nodeB)
    totalCost = totalCost + realC
  else:
    splitPath(nodeA, nodeB)
    let heavyNode = nodeMaxIndex[nodeB]
    let removedCost = nodeMaxValue[nodeB]
    if removedCost > realC:
      cutNodes(heavyNode, edgeLeftEndpoint[heavyNode])
      cutNodes(heavyNode, edgeRightEndpoint[heavyNode])
      linkNodes(edgeNode, nodeA)
      linkNodes(edgeNode, nodeB)
      totalCost = totalCost + realC - removedCost
  lastAnswer = totalCost
  appendOutput($totalCost)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

A fresh edge node is prepared for each road, whether or not it is kept.
The XOR is undone before any graph operation, and the new total feeds the next road.

## Complexity

Each road needs a constant number of link-cut tree operations.

| phase | time | space |
|---|---|---|
| input read | one pass over M triples | one input string |
| tree setup | allocate arrays once | O(N + M) nodes |
| per road | O(log(N + M)) amortized | splay ancestor stack |
| output | one buffered line per road | block buffer |

Path maximum and connectivity dominate the per-road cost.

| measure | Big O |
|---|---|
| total time | O(M log(N + M)) amortized |
| space | O(N + M) |

Recomputing a spanning forest with Kruskal after every road costs O(M^2 log M), which cannot meet the limit. Takeaway: maintain the forest online with path maxima.
