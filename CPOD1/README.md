# CPOD1 — Closest pairs in 1D V1 (SPOJ)

<https://www.spoj.com/problems/CPOD1/>

## Problem

Given several arrays of integers, find the smallest distance between any two different values in each array.

The input starts with the test count. Each test gives its array size, then that many integers. Print one distance per test.

| item | bound |
|---|---|
| tests t | 1 to 10 |
| array size n | 2 to 100000 |
| value | -2000000000 to 2000000000 |
| judge limit | 1000 ms, 1536 MB |

Values are signed, so the scanner accepts a minus sign.

Sample input:

```
2
5
-2 -1 0 1 2
2
1 10
```

Sample output:

```
1
9
```

## Idea

Sort the values, like lining up people by height before measuring neighbours. In sorted order the closest pair must sit side by side. Compare each adjacent pair once and keep the smallest gap. Checking every pair would cost quadratic work.

## Why It Works

1. Sorting preserves all values and groups nearby values together.
2. For any two non-adjacent values, a value between them is at least as close to one of them.
3. Therefore the minimum gap occurs between adjacent sorted values.
4. One pass over adjacent pairs finds that gap.

| term | meaning |
|---|---|
| `values` | sorted array for one test |
| `closestGap` | smallest adjacent gap seen so far |
| `increasingOrder` | comparator used by the sort |

The gap is non-negative and fits in int64.

Script-generated trace for the first sample array:

```
sorted | -2 | -1 | 0 | 1 | 2
gap | 1 | 1 | 1 | 1
closest | 1
```

The closest gap is 1, matching the first sample answer.

## Code

**Bulk input and scanner.** The whole stream is read once and parsed with signed integers.

```nim
import algorithm

const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextSignedInt(data: string, position: var int): int64 =
  while position < data.len and data[position] != '-' and (data[position] < '0' or data[position] > '9'):
    position += 1
  var negative = false
  if position < data.len and data[position] == '-':
    negative = true
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc increasingOrder(left, right: int64): int =
  if left < right:
    return -1
  if left > right:
    return 1
  return 0

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The sign branch keeps negative values intact.
The comparator gives ascending order explicitly.
The buffer flushes only at the block boundary.

**Sort and gap pass.** Each test costs one sort and one linear scan.

```nim
let caseCount = int(nextSignedInt(inputData, scanPos))
var values = newSeq[int64](0)
for caseIndex in 0..<caseCount:
  let elementCount = int(nextSignedInt(inputData, scanPos))
  values.setLen elementCount
  for i in 0..<elementCount:
    values[i] = nextSignedInt(inputData, scanPos)
  sort(values, increasingOrder)
  var closestGap = values[1] - values[0]
  for i in 1..<elementCount:
    let gap = values[i] - values[i - 1]
    if gap < closestGap:
      closestGap = gap
  appendOutput($closestGap & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The first gap seeds the running minimum.
Only adjacent values are compared.
Each test writes one buffered line.

## Complexity

Sorting dominates each test.

| phase | time | space |
|---|---|---|
| input read | one pass over n values | one input string |
| sort | O(n log n) comparisons | array of n integers |
| gap pass | one pass over n values | a few counters |
| output | one line per test | block buffer |

Pairs are never compared directly.

| measure | Big O |
|---|---|
| time | O(n log n) per test |
| space | O(n) |

Checking all pairs would cost O(n squared) and repeat the same comparisons.
