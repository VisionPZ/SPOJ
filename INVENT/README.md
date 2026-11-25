# INVENT — Inventing Test Data (SPOJ)

<https://www.spoj.com/problems/INVENT/>

## Problem

Given a weighted tree, build the cheapest complete graph whose only minimum spanning tree is that tree. Non-tree edges need the smallest weights that keep every alternative spanning tree heavier.

Input starts with the number of test cases. Each case is preceded by a blank line. A line holds the node count N, then N-1 lines hold three integers: two endpoint nodes and a tree edge weight. Output one integer per case: the minimum total weight of the complete graph.

| item | bound |
|---|---|
| test cases | first integer, blank line before each case |
| nodes N | up to 15000 |
| tree edge weight | 1 to 10000 |
| judge limit | 500 ms, 1536 MB |

Node count drives the work because the number of non-tree pairs grows quadratically.

Sample input:

```
2

3
1 2 4
2 3 7

4
1 2 1
1 3 1
1 4 2
```

Sample output:

```
19
12
```

## Idea

Treat each tree edge like a gate that opens between two crowds, and charge every new cross-crowd pair as it passes. Union-find processes tree edges from light to heavy and counts pairs that become connected. Each such pair needs one more than the heaviest tree edge on its path. Kruskal-style merging finds those pairs in one pass, while checking all N squared pairs would be far slower. The answer is the tree weight plus these extra charges.

## Why It Works

1. A complete graph has one edge for every unordered pair of nodes.
2. A tree edge of weight w keeps weight w; changing it would change the given tree.
3. A non-tree edge between nodes u and v must weigh more than every tree edge on the u-v path, or an alternate minimum spanning tree appears.
4. The smallest safe weight for that pair is the heaviest path edge plus one.
5. Sorting tree edges by weight and merging components assigns each pair to the last edge of maximum weight on its path.
6. When an edge of weight w merges components of sizes s and t, exactly s times t minus one new pairs get charge w plus one.

| term | meaning |
|---|---|
| `treeWeightTotal` | sum of the given tree edge weights |
| `crossingPairs` | new node pairs joined by one tree edge |
| `extraWeightTotal` | total charge for all non-tree pairs |
| `componentSizes` | node count of every union-find component |

The table names the only values needed for the final sum.

A script trace of the second sample case gives visible numbers:

```text
tree sum 4
edge 1-2 w=1: sizes 1x1, pairs=0, add=0
edge 1-3 w=1: sizes 2x1, pairs=1, add=2
edge 1-4 w=2: sizes 3x1, pairs=2, add=6
extra 8 total 12
```

The trace adds the tree sum of 4 to extra charges of 8 and reproduces the sample answer 12.

## Code

**Input and scanning.** The hand reader loads every test case into one string.

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
```

Blank lines contain no digits, so the scanner skips them.
Every weight is positive, so no minus branch is needed.
Scanning runs once over the whole input string.

**Output buffer.** Large answer lists are written in blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

One buffer serves every test case.
A write happens only after the buffer reaches the block size.
This keeps the output path cheap when many cases are present.

**Edge sorting.** A merge sort orders edges by weight without a library comparator.

```nim
type TreeEdge = object
  endpointA: int
  endpointB: int
  edgeWeight: int

proc compareEdges(leftEdge: TreeEdge, rightEdge: TreeEdge): int =
  if leftEdge.edgeWeight < rightEdge.edgeWeight:
    return -1
  if leftEdge.edgeWeight > rightEdge.edgeWeight:
    return 1
  return 0

proc mergeSortEdges(edgeList: var seq[TreeEdge], helperList: var seq[TreeEdge], leftBound: int, rightBound: int) =
  if rightBound - leftBound <= 1:
    return
  let middleIndex = (leftBound + rightBound) div 2
  mergeSortEdges(edgeList, helperList, leftBound, middleIndex)
  mergeSortEdges(edgeList, helperList, middleIndex, rightBound)
  var leftCursor = leftBound
  var rightCursor = middleIndex
  var writeCursor = leftBound
  while leftCursor < middleIndex and rightCursor < rightBound:
    if compareEdges(edgeList[leftCursor], edgeList[rightCursor]) <= 0:
      helperList[writeCursor] = edgeList[leftCursor]
      leftCursor += 1
    else:
      helperList[writeCursor] = edgeList[rightCursor]
      rightCursor += 1
    writeCursor += 1
  while leftCursor < middleIndex:
    helperList[writeCursor] = edgeList[leftCursor]
    leftCursor += 1
    writeCursor += 1
  while rightCursor < rightBound:
    helperList[writeCursor] = edgeList[rightCursor]
    rightCursor += 1
    writeCursor += 1
  for edgeIndex in leftBound .. rightBound - 1:
    edgeList[edgeIndex] = helperList[edgeIndex]
```

Each edge is read once and copied once per merge level.
Ties keep any order, because equal-weight merges give the same total.
Sorting costs O(N log N) for N-1 edges.

**Union-find.** Path halving finds the component of an endpoint.

```nim
proc findRoot(parentNodes: var seq[int], nodeIndex: int): int =
  var currentNode = nodeIndex
  while parentNodes[currentNode] != currentNode:
    parentNodes[currentNode] = parentNodes[parentNodes[currentNode]]
    currentNode = parentNodes[currentNode]
  return currentNode
```

Path halving shortens chains during each lookup.
The parent and size arrays are rebuilt for every test case.
Each operation is near constant time in practice.

**Main loop.** Edges are merged in weight order and each merge charges its new pairs.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let nodeCount = nextInt(inputData, scanPos)
  var treeEdges = newSeq[TreeEdge](nodeCount - 1)
  var treeWeightTotal: int64 = 0
  for edgeIndex in 0 .. nodeCount - 2:
    treeEdges[edgeIndex].endpointA = nextInt(inputData, scanPos)
    treeEdges[edgeIndex].endpointB = nextInt(inputData, scanPos)
    treeEdges[edgeIndex].edgeWeight = nextInt(inputData, scanPos)
    treeWeightTotal = treeWeightTotal + int64(treeEdges[edgeIndex].edgeWeight)
  var helperEdges = newSeq[TreeEdge](nodeCount - 1)
  mergeSortEdges(treeEdges, helperEdges, 0, nodeCount - 1)
  var parentNodes = newSeq[int](nodeCount + 1)
  var componentSizes = newSeq[int](nodeCount + 1)
  for nodeIndex in 1 .. nodeCount:
    parentNodes[nodeIndex] = nodeIndex
    componentSizes[nodeIndex] = 1
  var extraWeightTotal: int64 = 0
  for edgeIndex in 0 .. nodeCount - 2:
    let firstEndpoint = treeEdges[edgeIndex].endpointA
    let secondEndpoint = treeEdges[edgeIndex].endpointB
    var firstRoot = findRoot(parentNodes, firstEndpoint)
    var secondRoot = findRoot(parentNodes, secondEndpoint)
    if firstRoot != secondRoot:
      let crossingPairs = int64(componentSizes[firstRoot]) * int64(componentSizes[secondRoot]) - 1
      extraWeightTotal = extraWeightTotal + crossingPairs * int64(treeEdges[edgeIndex].edgeWeight + 1)
      if componentSizes[firstRoot] < componentSizes[secondRoot]:
        swap firstRoot, secondRoot
      parentNodes[secondRoot] = firstRoot
      componentSizes[firstRoot] = componentSizes[firstRoot] + componentSizes[secondRoot]
  appendOutput($(treeWeightTotal + extraWeightTotal))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Products use int64 because pair counts reach hundreds of millions.
The tree edge itself is excluded by subtracting one from the product.
The final write flushes any remaining buffered answers.

## Complexity

Each test case sorts the tree edges, then merges them once.

| phase | time | space |
|---|---|---|
| input read | one pass over all tokens | one input string |
| edge sort | N log N comparisons | two edge arrays |
| union-find | one merge per tree edge | two node arrays |
| output | one write per block | block buffer |

The sort and the merges dominate each case.

| measure | Big O |
|---|---|
| time per case | O(N log N) |
| space per case | O(N) |

Checking every pair directly would cost O(N squared) time per case.
Union-find turns those pairs into a single weighted pass, and that is the takeaway.
