# INTERVAL — Intervals (SPOJ)
<https://www.spoj.com/problems/INTERVAL/>

## Problem

Given closed integer intervals with required counts, choose a set `Z` of integers with at least the required count in each interval. Minimize the size of `Z`, since one position can serve several intervals.

The first line holds a test count. Each case starts with an interval count n from 1 to 50000, then n lines of three integers a, b, and c. The interval is [a, b] with 0 <= a <= b <= 50000, and the demand c lies from 1 to b - a + 1. Print one integer per case, the minimum size of the chosen set.

The judge limits are:

| Item | Value |
| --- | --- |
| Intervals per case n | 1 to 50000 |
| Endpoints | 0 to 50000 |
| Demand c | 1 to b - a + 1 |
| Time limit | 1604 ms |
| Memory limit | 1536 MB |

The coordinate range of 50001 values fits a flat table.

The sample input reads:

```text
1
5
3 7 3
8 10 3
6 8 1
1 3 1
10 11 1
```

The sample output reads:

```text
6
```

## Idea

Fill the rightmost open integer positions first, like taking the highest free slots in a row. Sort intervals by right endpoint so each new interval ends no earlier than the last one. A Fenwick tree (a prefix-sum array with logarithmic updates) counts chosen positions in a range and finds the highest free coordinate. Each chosen point costs O(log 50001), and each interval is visited once. Scanning every coordinate for every interval would cost O(n times 50000). Takeaway: sort by deadline, then fill the highest free slots.

## Why It Works

1. Sorting by right endpoint makes every later interval end no earlier than the current one.
2. A point placed near the current right endpoint stays useful for later intervals that start before it.
3. A later interval starting beyond the current right endpoint cannot use those points, so placement cannot hurt it.
4. The program stores coordinate p at Fenwick index p + 1.
5. `already = prefix(j) - prefix(i - 1)` counts chosen positions inside [a, b], with i = a + 1 and j = b + 1.
6. `freeRank = j - prefix(j)` counts unused coordinates at or below b, and `findKthFree` returns the highest one.
7. Cleanup restores only touched coordinates, which keeps the cost independent of the coordinate range.

The table defines the terms.

| Term | Meaning |
| --- | --- |
| `chosenBit` | Fenwick tree of chosen positions |
| `freeBit` | Fenwick tree of still-free positions |
| `touched` | coordinates added in the current case |
| `findKthFree` | highest free coordinate for a given free rank |

These four terms drive each interval step.

A script replayed the sample in sorted order.

| Interval | Need | Have | Add |
| --- | --- | --- | --- |
| [1,3] | 1 | 0 | 3 |
| [3,7] | 3 | 1 | 7, 6 |
| [6,8] | 1 | 2 | none |
| [8,10] | 3 | 0 | 10, 9, 8 |
| [10,11] | 1 | 1 | none |

The chosen coordinates 3, 6, 7, 8, 9, and 10 give the answer 6.

## Code

**Constants and interval record.** The array size follows from the largest coordinate.

```nim
import std/algorithm

const
  maxCoordinate = 50000
  treeSize = maxCoordinate + 1
  firstDigitValue = 48
  flushBlockBytes = 1 shl 18

type
  Interval = object
    left: int
    right: int
    demand: int
```

`treeSize` is one more than the maximum coordinate because Fenwick indices start at 1. The object groups the three fields of one interval. The output block caps buffered memory at 256 KiB.

**Input and writer.** The code reads once, scans integers by hand, and buffers answers.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The read loop appends every input line to one buffer. The scanner skips separators and builds each integer by hand. All values are non-negative, so no sign branch is needed. The output helper writes only at the block boundary.

**Fenwick trees.** Both trees are built once for all cases.

```nim
var chosenBit = newSeq[int](treeSize + 1)
var freeBit = newSeq[int](treeSize + 1)
for j in 1..treeSize:
  freeBit[j] += 1
  let k = j + (j and (-j))
  if k <= treeSize:
    freeBit[k] += freeBit[j]

var startStep = 1
while startStep shl 1 <= treeSize:
  startStep = startStep shl 1

proc bitAdd(bit: var seq[int], i: int, delta: int) =
  var j = i
  while j <= treeSize:
    bit[j] += delta
    j += j and (-j)

proc bitPrefix(bit: seq[int], i: int): int =
  var j = i
  var total = 0
  while j > 0:
    total += bit[j]
    j -= j and (-j)
  return total

proc findKthFree(rank: int): int =
  var i = 0
  var step = startStep
  var remaining = rank
  while step != 0:
    let j = i + step
    if j <= treeSize and freeBit[j] < remaining:
      i = j
      remaining -= freeBit[j]
    step = step shr 1
  return i + 1
```

The free tree starts with one unit at every coordinate. `bitAdd` climbs to parent nodes, and `bitPrefix` descends through them. `findKthFree` descends by powers of two to locate the highest free slot. Each procedure costs O(log 50001).

**Greedy walk.** The comparator sorts by right endpoint, then by left endpoint in reverse.

```nim
proc compareIntervals(x, y: Interval): int =
  if x.right != y.right:
    return x.right - y.right
  return y.left - x.left

proc solveCase(intervals: var seq[Interval], touched: var seq[int]): int =
  intervals.sort(compareIntervals)
  var totalChosen = 0
  for interval in intervals:
    let i = interval.left + 1
    let j = interval.right + 1
    let already = bitPrefix(chosenBit, j) - bitPrefix(chosenBit, i - 1)
    var missing = interval.demand - already
    var freeRank = j - bitPrefix(chosenBit, j)
    while missing > 0:
      let k = findKthFree(freeRank)
      bitAdd(chosenBit, k, 1)
      bitAdd(freeBit, k, -1)
      touched.add k
      freeRank -= 1
      totalChosen += 1
      missing -= 1
  return totalChosen
```

`i` and `j` name Fenwick indices for the interval ends. Each added coordinate is recorded in `touched` for later cleanup. The strict need check adds points only while `missing` exceeds zero. Sorting costs O(n log n).

**Driver.** Each case solves its intervals, then restores only the touched coordinates.

```nim
var touched = newSeq[int]()

let caseCount = nextInt(inputData, i)
for j in 0..<caseCount:
  let intervalCount = nextInt(inputData, i)
  var intervals = newSeq[Interval](intervalCount)
  for k in 0..<intervalCount:
    intervals[k].left = nextInt(inputData, i)
    intervals[k].right = nextInt(inputData, i)
    intervals[k].demand = nextInt(inputData, i)
  let answer = solveCase(intervals, touched)
  appendOutput($answer)
  outputBuffer.add '\n'
  for k in touched:
    bitAdd(chosenBit, k, -1)
    bitAdd(freeBit, k, 1)
  touched.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
```

The cleanup loop touches only coordinates added in this case. `setLen 0` keeps the sequence capacity for the next case. One final write flushes any remaining output. The tables stay ready for the next case.

## Complexity

| Phase | Time | Space |
| --- | --- | --- |
| Read one case | O(n) | O(n) |
| Sort intervals | O(n log n) | O(1) extra |
| Add and clean points | O(K log 50001) | O(K) touched |

Point placement drives the total work.

K is the number of chosen coordinates in one case.

| Measure | Bound |
| --- | --- |
| Per case | O(n log n + K log 50001) |
| Per case | O(n + 50001) space |
| Table build | once for all cases |

The naive form scans all 50000 coordinates for every interval and costs O(n times 50000) per case.
