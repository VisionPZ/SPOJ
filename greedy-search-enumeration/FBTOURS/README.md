<https://www.spoj.com/problems/FBTOURS/>

## Problem

A tour from building X to building Y leaves O outsiders in every building that lies on some route using each walkway at most once. A sweep of building Z removes and counts its outsiders. Report the total count over all sweeps.

Input starts with T cases. Each case gives N, M, and D, then M walkway pairs, then D events. Event T gives X, Y, and O. Event S gives Z. Output prints one total per case, modulo 1000000007.

| item | bound |
|---|---|
| test cases T | 1 to 20 |
| buildings N | 1 to 100000 |
| walkways M | 1 to 1000000 |
| days D | 1 to 1000000 |
| outsiders per tour O | 1 to 1000 |
| judge limit | 8000 ms, 1536 MB |

A cancelled tour changes nothing. A route may revisit a building but never reuses a walkway.

Sample input:

```
1
6 5 9
1 2
2 3
3 4
4 5
5 3
T 1 2 5
T 5 6 1000
S 2
S 6
T 2 3 1
T 5 3 14
S 1
S 2
S 4
```

Sample output:

```
26
```

## Idea

Cutting bridges turns the map into a tree of rooms, like hallways joining clusters of rooms. Every building in a cluster lies on the same set of tour routes. Add outsiders to whole clusters along the tree path, then track each building's offset so a sweep clears only that building. A search over all trails for each event would be far too slow.

## Why It Works

1. A walkway whose removal splits the graph is a bridge.
2. Removing bridges leaves clusters where any two buildings share a trail.
3. Contracting each cluster gives a tree, and a cancelled tour means two different trees.
4. A tour adds outsiders to every cluster on the tree path between its endpoints.
5. A sweep reads a building's cluster total plus its own offset.
6. After a sweep, the offset cancels that cluster total, so the building reads zero.
7. Heavy-light decomposition splits each tree path into a few base-array intervals.

| term | meaning |
|---|---|
| `bridgeMark` | flags bridges and their reverse arcs |
| `componentOf` | cluster id of each building |
| `treeRoot` | root of the tree holding a building |
| `chainHead` | top component of a heavy-light chain |
| `basePosition` | array slot of a component |
| `bitTree` | Fenwick tree with range add and point sum |
| `buildingOffset` | per-building adjustment after sweeps |
| `totalEscorted` | running answer modulo 1000000007 |

In the sample, tour 1-2 leaves 5 in buildings 1 and 2. The tour from 5 to 6 is cancelled. Sweeps of 2 and 6 count 5 and 0. Tour 2-3 adds 1 to buildings 2, 3, 4, and 5. Tour 5-3 adds 14 to buildings 3, 4, and 5. The last sweeps count 5, 1, and 15, giving 26.

## Code

**Input and helpers.** The reader parses numbers and event letters directly.

```nim
const flushBlockBytes = 1 shl 17
const moduloValue = 1000000007

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

proc reverseArc(arc: int): int =
  if (arc mod 2) == 1:
    return arc + 1
  return arc - 1

proc nextEvent(data: string, pos: var int): char =
  while pos < data.len and data[pos] != 'T' and data[pos] != 'S':
    pos += 1
  result = data[pos]
  pos += 1

proc fenwickAdd(bit: var seq[int], index: int, value: int) =
  var position = index
  while position < bit.len:
    bit[position] = (bit[position] + value) mod moduloValue
    position += position and (-position)

proc fenwickSum(bit: seq[int], index: int): int =
  var position = index
  var total = 0
  while position > 0:
    total = (total + bit[position]) mod moduloValue
    position -= position and (-position)
  return total

proc addRange(bit: var seq[int], leftIndex: int, rightIndex: int, value: int) =
  fenwickAdd(bit, leftIndex, value)
  let negated = if value == 0: 0 else: moduloValue - value
  fenwickAdd(bit, rightIndex + 1, negated)
```

Arc ids come in consecutive pairs.
The event reader stops at the next T or S.
The Fenwick tree supports range add and point sum.

**Bridge search.** An iterative depth-first walk finds every bridge.

```nim
let testCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCount - 1:
  let buildingCount = nextInt(inputData, scanPos)
  let walkwayCount = nextInt(inputData, scanPos)
  let eventCount = nextInt(inputData, scanPos)
  var firstArc = newSeq[int](buildingCount + 1)
  var arcTarget = newSeq[int](2 * walkwayCount + 2)
  var nextArc = newSeq[int](2 * walkwayCount + 2)
  var arcCount = 0
  for walkwayIndex in 0 .. walkwayCount - 1:
    let leftBuilding = nextInt(inputData, scanPos)
    let rightBuilding = nextInt(inputData, scanPos)
    arcCount += 1
    arcTarget[arcCount] = rightBuilding
    nextArc[arcCount] = firstArc[leftBuilding]
    firstArc[leftBuilding] = arcCount
    arcCount += 1
    arcTarget[arcCount] = leftBuilding
    nextArc[arcCount] = firstArc[rightBuilding]
    firstArc[rightBuilding] = arcCount
  var discoveryTime = newSeq[int](buildingCount + 1)
  var lowLink = newSeq[int](buildingCount + 1)
  var parentBuilding = newSeq[int](buildingCount + 1)
  var parentWalkway = newSeq[int](buildingCount + 1)
  var bridgeMark = newSeq[int](2 * walkwayCount + 2)
  var treeRoot = newSeq[int](buildingCount + 1)
  var stackBuildings = newSeq[int](buildingCount + 1)
  var stackArcs = newSeq[int](buildingCount + 1)
  var timerValue = 0
  for startBuilding in 1 .. buildingCount:
    if discoveryTime[startBuilding] != 0:
      continue
    timerValue += 1
    discoveryTime[startBuilding] = timerValue
    lowLink[startBuilding] = timerValue
    treeRoot[startBuilding] = startBuilding
    parentBuilding[startBuilding] = 0
    parentWalkway[startBuilding] = 0
    var stackTop = 0
    stackTop += 1
    stackBuildings[stackTop] = startBuilding
    stackArcs[stackTop] = firstArc[startBuilding]
    while stackTop > 0:
      let currentBuilding = stackBuildings[stackTop]
      var currentArc = stackArcs[stackTop]
      if currentArc != 0:
        stackArcs[stackTop] = nextArc[currentArc]
        let neighbor = arcTarget[currentArc]
        if parentWalkway[currentBuilding] != 0 and currentArc == reverseArc(parentWalkway[currentBuilding]):
          continue
        if discoveryTime[neighbor] == 0:
          parentBuilding[neighbor] = currentBuilding
          parentWalkway[neighbor] = currentArc
          treeRoot[neighbor] = startBuilding
          timerValue += 1
          discoveryTime[neighbor] = timerValue
          lowLink[neighbor] = timerValue
          stackTop += 1
          stackBuildings[stackTop] = neighbor
          stackArcs[stackTop] = firstArc[neighbor]
        else:
          if discoveryTime[neighbor] < lowLink[currentBuilding]:
            lowLink[currentBuilding] = discoveryTime[neighbor]
      else:
        stackTop -= 1
        if stackTop > 0:
          let parentNode = stackBuildings[stackTop]
          if lowLink[currentBuilding] < lowLink[parentNode]:
            lowLink[parentNode] = lowLink[currentBuilding]
          if lowLink[currentBuilding] > discoveryTime[parentNode]:
            let bridgeArc = parentWalkway[currentBuilding]
            bridgeMark[bridgeArc] = 1
            bridgeMark[reverseArc(bridgeArc)] = 2
```

Each undirected walkway gets two arcs.
A child with a larger low link marks its parent arc as a bridge.
The root of each walk identifies disconnected tours.

**Clusters and chains.** Bridge removal yields clusters, and heavy-light decomposition lays the cluster tree into one array.

```nim
  var componentOf = newSeq[int](buildingCount + 1)
  var buildQueue = newSeq[int](buildingCount + 1)
  var componentCount = 0
  for startBuilding in 1 .. buildingCount:
    if componentOf[startBuilding] != 0:
      continue
    componentCount += 1
    var queueHead = 0
    var queueTail = 0
    queueTail += 1
    buildQueue[queueTail] = startBuilding
    componentOf[startBuilding] = componentCount
    while queueHead < queueTail:
      queueHead += 1
      let currentBuilding = buildQueue[queueHead]
      var currentArc = firstArc[currentBuilding]
      while currentArc != 0:
        if bridgeMark[currentArc] == 0:
          let neighbor = arcTarget[currentArc]
          if componentOf[neighbor] == 0:
            componentOf[neighbor] = componentCount
            queueTail += 1
            buildQueue[queueTail] = neighbor
        currentArc = nextArc[currentArc]
  var treeFirst = newSeq[int](componentCount + 1)
  var treeTarget = newSeq[int](2 * componentCount + 2)
  var treeNext = newSeq[int](2 * componentCount + 2)
  var treeArcCount = 0
  for arc in 1 .. arcCount:
    if bridgeMark[arc] == 1:
      let leftComponent = componentOf[arcTarget[arc]]
      let rightComponent = componentOf[arcTarget[reverseArc(arc)]]
      treeArcCount += 1
      treeTarget[treeArcCount] = rightComponent
      treeNext[treeArcCount] = treeFirst[leftComponent]
      treeFirst[leftComponent] = treeArcCount
      treeArcCount += 1
      treeTarget[treeArcCount] = leftComponent
      treeNext[treeArcCount] = treeFirst[rightComponent]
      treeFirst[rightComponent] = treeArcCount
  var treeParent = newSeq[int](componentCount + 1)
  var treeDepth = newSeq[int](componentCount + 1)
  var traversalOrder = newSeq[int](componentCount + 1)
  var componentStack = newSeq[int](componentCount + 1)
  var orderSize = 0
  for rootComponent in 1 .. componentCount:
    if treeParent[rootComponent] != 0:
      continue
    treeParent[rootComponent] = rootComponent
    var stackTop = 0
    stackTop += 1
    componentStack[stackTop] = rootComponent
    while stackTop > 0:
      let currentComponent = componentStack[stackTop]
      stackTop -= 1
      orderSize += 1
      traversalOrder[orderSize] = currentComponent
      var arc = treeFirst[currentComponent]
      while arc != 0:
        let neighbor = treeTarget[arc]
        if neighbor != treeParent[currentComponent] and treeParent[neighbor] == 0:
          treeParent[neighbor] = currentComponent
          treeDepth[neighbor] = treeDepth[currentComponent] + 1
          stackTop += 1
          componentStack[stackTop] = neighbor
        arc = treeNext[arc]
  var subtreeSize = newSeq[int](componentCount + 1)
  var heavyChild = newSeq[int](componentCount + 1)
  for componentIndex in 1 .. componentCount:
    subtreeSize[componentIndex] = 1
  for orderIndex in countdown(orderSize, 1):
    let currentComponent = traversalOrder[orderIndex]
    var arc = treeFirst[currentComponent]
    while arc != 0:
      let neighbor = treeTarget[arc]
      if treeParent[neighbor] == currentComponent:
        subtreeSize[currentComponent] += subtreeSize[neighbor]
        if subtreeSize[neighbor] > subtreeSize[heavyChild[currentComponent]]:
          heavyChild[currentComponent] = neighbor
      arc = treeNext[arc]
  var chainHead = newSeq[int](componentCount + 1)
  var basePosition = newSeq[int](componentCount + 1)
  var chainStack = newSeq[int](componentCount + 1)
  var baseIndex = 0
  for rootComponent in 1 .. componentCount:
    if chainHead[rootComponent] != 0:
      continue
    var stackTop = 0
    stackTop += 1
    chainStack[stackTop] = rootComponent
    chainHead[rootComponent] = rootComponent
    while stackTop > 0:
      let chainRoot = chainStack[stackTop]
      stackTop -= 1
      var currentComponent = chainRoot
      while currentComponent != 0:
        baseIndex += 1
        basePosition[currentComponent] = baseIndex
        chainHead[currentComponent] = chainRoot
        var arc = treeFirst[currentComponent]
        while arc != 0:
          let neighbor = treeTarget[arc]
          if treeParent[neighbor] == currentComponent and neighbor != heavyChild[currentComponent]:
            stackTop += 1
            chainStack[stackTop] = neighbor
            chainHead[neighbor] = neighbor
          arc = treeNext[arc]
        currentComponent = heavyChild[currentComponent]
```

Bridges become edges of the cluster tree.
A reverse-order pass finds the largest child of each cluster.
Each heavy path occupies one consecutive stretch of base positions.

**Events.** Tours add to paths, and sweeps read one building.

```nim
  var bitTree = newSeq[int](componentCount + 2)
  var buildingOffset = newSeq[int](buildingCount + 1)
  var totalEscorted = 0
  for eventIndex in 0 .. eventCount - 1:
    let eventType = nextEvent(inputData, scanPos)
    if eventType == 'T':
      let tourStart = nextInt(inputData, scanPos)
      let tourEnd = nextInt(inputData, scanPos)
      let outsiderCount = nextInt(inputData, scanPos)
      if treeRoot[tourStart] == treeRoot[tourEnd]:
        let amount = outsiderCount mod moduloValue
        var leftComponent = componentOf[tourStart]
        var rightComponent = componentOf[tourEnd]
        while chainHead[leftComponent] != chainHead[rightComponent]:
          if treeDepth[chainHead[leftComponent]] < treeDepth[chainHead[rightComponent]]:
            swap(leftComponent, rightComponent)
          addRange(bitTree, basePosition[chainHead[leftComponent]], basePosition[leftComponent], amount)
          leftComponent = treeParent[chainHead[leftComponent]]
        if treeDepth[leftComponent] > treeDepth[rightComponent]:
          swap(leftComponent, rightComponent)
        addRange(bitTree, basePosition[leftComponent], basePosition[rightComponent], amount)
    else:
      let sweptBuilding = nextInt(inputData, scanPos)
      let sweptComponent = componentOf[sweptBuilding]
      let groupAmount = fenwickSum(bitTree, basePosition[sweptComponent])
      let foundHere = (groupAmount + buildingOffset[sweptBuilding]) mod moduloValue
      totalEscorted = (totalEscorted + foundHere) mod moduloValue
      buildingOffset[sweptBuilding] = (moduloValue - groupAmount) mod moduloValue
  appendOutput($totalEscorted)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The deepest chain head climbs first.
A cancelled tour leaves the tree untouched.
The offset clears one building without changing its cluster.

## Complexity

Bridge finding and cluster building each visit the graph once.

| phase | time | space |
|---|---|---|
| read walkways | one scan of M pairs | two arcs per walkway |
| bridge search | one visit per building and arc | discovery and stack arrays |
| cluster tree | one visit per building and arc | tree arc arrays |
| chain layout | two passes over the tree | depth, size, and base arrays |
| events | O(log^2 N) per tour or sweep | Fenwick array |

| measure | Big O |
|---|---|
| preprocessing | O(N + M) |
| per tour | O(log^2 N) |
| per sweep | O(log N) |
| space | O(N + M) |

Enumerating every trail for each tour would grow exponentially with the number of walkways. The tree reduces a tour to one path update.
