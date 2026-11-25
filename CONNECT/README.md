# CONNECT — Connections (SPOJ)

<https://www.spoj.com/problems/CONNECT/>

## Problem

A directed road network connects towns, and each query names two towns and a rank k. Find the length of the k-th shortest walk, counting walks that revisit towns.

Input: one integer for the case count, then n and m per case. Then come m roads as `u v length` and q queries as `u v rank`. Cases print a blank line between them.

Output: the length of the ranked route for each query, or `-1` when no such route exists.

The statement and judge give these bounds:

| Item | Bound |
| --- | --- |
| Test cases | at most 15 |
| Towns per case | 1 to 100 |
| Roads per case | 0 to n² - n |
| Road length | 1 to 500 |
| Queries per case | 1 to 10000 |
| Rank | 1 to 100 |
| Time limit | 5000 ms |
| Memory limit | 1536 MB |

The town count and the largest rank set the search size.

The sample input and output:

```
1

5 5
1 2 3
2 3 2
3 2 1
1 3 10
1 4 1
8
1 3 1
1 3 2
1 3 3
1 4 2
2 5 1
2 2 1
2 2 2
1 1 2
```

```
5
8
10
-1
-1
3
6
-1
```

## Idea

Keep a sorted shortlist of the best few routes to every town, like posting only the fastest few times for each destination. Once a route is worse than the shortlist's last entry, it can never improve that town.

The program runs a ranked shortest-path search from each town. A bucket queue settles partial walks in increasing length, and each town stores only its k best lengths. Queries then read one cell from a precomputed table.

Each settled walk relaxes its outgoing roads once, so one source costs O(km) work. Enumerating walks without the cutoff never stops, because a reachable cycle creates longer walks forever.

The cutoff makes an infinite route set finite in practice.

## Why It Works

Positive road lengths make the ranked search well behaved.

1. Extending a walk never shortens it, so settling the smallest pending length first is safe.
2. Each town keeps its best k lengths in ascending order. The last one is the cutoff.
3. A walk that already reaches its town with k shorter lengths cannot enter that shortlist.
4. A bucket queue indexes lengths by a power-of-two mask, so push and pop take constant work.

The formulas used in the search are as follows:

| Term | Meaning |
| --- | --- |
| candidate length | settled length + road length |
| cutoff | last stored length at the target town |
| bucket index | length modulo `bucketModulus` |
| answer index | `(source × n + target) × k + rank - 1` |

Every pending length stays within one longest road of the current length, so a small bucket ring covers it.

A script settles walks from town 1 in the sample:

```
settled length  town  action
0               1     source
1               4     label 1 accepted
3               2     label 3 accepted
5               3     label 5 accepted
6               2     label 6 accepted
8               3     label 8 accepted
9               2     label 9 accepted
10              3     label 10 accepted
11              3     skipped by cutoff
```

The answers for town 1 to town 3 at ranks 1, 2, and 3 are 5, 8, and 10.

## Code

**Input and output helpers.** One buffer holds the stream, and the output flushes in blocks.

```nim
{.push warning[Deprecated]: off.}
{.define: release.}
{.pop.}
{.push checks: off.}
{.passC: "-O3".}

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

The read loop visits every input line once. The scanner skips non-digits, so blank lines need no special case. The writer flushes at 256 KiB.

**Shared arrays.** The graph, the labels, and the buckets are allocated once and resized per case.

```nim
var nodeCount = 0
var edgeCount = 0
var adjStart: seq[int] = @[]
var adjFill: seq[int] = @[]
var adjTo: seq[int] = @[]
var adjWeight: seq[int] = @[]
var rawSource: seq[int] = @[]
var rawTo: seq[int] = @[]
var rawWeight: seq[int] = @[]

var labelLimit = 0
var labelCount: seq[int] = @[]
var labelList: seq[int] = @[]
var answerTable: seq[int] = @[]

var weightBound = 1
var bucketModulus = 2
var bucketMask = 1
var bucketHead: seq[int] = @[]
var bucketVertex: seq[int] = @[]
var bucketNext: seq[int] = @[]
var bucketSlotCount = 0
var bucketEntryCount = 0
var currentDistance = 0
var poppedVertex = 0
var fullCount = 0
var minWorst = 0
var minWorstVertex = -1
```

`adjStart` holds one range start per town. `labelList` holds the k best lengths per town. Reusing the arrays avoids a large allocation inside the case loop.

**Bucket queue.** Each bucket holds one length, and an empty ring advances the current length.

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

`bucketPush` appends a walk to the bucket for its length. `bucketPop` advances until a bucket is nonempty. Each operation costs constant work because the index is a mask.

**Shortlist insertion.** Labels stay sorted, and the smallest cutoff is tracked for early exit.

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

`insertLabel` shifts entries to keep the list ascending. `recomputeMinWorst` scans all towns when the smallest cutoff changes. A full town holds exactly k labels, so the loop bound is the rank.

**One source.** The search stops when no candidate can improve any shortlist.

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

The outer loop ends when no candidate walk remains. The cutoff test skips a settled walk that cannot improve a town. Each settled walk relaxes its outgoing roads once, and the table copy writes k cells per town.

**Main loop.** The program stores roads in contiguous ranges, then answers queries by lookup.

```nim
var queryFrom: seq[int] = @[]
var queryTo: seq[int] = @[]
var queryRank: seq[int] = @[]

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

stdout.write outputBuffer
outputBuffer.setLen 0
```

The first road loop counts outgoing roads and finds the longest length. The second loop places roads into contiguous ranges. The rank sets `labelLimit`, so no work is spent on unasked ranks. Each query reads one table cell.

## Complexity

One source settles at most k walks per town and relaxes each outgoing road once.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over input bytes | input bytes |
| Road ranges | O(n + m) per case | O(n + m) |
| Ranked search | O(nkm) per case | O(nk) labels |
| Answer table | O(n²k) per case | O(n²k) |
| Output | one write per 256 KiB block | 256 KiB |
| Total per case | O(nkm + n²k) | O(n²k) |

At the largest case, the table holds about one million integers.

The asymptotic bounds are as follows:

| Measure | Big O |
| --- | --- |
| Time | O(nkm + n²k) per case |
| Space | O(n²k) per case |

Enumerating walks without a cutoff runs forever once a cycle is reachable.
