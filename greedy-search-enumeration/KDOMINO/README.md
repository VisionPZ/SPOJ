# KDOMINO — K-dominant array (SPOJ)

<https://www.spoj.com/problems/KDOMINO/>

## Problem

For each query range `[l, r]` and factor `k`, decide whether some value occurs often enough to make `occurrence x k` at least the range length. Answer `YES` or `NO` per query, in input order.

The input starts with `N` and `Q`. The next line holds `N` array values. Each of the following `Q` lines holds `l`, `r`, and `k`, with `1 <= l <= r <= N`. All values are positive 32-bit integers, and the sum of all `k` values is at most 500000.

| item | bound |
|---|---|
| elements N | 1 to 200000 |
| queries Q | 1 to 200000 |
| factor k | positive 32-bit integer |
| sum of k over queries | at most 500000 |
| judge limit | 2000 ms, 1536 MB |

Both `N` and `Q` drive the design: scanning the range for every query is too costly.

Sample input:

```
8 3
1 4 2 3 2 2 5 3
2 6 2
1 8 2
1 8 3
```

Sample output:

```
YES
NO
YES
```

## Idea

Ordering the queries to keep both window edges nearby is like a waiter serving tables in one sweep instead of crossing the room for every order. The algorithm is Mo's algorithm over the query ranges. Each endpoint move changes one frequency in O(1), so the sweep costs O((N + Q) sqrt N). A fresh count for every query costs up to O(N Q), which is far slower. Keep one live window, track its largest frequency, and read every answer from that value.

## Why It Works

1. A range of length `L` is dominant exactly when some value occurs at least `ceil(L / k)` times.
2. That required count is `requiredCount` in the code; a count of one always succeeds.
3. Mo's algorithm sorts queries by left block, then by right endpoint in alternating direction.
4. Adding or removing one element changes a single frequency, and `countOfCounts` keeps the current maximum.
5. The answer is `YES` when `maxFrequency` reaches `requiredCount`, and `NO` otherwise.

| term | meaning |
|---|---|
| `requiredCount` | needed occurrences, computed as `ceil(L / k)` |
| `occurrenceCounts` | frequency of each compressed value in the live window |
| `countOfCounts` | how many values have each frequency |
| `maxFrequency` | largest frequency in the live window |
| `blockSize` | left-endpoint block width used for sorting queries |

For the sample, query `2 6 2` spans five values `4 2 3 2 2`, needs three occurrences, and value `2` occurs three times, so the answer is `YES`. Query `1 8 2` needs four occurrences and the best value has three, so the answer is `NO`. Query `1 8 3` needs three and value `2` has three, so the answer is `YES`.

## Code

**Input and helpers.** The reader loads the array and queries, and binary search compresses large values into small ids.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

type QueryRecord = object
  leftPos: int
  rightPos: int
  requiredCount: int
  answerIndex: int

proc compareNumbers(leftValue: int, rightValue: int): int =
  leftValue - rightValue

proc findValueId(sortedValues: seq[int], target: int): int =
  var lowIndex = 0
  var highIndex = sortedValues.len - 1
  while lowIndex <= highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if sortedValues[middleIndex] < target:
      lowIndex = middleIndex + 1
    elif sortedValues[middleIndex] > target:
      highIndex = middleIndex - 1
    else:
      return middleIndex
  return lowIndex
```

Compression keeps the frequency arrays sized by distinct values, not by 32-bit values.
The answer index restores input order after sorting.
The scanner ignores line breaks and spacing.

**Query setup.** Each query stores its required count and its sorted order key.

```nim
let elementCount = nextInt(inputData, scanPos)
let queryCount = nextInt(inputData, scanPos)

var rawValues = newSeq[int](elementCount)
var sortedValues = newSeq[int](elementCount)
for elementIndex in 0 .. elementCount - 1:
  let currentValue = nextInt(inputData, scanPos)
  rawValues[elementIndex] = currentValue
  sortedValues[elementIndex] = currentValue
sortedValues.sort(compareNumbers)

var distinctValues = newSeq[int]()
for sortedValue in sortedValues:
  if distinctValues.len == 0 or distinctValues[distinctValues.len - 1] != sortedValue:
    distinctValues.add sortedValue

var compressedValues = newSeq[int](elementCount)
for elementIndex in 0 .. elementCount - 1:
  compressedValues[elementIndex] = findValueId(distinctValues, rawValues[elementIndex])

var blockSize = 1
while blockSize * blockSize < elementCount:
  blockSize += 1

var queryRecords = newSeq[QueryRecord](queryCount)
for queryIndex in 0 .. queryCount - 1:
  let leftBound = nextInt(inputData, scanPos)
  let rightBound = nextInt(inputData, scanPos)
  let dominanceFactor = nextInt(inputData, scanPos)
  let spanLength = rightBound - leftBound + 1
  queryRecords[queryIndex].leftPos = leftBound - 1
  queryRecords[queryIndex].rightPos = rightBound - 1
  queryRecords[queryIndex].requiredCount = (spanLength + dominanceFactor - 1) div dominanceFactor
  queryRecords[queryIndex].answerIndex = queryIndex

proc compareQueries(leftQuery: QueryRecord, rightQuery: QueryRecord): int =
  let leftBlock = leftQuery.leftPos div blockSize
  let rightBlock = rightQuery.leftPos div blockSize
  if leftBlock != rightBlock:
    return leftBlock - rightBlock
  if (leftBlock and 1) == 1:
    return rightQuery.rightPos - leftQuery.rightPos
  return leftQuery.rightPos - rightQuery.rightPos

queryRecords.sort(compareQueries)
```

Integer division rounds the required count up without floats.
Alternating right-endpoint order reduces pointer travel between blocks.
The block width is the integer square root of the array length.

**Mo sweep.** Two pointers maintain one live window and answer every query in sorted order.

```nim
var occurrenceCounts = newSeq[int](distinctValues.len)
var countOfCounts = newSeq[int](elementCount + 1)
var maxFrequency = 0

proc addOccurrence(valueId: int) =
  let oldCount = occurrenceCounts[valueId]
  if oldCount > 0:
    countOfCounts[oldCount] -= 1
  let newCount = oldCount + 1
  occurrenceCounts[valueId] = newCount
  countOfCounts[newCount] += 1
  if newCount > maxFrequency:
    maxFrequency = newCount

proc removeOccurrence(valueId: int) =
  let oldCount = occurrenceCounts[valueId]
  countOfCounts[oldCount] -= 1
  let newCount = oldCount - 1
  occurrenceCounts[valueId] = newCount
  countOfCounts[newCount] += 1
  if oldCount == maxFrequency and countOfCounts[oldCount] == 0:
    maxFrequency -= 1

var answers = newSeq[string](queryCount)
var currentLeft = 0
var currentRight = -1
for query in queryRecords:
  while currentRight < query.rightPos:
    currentRight += 1
    addOccurrence(compressedValues[currentRight])
  while currentLeft > query.leftPos:
    currentLeft -= 1
    addOccurrence(compressedValues[currentLeft])
  while currentRight > query.rightPos:
    removeOccurrence(compressedValues[currentRight])
    currentRight -= 1
  while currentLeft < query.leftPos:
    removeOccurrence(compressedValues[currentLeft])
    currentLeft += 1
  if query.requiredCount <= 1 or maxFrequency >= query.requiredCount:
    answers[query.answerIndex] = "YES\n"
  else:
    answers[query.answerIndex] = "NO\n"

for answerText in answers:
  appendOutput(answerText)
stdout.write outputBuffer
outputBuffer.setLen 0
```

Each pointer step updates one frequency in constant time.
Removing the last value at the maximum lowers the maximum by one.
Output is restored to input order before it reaches the buffer.

## Complexity

Sorting the queries and moving the two pointers dominate the running time.

| phase | time | space |
|---|---|---|
| compression | `O(N log N)` | `N` values |
| query sort | `O(Q log Q)` | `Q` records |
| Mo sweep | `O((N + Q) sqrt N)` | frequency arrays |
| output | one pass over answers | block buffer |

The sweep sets the total cost for large inputs.

| measure | Big O |
|---|---|
| time | `O((N + Q) log(N + Q) + (N + Q) sqrt N)` |
| space | `O(N + Q)` |

Recounting each range from scratch would cost `O(N Q)`, so the shared sweep is the deciding gain. Answering from one live window keeps every query cheap.
