## Problem

Read `d` datasets. Each dataset lists `n` disjoint vertical segments as a low y, a high y and an x. Two segments are horizontally visible when a horizontal line joins them without touching any other segment. Count triples where every pair is visible, and print one count per dataset.

Here are the judge limits.

| Item | Value |
| --- | --- |
| Datasets | 1 to 20 |
| Segments per dataset | 1 to 8000 |
| y endpoints | 0 to 8000, low < high |
| x coordinate | 0 to 8000 |
| Time | 3250 ms |
| Memory | 1536 MB |

The segment count and coordinate range drive the cost; the output stays tiny.

## Idea

Sweep segments from left to right and keep the nearest segment seen at every y position. A new segment sees the distinct stored segments covering its span; record each pair as one bit in a bitset. One tree update per segment and one bit pass per pair replace the naive test of every pair and every triple.

## Why It Works

Every endpoint is an integer, so the real y axis splits into integer points `k` and open gaps `(k, k + 1)`. Doubling maps those pieces to integer slots `2 * k` and `2 * k + 1`. A segment from `y1` to `y2` owns every slot from `2 * y1` to `2 * y2`. Two spans share a slot exactly when some horizontal line meets both spans.

The tree stores one value per slot. Zero means no segment owns the slot. Minus one means a node range holds several values, so the query walks into its children.

At slot `p`, the sweep keeps the processed segment with the largest x that owns `p`. When segment B arrives, a stored segment A at a shared slot has no segment between A and B that owns that slot. Such a segment would have been processed before B and would be stored instead. So A and B are visible. The reverse also holds. If A and B are visible, a shared slot has no blocker, and A is still stored there when B arrives. The collected set is therefore exact.

For an edge between segments `i` and `j`, the AND of their two bit rows marks every common neighbor `k`. Summing those counts over all edges counts each triangle three times, once per edge, so the program divides by three.

The index formula has one term per piece of the geometry.

```text
endpoint k        -> slot 2 * k
gap (k, k + 1)    -> slot 2 * k + 1
segment [y1, y2]  -> slots 2 * y1 through 2 * y2
```

The sample gives this trace. The pairs come from an independent interval check, not from the tree sweep.

```text
Input segments (low, high, x):
  1: 0 4 4
  2: 0 3 1
  3: 3 4 2
  4: 0 2 2
  5: 0 2 3

Visible pairs: (1,2) (1,3) (1,5) (2,3) (2,4) (4,5)
Triangle: (1,2,3)
Answer: 1
```

Segments 2 and 3 meet only at y = 3, and no segment blocks that point, so the pair counts.

## Code

The tree spans slots from 0 to `doubledLimit`, and each node covers one contiguous range of slots.

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
  scanPosition = 0
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

A node array of four times the slot count holds the tree. The bitset uses 64 bits per word. The output buffer flushes after 256 KiB.

```nim
proc loadInput() =
  var oneLine = ""
  while readLine(stdin, oneLine):
    inputData.add oneLine
    inputData.add '\n'
```

The loop reads the whole stream once into one buffer, so scanning never calls the stream layer.

```nim
proc nextInteger(): int =
  var numberValue = 0
  while scanPosition < inputData.len and inputData[scanPosition] < zeroCharacter:
    inc scanPosition
  while scanPosition < inputData.len and inputData[scanPosition] >= zeroCharacter:
    numberValue = numberValue * 10 + int(inputData[scanPosition]) - digitBase
    inc scanPosition
  result = numberValue
```

The scanner skips whitespace and reads digits by index. Input values are never negative, so no sign branch is needed. It runs once per number.

```nim
proc appendResult(answerValue: int64) =
  outputBuffer.add $answerValue
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer holds at most one block plus one answer. A large answer needs 64 bits.

```nim
proc assignCover(nodeIndex: int, leftBound: int, rightBound: int,
                 queryLeft: int, queryRight: int, coverValue: int) =
  if queryLeft <= leftBound and rightBound <= queryRight:
    coverTree[nodeIndex] = coverValue
    return
  if coverTree[nodeIndex] >= 0:
    coverTree[nodeIndex * 2] = coverTree[nodeIndex]
    coverTree[nodeIndex * 2 + 1] = coverTree[nodeIndex]
    coverTree[nodeIndex] = -1
  let middle = (leftBound + rightBound) div 2
  if queryLeft <= middle:
    assignCover(nodeIndex * 2, leftBound, middle, queryLeft, queryRight, coverValue)
  if queryRight > middle:
    assignCover(nodeIndex * 2 + 1, middle + 1, rightBound, queryLeft, queryRight, coverValue)
  if coverTree[nodeIndex * 2] == coverTree[nodeIndex * 2 + 1]:
    coverTree[nodeIndex] = coverTree[nodeIndex * 2]
  else:
    coverTree[nodeIndex] = -1
```

A full node takes one assignment. A partial node pushes its uniform value to both children before the recursion, which avoids stale children. The work per segment is O(log 16001).

```nim
proc collectCovers(nodeIndex: int, leftBound: int, rightBound: int,
                   queryLeft: int, queryRight: int, collected: var seq[int]) =
  if rightBound < queryLeft or leftBound > queryRight:
    return
  let nodeCover = coverTree[nodeIndex]
  if nodeCover >= 0:
    if nodeCover > 0:
      collected.add nodeCover
    return
  if leftBound == rightBound:
    return
  let middle = (leftBound + rightBound) div 2
  collectCovers(nodeIndex * 2, leftBound, middle, queryLeft, queryRight, collected)
  collectCovers(nodeIndex * 2 + 1, middle + 1, rightBound, queryLeft, queryRight, collected)
```

A uniform node adds one id and stops. A mixed node splits until uniform pieces appear. Each visible pair appears at least once in the list.

```nim
proc solveDataset(segmentCount: int): int64 =
  wordCount = (segmentCount + wordMask) div bitsPerWord
  adjacency = newSeq[uint64](segmentCount * wordCount)
  for xPosition in 0..maxCoordinate:
    xCounts[xPosition] = 0
  for segmentId in 0..<segmentCount:
    inc xCounts[segmentX[segmentId]]
  var runningIndex = 0
  for xPosition in 0..maxCoordinate:
    let bucketSize = xCounts[xPosition]
    xCounts[xPosition] = runningIndex
    runningIndex += bucketSize
  for segmentId in 0..<segmentCount:
    let xPosition = segmentX[segmentId]
    visitOrder[xCounts[xPosition]] = segmentId
    inc xCounts[xPosition]
  for treeIndex in 0..<treeEntryCount:
    coverTree[treeIndex] = 0
  for segmentId in 0..<segmentCount:
    seenStamp[segmentId] = 0
  currentStamp = 0
  var collected: seq[int] = @[]
  for orderIndex in 0..<segmentCount:
    let currentId = visitOrder[orderIndex]
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

Counting by x replaces sorting with one pass over 8001 buckets. The stamp array drops repeated ids without clearing an array per segment. The sweep loop runs exactly `segmentCount` times.

```nim
  var triangleSum = 0'i64
  for fromId in 0..<segmentCount:
    let fromBase = fromId * wordCount
    for wordIndex in 0..<wordCount:
      var remainingBits = adjacency[fromBase + wordIndex]
      while remainingBits != 0'u64:
        let lowestBit = remainingBits and (0'u64 - remainingBits)
        let toId = wordIndex * bitsPerWord + countTrailingZeros(lowestBit)
        remainingBits = remainingBits xor lowestBit
        if toId > fromId:
          let toBase = toId * wordCount
          var sharedCount = 0
          for innerWord in 0..<wordCount:
            sharedCount += countSetBits(adjacency[fromBase + innerWord] and
                                        adjacency[toBase + innerWord])
          triangleSum += int64(sharedCount)
  result = triangleSum div 3'i64
```

The loop visits each edge once by testing `toId > fromId`. Each edge costs `wordCount` bit operations. The final division removes the three-way count.

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
  for datasetIndex in 0..<datasetCount:
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

The arrays are allocated once for the largest legal dataset. A final write emits the last partial block.

## Complexity

Let C be 16001 slots, E the number of visible pairs, and n the segment count.

| Phase | Time | Space |
| --- | --- | --- |
| Input and x buckets | O(n + 8001) | O(n) |
| Tree sweep | O((n + E) log C) | O(C) |
| Triangle count | O(E * n / 64) | O(n^2 / 64) |
| Total per dataset | O((n + E) log C + E * n / 64) | O(C + n^2 / 64) |

For n = 8000 the bitset holds 125 words per segment, about 8 MB. The sweep and triangle count stay well below the 3250 ms limit.

The naive method checks each pair against all other segments, then scans all triples. That takes O(n^3) time per dataset, which is far too slow at the largest size.
