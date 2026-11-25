# PERMTGEN — Permutation Generator (SPOJ)

<https://www.spoj.com/problems/PERMTGEN/>

## Problem

An array is processed from left to right. At position i, every earlier entry that is at least as large as the entry at i is increased by one. Print the array after all positions have been processed.

Input has n on the first line and n integers on the second line. Values lie between 1 and 10^9, and the permutation constraint is not guaranteed. Output the n resulting integers separated by spaces.

| item | bound |
|---|---|
| array length n | 1 to 100000 |
| input value | 1 to 10^9 |
| judge limit | 1000 ms, 1536 MB |

The length bound rules out the quadratic nested loops of the statement.

Sample input:

```
4
4 2 1 3
```

Sample output:

```
7 4 1 3
```

The first entry grows three times, and the second grows twice.

## Idea

Think of the running values as numbered hooks on a rack, like sliding every hook at or above a mark one slot higher. An insertion shifts a whole suffix of the sorted values, and the final values never repeat. For position i, its answer is the A_i-th smallest positive integer missing from the final values on its right. Walk from right to left and keep those used values in an order-statistics treap. A binary search per position finds the missing value in O(log n) probes, each costing O(log n). The written loops would use O(n^2) increments. The missing-value view is the shortcut.

## Why It Works

1. Increasing every value at or above a fixed mark preserves their relative order, so sorted values keep their order.
2. When a value equal to the mark is inserted, the old equal values shift up, so final values are all distinct.
3. Let S be the set of final values to the right of position i, and let c be the count of S values at most y.
4. The answer for position i is the smallest y at least A_i with y - A_i at least c, which means y is the A_i-th missing positive integer.
5. Since S is a set, the test c at most y - A_i changes monotonically, so binary search finds that smallest y.

| term | meaning |
|---|---|
| used | the final values already fixed to the right |
| nodeKey | one used value stored in the treap |
| nodeSize | subtree size, used for rank queries |
| countUpTo | number of used values at most a target |

The table names the treap fields that make rank queries possible.

The generator traces the sample as follows:

```
start [4, 2, 1, 3]
i 2 [5, 2, 1, 3]
i 3 [6, 3, 1, 3]
i 4 [7, 4, 1, 3]
```

The last line equals the sample output, confirming the right-to-left shortcut.

A value never needs more than n increments, so the binary search upper bound is n.

## Code

**Input and block output.** The whole array is read once and answers are buffered.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

All values are non-negative, so the scanner needs no sign branch.
One block buffer holds the entire output line.
Tokens are separated by any mix of spaces and newlines.

**Treap storage.** Nodes live in fixed arrays, and subtree sizes support rank queries.

```nim
var nodeKey: array[100005, int]
var nodePriority: array[100005, int]
var nodeLeft: array[100005, int]
var nodeRight: array[100005, int]
var nodeSize: array[100005, int]
var nodeCount = 0
var prioritySeed: int64 = 123456789

proc nextPriority(): int =
  prioritySeed = (prioritySeed * 1103515245 + 12345) mod 2147483648
  return int(prioritySeed)

proc treeSize(nodeIndex: int): int =
  if nodeIndex == 0:
    return 0
  return nodeSize[nodeIndex]

proc pullNode(nodeIndex: int) =
  nodeSize[nodeIndex] = 1 + treeSize(nodeLeft[nodeIndex]) + treeSize(nodeRight[nodeIndex])
```

Index zero stands for an empty child.
A seeded generator supplies deterministic priorities.
Each pull recomputes one subtree size in constant time.

**Split and merge.** These two operations keep the treap balanced while inserting values.

```nim
proc splitTree(root: int, key: int, leftPart: var int, rightPart: var int) =
  if root == 0:
    leftPart = 0
    rightPart = 0
    return
  if nodeKey[root] <= key:
    var innerRight = 0
    splitTree(nodeRight[root], key, innerRight, rightPart)
    nodeRight[root] = innerRight
    leftPart = root
    pullNode(root)
  else:
    var innerLeft = 0
    splitTree(nodeLeft[root], key, leftPart, innerLeft)
    nodeLeft[root] = innerLeft
    rightPart = root
    pullNode(root)

proc mergeTrees(leftPart: int, rightPart: int): int =
  if leftPart == 0:
    return rightPart
  if rightPart == 0:
    return leftPart
  if nodePriority[leftPart] < nodePriority[rightPart]:
    nodeRight[leftPart] = mergeTrees(nodeRight[leftPart], rightPart)
    pullNode(leftPart)
    return leftPart
  nodeLeft[rightPart] = mergeTrees(leftPart, nodeLeft[rightPart])
  pullNode(rightPart)
  return rightPart
```

Split puts keys at most the target on the left.
Merge joins the two pieces by smaller priority.
Both operations run in expected logarithmic time.

**Rank query.** The right-to-left pass finds each missing value and inserts it.

```nim
proc insertValue(root: var int, key: int) =
  nodeCount += 1
  nodeKey[nodeCount] = key
  nodePriority[nodeCount] = nextPriority()
  nodeLeft[nodeCount] = 0
  nodeRight[nodeCount] = 0
  nodeSize[nodeCount] = 1
  var leftPart = 0
  var rightPart = 0
  splitTree(root, key, leftPart, rightPart)
  root = mergeTrees(mergeTrees(leftPart, nodeCount), rightPart)

proc countUpTo(root: int, key: int): int =
  var current = root
  var total = 0
  while current != 0:
    if nodeKey[current] <= key:
      total += 1 + treeSize(nodeLeft[current])
      current = nodeRight[current]
    else:
      current = nodeLeft[current]
  return total
```

Insertion adds one fresh node per array position.
The rank query walks one root-to-leaf path.
No rebalancing scan touches the whole tree.

**Main pass.** Each position binary searches the increment count, then inserts its answer.

```nim
let itemCount = nextInt(inputData, scanPos)
var sourceValues = newSeq[int](itemCount)
for itemIndex in 0 .. itemCount - 1:
  sourceValues[itemIndex] = nextInt(inputData, scanPos)
var finalValues = newSeq[int](itemCount)
var treeRoot = 0
for itemIndex in countdown(itemCount - 1, 0):
  let baseValue = sourceValues[itemIndex]
  var low = 0
  var high = itemCount
  while low < high:
    let middle = (low + high) div 2
    if middle >= countUpTo(treeRoot, baseValue + middle):
      high = middle
    else:
      low = middle + 1
  let finalValue = baseValue + low
  finalValues[itemIndex] = finalValue
  insertValue(treeRoot, finalValue)
for itemIndex in 0 .. itemCount - 1:
  if itemIndex > 0:
    outputBuffer.add ' '
  appendOutput($finalValues[itemIndex])
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The search bound is the array length.
Each result is inserted before moving to the next position.
One pass writes all answers in input order.

## Complexity

The treap and the per-position search set the cost.

| phase | time | space |
|---|---|---|
| input read | one pass over n values | one input string |
| treap work | O(n log n) split and merge steps | n nodes |
| rank searches | O(n log n) probes of O(log n) steps | treap arrays |
| output | one line of n integers | block buffer |

Both logarithmic phases grow the same way.

| measure | Big O |
|---|---|
| time | O(n log n) |
| space | O(n) |

The nested loops in the statement would take O(n^2) time and stall at n = 100000.

Order statistics replace a full scan with a short tree walk.
