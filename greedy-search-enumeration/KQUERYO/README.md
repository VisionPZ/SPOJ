# KQUERYO — K-Query Online (SPOJ)

<https://www.spoj.com/problems/KQUERYO/>

## Problem

A fixed sequence of numbers receives queries that ask how many entries in a position range exceed a threshold. Each raw query is XORed with the previous answer, so queries must be decoded and answered in order. Clamp a decoded left edge below one up to one. Clamp a decoded right edge above n down to n. Answer zero when the left edge passes the right edge.

Input gives n, the n sequence values, q, then q triples of raw values. Output one answer per query.

| item | bound |
|---|---|
| sequence length n | 1 to 30000 |
| query count q | 1 to 200000 |
| value and threshold | 1 to 1000000000 |
| judge limit | 200 ms, 1536 MB |

The XOR chain makes offline query sorting unusable.

Sample input:

```
6
8 9 3 5 1 9
5
2 3 5
3 3 7
0 0 11
0 0 2
3 7 4
```

Sample output:

```
1
1
0
0
2
```

## Idea

Think of each prefix of the sequence as a snapshot of a bookshelf, like keeping a dated copy after every new book arrives. A persistent segment tree stores those snapshots with shared nodes. Each insertion copies only one path, so version r minus version l-1 gives the range. A threshold query walks that path difference in logarithmic time. A fresh scan of the range would cost linear time per query, while the tree costs logarithmic time. Every query works online, so the XOR chain stays intact.

## Why It Works

1. Compressing values turns a threshold into a compressed index boundary.
2. Version k holds exactly the first k sequence values.
3. Subtracting version l-1 from version r removes all earlier entries.
4. Two moduli are unnecessary because counts fit in an integer.
5. Clamping and the empty-range check happen before any tree query.

| term | meaning |
|---|---|
| `distinctValues` | sorted unique sequence values |
| `versionRoots` | root node of each prefix version |
| `nodeTotal` | number of values stored in a node subtree |
| `firstGreaterIndex` | first compressed index whose value exceeds the threshold |
| `countFromIndex` | counts entries at or above a compressed index |

The version difference isolates the requested range without rebuilding anything.

A script trace over the sample queries gives these decoded requests:

```
raw          last  decoded (i, j, k)   answer
2 3 5        0     (2, 3, 5)           1
3 3 7        1     (2, 2, 6)           1
0 0 11       1     (1, 1, 10)          0
0 0 2        0     (0, 0, 2) -> empty  0
3 7 4        0     (3, 6, 4)           2
```

The five answers match the sample output in order.

The first query over [9, 3] with threshold 5 has one qualifying value, which becomes the next XOR key.

## Code

**Input and compression.** The reader loads the sequence and builds sorted unique values.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const maxTreeNodes = 700000

import algorithm

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

proc compareValues(firstValue: int, secondValue: int): int =
  if firstValue < secondValue:
    return -1
  elif firstValue > secondValue:
    return 1
  return 0
```

The scanner skips all separators and reads one decimal integer at a time.
Sorting needs an explicit comparator on this compiler.
The sequence stays in input order for version building.

**Version construction.** Each sequence value creates one persistent root.

```nim
let elementCount = nextInt(inputData, scanPos)
var sequenceValues = newSeq[int](elementCount)
for elementIndex in 0 .. elementCount - 1:
  sequenceValues[elementIndex] = nextInt(inputData, scanPos)

var sortedValues = newSeq[int](elementCount)
for elementIndex in 0 .. elementCount - 1:
  sortedValues[elementIndex] = sequenceValues[elementIndex]
sortedValues.sort(compareValues)

var distinctValues = newSeq[int](elementCount)
var distinctCount = 0
for elementIndex in 0 .. elementCount - 1:
  if elementIndex == 0 or sortedValues[elementIndex] != sortedValues[elementIndex - 1]:
    distinctValues[distinctCount] = sortedValues[elementIndex]
    distinctCount += 1
distinctValues.setLen(distinctCount)

proc compressedIndex(value: int): int =
  var lowIndex = 0
  var highIndex = distinctCount - 1
  while lowIndex <= highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if distinctValues[middleIndex] == value:
      return middleIndex + 1
    elif distinctValues[middleIndex] < value:
      lowIndex = middleIndex + 1
    else:
      highIndex = middleIndex - 1
  return -1

proc firstGreaterIndex(value: int): int =
  var lowIndex = 0
  var highIndex = distinctCount
  while lowIndex < highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if distinctValues[middleIndex] <= value:
      lowIndex = middleIndex + 1
    else:
      highIndex = middleIndex
  return lowIndex + 1
```

Compression keeps tree size logarithmic in the value range.
`firstGreaterIndex` finds the first value above the decoded threshold.
Both lookups use binary search over the sorted values.

```nim
var leftBranch = newSeq[int](maxTreeNodes)
var rightBranch = newSeq[int](maxTreeNodes)
var nodeTotal = newSeq[int](maxTreeNodes)
var allocatedNodes = 0

proc insertValue(previousNode: int, lowBound: int, highBound: int, targetIndex: int): int =
  allocatedNodes += 1
  let newNode = allocatedNodes
  leftBranch[newNode] = leftBranch[previousNode]
  rightBranch[newNode] = rightBranch[previousNode]
  nodeTotal[newNode] = nodeTotal[previousNode] + 1
  if lowBound < highBound:
    let middleBound = (lowBound + highBound) div 2
    if targetIndex <= middleBound:
      leftBranch[newNode] = insertValue(leftBranch[previousNode], lowBound, middleBound, targetIndex)
    else:
      rightBranch[newNode] = insertValue(rightBranch[previousNode], middleBound + 1, highBound, targetIndex)
  return newNode

var versionRoots = newSeq[int](elementCount + 1)
for elementIndex in 0 .. elementCount - 1:
  let rankIndex = compressedIndex(sequenceValues[elementIndex])
  versionRoots[elementIndex + 1] = insertValue(versionRoots[elementIndex], 1, distinctCount, rankIndex)
```

Each insertion copies one root-to-leaf path.
Unchanged branches are shared between versions.
The root array gives constant-time access to any prefix.

**Range counting.** The walk adds whole right segments whenever the threshold falls left of a midpoint.

```nim
proc countFromIndex(rightVersion: int, leftVersion: int, lowBound: int, highBound: int, thresholdIndex: int): int =
  var rightNode = rightVersion
  var leftNode = leftVersion
  var low = lowBound
  var high = highBound
  var countTotal = 0
  while low < high:
    let middleBound = (low + high) div 2
    if thresholdIndex <= middleBound:
      countTotal += nodeTotal[rightBranch[rightNode]] - nodeTotal[rightBranch[leftNode]]
      rightNode = leftBranch[rightNode]
      leftNode = leftBranch[leftNode]
      high = middleBound
    else:
      rightNode = rightBranch[rightNode]
      leftNode = rightBranch[leftNode]
      low = middleBound + 1
  if thresholdIndex <= low:
    countTotal += nodeTotal[rightNode] - nodeTotal[leftNode]
  return countTotal
```

The iterative walk avoids recursion overhead on every query.
Right segments added along the way lie fully above the threshold.
The final leaf contributes its own count.

**Query driver.** XOR decoding, clamping, and output happen in one pass.

```nim
let queryCount = nextInt(inputData, scanPos)
var lastAnswer = 0
for queryIndex in 0 .. queryCount - 1:
  let rawLeft = nextInt(inputData, scanPos)
  let rawRight = nextInt(inputData, scanPos)
  let rawThreshold = nextInt(inputData, scanPos)
  var queryLeft = rawLeft xor lastAnswer
  var queryRight = rawRight xor lastAnswer
  let queryThreshold = rawThreshold xor lastAnswer
  if queryLeft < 1:
    queryLeft = 1
  if queryRight > elementCount:
    queryRight = elementCount
  if queryLeft > queryRight:
    lastAnswer = 0
    appendOutput("0")
    outputBuffer.add '\n'
    continue
  let thresholdIndex = firstGreaterIndex(queryThreshold)
  if thresholdIndex > distinctCount:
    lastAnswer = 0
    appendOutput("0")
    outputBuffer.add '\n'
    continue
  let answer = countFromIndex(versionRoots[queryRight], versionRoots[queryLeft - 1], 1, distinctCount, thresholdIndex)
  lastAnswer = answer
  appendOutput($(answer))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Decoding uses the previous answer before any clamping.
Empty ranges and thresholds above every value answer zero.
The buffer flushes once after the last query.

## Complexity

Most work happens in the query walk over compressed value ranges.

| phase | time | space |
|---|---|---|
| compression | sort n values | two value arrays |
| version build | n path insertions | one node per insertion level |
| query | one root-to-leaf walk | constant |
| output | one flush per block | block buffer |

The query walk drives the runtime for large q.

| measure | Big O |
|---|---|
| time | O(n log n + q log n) |
| space | O(n log n) |

Scanning each range directly would cost O(n q) time, which is slower.
Persistent versions keep every query online and logarithmic, which is the takeaway.
