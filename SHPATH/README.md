# SHPATH — The Shortest Path (SPOJ)
<https://www.spoj.com/problems/SHPATH/>

## Problem

Given named cities and positive costs on direct connections, the cost of a path is the sum of its links. Answer the given source-destination pairs with the minimum path cost.

Input: an integer s, then s cases. Each case gives city count n, then for each city a name, neighbor count p, and p pairs of city index and cost. Then come r queries with two names. Output: one cost per query, in input order.

The statement sets these bounds.

| Item | Bound |
| --- | --- |
| Test cases s | at most 10 |
| Cities n | at most 10000 |
| Queries r | at most 100 |
| City name length | at most 10 lowercase letters |
| Cost of any path | at most 200000 |
| Judge time limit | 1500 ms |
| Judge memory limit | 1536 MB |

The path cost bound makes bucket indexing practical.

The sample input:

```
1
4
gdansk
2
2 1
3 3
bydgoszcz
3
1 1
3 1
4 4
torun
3
1 3
2 1
4 1
warszawa
2
2 4
3 1
2
gdansk warszawa
bydgoszcz warszawa
```

The sample output:

```
3
2
```

## Idea

Group questions by their starting city, like a travel desk handling one departure point at a time. One fare map from that city answers all its queries. The program explores outward in cheap-to-expensive order and stops once every target is settled.

It uses Dijkstra with a bucket queue, also called Dial's algorithm. Path costs never exceed 200000, so the distance itself is a bucket index. A bit mask marks which buckets hold work, which lets the scan skip empty distances quickly. Each source runs one Dijkstra pass, so a case costs at most r passes. A heap would replace the buckets with a logarithm per step.

Grouping queries avoids one search per query.

## Why It Works

Four facts carry the program.

1. Cities are numbered from one in the input, so the scanner subtracts one. A hash table maps each name to that internal index.
2. All costs are positive, so Dijkstra settles cities in nondecreasing distance. The first time a target is settled, its distance is final.
3. A bucket holds every city at one distance. The bit mask has one bit per bucket, so finding the next nonempty bucket skips long gaps without a linear scan.
4. Queries sharing a source use one search. The `targetStamp` array counts distinct targets, and the search stops when that count reaches zero.

Each term has one job.

| Term | Meaning |
| --- | --- |
| `bucketHead` | first queued node at a distance |
| `bucketWords` | bit mask of nonempty buckets |
| `distanceValue` | cheapest known cost to a city |
| `targetStamp` | marks the targets of the current source |

Distances are integers, so no rounding occurs. Paths above 200000 are ignored because the statement bounds every valid path.

A script traces the first sample query from gdansk.

```text
gdansk links: torun 3, bydgoszcz 1
settled bydgoszcz at 1
from bydgoszcz: torun at 2, warszawa at 5
settled torun at 2
from torun: warszawa at 3
settled warszawa at 3
answer gdansk -> warszawa = 3
```

The second query from bydgoszcz answers 2 through torun.

## Code

**Line reader and integer scanner.** One line buffer is refilled on demand.

```nim
import tables
import sequtils

const flushBlockBytes = 1 shl 17
const unreachableDistance: int32 = 1000000000
const guaranteedPathCost: int32 = 200000
const bucketTotal = int(guaranteedPathCost) + 2
const wordTotal = (bucketTotal shr 6) + 1

var lineBuffer: string
var i = 0
var inputDone = false

proc refillLine(): bool =
  while true:
    if i < lineBuffer.len: return true
    if inputDone: return false
    if not readLine(stdin, lineBuffer):
      inputDone = true
      lineBuffer.setLen 0
      return false
    lineBuffer.add "\n"
    i = 0

proc skipSpace() =
  while true:
    while i < lineBuffer.len and lineBuffer[i] <= ' ': i = i + 1
    if i < lineBuffer.len: return
    if not refillLine(): return

proc readInt32(): int32 =
  skipSpace()
  var value: int32 = 0
  while i < lineBuffer.len and lineBuffer[i] >= '0' and lineBuffer[i] <= '9':
    value = value * 10 + int32(int(lineBuffer[i]) - 48)
    i = i + 1
  return value
```

`bucketTotal` is 200002, and `wordTotal` is 3126 words of 64 bits. `refillLine` crosses line and blank-line boundaries, so the scanner never misses a token.

**Bit mask lookup.** A table maps a 16-bit chunk to its lowest set bit.

```nim
var wordText: string
var lowBitPosition = newSeq[int](1 shl 16)
var positionProbe = 1
while positionProbe < (1 shl 16):
  var shiftedValue = positionProbe
  var i = 0
  while (shiftedValue and 1) == 0:
    shiftedValue = shiftedValue shr 1
    i = i + 1
  lowBitPosition[positionProbe] = i
  positionProbe = positionProbe + 1
lowBitPosition[0] = 16

proc lowestSetBitPosition(value: uint64): int =
  var chunk = cast[int](value and cast[uint64](0xFFFF))
  if chunk != 0: return lowBitPosition[chunk]
  chunk = cast[int]((value shr 16) and cast[uint64](0xFFFF))
  if chunk != 0: return 16 + lowBitPosition[chunk]
  chunk = cast[int]((value shr 32) and cast[uint64](0xFFFF))
  if chunk != 0: return 32 + lowBitPosition[chunk]
  chunk = cast[int]((value shr 48) and cast[uint64](0xFFFF))
  return 48 + lowBitPosition[chunk]
```

The table is built once at startup. Four chunk lookups find the next set bit in O(1).

**Queue state.** Touched buckets and words leave no stale state.

```nim
var edgeStart: seq[int]
var edgeTarget: seq[int32]
var edgeCost: seq[int32]
var distanceValue: seq[int32]
var bucketHead = repeat(-1, bucketTotal)
var bucketWords: seq[uint64]
var usedDistanceList: seq[int]
var usedWordList: seq[int]
var nodeVertex: seq[int32]
var nodeNext: seq[int]
var nodeTotal = 0
var targetStamp: seq[int]
var searchStamp = 0

proc clearBuckets() =
  for i in usedDistanceList:
    bucketHead[i] = -1
  for j in usedWordList:
    bucketWords[j] = 0

proc enqueueBucket(distance: int32, vertex: int32) =
  var i = int(distance)
  if bucketHead[i] == -1: usedDistanceList.add i
  var j = i shr 6
  if bucketWords[j] == 0: usedWordList.add j
  bucketWords[j] = bucketWords[j] or (cast[uint64](1) shl (i and 63))
  nodeNext[nodeTotal] = bucketHead[i]
  bucketHead[i] = nodeTotal
  nodeVertex[nodeTotal] = vertex
  nodeTotal = nodeTotal + 1
```

`clearBuckets` touches only used buckets, not all 200002. `enqueueBucket` sets one bit and prepends one node, both in O(1).

**Dijkstra pass.** The bit mask skips empty distance rows.

```nim
proc shortestPathsFrom(source: int32, cityCount: int, targetsLeft: var int) =
  for i in 0 .. cityCount - 1: distanceValue[i] = unreachableDistance
  usedDistanceList.setLen 0
  usedWordList.setLen 0
  nodeTotal = 0
  distanceValue[int(source)] = 0
  enqueueBucket(0, source)
  var currentDistance = 0
  while true:
    var i = bucketHead[currentDistance]
    while i >= 0:
      var settledVertex = int(nodeVertex[i])
      i = nodeNext[i]
      if distanceValue[settledVertex] != int32(currentDistance): continue
      if targetStamp[settledVertex] == searchStamp:
        targetStamp[settledVertex] = 0
        targetsLeft = targetsLeft - 1
        if targetsLeft == 0:
          currentDistance = int(guaranteedPathCost) + 1
          break
      var j = edgeStart[settledVertex]
      let walkLimit = edgeStart[settledVertex + 1]
      while j < walkLimit:
        var neighbour = int(edgeTarget[j])
        var candidateDistance = int32(currentDistance) + edgeCost[j]
        if candidateDistance < distanceValue[neighbour] and candidateDistance <= guaranteedPathCost:
          distanceValue[neighbour] = candidateDistance
          enqueueBucket(candidateDistance, int32(neighbour))
        j = j + 1
    if targetsLeft == 0 or currentDistance >= int(guaranteedPathCost): break
    bucketHead[currentDistance] = -1
    var j = (currentDistance + 1) shr 6
    var bitMask = bucketWords[j] and
      not((cast[uint64](1) shl ((currentDistance + 1) and 63)) - 1)
    while true:
      if bitMask != 0: break
      j = j + 1
      if j >= wordTotal: break
      bitMask = bucketWords[j]
    if bitMask == 0:
      currentDistance = int(guaranteedPathCost) + 1
      break
    currentDistance = (j shl 6) + lowestSetBitPosition(bitMask)
    bucketWords[j] = bucketWords[j] and not(cast[uint64](1) shl (currentDistance and 63))
  clearBuckets()
```

A settled target is cleared, so it cannot be counted twice. Relaxations above the guaranteed cost are dropped. The mask lookup jumps straight to the next nonempty bucket.

**Name reader.** One word is read at a time.

```nim
proc readWord(): string =
  skipSpace()
  var collected: string
  while i < lineBuffer.len and lineBuffer[i] > ' ':
    collected.add lineBuffer[i]
    i = i + 1
  return collected
```

The scan stops at whitespace, so city names and counts share one reader.

**Driver.** One search serves all queries with the same source.

```nim
var testCount = int(readInt32())
var outputBuffer: string
for _ in 1 .. testCount:
  var cityCount = int(readInt32())
  var nameToIndex = initTable[string, int]()
  edgeStart = newSeq[int](cityCount + 1)
  edgeTarget = newSeq[int32]()
  edgeCost = newSeq[int32]()
  for i in 0 .. cityCount - 1:
    nameToIndex[readWord()] = i
    var neighbourCount = int(readInt32())
    edgeStart[i] = edgeTarget.len
    for _ in 1 .. neighbourCount:
      edgeTarget.add readInt32() - 1
      edgeCost.add readInt32()
  edgeStart[cityCount] = edgeTarget.len
  var edgeTotal = edgeTarget.len
  distanceValue = repeat(unreachableDistance, cityCount)
  targetStamp = repeat(0, cityCount)
  nodeVertex = newSeq[int32](edgeTotal + 2)
  nodeNext = newSeq[int](edgeTotal + 2)
  bucketWords = repeat(cast[uint64](0), wordTotal)
  var queryCount = int(readInt32())
  var querySource = newSeq[int32](queryCount)
  var queryTarget = newSeq[int32](queryCount)
  for i in 0 .. queryCount - 1:
    querySource[i] = int32(nameToIndex[readWord()])
    queryTarget[i] = int32(nameToIndex[readWord()])
  var answerValue = newSeq[int32](queryCount)
  var sourceUsed = repeat(false, cityCount)
  for i in 0 .. queryCount - 1:
    if sourceUsed[int(querySource[i])]: continue
    sourceUsed[int(querySource[i])] = true
    searchStamp = searchStamp + 1
    var targetsLeft = 0
    for j in 0 .. queryCount - 1:
      if querySource[j] == querySource[i]:
        if targetStamp[int(queryTarget[j])] != searchStamp:
          targetStamp[int(queryTarget[j])] = searchStamp
          targetsLeft = targetsLeft + 1
    shortestPathsFrom(querySource[i], cityCount, targetsLeft)
    for j in 0 .. queryCount - 1:
      if querySource[j] == querySource[i]:
        answerValue[j] = distanceValue[int(queryTarget[j])]
  for i in 0 .. queryCount - 1:
    outputBuffer.add $answerValue[i]
    outputBuffer.add "\n"
    if outputBuffer.len >= flushBlockBytes:
      stdout.write outputBuffer
      outputBuffer.setLen 0
stdout.write outputBuffer
```

Adjacency is stored in flat arrays with one start index per city. `sourceUsed` skips a source after its first search. Answers are written in query order, not in source order.

## Complexity

Bucket Dijkstra dominates each distinct source.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | O(B) for B bytes | B bytes |
| Graph build | O(n + p total) | O(n + p total) |
| One Dijkstra pass | O(200002 + edges touched) | O(200002) buckets |
| All queries | at most r passes | O(n) per pass |
| Output | O(r) lines | one block |

r is at most 100, but repeated sources share a pass.

| Measure | Big O |
| --- | --- |
| Time | O(distinct sources times (200002 + edges)) |
| Space | O(n + edges + 200002) |

One Dijkstra per query would repeat the same search up to 100 times.
