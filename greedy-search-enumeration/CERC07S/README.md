# CERC07S — Robotic Sort (SPOJ)

<https://www.spoj.com/problems/CERC07S/>

## Problem

Print the positions a robot must use to sort samples by repeatedly reversing one interval. At step i, find the i-th smallest remaining sample and report its current position before reversing positions i through that position.

Input holds scenarios. Each starts with sample count N, then N positive heights. A line with `0` ends the input. Equal heights keep their original order. Output holds one line per scenario with N space-separated positions.

| item | bound |
|---|---|
| samples N | 1 to 100000 |
| heights | positive integers |
| scenarios | until `0` |
| judge limit | 1000 ms, 1536 MB |

The interval starts at i, so early positions stay fixed after each step.

Sample input:

```
6
3 4 5 1 6 2
4
3 3 2 1
0
```

Sample output:

```
4 6 4 5 6 6
4 2 4 4
```

## Idea

Keep the samples in a splay tree and treat each node as a permanent handle, like a labeled book on a shifting shelf. The tree's in-order traversal is the current row; subtree sizes give ranks. Sort (height, original index) pairs first. For each pair, splay its node to the root so its left subtree size gives the position. Then splay the interval boundaries and flip one lazy flag to reverse that interval. Copying the row each step costs O(N^2); splay work is logarithmic on average.

## Why It Works

1. Sorting by (height, original index) fixes the order and preserves ties.
2. A splay tree's in-order traversal is the current sample row.
3. Splaying a node to the root makes left subtree size plus one its rank.
4. Positions 1 through i-1 already hold sorted samples, so the rank is at least i.
5. Splaying rank i-1 and rank P+1 isolates positions i through P as one subtree.
6. A lazy flip reverses that subtree without touching any sample data.

| term | meaning |
|---|---|
| `splayRoot` | root node of the current sequence tree |
| `nodeSize` | subtree size, used to read ranks |
| `nodeReversed` | lazy flag that postpones a subtree reversal |
| `sortedKeys` | heights packed with original indices, in sorted order |
| `positionValue` | rank of the current target before reversal |

The table maps each operation to the structure that supports it.

A script trace of the first sample:

```
sorted targets = 4 6 1 2 3 5
step 1 target 4 at position 4 -> reverse 1..4
step 2 target 6 at position 6 -> reverse 2..6
step 3 target 1 at position 4 -> reverse 3..4
step 4 target 2 at position 5 -> reverse 4..5
step 5 target 3 at position 6 -> reverse 5..6
step 6 target 5 at position 6 -> reverse 6..6
output = 4 6 4 5 6 6
```

The trace matches the sample answer line by line.

## Code

**Bulk input and output.** The reader loads all numbers and buffers one answer line per scenario.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const emptyNode = 0

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

Heights are positive, so the scanner needs no minus branch.
Block flushing keeps memory bounded on large scenarios.

**Node state and rotations.** Sizes drive ranks and lazy flags drive reversals.

```nim
var nodeLeft: seq[int]
var nodeRight: seq[int]
var nodeParent: seq[int]
var nodeSize: seq[int]
var nodeReversed: seq[bool]
var splayRoot = emptyNode

proc refreshNodeSize(nodeIndex: int) =
  nodeSize[nodeIndex] = 1 + nodeSize[nodeLeft[nodeIndex]] + nodeSize[nodeRight[nodeIndex]]

proc pushDown(nodeIndex: int) =
  if nodeIndex != emptyNode and nodeReversed[nodeIndex]:
    let formerLeft = nodeLeft[nodeIndex]
    let formerRight = nodeRight[nodeIndex]
    nodeLeft[nodeIndex] = formerRight
    nodeRight[nodeIndex] = formerLeft
    if formerLeft != emptyNode:
      nodeReversed[formerLeft] = not nodeReversed[formerLeft]
    if formerRight != emptyNode:
      nodeReversed[formerRight] = not nodeReversed[formerRight]
    nodeReversed[nodeIndex] = false

proc rotateNode(nodeIndex: int) =
  let parentIndex = nodeParent[nodeIndex]
  let grandIndex = nodeParent[parentIndex]
  pushDown(parentIndex)
  pushDown(nodeIndex)
  if nodeLeft[parentIndex] == nodeIndex:
    nodeLeft[parentIndex] = nodeRight[nodeIndex]
    if nodeRight[nodeIndex] != emptyNode:
      nodeParent[nodeRight[nodeIndex]] = parentIndex
    nodeRight[nodeIndex] = parentIndex
  else:
    nodeRight[parentIndex] = nodeLeft[nodeIndex]
    if nodeLeft[nodeIndex] != emptyNode:
      nodeParent[nodeLeft[nodeIndex]] = parentIndex
    nodeLeft[nodeIndex] = parentIndex
  nodeParent[nodeIndex] = grandIndex
  nodeParent[parentIndex] = nodeIndex
  if grandIndex != emptyNode:
    if nodeLeft[grandIndex] == parentIndex:
      nodeLeft[grandIndex] = nodeIndex
    else:
      nodeRight[grandIndex] = nodeIndex
  refreshNodeSize(parentIndex)
  refreshNodeSize(nodeIndex)
```

`pushDown` swaps both children before clearing the flag.
Each rotation refreshes only the two affected nodes.

**Splay and rank lookup.** One splay reaches the root; the other stops at a parent.

```nim
proc splayNode(nodeIndex: int) =
  var pathNodes: seq[int] = @[]
  var cursor = nodeIndex
  while cursor != emptyNode:
    pathNodes.add cursor
    cursor = nodeParent[cursor]
  for pathIndex in countdown(pathNodes.len - 1, 0):
    pushDown(pathNodes[pathIndex])
  while nodeParent[nodeIndex] != emptyNode:
    let parentIndex = nodeParent[nodeIndex]
    let grandIndex = nodeParent[parentIndex]
    if grandIndex != emptyNode:
      if (nodeLeft[parentIndex] == nodeIndex) == (nodeLeft[grandIndex] == parentIndex):
        rotateNode(parentIndex)
      else:
        rotateNode(nodeIndex)
    rotateNode(nodeIndex)
  splayRoot = nodeIndex

proc splayUnderParent(nodeIndex: int, stopParent: int) =
  var pathNodes: seq[int] = @[]
  var cursor = nodeIndex
  while cursor != emptyNode and cursor != stopParent:
    pathNodes.add cursor
    cursor = nodeParent[cursor]
  for pathIndex in countdown(pathNodes.len - 1, 0):
    pushDown(pathNodes[pathIndex])
  while nodeParent[nodeIndex] != emptyNode and nodeParent[nodeIndex] != stopParent:
    let parentIndex = nodeParent[nodeIndex]
    let grandIndex = nodeParent[parentIndex]
    if grandIndex != emptyNode and grandIndex != stopParent:
      if (nodeLeft[parentIndex] == nodeIndex) == (nodeLeft[grandIndex] == parentIndex):
        rotateNode(parentIndex)
      else:
        rotateNode(nodeIndex)
    rotateNode(nodeIndex)

proc nodeAtRank(wantedRank: int): int =
  var remainingRank = wantedRank
  var cursor = splayRoot
  while cursor != emptyNode:
    pushDown(cursor)
    let leftSize = nodeSize[nodeLeft[cursor]]
    if remainingRank <= leftSize:
      cursor = nodeLeft[cursor]
    elif remainingRank == leftSize + 1:
      return cursor
    else:
      remainingRank = remainingRank - leftSize - 1
      cursor = nodeRight[cursor]
  return emptyNode
```

The path is pushed top down before any rotation.
`splayUnderParent` stops one level below the root.
`nodeAtRank` skips whole subtrees using their sizes.

**Interval reversal.** Boundary splays isolate one subtree for a single flip.

```nim
proc reverseInterval(leftRank: int, rightRank: int) =
  let totalNodes = nodeSize[splayRoot]
  if rightRank < totalNodes:
    if leftRank > 1:
      splayNode(nodeAtRank(leftRank - 1))
      let boundaryNode = nodeAtRank(rightRank + 1)
      splayUnderParent(boundaryNode, splayRoot)
      let middleNode = nodeLeft[boundaryNode]
      if middleNode != emptyNode:
        nodeReversed[middleNode] = not nodeReversed[middleNode]
    else:
      splayNode(nodeAtRank(rightRank + 1))
      let middleNode = nodeLeft[splayRoot]
      if middleNode != emptyNode:
        nodeReversed[middleNode] = not nodeReversed[middleNode]
  else:
    if leftRank > 1:
      splayNode(nodeAtRank(leftRank - 1))
      let middleNode = nodeRight[splayRoot]
      if middleNode != emptyNode:
        nodeReversed[middleNode] = not nodeReversed[middleNode]
    else:
      nodeReversed[splayRoot] = not nodeReversed[splayRoot]
```

The four branches cover both ends of the row.
No node values move during a reversal.

**Sorted targets and driver.** A packed key sorts height and original index together.

```nim
proc buildTree(lowerIndex: int, upperIndex: int): int =
  if lowerIndex > upperIndex:
    return emptyNode
  let middleIndex = (lowerIndex + upperIndex) div 2
  nodeLeft[middleIndex] = buildTree(lowerIndex, middleIndex - 1)
  nodeRight[middleIndex] = buildTree(middleIndex + 1, upperIndex)
  if nodeLeft[middleIndex] != emptyNode:
    nodeParent[nodeLeft[middleIndex]] = middleIndex
  if nodeRight[middleIndex] != emptyNode:
    nodeParent[nodeRight[middleIndex]] = middleIndex
  refreshNodeSize(middleIndex)
  return middleIndex

proc quickSortKeys(keys: var seq[int64], lowerIndex: int, upperIndex: int) =
  var lowCursor = lowerIndex
  var highCursor = upperIndex
  let pivotValue = keys[(lowerIndex + upperIndex) div 2]
  while lowCursor <= highCursor:
    while keys[lowCursor] < pivotValue:
      lowCursor += 1
    while keys[highCursor] > pivotValue:
      highCursor -= 1
    if lowCursor <= highCursor:
      let swapValue = keys[lowCursor]
      keys[lowCursor] = keys[highCursor]
      keys[highCursor] = swapValue
      lowCursor += 1
      highCursor -= 1
  if lowerIndex < highCursor:
    quickSortKeys(keys, lowerIndex, highCursor)
  if lowCursor < upperIndex:
    quickSortKeys(keys, lowCursor, upperIndex)

while true:
  let sampleCount = nextInt(inputData, scanPos)
  if sampleCount == 0:
    break
  var heightValues = newSeq[int](sampleCount + 1)
  for sampleIndex in 1 .. sampleCount:
    heightValues[sampleIndex] = nextInt(inputData, scanPos)

  nodeLeft = newSeq[int](sampleCount + 1)
  nodeRight = newSeq[int](sampleCount + 1)
  nodeParent = newSeq[int](sampleCount + 1)
  nodeSize = newSeq[int](sampleCount + 1)
  nodeReversed = newSeq[bool](sampleCount + 1)
  splayRoot = buildTree(1, sampleCount)

  var sortedKeys = newSeq[int64](sampleCount)
  let keyStride = int64(sampleCount + 1)
  for sampleIndex in 1 .. sampleCount:
    sortedKeys[sampleIndex - 1] = int64(heightValues[sampleIndex]) * keyStride + int64(sampleIndex)
  quickSortKeys(sortedKeys, 0, sampleCount - 1)

  for stepIndex in 0 .. sampleCount - 1:
    let targetNode = int(sortedKeys[stepIndex] mod keyStride)
    splayNode(targetNode)
    let positionValue = nodeSize[nodeLeft[splayRoot]] + 1
    appendOutput($positionValue)
    if stepIndex == sampleCount - 1:
      outputBuffer.add '\n'
    else:
      outputBuffer.add ' '
    reverseInterval(stepIndex + 1, positionValue)

stdout.write outputBuffer
outputBuffer.setLen 0
```

The packed key keeps equal heights in input order.
The balanced build gives an initial row in original order.
One final flush writes every scenario line.

## Complexity

Sorting and splay steps dominate the runtime.

| phase | time | space |
|---|---|---|
| input read | one pass over heights | one input string |
| target sort | N log N key comparisons | array of N keys |
| splay steps | N splays and rank lookups | six arrays of N slots |
| output | one buffered line per scenario | block buffer |

Splay operations keep their cost per step logarithmic on average.

| measure | Big O |
|---|---|
| time | O(N log N) per scenario |
| space | O(N) per scenario |

Copying and reversing the row at every step would cost O(N^2). Lazy splay intervals are the takeaway.
