# GIVEAWAY — Give Away (SPOJ)
<https://www.spoj.com/problems/GIVEAWAY/>

## Problem

Keep an array of N integers under point updates. A count query asks how many entries in an index interval are at least a threshold. Print one answer line for each count query; update queries print nothing.

The first line holds N. The next line holds N values. The next line holds Q, followed by Q queries. A type 0 query has the form `0 a b c` with indices between 1 and N. A type 1 query has the form `1 a b` and sets entry a to b.

| item | bound |
|---|---|
| array size N | 1 to 500000 |
| query count Q | 1 to 100000 |
| array value | 1 to 1000000000 |
| query threshold | 1 to 1000000000 |
| judge limit | 1000 ms, 1536 MB |

Updates and count queries share one array, so a static answer table does not work.

Sample input:

```
5
1 2 3 4 5
3
0 1 5 10
1 2 20
0 1 3 10
```

The sample has two count queries around one update.

Sample output:

```
0
1
```

The first count is zero and the second is one.

## Idea

Think of the array as a row of sorted filing cabinets: each cabinet holds one block of entries in order. A count query scans the two partial cabinets by hand and binary-searches every full cabinet. An update replaces one card in its cabinet by sliding cards over. The cost per query stays near the square root of N instead of scanning the whole interval. A plain interval scan costs O(N) per query, which is too slow at these bounds. One sorted copy per block is enough to keep both query types fast.

## Why It Works

1. A block holds `blockSize` consecutive array entries, except possibly the last one.
2. `sortedBlocks` stores each block's values in ascending order, while `currentValues` keeps array order.
3. A count query scans the partial blocks directly, because only two blocks touch interval ends.
4. Every full block contributes its length minus the lower bound of the threshold.
5. `lowerBound` returns the first position whose value is at least the threshold.
6. An update removes the old value through one binary search and a left shift.
7. It inserts the new value through another binary search and a right shift.
8. Both blocks and answers stay current after each update.

| term | meaning |
|---|---|
| `blockSize` | number of consecutive entries per block |
| `sortedBlocks` | ascending value lists, one per block |
| `currentValues` | array entries in index order |
| `lowerBound` | first sorted position holding a value at least the target |
| `matchingCount` | answer to one count query |

The two block views separate ordered lookup from index lookup.

The generator script produced this example from the sample, using a block width of two for illustration. The sorted cabinets change only in the block that holds entry 2.

| step | sorted blocks | answer |
|---|---|---|
| start | [1,2], [3,4], [5] | - |
| 0 1 5 10 | [1,2], [3,4], [5] | 0 |
| 1 2 20 | [1,20], [3,4], [5] | - |
| 0 1 3 10 | [1,20], [3,4], [5] | 1 |

After the update, one card moves inside the first cabinet; the other cabinets stay untouched.

A block width near 3400 balances the two partial scans against the number of binary searches. Counts never exceed N, so a plain integer holds every answer.

## Code

**Helpers.** Constants, input, scanner, output buffer, comparator and lower bound.

```nim
import algorithm

const flushBlockBytes = 1 shl 17
const blockSize = 3400

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

proc compareValues(leftValue, rightValue: int): int =
  if leftValue < rightValue:
    return -1
  if leftValue > rightValue:
    return 1
  return 0

proc lowerBound(sortedValues: openArray[int], target: int): int =
  var lowIndex = 0
  var highIndex = sortedValues.len
  while lowIndex < highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if sortedValues[middleIndex] < target:
      lowIndex = middleIndex + 1
    else:
      highIndex = middleIndex
  return lowIndex
```

`nextInt` reads every number from the one input string.
`compareValues` gives the sort its ordering.
`lowerBound` takes `openArray` so no block copy occurs.

**Block setup.** Build the two views of the array and sort every block once.

```nim
let elementCount = nextInt(inputData, scanPos)
var currentValues = newSeq[int](elementCount)
let blockCount = (elementCount + blockSize - 1) div blockSize
var sortedBlocks = newSeq[seq[int]](blockCount)
for blockIndex in 0 .. blockCount - 1:
  sortedBlocks[blockIndex] = newSeq[int](0)
for elementIndex in 0 .. elementCount - 1:
  currentValues[elementIndex] = nextInt(inputData, scanPos)
  sortedBlocks[elementIndex div blockSize].add currentValues[elementIndex]
for blockIndex in 0 .. blockCount - 1:
  sort(sortedBlocks[blockIndex], compareValues)
```

Each element lands in one block by integer division.
`sort` uses the explicit comparator required by Nim.
The setup runs once before any query.

**Query loop.** Answer count queries and apply point updates in place.

```nim
let queryCount = nextInt(inputData, scanPos)
for queryIndex in 0 .. queryCount - 1:
  let queryType = nextInt(inputData, scanPos)
  if queryType == 0:
    let leftIndex = nextInt(inputData, scanPos) - 1
    let rightIndex = nextInt(inputData, scanPos) - 1
    let threshold = nextInt(inputData, scanPos)
    let leftBlock = leftIndex div blockSize
    let rightBlock = rightIndex div blockSize
    var matchingCount = 0
    if leftBlock == rightBlock:
      for elementIndex in leftIndex .. rightIndex:
        if currentValues[elementIndex] >= threshold:
          matchingCount += 1
    else:
      let leftEnd = (leftBlock + 1) * blockSize - 1
      for elementIndex in leftIndex .. leftEnd:
        if currentValues[elementIndex] >= threshold:
          matchingCount += 1
      let rightStart = rightBlock * blockSize
      for elementIndex in rightStart .. rightIndex:
        if currentValues[elementIndex] >= threshold:
          matchingCount += 1
      for blockIndex in leftBlock + 1 .. rightBlock - 1:
        matchingCount += sortedBlocks[blockIndex].len - lowerBound(sortedBlocks[blockIndex], threshold)
    appendOutput($matchingCount)
    outputBuffer.add '\n'
  else:
    let updateIndex = nextInt(inputData, scanPos) - 1
    let newValue = nextInt(inputData, scanPos)
    let blockIndex = updateIndex div blockSize
    let oldValue = currentValues[updateIndex]
    currentValues[updateIndex] = newValue
    var removalIndex = lowerBound(sortedBlocks[blockIndex], oldValue)
    while removalIndex < sortedBlocks[blockIndex].len - 1:
      sortedBlocks[blockIndex][removalIndex] = sortedBlocks[blockIndex][removalIndex + 1]
      removalIndex += 1
    sortedBlocks[blockIndex].setLen(sortedBlocks[blockIndex].len - 1)
    let insertionIndex = lowerBound(sortedBlocks[blockIndex], newValue)
    sortedBlocks[blockIndex].setLen(sortedBlocks[blockIndex].len + 1)
    var shiftIndex = sortedBlocks[blockIndex].len - 1
    while shiftIndex > insertionIndex:
      sortedBlocks[blockIndex][shiftIndex] = sortedBlocks[blockIndex][shiftIndex - 1]
      shiftIndex -= 1
    sortedBlocks[blockIndex][insertionIndex] = newValue

stdout.write outputBuffer
outputBuffer.setLen 0
```

Full blocks add their sorted tail past the lower bound.
The update shifts cards inside one block only.
The final write flushes the buffered answer lines once.

## Complexity

Each query touches two partial blocks and a binary search per remaining block.

| phase | time | space |
|---|---|---|
| input read | one pass over array and queries | one input string |
| block setup | sort each block once | array plus sorted blocks |
| count query | scan two partial blocks, search full blocks | constant |
| point update | shift cards inside one block | constant |

The setup cost is small compared with the query loop.

| measure | Big O |
|---|---|
| setup | O(N log blockSize) |
| count query | O(blockSize + (N / blockSize) log blockSize) |
| point update | O(blockSize) |
| space | O(N) |

The block width balances the two cost terms for these bounds.

Scanning the full interval for every count query would cost O(QN) time.

Sqrt decomposition keeps both query types inside the judge limit.
