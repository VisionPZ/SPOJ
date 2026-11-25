# NCOPRIME — Coprime Pairs (SPOJ)

<https://www.spoj.com/problems/NCOPRIME/>

## Problem

Two arrays of integers receive labels 0 or 1. Count the largest possible number of pairs where the smaller value is labeled 0, the larger value is labeled 1, and the two values share a factor.

Input starts with N, then array A, then array B. Each array holds N values. Output the maximum score as one integer.

| item | bound |
|---|---|
| array length N | 1 to 40 |
| array value | 2 to 1000000000 |
| judge limit | 1000 ms, 1536 MB |

Pairs always join one value from A with one value from B. Equal values never form an edge.

Sample input:

```
4
16 3 2 9
12 18 13 4
```

Sample output:

```
8
```

## Idea

Think of each legal pair as a reward for pointing an arrow from its smaller value to its larger value. Choosing labels is like funding projects, where each reward requires both endpoint labels. Maximum closure turns that choice into one min-cut, while enumerating all 2^(2N) labelings would be far larger.

## Why It Works

1. A pair contributes one point when the smaller endpoint has label 0 and the larger endpoint has label 1.
2. Let alpha be 1 when an A value has label 0, and gamma be 1 when a B value has label 1.
3. For a pair with the A value smaller, the reward is alpha times gamma.
4. For a pair with the B value smaller, the reward equals one minus alpha minus gamma plus alpha times gamma.
5. The last case adds a constant one and a penalty of one for each chosen endpoint.
6. A closure node per pair carries profit one and points to both required label nodes.
7. Penalty arcs from label nodes to the sink cost one per reversed pair.
8. The best closure value plus the number of reversed pairs is the maximum score.

| term | meaning |
|---|---|
| `qualifyingPairs` | cross-array pairs with a common factor and unequal values |
| `firstPenalties` | reversed pairs charged to each A value |
| `secondPenalties` | reversed pairs charged to each B value |
| `minimumCut` | cut capacity lost from total pair profit |
| `bestScore` | maximum number of drawn edges |

The cut removes exactly the profit lost by incompatible labels.

A worked trace from `gen.py`:

```
sample arrays: 10 qualifying pairs, 2 have the B value smaller
best labeling: mark 2, 3, 9, 16 as 0 and 12, 18, 4 as 1
closure profit 6, minimum cut 4, reversed pairs 2
score = 10 - 4 + 2 = 8
```

The score 8 matches the sample output.

## Code

**Input and scanner.** The whole input is read once and parsed by hand.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const infiniteCapacity = 1 shl 29

type
  FlowEdge = object
    destination: int
    reverseIndex: int
    capacity: int
  ElementPair = tuple[firstIndex: int, secondIndex: int]

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
```

The infinite capacity exceeds the total finite weight.
Each edge stores its reverse index for residual updates.
The pair tuple keeps both array indexes together.

**Buffered output.** One answer is written through the shared buffer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The answer is appended once.
The block flush keeps the write path uniform.
A final write clears remaining bytes.

**Dinic flow.** Level graphs and blocking flows compute the min-cut.

```nim
var flowGraph = newSeq[seq[FlowEdge]]()
var levelGraph = newSeq[int]()
var edgeCursor = newSeq[int]()

proc addFlowEdge(sourceIndex, targetIndex, capacityValue: int) =
  let forwardIndex = flowGraph[sourceIndex].len
  flowGraph[sourceIndex].add FlowEdge(destination: targetIndex, reverseIndex: flowGraph[targetIndex].len, capacity: capacityValue)
  flowGraph[targetIndex].add FlowEdge(destination: sourceIndex, reverseIndex: forwardIndex, capacity: 0)

proc sendFlow(nodeIndex, availableFlow, sinkIndex: int): int =
  if nodeIndex == sinkIndex:
    return availableFlow
  while edgeCursor[nodeIndex] < flowGraph[nodeIndex].len:
    let edgeIndex = edgeCursor[nodeIndex]
    let edgeDestination = flowGraph[nodeIndex][edgeIndex].destination
    if flowGraph[nodeIndex][edgeIndex].capacity > 0 and levelGraph[edgeDestination] == levelGraph[nodeIndex] + 1:
      let pushedFlow = sendFlow(edgeDestination, min(availableFlow, flowGraph[nodeIndex][edgeIndex].capacity), sinkIndex)
      if pushedFlow > 0:
        flowGraph[nodeIndex][edgeIndex].capacity -= pushedFlow
        flowGraph[edgeDestination][flowGraph[nodeIndex][edgeIndex].reverseIndex].capacity += pushedFlow
        return pushedFlow
    edgeCursor[nodeIndex] += 1
  return 0

proc maximumFlow(sourceIndex, sinkIndex: int): int =
  var totalFlow = 0
  while true:
    let nodeCount = flowGraph.len
    levelGraph = newSeq[int](nodeCount)
    for nodeIndex in 0 .. nodeCount - 1:
      levelGraph[nodeIndex] = -1
    levelGraph[sourceIndex] = 0
    var queue = newSeq[int]()
    queue.add sourceIndex
    var queueHead = 0
    while queueHead < queue.len:
      let currentNode = queue[queueHead]
      queueHead += 1
      for edgeIndex in 0 .. flowGraph[currentNode].len - 1:
        let edge = flowGraph[currentNode][edgeIndex]
        if edge.capacity > 0 and levelGraph[edge.destination] == -1:
          levelGraph[edge.destination] = levelGraph[currentNode] + 1
          queue.add edge.destination
    if levelGraph[sinkIndex] == -1:
      break
    edgeCursor = newSeq[int](nodeCount)
    while true:
      let pushedFlow = sendFlow(sourceIndex, infiniteCapacity, sinkIndex)
      if pushedFlow == 0:
        break
      totalFlow += pushedFlow
  return totalFlow
```

Breadth-first search builds each level graph.
The cursor skips exhausted edges during a blocking flow.
The final residual graph identifies the minimum cut.

**Divisor check.** Only pairs with a common factor can score.

```nim
proc greatestCommonDivisor(firstValue, secondValue: int): int =
  var leftValue = firstValue
  var rightValue = secondValue
  while rightValue != 0:
    let remainderValue = leftValue mod rightValue
    leftValue = rightValue
    rightValue = remainderValue
  return leftValue
```

Euclid's loop uses one remainder per step.
Values stay in signed 64-bit range.
Equal values are filtered before this call.

**Graph construction.** Pairs, penalties, and closure arcs build the flow network.

```nim
let elementCount = nextInt(inputData, scanPos)
var firstArray = newSeq[int](elementCount)
var secondArray = newSeq[int](elementCount)
for elementIndex in 0 .. elementCount - 1:
  firstArray[elementIndex] = nextInt(inputData, scanPos)
for elementIndex in 0 .. elementCount - 1:
  secondArray[elementIndex] = nextInt(inputData, scanPos)

var qualifyingPairs = newSeq[ElementPair]()
var smallerSecondCount = 0
for firstIndex in 0 .. elementCount - 1:
  for secondIndex in 0 .. elementCount - 1:
    if firstArray[firstIndex] != secondArray[secondIndex] and
       greatestCommonDivisor(firstArray[firstIndex], secondArray[secondIndex]) > 1:
      qualifyingPairs.add (firstIndex, secondIndex)
      if secondArray[secondIndex] < firstArray[firstIndex]:
        smallerSecondCount += 1

var firstPenalties = newSeq[int](elementCount)
var secondPenalties = newSeq[int](elementCount)
for pairEntry in qualifyingPairs:
  if secondArray[pairEntry.secondIndex] < firstArray[pairEntry.firstIndex]:
    firstPenalties[pairEntry.firstIndex] += 1
    secondPenalties[pairEntry.secondIndex] += 1

let sourceNode = 0
let sinkNode = 2 * elementCount + qualifyingPairs.len + 1
flowGraph = newSeq[seq[FlowEdge]](sinkNode + 1)
for nodeIndex in 0 .. sinkNode:
  flowGraph[nodeIndex] = newSeq[FlowEdge]()
for firstIndex in 0 .. elementCount - 1:
  if firstPenalties[firstIndex] > 0:
    addFlowEdge(1 + firstIndex, sinkNode, firstPenalties[firstIndex])
for secondIndex in 0 .. elementCount - 1:
  if secondPenalties[secondIndex] > 0:
    addFlowEdge(1 + elementCount + secondIndex, sinkNode, secondPenalties[secondIndex])

var pairNode = 2 * elementCount + 1
for pairEntry in qualifyingPairs:
  addFlowEdge(sourceNode, pairNode, 1)
  addFlowEdge(pairNode, 1 + pairEntry.firstIndex, infiniteCapacity)
  addFlowEdge(pairNode, 1 + elementCount + pairEntry.secondIndex, infiniteCapacity)
  pairNode += 1

let minimumCut = maximumFlow(sourceNode, sinkNode)
let bestScore = qualifyingPairs.len - minimumCut + smallerSecondCount
appendOutput($bestScore)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Each qualifying pair adds one profit node.
Penalty arcs charge reversed pairs once per endpoint.
The cut value converts closure profit into the final score.

## Complexity

The graph has one node per array element and per qualifying pair.

| phase | time | space |
|---|---|---|
| input read | one pass over both arrays | one input string |
| pair scan | N squared gcd checks | pair list |
| flow | Dinic on the closure graph | edges and levels |
| output | one line | block buffer |

The pair scan and the flow both stay small at N = 40.

| measure | Big O |
|---|---|
| time | O(N^2 log V) with V at most 2N + N^2 |
| space | O(N^2) |

Brute-force labeling would test 2^(2N) assignments.
Maximum closure gives the same optimum through one min-cut.
