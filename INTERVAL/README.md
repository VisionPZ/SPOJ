## Problem

Each test case gives n closed integer intervals [a, b] and a demand c for each interval. Print the smallest size of an integer set Z that has at least c members inside every interval. The program reads all cases from standard input and prints one answer per line.

The statement fixes these bounds:

| Quantity | Bound |
| --- | --- |
| Test cases per file | not bounded by the statement |
| Intervals per case, n | 1 to 50000 |
| Endpoints a and b | 0 to 50000, with a at most b |
| Demand c | 1 to b minus a plus 1 |
| Time limit | 1604 ms |
| Memory limit | 1536 MB |

The coordinate range of 50001 values stays small, so a flat counting table fits, and the interval count drives the work.

## Idea

Sort the intervals by right endpoint, then walk them once. When an interval lacks points, place new points at the highest unused coordinates at or below its right endpoint. A Fenwick tree (a prefix-sum array with logarithmic updates) counts chosen points in a range and finds the next free coordinate.

Cost per chosen point is O(log 50001), and each interval is visited once.

## Why It Works

Sorting by right endpoint makes every later interval end no earlier than the current one. A point placed near the current right endpoint stays inside every later interval that starts at or before it. A later interval that starts beyond the current right endpoint cannot use any current point, so placement inside the current interval cannot hurt it.

The program stores coordinate p at Fenwick index p + 1. These lines define each quantity in the walk:

- leftIndex stores left + 1, the Fenwick index of the left endpoint.
- rightIndex stores right + 1, the Fenwick index of the right endpoint.
- already subtracts the prefix at leftIndex minus 1 from the prefix at rightIndex. That difference counts chosen points inside the interval.
- freeRank subtracts the prefix at rightIndex from rightIndex. That difference counts unused coordinates at or below the right endpoint.
- findKthFree(freeRank) returns the highest unused index at or below rightIndex.

The trace script prints these steps for the sample:

| Interval | Need | Have | Add |
| --- | --- | --- | --- |
| [1,3] | 1 | 0 | 3 |
| [3,7] | 3 | 1 | 7, 6 |
| [6,8] | 1 | 2 | - |
| [8,10] | 3 | 0 | 10, 9, 8 |
| [10,11] | 1 | 1 | - |

The chosen coordinates 3, 6, 7, 8, 9, and 10 give the answer 6.

## Code

The constants cap the table and the output block. The object groups one interval into three named fields.

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

The read loop appends every input line to one buffer. The scanner skips separators and builds each integer by hand. The output helper writes only when the buffer reaches the block size.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Both trees are built once for all cases. The free tree starts with one unit at every coordinate. The step variable is the highest power of two inside the table.

```nim
var chosenBit = newSeq[int](treeSize + 1)
var freeBit = newSeq[int](treeSize + 1)
for index in 1..treeSize:
  freeBit[index] += 1
  let parent = index + (index and (-index))
  if parent <= treeSize:
    freeBit[parent] += freeBit[index]

var startStep = 1
while startStep shl 1 <= treeSize:
  startStep = startStep shl 1
```

These three procedures do the counting. bitAdd climbs to the parent nodes, and bitPrefix descends through them. findKthFree uses free-slot totals to find the highest free slot.

```nim
proc bitAdd(bit: var seq[int], index: int, delta: int) =
  var position = index
  while position <= treeSize:
    bit[position] += delta
    position += position and (-position)

proc bitPrefix(bit: seq[int], index: int): int =
  var position = index
  var total = 0
  while position > 0:
    total += bit[position]
    position -= position and (-position)
  return total

proc findKthFree(rank: int): int =
  var index = 0
  var step = startStep
  var remaining = rank
  while step != 0:
    let nextIndex = index + step
    if nextIndex <= treeSize and freeBit[nextIndex] < remaining:
      index = nextIndex
      remaining -= freeBit[nextIndex]
    step = step shr 1
  return index + 1
```

The comparator sorts by right endpoint, then by left endpoint in reverse. solveCase walks that order and fills the highest free slots until the demand is met. Each added coordinate is recorded in touched for later cleanup.

```nim
proc compareIntervals(x, y: Interval): int =
  if x.right != y.right:
    return x.right - y.right
  return y.left - x.left

proc solveCase(intervals: var seq[Interval], touched: var seq[int]): int =
  intervals.sort(compareIntervals)
  var totalChosen = 0
  for interval in intervals:
    let leftIndex = interval.left + 1
    let rightIndex = interval.right + 1
    let already = bitPrefix(chosenBit, rightIndex) - bitPrefix(chosenBit, leftIndex - 1)
    var missing = interval.demand - already
    var freeRank = rightIndex - bitPrefix(chosenBit, rightIndex)
    while missing > 0:
      let freeIndex = findKthFree(freeRank)
      bitAdd(chosenBit, freeIndex, 1)
      bitAdd(freeBit, freeIndex, -1)
      touched.add freeIndex
      freeRank -= 1
      totalChosen += 1
      missing -= 1
  return totalChosen
```

The main loop reads one case, solves it, and prints the answer. It then restores only the touched coordinates, which keeps the cost independent of the coordinate range. One final write flushes any remaining output.

```nim
var touched = newSeq[int]()

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let intervalCount = nextInt(inputData, scanPos)
  var intervals = newSeq[Interval](intervalCount)
  for intervalIndex in 0..<intervalCount:
    intervals[intervalIndex].left = nextInt(inputData, scanPos)
    intervals[intervalIndex].right = nextInt(inputData, scanPos)
    intervals[intervalIndex].demand = nextInt(inputData, scanPos)
  let answer = solveCase(intervals, touched)
  appendOutput($answer)
  outputBuffer.add '\n'
  for position in touched:
    bitAdd(chosenBit, position, -1)
    bitAdd(freeBit, position, 1)
  touched.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
```

## Complexity

Reading input costs one pass over the whole buffer. Sorting one case costs O(n log n). Each interval costs two prefix queries, and each added point costs one k-th lookup plus four updates.

Total time is O(total tokens plus the sum over cases of n log n plus the chosen count times log 50001). Space is O(n plus 50001). The table is built once, so the case count adds no table cost.

The naive form scans every coordinate for every interval and costs O(n times 50000) per case.
