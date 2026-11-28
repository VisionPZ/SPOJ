# MINDIST — Minimum Distance (SPOJ)

<https://www.spoj.com/problems/MINDIST/>

## Problem

Choose a path of total edge length at most S in a weighted tree and minimize the farthest any node sits from that path. Print that smallest worst-case distance for each test case.

Input starts with test count T. Each case gives node count N and budget S, then N-1 weighted undirected edges. Output holds one integer per case.

| item | bound |
|---|---|
| test cases T | input dependent |
| nodes N | 1 to 100000 |
| path budget S | 0 to 100000000 |
| edge weight | 1 to 1000 |
| judge limit | 2000 ms, 1536 MB |

The path endpoints are tree nodes, and distances follow tree edges.

Sample input:

```
2
5 2
1 2 5
2 3 2
2 4 4
2 5 3
8 6
1 3 2
2 3 2
3 4 6
4 5 3
4 6 4
4 7 2
7 8 3
```

Sample output:

```
5
5
```

## Idea

Treat the answer as a radius, like placing a short hose. Ask whether some short path covers every node within that radius. Root the tree. A branch whose farthest node lies beyond the radius forces the path to enter that branch. For a candidate top node, collect all forced edges and check they form a path within budget. Binary search the radius. Trying every node pair would cost far more than one linear check per radius. Test the radius, then halve the range.

## Why It Works

1. Root the tree at any node and look at child subtrees.
2. If a child subtree reaches farther than the radius from its parent, the path must enter it.
3. Forced edges below one top node form a tree. That tree is a path only when no node has more than two forced children. No inner node may have more than one.
4. The parent side of the top node must lie within the radius of that node.
5. Every unforced child subtree already lies within the radius of its parent on the path.
6. The forced path length cannot exceed S, so the budget test is exact.

| term | meaning |
|---|---|
| `downReach` | farthest distance from a node into its own subtree |
| `outsideReach` | farthest distance from a node to nodes outside its subtree |
| `requiredLength` | sum of forced edge lengths below a node |
| `pathFits` | whether forced edges below a node form a legal path |
| `radiusValue` | candidate answer tested by `canCover` |

The table names the values used in one feasibility test.

A script trace of the first sample:

```
radius 5: node 2 sees branches 5,2,4,3; none exceeds 5
          outside reach of node 2 is 5; forced path length 0 <= 2 -> feasible
radius 4: branch to node 1 reaches 5 > 4, so that edge is forced
          forced length 5 exceeds budget 2 -> infeasible
smallest feasible radius = 5
```

The trace gives 5 for the first sample case.

## Code

**Bulk input and scanner.** All tokens come from one string read once.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const absentNode = -1
const absentLength = -1000000000

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

Weights and node IDs are nonnegative.
Block flushing limits memory on large test sets.

**Tree storage.** Each undirected edge enters two adjacency slots.

```nim
let testCount = nextInt(inputData, scanPos)

proc solveCase() =
  let nodeCount = nextInt(inputData, scanPos)
  let pathBudget = nextInt(inputData, scanPos)
  var edgeHead = newSeq[int](nodeCount)
  var edgeTo = newSeq[int](2 * (nodeCount - 1))
  var edgeWeight = newSeq[int](2 * (nodeCount - 1))
  var edgeNext = newSeq[int](2 * (nodeCount - 1))
  for nodeIndex in 0 .. nodeCount - 1:
    edgeHead[nodeIndex] = absentNode
  var edgeCount = 0
  for edgeIndex in 0 .. nodeCount - 2:
    let firstNode = nextInt(inputData, scanPos) - 1
    let secondNode = nextInt(inputData, scanPos) - 1
    let bridgeWeight = nextInt(inputData, scanPos)
    edgeTo[edgeCount] = secondNode
    edgeWeight[edgeCount] = bridgeWeight
    edgeNext[edgeCount] = edgeHead[firstNode]
    edgeHead[firstNode] = edgeCount
    edgeCount += 1
    edgeTo[edgeCount] = firstNode
    edgeWeight[edgeCount] = bridgeWeight
    edgeNext[edgeCount] = edgeHead[secondNode]
    edgeHead[secondNode] = edgeCount
    edgeCount += 1
```

Node IDs shift down by one for array indexing.
The head array stores the first edge slot per node.
An iterative walk avoids deep recursion.

**Reach preprocessing.** Reverse order gives downward reach; rerooting gives outside reach.

```nim
  var parentNode = newSeq[int](nodeCount)
  var traversalOrder: seq[int] = @[]
  var stackNodes: seq[int] = @[0]
  for nodeIndex in 0 .. nodeCount - 1:
    parentNode[nodeIndex] = absentNode
  while stackNodes.len > 0:
    let currentNode = stackNodes[stackNodes.len - 1]
    stackNodes.setLen(stackNodes.len - 1)
    traversalOrder.add currentNode
    var edgeIndex = edgeHead[currentNode]
    while edgeIndex != absentNode:
      let neighborNode = edgeTo[edgeIndex]
      if neighborNode != parentNode[currentNode]:
        parentNode[neighborNode] = currentNode
        stackNodes.add neighborNode
      edgeIndex = edgeNext[edgeIndex]

  var downReach = newSeq[int](nodeCount)
  for orderIndex in countdown(traversalOrder.len - 1, 0):
    let currentNode = traversalOrder[orderIndex]
    var deepest = 0
    var edgeIndex = edgeHead[currentNode]
    while edgeIndex != absentNode:
      let neighborNode = edgeTo[edgeIndex]
      if parentNode[neighborNode] == currentNode:
        let candidate = edgeWeight[edgeIndex] + downReach[neighborNode]
        if candidate > deepest:
          deepest = candidate
      edgeIndex = edgeNext[edgeIndex]
    downReach[currentNode] = deepest

  var outsideReach = newSeq[int](nodeCount)
  for orderIndex in 0 .. traversalOrder.len - 1:
    let currentNode = traversalOrder[orderIndex]
    var bestBranch = absentLength
    var secondBranch = absentLength
    var edgeIndex = edgeHead[currentNode]
    while edgeIndex != absentNode:
      let neighborNode = edgeTo[edgeIndex]
      if parentNode[neighborNode] == currentNode:
        let branchReach = edgeWeight[edgeIndex] + downReach[neighborNode]
        if branchReach > bestBranch:
          secondBranch = bestBranch
          bestBranch = branchReach
        elif branchReach > secondBranch:
          secondBranch = branchReach
      edgeIndex = edgeNext[edgeIndex]
    edgeIndex = edgeHead[currentNode]
    while edgeIndex != absentNode:
      let neighborNode = edgeTo[edgeIndex]
      if parentNode[neighborNode] == currentNode:
        let branchReach = edgeWeight[edgeIndex] + downReach[neighborNode]
        var otherReach = outsideReach[currentNode]
        if branchReach == bestBranch:
          if secondBranch > otherReach:
            otherReach = secondBranch
        else:
          if bestBranch > otherReach:
            otherReach = bestBranch
        outsideReach[neighborNode] = edgeWeight[edgeIndex] + otherReach
      edgeIndex = edgeNext[edgeIndex]
```

The two largest child reaches exclude the current child.
`absentLength` acts as a sentinel for a missing branch.
Both passes cost one scan of all edges.

**Feasibility test.** Forced edges must form one path inside the budget.

```nim
  proc canCover(radiusValue: int): bool =
    var requiredLength = newSeq[int64](nodeCount)
    var chainFits = newSeq[bool](nodeCount)
    var pathFits = newSeq[bool](nodeCount)
    for orderIndex in countdown(traversalOrder.len - 1, 0):
      let currentNode = traversalOrder[orderIndex]
      var requiredChildren = 0
      var subtreeLength: int64 = 0
      var chainResult = true
      var pathResult = true
      var edgeIndex = edgeHead[currentNode]
      while edgeIndex != absentNode:
        let neighborNode = edgeTo[edgeIndex]
        if parentNode[neighborNode] == currentNode:
          if edgeWeight[edgeIndex] + downReach[neighborNode] > radiusValue:
            requiredChildren += 1
            subtreeLength = subtreeLength + int64(edgeWeight[edgeIndex]) + requiredLength[neighborNode]
            if not chainFits[neighborNode]:
              chainResult = false
              pathResult = false
        edgeIndex = edgeNext[edgeIndex]
      requiredLength[currentNode] = subtreeLength
      chainFits[currentNode] = (requiredChildren <= 1) and chainResult
      pathFits[currentNode] = (requiredChildren <= 2) and pathResult
    for nodeIndex in 0 .. nodeCount - 1:
      if outsideReach[nodeIndex] <= radiusValue and pathFits[nodeIndex] and requiredLength[nodeIndex] <= int64(pathBudget):
        return true
    return false
```

A top node may force two children.
An inner node may force only one.
`int64` holds the summed path length.

**Binary search and driver.** Each radius costs one linear pass.

```nim
  var lowerBound = 0
  var upperBound = downReach[0]
  while lowerBound < upperBound:
    let middleValue = (lowerBound + upperBound) div 2
    if canCover(middleValue):
      upperBound = middleValue
    else:
      lowerBound = middleValue + 1
  appendOutput($lowerBound)
  outputBuffer.add '\n'

for testIndex in 0 .. testCount - 1:
  solveCase()

stdout.write outputBuffer
outputBuffer.setLen 0
```

The root alone gives the upper bound.
Feasibility is monotone in the radius.
One final write flushes every answer.

## Complexity

Preprocessing runs once per case; the binary search repeats a linear check.

| phase | time | space |
|---|---|---|
| input read | one pass over edge tokens | one input string |
| reach preprocessing | two passes over N nodes and edges | four arrays of N values |
| radius checks | O(N) per binary step | three arrays of N values |
| output | one buffered line per case | block buffer |

The binary search needs about 27 checks for the largest budget.

| measure | Big O |
|---|---|
| time | O(N log S) per case |
| space | O(N) per case |

Checking every node pair and every path would cost O(N^2) or worse. Forced-edge checks are the takeaway.
