## Problem

Read several test cases. Each case lists the number of houses, streets, and clients, then the client houses, then the street pairs. The administrator lives in house 1. Every client needs a cable from that house, and two cables of one color cannot use the same street. Print the fewest colors each case needs.

| quantity | bound |
| --- | --- |
| test cases | up to 500 |
| houses | up to 500 |
| clients | at most houses minus one |
| streets | at most every house pair |
| time limit | 4072 ms |
| memory limit | 1536 MB |

The street count drives the running time, and each case prints one line.

## Idea

Binary search the number of colors and test each guess with a flow computation. Give every street the guessed capacity, give each client a unit demand, and push flow toward the administrator. Push-relabel moves surplus flow locally and avoids the repeated searches that slow augmenting-path methods.

Each guess rebuilds four arcs per street; the flow work grows with the arc count and the relabel count.

## Why It Works

One color may cross each street once. With C colors, a street can carry C cables, while each client still needs exactly one unit. The guess C works exactly when the flow network sends one unit to every client. A larger C never breaks a working guess, so the search can halve the interval.

A cut proves the rule. Take any set of houses that contains the administrator. Let q be the clients inside and d the streets leaving the set. Those d streets must carry the other k minus q clients, so C times d must reach k minus q. The answer is the largest such requirement over all house sets.

Push-relabel keeps an excess value at each house. A house sends excess along an arc to a neighbor one level lower. When no such neighbor exists, the house raises its level above the lowest neighbor. A gap in the level counts proves that all taller houses cannot reach the sink, so the program lifts them out of the way. A periodic search from the sink restores exact distances and keeps the levels useful.

A fixed unit-capacity flow gives a wrong shortcut. On the seven-house case in the generator, that flow is 2 and five clients wait, which suggests 3 colors. Capacity 2 already serves all five clients, so the answer is 2.

The index formulas are short:
- `addArc(0, clientList[i], 1)` gives one client one unit of demand.
- `addStreet(edgeFirst[i], edgeSecond[i], capacity)` gives a street the guessed capacity in both directions.
- `enoughColors` returns `pushRelabel(0, 1) == clientList.len`, so only a full flow passes.
- `activeQueue[queueBack mod activeQueue.len]` wraps the queue, so a node can re-enter it safely.

The script-generated example uses the first sample case. Its tested guesses are listed below.

| tested capacity | max flow | serves 4 clients? |
| --- | --- | --- |
| 2 | 4 | yes |
| 1 | 2 | no |

The smallest feasible capacity is 2, which matches the sample answer.

## Code

The scanner reads digits from one input buffer. Each arc stores its reverse beside it, so the partner index is a parity change.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const infiniteFlow = 1 shl 29

var head = newSeq[int](0)
var inHead = newSeq[int](0)
var toNode = newSeq[int](0)
var arcCap = newSeq[int](0)
var nextArc = newSeq[int](0)
var nextIn = newSeq[int](0)
var nodeHeight = newSeq[int](0)
var nodeExcess = newSeq[int](0)
var gapCount = newSeq[int](0)
var nodeDistance = newSeq[int](0)
var iterArc = newSeq[int](0)
var inQueue = newSeq[bool](0)
var activeQueue = newSeq[int](0)
var relabelQueue = newSeq[int](0)
var clientList = newSeq[int](0)
var edgeFirst = newSeq[int](0)
var edgeSecond = newSeq[int](0)
var arcCount = 0
var nodeCount = 0
var queueFront = 0
var queueBack = 0
var pushCounter = 0

proc nextInt(data: string, scanPos: var int): int =
  while scanPos < data.len and (data[scanPos] < '0' or data[scanPos] > '9'):
    scanPos += 1
  result = 0
  while scanPos < data.len and data[scanPos] >= '0' and data[scanPos] <= '9':
    result = result * 10 + (int(data[scanPos]) - firstDigitValue)
    scanPos += 1

proc reverseArcIndex(arcIndex: int): int =
  if arcIndex mod 2 == 0: arcIndex + 1 else: arcIndex - 1

proc addArc(fromNode, targetNode, capacity: int) =
  toNode[arcCount] = targetNode
  arcCap[arcCount] = capacity
  nextArc[arcCount] = head[fromNode]
  head[fromNode] = arcCount
  nextIn[arcCount] = inHead[targetNode]
  inHead[targetNode] = arcCount
  arcCount += 1
  toNode[arcCount] = fromNode
  arcCap[arcCount] = 0
  nextArc[arcCount] = head[targetNode]
  head[targetNode] = arcCount
  nextIn[arcCount] = inHead[fromNode]
  inHead[fromNode] = arcCount
  arcCount += 1

proc addStreet(firstHouse, secondHouse, capacity: int) =
  addArc(firstHouse, secondHouse, capacity)
  addArc(secondHouse, firstHouse, capacity)
```

The scanner loops over digits, so it builds no token strings. Two calls to `addArc` make a street usable in both directions. Each street costs four stored arcs, and `inHead` tracks arcs that enter a house.

The queue wraps around because a house can receive surplus more than once. The search from the sink walks incoming arcs and resets the levels. The gap step moves houses that cannot reach the sink above the useful range.

```nim
proc enqueueNode(nodeIndex: int) =
  if nodeIndex != 0 and nodeIndex != 1 and not inQueue[nodeIndex]:
    inQueue[nodeIndex] = true
    activeQueue[queueBack mod activeQueue.len] = nodeIndex
    queueBack += 1

proc globalRelabel(sinkNode: int) =
  for i in 0..nodeCount: nodeDistance[i] = -1
  var front = 0
  var back = 0
  nodeDistance[sinkNode] = 0
  relabelQueue[back] = sinkNode
  back += 1
  while front < back:
    let current = relabelQueue[front]
    front += 1
    var arcIndex = inHead[current]
    while arcIndex != -1:
      let previous = toNode[reverseArcIndex(arcIndex)]
      if arcCap[arcIndex] > 0 and nodeDistance[previous] == -1:
        nodeDistance[previous] = nodeDistance[current] + 1
        relabelQueue[back] = previous
        back += 1
      arcIndex = nextIn[arcIndex]
  for i in 0..nodeCount:
    let newHeight = if nodeDistance[i] == -1: nodeCount + 1 else: nodeDistance[i]
    if newHeight != nodeHeight[i]:
      gapCount[nodeHeight[i]] -= 1
      nodeHeight[i] = newHeight
      gapCount[nodeHeight[i]] += 1

proc relabelNode(nodeIndex: int) =
  let oldHeight = nodeHeight[nodeIndex]
  var minimum = infiniteFlow
  var arcIndex = head[nodeIndex]
  while arcIndex != -1:
    if arcCap[arcIndex] > 0:
      let neighbor = toNode[arcIndex]
      if nodeHeight[neighbor] < minimum: minimum = nodeHeight[neighbor]
    arcIndex = nextArc[arcIndex]
  gapCount[oldHeight] -= 1
  nodeHeight[nodeIndex] = minimum + 1
  gapCount[nodeHeight[nodeIndex]] += 1
  if gapCount[oldHeight] == 0 and oldHeight <= nodeCount:
    for i in 0..nodeCount:
      if nodeHeight[i] > oldHeight and nodeHeight[i] <= nodeCount:
        gapCount[nodeHeight[i]] -= 1
        nodeHeight[i] = nodeCount + 1
        gapCount[nodeHeight[i]] += 1
```

`enqueueNode` writes through a modulo index, which keeps the queue inside its array. `globalRelabel` visits each house once and updates the gap counts. `relabelNode` picks the lowest reachable neighbor, then applies the gap step.

The push-relabel loop starts by saturating every arc out of the source. It then pushes and relabels active houses until their excess disappears.

```nim
proc pushRelabel(sourceNode, sinkNode: int): int =
  queueFront = 0
  queueBack = 0
  pushCounter = 0
  for i in 0..nodeCount:
    nodeExcess[i] = 0
    nodeHeight[i] = 0
    inQueue[i] = false
    iterArc[i] = head[i]
    gapCount[i] = 0
  gapCount[nodeCount + 1] = 0
  gapCount[0] = nodeCount + 1
  nodeHeight[sourceNode] = nodeCount + 1
  gapCount[0] -= 1
  gapCount[nodeCount + 1] += 1
  var arcIndex = head[sourceNode]
  while arcIndex != -1:
    let available = arcCap[arcIndex]
    if available > 0:
      arcCap[arcIndex] = 0
      arcCap[reverseArcIndex(arcIndex)] += available
      let neighbor = toNode[arcIndex]
      nodeExcess[neighbor] += available
      enqueueNode(neighbor)
    arcIndex = nextArc[arcIndex]
  while queueFront < queueBack:
    let current = activeQueue[queueFront mod activeQueue.len]
    queueFront += 1
    inQueue[current] = false
    while nodeExcess[current] > 0:
      var edgeIndex = iterArc[current]
      while edgeIndex != -1:
        let neighbor = toNode[edgeIndex]
        if arcCap[edgeIndex] > 0 and nodeHeight[neighbor] + 1 == nodeHeight[current]:
          let amount = min(nodeExcess[current], arcCap[edgeIndex])
          arcCap[edgeIndex] -= amount
          arcCap[reverseArcIndex(edgeIndex)] += amount
          nodeExcess[current] -= amount
          nodeExcess[neighbor] += amount
          enqueueNode(neighbor)
          pushCounter += 1
          if nodeExcess[current] == 0: break
        edgeIndex = nextArc[edgeIndex]
      iterArc[current] = edgeIndex
      if nodeExcess[current] > 0:
        if iterArc[current] == -1:
          if pushCounter mod (nodeCount * 4 + 1) == 0: globalRelabel(sinkNode)
          relabelNode(current)
          iterArc[current] = head[current]
        else:
          iterArc[current] = nextArc[iterArc[current]]
  return nodeExcess[sinkNode]

proc enoughColors(capacity: int): bool =
  for i in 0..nodeCount:
    head[i] = -1
    inHead[i] = -1
  arcCount = 0
  for i in 0..<clientList.len:
    addArc(0, clientList[i], 1)
  for i in 0..<edgeFirst.len:
    addStreet(edgeFirst[i], edgeSecond[i], capacity)
  return pushRelabel(0, 1) == clientList.len
```

The sink excess is the flow value, and `enoughColors` compares it with the client count. Each guess resets only the heads and the arc count, so the arc arrays stay allocated. The wraparound queue keeps repeated enqueues safe.

The main loop reads one case at a time and halves the color interval.

```nim
let inputData = stdin.readAll()
var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""

for caseIndex in 0..<caseCount:
  let houseCount = nextInt(inputData, scanPos)
  let streetCount = nextInt(inputData, scanPos)
  let clientCount = nextInt(inputData, scanPos)
  nodeCount = houseCount
  if head.len <= houseCount:
    head.setLen(houseCount + 1)
    inHead.setLen(houseCount + 1)
    nodeHeight.setLen(houseCount + 1)
    nodeExcess.setLen(houseCount + 1)
    nodeDistance.setLen(houseCount + 1)
    iterArc.setLen(houseCount + 1)
    inQueue.setLen(houseCount + 1)
    activeQueue.setLen(houseCount + 2)
    relabelQueue.setLen(houseCount + 2)
  if gapCount.len < 2 * houseCount + 4: gapCount.setLen(2 * houseCount + 4)
  let neededArcs = 4 * streetCount + 2 * clientCount + 4
  if toNode.len < neededArcs:
    toNode.setLen(neededArcs)
    arcCap.setLen(neededArcs)
    nextArc.setLen(neededArcs)
    nextIn.setLen(neededArcs)
  clientList.setLen(clientCount)
  for i in 0..<clientCount: clientList[i] = nextInt(inputData, scanPos)
  edgeFirst.setLen(streetCount)
  edgeSecond.setLen(streetCount)
  for i in 0..<streetCount:
    edgeFirst[i] = nextInt(inputData, scanPos)
    edgeSecond[i] = nextInt(inputData, scanPos)
  var lowerBound = 0
  var upperBound = clientCount + 1
  while upperBound - lowerBound > 1:
    let middle = (lowerBound + upperBound) div 2
    if enoughColors(middle): upperBound = middle
    else: lowerBound = middle
  outputBuffer.add($upperBound)
  outputBuffer.add('\n')
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
```

The arrays grow only when a larger case arrives, so later cases reuse the same memory. Clients and streets are stored once, before the guesses begin. The buffer flushes once it passes the block size, and one final write emits the rest.

## Complexity

Reading costs time linear in the number of integers. Storing the case costs O(streets plus clients). Each guess rebuilds O(streets plus clients) arcs, and push-relabel spends O(houses plus arcs) work per relabel phase. The search makes O(log clients) guesses.

Total time is O(test cases times log clients times relabel phases times (houses plus arcs)). Space is O(houses plus arcs) for the network arrays. Testing every color count in increasing order would repeat far more flow computations.
