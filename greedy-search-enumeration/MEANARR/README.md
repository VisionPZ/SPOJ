# MEANARR — Mean of array (SPOJ)

<https://www.spoj.com/problems/MEANARR/>

## Problem

Count the subarrays whose average is at least `K`. Subtracting `K` from each element turns the average test into a sum test.

The input has two integers `N` and `K` on the first line, then `N` array values on the next line. Output one integer: the number of qualifying subarrays.

| item | bound |
|---|---|
| elements N | 1 to 200000 |
| threshold K | 1 to 2147483647 |
| each array value | 1 to 2147483647 |
| judge limit | 1000 ms, 1536 MB |

The value bound drives the design: `N` is large, so a quadratic scan cannot pass.

Sample input:

```
5 4
5 2 4 5 1
```

Sample output:

```
5
```

## Idea

Subtracting `K` from every value and counting negative-sum subarrays is like removing the bad apples from a crate and counting what remains. The real algorithm counts decreasing prefix-sum pairs with a merge sort. Each prefix costs `O(log N)` work during merging, so the total is `O(N log N)`. A naive scan checks every subarray sum and costs `O(N^2)`, which is too slow at `N = 200000`. Count the rejections once, then subtract them from the total.

## Why It Works

1. A subarray from `i+1` to `j` has average at least `K` exactly when its sum is at least `K` times its length.
2. Subtract `K` from each element, and that condition becomes `prefix[j] - prefix[i] >= 0`.
3. The failing subarrays are therefore the pairs `i < j` with `prefix[j] < prefix[i]`.
4. A merge sort counts those strict pairs while merging two sorted halves.
5. Every qualifying subarray is the complement of one failing pair.

| term | meaning |
|---|---|
| `prefixSums` | running total of `value - K` up to each position |
| `decreasingPairs` | prefix pairs where the later prefix is smaller |
| `scratchSums` | temporary array used while merging |
| `totalSubarrays` | `N` times `N+1` divided by two |

For the sample, the adjusted values are `1 -2 0 1 -3`, and the prefixes are `0 1 -1 -1 0 -3`. Ten prefix pairs decrease, so `15 - 10 = 5`. Arithmetic uses exact integers, so no rounding guard is needed.

## Code

**Input and scanning.** The reader loads the header and the array, then builds adjusted prefix sums.

```nim
const flushBlockBytes = 1 shl 17

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

The scanner skips separators and advances one index per number.
Prefix sums use `int64` because 200000 values up to 2^31 exceed 32 bits.
Output stays in one buffer until the block limit or the final flush.

**Merge count.** Each merge adds the number of strict inversions across the two halves.

```nim
let elementCount = nextInt(inputData, scanPos)
let requiredMean = nextInt(inputData, scanPos)

var prefixSums = newSeq[int64](elementCount + 1)
for elementIndex in 1 .. elementCount:
  let currentValue = nextInt(inputData, scanPos)
  prefixSums[elementIndex] = prefixSums[elementIndex - 1] + int64(currentValue - requiredMean)

var scratchSums = newSeq[int64](elementCount + 1)
var decreasingPairs: int64 = 0

proc mergeCount(leftStart: int, rightEnd: int) =
  if rightEnd - leftStart < 2:
    return
  let middleIndex = (leftStart + rightEnd) div 2
  mergeCount(leftStart, middleIndex)
  mergeCount(middleIndex, rightEnd)
  var leftPos = leftStart
  var rightPos = middleIndex
  var writePos = leftStart
  while leftPos < middleIndex and rightPos < rightEnd:
    if prefixSums[leftPos] <= prefixSums[rightPos]:
      scratchSums[writePos] = prefixSums[leftPos]
      leftPos += 1
    else:
      scratchSums[writePos] = prefixSums[rightPos]
      decreasingPairs += int64(middleIndex - leftPos)
      rightPos += 1
    writePos += 1
  while leftPos < middleIndex:
    scratchSums[writePos] = prefixSums[leftPos]
    leftPos += 1
    writePos += 1
  while rightPos < rightEnd:
    scratchSums[writePos] = prefixSums[rightPos]
    rightPos += 1
    writePos += 1
  for copyPos in leftStart .. rightEnd - 1:
    prefixSums[copyPos] = scratchSums[copyPos]

mergeCount(0, elementCount + 1)
let totalSubarrays = int64(elementCount) * int64(elementCount + 1) div 2
appendOutput($(totalSubarrays - decreasingPairs))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The strict `<=` test keeps equal prefixes out of the rejection count.
When a right value wins, all remaining left values form inversions at once.
The final subtraction counts the accepted subarrays.

## Complexity

Each merge pass touches every prefix once.

| phase | time | space |
|---|---|---|
| input read | one pass over the array | one input string |
| prefix build | `O(N)` | `N` prefix values |
| merge count | `O(N log N)` | `N` scratch values |
| output | one line | block buffer |

The merge pass dominates the running time.

| measure | Big O |
|---|---|
| time | `O(N log N)` |
| space | `O(N)` |

A quadratic scan of all subarrays would cost `O(N^2)`, so the merge count is the deciding gain. Counting rejections first gives the same answer in far less time.
