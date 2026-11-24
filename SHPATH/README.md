## Problem

Read several test cases. Each case gives cities, their neighbours with costs, and pairs of cities to query. Print the least path cost for each pair, one answer per line.

The statement and judge table give these bounds.

| item | bound |
|---|---|
| test cases | at most 10 |
| cities per case | at most 10 000 |
| queries per case | at most 100 |
| any path cost | at most 200 000 |
| judge limit | 1500 ms, 1536 MB |

The cost bound makes a bucket queue possible.

## Idea

Group queries by source city and run Dijkstra's algorithm once per distinct source. Instead of a binary heap, use a bucket queue (Dial's algorithm): one slot per possible distance, with a bit for each city waiting there. Stop a run once every target of that source has a settled distance.

Cost per settled city: one bit test to find the next distance, plus one pass over its outgoing edges.

## Why It Works

Dijkstra settles cities in nondecreasing distance order, since all edge costs are positive. The smallest nonempty bucket therefore gives the next city to settle.

A 64-bit word holds 64 buckets, so the scan moves word by word, not slot by slot. Bits are cleared after each use, and only touched words are reset between runs.

These expressions map a distance to a bit.

| term | meaning |
|---|---|
| `i shr 6` | the 64-bit word that holds this distance |
| `i and 63` | the bit inside that word |
| `(j shl 6) + lowestSetBitPosition(bitMask)` | decode the next distance |
| `candidateDistance <= guaranteedPathCost` | keep only paths within the stated bound |

Decoding gives the next distance without a heap.

This trace uses the four-city sample and its two queries.

| source | target | distance | all distances |
|---|---|---|---|
| gdansk | warszawa | 3 | 0, 1, 2, 3 |
| bydgoszcz | warszawa | 2 | 1, 0, 1, 2 |

Both answers match the sample output.

These distances show the bucket encoding.

| distance | word index | bit | decoded distance |
|---|---|---|---|
| 0 | 0 | 0 | 0 |
| 1 | 0 | 1 | 1 |
| 3 | 0 | 3 | 3 |
| 65 | 1 | 1 | 65 |
| 200 000 | 3125 | 0 | 200 000 |

Each row decodes back to its input distance.

## Code

**Constants.**

```nim
import tables
import sequtils

const flushBlockBytes = 1 shl 17
const unreachableDistance: int32 = 1000000000
const guaranteedPathCost: int32 = 200000
const bucketTotal = int(guaranteedPathCost) + 2
const wordTotal = (bucketTotal shr 6) + 1
```

`guaranteedPathCost` is the stated path bound. `wordTotal` counts the 64-bit words needed for all buckets. These values never change. Cost: no work at run time.

**Line refill and spacing.**

```nim
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
```

`refillLine` reads one line at a time and appends a newline to the buffer. `skipSpace` crosses line breaks and blank lines. Cost: one read per line of input.

**Integer reader.**

```nim
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

`readInt32` scans digits from the shared line buffer. It builds the value by index, with no substring. Cost: one pass over each number's digits.

**Low-bit table.**

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

The table is built once for all 16-bit chunks. `lowestSetBitPosition` checks four chunks to cover a 64-bit word. Cost: O(2^16) to build, O(1) per lookup.

**Shared arrays.**

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
```

`bucketHead` and `bucketWords` are reused across cases. `nodeVertex` and `nodeNext` hold the waiting cities. `targetStamp` marks the targets of the current run. Cost: arrays sized by the stated bounds.

**Bucket operations.**

```nim
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

`clearBuckets` touches only the slots used by the last run. `enqueueBucket` sets one bit, then links a fresh node. The line `nodeNext[nodeTotal] = bucketHead[i]` fills the new node's pointer; appending instead would leave a stale slot and break the list. Cost: O(1) per enqueue.

**One Dijkstra run.**

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

The scan starts at distance zero and jumps to the next set bit. `edgeStart` bounds each adjacency walk. `targetsLeft` drops when a target settles, and the run ends at `currentDistance >= int(guaranteedPathCost)`. Cost: O(E + C) per source, for cost bound C.

**Word reader.**

```nim
proc readWord(): string =
  skipSpace()
  var collected: string
  while i < lineBuffer.len and lineBuffer[i] > ' ':
    collected.add lineBuffer[i]
    i = i + 1
  return collected
```

`readWord` collects bytes above a space. The city name stays as a string for the table lookup. Cost: one slice per name.

**Graph input.**

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
```

`nameToIndex` maps each name to its city index. `edgeStart[i]` records the first edge of each city. `nodeVertex` and `nodeNext` are sized `edgeTotal + 2` for the enqueues. Cost: O(V + E) per case.

**Query grouping.**

```nim
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
```

`querySource` and `queryTarget` hold the pairs in input order. `sourceUsed` skips a source after its first run. `targetStamp` marks every target of that source before the run. Cost: O(r) per case for r queries.

**Output.**

```nim
  for i in 0 .. queryCount - 1:
    outputBuffer.add $answerValue[i]
    outputBuffer.add "\n"
    if outputBuffer.len >= flushBlockBytes:
      stdout.write outputBuffer
      outputBuffer.setLen 0
stdout.write outputBuffer
```

`answerValue` is written in input order, not in run order. The buffer flushes every 128 KiB. Cost: one line per query.

## Complexity

Costs by phase:

| phase | time | space |
|---|---|---|
| input read | one pass over all lines | input bytes |
| graph build | O(V + E) per case | V + E entries |
| query grouping | O(r) per case | r pairs |
| each Dijkstra run | O(E + C) | C/64 bucket words |
| output | one write per 128 KiB block | 128 KiB |

Runs with the same source are shared, so at most V runs occur.

Big O terms:

| measure | form |
|---|---|
| time | O(s(E + C) + r) worst case |
| space | O(V + E + C/64) per case |

Both measures depend on the cost bound C, not on a heap.

A binary heap gives O(r E log V) time when run per query. Floyd-Warshall costs O(V^3) time and O(V^2) space, which is too large at V = 10 000.
