# NTICKETS — Nlogonian Tickets (SPOJ)

<https://www.spoj.com/problems/NTICKETS/>

## Problem

Find the fewest tickets needed to travel between two cities in a tree. A road demands a given number of tickets, tickets are returned after inspection, and only the largest demand on the path matters.

Each test case starts with city count `N`. The next `N - 1` lines give `A B T` for one road. Then come `Q` query lines with two city numbers. A line containing `0` ends all cases. Print one answer per query and a blank line after every case.

| item | bound |
|---|---|
| cities `N` | 2 to 100000 |
| roads | `N - 1` |
| ticket demand `T` | up to 1000000000 |
| queries `Q` | 1 to 500000 |
| judge limit | 1000 ms, 1536 MB |

```
6
1 2 1
1 3 5
3 4 3
3 5 8
1 6 2
3
2 6
5 2
4 6
0
```

```
2
8
5

```

## Idea

Think of each city as having a stack of snapshots of the road to its ancestor; answering a query pops matching snapshots until both climbers meet. Binary lifting is the algorithm, with the largest edge cost stored beside each ancestor. Each query costs logarithmic time, while walking the path for every query costs linear time.

## Why It Works

1. The road system is a tree, so exactly one path joins two cities.
2. Reused tickets make the answer the maximum edge cost on that path.
3. Lifting a city by `2^level` edges needs one stored table entry per level.
4. Each table entry keeps the maximum cost seen on its upward jump.
5. After aligning depths, climbing both cities together locates their common ancestor path.

| term | meaning |
|---|---|
| `ancestor` | flattened table of ancestors at every power of two |
| `maxEdgeCost` | largest ticket demand on the matching jump |
| `depth` | number of edges from the root city |
| `headEdge` | first adjacency entry for each city |

For the sample query `5 2`, the path runs 5 to 3 to 1 to 2 with demands 8, 5, 1. The largest demand is 8, so eight tickets are enough.

The blank line after each case is written from the same output buffer as the numeric answers.

## Code

**Input and scanning.** All stdin is read once and parsed by a digit scanner.

```nim
const flushBlockBytes = 1 shl 17
const maxLevel = 18

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

The level count 18 covers trees up to 100000 cities.
Adjacency arrays are rebuilt for each case.
Parsing ignores all separators between numbers.

**Tree preprocessing.** An explicit stack assigns parents and fills the lifting tables.

```nim
while true:
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  if scanPos >= inputData.len:
    break
  let cityCount = nextInt(inputData, scanPos)
  if cityCount == 0:
    break
  let edgeCapacity = 2 * (cityCount - 1)
  var headEdge = newSeq[int](cityCount + 1)
  for index in 0 .. cityCount:
    headEdge[index] = -1
  var edgeTarget = newSeq[int](edgeCapacity)
  var edgeNext = newSeq[int](edgeCapacity)
  var edgeCost = newSeq[int](edgeCapacity)
  var edgeCursor = 0
  for roadIndex in 0 .. cityCount - 2:
    let cityA = nextInt(inputData, scanPos)
    let cityB = nextInt(inputData, scanPos)
    let ticketCost = nextInt(inputData, scanPos)
    edgeTarget[edgeCursor] = cityB
    edgeCost[edgeCursor] = ticketCost
    edgeNext[edgeCursor] = headEdge[cityA]
    headEdge[cityA] = edgeCursor
    edgeCursor += 1
    edgeTarget[edgeCursor] = cityA
    edgeCost[edgeCursor] = ticketCost
    edgeNext[edgeCursor] = headEdge[cityB]
    headEdge[cityB] = edgeCursor
    edgeCursor += 1
  var depth = newSeq[int](cityCount + 1)
  var traversalStack = newSeq[int](cityCount)
  var stackSize = 1
  traversalStack[0] = 1
  var ancestor = newSeq[int]((cityCount + 1) * maxLevel)
  var maxEdgeCost = newSeq[int]((cityCount + 1) * maxLevel)
  ancestor[1 * maxLevel] = 0
  maxEdgeCost[1 * maxLevel] = 0
  while stackSize > 0:
    stackSize -= 1
    let currentCity = traversalStack[stackSize]
    var edgeIndex = headEdge[currentCity]
    while edgeIndex != -1:
      let neighborCity = edgeTarget[edgeIndex]
      if neighborCity != ancestor[currentCity * maxLevel]:
        ancestor[neighborCity * maxLevel] = currentCity
        maxEdgeCost[neighborCity * maxLevel] = edgeCost[edgeIndex]
        depth[neighborCity] = depth[currentCity] + 1
        traversalStack[stackSize] = neighborCity
        stackSize += 1
      edgeIndex = edgeNext[edgeIndex]
  for levelIndex in 1 .. maxLevel - 1:
    for cityIndex in 1 .. cityCount:
      let middleCity = ancestor[cityIndex * maxLevel + levelIndex - 1]
      ancestor[cityIndex * maxLevel + levelIndex] = ancestor[middleCity * maxLevel + levelIndex - 1]
      if maxEdgeCost[middleCity * maxLevel + levelIndex - 1] > maxEdgeCost[cityIndex * maxLevel + levelIndex - 1]:
        maxEdgeCost[cityIndex * maxLevel + levelIndex] = maxEdgeCost[middleCity * maxLevel + levelIndex - 1]
      else:
        maxEdgeCost[cityIndex * maxLevel + levelIndex] = maxEdgeCost[cityIndex * maxLevel + levelIndex - 1]
```

Each road is stored in both directions.
The stack avoids deep recursion on long chains.
Table entries combine two smaller jumps into one.

**Queries and output.** Each query lifts the deeper city, then both cities together.

```nim
  let queryCount = nextInt(inputData, scanPos)
  for queryIndex in 0 .. queryCount - 1:
    var cityA = nextInt(inputData, scanPos)
    var cityB = nextInt(inputData, scanPos)
    var answer = 0
    if depth[cityA] < depth[cityB]:
      swap cityA, cityB
    let depthGap = depth[cityA] - depth[cityB]
    for levelIndex in 0 .. maxLevel - 1:
      if (depthGap and (1 shl levelIndex)) != 0:
        let tableIndex = cityA * maxLevel + levelIndex
        if maxEdgeCost[tableIndex] > answer:
          answer = maxEdgeCost[tableIndex]
        cityA = ancestor[tableIndex]
    if cityA != cityB:
      for levelIndex in countdown(maxLevel - 1, 0):
        let tableA = cityA * maxLevel + levelIndex
        let tableB = cityB * maxLevel + levelIndex
        if ancestor[tableA] != ancestor[tableB]:
          if maxEdgeCost[tableA] > answer:
            answer = maxEdgeCost[tableA]
          if maxEdgeCost[tableB] > answer:
            answer = maxEdgeCost[tableB]
          cityA = ancestor[tableA]
          cityB = ancestor[tableB]
      if maxEdgeCost[cityA * maxLevel] > answer:
        answer = maxEdgeCost[cityA * maxLevel]
      if maxEdgeCost[cityB * maxLevel] > answer:
        answer = maxEdgeCost[cityB * maxLevel]
    appendOutput($answer)
    appendOutput("\n")
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The maximum cost accumulates during every jump.
Finally the two edges into the common ancestor are checked.
A newline closes each case after its answers.

## Complexity

| phase | time | space |
|---|---|---|
| tree build | one pass over `N - 1` roads | adjacency arrays |
| lifting table | `N` times 18 levels | two flat tables |
| each query | 18 jump checks | constant |

| measure | Big O |
|---|---|
| preprocessing | O(N log N) |
| queries | O(Q log N) |
| space | O(N log N) |

Walking the tree for each query would cost O(N) per query, far above the lifting bound.

The fixed level count keeps table access fast and handles the largest allowed tree.
