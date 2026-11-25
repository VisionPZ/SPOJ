# AR2015PC — Terrorists (SPOJ)

<https://www.spoj.com/problems/AR2015PC/>

## Problem

A road network has N intersections and M roads, where M is close to N. Terrorists travel along shortest routes from a meeting point to a destination. Answer many such route queries per test case.

The first line holds the test count. Each case starts with N, M and Q, then M roads given as U, V and D, then Q query pairs. Print `Case x:` followed by one distance per query.

| item | bound |
|---|---|
| test cases | 1 to 5 |
| intersections N | 1 to 100000 |
| roads M | N-1 to N+50 |
| queries Q | 1 to 50000 |
| judge limit | 1000 ms, 1536 MB |

The small excess of roads over a tree shapes the algorithm.

Sample input:

```
1
7 9 5
7 6 6114
5 3 5473
2 4 2601
5 4 8525
7 3 291
2 7 3363
1 6 399
6 4 4477
1 7 3075
6 3
4 4
3 1
2 3
7 3
```

Sample output:

```
Case 1:
3765
0
3366
3654
291
```

## Idea

Think of the roads as a tree with a handful of shortcuts, like a rail map with only a few express lines. A shortest route either stays in the tree or enters a shortcut at one of its endpoints. Only those endpoints need a full shortest-path search.

Build a spanning tree with union-find and keep the non-tree roads as shortcuts. Answer the pure tree route by binary-lifting LCA. Run Dijkstra once from every useful shortcut endpoint, then combine those tables with the tree distance.

## Why It Works

1. Every road that joins two existing components belongs to the spanning tree.
2. The remaining roads number at most 51, so their endpoints form a small set.
3. Any shortest route using a shortcut passes through one of those endpoints.
4. Splitting that route at the endpoint gives two shortest sub-routes.
5. A tree route has distance found from ancestor distances at the LCA.
6. The minimum of all candidates is the required shortest distance.

| term | meaning |
|---|---|
| `specialNodes` | endpoints of shortcuts that improve a tree route |
| `rootDistances` | weighted distance from the root to each node |
| `liftTable` | ancestor table for binary lifting |
| `distanceTables` | one Dijkstra table per special node |

The shortcut endpoints cover every route that leaves the tree.

A script-generated trace from the sample case:

```
query 7 3: tree route 291, shortcut routes none, answer 291
query 6 3: tree route 9755, via node 1 399+291+3075, answer 3765
query 3 1: tree route 3366, no shorter shortcut, answer 3366
```

Each answer is the smallest distance among the candidates.

## Code

**Input and shared structures.** The scanner and global graph arrays serve all cases.

```nim
const flushBlockBytes = 1 shl 17
const infinityDistance = 1 shl 60
const liftLevels = 17

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

The scan skips arbitrary whitespace between tokens.
The buffer flushes in large blocks.
The lifting level count covers one hundred thousand nodes.

**Tree distance.** A spanning tree gives ancestor queries and weighted distances.

```nim
var nodeCount = 0
var graphHead = newSeq[int](0)
var graphTo = newSeq[int](0)
var graphNext = newSeq[int](0)
var graphWeight = newSeq[int](0)
var treeHead = newSeq[int](0)
var treeTo = newSeq[int](0)
var treeNext = newSeq[int](0)
var treeWeight = newSeq[int](0)
var nodeDepths = newSeq[int](0)
var rootDistances = newSeq[int](0)
var liftTable = newSeq[seq[int]](0)
var unionParent = newSeq[int](0)

proc findRoot(nodeIndex: int): int =
  var currentNode = nodeIndex
  while unionParent[currentNode] != currentNode:
    unionParent[currentNode] = unionParent[unionParent[currentNode]]
    currentNode = unionParent[currentNode]
  return currentNode

proc lowestCommonAncestor(firstNode: int, secondNode: int): int =
  var firstWalker = firstNode
  var secondWalker = secondNode
  if nodeDepths[firstWalker] < nodeDepths[secondWalker]:
    swap firstWalker, secondWalker
  var depthGap = nodeDepths[firstWalker] - nodeDepths[secondWalker]
  var levelIndex = 0
  while depthGap > 0:
    if (depthGap and 1) != 0:
      firstWalker = liftTable[levelIndex][firstWalker]
    depthGap = depthGap div 2
    levelIndex += 1
  if firstWalker == secondWalker:
    return firstWalker
  for levelIndex in countdown(liftLevels, 0):
    if liftTable[levelIndex][firstWalker] != liftTable[levelIndex][secondWalker]:
      firstWalker = liftTable[levelIndex][firstWalker]
      secondWalker = liftTable[levelIndex][secondWalker]
  return liftTable[0][firstWalker]

proc treeDistance(firstNode: int, secondNode: int): int =
  let meetingNode = lowestCommonAncestor(firstNode, secondNode)
  return rootDistances[firstNode] + rootDistances[secondNode] - 2 * rootDistances[meetingNode]
```

Union-find selects the tree roads while reading.
Root distances carry the road weights.
LCA alignment uses the depth table.

**Shortest-path table.** Dijkstra runs once per shortcut endpoint.

```nim
proc shortestDistances(sourceNode: int): seq[int] =
  var distances = newSeq[int](nodeCount + 1)
  for nodeIndex in 0 .. nodeCount:
    distances[nodeIndex] = infinityDistance
  var heapNodes = newSeq[int](1)
  var heapPriorities = newSeq[int](1)
  heapNodes[0] = sourceNode
  heapPriorities[0] = 0
  distances[sourceNode] = 0
  while heapNodes.len > 0:
    let currentNode = heapNodes[0]
    let currentDistance = heapPriorities[0]
    let lastNode = heapNodes[heapNodes.len - 1]
    let lastPriority = heapPriorities[heapPriorities.len - 1]
    heapNodes.setLen(heapNodes.len - 1)
    heapPriorities.setLen(heapPriorities.len - 1)
    if heapNodes.len > 0:
      var position = 0
      while true:
        let leftChild = 2 * position + 1
        if leftChild >= heapNodes.len:
          break
        let rightChild = leftChild + 1
        var smallerChild = leftChild
        if rightChild < heapNodes.len and heapPriorities[rightChild] < heapPriorities[leftChild]:
          smallerChild = rightChild
        if heapPriorities[smallerChild] >= lastPriority:
          break
        heapNodes[position] = heapNodes[smallerChild]
        heapPriorities[position] = heapPriorities[smallerChild]
        position = smallerChild
      heapNodes[position] = lastNode
      heapPriorities[position] = lastPriority
    if currentDistance != distances[currentNode]:
      continue
    var edgeIndex = graphHead[currentNode]
    while edgeIndex != -1:
      let neighborNode = graphTo[edgeIndex]
      let candidateDistance = currentDistance + graphWeight[edgeIndex]
      if candidateDistance < distances[neighborNode]:
        distances[neighborNode] = candidateDistance
        var position = heapNodes.len
        heapNodes.add neighborNode
        heapPriorities.add candidateDistance
        while position > 0:
          let parentPosition = (position - 1) div 2
          if heapPriorities[parentPosition] <= candidateDistance:
            break
          heapNodes[position] = heapNodes[parentPosition]
          heapPriorities[position] = heapPriorities[parentPosition]
          position = parentPosition
        heapNodes[position] = neighborNode
        heapPriorities[position] = candidateDistance
      edgeIndex = graphNext[edgeIndex]
  return distances
```

The heap holds pairs of node and tentative distance.
Stale entries are skipped on pop.
Each table is reused for every query in the case.

**Case driver.** Tree construction, LCA fill, and query answers live here.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  nodeCount = nextInt(inputData, scanPos)
  let roadCount = nextInt(inputData, scanPos)
  let planCount = nextInt(inputData, scanPos)

  graphHead = newSeq[int](nodeCount + 1)
  treeHead = newSeq[int](nodeCount + 1)
  for nodeIndex in 1 .. nodeCount:
    graphHead[nodeIndex] = -1
    treeHead[nodeIndex] = -1
  graphTo = newSeq[int](2 * roadCount)
  graphNext = newSeq[int](2 * roadCount)
  graphWeight = newSeq[int](2 * roadCount)
  treeTo = newSeq[int](2 * max(0, nodeCount - 1))
  treeNext = newSeq[int](2 * max(0, nodeCount - 1))
  treeWeight = newSeq[int](2 * max(0, nodeCount - 1))
  unionParent = newSeq[int](nodeCount + 1)
  for nodeIndex in 1 .. nodeCount:
    unionParent[nodeIndex] = nodeIndex

  var graphEdgeCount = 0
  var treeEdgeCount = 0
  var extraFrom = newSeq[int](0)
  var extraTo = newSeq[int](0)
  var extraWeight = newSeq[int](0)
  for roadIndex in 0 .. roadCount - 1:
    let roadFrom = nextInt(inputData, scanPos)
    let roadTo = nextInt(inputData, scanPos)
    let roadLength = nextInt(inputData, scanPos)
    graphTo[graphEdgeCount] = roadTo
    graphWeight[graphEdgeCount] = roadLength
    graphNext[graphEdgeCount] = graphHead[roadFrom]
    graphHead[roadFrom] = graphEdgeCount
    graphEdgeCount += 1
    graphTo[graphEdgeCount] = roadFrom
    graphWeight[graphEdgeCount] = roadLength
    graphNext[graphEdgeCount] = graphHead[roadTo]
    graphHead[roadTo] = graphEdgeCount
    graphEdgeCount += 1
    let fromRoot = findRoot(roadFrom)
    let toRoot = findRoot(roadTo)
    if fromRoot != toRoot:
      unionParent[fromRoot] = toRoot
      treeTo[treeEdgeCount] = roadTo
      treeWeight[treeEdgeCount] = roadLength
      treeNext[treeEdgeCount] = treeHead[roadFrom]
      treeHead[roadFrom] = treeEdgeCount
      treeEdgeCount += 1
      treeTo[treeEdgeCount] = roadFrom
      treeWeight[treeEdgeCount] = roadLength
      treeNext[treeEdgeCount] = treeHead[roadTo]
      treeHead[roadTo] = treeEdgeCount
      treeEdgeCount += 1
    else:
      extraFrom.add roadFrom
      extraTo.add roadTo
      extraWeight.add roadLength

  nodeDepths = newSeq[int](nodeCount + 1)
  rootDistances = newSeq[int](nodeCount + 1)
  liftTable = newSeq[seq[int]](liftLevels + 1)
  for levelIndex in 0 .. liftLevels:
    liftTable[levelIndex] = newSeq[int](nodeCount + 1)
  var traversalStack = newSeq[int](1)
  traversalStack[0] = 1
  liftTable[0][1] = 1
  while traversalStack.len > 0:
    let currentNode = traversalStack[traversalStack.len - 1]
    traversalStack.setLen(traversalStack.len - 1)
    var edgeIndex = treeHead[currentNode]
    while edgeIndex != -1:
      let neighborNode = treeTo[edgeIndex]
      if neighborNode != liftTable[0][currentNode]:
        liftTable[0][neighborNode] = currentNode
        nodeDepths[neighborNode] = nodeDepths[currentNode] + 1
        rootDistances[neighborNode] = rootDistances[currentNode] + treeWeight[edgeIndex]
        traversalStack.add neighborNode
      edgeIndex = treeNext[edgeIndex]
  for levelIndex in 1 .. liftLevels:
    for nodeIndex in 1 .. nodeCount:
      let middleNode = liftTable[levelIndex - 1][nodeIndex]
      liftTable[levelIndex][nodeIndex] = liftTable[levelIndex - 1][middleNode]

  var specialNodes = newSeq[int](0)
  for extraIndex in 0 .. extraFrom.len - 1:
    if extraWeight[extraIndex] < treeDistance(extraFrom[extraIndex], extraTo[extraIndex]):
      var fromSeen = false
      var toSeen = false
      for specialIndex in 0 .. specialNodes.len - 1:
        if specialNodes[specialIndex] == extraFrom[extraIndex]:
          fromSeen = true
        if specialNodes[specialIndex] == extraTo[extraIndex]:
          toSeen = true
      if not fromSeen:
        specialNodes.add extraFrom[extraIndex]
      if not toSeen:
        specialNodes.add extraTo[extraIndex]

  var distanceTables = newSeq[seq[int]](specialNodes.len)
  for specialIndex in 0 .. specialNodes.len - 1:
    distanceTables[specialIndex] = shortestDistances(specialNodes[specialIndex])

  appendOutput("Case " & $caseIndex & ":")
  outputBuffer.add '\n'
  for planIndex in 0 .. planCount - 1:
    let meetNode = nextInt(inputData, scanPos)
    let targetNode = nextInt(inputData, scanPos)
    var bestDistance = treeDistance(meetNode, targetNode)
    for specialIndex in 0 .. specialNodes.len - 1:
      let viaSpecial = distanceTables[specialIndex][meetNode] + distanceTables[specialIndex][targetNode]
      if viaSpecial < bestDistance:
        bestDistance = viaSpecial
    appendOutput($bestDistance)
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Shortcut endpoints are collected only when a shortcut helps.
Queries read after the tables are ready.
Each answer compares the tree route with all endpoint routes.

## Complexity

The spanning tree and LCA are linear, and Dijkstra runs once per shortcut endpoint.

| phase | time | space |
|---|---|---|
| input read | one pass over roads and queries | one input string |
| tree build and LCA | one union-find and one tree traversal | ancestor table |
| Dijkstra tables | one heap search per useful shortcut endpoint | one distance table per endpoint |
| query loop | one comparison per endpoint per query | block buffer |

The number of useful shortcuts stays at most 51.

| measure | Big O |
|---|---|
| time | O(M log N + K (M log N) + Q K), K is at most 102 |
| space | O(N log N + K N) |

Running Dijkstra from every intersection would replace K with N and miss the near-tree structure.
