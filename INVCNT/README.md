# INVCNT — Inversion Count (SPOJ)

<https://www.spoj.com/problems/INVCNT/>

## Problem

Given an array of `n` distinct positive integers, count all index pairs `(i, j)` with `i < j` and `A[i] > A[j]`. Each such out-of-order pair is called an inversion.

Input begins with `t`, the number of test cases, separated by blank lines. Each test case gives `n`, followed by `n` integers on separate lines. Output one line per test case with the total inversion count.

This table lists the constraints and judge limits.

| item | bound |
|---|---|
| array length `n` | 1 <= n <= 200 000 |
| values `A[i]` | 1 <= A[i] <= 10^7 |
| max inversions | n * (n - 1) / 2 ~ 2 * 10^10 |
| judge limit | 3600 ms, 1536 MB, 50000 B |

Because the count can reach `2 * 10^10`, 64-bit integers are required.

Sample input:

```
2

3
3
1
2

5
2
3
8
6
1
```

Sample output:

```
2
5
```

## Idea

Counting inversions while sorting is like tallying how many cards jump left when you merge two sorted decks. Bottom-up merge sort splits the array into sorted runs of width `1, 2, 4, ...` and merges adjacent pairs in `O(n log n)` time. Whenever the next element from the right run is smaller than the current element of the left run, it forms an inversion with every remaining element in the left run.

Checking every pair directly costs `O(n^2)` time, which exceeds the time limit at `n = 200 000`.

## Why It Works

1. Every pair `(i, j)` with `i < j` has `i` in the left run and `j` in the right run during exactly one merge step.
2. Both runs are already sorted in ascending order when they merge.
3. When `values[rightIdx] < values[leftIdx]`, `values[rightIdx]` is smaller than `values[leftIdx]` and all elements after `leftIdx` in the left run, adding `mid - leftIdx` inversions in `O(1)` time.
4. When `values[leftIdx] <= values[rightIdx]`, no inversion is added and stability is preserved.

This table lists the variables used in the iterative merge.

| term | meaning |
|---|---|
| `values` | current array state between merge passes |
| `scratch` | reusable buffer receiving merged runs |
| `runWidth` | current sorted run size (powers of 2) |
| `mid - leftIdx` | remaining left-run elements larger than `values[rightIdx]` |

Hoisting `values` and `scratch` outside the test loop eliminates per-case allocations.

Worked example for `[2, 3, 8, 6, 1]`:

```
width 1: [2,3] (+0), [6,8] (+1: 6<8), [1] (+0) -> [2, 3, 6, 8, 1]
width 2: [2,3,6,8] (+0), [1] (+0)              -> [2, 3, 6, 8, 1]
width 4: merge [2,3,6,8] and [1] (+4: 1 < 2,3,6,8) -> [1, 2, 3, 6, 8]
total  : 0 + 1 + 4 = 5
```

Every inversion is counted once, giving 5.

## Code

**Bulk input, digit scanner, and output buffer.** Reads stdin once, scans non-negative integers by index, and flushes output in 128 KiB blocks.

```nim
const flushBlockBytes = 1 shl 17
const maxArraySize = 200000

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
```

Skipping all non-digit bytes handles blank lines between test cases automatically.

**Bottom-up merge sort inversion counter.** Merges runs of doubling width in `values` using hoisted `scratch` and accumulates cross-run inversions in `int64`.

```nim
var values = newSeq[int](maxArraySize)
var scratch = newSeq[int](maxArraySize)

proc countInversions(length: int): int64 =
  var totalInversions: int64 = 0
  var runWidth = 1
  while runWidth < length:
    var leftStart = 0
    while leftStart < length:
      let mid = leftStart + runWidth
      if mid >= length:
        for idx in leftStart .. length - 1:
          scratch[idx] = values[idx]
        break
      var rightEnd = mid + runWidth
      if rightEnd > length:
        rightEnd = length
      var leftIdx = leftStart
      var rightIdx = mid
      var writeIdx = leftStart
      while leftIdx < mid and rightIdx < rightEnd:
        if values[leftIdx] <= values[rightIdx]:
          scratch[writeIdx] = values[leftIdx]
          leftIdx += 1
        else:
          scratch[writeIdx] = values[rightIdx]
          totalInversions += int64(mid - leftIdx)
          rightIdx += 1
        writeIdx += 1
      while leftIdx < mid:
        scratch[writeIdx] = values[leftIdx]
        leftIdx += 1
        writeIdx += 1
      while rightIdx < rightEnd:
        scratch[writeIdx] = values[rightIdx]
        rightIdx += 1
        writeIdx += 1
      leftStart = rightEnd
    for idx in 0 .. length - 1:
      values[idx] = scratch[idx]
    runWidth = runWidth shl 1
  return totalInversions
```

The outer loop runs `ceil(log2(length))` passes, and each pass copies `length` elements once. Using an iterative loop avoids recursion overhead.

**Driver loop.** Loads each test case into `values`, computes its inversion count, and flushes remaining output.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIdx in 0 .. caseCount - 1:
  let elementCount = nextInt(inputData, scanPos)
  for idx in 0 .. elementCount - 1:
    values[idx] = nextInt(inputData, scanPos)
  let answer = countInversions(elementCount)
  appendOutput($answer)
  appendOutput("\n")

if outputBuffer.len > 0:
  stdout.write outputBuffer
  outputBuffer.setLen 0
```

Each case overwrites the first `elementCount` slots of `values` without reallocating memory.

## Complexity

This table summarizes time and space per test case of length `n`.

| phase | time | space |
|---|---|---|
| read array | O(n) | O(n) |
| bottom-up merge | O(n log n) | O(n) |
| emit answer | O(1) | O(1) |

The `O(n log n)` merge dominates every case.

This table states the overall Big O bounds per test case.

| measure | big O |
|---|---|
| time | O(n log n) |
| space | O(n) |

Direct pairwise comparison takes `O(n^2)` time, whereas merge counting finishes `n = 200 000` in milliseconds.
