# SEGVIS — Horizontally Visible Segments (SPOJ)
<https://www.spoj.com/problems/SEGVIS/>

## Problem

Vertical segments stand side by side on a plane. Two segments are visible when a horizontal line joins them without crossing any other segment. Three segments form a triangle when every pair is visible. Count the triangles.

Input: an integer d, then d datasets. Each dataset starts with segment count n, then n lines with low y, high y and x. Output: one integer per dataset, the triangle count.

Here are the judge limits.

| Item | Value |
| --- | --- |
| Datasets d | 1 to 20 |
| Segments per dataset | 1 to 8000 |
| y endpoints | 0 to 8000, low below high |
| x coordinate | 0 to 8000 |
| Judge time limit | 3250 ms |
| Judge memory limit | 1536 MB |

The segment count and coordinate range drive the cost, while output stays tiny.

The sample input:

```
1
5
0 4 4
0 3 1
3 4 2
0 2 2
0 2 3
```

The sample output:

```
1
```

## Idea

Sweep the segments from left to right, like sliding a curtain across a row of posts. Keep the nearest post seen at every height. A new segment sees exactly the posts still showing through its span. That gives one visibility edge per pair.

The program stores the nearest segment in a coverage tree over doubled y slots. Doubling captures both integer points and gaps between them. Each segment takes one tree update and one query. A bitset then holds the graph, and common-neighbor counts give triangles. Testing every pair and every triple would be far slower than one sweep.

One sweep replaces a quadratic pile of visibility tests.

## Why It Works

Four facts carry the program.

1. Every endpoint is an integer, so the y axis splits into integer points k and open gaps between k and k plus 1. Doubling maps those pieces to slots `2 * k` and `2 * k + 1`.
2. A segment from y1 to y2 owns every slot from `2 * y1` through `2 * y2`. Two spans share a slot exactly when a horizontal line meets both.
3. The sweep keeps the processed segment with the largest x at each slot. A stored segment sharing a slot with the new one has no blocker between them, so the pair is visible.
4. For an edge between i and j, the AND of their bit rows marks every common neighbor. Summing over edges counts each triangle three times, so the answer is divided by three.

Each term has one job.

| Term | Meaning |
| --- | --- |
| `coverTree` | nearest segment id stored per slot range |
| `adjacency` | visibility graph as rows of 64-bit words |
| `seenStamp` | stamp that drops repeated ids per segment |
| `wordCount` | number of 64-bit words per graph row |

The tree stores ids one-based, so zero means an empty slot.

The index formula has one term per piece of geometry.

```text
endpoint k       -> slot 2 * k
gap (k, k+1)     -> slot 2 * k + 1
segment [y1, y2] -> slots 2*y1 through 2*y2
```

A script traces the sample through an interval check.

```text
segments: 1:(0,4,4) 2:(0,3,1) 3:(3,4,2) 4:(0,2,2) 5:(0,2,3)
visible pairs: (1,2) (1,3) (1,5) (2,3) (2,4) (4,5)
common neighbors sum: 3
triangles: 3 / 3 = 1
```

Segments 2 and 3 meet at y = 3 with no blocker, so the pair counts.

## Code

**Constants and working arrays.** The tree spans 16001 doubled slots.

```nim
const
  maxCoordinate = 8000
  doubledLimit = 2 * maxCoordinate
  doubledPointCount = doubledLimit + 1
  treeEntryCount = 4 * doubledPointCount
  flushBlockBytes = 1 shl 18
  zeroCharacter = '0'
  digitBase = 48
  bitsPerWord = 64
  wordShift = 6
  wordMask = 63

var
  inputData = ""
  i = 0
  outputBuffer = ""
  segmentLow: seq[int]
  segmentHigh: seq[int]
  segmentX: seq[int]
  visitOrder: seq[int]
  xCounts: array[0..maxCoordinate, int]
  coverTree: seq[int]
  seenStamp: seq[int]
  adjacency: seq[uint64]
  currentStamp = 0
  wordCount = 0
```

A node array four times the slot count holds the tree. The graph uses 64 bits per word. The output buffer flushes after 256 KiB.

**Input reader.** One loop collects the whole stream.

```nim
proc loadInput() =
  var oneLine = ""
  while readLine(stdin, oneLine):
    inputData.add oneLine
    inputData.add '\n'
```

The loop reads the stream once into one buffer. Parsing never calls the stream layer again.

**Integer scanner.** Values are nonnegative, so no sign branch appears.

```nim
proc nextInteger(): int =
  var numberValue = 0
  while i < inputData.len and inputData[i] < zeroCharacter:
    inc i
  while i < inputData.len and inputData[i] >= zeroCharacter:
    numberValue = numberValue * 10 + int(inputData[i]) - digitBase
    inc i
  result = numberValue
```

The first loop skips whitespace, and the second reads digits. The cost is one pass per number.

**Output helper.** A large answer needs 64 bits.

```nim
proc appendResult(answerValue: int64) =
  outputBuffer.add $answerValue
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer holds one block plus one answer. Flushing bounds memory at the block size.

**Tree update.** A uniform node takes one assignment.

```nim
proc assignCover(i: int, leftBound: int, rightBound: int,
                 queryLeft: int, queryRight: int, coverValue: int) =
  if queryLeft <= leftBound and rightBound <= queryRight:
    coverTree[i] = coverValue
    return
  if coverTree[i] >= 0:
    coverTree[i * 2] = coverTree[i]
    coverTree[i * 2 + 1] = coverTree[i]
    coverTree[i] = -1
  let middle = (leftBound + rightBound) div 2
  if queryLeft <= middle:
    assignCover(i * 2, leftBound, middle, queryLeft, queryRight, coverValue)
  if queryRight > middle:
    assignCover(i * 2 + 1, middle + 1, rightBound, queryLeft, queryRight, coverValue)
  if coverTree[i * 2] == coverTree[i * 2 + 1]:
    coverTree[i] = coverTree[i * 2]
  else:
    coverTree[i] = -1
```

A partial node pushes its value to both children first, which avoids stale children. The work per segment is O(log 16001).

**Tree query.** A uniform node adds one id and stops.

```nim
proc collectCovers(i: int, leftBound: int, rightBound: int,
                   queryLeft: int, queryRight: int, collected: var seq[int]) =
  if rightBound < queryLeft or leftBound > queryRight:
    return
  let nodeCover = coverTree[i]
  if nodeCover >= 0:
    if nodeCover > 0:
      collected.add nodeCover
    return
  if leftBound == rightBound:
    return
  let middle = (leftBound + rightBound) div 2
  collectCovers(i * 2, leftBound, middle, queryLeft, queryRight, collected)
  collectCovers(i * 2 + 1, middle + 1, rightBound, queryLeft, queryRight, collected)
```

A mixed node splits until uniform pieces appear. Every visible pair appears at least once in the list.

**Edge write.** Each edge sets one bit in two rows.

```nim
proc addEdge(firstId: int, secondId: int) =
  let i = firstId * wordCount + (secondId shr wordShift)
  adjacency[i] = adjacency[i] or (1'u64 shl (secondId and wordMask))
```

The shift picks the word, and the mask picks the bit. Setting both directions makes later AND tests symmetric.

**Sweep and bitset build.** Counting by x replaces a sort.

```nim
proc solveDataset(segmentCount: int): int64 =
  wordCount = (segmentCount + wordMask) div bitsPerWord
  adjacency = newSeq[uint64](segmentCount * wordCount)
  for i in 0..maxCoordinate:
    xCounts[i] = 0
  for segmentId in 0..<segmentCount:
    inc xCounts[segmentX[segmentId]]
  var j = 0
  for i in 0..maxCoordinate:
    let bucketSize = xCounts[i]
    xCounts[i] = j
    j += bucketSize
  for segmentId in 0..<segmentCount:
    let i = segmentX[segmentId]
    visitOrder[xCounts[i]] = segmentId
    inc xCounts[i]
  for i in 0..<treeEntryCount:
    coverTree[i] = 0
  for segmentId in 0..<segmentCount:
    seenStamp[segmentId] = 0
  currentStamp = 0
  var collected: seq[int] = @[]
  for i in 0..<segmentCount:
    let currentId = visitOrder[i]
    inc currentStamp
    collected.setLen 0
    let lowPosition = 2 * segmentLow[currentId]
    let highPosition = 2 * segmentHigh[currentId]
    collectCovers(1, 0, doubledLimit, lowPosition, highPosition, collected)
    for coverValue in collected:
      let previousId = coverValue - 1
      if seenStamp[previousId] != currentStamp:
        seenStamp[previousId] = currentStamp
        addEdge(previousId, currentId)
        addEdge(currentId, previousId)
    assignCover(1, 0, doubledLimit, lowPosition, highPosition, currentId + 1)
```

One pass over 8001 buckets orders segments by x. The stamp drops repeated ids without clearing an array. The sweep loop runs exactly `segmentCount` times.

**Triangle count.** Each edge is visited once.

```nim
  var triangleSum = 0'i64
  for fromId in 0..<segmentCount:
    let fromBase = fromId * wordCount
    for i in 0..<wordCount:
      var remainingBits = adjacency[fromBase + i]
      while remainingBits != 0'u64:
        let lowestBit = remainingBits and (0'u64 - remainingBits)
        let toId = i * bitsPerWord + countTrailingZeros(lowestBit)
        remainingBits = remainingBits xor lowestBit
        if toId > fromId:
          let toBase = toId * wordCount
          var sharedCount = 0
          for j in 0..<wordCount:
            sharedCount += countSetBits(adjacency[fromBase + j] and
                                        adjacency[toBase + j])
          triangleSum += int64(sharedCount)
  result = triangleSum div 3'i64
```

`toId > fromId` visits each edge once. Each edge costs `wordCount` bit operations. The division removes the three-way count.

**Driver.** Fixed arrays serve every dataset.

```nim
proc main() =
  loadInput()
  let datasetCount = nextInteger()
  segmentLow = newSeq[int](maxCoordinate)
  segmentHigh = newSeq[int](maxCoordinate)
  segmentX = newSeq[int](maxCoordinate)
  visitOrder = newSeq[int](maxCoordinate)
  seenStamp = newSeq[int](maxCoordinate)
  coverTree = newSeq[int](treeEntryCount)
  for j in 0..<datasetCount:
    let segmentCount = nextInteger()
    for segmentId in 0..<segmentCount:
      segmentLow[segmentId] = nextInteger()
      segmentHigh[segmentId] = nextInteger()
      segmentX[segmentId] = nextInteger()
    appendResult(solveDataset(segmentCount))
  if outputBuffer.len > 0:
    stdout.write outputBuffer
    outputBuffer.setLen 0

main()
```

The arrays hold at most 8000 segments, so main allocates them once. The final write clears the tail. Each dataset costs one sweep.

## Complexity

The sweep and the edge pass dominate each dataset.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | O(B) for B bytes | B bytes |
| Bucket order | O(8001 + n) | O(n) |
| Tree sweep | O(n log 16001) | O(16001 * 4) |
| Triangle pass | O(n squared times words) | O(n times words) |
| Total | O(n squared times words) per dataset | O(n squared) bits |

Words is n divided by 64, rounded up, and n is at most 8000.

| Measure | Big O |
| --- | --- |
| Time | O(n squared / 64) per dataset |
| Space | O(n squared / 8) for the bitset |

Testing every pair and triple would cost O(n cubed) time.
