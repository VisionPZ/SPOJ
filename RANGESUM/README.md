# RANGESUM — Range Sum (SPOJ)

<https://www.spoj.com/problems/RANGESUM/>

## Problem

An array starts with N integers. Each query either reports the sum of a chosen slice or pushes a new value onto the front. Report every slice sum in input order.

Input starts with N, then N integers, then Q. Each of the Q lines holds type one with two indices for a sum, or type two with one value for a front push. Indices are one-based and grow after each push. Print one line per type-one query and nothing for pushes.

| item | bound |
|---|---|
| initial size N | 1 to 100000 |
| query count Q | 1 to 100000 |
| array value | -1000000000 to 1000000000 |
| judge limit | 2000 ms, 1536 MB |

The push count drives the array capacity, and the value range drives 64-bit sums.

Sample input:

```
10
1 2 3 4 5 6 7 8 9 10
4
1 1 10
1 1 1
1 10 10
1 2 7
```

Sample output:

```
55
1
10
27
```

## Idea

Push work to one end of a fixed array, like adding pages to the front of a notebook while keeping the page numbers. Store suffix totals anchored at the far right, so a front push only writes one new cell. A slice sum becomes two stored totals subtracted. Sliding the front index turns insertion into a decrement and keeps each query constant time.

## Why It Works

1. The right anchor stays fixed for the whole run.
2. Each cell of `suffixSums` holds the total from its position through the anchor.
3. A front push writes the new value plus the next suffix total into the new front cell.
4. No older suffix total changes, because they all lie to the right of the new cell.
5. A slice from l to r equals the suffix at the first slice position minus the suffix at the position after the last.

| term | meaning |
|---|---|
| `frontIndex` | array position of the current first element |
| `tailIndex` | fixed anchor one cell past the final element |
| `suffixSums` | total from a position through the anchor |
| `initialFront` | front position before any push |

Every query uses two cells of the same table.

The sample walks through the table as follows.

```
front = 10, suffix[10..20] = 55 54 52 49 45 40 34 27 19 10 0
1 1 10 -> 55 - 0 = 55
1 1 1  -> 55 - 54 = 1
1 10 10 -> 10 - 0 = 10
1 2 7  -> 54 - 27 = 27
```

Each answer matches the sample output line by line.

## Code

**Input and scanner.** The whole input is read once, and the hand scanner accepts signed values.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  if negative:
    return -value
  return value
```

The minus branch handles negative array values and pushed values.
Token scanning skips all spacing and line breaks.
One pass loads every byte of input.

**Suffix table and queries.** The table is filled from the right, then each query reads two cells.

```nim
let initialCount = nextInt(inputData, scanPos)
let capacity = initialCount + 100000 + 3
var suffixSums = newSeq[int64](capacity)
let tailIndex = capacity - 1
let initialFront = tailIndex - initialCount
var frontIndex = initialFront
var currentIndex = initialFront
while currentIndex < tailIndex:
  let initialValue = int64(nextInt(inputData, scanPos))
  suffixSums[currentIndex] = initialValue
  currentIndex += 1
var runningSum: int64 = 0
var walkIndex = tailIndex
while walkIndex >= initialFront:
  runningSum = runningSum + suffixSums[walkIndex]
  suffixSums[walkIndex] = runningSum
  walkIndex -= 1
let queryCount = nextInt(inputData, scanPos)
var queryIndex = 0
while queryIndex < queryCount:
  let queryType = nextInt(inputData, scanPos)
  if queryType == 1:
    let leftIndex = nextInt(inputData, scanPos)
    let rightIndex = nextInt(inputData, scanPos)
    let firstPosition = frontIndex + leftIndex - 1
    let afterLast = frontIndex + rightIndex
    let rangeTotal = suffixSums[firstPosition] - suffixSums[afterLast]
    appendOutput($rangeTotal)
    outputBuffer.add '\n'
  else:
    let insertedValue = int64(nextInt(inputData, scanPos))
    frontIndex -= 1
    suffixSums[frontIndex] = insertedValue + suffixSums[frontIndex + 1]
  queryIndex += 1
stdout.write outputBuffer
outputBuffer.setLen 0
```

Capacity reserves one cell per possible push.
The backward pass builds all suffix totals in one sweep.
Pushes never rewrite existing cells, and output is flushed from one buffer.

## Complexity

Each phase touches a fixed number of cells per item.

| phase | time | space |
|---|---|---|
| input read | one pass over all tokens | one input string |
| suffix build | one backward pass over N cells | one int64 table |
| each query | one subtraction or one cell write | front index |
| output | one block flush | one output string |

A push costs one write, and a sum costs two reads.

| measure | Big O |
|---|---|
| time | O(N + Q) |
| space | O(N + Q) |

A shifting list would spend O(N) on every push, while the suffix table spends O(1). The fixed anchor keeps the whole run linear.
