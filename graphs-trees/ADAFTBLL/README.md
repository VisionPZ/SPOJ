# ADAFTBLL — Ada and Football (SPOJ)

<https://www.spoj.com/problems/ADAFTBLL/>

## Problem

Friends sit on a tree and each supports a team. For a trip between two friends, report how many happy pairs form when each friend hears about earlier friends on the same team. Team changes also arrive as queries.

The first line gives N and Q. The next line gives N team ids. The next N minus one lines give tree edges. Later lines are either a team change or a trip. Print one answer per trip.

| item | bound |
|---|---|
| friends N | 1 to 10 to the 5 |
| queries Q | 1 to 10 to the 5 |
| team id | 0 to 10 to the 5 |
| judge limit | 3000 ms, 1536 MB |

Both counts drive the design; each trip needs its own answer.

Sample input:

```
7 8
0 0 1 2 1 1 2
0 1
1 5
1 2
2 4
2 3
3 6
2 4 5
2 0 6
2 1 3
1 1 2
1 2 2
2 4 5
2 0 6
2 1 3
```

Sample output:

```
3
2
0
2
6
3
```

## Idea

Unroll the tree into a line and slide a window while stepping through time, like replaying a film with a movable frame. An Euler tour turns each trip into one line segment plus one optional node. Team counts update happiness in constant time when a node enters or leaves. Offline sorting by left, right and time blocks keeps pointer moves small. Walking the whole path for every trip costs far more. One moving frame answers every trip.

## Why It Works

1. A friend met at position i hears about earlier friends with the same team, so a team with c friends contributes c times c minus one over two.
2. `eulerTour` lists each node at entry and exit; a contiguous segment marks exactly the path nodes, with the common ancestor handled by `extraNode`.
3. `tourPositions` and `exitPositions` convert the two trip ends into that segment.
4. `ancestorTable` finds the common ancestor by lifting the deeper node first.
5. `teamCounts` tracks how many active nodes support each team; adding a node raises `happiness` by that count.
6. `applyUpdate` and `revertUpdate` keep `workingTeams` at the right moment in query order.
7. `comesEarlier` sorts trips by left block, right block and time block to bound all pointer moves.

| term | meaning |
|---|---|
| `eulerTour` | entry and exit sequence of every node |
| `ancestorTable` | binary lifting table for common ancestors |
| `teamCounts` | active nodes per team |
| `happiness` | current sum of choose two per team |
| `updateEvents` | team changes with their old and new values |
| `treeQueries` | sorted trip requests with segment bounds |
| `activeNodes` | membership of each node in the current path |

The table names the state carried by the moving window.

A script trace of the first sample trip, from friend 4 to friend 5:

| node on trip | team | friends of that team seen before | added happiness |
|---|---|---|---|
| 4 | 1 | 0 | 0 |
| 2 | 1 | 1 | 1 |
| 1 | 0 | 0 | 0 |
| 5 | 1 | 2 | 2 |

The additions sum to three, which matches the first sample answer.

Moving a pointer costs one add or remove, never a path scan.

## Code

**Input and helpers.** The reader parses queries, and binary lifting supports ancestor lookup.

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

type
  UpdateEvent = object
    targetNode: int
    oldTeam: int
    newTeam: int
  TreeQuery = object
    startNode: int
    finishNode: int
    rangeLeft: int
    rangeRight: int
    extraNode: int
    timeIndex: int
    answerIndex: int

proc findLca(firstNode: int, secondNode: int, depths: seq[int], ancestorTable: seq[int], logCount: int): int =
  var nodeOne = firstNode
  var nodeTwo = secondNode
  if depths[nodeOne] < depths[nodeTwo]:
    let swapNode = nodeOne
    nodeOne = nodeTwo
    nodeTwo = swapNode
  var depthGap = depths[nodeOne] - depths[nodeTwo]
  for level in 0 .. logCount - 1:
    if (depthGap and (1 shl level)) != 0:
      nodeOne = ancestorTable[nodeOne * logCount + level]
  if nodeOne == nodeTwo:
    return nodeOne
  for levelIndex in 0 .. logCount - 1:
    let level = logCount - 1 - levelIndex
    if ancestorTable[nodeOne * logCount + level] != ancestorTable[nodeTwo * logCount + level]:
      nodeOne = ancestorTable[nodeOne * logCount + level]
      nodeTwo = ancestorTable[nodeTwo * logCount + level]
  return ancestorTable[nodeOne * logCount]

proc comesEarlier(firstQuery: TreeQuery, secondQuery: TreeQuery, blockSize: int): bool =
  let firstLeftBlock = firstQuery.rangeLeft div blockSize
  let secondLeftBlock = secondQuery.rangeLeft div blockSize
  if firstLeftBlock != secondLeftBlock:
    return firstLeftBlock < secondLeftBlock
  let firstRightBlock = firstQuery.rangeRight div blockSize
  let secondRightBlock = secondQuery.rangeRight div blockSize
  if firstRightBlock != secondRightBlock:
    return firstRightBlock < secondRightBlock
  return firstQuery.timeIndex < secondQuery.timeIndex

proc sortQueries(queryList: var seq[TreeQuery], lowIndex: int, highIndex: int, blockSize: int) =
  if lowIndex >= highIndex:
    return
  let pivotQuery = queryList[(lowIndex + highIndex) div 2]
  var leftIndex = lowIndex
  var rightIndex = highIndex
  while leftIndex <= rightIndex:
    while comesEarlier(queryList[leftIndex], pivotQuery, blockSize):
      leftIndex += 1
    while comesEarlier(pivotQuery, queryList[rightIndex], blockSize):
      rightIndex -= 1
    if leftIndex <= rightIndex:
      let swapQuery = queryList[leftIndex]
      queryList[leftIndex] = queryList[rightIndex]
      queryList[rightIndex] = swapQuery
      leftIndex += 1
      rightIndex -= 1
  if lowIndex < rightIndex:
    sortQueries(queryList, lowIndex, rightIndex, blockSize)
  if leftIndex < highIndex:
    sortQueries(queryList, leftIndex, highIndex, blockSize)
```

The tree is read after the team list.
The comparator orders trips by three block keys.
Sorting runs in place before the sweep.

**Window state changes.** Each toggle changes team counts and happiness together.

```nim
proc addTeam(teamIndex: int, teamCounts: var seq[int], happiness: var int64) =
  happiness = happiness + int64(teamCounts[teamIndex])
  teamCounts[teamIndex] = teamCounts[teamIndex] + 1

proc removeTeam(teamIndex: int, teamCounts: var seq[int], happiness: var int64) =
  teamCounts[teamIndex] = teamCounts[teamIndex] - 1
  happiness = happiness - int64(teamCounts[teamIndex])

proc toggleTourNode(nodeIndex: int, workingTeams: seq[int], activeNodes: var seq[bool], teamCounts: var seq[int], happiness: var int64) =
  let teamIndex = workingTeams[nodeIndex]
  if activeNodes[nodeIndex]:
    removeTeam(teamIndex, teamCounts, happiness)
    activeNodes[nodeIndex] = false
  else:
    addTeam(teamIndex, teamCounts, happiness)
    activeNodes[nodeIndex] = true

proc applyUpdate(event: UpdateEvent, workingTeams: var seq[int], activeNodes: seq[bool], teamCounts: var seq[int], happiness: var int64) =
  if workingTeams[event.targetNode] != event.newTeam:
    if activeNodes[event.targetNode]:
      removeTeam(workingTeams[event.targetNode], teamCounts, happiness)
    workingTeams[event.targetNode] = event.newTeam
    if activeNodes[event.targetNode]:
      addTeam(event.newTeam, teamCounts, happiness)

proc revertUpdate(event: UpdateEvent, workingTeams: var seq[int], activeNodes: seq[bool], teamCounts: var seq[int], happiness: var int64) =
  if workingTeams[event.targetNode] != event.oldTeam:
    if activeNodes[event.targetNode]:
      removeTeam(workingTeams[event.targetNode], teamCounts, happiness)
    workingTeams[event.targetNode] = event.oldTeam
    if activeNodes[event.targetNode]:
      addTeam(event.oldTeam, teamCounts, happiness)
```

A toggle flips membership of exactly one node.
An active node changes team by removing the old one and adding the new one.
Reverting uses the old team stored when the query was read.

**Query parsing.** Each change records its previous team, and each trip records its moment in time.

```nim
let friendCount = nextInt(inputData, scanPos)
let queryCount = nextInt(inputData, scanPos)
var initialTeams = newSeq[int](friendCount)
var workingTeams = newSeq[int](friendCount)
var maximumTeam = 0
for friendIndex in 0 .. friendCount - 1:
  let teamIndex = nextInt(inputData, scanPos)
  initialTeams[friendIndex] = teamIndex
  workingTeams[friendIndex] = teamIndex
  if teamIndex > maximumTeam:
    maximumTeam = teamIndex

var adjacency = newSeq[seq[int]](friendCount)
for edgeIndex in 0 .. friendCount - 2:
  let endpointOne = nextInt(inputData, scanPos)
  let endpointTwo = nextInt(inputData, scanPos)
  adjacency[endpointOne].add endpointTwo
  adjacency[endpointTwo].add endpointOne

var updateEvents = newSeq[UpdateEvent](queryCount)
var treeQueries = newSeq[TreeQuery](queryCount)
var updateCount = 0
var answerCount = 0
for queryIndex in 0 .. queryCount - 1:
  let queryType = nextInt(inputData, scanPos)
  if queryType == 1:
    let targetNode = nextInt(inputData, scanPos)
    let newTeam = nextInt(inputData, scanPos)
    updateEvents[updateCount].targetNode = targetNode
    updateEvents[updateCount].oldTeam = workingTeams[targetNode]
    updateEvents[updateCount].newTeam = newTeam
    workingTeams[targetNode] = newTeam
    updateCount += 1
    if newTeam > maximumTeam:
      maximumTeam = newTeam
  else:
    treeQueries[answerCount].startNode = nextInt(inputData, scanPos)
    treeQueries[answerCount].finishNode = nextInt(inputData, scanPos)
    treeQueries[answerCount].timeIndex = updateCount
    treeQueries[answerCount].answerIndex = answerCount
    treeQueries[answerCount].extraNode = -1
    answerCount += 1
```

The parse pass simulates changes to learn each old team.
Trips keep their original index for ordered output.
The time index counts changes seen so far.

**Euler tour.** An iterative walk records entry and exit positions with ancestor data.

```nim
var logCount = 1
while (1 shl logCount) <= friendCount:
  logCount += 1
var tourPositions = newSeq[int](friendCount)
var exitPositions = newSeq[int](friendCount)
var eulerTour = newSeq[int](2 * friendCount)
var ancestorTable = newSeq[int](friendCount * logCount)
var depths = newSeq[int](friendCount)
var parents = newSeq[int](friendCount)
var stackNodes = newSeq[int](friendCount + 1)
var stackEdges = newSeq[int](friendCount + 1)
var stackTop = 0
stackNodes[stackTop] = 0
stackEdges[stackTop] = 0
stackTop = 1
var tourLength = 0
while stackTop > 0:
  stackTop -= 1
  let currentNode = stackNodes[stackTop]
  let edgeIndex = stackEdges[stackTop]
  if edgeIndex == 0:
    tourPositions[currentNode] = tourLength
    eulerTour[tourLength] = currentNode
    tourLength += 1
  if edgeIndex < adjacency[currentNode].len:
    let neighborNode = adjacency[currentNode][edgeIndex]
    stackNodes[stackTop] = currentNode
    stackEdges[stackTop] = edgeIndex + 1
    stackTop += 1
    if neighborNode != parents[currentNode]:
      parents[neighborNode] = currentNode
      depths[neighborNode] = depths[currentNode] + 1
      ancestorTable[neighborNode * logCount] = currentNode
      for level in 1 .. logCount - 1:
        let halfAncestor = ancestorTable[neighborNode * logCount + level - 1]
        ancestorTable[neighborNode * logCount + level] = ancestorTable[halfAncestor * logCount + level - 1]
      stackNodes[stackTop] = neighborNode
      stackEdges[stackTop] = 0
      stackTop += 1
  else:
    exitPositions[currentNode] = tourLength
    eulerTour[tourLength] = currentNode
    tourLength += 1
```

The stack avoids deep recursion on long chains.
Each node is written twice, at entry and exit.
Ancestor rows are built as nodes are discovered.

**Segment conversion and ordering.** A common ancestor either sits at the segment start or needs a separate toggle.

```nim
for queryIndex in 0 .. answerCount - 1:
  var startNode = treeQueries[queryIndex].startNode
  var finishNode = treeQueries[queryIndex].finishNode
  if tourPositions[startNode] > tourPositions[finishNode]:
    let swapNode = startNode
    startNode = finishNode
    finishNode = swapNode
  let commonNode = findLca(startNode, finishNode, depths, ancestorTable, logCount)
  if commonNode == startNode:
    treeQueries[queryIndex].rangeLeft = tourPositions[startNode]
    treeQueries[queryIndex].rangeRight = tourPositions[finishNode]
  else:
    treeQueries[queryIndex].rangeLeft = exitPositions[startNode]
    treeQueries[queryIndex].rangeRight = tourPositions[finishNode]
    treeQueries[queryIndex].extraNode = commonNode

let blockSize = friendCount div 32 + 1
sortQueries(treeQueries, 0, answerCount - 1, blockSize)
```

Entry order decides which end is first.
The extra node is toggled only while its answer is read.
The quicksort partitions around a middle pivot.

**Sweep and output.** Three pairs of pointers move through space and time.

```nim
var activeNodes = newSeq[bool](friendCount)
var teamCounts = newSeq[int](maximumTeam + 2)
var happiness: int64 = 0
for friendIndex in 0 .. friendCount - 1:
  workingTeams[friendIndex] = initialTeams[friendIndex]
var answers = newSeq[int64](answerCount)
var currentTime = 0
var currentLeft = 0
var currentRight = -1

for queryIndex in 0 .. answerCount - 1:
  let currentQuery = treeQueries[queryIndex]
  while currentTime < currentQuery.timeIndex:
    applyUpdate(updateEvents[currentTime], workingTeams, activeNodes, teamCounts, happiness)
    currentTime += 1
  while currentTime > currentQuery.timeIndex:
    currentTime -= 1
    revertUpdate(updateEvents[currentTime], workingTeams, activeNodes, teamCounts, happiness)
  while currentLeft > currentQuery.rangeLeft:
    currentLeft -= 1
    toggleTourNode(eulerTour[currentLeft], workingTeams, activeNodes, teamCounts, happiness)
  while currentRight < currentQuery.rangeRight:
    currentRight += 1
    toggleTourNode(eulerTour[currentRight], workingTeams, activeNodes, teamCounts, happiness)
  while currentLeft < currentQuery.rangeLeft:
    toggleTourNode(eulerTour[currentLeft], workingTeams, activeNodes, teamCounts, happiness)
    currentLeft += 1
  while currentRight > currentQuery.rangeRight:
    toggleTourNode(eulerTour[currentRight], workingTeams, activeNodes, teamCounts, happiness)
    currentRight -= 1
  if currentQuery.extraNode >= 0:
    toggleTourNode(currentQuery.extraNode, workingTeams, activeNodes, teamCounts, happiness)
    answers[currentQuery.answerIndex] = happiness
    toggleTourNode(currentQuery.extraNode, workingTeams, activeNodes, teamCounts, happiness)
  else:
    answers[currentQuery.answerIndex] = happiness

for answerValue in answers:
  appendOutput($answerValue)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Time is adjusted before the segment so active nodes see correct teams.
The empty start has left at zero and right at minus one.
Answers are stored by original index and written once at the end.

## Complexity

Sorted trips move the two tour pointers and the time pointer; each move is one team update.

| phase | time | space |
|---|---|---|
| input read | one pass over Q queries | two arrays of Q records |
| Euler tour | one pass over N nodes | N log N ancestors |
| ordered sweep | bounded pointer moves | one team count array |
| output | one line per trip | block buffer |

Each tour position flips often, but block sorting bounds the total flips.

| measure | Big O |
|---|---|
| time | O((N + Q) to the five thirds) |
| space | O(N log N + Q + maximum team) |

Walking the full path for every trip would cost far more on long paths.

One sorted sweep handles both team changes and trip answers with constant-time updates.
