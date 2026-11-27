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

Sort the values, like lining up people by height before measuring neighbors. In sorted order the closest pair must sit side by side. Compare each adjacent pair once and keep the smallest gap. Checking every pair would cost quadratic work.

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

**Bulk input and scanner.** One read loop loads the whole stream and a signed scanner parses each integer.

```nim
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

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc radixSortAscending(values: var seq[int64], count: var seq[int], scratch: var seq[int64]) =
  let n = values.len
  var minValue = values[0]
  var maxValue = values[0]
  for i in 1..<n:
    if values[i] < minValue: minValue = values[i]
    if values[i] > maxValue: maxValue = values[i]
  if minValue == maxValue: return
  for i in 0..<n: values[i] = values[i] - minValue
  var walk = cast[uint64](maxValue - minValue)
  var bits = 0
  while walk > 0'u64:
    bits += 1
    walk = walk shr 1
  let passes = (bits + 11) div 12
  let digitMask = 0xFFF'u64
  scratch.setLen n
  var shift = 0
  for pass in 0..<passes:
    for i in 0..4095: count[i] = 0
    for i in 0..<n:
      inc count[int((cast[uint64](values[i]) shr shift) and digitMask)]
    var total = 0
    for i in 0..4095:
      let c = count[i]
      count[i] = total
      total += c
    for i in 0..<n:
      let d = int((cast[uint64](values[i]) shr shift) and digitMask)
      scratch[count[d]] = values[i]
      inc count[d]
    swap(values, scratch)
    shift += 12
```

The minus sign is kept by the scanner.
All cases are parsed before sorting starts.
The buffer flushes only on large blocks.

**Sort and closest gap.** One sort and one adjacent pass answer each case.

```nim
let caseCount = int(nextSignedInt(inputData, scanPos))
var values = newSeq[int64](0)
var scratchValues = newSeq[int64](0)
var count = newSeq[int](4096)
for caseIndex in 0..<caseCount:
  let elementCount = int(nextSignedInt(inputData, scanPos))
  values.setLen elementCount
  for i in 0..<elementCount:
    values[i] = nextSignedInt(inputData, scanPos)
  radixSortAscending(values, count, scratchValues)
  var closestGap = values[1] - values[0]
  for i in 1..<elementCount:
    let gap = values[i] - values[i - 1]
    if gap < closestGap:
      closestGap = gap
      if closestGap == 0: break
  appendOutput($closestGap & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The first adjacent pair seeds the gap.
Each later pair can replace it.
One line is written per case.

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
