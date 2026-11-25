# INCDSEQ — Distinct Increasing Subsequences (SPOJ)

<https://www.spoj.com/problems/INCDSEQ/>

## Problem

Count distinct value sequences of length K that appear as increasing subsequences. Print the count modulo 5,000,000. One test is given.

Line 1 holds N and K. The next N lines hold the sequence values in order. Output holds one integer.

| item | bound |
|---|---|
| length N | 1 to 10,000 |
| subsequence length K | 1 to 50, and at most N |
| value Si | 0 to 999,999,999 |
| modulus | 5,000,000 |
| judge limit | 1000 ms, 1536 MB |

Two position choices that give the same value sequence count once here.

Sample input and output:

```
4 3
1
2
2
10
```

```
1
```

Both position choices for 2 produce the same sequence 1, 2, 10.

## Idea

A repeat of a value must replace the old contribution, like updating one row in a ledger instead of writing a second copy. The Fenwick tree for each length holds the current contribution of every value. A repeat subtracts the old row and stores the new row.

Compress the large values to dense ranks first. For a rank r and length k, count only trees of length k-1 at ranks below r. Replace the old count at rank r with that sum. The final total is the length-K tree summed over all ranks.

Each element costs K prefix queries and K updates, all O(log N). Naive enumeration of value tuples is exponential.

Replacement removes duplicates without extra state per subsequence.

## Why It Works

1. Compressed ranks preserve the strict value order, so increasing means increasing rank.
2. An increasing subsequence ending at rank r extends only subsequences ending at ranks below r.
3. For each length, the Fenwick tree holds the current number of distinct subsequences ending at each rank.
4. When a value repeats, the same set of distinct value sequences ending there is produced again.
5. Subtracting the stored old count and adding the new count replaces that set exactly once.
6. Lengths run from K down to 2, so the current element cannot extend itself.
7. The answer is the sum over all ranks in the length-K tree, reduced modulo 5,000,000.

| term | meaning |
|---|---|
| `sortedValues` | distinct values in order after compression |
| `valueRank` | one-based compressed index of the current value |
| `fenwickTrees` | current count per rank for each subsequence length |
| `lastCounts` | count previously stored at each rank, used for replacement |
| `newlyFound` | count of shorter sequences ending at a smaller rank |

The table names the state used by the replacement step.

A scripted trace of the sample uses K = 3 and values 1, 2, 2, 10.

```
value 1: length 1 contribution at rank 1 becomes 1
value 2: length 2 contribution becomes 1 from the smaller rank 1
second 2: length 2 contribution is again 1, so the delta is 0
value 10: length 3 contribution becomes 1 from the stored length-2 count
answer = 1
```

The zero delta is the step that removes the duplicate from the sample.

## Code

**Input and tree helpers.** The reader compresses values and defines Fenwick operations.

```nim
import algorithm

const flushBlockBytes = 1 shl 17
const modulusValue = 5000000

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

proc prefixQuery(tree: seq[int], upperIndex: int): int =
  var total = 0
  var cursor = upperIndex
  while cursor > 0:
    total = (total + tree[cursor]) mod modulusValue
    cursor -= cursor and (-cursor)
  return total

proc addToTree(tree: var seq[int], startIndex: int, deltaValue: int) =
  var cursor = startIndex
  while cursor <= tree.len - 1:
    tree[cursor] = (tree[cursor] + deltaValue) mod modulusValue
    cursor += cursor and (-cursor)

proc findRank(sortedValues: seq[int], targetValue: int): int =
  var lowIndex = 0
  var highIndex = sortedValues.len - 1
  while lowIndex <= highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if sortedValues[middleIndex] < targetValue:
      lowIndex = middleIndex + 1
    elif sortedValues[middleIndex] > targetValue:
      highIndex = middleIndex - 1
    else:
      return middleIndex + 1
  return 0
```

Values up to 1e9 need compression before indexing a tree.
The query upper index is one less than the current rank.
Tree updates use the number of distinct values as their limit.

**Compression and replacement sweep.** Each value replaces, rather than adds to, each rank row.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let elementCount = nextInt(inputData, scanPos)
let subsequenceLength = nextInt(inputData, scanPos)
var sequenceValues = newSeq[int](elementCount)
var sortedValues = newSeq[int](elementCount)
for position in 0 .. elementCount - 1:
  sequenceValues[position] = nextInt(inputData, scanPos)
  sortedValues[position] = sequenceValues[position]
sortedValues.sort(proc (leftValue, rightValue: int): int = cmp(leftValue, rightValue))
var distinctCount = 0
for position in 0 .. elementCount - 1:
  if position == 0 or sortedValues[position] != sortedValues[position - 1]:
    sortedValues[distinctCount] = sortedValues[position]
    distinctCount += 1
sortedValues.setLen(distinctCount)
var fenwickTrees = newSeq[seq[int]](subsequenceLength + 1)
var lastCounts = newSeq[seq[int]](subsequenceLength + 1)
for lengthIndex in 0 .. subsequenceLength:
  fenwickTrees[lengthIndex] = newSeq[int](distinctCount + 1)
  lastCounts[lengthIndex] = newSeq[int](distinctCount + 1)
for position in 0 .. elementCount - 1:
  let valueRank = findRank(sortedValues, sequenceValues[position])
  for lengthIndex in countdown(subsequenceLength, 2):
    let newlyFound = prefixQuery(fenwickTrees[lengthIndex - 1], valueRank - 1)
    var deltaValue = (newlyFound - lastCounts[lengthIndex][valueRank]) mod modulusValue
    if deltaValue < 0:
      deltaValue += modulusValue
    addToTree(fenwickTrees[lengthIndex], valueRank, deltaValue)
    lastCounts[lengthIndex][valueRank] = newlyFound
  var singleDelta = (1 - lastCounts[1][valueRank]) mod modulusValue
  if singleDelta < 0:
    singleDelta += modulusValue
  addToTree(fenwickTrees[1], valueRank, singleDelta)
  lastCounts[1][valueRank] = 1
let answerValue = prefixQuery(fenwickTrees[subsequenceLength], distinctCount)
appendOutput($answerValue)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

A negative difference becomes positive with one modular guard.
Every tree holds at most 10,001 entries per length.
The swept total is already the final answer.

## Complexity

The work is compression plus one replacement sweep.

| phase | time | space |
|---|---|---|
| input read | one pass over N values | one input string |
| compression | sort of N values | N values |
| replacement sweep | N times K tree operations | K trees and K rows |
| output | one line | block buffer |

The replacement sweep dominates the runtime.

| measure | Big O |
|---|---|
| time | O(N K log N) |
| space | O(N K) |

Enumerating value tuples costs exponential time and cannot handle N near 10,000.

Compression plus replacement keeps every duplicate out of the total.
