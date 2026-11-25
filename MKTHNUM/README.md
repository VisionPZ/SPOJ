# MKTHNUM — K-th Number (SPOJ)

<https://www.spoj.com/problems/MKTHNUM/>

## Problem

Given an array of distinct integers, answer range queries that ask for the k-th smallest value inside a subarray. The answer is the value after sorting that subarray.

The input starts with the array size `n` and the query count `m`. One line holds the array values, then each query line holds `i`, `j`, and `k`. A query `Q(i,j,k)` asks for the k-th smallest value in the segment `a[i..j]`. For example, the segment `5 2 6 3` sorted gives 2, 3, 5, 6. The output holds one answer per query.

| item | bound |
|---|---|
| array size `n` | 1 to 100000 |
| query count `m` | 1 to 5000 |
| array values | between -10^9 and 10^9 |
| judge limit | 1000 ms, 1536 MB |

The product of the two bounds rules out sorting a fresh subarray for every query.

Sample input:

```
7 3
1 5 2 6 3 7 4
2 5 3
4 4 1
1 7 3
```

Sample output:

```
5
6
3
```

## Idea

Keep one sorted-history snapshot per array prefix, like saving a cumulative tally after each card is dealt. This is a persistent segment tree over compressed value ranks.

Build a version for every prefix by copying one root-to-leaf path. A query subtracts the counts of the version before the range from the counts of the version at its end, then walks down to the k-th rank.

Sorting each query costs O(length log length), while each query here costs O(log n).

## Why It Works

1. Compressing values to ranks preserves their order and keeps the tree small.
2. Each version stores how many array values of every rank occur in its prefix.
3. Adding one value copies only the nodes along a single root-to-leaf path.
4. Subtracting the versions before `i` and at `j` leaves counts for exactly the range `i` to `j`.
5. Walking toward the child that holds the k-th remaining rank returns the k-th smallest value.

| term | meaning |
|---|---|
| `distinctValues` | sorted unique array values, indexed by rank |
| `versionRoots` | root node of the persistent tree for each prefix |
| `subtreeCount` | number of values stored in a node's rank interval |
| `leftAmount` | number of range values in the current left half |

The term table names the arrays that make prefix subtraction work.

A worked example from the sample uses `Q(2,5,3)` over values `5 2 6 3`:

```
ranks present: 2, 3, 5, 6
range 1..7, left half 1..4 holds 2 values; k=3 goes right with k=1
range 5..7, left half 5..6 holds 2 values; k=1 goes left
range 5..5, rank 5 maps to value 5
```

The walk returns five, matching the first sample answer.

## Code

**Input and scanning.** One read pass loads the input, and the scanner handles negative values.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value * sign
```

The minus branch is needed because array values can be negative.
Token boundaries come from non-digit characters, so spacing is irrelevant.
The whole input stays in one string during parsing.

**Buffered output.** Answers accumulate in a block buffer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes once per 128 KiB of answer text.
A single final write handles the remainder.

**Rank compression.** A bottom-up merge sort orders the values for rank lookup.

```nim
proc mergeSortAsc(data: var seq[int]) =
  let length = data.len
  if length < 2:
    return
  var buffer = newSeq[int](length)
  var runWidth = 1
  while runWidth < length:
    var blockStart = 0
    while blockStart < length:
      var leftPos = blockStart
      var rightPos = blockStart + runWidth
      let leftEnd = if blockStart + runWidth < length: blockStart + runWidth else: length
      let rightEnd = if blockStart + 2 * runWidth < length: blockStart + 2 * runWidth else: length
      var writePos = blockStart
      while leftPos < leftEnd and rightPos < rightEnd:
        if data[leftPos] <= data[rightPos]:
          buffer[writePos] = data[leftPos]
          leftPos = leftPos + 1
        else:
          buffer[writePos] = data[rightPos]
          rightPos = rightPos + 1
        writePos = writePos + 1
      while leftPos < leftEnd:
        buffer[writePos] = data[leftPos]
        leftPos = leftPos + 1
        writePos = writePos + 1
      while rightPos < rightEnd:
        buffer[writePos] = data[rightPos]
        rightPos = rightPos + 1
        writePos = writePos + 1
      blockStart = blockStart + 2 * runWidth
    for index in 0 .. length - 1:
      data[index] = buffer[index]
    runWidth = runWidth * 2
```

Merge sort uses an explicit order test instead of a comparator object.
Equal values stay adjacent, so one pass removes duplicates.
The sorted unique list maps each rank back to its actual value.

**Persistent versions.** Each prefix adds one path of nodes.

```nim
let elementCount = nextInt(inputData, scanPos)
let questionCount = nextInt(inputData, scanPos)
var values = newSeq[int](elementCount)
for index in 0 .. elementCount - 1:
  values[index] = nextInt(inputData, scanPos)

var sortedValues = newSeq[int](elementCount)
for index in 0 .. elementCount - 1:
  sortedValues[index] = values[index]
mergeSortAsc(sortedValues)

var distinctValues = newSeq[int](0)
for index in 0 .. elementCount - 1:
  if index == 0 or sortedValues[index] != sortedValues[index - 1]:
    distinctValues.add sortedValues[index]
let rankCount = distinctValues.len

let maxNodes = elementCount * 20 + 5
var leftChild = newSeq[int](maxNodes)
var rightChild = newSeq[int](maxNodes)
var subtreeCount = newSeq[int](maxNodes)
var versionRoots = newSeq[int](elementCount + 1)
var nodeCursor = 1

proc addVersion(previousNode: int, rangeLeft: int, rangeRight: int, rank: int): int =
  let currentNode = nodeCursor
  nodeCursor = nodeCursor + 1
  leftChild[currentNode] = leftChild[previousNode]
  rightChild[currentNode] = rightChild[previousNode]
  subtreeCount[currentNode] = subtreeCount[previousNode] + 1
  if rangeLeft != rangeRight:
    let rangeMiddle = (rangeLeft + rangeRight) div 2
    if rank <= rangeMiddle:
      leftChild[currentNode] = addVersion(leftChild[previousNode], rangeLeft, rangeMiddle, rank)
    else:
      rightChild[currentNode] = addVersion(rightChild[previousNode], rangeMiddle + 1, rangeRight, rank)
  return currentNode

for index in 0 .. elementCount - 1:
  var rank = 0
  var low = 0
  var high = rankCount - 1
  while low <= high:
    let middle = (low + high) div 2
    if distinctValues[middle] == values[index]:
      rank = middle + 1
      break
    elif distinctValues[middle] < values[index]:
      low = middle + 1
    else:
      high = middle - 1
  versionRoots[index + 1] = addVersion(versionRoots[index], 1, rankCount, rank)
```

Node zero is the empty tree, so node numbering starts at one.
Each update copies one node per level and changes only that path.
Binary search finds the rank of each array value.

**Range query.** Two root counts subtract, then one descent finds the k-th rank.

```nim
proc kthInRange(rightRoot: int, leftRoot: int, rangeLeft: int, rangeRight: int, order: int): int =
  if rangeLeft == rangeRight:
    return rangeLeft
  let rangeMiddle = (rangeLeft + rangeRight) div 2
  let leftAmount = subtreeCount[leftChild[rightRoot]] - subtreeCount[leftChild[leftRoot]]
  if order <= leftAmount:
    return kthInRange(leftChild[rightRoot], leftChild[leftRoot], rangeLeft, rangeMiddle, order)
  return kthInRange(rightChild[rightRoot], rightChild[leftRoot], rangeMiddle + 1, rangeRight, order - leftAmount)

for questionIndex in 0 .. questionCount - 1:
  let leftIndex = nextInt(inputData, scanPos)
  let rightIndex = nextInt(inputData, scanPos)
  let order = nextInt(inputData, scanPos)
  let rank = kthInRange(versionRoots[rightIndex], versionRoots[leftIndex - 1], 1, rankCount, order)
  appendOutput($distinctValues[rank - 1])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The root before the range removes values outside it.
The order shrinks by the left child count when the walk goes right.
The leaf rank maps back to the original value for output.

## Complexity

Building versions dominates the work before queries start.

| phase | time | space |
|---|---|---|
| rank sort | O(n log n) | one sorted copy |
| version build | O(n log n) node copies | about 20n nodes |
| queries | O(m log n) descent | constant per query |
| output | one block flush per 128 KiB | output buffer |

The phase table shows that each query touches one root-to-leaf path.

| measure | Big O |
|---|---|
| time | O(n log n + m log n) |
| space | O(n log n) |

Sorting each queried segment costs O(length log length) per query, which grows with the range size and the query count.
