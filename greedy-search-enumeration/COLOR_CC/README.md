# COLOR_CC — Colors (SPOJ)

<https://www.spoj.com/problems/COLOR_CC/>

## Problem

A bipartite graph gives each node a short list of allowed colors. Count the assignments where adjacent nodes never share a color. Print the count for each graph.

The first input value is the test count. Each case gives the node count, the symmetric Y/N matrix, then one line per node with its color count and colors. Print one count per case.

| item | bound |
|---|---|
| tests T | fewer than 20 |
| nodes N | 0 to 13 |
| colors per node | 0 to 8 |
| color number | below 100000 |
| judge limit | 2000 ms, 1536 MB |

No test uses zero nodes, so every case has at least one assignment to count.

Sample input:

```
1
4
NYNN
YNNN
NNNY
NNYN
3 1 2 3
2 4 5
3 4 5 6
3 1 2 3
```

Sample output:

```
54
```

## Idea

Split the graph like sorting socks into two drawers, with no two socks in one drawer touching. Color one drawer first; every node in the other drawer then counts colors unused by its neighbors.

Enumerating the smaller drawer keeps the search short, and multiplying the remaining counts finishes each branch. A full assignment search would try every combination of all nodes.

## Why It Works

1. A bipartite graph splits into two sides with no edges inside either side.
2. Assigning one side fixes which colors are blocked for the other side.
3. Nodes on the other side are independent, so their counts multiply.
4. The smaller side has at most six nodes when both sides are nonempty.
5. An empty side contributes one assignment and reduces the task to a product.

| term | meaning |
|---|---|
| `adjacencyMasks` | bit mask of neighbors for each node |
| `nodeSides` | bipartition side of each node |
| `blockedCounts` | how many assigned neighbors use each color |
| `searchNodes` | nodes assigned by the recursion |

Script-generated trace for the sample case:

| component | nodes | product |
|---|---|---|
| one | 1 and 2 | 3 x 2 = 6 |
| two | 3 and 4 | 3 x 3 = 9 |

The graph splits into two separate edges, so the total is 6 x 9 = 54.

## Code

**Input, scanners, and output buffer.** Matrix rows are read as words of Y and N.

```nim
const flushBlockBytes = 1 shl 17
const adjacencyPresent = 'Y'
const maximumSearchWork = 4000000

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

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and not ((data[pos] >= 'A' and data[pos] <= 'Z') or (data[pos] >= 'a' and data[pos] <= 'z') or (data[pos] >= '0' and data[pos] <= '9')):
    pos += 1
  var wordValue = ""
  while pos < data.len and ((data[pos] >= 'A' and data[pos] <= 'Z') or (data[pos] >= 'a' and data[pos] <= 'z') or (data[pos] >= '0' and data[pos] <= '9')):
    wordValue.add data[pos]
    pos += 1
  return wordValue

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The word scanner skips whitespace between matrix rows.
Integers and words share one input cursor.
Blocking large work estimates keeps the choice cheap.

**Bipartition and recursive count.** The smaller side drives the search.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let nodeCount = nextInt(inputData, scanPos)
  var adjacencyMasks = newSeq[int](nodeCount)
  for rowIndex in 0 .. nodeCount - 1:
    let matrixRow = nextWord(inputData, scanPos)
    for columnIndex in 0 .. nodeCount - 1:
      if columnIndex < matrixRow.len and matrixRow[columnIndex] == adjacencyPresent:
        adjacencyMasks[rowIndex] = adjacencyMasks[rowIndex] or (1 shl columnIndex)
  var nodeSides = newSeq[int](nodeCount)
  for nodeIndex in 0 .. nodeCount - 1:
    nodeSides[nodeIndex] = -1
  for startNode in 0 .. nodeCount - 1:
    if nodeSides[startNode] != -1:
      continue
    nodeSides[startNode] = 0
    var frontier = newSeq[int](nodeCount)
    var frontierEnd = 1
    frontier[0] = startNode
    var frontierStart = 0
    while frontierStart < frontierEnd:
      let currentNode = frontier[frontierStart]
      frontierStart += 1
      for neighbor in 0 .. nodeCount - 1:
        if (adjacencyMasks[currentNode] and (1 shl neighbor)) == 0:
          continue
        if nodeSides[neighbor] == -1:
          nodeSides[neighbor] = 1 - nodeSides[currentNode]
          frontier[frontierEnd] = neighbor
          frontierEnd += 1
  var distinctColors = newSeq[int](0)
  var nodeColorIndices = newSeq[seq[int]](nodeCount)
  for nodeIndex in 0 .. nodeCount - 1:
    let colorTotal = nextInt(inputData, scanPos)
    var colorIndices = newSeq[int](colorTotal)
    for colorSlot in 0 .. colorTotal - 1:
      let colorValue = nextInt(inputData, scanPos)
      var colorIndex = -1
      for knownIndex in 0 .. distinctColors.len - 1:
        if distinctColors[knownIndex] == colorValue:
          colorIndex = knownIndex
          break
      if colorIndex == -1:
        colorIndex = distinctColors.len
        distinctColors.add colorValue
      colorIndices[colorSlot] = colorIndex
    nodeColorIndices[nodeIndex] = colorIndices
  let colorCount = distinctColors.len
  var blockedCounts = newSeq[int](nodeCount * colorCount)
  var sideZeroWork: int64 = 1
  var sideOneWork: int64 = 1
  for nodeIndex in 0 .. nodeCount - 1:
    let choices = nodeColorIndices[nodeIndex].len
    if nodeSides[nodeIndex] == 0:
      sideZeroWork = sideZeroWork * int64(choices)
    else:
      sideOneWork = sideOneWork * int64(choices)
    if sideZeroWork > maximumSearchWork:
      sideZeroWork = int64(maximumSearchWork)
    if sideOneWork > maximumSearchWork:
      sideOneWork = int64(maximumSearchWork)
  let searchSide = if sideZeroWork <= sideOneWork: 0 else: 1
  var searchNodes = newSeq[int](nodeCount)
  var countNodes = newSeq[int](nodeCount)
  var searchCount = 0
  var countTotal = 0
  for nodeIndex in 0 .. nodeCount - 1:
    if nodeSides[nodeIndex] == searchSide:
      searchNodes[searchCount] = nodeIndex
      searchCount += 1
    else:
      countNodes[countTotal] = nodeIndex
      countTotal += 1
  var totalWays: int64 = 0

  proc explore(searchDepth: int) =
    if searchDepth == searchCount:
      var ways: int64 = 1
      for countIndex in 0 .. countTotal - 1:
        let nodeIndex = countNodes[countIndex]
        var available = 0
        for colorIndex in nodeColorIndices[nodeIndex]:
          if blockedCounts[nodeIndex * colorCount + colorIndex] == 0:
            available += 1
        ways = ways * int64(available)
      totalWays = totalWays + ways
      return
    let nodeIndex = searchNodes[searchDepth]
    for colorIndex in nodeColorIndices[nodeIndex]:
      var changedNodes = newSeq[int](nodeCount)
      var changedCount = 0
      for neighbor in 0 .. nodeCount - 1:
        if (adjacencyMasks[nodeIndex] and (1 shl neighbor)) == 0:
          continue
        let slot = neighbor * colorCount + colorIndex
        changedNodes[changedCount] = neighbor
        changedCount += 1
        blockedCounts[slot] += 1
      explore(searchDepth + 1)
      for changedIndex in 0 .. changedCount - 1:
        blockedCounts[changedNodes[changedIndex] * colorCount + colorIndex] -= 1

  explore(0)
  appendOutput($totalWays)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

A breadth-first walk builds the two sides.
Backtracking restores every blocked count after a branch.
The leaf multiplication gives the count for that branch.

## Complexity

The enumeration follows the smaller bipartition side.

| phase | time | space |
|---|---|---|
| matrix parse | O(N^2) characters | one mask per node |
| bipartition | O(N^2) | one side label per node |
| recursion | up to 8^(N/2) leaves | one count per node and color |

| measure | Big O |
|---|---|
| time | O(N^2 + 8^(N/2) x N) |
| space | O(N^2) |

Testing all N node colors would reach 8^N leaves.

Narrowing the search to one side removes the repeated checks.
