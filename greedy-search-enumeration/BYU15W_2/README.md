# BYU15W_2 — Grid Arithmetic (SPOJ)

<https://www.spoj.com/problems/BYU15W_2/>

## Problem

Pick one cell from every row and every column of a square matrix. Give each picked cell a plus or minus sign and make the signed sum as close to zero as possible. Report the smallest absolute sum.

The input starts with `caseCount`. Each case gives `matrixSize`, then `matrixSize` rows of `matrixSize` integers. Print one absolute value per case.

| item | bound |
|---|---|
| `matrixSize` | up to 10 |
| matrix values | signed integers |
| signed sums | fit in a signed 32-bit integer |
| judge limit | 1000 ms, 1536 MB |

The row count is small enough for an exhaustive split but too large for a plain product of all signed permutations.

Sample input:

```
2
2
1 5
4 3
3
1 75 10
22 500 3
9 125 50
```

Sample output:

```
1
3
```

## Idea

Splitting the rows in half turns one huge search into two small lists, like finding two puzzle pieces whose values cancel. Generate every signed column choice for each half and group the sums by the set of columns used. Then match each group with the complementary group from the other half and scan for the pair closest to zero. A full search visits `matrixSize!` times two to the `matrixSize` choices; the split visits about twice the square root of that.

## Why It Works

1. Every valid solution picks exactly one column per row, so the two row halves use disjoint column sets.
2. A column mask records which columns one half uses, so the other half must use the complement mask.
3. For one mask, the signed sums of the first half form a sorted list; the complementary second-half list is sorted too.
4. A two-pointer walk starts at the smallest first-half sum and the largest second-half sum. Moving the pointer toward zero visits the closest pair in linear time.
5. The smallest absolute sum seen over all masks is the global optimum, because every signed permutation belongs to exactly one complementary mask pair.

| term | meaning |
|---|---|
| `firstRows` | row count of the upper half |
| `usedMask` | bit set of columns already taken |
| `runningSum` | signed sum of the current partial choice |
| `firstBuckets` | signed sums grouped by column mask |
| `fullMask` | bit set of all columns |
| `bestAbs` | smallest absolute sum found |

A worked trace for the first sample case follows.

```
matrix       [1 5]
             [4 3]
firstRows    1
secondRows   1
mask 1       first  {1, -1}   second mask 2 {3, -3}
mask 2       first  {5, -5}   second mask 1 {4, -4}
mask 1 best  |1 - 3| = 2
mask 2 best  |5 - 4| = 1
answer       1
```

The choice `5 - 4 = 1` uses one cell from each row and each column, matching the sample.

## Code

**Input and hand scanner.** The reader loads stdin once and parses signed integers.

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
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * value
```

A minus sign is accepted because matrix entries may be negative.
Values are widened to int64 before sums are formed.
`nextInt` ignores whitespace and line breaks between cells.

**Buffered output.** One block buffer collects all case answers.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Each case appends one number and one newline.
A write occurs only when the buffer reaches `flushBlockBytes`.
The last flush follows the case loop.

**Partial-choice generation.** Recursion enumerates signed column choices for each row half.

```nim
proc fillBuckets(matrixValues: seq[int64], rowOffset: int, groupSize: int,
                 columnCount: int, rowIndex: int, usedMask: int,
                 runningSum: int64, buckets: var seq[seq[int64]]) =
  if rowIndex == groupSize:
    buckets[usedMask].add runningSum
    return
  let matrixRow = rowOffset + rowIndex
  var columnIndex = 0
  while columnIndex < columnCount:
    if (usedMask and (1 shl columnIndex)) == 0:
      let cellValue = matrixValues[matrixRow * columnCount + columnIndex]
      let nextMask = usedMask or (1 shl columnIndex)
      fillBuckets(matrixValues, rowOffset, groupSize, columnCount, rowIndex + 1,
                  nextMask, runningSum + cellValue, buckets)
      fillBuckets(matrixValues, rowOffset, groupSize, columnCount, rowIndex + 1,
                  nextMask, runningSum - cellValue, buckets)
    columnIndex += 1
```

`usedMask` prevents choosing a column twice.
Each cell contributes once with a plus sign and once with a minus sign.
Every leaf stores its `runningSum` in the bucket for its mask.

**Bucket sorting.** Sorted buckets enable the two-pointer scan.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let matrixSize = nextInt(inputData, scanPos)
  var matrixValues = newSeq[int64](matrixSize * matrixSize)
  for cellIndex in 0 .. matrixSize * matrixSize - 1:
    matrixValues[cellIndex] = int64(nextInt(inputData, scanPos))

  let firstRows = matrixSize div 2
  let secondRows = matrixSize - firstRows
  let maskCount = 1 shl matrixSize
  var firstBuckets = newSeq[seq[int64]](maskCount)
  var secondBuckets = newSeq[seq[int64]](maskCount)
  fillBuckets(matrixValues, 0, firstRows, matrixSize, 0, 0, 0, firstBuckets)
  fillBuckets(matrixValues, firstRows, secondRows, matrixSize, 0, 0, 0, secondBuckets)
  for bucketIndex in 0 .. maskCount - 1:
    firstBuckets[bucketIndex].sort(proc(leftValue, rightValue: int64): int =
      if leftValue < rightValue: return -1
      if leftValue > rightValue: return 1
      return 0)
    secondBuckets[bucketIndex].sort(proc(leftValue, rightValue: int64): int =
      if leftValue < rightValue: return -1
      if leftValue > rightValue: return 1
      return 0)
```

The two halves may differ by one row when `matrixSize` is odd.
`maskCount` bounds the bucket array at 1024 entries.
Each bucket is sorted with an explicit int64 comparator.

**Complementary scan.** One mask pair at a time yields the best cancellation.

```nim
  let fullMask = maskCount - 1
  var bestAbs: int64 = 1 shl 60
  for columnMask in 0 .. fullMask:
    let firstSums = firstBuckets[columnMask]
    let secondSums = secondBuckets[fullMask xor columnMask]
    if firstSums.len == 0 or secondSums.len == 0:
      continue
    var leftCursor = 0
    var rightCursor = secondSums.len - 1
    while leftCursor < firstSums.len and rightCursor >= 0:
      let combined = firstSums[leftCursor] + secondSums[rightCursor]
      let magnitude = if combined >= 0: combined else: -combined
      if magnitude < bestAbs:
        bestAbs = magnitude
      if combined > 0:
        rightCursor -= 1
      elif combined < 0:
        leftCursor += 1
      else:
        break
    if bestAbs == 0:
      break

  appendOutput($bestAbs)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

`fullMask xor columnMask` gives the only partner mask for this half.
The two pointers move toward the sum closest to zero.
A zero sum ends the search early.

## Complexity

Generation and sorting dominate the runtime.

| phase | time | space |
|---|---|---|
| generation | one leaf per signed partial choice | two bucket arrays |
| sorting | one sort per bucket | same buckets |
| scan | linear in both bucket sizes | constant |
| output | one line per case | block buffer |

| measure | Big O |
|---|---|
| time | O(P(n/2) · 2^(n/2) · log) per case |
| space | O(P(n/2) · 2^(n/2)) |

A plain search visits `n! · 2^n` signed permutations, while the split visits about twice as many half choices. The scan then couples the halves in linear time.
