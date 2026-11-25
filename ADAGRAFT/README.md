# ADAGRAFT — Ada and Graft (SPOJ)

<https://www.spoj.com/problems/ADAGRAFT/>

## Problem

A rooted tree carries one fruit kind on each node. The value of a node is the number of different kinds inside its subtree, and the value of the tree is the product of all node values modulo 1000000007.

Input gives the node count, then one parent per node except the root, then one fruit kind per node. Output the tree value modulo 1000000007.

| item | bound |
|---|---|
| nodes N | 1 to 400000 |
| parent of node i | 0 ≤ p[i] < i |
| fruit kind | 0 to 1000000000 |
| judge limit | 3000 ms, 1536 MB |

The node count rules out building a fruit set for every subtree.

Sample input:

```
5
0 0 1 1
1 1 1 2 2
```

The sample has five nodes, with nodes 1 and 2 under the root.

Sample output:

```
4
```

Only the root and node 1 have two distinct kinds; the other nodes have one.

## Idea

A subtree becomes a single slice of a line when the tree is walked in preorder, like folding a family tree into one shelf. Count distinct kinds in every slice with a last-occurrence sweep and a Fenwick tree. An offline sweep keeps one marker per kind: move it from its previous position to its current one. Each position costs one hash lookup and two logarithmic updates. Rebuilding a set for each subtree would cost far more on a chain of 400000 nodes. Flatten first, then sweep.

## Why It Works

1. In a preorder walk, each subtree occupies one contiguous block of positions.
2. A Fenwick tree holds a one at the latest position of each kind and zero at older positions.
3. The sum over a subtree block then equals the number of distinct kinds in that block.
4. Several nodes can end at the same position, so each end position holds a chain of pending nodes.
5. Multiplying all distinct counts modulo 1000000007 yields the required value.

| term | meaning |
|---|---|
| `entryPositions` | first preorder position of each subtree |
| `firstNodeAtExit` | chain head for nodes ending at a position |
| `bitTree` | Fenwick tree of latest fruit occurrences |
| `hashLastPositions` | latest preorder position for each fruit kind |

The four structures link a subtree interval to its distinct kind count.

A script trace of the sample with euler order 0, 2, 4, 3, 1:

```
node  subtree kinds  distinct
0     {1, 2}         2
1     {1, 2}         2
2     {1}            1
3     {2}            1
4     {2}            1
```

The product 2 * 2 * 1 * 1 * 1 equals 4.

## Code

**Input and tree walk.** Parents become forward-star edges and an iterative walk records entry order.

```nim
const flushBlockBytes = 1 shl 17
const moduloBase = 1000000007'i64
const hashMultiplier = 2654435761'i64

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

let treeSize = nextInt(inputData, scanPos)
var fruitKinds = newSeq[int64](treeSize)
var childHeads = newSeq[int32](treeSize)
for nodeIndex in 0 .. treeSize - 1:
  childHeads[nodeIndex] = -1
var nextEdges = newSeq[int32](treeSize - 1)
var edgeTargets = newSeq[int32](treeSize - 1)
var edgeIndex = 0
for childIndex in 1 .. treeSize - 1:
  let parentIndex = nextInt(inputData, scanPos)
  edgeTargets[edgeIndex] = int32(childIndex)
  nextEdges[edgeIndex] = childHeads[parentIndex]
  childHeads[parentIndex] = int32(edgeIndex)
  edgeIndex += 1
for nodeIndex in 0 .. treeSize - 1:
  fruitKinds[nodeIndex] = int64(nextInt(inputData, scanPos))

var entryPositions = newSeq[int32](treeSize)
var eulerNodes = newSeq[int32](treeSize)
var firstNodeAtExit = newSeq[int32](treeSize)
var nextNodeAtExit = newSeq[int32](treeSize)
for nodeIndex in 0 .. treeSize - 1:
  firstNodeAtExit[nodeIndex] = -1
  nextNodeAtExit[nodeIndex] = -1
var stackNodes = newSeq[int32](treeSize)
var stackEdges = newSeq[int32](treeSize)
var stackTop = 0
stackNodes[0] = 0
stackEdges[0] = childHeads[0]
entryPositions[0] = 0
eulerNodes[0] = 0
var eulerCount = 1
while stackTop >= 0:
  let currentEdge = stackEdges[stackTop]
  if currentEdge != -1:
    stackEdges[stackTop] = nextEdges[currentEdge]
    let childNode = edgeTargets[currentEdge]
    entryPositions[childNode] = int32(eulerCount)
    eulerNodes[eulerCount] = childNode
    eulerCount += 1
    stackTop += 1
    stackNodes[stackTop] = childNode
    stackEdges[stackTop] = childHeads[childNode]
  else:
    let finishedNode = stackNodes[stackTop]
    nextNodeAtExit[finishedNode] = firstNodeAtExit[eulerCount - 1]
    firstNodeAtExit[eulerCount - 1] = finishedNode
    stackTop -= 1
```

An explicit stack avoids deep recursion on a chain tree.
Each edge is inserted once at the head of its parent list.
Several nodes may share one end position, so they form a chain.

**Fenwick helpers.** Two small procedures maintain latest occurrences.

```nim
var bitTree = newSeq[int32](treeSize + 1)

proc bitAdd(position: int, delta: int32) =
  var index = position + 1
  while index <= treeSize:
    bitTree[index] = bitTree[index] + delta
    index += index and -index

proc bitQuery(count: int): int32 =
  result = 0
  var index = count
  while index > 0:
    result = result + bitTree[index]
    index -= index and -index
```

Adding a delta clears an older marker or sets a newer one.
A prefix query counts every marker up to a position.
Both loops run in logarithmic time.

**Offline sweep.** One pass moves fruit markers and multiplies finished subtree counts.

```nim
var hashTableSize = 1
while hashTableSize < treeSize * 2:
  hashTableSize = hashTableSize shl 1
let hashMask = hashTableSize - 1
var hashKeys = newSeq[int64](hashTableSize)
var hashLastPositions = newSeq[int32](hashTableSize)
for slotIndex in 0 .. hashTableSize - 1:
  hashKeys[slotIndex] = -1'i64

var answerValue = 1'i64
for position in 0 .. treeSize - 1:
  let currentNode = eulerNodes[position]
  let fruitKind = fruitKinds[currentNode]
  var hashIndex = int((fruitKind * hashMultiplier) and int64(hashMask))
  while hashKeys[hashIndex] != -1'i64 and hashKeys[hashIndex] != fruitKind:
    hashIndex = (hashIndex + 1) and hashMask
  if hashKeys[hashIndex] == fruitKind:
    bitAdd(int(hashLastPositions[hashIndex]), -1)
  else:
    hashKeys[hashIndex] = fruitKind
  bitAdd(position, 1)
  hashLastPositions[hashIndex] = int32(position)
  var finishedNode = firstNodeAtExit[position]
  while finishedNode >= 0:
    let distinctKinds = bitQuery(position + 1) - bitQuery(int(entryPositions[finishedNode]))
    answerValue = answerValue * int64(distinctKinds) mod moduloBase
    finishedNode = nextNodeAtExit[finishedNode]

appendOutput($answerValue)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The hash table maps a fruit kind up to 1e9 to one slot.
A repeated kind clears its old slot before setting the new one.
Every finished node contributes one factor to the final product.

## Complexity

The walk and the sweep each visit every node once.

| phase | time | space |
|---|---|---|
| input read | one token scan | input string |
| tree walk | one pass over nodes and edges | edge and position arrays |
| sweep | one hash lookup and two Fenwick updates per node | Fenwick array and hash table |
| output | one buffered write | block buffer |

The hash table holds about twice as many slots as nodes.

| measure | Big O |
|---|---|
| time | O(N log N) expected |
| space | O(N) |

Building a fruit set for each subtree would cost O(N^2) on a chain. The offline sweep keeps each node to logarithmic work.
