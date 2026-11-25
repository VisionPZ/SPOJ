# ADACUT — Ada and Alley (SPOJ)
<https://www.spoj.com/problems/ADACUT/>

## Problem

Choose one final height and pay for every tree to reach it. Trimming one unit costs one coin; removing a tree costs its whole height. Trees shorter than the target must be removed, so the target cannot exceed any kept height.

The input starts with the tree count `treeCount`. One line follows with `treeCount` heights between zero and one billion. Output one integer: the smallest cost.

| item | bound |
|---|---|
| tree count | 1 to 300000 |
| each height | 0 to 1000000000 |
| judge limit | 1000 ms, 1536 MB |

The cost grows with the number of trimmed units, so only candidate heights matter.

Sample input:

```
5
1 2 3 4 5
```

Sample output:

```
6
```

## Idea

Trim every hedge to one fence line, and chop down any hedge already below that line; like choosing where to set the fence. Try each height present in the data, summing trims above it and removal costs below it. Sorting the heights and keeping prefix totals turns each trial into constant work. A direct scan of all heights repeats the same sums for every candidate, which is far slower when heights are large. Sort once, sweep the distinct heights, and stop.

## Why It Works

1. For a target h, a tree of height t with t ≥ h costs t − h units of trimming.
2. A tree with t < h cannot grow, so it must be removed for cost t.
3. Between two consecutive heights in the data, every kept tree costs one more unit each step, so the total strictly falls.
4. The optimum therefore sits at a present height, or at zero when every height is zero.
5. Sorting groups equal heights, and prefix totals give both sums in constant time.

These names carry the main values.

| term | meaning |
|---|---|
| `heights` | sorted tree heights |
| `prefixTotals` | running sum of heights up to an index |
| `targetHeight` | height shared by the current group |
| `shorterTotal` | removal cost for trees below the target |
| `tallerTotal` | untrimmed sum of trees at or above the target |
| `bestCost` | cheapest total found so far |

Prefix sums turn a repeated sum into two subtractions.

A script-generated example uses heights 1, 2, 3, 4, 5:

| target | removals | trims | total |
|---|---|---|---|
| 1 | 0 | 10 | 10 |
| 2 | 1 | 6 | 7 |
| 3 | 3 | 3 | 6 |
| 4 | 6 | 1 | 7 |
| 5 | 10 | 0 | 10 |

The sweep picks height 3 and reports 6.

All totals fit in a 64-bit integer, since 300000 heights of one billion sum to 3e14. No rounding appears in this problem.

## Code

**Input and scanner.** The reader loads every number and the parser skips separators.

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
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

proc compareHeights(leftValue, rightValue: int): int =
  if leftValue < rightValue: return -1
  if leftValue > rightValue: return 1
  return 0
```

The scanner builds each value one digit at a time.
The comparator sorts heights in ascending order.

**Buffer and prefix totals.** One output buffer holds the answer, and totals use 64 bits.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let treeCount = nextInt(inputData, scanPos)
var heights = newSeq[int](treeCount)
for treeIndex in 0 .. treeCount - 1:
  heights[treeIndex] = nextInt(inputData, scanPos)
heights.sort(compareHeights)

var prefixTotals = newSeq[int64](treeCount + 1)
for treeIndex in 0 .. treeCount - 1:
  prefixTotals[treeIndex + 1] = prefixTotals[treeIndex] + int64(heights[treeIndex])
```

Sorting groups equal heights into one block.
Each prefix entry holds the sum before its index.

**Distinct-height sweep.** The loop tests each block and keeps the cheapest total.

```nim
var bestCost = prefixTotals[treeCount]
var groupStart = 0
while groupStart < treeCount:
  let targetHeight = heights[groupStart]
  var groupEnd = groupStart + 1
  while groupEnd < treeCount and heights[groupEnd] == targetHeight:
    groupEnd += 1
  let shorterTotal = prefixTotals[groupStart]
  let tallerTotal = prefixTotals[treeCount] - prefixTotals[groupEnd]
  let tallerCount = treeCount - groupEnd
  let groupCost = shorterTotal + tallerTotal - int64(tallerCount) * int64(targetHeight)
  if groupCost < bestCost:
    bestCost = groupCost
  groupStart = groupEnd

appendOutput($bestCost)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Removal costs come from the lower prefix, and trim costs from the upper prefix.
The final flush writes a single line.

## Complexity

The scan reads the input once, then sorting dominates before one linear sweep.

| phase | time | space |
|---|---|---|
| input read | one pass over all heights | one input string |
| sorting | O(N log N) comparisons | height array |
| sweep | one step per height | prefix array |
| output | one integer | block buffer |

The sort sets the overall cost.

| measure | Big O |
|---|---|
| time | O(N log N) |
| space | O(N) |

A direct trial of every integer height costs far more when heights reach one billion.

Sort once and sweep the distinct heights to finish in near-linear time.
