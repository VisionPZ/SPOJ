# CPAIR2 — Counting diff-pairs (SPOJ)

<https://www.spoj.com/problems/CPAIR2/>

## Problem

For each range of an array, count index pairs whose values differ by at least a fixed threshold. Report one count per query in the original query order.

The first line holds `N`, `M`, and `K`. The next line holds `N` array values. Each of the following `M` lines holds two 1-based indices `L` and `R`.

The statement gives these bounds:

| item | bound |
|---|---|
| array length N | up to 50000 |
| query count M | up to 50000 |
| threshold K | integer |
| array values | 1 to 100000 |
| judge limit | 1000 ms, 1536 MB |

Both sizes are large, so each range needs an incremental answer rather than a fresh scan.

Sample input:

```
3 1 21
2 31 3
2 3
```

Sample output:

```
1
```

## Idea

Picture sliding a window over an array with two movable ends, like opening and closing a folding ruler one section at a time.

Mo ordering sorts queries by left-index block and then by right index. The two window ends then move a bounded total distance. A Fenwick tree counts current values near a newly added value, so the window tracks the number of close pairs. Far pairs equal all pairs minus close pairs.

Scanning each query from scratch costs quadratic work. Mo ordering reuses one window across many queries. The takeaway is to reorder queries for reuse, then maintain only the close-pair count.

## Why It Works

1. Every pair in the window either has difference below `K` or at least `K`.
2. The total pair count of a window of size `c` is `c` times `c` minus one, divided by two.
3. Adding a value creates close pairs with existing values only in the interval around that value.
4. A Fenwick tree over value 1 to 100000 answers that interval count in logarithmic time.
5. Removing a value subtracts the same interval count after dropping its own frequency.
6. Mo ordering bounds total left-end movement by block count times block width.

The main terms are listed here:

| term | meaning |
|---|---|
| `badPairCount` | pairs in the window with difference below K |
| `windowCount` | number of values currently in the window |
| `fenwickTree` | prefix counts over array values |
| `blockSize` | width of one left-index bucket |

Alternating right-end direction between blocks halves the right-end travel.

A script trace for the sample with threshold twenty-one adds range positions two to three:

| step | window values | close pairs | answer |
|---|---|---|---|
| add 31 | [31] | 0 | 0 |
| add 3 | [31, 3] | 0 | 1 |

The pair differs by twenty-eight, so one pair qualifies.

Guard: the interval bounds are clipped to the value range before each Fenwick query.

## Code

**Input and query ordering.** The reader loads the array and queries, then sorts them in Mo order.

```nim
import math, algorithm

const flushBlockBytes = 1 shl 17
const maxArrayValue = 100000

type Query = object
  left: int
  right: int
  index: int

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

let elementCount = nextInt(inputData, scanPos)
let queryCount = nextInt(inputData, scanPos)
let differenceLimit = nextInt(inputData, scanPos)
var values = newSeq[int](elementCount)
for elementIndex in 0 .. elementCount - 1:
  values[elementIndex] = nextInt(inputData, scanPos)
var queries = newSeq[Query](queryCount)
for queryIndex in 0 .. queryCount - 1:
  queries[queryIndex].left = nextInt(inputData, scanPos) - 1
  queries[queryIndex].right = nextInt(inputData, scanPos) - 1
  queries[queryIndex].index = queryIndex

let blockSize = max(1, elementCount div max(1, int(sqrt(float64(queryCount)))))

proc compareQueries(firstQuery: Query, secondQuery: Query): int =
  let firstBlock = firstQuery.left div blockSize
  let secondBlock = secondQuery.left div blockSize
  if firstBlock != secondBlock:
    if firstBlock < secondBlock:
      return -1
    return 1
  if (firstBlock and 1) == 0:
    if firstQuery.right < secondQuery.right:
      return -1
    if firstQuery.right > secondQuery.right:
      return 1
    return 0
  if firstQuery.right > secondQuery.right:
    return -1
  if firstQuery.right < secondQuery.right:
    return 1
  return 0

queries.sort(compareQueries)
```

Indices are stored zero-based and the original index travels with each query.
The block width balances left-end and right-end travel.
The standard sort keeps ordering cost near linearithmic.

**Fenwick helpers.** A tree over values maintains prefix counts of the current window.

```nim
var fenwickTree = newSeq[int32](maxArrayValue + 2)
var currentLeft = 0
var currentRight = -1
var windowCount = 0
var badPairCount: int64 = 0

proc fenwickAdd(value: int, delta: int32) {.inline.} =
  var treeIndex = value
  while treeIndex <= maxArrayValue:
    fenwickTree[treeIndex] += delta
    treeIndex += treeIndex and (-treeIndex)

proc fenwickPrefix(value: int): int {.inline.} =
  var treeIndex = value
  var total = 0
  while treeIndex > 0:
    total += int(fenwickTree[treeIndex])
    treeIndex -= treeIndex and (-treeIndex)
  return total

proc nearbyCount(value: int): int {.inline.} =
  var lowValue = value - differenceLimit + 1
  var highValue = value + differenceLimit - 1
  if lowValue < 1:
    lowValue = 1
  if highValue > maxArrayValue:
    highValue = maxArrayValue
  if lowValue > highValue:
    return 0
  return fenwickPrefix(highValue) - fenwickPrefix(lowValue - 1)
```

Tree entries are 32-bit integers to save cache space.
The low and high bounds are clipped before the prefix difference.
Each interval count costs two logarithmic walks.

**Window updates.** Adding or removing one element adjusts the close-pair counter.

```nim
proc addValue(value: int) =
  badPairCount += int64(nearbyCount(value))
  fenwickAdd(value, 1.int32)
  windowCount += 1

proc removeValue(value: int) =
  fenwickAdd(value, -1.int32)
  badPairCount -= int64(nearbyCount(value))
  windowCount -= 1
```

Insertion counts close pairs before storing the new value.
Deletion removes the value before counting close pairs.
Both operations keep the counter exact for the current window.

**Query sweep and output.** The sorted queries drive the two window ends and answers return to input order.

```nim
var answers = newSeq[int64](queryCount)
for queryIndex in 0 .. queryCount - 1:
  let chosenQuery = queries[queryIndex]
  while currentLeft > chosenQuery.left:
    currentLeft -= 1
    addValue(values[currentLeft])
  while currentRight < chosenQuery.right:
    currentRight += 1
    addValue(values[currentRight])
  while currentLeft < chosenQuery.left:
    removeValue(values[currentLeft])
    currentLeft += 1
  while currentRight > chosenQuery.right:
    removeValue(values[currentRight])
    currentRight -= 1
  let totalPairs = int64(windowCount * (windowCount - 1) div 2)
  answers[chosenQuery.index] = totalPairs - badPairCount

for answerIndex in 0 .. queryCount - 1:
  appendOutput($answers[answerIndex])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Each end moves only as far as the next query requires.
Pair counts use 64-bit integers because window size reaches 50000.
The buffered writer emits one line per query.

## Complexity

Mo ordering and Fenwick updates set the cost.

| phase | time | space |
|---|---|---|
| input read | one pass over N values and M queries | input string |
| query sort | O(M log M) comparisons | one query record per query |
| window sweep | O((N + M) sqrt M) pointer moves | Fenwick tree over value range |
| output | one line per query | block buffer |

Each pointer move costs two logarithmic Fenwick walks.

| measure | Big O |
|---|---|
| time | O((N + M) sqrt M log 100000) |
| space | O(N + M + 100000) |

Rescanning every range would cost O(M N log N). Reusing one ordered window is the takeaway.
