<https://www.spoj.com/problems/COT5/>

## Problem

Maintain a max-treap ordered by key and heap-ordered by weight; answer the edge distance between the nodes with two queried keys after insertions and deletions. Keys and weights never repeat, and deletions always name a node that exists.

| item | bound |
|---|---|
| operations N | 1 to 200000 |
| keys and weights | 1 to 2147483647 |
| op 0 | insert key and weight |
| op 1 | delete key |
| op 2 | print distance between two keys |
| judge limit | 1220 ms, 1536 MB |

Treap shape follows the given weights, so the parent of a node changes during rotations.

Sample input:

```
12
0 4 17535
0 10 38964
0 2 21626
0 1 61321
2 1 10
2 10 4
1 10
1 1
0 8 42634
2 8 4
2 8 2
2 4 2
```

Sample output:

```
1
2
2
1
1
```

## Idea

Think of two climbers on a tree who meet after walking up to a common branch. Store a parent link on every node, walk each query node up to the root, then move the deeper climber up until the levels match. Once the levels match, both climbers move together until they meet.

Rotations maintain the treap and repair each affected parent link.

The distance is the sum of the two root depths minus twice the meeting depth.

## Why It Works

1. A max-treap keeps the binary search order by key and the heap order by weight.
2. Insertion places a node by key, then rotates it up while its weight exceeds its parent's weight.
3. Deletion rotates the target down until it is a leaf, then unlinks it.
4. Every rotation rewrites the parent link of each moved node.
5. Walking parents gives a node's depth; matching depths finds the lowest common ancestor.

| term | meaning |
|---|---|
| `nodeWeights` | heap priority of each node |
| `parentNode` | parent index of each node, zero at the root |
| `rootNode` | index of the current root |
| `depthOne` | depth of the first climber after alignment |

After the four sample insertions, the root is key 1. Key 10 is its right child. Key 2 is the left child of 10, and key 4 is the right child of 2.

The query 10 to 4 therefore travels 10 to 2 to 4, giving distance 2.

## Code

**Input and scanning.** The reader loads all operations before the treap starts.

```nim
const flushBlockBytes = 1 shl 17
const maxTreapNodes = 200005

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

Index zero acts as the null node.
The node arrays are sized for every possible insertion.

**Rotations.** Each rotation moves a child above its parent and fixes three links.

```nim
var nodeKeys = newSeq[int](maxTreapNodes)
var nodeWeights = newSeq[int](maxTreapNodes)
var leftChild = newSeq[int](maxTreapNodes)
var rightChild = newSeq[int](maxTreapNodes)
var parentNode = newSeq[int](maxTreapNodes)
var rootNode = 0
var nodeCount = 0

proc rotateLeft(lowerNode: int) =
  let upperNode = rightChild[lowerNode]
  rightChild[lowerNode] = leftChild[upperNode]
  if leftChild[upperNode] != 0:
    parentNode[leftChild[upperNode]] = lowerNode
  parentNode[upperNode] = parentNode[lowerNode]
  if parentNode[lowerNode] == 0:
    rootNode = upperNode
  elif leftChild[parentNode[lowerNode]] == lowerNode:
    leftChild[parentNode[lowerNode]] = upperNode
  else:
    rightChild[parentNode[lowerNode]] = upperNode
  leftChild[upperNode] = lowerNode
  parentNode[lowerNode] = upperNode

proc rotateRight(lowerNode: int) =
  let upperNode = leftChild[lowerNode]
  leftChild[lowerNode] = rightChild[upperNode]
  if rightChild[upperNode] != 0:
    parentNode[rightChild[upperNode]] = lowerNode
  parentNode[upperNode] = parentNode[lowerNode]
  if parentNode[lowerNode] == 0:
    rootNode = upperNode
  elif leftChild[parentNode[lowerNode]] == lowerNode:
    leftChild[parentNode[lowerNode]] = upperNode
  else:
    rightChild[parentNode[lowerNode]] = upperNode
  rightChild[upperNode] = lowerNode
  parentNode[lowerNode] = upperNode
```

A root rotation also replaces `rootNode`.
The former parent becomes a child of the promoted node.

**Insert and delete.** Insert rotates upward; delete rotates the target down to a leaf.

```nim
proc findNode(targetKey: int): int =
  var walkNode = rootNode
  while walkNode != 0:
    if targetKey == nodeKeys[walkNode]:
      return walkNode
    elif targetKey < nodeKeys[walkNode]:
      walkNode = leftChild[walkNode]
    else:
      walkNode = rightChild[walkNode]
  return 0

proc insertNode(newKey: int, newWeight: int) =
  nodeCount += 1
  nodeKeys[nodeCount] = newKey
  nodeWeights[nodeCount] = newWeight
  leftChild[nodeCount] = 0
  rightChild[nodeCount] = 0
  parentNode[nodeCount] = 0
  if rootNode == 0:
    rootNode = nodeCount
    return
  var walkNode = rootNode
  while true:
    if newKey < nodeKeys[walkNode]:
      if leftChild[walkNode] == 0:
        leftChild[walkNode] = nodeCount
        parentNode[nodeCount] = walkNode
        break
      walkNode = leftChild[walkNode]
    else:
      if rightChild[walkNode] == 0:
        rightChild[walkNode] = nodeCount
        parentNode[nodeCount] = walkNode
        break
      walkNode = rightChild[walkNode]
  while parentNode[nodeCount] != 0 and nodeWeights[nodeCount] > nodeWeights[parentNode[nodeCount]]:
    let upperNode = parentNode[nodeCount]
    if leftChild[upperNode] == nodeCount:
      rotateRight(upperNode)
    else:
      rotateLeft(upperNode)

proc deleteKey(targetKey: int) =
  let targetNode = findNode(targetKey)
  while leftChild[targetNode] != 0 or rightChild[targetNode] != 0:
    if rightChild[targetNode] == 0 or
       (leftChild[targetNode] != 0 and nodeWeights[leftChild[targetNode]] > nodeWeights[rightChild[targetNode]]):
      rotateRight(targetNode)
    else:
      rotateLeft(targetNode)
  let upperNode = parentNode[targetNode]
  if upperNode == 0:
    rootNode = 0
  elif leftChild[upperNode] == targetNode:
    leftChild[upperNode] = 0
  else:
    rightChild[upperNode] = 0
  parentNode[targetNode] = -1
```

The heavier child is promoted on each deletion step.
Marking the parent as -1 prevents accidental reuse.

**Distance query.** Both nodes climb to the root, then climb in lockstep to their meeting point.

```nim
proc treeDistance(firstKey: int, secondKey: int): int =
  let firstNode = findNode(firstKey)
  let secondNode = findNode(secondKey)
  var firstDepth = 0
  var climbNode = firstNode
  while parentNode[climbNode] != 0:
    firstDepth += 1
    climbNode = parentNode[climbNode]
  var secondDepth = 0
  climbNode = secondNode
  while parentNode[climbNode] != 0:
    secondDepth += 1
    climbNode = parentNode[climbNode]
  var nodeOne = firstNode
  var nodeTwo = secondNode
  var depthOne = firstDepth
  var depthTwo = secondDepth
  while depthOne > depthTwo:
    nodeOne = parentNode[nodeOne]
    depthOne -= 1
  while depthTwo > depthOne:
    nodeTwo = parentNode[nodeTwo]
    depthTwo -= 1
  while nodeOne != nodeTwo:
    nodeOne = parentNode[nodeOne]
    nodeTwo = parentNode[nodeTwo]
  return firstDepth + secondDepth - 2 * depthOne

let operationCount = nextInt(inputData, scanPos)
for operationIndex in 0 .. operationCount - 1:
  let operationCode = nextInt(inputData, scanPos)
  if operationCode == 0:
    let insertedKey = nextInt(inputData, scanPos)
    let insertedWeight = nextInt(inputData, scanPos)
    insertNode(insertedKey, insertedWeight)
  elif operationCode == 1:
    let deletedKey = nextInt(inputData, scanPos)
    deleteKey(deletedKey)
  else:
    let firstKey = nextInt(inputData, scanPos)
    let secondKey = nextInt(inputData, scanPos)
    appendOutput($treeDistance(firstKey, secondKey))
    outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Equal depths mean the two climbers can meet at the same level.
The last line flushes all query answers together.

## Complexity

Each operation follows one path in the treap.

| phase | time | space |
|---|---|---|
| input read | one pass over operations | one input string |
| insert or delete | one search plus rotations | five node arrays |
| distance query | two climbs to the root | one output buffer |

| measure | Big O |
|---|---|
| time per operation | O(h) for treap height h |
| space | O(number of inserted nodes) |

A full rebuild per query would cost linear time instead of path length.

The parent links give the meeting depth without any extra tree structure.
