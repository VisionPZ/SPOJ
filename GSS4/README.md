# GSS4 — Can you answer these queries IV (SPOJ)

<https://www.spoj.com/problems/GSS4/>

## Problem

Maintain a sequence under range square-root updates and range sum queries. Report sums after the requested updates for each test case.

The input contains test cases until end of file. Each case gives `N`, then `N` positive integers, then `M`, then `M` operations written as `i x y`. Operation `0` replaces each element in `[x, y]` with its floor square root; operation `1` prints the sum on `[x, y]`, using one-based inclusive indices. Print `Case #k:` before each case and a blank line after it.

| item | bound |
|---|---|
| elements N | up to 100000 |
| operations M | up to 100000 |
| total sequence sum | less than 10^18 |
| judge limit | 500 ms, 1536 MB |

The operation count drives the need for a fast range structure.

Sample input:

```
5
1 2 3 4 5
5
1 2 4
0 2 4
1 2 4
0 4 5
1 1 5
4
10 10 10 10
3
1 1 4
0 2 3
1 1 4
```

Sample output:

```
Case #1:
9
4
6

Case #2:
40
26

```

## Idea

Think of each number as a candle that shrinks until it reaches one, then never changes again. A segment tree stores sums and maximums, so a range with maximum one can be skipped without visiting it. Each element changes only a handful of times before it settles at one. Rescanning the whole range on every update would cost far more. Take the skip-when-settled tree as the whole algorithm.

## Why It Works

1. The square root of a positive integer is at least one, and it equals one for values one and two.
2. An element above two drops at least to its square root on each update, so after a few updates it reaches one.
3. A tree node with maximum at most one holds only settled elements, so an update can stop there.
4. A leaf update replaces its value with the floor square root, then the tree recomputes sums and maximums upward.
5. A range query adds the covered node sums, so it costs logarithmic time.

| term | meaning |
|---|---|
| `treeSum` | sum of the elements covered by a tree node |
| `treeMax` | largest element in the node, used as the skip test |
| `integerSquareRoot` | floor square root, corrected after a float estimate |
| `caseNumber` | one-based test case label in the output |

The two tree arrays carry both query answers and update pruning.

A script trace for case one starts with `1 2 3 4 5`. The first query returns `2+3+4 = 9`. The first update changes `2 3 4` to `1 1 2`, so the next query returns `4`. The second update changes `4 5` to `1 2`, so the final query returns `6`.

These numbers match the sample output exactly.

## Code

**Input and scanning.** A hand reader loads stdin once, and a digit scan extracts every integer or checks for end of file.

```nim
import math

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

proc hasMore(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len:
    if data[cursor] >= '0' and data[cursor] <= '9':
      return true
    cursor += 1
  return false
```

`hasMore` detects the next test case at end of file.
Blank lines between cases need no special handling.
Parsing visits each number once.

**Square root helper.** A float estimate is corrected with exact integer comparisons.

```nim
proc largerValue(first: int64, second: int64): int64 =
  if first > second:
    return first
  return second

proc integerSquareRoot(value: int64): int64 =
  if value <= 1:
    return value
  var guess = int64(sqrt(float64(value)))
  while (guess + 1) * (guess + 1) <= value:
    guess += 1
  while guess * guess > value:
    guess -= 1
  return guess
```

The correction loops guard against float rounding near a square.
All comparisons stay inside `int64`.
Values up to 10^18 produce roots near 10^9.

**Tree operations.** Build, update and query share one array pair.

```nim
var treeSum = newSeq[int64](1)
var treeMax = newSeq[int64](1)

proc buildTree(node: int, left: int, right: int, values: seq[int64]) =
  if left == right:
    treeSum[node] = values[left]
    treeMax[node] = values[left]
    return
  let middle = (left + right) div 2
  buildTree(node * 2, left, middle, values)
  buildTree(node * 2 + 1, middle + 1, right, values)
  treeSum[node] = treeSum[node * 2] + treeSum[node * 2 + 1]
  treeMax[node] = largerValue(treeMax[node * 2], treeMax[node * 2 + 1])

proc updateRange(node: int, left: int, right: int, queryLeft: int, queryRight: int) =
  if treeMax[node] <= 1:
    return
  if queryLeft <= left and right <= queryRight:
    if left == right:
      let rooted = integerSquareRoot(treeSum[node])
      treeSum[node] = rooted
      treeMax[node] = rooted
      return
  let middle = (left + right) div 2
  if queryLeft <= middle:
    updateRange(node * 2, left, middle, queryLeft, queryRight)
  if queryRight > middle:
    updateRange(node * 2 + 1, middle + 1, right, queryLeft, queryRight)
  treeSum[node] = treeSum[node * 2] + treeSum[node * 2 + 1]
  treeMax[node] = largerValue(treeMax[node * 2], treeMax[node * 2 + 1])

proc queryRange(node: int, left: int, right: int, queryLeft: int, queryRight: int): int64 =
  if queryLeft <= left and right <= queryRight:
    return treeSum[node]
  let middle = (left + right) div 2
  var total: int64 = 0
  if queryLeft <= middle:
    total = total + queryRange(node * 2, left, middle, queryLeft, queryRight)
  if queryRight > middle:
    total = total + queryRange(node * 2 + 1, middle + 1, right, queryLeft, queryRight)
  return total
```

The maximum check prunes a settled node before any descent.
Only overlapping children are visited on an update.
Both arrays are rebuilt for each test case.

**Driver and buffering.** Cases are labelled, operations are applied, and answers are buffered.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var caseNumber = 0
while hasMore(inputData, scanPos):
  let valueCount = nextInt(inputData, scanPos)
  var values = newSeq[int64](valueCount)
  for valueIndex in 0 .. valueCount - 1:
    values[valueIndex] = int64(nextInt(inputData, scanPos))
  treeSum = newSeq[int64](valueCount * 4 + 5)
  treeMax = newSeq[int64](valueCount * 4 + 5)
  if valueCount > 0:
    buildTree(1, 0, valueCount - 1, values)
  let operationCount = nextInt(inputData, scanPos)
  caseNumber += 1
  appendOutput("Case #" & $caseNumber & ":\n")
  for operationIndex in 0 .. operationCount - 1:
    let operationKind = nextInt(inputData, scanPos)
    let leftIndex = nextInt(inputData, scanPos) - 1
    let rightIndex = nextInt(inputData, scanPos) - 1
    if operationKind == 0:
      if valueCount > 0:
        updateRange(1, 0, valueCount - 1, leftIndex, rightIndex)
    else:
      let rangeSum = queryRange(1, 0, valueCount - 1, leftIndex, rightIndex)
      appendOutput($rangeSum)
      outputBuffer.add '\n'
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Indices are converted from one-based to zero-based on input.
Each query appends one line, and each case appends a blank line.
The final write empties the buffer.

## Complexity

Each element is visited a bounded number of times because it settles at one quickly.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| tree build | one visit per element | four arrays of node pairs |
| updates | logarithmic cost per changing element | unchanged |
| queries | logarithmic cost per query | unchanged |
| output | one write per buffer block | block buffer |

The tree arrays and the input string dominate memory use.

| measure | Big O |
|---|---|
| update | O(log N) amortised |
| query | O(log N) |
| space | O(N) |

Rescanning an entire range on each update would cost O(N) per operation. The skip rule keeps long runs of settled values out of the work.
