# MTREE — Another Tree Problem (SPOJ)

<https://www.spoj.com/problems/MTREE/>

## Problem

A tree has weighted edges, and the weight of a path is the product of its edge weights. We sum that product over every unordered pair of distinct vertices and print the sum modulo 1000000007. Single vertices do not form paths for this sum.

The first input line holds the vertex count N. The next N minus one lines each hold three integers: the two endpoint indices and the edge weight. Vertices are numbered from 1 to N. Print one line containing the total modulo 1000000007.

| item | bound |
|---|---|
| vertices N | 2 to 100000 |
| edge weight W | 0 to 1000 |
| modulus | 1000000007 |
| judge limit | 1000 ms, 1536 MB |

The vertex count drives the choice of an iterative traversal.

Sample input:

```
3
3 2 100
2 1 100
```

Sample output:

```
10200
```

## Idea

Charge every pair to the vertex where its two branches meet, like sorting letters by their common post office. Root the tree once and walk it in reverse postorder. At each vertex, combine the accumulated product sums of its children to count both leaf-to-vertex and cross-branch pairs. A fresh traversal for every pair would cost quadratic time; one bottom-up pass costs linear time.

One pass over the adjacency lists gives the whole total.

## Why It Works

1. Root the tree at vertex 1, which gives every other vertex one parent.
2. For a vertex u, let childTerm equal the edge weight times downSum of that child.
3. downSum of u is one plus the sum of its childTerm values.
4. Pairs with u as their top vertex split into two kinds.
5. A pair of u with a descendant contributes that childTerm.
6. A pair in two different child branches contributes the product of their childTerm values.
7. Adding childTerm values one at a time turns cross-branch pairs into a running product with earlier terms.
8. Taking every total modulo 1000000007 keeps products inside 64-bit integers.

| term | meaning |
|---|---|
| `downSum` | one plus the sum of weighted child contributions at a vertex |
| `childTerm` | edge weight times the child downSum, reduced modulo the modulus |
| `siblingTotal` | sum of child terms processed before the current child |
| `totalWeight` | running answer over all processed vertices |
| `headNode` | first adjacency slot for a vertex |

The running sibling sum converts many pair products into one multiplication per child.

The star sample has three children of weight 5, and the script trace shows the additions:

```
root child 1: childTerm 5, siblingTotal 0, cross pairs 0
root child 2: childTerm 5, siblingTotal 5, cross pairs 25
root child 3: childTerm 5, siblingTotal 10, cross pairs 50
leaf pairs: siblingTotal 15, total 90
```

The trace accounts for three leaf pairs and three center-to-leaf pairs.

Products stay reduced after each operation, so no rounding appears. A child term below the modulus times a sibling total below the modulus stays below 10^18, which fits in a signed 64-bit integer.

## Code

**Input and output helpers.** The reader loads stdin once, and the scanner skips all non-digit bytes.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const modulusValue = 1000000007

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

The three constants fix the buffer size, digit base, and modulus.
The scanner needs no sign branch because all inputs are non-negative.
The buffer writes once per large block, not once per vertex.

**Adjacency build.** Each undirected edge occupies two slots in flat arrays.

```nim
let nodeCount = nextInt(inputData, scanPos)
let edgeCount = nodeCount - 1
var headNode = newSeq[int](nodeCount + 1)
var edgeTarget = newSeq[int](2 * edgeCount)
var edgeWeight = newSeq[int](2 * edgeCount)
var edgeLink = newSeq[int](2 * edgeCount)
for nodeIndex in 1 .. nodeCount:
  headNode[nodeIndex] = -1
var edgeSlot = 0
for edgeNumber in 0 .. edgeCount - 1:
  let firstNode = nextInt(inputData, scanPos)
  let secondNode = nextInt(inputData, scanPos)
  let weightValue = nextInt(inputData, scanPos)
  edgeTarget[edgeSlot] = secondNode
  edgeWeight[edgeSlot] = weightValue
  edgeLink[edgeSlot] = headNode[firstNode]
  headNode[firstNode] = edgeSlot
  edgeSlot += 1
  edgeTarget[edgeSlot] = firstNode
  edgeWeight[edgeSlot] = weightValue
  edgeLink[edgeSlot] = headNode[secondNode]
  headNode[secondNode] = edgeSlot
  edgeSlot += 1
```

Every vertex starts with an empty adjacency head.
Both directions of an edge share the same weight.
Flat arrays avoid per-vertex sequence overhead at 100000 vertices.

**Iterative traversal.** An explicit stack records a root-first visit order.

```nim
var parentNode = newSeq[int](nodeCount + 1)
var traversalOrder = newSeq[int](nodeCount)
var nodeStack = newSeq[int](nodeCount)
var stackTop = 0
nodeStack[stackTop] = 1
stackTop += 1
var orderCount = 0
while stackTop > 0:
  stackTop -= 1
  let currentNode = nodeStack[stackTop]
  traversalOrder[orderCount] = currentNode
  orderCount += 1
  var linkIndex = headNode[currentNode]
  while linkIndex != -1:
    let neighborNode = edgeTarget[linkIndex]
    if neighborNode != parentNode[currentNode]:
      parentNode[neighborNode] = currentNode
      nodeStack[stackTop] = neighborNode
      stackTop += 1
    linkIndex = edgeLink[linkIndex]
```

The stack never holds more than N vertices.
Skipping the parent is enough because the graph is a tree.
The recorded order is reversed later to give postorder.

**Bottom-up accumulation.** Reverse order makes every child ready before its parent.

```nim
var downSum = newSeq[int64](nodeCount + 1)
var totalWeight: int64 = 0
for reverseIndex in 0 .. orderCount - 1:
  let currentNode = traversalOrder[orderCount - 1 - reverseIndex]
  var childTotal: int64 = 0
  var siblingTotal: int64 = 0
  var linkIndex = headNode[currentNode]
  while linkIndex != -1:
    let neighborNode = edgeTarget[linkIndex]
    if parentNode[neighborNode] == currentNode:
      let childTerm = (int64(edgeWeight[linkIndex]) * downSum[neighborNode]) mod modulusValue
      totalWeight = (totalWeight + childTerm * siblingTotal) mod modulusValue
      siblingTotal = (siblingTotal + childTerm) mod modulusValue
      childTotal = (childTotal + childTerm) mod modulusValue
    linkIndex = edgeLink[linkIndex]
  downSum[currentNode] = childTotal + 1
  if downSum[currentNode] >= modulusValue:
    downSum[currentNode] = downSum[currentNode] - modulusValue
  totalWeight = (totalWeight + siblingTotal) mod modulusValue

appendOutput($totalWeight)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Each child adds cross-branch pairs before joining the sibling total.
The final sibling total adds all center-to-descendant pairs.
Every arithmetic intermediate stays within signed 64-bit range.

## Complexity

The traversal and the accumulation each scan every edge a constant number of times.

| phase | time | space |
|---|---|---|
| input read | one pass over edge triples | one input string |
| adjacency build | two slots per edge | arrays of size 2N |
| traversal and accumulation | one visit per vertex and edge | parent and order arrays |
| output | one line | block buffer |

Flat adjacency arrays keep the traversal cost predictable.

| measure | Big O |
|---|---|
| time | O(N) |
| space | O(N) |

Testing every vertex pair would cost O(N^2) path walks.
