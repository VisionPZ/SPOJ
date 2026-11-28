# SPLITS — Split (SPOJ)

<https://www.spoj.com/problems/SPLITS/>

## Problem

Maintain an array of labels that starts uniform, then answer point queries after range splits. A split at position X relabels the same-label run left of X with S1 and the run right of X with S2, while X keeps its label.

Input starts with the array size and the operation count. The next line gives the initial label. Each later line is either SPLIT X S1 S2 or QUERY X.

Output one line per query, holding the label at that position.

| item | bound |
|---|---|
| array size N | 1 to 100000 |
| operations Q | 1 to 100000 |
| label length | 1 to 50 |
| labels | lowercase letters, unique across operations |
| judge limit | 1000 ms, 1536 MB |

Every label occupies one contiguous block, so the array is a set of ordered intervals.

Sample input:

```
6 6
picsel
SPLIT 3 petarv duxserbia
SPLIT 5 sasav nikolaj
QUERY 1
QUERY 3
QUERY 5
QUERY 6
```

Sample output:

```
petarv
picsel
duxserbia
nikolaj
```

## Idea

Keep the array as sorted intervals on a search tree, like a shelf of consecutive book stacks. A split finds one stack, shortens it to the single position X, and places two new stacks on either side. Queries descend the tree to the stack covering the position. Rewriting the whole array would take O(N) per split; the tree touches only three intervals. A balanced treap keeps every search logarithmic.

## Why It Works

1. Each label names one contiguous block because a split gives fresh labels to both sides and keeps the old label at X.
2. Intervals never overlap, and sorting them by start position makes binary search possible.
3. A treap keys nodes by start position and balances by a fixed random priority.
4. Splitting the tree by a key isolates the prefix, the old node, and the suffix.
5. Merging the new nodes back restores one ordered set of intervals.

| term | meaning |
|---|---|
| `treapRoot` | root of the balanced tree of intervals |
| `nodeStart` | first position covered by a node |
| `nodeFinish` | last position covered by a node |
| `nodeLabel` | index of the label string for that node |

The table lists the fields that describe one interval.

A worked example from the generator:

```
initial: [picsel, picsel, picsel, picsel, picsel, picsel]
split 3: [petarv, petarv, picsel, duxserbia, duxserbia, duxserbia]
split 5: [petarv, petarv, picsel, sasav, duxserbia, nikolaj]
queries at 1, 3, 5, 6: petarv, picsel, duxserbia, nikolaj
```

The final row matches the sample output exactly.

## Code

**Input and tree storage.** Tokens are read one at a time, and node arrays are sized from Q.

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

proc isSpaceCharacter(character: char): bool =
  return character == ' ' or character == '\n' or character == '\r' or character == '\t'

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and isSpaceCharacter(data[pos]):
    pos += 1
  var token = ""
  while pos < data.len and not isSpaceCharacter(data[pos]):
    token.add data[pos]
    pos += 1
  return token

var nodeStart: seq[int]
var nodeFinish: seq[int]
var nodeLabel: seq[int]
var nodePriority: seq[int]
var nodeLeft: seq[int]
var nodeRight: seq[int]
var nodeCount = 0
var priorityState: uint64 = 881726454633252552'u64

proc nextPriority(): int =
  priorityState = priorityState xor (priorityState shl 13)
  priorityState = priorityState xor (priorityState shr 7)
  priorityState = priorityState xor (priorityState shl 17)
  return int(priorityState and 0x7fffffff'u64)

proc createNode(startPosition: int, finishPosition: int, labelIndex: int): int =
  nodeCount += 1
  nodeStart[nodeCount] = startPosition
  nodeFinish[nodeCount] = finishPosition
  nodeLabel[nodeCount] = labelIndex
  nodePriority[nodeCount] = nextPriority()
  nodeLeft[nodeCount] = 0
  nodeRight[nodeCount] = 0
  return nodeCount
```

A deterministic random stream supplies treap priorities.
Each split allocates at most three nodes, so the arrays hold 3Q nodes.
Label strings live in one list and nodes store integer indexes.

**Treap operations.** Split by key isolates one interval, and merge restores balance.

```nim
proc splitByKey(root: int, keyValue: int, leftRoot: var int, rightRoot: var int) =
  if root == 0:
    leftRoot = 0
    rightRoot = 0
    return
  if nodeStart[root] < keyValue:
    var innerRight = 0
    splitByKey(nodeRight[root], keyValue, innerRight, rightRoot)
    nodeRight[root] = innerRight
    leftRoot = root
  else:
    var innerLeft = 0
    splitByKey(nodeLeft[root], keyValue, leftRoot, innerLeft)
    nodeLeft[root] = innerLeft
    rightRoot = root

proc mergeTrees(leftTree: int, rightTree: int): int =
  if leftTree == 0:
    return rightTree
  if rightTree == 0:
    return leftTree
  if nodePriority[leftTree] > nodePriority[rightTree]:
    nodeRight[leftTree] = mergeTrees(nodeRight[leftTree], rightTree)
    return leftTree
  nodeLeft[rightTree] = mergeTrees(leftTree, nodeLeft[rightTree])
  return rightTree

proc findNode(root: int, position: int): int =
  var currentNode = root
  while currentNode != 0:
    if position < nodeStart[currentNode]:
      currentNode = nodeLeft[currentNode]
    elif position > nodeFinish[currentNode]:
      currentNode = nodeRight[currentNode]
    else:
      return currentNode
  return 0
```

Every recursive call follows one tree edge.
The merge chooses the root with the higher priority.
A query finds the covering interval with one descent.

**Command loop.** A split rebuilds three intervals; a query emits one label.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let arraySize = nextInt(inputData, scanPos)
let operationCount = nextInt(inputData, scanPos)
var labelStrings = newSeq[string](1)
labelStrings[0] = nextToken(inputData, scanPos)

let nodeCapacity = 3 * operationCount + 5
nodeStart = newSeq[int](nodeCapacity)
nodeFinish = newSeq[int](nodeCapacity)
nodeLabel = newSeq[int](nodeCapacity)
nodePriority = newSeq[int](nodeCapacity)
nodeLeft = newSeq[int](nodeCapacity)
nodeRight = newSeq[int](nodeCapacity)

var treapRoot = createNode(1, arraySize, 0)

for operationIndex in 0 .. operationCount - 1:
  let commandText = nextToken(inputData, scanPos)
  if commandText == "SPLIT":
    let splitPosition = nextInt(inputData, scanPos)
    let leftString = nextToken(inputData, scanPos)
    let rightString = nextToken(inputData, scanPos)
    labelStrings.add leftString
    let leftLabel = labelStrings.len - 1
    labelStrings.add rightString
    let rightLabel = labelStrings.len - 1

    let oldNode = findNode(treapRoot, splitPosition)
    let oldStart = nodeStart[oldNode]
    let oldFinish = nodeFinish[oldNode]
    let oldLabel = nodeLabel[oldNode]

    var beforeTree = 0
    var oldAndAfter = 0
    splitByKey(treapRoot, oldStart, beforeTree, oldAndAfter)
    var oldTree = 0
    var afterTree = 0
    splitByKey(oldAndAfter, oldFinish + 1, oldTree, afterTree)

    var rebuilt = beforeTree
    if oldStart <= splitPosition - 1:
      let leftNode = createNode(oldStart, splitPosition - 1, leftLabel)
      rebuilt = mergeTrees(rebuilt, leftNode)
    let centerNode = createNode(splitPosition, splitPosition, oldLabel)
    rebuilt = mergeTrees(rebuilt, centerNode)
    if splitPosition + 1 <= oldFinish:
      let rightNode = createNode(splitPosition + 1, oldFinish, rightLabel)
      rebuilt = mergeTrees(rebuilt, rightNode)
    rebuilt = mergeTrees(rebuilt, afterTree)
    treapRoot = rebuilt
  else:
    let queryPosition = nextInt(inputData, scanPos)
    let foundNode = findNode(treapRoot, queryPosition)
    appendOutput(labelStrings[nodeLabel[foundNode]])
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The center node keeps the old label at X.
Empty left or right parts create no node.
Output lines collect in one buffer and flush in blocks.

## Complexity

Each operation does a constant number of tree descents.

| phase | time | space |
|---|---|---|
| input read | one pass over the command stream | one input string |
| split | two key splits and four merges | three new nodes |
| query | one tree descent | constant |
| output | one buffered line per query | block buffer |

Treap height stays logarithmic with random priorities.

| measure | Big O |
|---|---|
| time | O(Q log Q) |
| space | O(N + Q) |

Rewriting the array on each split would cost O(NQ), which fails at the largest bounds.
The interval tree replaces that rewrite with a few logarithmic steps.
