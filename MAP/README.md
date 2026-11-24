## Problem

Read the populations of regions in Byteland for each test case. Split the regions into m colors so regions with similar populations share a color. Each color uses a representative population A with at least half of its regions on either side. Print the smallest sum of absolute differences for each case.

The statement and judge page give these bounds.

| Quantity | Bound |
| --- | --- |
| Test cases t | not specified |
| Regions n | 10 < n < 3000 |
| Colors m | 2 ≤ m ≤ 10 |
| Population | at most 2^30 |
| Time limit | 7000 ms |
| Memory limit | 1536 MB |

The region count and color count set the table size; populations only widen the arithmetic.

## Idea

Sort the populations and give each color one contiguous block of the sorted list. Prefix sums make the cost of any block a constant-time lookup, so dynamic programming can try every split point for each color and prefix. Enumeration of all colorings is exponential, while this table is quadratic.

Cost per transition: constant time. Total transitions: about m·n²/2.

## Why It Works

Two facts make this correct. In sorted order, blocks never cross: exchanging a larger value for a smaller one across two colors cannot raise the error. The best representative of a block is a median, which puts at least half of the values on each side.

`medianIndex = (leftIndex + rightIndex) div 2` picks a median position in the sorted block.
`leftCount = medianIndex - leftIndex + 1` counts the values at or below the median.
`leftSum = prefixSums[medianIndex + 1] - prefixSums[leftIndex]` adds those values.
`int64(leftCount) * medianValue - leftSum` is the deviation on the left side.
`rightSum - int64(rightCount) * medianValue` is the deviation on the right side.
`blockCost` returns the sum of those two deviations as the cost of one color.

The generator prints this trace for the sample:

```
sorted: [2, 2, 2, 3, 6, 10, 12, 14, 15, 18, 21]
block [0,4] median 2 cost 5
block [5,7] median 12 cost 4
block [8,10] median 18 cost 6
total: 15
```

The three block costs add to 15, the sample answer.

## Code

```nim
{.passC: "-O2".}
{.push checks: off.}
import algorithm

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxRegionCount = 3000
const infiniteCost = int64.high div 4

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, scanPos: var int): int =
  while scanPos < data.len and (data[scanPos] < '0' or data[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < data.len and data[scanPos] >= '0' and data[scanPos] <= '9':
    value = value * 10 + int(data[scanPos]) - firstDigitValue
    scanPos += 1
  return value
```

The read loop runs once per input line and fills one buffer. The scanner stops on any non-digit, so blank lines between cases need no special branch. Each scan walks forward once, at a cost linear in the input size.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The flush fires once per 256 KiB of answer text, not once per answer. The size test avoids a write on every line. The cost is one write per full block.

```nim
var sortedValues: seq[int64] = @[]
var prefixSums: array[0..maxRegionCount + 1, int64]
var previousCosts: array[0..maxRegionCount, int64]
var currentCosts: array[0..maxRegionCount, int64]

proc blockCost(leftIndex, rightIndex: int): int64 =
  let medianIndex = (leftIndex + rightIndex) div 2
  let leftCount = medianIndex - leftIndex + 1
  let rightCount = rightIndex - medianIndex
  let leftSum = prefixSums[medianIndex + 1] - prefixSums[leftIndex]
  let rightSum = prefixSums[rightIndex + 1] - prefixSums[medianIndex + 1]
  let medianValue = sortedValues[medianIndex]
  return int64(leftCount) * medianValue - leftSum + rightSum - int64(rightCount) * medianValue
```

`leftIndex` and `rightIndex` bound one sorted block; `medianIndex` is its median. The extra prefix slot covers a block ending at the last region. One call costs constant time and runs once per split point.

```nim
let caseCount = nextInt(inputData, scanPos)
for i in 0..<caseCount:
  let regionCount = nextInt(inputData, scanPos)
  let colorCount = nextInt(inputData, scanPos)
  sortedValues.setLen(regionCount)
  for j in 0..<regionCount:
    sortedValues[j] = int64(nextInt(inputData, scanPos))
  sortedValues.sort(system.cmp[int64])
  prefixSums[0] = 0
  for j in 0..<regionCount:
    prefixSums[j + 1] = prefixSums[j] + sortedValues[j]
  for j in 0..regionCount:
    previousCosts[j] = infiniteCost
  for j in 1..regionCount:
    previousCosts[j] = blockCost(0, j - 1)
  for colorIndex in 2..colorCount:
    for j in 0..regionCount:
      currentCosts[j] = infiniteCost
    for coloredCount in colorIndex..regionCount:
      var bestCost = infiniteCost
      for k in (colorIndex - 1)..(coloredCount - 1):
        let candidateCost = previousCosts[k] + blockCost(k, coloredCount - 1)
        if candidateCost < bestCost:
          bestCost = candidateCost
      currentCosts[coloredCount] = bestCost
    swap previousCosts, currentCosts
  appendOutput($(previousCosts[regionCount]))
  outputBuffer.add '\n'
```

`i` walks cases, `j` walks prefix lengths, and `k` walks split points. Starting each split at `colorIndex - 1` keeps every color nonempty; `infiniteCost` discards unreachable states. Two rolling rows replace a full m by n table, so the loop runs about m·n²/2 times with linear storage.

```nim
stdout.write outputBuffer
outputBuffer.setLen 0
{.pop.}
```

One final write emits the bytes left under `flushBlockBytes`. Without it the last answer would stay in memory. The flush costs one write and ends the run.

## Complexity

Sorting costs O(n log n) per case and the prefix pass costs O(n). The DP costs O(m n²) time and holds two rows of n costs plus the prefix sums.

Total time is O(m n²) and total space is O(n). Direct enumeration of colorings costs O(m^n).
