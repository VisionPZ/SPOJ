# JAZZYJOB — Jazzy Job (SPOJ)

<https://www.spoj.com/problems/JAZZYJOB/>

## Problem

Find the smallest energy cap that lets every target substance be made from some source, then count the fewest reactions needed under that cap. Directed reactions each require one activation energy.

A test gives `S` sources, `D` targets, `N` elements, then `S + D` ID lines, then `R` and its reactions. Print `upper conversions` or `Excessive Energy.` when some target stays unreachable.

| item | bound |
|---|---|
| elements N | up to 10000 |
| reactions R | below 1000000 |
| energy A | 1 to 999999999 |
| judge limit | 1000 ms, 1536 MB |

The reaction count drives the need for linear-time graph passes.

Sample input:

```
1
2 2 6
1
3
0
3
6
1 2 2
2 4 3
4 5 1
4 2 2
3 0 4
5 0 1
```

Sample output:

```
3 4
```

## Idea

Think of the energy cap as a gate on a one-way pipe system. Open gates from low energy upward until every destination is reachable, like raising a floodgate until water reaches each tap.

A bottleneck shortest path from the sources gives the minimal cap for each target. The largest of those caps is the answer's first number. A second pass counts reaction steps using only gates at or below that cap.

Trying every cap value would repeat work many times.

Two graph passes settle the whole test case.

## Why It Works

1. A reaction with energy above the cap cannot be used.
2. The bottleneck of a path is its largest reaction energy.
3. Minimising the bottleneck gives the cheapest cap for one target.
4. The cap serving every target is the largest individual bottleneck.
5. Under that cap, breadth-first search gives the fewest reactions per target.

| term | meaning |
|---|---|
| `bottleneck` | smallest possible largest energy on a path |
| `upperBound` | largest bottleneck over all targets |
| `pathLength` | fewest reactions from any source |
| `conversionCount` | sum of path lengths over targets |

A worked trace follows for the sample with cap three.

```
source 1 to target 0: 1-2-4-5-0, four reactions
target 3 is a source: zero reactions
total = 4
```

The cap four edge `3-0` is excluded, so the longer route wins.

## Code

**Input and buffered output.** The hand reader stores the whole test file.

```nim
const flushBlockBytes = 1 shl 17
const infiniteDistance = int64(1) shl 60

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

Infinite distance marks unreachable elements.
All tokens use the same integer scanner.
Output lines accumulate in one buffer.

**Heap helpers.** A binary heap keeps the frontier ordered by bottleneck.

```nim
var heapNode = newSeq[int](0)
var heapCost = newSeq[int64](0)

proc heapPush(nodeIndex: int, costValue: int64) =
  heapNode.add nodeIndex
  heapCost.add costValue
  var childIndex = heapNode.len - 1
  while childIndex > 0:
    let parentIndex = (childIndex - 1) div 2
    if heapCost[parentIndex] <= heapCost[childIndex]:
      break
    swap heapCost[parentIndex], heapCost[childIndex]
    swap heapNode[parentIndex], heapNode[childIndex]
    childIndex = parentIndex

proc heapPop(): (int, int64) =
  let topNode = heapNode[0]
  let topCost = heapCost[0]
  let lastIndex = heapNode.len - 1
  heapNode[0] = heapNode[lastIndex]
  heapCost[0] = heapCost[lastIndex]
  heapNode.setLen lastIndex
  heapCost.setLen lastIndex
  var parentIndex = 0
  while true:
    let leftChild = parentIndex * 2 + 1
    if leftChild >= heapNode.len:
      break
    let rightChild = leftChild + 1
    var smallerChild = leftChild
    if rightChild < heapNode.len and heapCost[rightChild] < heapCost[leftChild]:
      smallerChild = rightChild
    if heapCost[parentIndex] <= heapCost[smallerChild]:
      break
    swap heapCost[parentIndex], heapCost[smallerChild]
    swap heapNode[parentIndex], heapNode[smallerChild]
    parentIndex = smallerChild
  return (topNode, topCost)
```

The heap stores pairs of node and cost.
Sift operations keep the tree ordered.
Each push and pop costs logarithmic time.

**Bottleneck search.** Every source starts at cost zero.

```nim
proc solveCase(elementCount: int, sourceCount: int, targetCount: int,
               scanPosition: var int): string =
  var sources = newSeq[int](sourceCount)
  for sourceIndex in 0 .. sourceCount - 1:
    sources[sourceIndex] = nextInt(inputData, scanPosition)
  var targets = newSeq[int](targetCount)
  for targetIndex in 0 .. targetCount - 1:
    targets[targetIndex] = nextInt(inputData, scanPosition)
  let edgeCount = nextInt(inputData, scanPosition)

  var edgeHead = newSeq[int](elementCount)
  for headIndex in 0 .. elementCount - 1:
    edgeHead[headIndex] = -1
  var edgeTo = newSeq[int](edgeCount)
  var edgeEnergy = newSeq[int](edgeCount)
  var edgeNext = newSeq[int](edgeCount)
  for edgeIndex in 0 .. edgeCount - 1:
    let fromElement = nextInt(inputData, scanPosition)
    let toElement = nextInt(inputData, scanPosition)
    let energyValue = nextInt(inputData, scanPosition)
    edgeTo[edgeIndex] = toElement
    edgeEnergy[edgeIndex] = energyValue
    edgeNext[edgeIndex] = edgeHead[fromElement]
    edgeHead[fromElement] = edgeIndex
```

Edges live in flat adjacency arrays.
Each reaction enters exactly one list.
Reading sources before edges matches the input.

```nim
  var bottleneck = newSeq[int64](elementCount)
  for elementIndex in 0 .. elementCount - 1:
    bottleneck[elementIndex] = infiniteDistance
  heapNode.setLen 0
  heapCost.setLen 0
  for sourceIndex in 0 .. sourceCount - 1:
    let sourceElement = sources[sourceIndex]
    if bottleneck[sourceElement] != 0:
      bottleneck[sourceElement] = 0
      heapPush(sourceElement, 0)

  while heapNode.len > 0:
    let popped = heapPop()
    let currentElement = popped[0]
    let currentCost = popped[1]
    if currentCost != bottleneck[currentElement]:
      continue
    var edgeIndex = edgeHead[currentElement]
    while edgeIndex >= 0:
      let nextElement = edgeTo[edgeIndex]
      var candidate = currentCost
      if int64(edgeEnergy[edgeIndex]) > candidate:
        candidate = int64(edgeEnergy[edgeIndex])
      if candidate < bottleneck[nextElement]:
        bottleneck[nextElement] = candidate
        heapPush(nextElement, candidate)
      edgeIndex = edgeNext[edgeIndex]

  var upperBound: int64 = 0
  for targetIndex in 0 .. targetCount - 1:
    let targetElement = targets[targetIndex]
    if bottleneck[targetElement] == infiniteDistance:
      return "Excessive Energy."
    if bottleneck[targetElement] > upperBound:
      upperBound = bottleneck[targetElement]
```

A relaxed edge raises the path bottleneck.
Stale heap entries are skipped by the cost check.
An infinite target bottleneck means the case is impossible.

**Reaction counting.** Breadth-first search uses only allowed edges.

```nim
  var pathLength = newSeq[int](elementCount)
  for elementIndex in 0 .. elementCount - 1:
    pathLength[elementIndex] = -1
  var queue = newSeq[int](elementCount)
  var queueHead = 0
  var queueTail = 0
  for sourceIndex in 0 .. sourceCount - 1:
    let sourceElement = sources[sourceIndex]
    if pathLength[sourceElement] < 0:
      pathLength[sourceElement] = 0
      queue[queueTail] = sourceElement
      queueTail += 1
  while queueHead < queueTail:
    let currentElement = queue[queueHead]
    queueHead += 1
    var edgeIndex = edgeHead[currentElement]
    while edgeIndex >= 0:
      if int64(edgeEnergy[edgeIndex]) <= upperBound:
        let nextElement = edgeTo[edgeIndex]
        if pathLength[nextElement] < 0:
          pathLength[nextElement] = pathLength[currentElement] + 1
          queue[queueTail] = nextElement
          queueTail += 1
      edgeIndex = edgeNext[edgeIndex]

  var conversionCount: int64 = 0
  for targetIndex in 0 .. targetCount - 1:
    conversionCount = conversionCount + int64(pathLength[targets[targetIndex]])
  return $upperBound & " " & $conversionCount
```

Multiple sources enter the queue together.
Edges above the cap are ignored in this pass.
One visit per element keeps the queue bounded.

**Case loop.** Each case yields one answer line.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let sourceCount = nextInt(inputData, scanPos)
  let targetCount = nextInt(inputData, scanPos)
  let elementCount = nextInt(inputData, scanPos)
  appendOutput(solveCase(elementCount, sourceCount, targetCount, scanPos))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The scan position advances past every reaction.
Buffered writes avoid one syscall per case.
The final flush ends the output.

## Complexity

The heap search and breadth-first pass dominate.

| phase | time | space |
|---|---|---|
| input read | one pass over reaction bytes | input string |
| bottleneck search | O((N+R) log N) | edges and heap |
| reaction count | O(N+R) | distances and queue |
| output | one buffered write per block | block buffer |

Flat adjacency lists keep both passes cache friendly.

| measure | Big O |
|---|---|
| time | O((N+R) log N) per case |
| space | O(N+R) |

Scanning every possible cap would multiply the graph passes many times.

Bottleneck search finds the cap once, and breadth-first search counts reactions once.
