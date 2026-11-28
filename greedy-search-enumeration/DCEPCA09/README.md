# DCEPCA09 — MMM (SPOJ)

<https://www.spoj.com/problems/DCEPCA09/>

## Problem

For each index interval [i, j], report the mean, median and mode of the values in that slice. Drop any fractional part from all three answers.

Input gives N, then N array values, then Q, then Q lines with i and j. Output Q lines with three integers each.

| item | bound |
|---|---|
| array size N | 2 to 10000 |
| query count Q | 1 to 10000 |
| array value | 0 to 100000000 |
| judge limit | 500 ms, 1536 MB |

Both N and Q drive the work, so the answer must avoid rescanning the array per query.

Sample input:

```
5
6 5 3 7 7
2
1 2
0 4
```

Sample output:

```
4 4 5
5 6 7
```

## Idea

Reorder the work like a librarian pulling books from nearby shelves instead of crossing the room for each request. Mo's algorithm slides one interval across all queries, and a segment tree reports order statistics at each stop.

The algorithm compresses values, sorts queries by block and endpoint, then adds or removes one element per pointer step. Each change costs O(log N). A fresh sort and scan per query would cost O(N log N) per query.

Takeaway: move the interval once and keep the statistics available at every stop.

## Why It Works

1. Prefix sums give the interval total, so the mean needs one subtraction.
2. Compressed values map each array entry to a leaf of a segment tree.
3. Each leaf holds a frequency; internal nodes hold subtree counts and peak frequencies.
4. Descending by subtree counts finds the k-th smallest value, which gives the median.
5. Descending to the rightmost leaf with the peak frequency gives the largest mode.

| term | meaning |
|---|---|
| `compressedValues` | sorted rank of each array entry |
| `treeSums` | number of active elements in each segment tree node |
| `treePeaks` | highest single leaf frequency inside each node |
| `queryOrder` | queries sorted by left block and alternating right endpoint |

Alternating the right endpoint saves pointer steps between blocks.

A script-generated trace for the second sample query:

```
values       6 5 3 7 7
sum          28
length       5
mean         28 / 5 = 5
sorted       3 5 6 7 7
median       6
frequencies  7 -> 2, 6 -> 1, 5 -> 1, 3 -> 1
mode         7
```

The trace gives `5 6 7`, matching the second sample line.

## Code

**Input and compression.** The reader loads the array, its prefix sums and sorted ranks.

```nim
import algorithm

const flushBlockBytes = 1 shl 17

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

let valueCount = nextInt(inputData, scanPos)
var values = newSeq[int](valueCount)
var prefixSums = newSeq[int64](valueCount + 1)
var sortedValues = newSeq[int](valueCount)
for valueIndex in 0 .. valueCount - 1:
  values[valueIndex] = nextInt(inputData, scanPos)
  prefixSums[valueIndex + 1] = prefixSums[valueIndex] + int64(values[valueIndex])
  sortedValues[valueIndex] = values[valueIndex]
sortedValues.sort(proc(leftValue, rightValue: int): int = leftValue - rightValue)

var uniqueValues = newSeq[int]()
for value in sortedValues:
  if uniqueValues.len == 0 or uniqueValues[uniqueValues.len - 1] != value:
    uniqueValues.add value

proc findValueIndex(value: int): int =
  var lowIndex = 0
  var highIndex = uniqueValues.len - 1
  while lowIndex <= highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if uniqueValues[middleIndex] < value:
      lowIndex = middleIndex + 1
    elif uniqueValues[middleIndex] > value:
      highIndex = middleIndex - 1
    else:
      return middleIndex
  return 0

var compressedValues = newSeq[int](valueCount)
for valueIndex in 0 .. valueCount - 1:
  compressedValues[valueIndex] = findValueIndex(values[valueIndex])
```

Prefix sums use 64-bit entries for large totals.
Sorting with an explicit comparator supports old Nim compilers.
Binary search maps each value to its rank.

**Segment tree.** Two node fields support both rank queries and mode queries.

```nim
var baseSize = 1
while baseSize < uniqueValues.len:
  baseSize *= 2
var treeSums = newSeq[int](baseSize * 2)
var treePeaks = newSeq[int](baseSize * 2)

proc changeCount(valueIndex: int, delta: int) =
  var nodeIndex = baseSize + valueIndex
  treeSums[nodeIndex] = treeSums[nodeIndex] + delta
  treePeaks[nodeIndex] = treeSums[nodeIndex]
  nodeIndex = nodeIndex div 2
  while nodeIndex >= 1:
    let leftChild = nodeIndex * 2
    let rightChild = leftChild + 1
    treeSums[nodeIndex] = treeSums[leftChild] + treeSums[rightChild]
    if treePeaks[leftChild] > treePeaks[rightChild]:
      treePeaks[nodeIndex] = treePeaks[leftChild]
    else:
      treePeaks[nodeIndex] = treePeaks[rightChild]
    nodeIndex = nodeIndex div 2

proc kthValue(rank: int): int =
  var nodeIndex = 1
  var remainingRank = rank
  while nodeIndex < baseSize:
    let leftChild = nodeIndex * 2
    if treeSums[leftChild] >= remainingRank:
      nodeIndex = leftChild
    else:
      remainingRank = remainingRank - treeSums[leftChild]
      nodeIndex = leftChild + 1
  return uniqueValues[nodeIndex - baseSize]

proc largestModeValue(): int =
  let peakCount = treePeaks[1]
  var nodeIndex = 1
  while nodeIndex < baseSize:
    let rightChild = nodeIndex * 2 + 1
    if treePeaks[rightChild] == peakCount:
      nodeIndex = rightChild
    else:
      nodeIndex = rightChild - 1
  return uniqueValues[nodeIndex - baseSize]
```

Padding leaves hold zero frequency.
Rank descent compares the count in the left child.
Mode descent prefers the right child on a tie.

**Query ordering.** The block order bounds total pointer travel.

```nim
let queryCount = nextInt(inputData, scanPos)
var queryLefts = newSeq[int](queryCount)
var queryRights = newSeq[int](queryCount)
var queryOrder = newSeq[int](queryCount)
for queryIndex in 0 .. queryCount - 1:
  queryLefts[queryIndex] = nextInt(inputData, scanPos)
  queryRights[queryIndex] = nextInt(inputData, scanPos)
  queryOrder[queryIndex] = queryIndex

var blockSize = 1
while (blockSize + 1) * (blockSize + 1) <= valueCount:
  blockSize += 1

queryOrder.sort(proc(leftIndex, rightIndex: int): int =
  let leftBlock = queryLefts[leftIndex] div blockSize
  let rightBlock = queryLefts[rightIndex] div blockSize
  if leftBlock != rightBlock:
    return leftBlock - rightBlock
  if (leftBlock and 1) == 0:
    if queryRights[leftIndex] < queryRights[rightIndex]:
      return -1
    if queryRights[leftIndex] > queryRights[rightIndex]:
      return 1
  else:
    if queryRights[leftIndex] > queryRights[rightIndex]:
      return -1
    if queryRights[leftIndex] < queryRights[rightIndex]:
      return 1
  return 0)
```

The block size approximates the square root of N.
Even blocks scan right endpoints upward.
Odd blocks scan them downward.

**Sliding sweep and output.** One interval serves every query, then answers return to input order.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var answers = newSeq[string](queryCount)
var currentLeft = 0
var currentRight = -1

for queryIndex in queryOrder:
  let wantedLeft = queryLefts[queryIndex]
  let wantedRight = queryRights[queryIndex]
  while currentLeft > wantedLeft:
    currentLeft -= 1
    changeCount(compressedValues[currentLeft], 1)
  while currentRight < wantedRight:
    currentRight += 1
    changeCount(compressedValues[currentRight], 1)
  while currentLeft < wantedLeft:
    changeCount(compressedValues[currentLeft], -1)
    currentLeft += 1
  while currentRight > wantedRight:
    changeCount(compressedValues[currentRight], -1)
    currentRight -= 1

  let spanLength = wantedRight - wantedLeft + 1
  let spanTotal = prefixSums[wantedRight + 1] - prefixSums[wantedLeft]
  var medianValue = 0
  if spanLength mod 2 == 1:
    medianValue = kthValue(spanLength div 2 + 1)
  else:
    let lowerRank = spanLength div 2
    let lowerValue = kthValue(lowerRank)
    let upperValue = kthValue(lowerRank + 1)
    medianValue = (lowerValue + upperValue) div 2
  answers[queryIndex] = $(spanTotal div int64(spanLength)) & " " &
                        $medianValue & " " & $largestModeValue()

for queryIndex in 0 .. queryCount - 1:
  appendOutput(answers[queryIndex])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Four loops shrink or grow the interval.
Stored answers keep the output in input order.
An even-length median averages the two central ranks.

## Complexity

The sweep pays for pointer moves, and each move updates two tree paths.

| phase | time | space |
|---|---|---|
| input and compression | O(N log N) | prefix and rank arrays |
| query sort | O(Q log Q) | sorted index array |
| sliding sweep | O((N + Q) sqrt(N) log N) | segment tree arrays |
| output | one line per query | block buffer |

The sweep dominates at full bounds.

| measure | Big O |
|---|---|
| time | O((N + Q) sqrt(N) log N) |
| space | O(N + Q) |

Sorting and rescanning each range costs O(Q * N log N) and misses the time limit.

Takeaway: keep one live interval and one tree that answers all three statistics.
