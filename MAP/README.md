# MAP — The Map (SPOJ)
<https://www.spoj.com/problems/MAP/>

## Problem

A map maker must color regions using only a few colors. Regions with similar populations should share a color. The goal is the smallest total coloring error.

The input starts with the case count. Each case gives a region count, a color count, and one population per region. Print the minimum cumulative error.

The judge bounds are:

| Item | Bound |
| --- | --- |
| Regions `n` | 10 < n < 3000 |
| Colors `m` | 2 to 10 |
| Population | below 2^30 |
| Judge time | 7000 ms |
| Memory | 1536 MB |
| Source size | 50000 B |

The bounds allow an ordered sweep with dynamic programming.

Sample input and output:

Input:

```
1
11
3
21
14
6
18
10
2
15
12
3
2
2
```

Output:

```
15
```

## Idea

Sort the populations first, then cut the sorted list into color groups. Think of slicing a row of houses into contiguous blocks and marking each block with one number.

The best value for a group is its median (the middle population). The program computes each block cost from prefix sums. Dynamic programming (a table of best costs) then tries every split. A block costs O(1), and one case costs O(m * n^2). Trying every coloring of every region would be exponential.

Takeaway: sorting turns colors into contiguous slices.

## Why It Works

An optimal coloring never crosses populations in the sorted order.

1. Sort the populations, so each color owns a contiguous block.
2. The median minimizes the sum of absolute deviations in a block.
3. Prefix sums give that sum in constant time.
4. `previousCosts[j]` holds the best cost for the first `j` regions.
5. The inner loop tries every split point and keeps the minimum.

The terms are:

| Term | Meaning |
| --- | --- |
| `sortedValues` | Populations in increasing order |
| `prefixSums` | Running totals of sorted values |
| `medianValue` | Middle value of a block |
| `blockCost` | Sum of median deviations in a block |

Prefix sums remove repeated additions from each split test.

A script checked the sample case:

| Quantity | Value |
| --- | --- |
| Sorted populations | 2, 2, 2, 3, 6, 10, 12, 14, 15, 18, 21 |
| Regions | 11 |
| Colors | 3 |
| Minimum error | 15 |

The three-color split reaches the sample answer.

## Code

**Compiler pragmas and constants.**

```nim
{.passC: "-O2".}
{.push checks: off.}
import algorithm

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxRegionCount = 3000
const infiniteCost = int64.high div 4
```

Checks are disabled for speed. `maxRegionCount` fixes the table size. `infiniteCost` marks states that are not reachable.

**Input and output helpers.**

```nim
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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

All lines join one buffer. The hand scanner reads integers without splitting strings. Answers collect in one buffer and flush in blocks.

**Cost tables and block cost.**

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

Two cost rows hold the dynamic program. `blockCost` reads a median and two prefix sums. One call costs constant time.

**Dynamic program.**

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

The first row costs one color. Each new color fills the next row by trying split points. Rows swap after every color, so memory stays fixed.

**Final flush.**

```nim
stdout.write outputBuffer
outputBuffer.setLen 0
{.pop.}
```

One write emits the remaining answers. The closing pragma restores default checks.

## Complexity

Sorting and the table fill dominate each case.

| Phase | Time | Space |
| --- | --- | --- |
| Input | O(Total digits) | O(Input size) |
| Sort | O(n log n) | O(n) |
| Dynamic program | O(m * n^2) | O(n) |
| Output | O(T) | O(1) |

The split loop sets the total cost.

| Measure | Bound |
| --- | --- |
| Time | O(m * n^2) per case |
| Space | O(n) per case |

At most 90 million split tests run in one case.

Coloring regions independently would explore far more combinations.
