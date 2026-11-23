## Problem

The roof is a set of slanted segments. Rain falls straight down. A segment shields the segments below it. Each segment sends all collected water off its lower end. Print that amount for every segment in input order.

The judge bounds shape the solution:

| quantity | limit |
| --- | --- |
| segments per case | 40000 |
| coordinate range | 0 to 1000000 |
| stacked segments at one point | 25 |
| time | 2742 ms |
| memory | 1536 MB |

The depth bound keeps the sweep state small.

## Idea

We sweep endpoints from left to right and keep the segments that cross the current x. In each gap between endpoints, the highest segment catches the direct rain. Each segment also drains from its lower end. That stream falls at one x and lands on the highest segment below it. We store this link, then add child water to each parent in a queue.

Cost per segment: one sweep insertion, one small height sort, one stream lookup.

## Why It Works

At a fixed x, rain hits the highest segment that covers x. So the highest segment in a gap collects that gap's width. Endpoints are the only x values where this choice changes.

We compare heights with exact integer products. Let span be `rightX - leftX` and slope be `rightY - leftY`. The height numerator is `leftY * span + slope * (x - leftX)`. Two segments are compared by cross multiplying numerator and span. No division occurs, so rounding cannot change the order.

Water from a lower end falls at `lowerEndX`. The first segment below `lowerEndY` at that x catches it. We scan the sorted list and take the first lower segment. A stream landing on an endpoint is caught by that segment.

A receiver always lies below its source at a shared x. Segments never cross, so this order cannot cycle. A queue sums child water into each parent.

Here is the sample roof, where `S0` means the ground.

Direct rain per gap:

| x gap | top segment | width | direct water |
| --- | --- | --- | --- |
| [1,3] | S3 | 2 | +2 |
| [3,5] | S2 | 2 | +2 |
| [5,6] | S2 | 1 | +1 |
| [6,7] | S2 | 1 | +1 |
| [7,8] | S4 | 1 | +1 |
| [8,9] | S4 | 1 | +1 |
| [9,12] | S6 | 3 | +3 |
| [13,15] | S1 | 2 | +2 |

S2 collects four liters of direct rain across three gaps.

Streams from each source:

| source | sink x | receiver | stream |
| --- | --- | --- | --- |
| S1 | 15 | S0 | 2 |
| S2 | 7 | S4 | 4 |
| S3 | 5 | S4 | 2 |
| S4 | 9 | S0 | 11 |
| S5 | 8 | S0 | 0 |
| S6 | 9 | S4 | 3 |

S4 collects direct water 2 plus streams 4, 2, and 3, which gives 11.

## Code

The scanner walks one input buffer. It skips separators and builds each integer from digits.

```nim
proc nextInt(): int =
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + (int(inputData[scanPos]) - firstDigitValue)
    scanPos += 1
  return value
```

The loop ends at the first non-digit. Negative values do not occur in this problem. Parsing costs one pass over the buffer.

The writer appends to one buffer and flushes a block at a time.

```nim
proc appendOutputLine(value: int64) =
  outputBuffer.add $value
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The block size is 256 KiB. No write happens per segment. Output costs one pass over the answers.

Heights use integer cross products, so no fraction is built.

```nim
proc yNumerator(segIndex: int): int64 =
  let span = int64(rightX[segIndex] - leftX[segIndex])
  let slope = int64(rightY[segIndex] - leftY[segIndex])
  result = int64(leftY[segIndex]) * span + slope * int64(currentX - leftX[segIndex])

proc higherAtX(firstSeg: int, secondSeg: int): bool =
  let firstSpan = int64(rightX[firstSeg] - leftX[firstSeg])
  let secondSpan = int64(rightX[secondSeg] - leftX[secondSeg])
  result = yNumerator(firstSeg) * secondSpan > yNumerator(secondSeg) * firstSpan
```

The product stays inside 64 bits for the given bounds. The comparison reads the shared `currentX`. Each comparison costs two multiplications.

The sweep handles one endpoint coordinate per iteration.

```nim
  for coordIndex in 0 ..< coordinateCount:
    currentX = coordinateList[coordIndex]
    var coverCount = 0
    for segIndex in activeList:
      coverList[coverCount] = segIndex
      coverCount += 1
    var startSeg = startHead[coordIndex]
    while startSeg != -1:
      coverList[coverCount] = startSeg
      coverCount += 1
      startSeg = startNext[startSeg]

    for sortIndex in 1 ..< coverCount:
      let keySeg = coverList[sortIndex]
      var posIndex = sortIndex - 1
      while posIndex >= 0 and higherAtX(keySeg, coverList[posIndex]):
        coverList[posIndex + 1] = coverList[posIndex]
        posIndex -= 1
      coverList[posIndex + 1] = keySeg

    var streamSeg = streamHead[coordIndex]
    while streamSeg != -1:
      var receiverSeg = -1
      let sourceHeight = int64(lowerEndY[streamSeg])
      for coverIndex in 0 ..< coverCount:
        let candidateSeg = coverList[coverIndex]
        let span = int64(rightX[candidateSeg] - leftX[candidateSeg])
        if yNumerator(candidateSeg) < sourceHeight * span:
          receiverSeg = candidateSeg
          break
      receiverIndex[streamSeg] = receiverSeg
      streamSeg = streamNext[streamSeg]

    if coordIndex < coordinateCount - 1:
      for coverIndex in 0 ..< coverCount:
        let candidateSeg = coverList[coverIndex]
        if endCoordIndex[candidateSeg] != coordIndex:
          directWater[candidateSeg] += int64(coordinateList[coordIndex + 1] - currentX)
          break

    nextActiveList.setLen(0)
    for coverIndex in 0 ..< coverCount:
      let candidateSeg = coverList[coverIndex]
      if endCoordIndex[candidateSeg] != coordIndex:
        nextActiveList.add candidateSeg
    swap activeList, nextActiveList
```

The loop runs once per distinct endpoint, at most `2 * segmentCount` times. Insertion sort keeps the list highest first. Ending segments are skipped for direct rain and for the next active list. The sorted list holds at most 26 segments.

The queue adds child water into each parent.

```nim
  queueList = @[]
  for segIndex in 0 ..< segmentCount:
    if pendingChildren[segIndex] == 0:
      queueList.add segIndex
  var queueHead = 0
  while queueHead < queueList.len:
    let currentSeg = queueList[queueHead]
    queueHead += 1
    let receiverSeg = receiverIndex[currentSeg]
    if receiverSeg != -1:
      answerWater[receiverSeg] += answerWater[currentSeg]
      pendingChildren[receiverSeg] -= 1
      if pendingChildren[receiverSeg] == 0:
        queueList.add receiverSeg
```

A segment enters the queue after all its children are done. Each segment enters once. The loop costs O(n) and needs no recursion.

## Complexity

Reading the input costs O(total input bytes). Sorting endpoints costs O(n log n).

The sweep visits at most `2n` coordinates. At each one, the sorted list holds at most 26 segments. Insertion sort costs O(26 squared) there. The whole sweep is O(n) with a small constant.

The queue pass costs O(n). Total time is O(n log n), dominated by the endpoint sort. The arrays use O(n) space and the sweep state uses O(26).

A naive method checks every pair of segments to find receivers and direct rain. That costs O(n squared) per case and fails at n = 40000.
