# MTREECOL — Color a tree (SPOJ)

<https://www.spoj.com/problems/MTREECOL/>

## Problem

Color every node of a rooted tree, one node per time unit, and pay each node's factor times its finish time. Find the smallest total cost over all orders that color a parent before its children.

Each case starts with N and the root R. The next line holds N cost factors. The next N minus one lines hold father-child pairs. A case with N = 0 and R = 0 ends input. Each case produces one integer.

| item | bound |
|---|---|
| nodes N | 1 to 1000 |
| root R | 1 to N |
| cost factor | 1 to 500 |
| judge limit | 1000 ms, 1536 MB |

The tree shape and the factors together drive the choice of order.

Sample input:

```
5 1
1 2 1 2 4
1 2
1 3
2 4
3 5
0 0
```

Sample output:

```
33
```

## Idea

Treat each finished group of nodes as one block, like stacking boxes from heaviest to lightest. Repeatedly pull the block with the highest average factor next to its parent, then fuse the two blocks. This greedy fusion is Sidney's decomposition for a rooted tree. Each pass scans the remaining nodes once, so a case costs O(N squared). Scoring every possible order would need factorial time.

| step | cost |
|---|---|
| find best average block | O(N) per fusion |
| fuse and rewire children | O(children) per fusion |
| total fusions | N minus one |

The fusion count is fixed, so the scan is the cost driver.

## Why It Works

1. A node can be colored only after its parent, so the root starts every valid order.
2. If a block ends immediately before its parent block, its nodes gain exactly the parent block size in finish time.
3. That shift adds parent size times the sum of factors in the moved block.
4. Sidney's rule says the block with the largest average factor moves first, because it gains the most from an early position.
5. Fusing the chosen block into its parent preserves the same decision problem on one fewer block.

| term | meaning |
|---|---|
| `groupCosts` | sum of factors inside one fused block |
| `groupSizes` | node count inside one fused block |
| `totalCost` | base factor sum plus all recorded shifts |
| `childLists` | children still needing a parent link |

The table maps each stored array to the block quantity it tracks.

A script-generated trace for the sample:

```
factor sum                      = 1 + 2 + 1 + 2 + 4 = 10
merge node 5 into node 3:       shift 4 * 1 = 4
merge block {3,5} into root 1:  shift 5 * 1 = 5
merge node 4 into node 2:       shift 2 * 1 = 2
merge block {2,4} into root 1:  shift 4 * 3 = 12
total cost                      = 10 + 4 + 5 + 2 + 12 = 33
```

The trace yields the order 1, 3, 5, 2, 4 shown in the statement.

## Code

**Hand scanner and buffered output.** One read pass loads each case, and one string buffers the answers.

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

The scanner ignores the collapsed spacing in the statement sample.
The buffer flushes once per 131072 bytes.
All cases share these two helpers.

**Greedy fusion.** Each pass selects the richest average block and merges it upward.

```nim
proc solveCase(nodeCount: int, rootNode: int, costFactors: seq[int], parentNodes: var seq[int]): int64 =
  var groupCosts = newSeq[int64](nodeCount + 1)
  var groupSizes = newSeq[int](nodeCount + 1)
  var aliveNodes = newSeq[bool](nodeCount + 1)
  var childLists = newSeq[seq[int]](nodeCount + 1)
  var totalCost: int64 = 0
  for nodeIndex in 1 .. nodeCount:
    groupCosts[nodeIndex] = int64(costFactors[nodeIndex])
    groupSizes[nodeIndex] = 1
    aliveNodes[nodeIndex] = true
    totalCost = totalCost + int64(costFactors[nodeIndex])
  for nodeIndex in 1 .. nodeCount:
    if nodeIndex != rootNode:
      childLists[parentNodes[nodeIndex]].add nodeIndex
  var remainingNodes = nodeCount
  while remainingNodes > 1:
    var bestNode = 0
    for candidateNode in 1 .. nodeCount:
      if not aliveNodes[candidateNode] or candidateNode == rootNode:
        continue
      if bestNode == 0:
        bestNode = candidateNode
      elif groupCosts[candidateNode] * int64(groupSizes[bestNode]) >
           groupCosts[bestNode] * int64(groupSizes[candidateNode]):
        bestNode = candidateNode
    let parentNode = parentNodes[bestNode]
    let mergedCost = groupCosts[bestNode]
    let mergedSize = groupSizes[bestNode]
    totalCost = totalCost + mergedCost * int64(groupSizes[parentNode])
    groupCosts[parentNode] = groupCosts[parentNode] + mergedCost
    groupSizes[parentNode] = groupSizes[parentNode] + mergedSize
    for childNode in childLists[bestNode]:
      if aliveNodes[childNode]:
        parentNodes[childNode] = parentNode
        childLists[parentNode].add childNode
    childLists[bestNode].setLen 0
    aliveNodes[bestNode] = false
    remainingNodes -= 1
  return totalCost
```

Cross multiplication compares averages without fractions.
Int64 holds the factor sum and each recorded shift.
Children of a removed block move to its parent, so no precedence link is lost.

**Case loop.** Parsing stops at the zero sentinel and writes one line per case.

```nim
while true:
  let nodeCount = nextInt(inputData, scanPos)
  let rootNode = nextInt(inputData, scanPos)
  if nodeCount == 0 and rootNode == 0:
    break
  var costFactors = newSeq[int](nodeCount + 1)
  for nodeIndex in 1 .. nodeCount:
    costFactors[nodeIndex] = nextInt(inputData, scanPos)
  var parentNodes = newSeq[int](nodeCount + 1)
  for edgeIndex in 1 .. nodeCount - 1:
    let fatherNode = nextInt(inputData, scanPos)
    let childNode = nextInt(inputData, scanPos)
    parentNodes[childNode] = fatherNode
  let answerValue = solveCase(nodeCount, rootNode, costFactors, parentNodes)
  appendOutput($answerValue)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Every node except the root has one father edge.
The root can be any node, not only node 1.
A final flush writes any partial buffer.

## Complexity

Each case performs a fixed number of full scans over its nodes.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| block selection | N scans of up to N nodes | arrays of N blocks |
| output | one write per block | block buffer |

Selection dominates both parsing and output.

| measure | Big O |
|---|---|
| time | O(N squared) per case |
| space | O(N) |

Checking every topological order would take factorial time in N, so the greedy fusion gives the practical bound.
