## Problem

Read a directed weighted graph and a list of queries for each test case. Each query names a start town, an end town, and a rank. Print the length of that ranked shortest route, or -1 when no route exists. Routes may revisit towns, so the route list is infinite whenever a reachable cycle exists.

The judge bounds are listed below.

| Quantity | Bound |
| --- | --- |
| Test cases | at most 15 |
| Towns per case | 1 to 100 |
| Roads per case | 0 to n² - n |
| Road length | 1 to 500 |
| Queries per case | 1 to 10000 |
| Rank | 1 to 100 |
| Time limit | 5000 ms |
| Memory limit | 1536 MB |

The town count and the rank set the size of the search.

## Idea

Precompute shortest route lengths for every town pair, up to the largest rank asked. Answer each query with one array lookup. For one start town, settle partial walks in increasing length and keep the best lengths seen at each town. A walk that already ranks below the k-th length at a town cannot improve that town, so the program discards it. Enumerating walks without this cutoff never ends, because cycles create longer walks forever.

Cost per settled walk: one bucket step and one pass over its outgoing roads.

## Why It Works

Every road has positive length, so extending a walk never shortens it. The unsettled walk with the smallest length is safe to settle next. Each town stores its best lengths in ascending order, and the last entry is the cutoff.

candidate length = settled length + road length

settled length is the length of the walk taken from the queue.
road length is the weight of one outgoing road from that walk's end town.
cutoff is the last stored length for the target town, once it holds k entries.

The queue uses buckets because road lengths are small integers. Every pending length stays within the longest road length of the current length. A power-of-two bucket count covers that window, and each bucket holds one length.

The generator writes the statement sample. The program prints these answers for town 1 to town 3.

    5
    8
    10

The three routes have lengths 5, 8, and 10, so ranks one through three return those values.

## Code

The input is read once into one buffer, and the output is flushed in blocks.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

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

The read loop runs once per input line, so stdin is read once.
nextInt skips non-digits and builds each value digit by digit.
appendOutput writes a block when the buffer reaches the flush size.
Parsing costs O(input bytes).

The buckets hold candidate walks grouped by length.

```nim
proc bucketPush(distance, vertex: int) {.inline.} =
  let slot = bucketSlotCount
  bucketSlotCount += 1
  bucketVertex[slot] = vertex
  let bucket = distance and bucketMask
  bucketNext[slot] = bucketHead[bucket]
  bucketHead[bucket] = slot
  bucketEntryCount += 1

proc bucketPop() {.inline.} =
  while bucketHead[currentDistance and bucketMask] == -1:
    currentDistance += 1
  let bucket = currentDistance and bucketMask
  let slot = bucketHead[bucket]
  bucketHead[bucket] = bucketNext[slot]
  poppedVertex = bucketVertex[slot]
  bucketEntryCount -= 1
```

bucketPush appends a walk to the bucket for its length.
bucketPop advances the current length until a bucket is nonempty.
Each operation costs O(1) time, because the bucket index is a mask.
Pending lengths stay inside one mask window.

insertLabel keeps each town's best lengths sorted and tracks the smallest cutoff.

```nim
proc recomputeMinWorst() {.inline.} =
  minWorst = high(int)
  minWorstVertex = -1
  for vertex in 0 .. nodeCount - 1:
    if labelCount[vertex] == labelLimit:
      let worst = labelList[vertex * labelLimit + labelLimit - 1]
      if worst < minWorst:
        minWorst = worst
        minWorstVertex = vertex

proc insertLabel(vertex, distance: int) {.inline.} =
  let base = vertex * labelLimit
  let count = labelCount[vertex]
  var pos = 0
  while pos < count and labelList[base + pos] < distance:
    pos += 1
  var shift = count
  while shift > pos:
    labelList[base + shift] = labelList[base + shift - 1]
    shift -= 1
  labelList[base + pos] = distance
  labelCount[vertex] = count + 1
  if count == labelLimit:
    if vertex == minWorstVertex:
      recomputeMinWorst()
    elif labelList[base + labelLimit - 1] < minWorst:
      minWorst = labelList[base + labelLimit - 1]
      minWorstVertex = vertex
  elif count + 1 == labelLimit:
    fullCount += 1
    let worst = labelList[base + labelLimit - 1]
    if worst < minWorst:
      minWorst = worst
      minWorstVertex = vertex
```

insertLabel shifts entries to keep the list ascending.
recomputeMinWorst scans all towns after the smallest cutoff changes.
A full town stores exactly k lengths, so the loop bound is the rank.

solveSource grows the walks from one start town.

```nim
proc solveSource(source: int) =
  for bucket in 0 .. bucketModulus - 1:
    bucketHead[bucket] = -1
  for vertex in 0 .. nodeCount - 1:
    labelCount[vertex] = 0
  bucketSlotCount = 0
  bucketEntryCount = 0
  currentDistance = 0
  fullCount = 0
  minWorst = high(int)
  minWorstVertex = -1
  bucketPush(0, source)
  while bucketEntryCount > 0:
    bucketPop()
    let distance = currentDistance
    let vertex = poppedVertex
    if distance > 0:
      let base = vertex * labelLimit
      let count = labelCount[vertex]
      if count == labelLimit and distance >= labelList[base + labelLimit - 1]:
        continue
      insertLabel(vertex, distance)
    if fullCount == nodeCount and distance + 1 >= minWorst:
      continue
    var edge = adjStart[vertex]
    let edgeEnd = adjStart[vertex + 1]
    while edge < edgeEnd:
      let target = adjTo[edge]
      let candidate = distance + adjWeight[edge]
      let targetBase = target * labelLimit
      let targetCount = labelCount[target]
      if targetCount < labelLimit or candidate < labelList[targetBase + labelLimit - 1]:
        bucketPush(candidate, target)
      edge += 1
  for vertex in 0 .. nodeCount - 1:
    let answerBase = (source * nodeCount + vertex) * labelLimit
    let labelBase = vertex * labelLimit
    for idx in 0 .. labelLimit - 1:
      answerTable[answerBase + idx] = -1
    for idx in 0 .. labelCount[vertex] - 1:
      answerTable[answerBase + idx] = labelList[labelBase + idx]
```

The outer loop ends when no candidate walk remains.
The cutoff test skips a settled walk that cannot improve any town.
Each settled walk relaxes its outgoing roads once.
One source costs O(km) relaxations and O(nk) stored lengths.

The main loop stores the graph, reads queries, and writes answers.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIdx in 0 .. caseCount - 1:
  nodeCount = nextInt(inputData, scanPos)
  edgeCount = nextInt(inputData, scanPos)
  adjStart.setLen(nodeCount + 1)
  adjFill.setLen(nodeCount)
  rawSource.setLen(edgeCount)
  rawTo.setLen(edgeCount)
  rawWeight.setLen(edgeCount)
  for vertex in 0 .. nodeCount - 1:
    adjFill[vertex] = 0
  weightBound = 1
  for edge in 0 .. edgeCount - 1:
    let fromTown = nextInt(inputData, scanPos) - 1
    let toTown = nextInt(inputData, scanPos) - 1
    let roadLength = nextInt(inputData, scanPos)
    rawSource[edge] = fromTown
    rawTo[edge] = toTown
    rawWeight[edge] = roadLength
    adjFill[fromTown] += 1
    if roadLength > weightBound:
      weightBound = roadLength
  adjStart[0] = 0
  for vertex in 0 .. nodeCount - 1:
    adjStart[vertex + 1] = adjStart[vertex] + adjFill[vertex]
    adjFill[vertex] = adjStart[vertex]
  adjTo.setLen(edgeCount)
  adjWeight.setLen(edgeCount)
  for edge in 0 .. edgeCount - 1:
    let slot = adjFill[rawSource[edge]]
    adjFill[rawSource[edge]] += 1
    adjTo[slot] = rawTo[edge]
    adjWeight[slot] = rawWeight[edge]
  bucketModulus = 1
  while bucketModulus <= weightBound:
    bucketModulus = bucketModulus shl 1
  bucketMask = bucketModulus - 1
  let queryCount = nextInt(inputData, scanPos)
  queryFrom.setLen(queryCount)
  queryTo.setLen(queryCount)
  queryRank.setLen(queryCount)
  labelLimit = 0
  for query in 0 .. queryCount - 1:
    queryFrom[query] = nextInt(inputData, scanPos) - 1
    queryTo[query] = nextInt(inputData, scanPos) - 1
    queryRank[query] = nextInt(inputData, scanPos)
    if queryRank[query] > labelLimit:
      labelLimit = queryRank[query]
  labelCount.setLen(nodeCount)
  labelList.setLen(nodeCount * labelLimit)
  answerTable.setLen(nodeCount * nodeCount * labelLimit)
  bucketHead.setLen(bucketModulus)
  let slotCapacity = (labelLimit + 1) * (edgeCount + 1) + nodeCount + 10
  bucketVertex.setLen(slotCapacity)
  bucketNext.setLen(slotCapacity)
  for source in 0 .. nodeCount - 1:
    solveSource(source)
  if caseIdx > 0:
    outputBuffer.add '\n'
  for query in 0 .. queryCount - 1:
    let answerPos = (queryFrom[query] * nodeCount + queryTo[query]) * labelLimit +
                    queryRank[query] - 1
    appendOutput($answerTable[answerPos])
    outputBuffer.add '\n'
```

The first loop counts roads per town and finds the longest road.
The second loop places roads into contiguous ranges.
Each query reads one answer from the table.
The program prints up to 150000 lines, which the output buffer writes in blocks.

## Complexity

Reading and parsing cost O(input bytes). Building the road ranges costs O(n + m) per case. One source settles at most k walks per town, so it performs O(km) relaxations with O(1) bucket work. All n sources cost O(nkm) time. The labels use O(nk) space and the answer table uses O(n²k) space. Naive walk enumeration runs forever when a cycle is reachable.
