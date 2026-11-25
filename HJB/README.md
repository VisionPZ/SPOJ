# HJB — Segmentation (SPOJ)
<https://www.spoj.com/problems/HJB/>

## Problem

Count pairs of non-overlapping segments where the first lies before the second and its minimum is at most the second minimum. Return the count modulo 1000000007.

Input has one case: a length `n`, then `n` array values. Output one integer, the goodness of the array.

| item | bound |
|---|---|
| length n | 1 to 500000 |
| value A_i | 0 to 1000000000 |
| answer | modulo 1000000007 |
| judge limit | 2000 ms, 1536 MB |

The array length drives the design, since the number of segments grows quadratically.

Sample input:

```
5
5 3 0 9 8
```

Sample output:

```
21
```

## Idea

Each boundary between seats splits the array into a left part and a right part. Picture a turnstile: count left segments that have already entered, then match them with right segments that start at the boundary.

A monotonic stack groups segments by their minimum value. In one scan, each group is created once and removed once, so there are O(n) groups. A Fenwick tree over compressed values counts left segments whose minimum is small enough.

The sweep needs left counts for every boundary and right groups at that boundary. Left counts change over time, so the program stores them as a quadratic function in the boundary index. Each right group contributes the difference of that function at two times.

Trying all segment pairs costs O(n⁴). The stack and tree reduce the work to O(n log n).

Takeaway: group segments by minimum, then count eligible pairs with a sweep.

## Why It Works

1. A segment ending at b has a minimum equal to one of the values on the increasing stack after position b.
2. A stack group stores a minimum rank and the number of segments with that minimum.
3. Each group is created once, then popped once, so both scans produce O(n) groups.
4. A left group is active for a range of ending positions. Its contribution to a boundary c is a linear function of c until its range ends, then constant.
5. Summing those linear pieces gives a quadratic prefix function for each value rank.
6. A right group is active for a range of starting positions. Its contribution is the quadratic function at the range end minus the value immediately before the range start.
7. Modulo arithmetic keeps every term below 64-bit even when products reach n².

| term | meaning |
|---|---|
| `ranks` | compressed value rank of each array entry |
| `LeftEvent` | change of slope and constant at one boundary |
| `RightEvent` | right group and the sign of its prefix term |
| `slopeTree` | Fenwick tree of quadratic leading coefficients |
| `linearTree` | Fenwick tree of linear coefficients |
| `constantTree` | Fenwick tree of constant coefficients |
| `goodness` | accumulated answer modulo the modulus |

The sample splits at four boundaries.

```
A = [5, 3, 0, 9, 8]
boundary after 1: right segment minima 9, 8 -> 3 pairs
boundary after 2: right segment minima 9, 8 -> 6 pairs
boundary after 3: right segment minima 9, 8 -> 9 pairs
boundary after 4: right segment minimum 8 -> 3 pairs
total = 3 + 6 + 9 + 3 = 21
```

Equal values use strict pops in one scan and tie-break implicitly, so each segment maps to exactly one group.

## Code

**Input and helpers.** One read pass, a block buffer, and compressed values.

```nim
import algorithm

const flushBlockBytes = 1 shl 17
const answerMod = 1000000007
const halfMod = 500000004

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

proc positiveMod(value: int64): int =
  var remainder = value mod answerMod
  if remainder < 0:
    remainder += answerMod
  return int(remainder)
```

`halfMod` is the inverse of two modulo the prime modulus. The buffer writes in large blocks. Sorting values uses an explicit comparator for compiler compatibility.

**Rank lookup and events.** Two event types connect the scans to the sweep.

```nim
proc compareValues(left: int, right: int): int =
  if left < right:
    return -1
  if left > right:
    return 1
  return 0

proc lowerValue(values: seq[int], target: int): int =
  var low = 0
  var high = values.len
  while low < high:
    let middle = (low + high) div 2
    if values[middle] < target:
      low = middle + 1
    else:
      high = middle
  return low

type LeftEvent = object
  valueRank: int
  deltaSlope: int
  deltaConstant: int
  nextEvent: int

type RightEvent = object
  valueRank: int
  groupCount: int
  sign: int
  nextEvent: int

proc addLeftEvent(eventList: var seq[LeftEvent], headList: var seq[int],
                  eventTime: int, valueRank: int, deltaSlope: int,
                  deltaConstant: int) =
  var newEvent: LeftEvent
  newEvent.valueRank = valueRank
  newEvent.deltaSlope = deltaSlope
  newEvent.deltaConstant = deltaConstant
  newEvent.nextEvent = headList[eventTime]
  eventList.add newEvent
  headList[eventTime] = eventList.len - 1

proc addRightEvent(eventList: var seq[RightEvent], headList: var seq[int],
                   eventTime: int, valueRank: int, groupCount: int, sign: int) =
  var newEvent: RightEvent
  newEvent.valueRank = valueRank
  newEvent.groupCount = groupCount
  newEvent.sign = sign
  newEvent.nextEvent = headList[eventTime]
  eventList.add newEvent
  headList[eventTime] = eventList.len - 1
```

Events use linked lists inside one flat array. No nested sequences are needed. Each event is inserted in O(1).

**Compression.** Values map to ranks from 1 upward.

```nim
let elementCount = nextInt(inputData, scanPos)
var values = newSeq[int](elementCount)
var sortedValues = newSeq[int](elementCount)
for elementIndex in 0 .. elementCount - 1:
  values[elementIndex] = nextInt(inputData, scanPos)
  sortedValues[elementIndex] = values[elementIndex]

sortedValues.sort(compareValues)
var uniqueCount = 0
for elementIndex in 0 .. elementCount - 1:
  if elementIndex == 0 or sortedValues[elementIndex] != sortedValues[elementIndex - 1]:
    sortedValues[uniqueCount] = sortedValues[elementIndex]
    uniqueCount += 1
sortedValues.setLen(uniqueCount)

var ranks = newSeq[int](elementCount)
for elementIndex in 0 .. elementCount - 1:
  ranks[elementIndex] = lowerValue(sortedValues, values[elementIndex]) + 1

var leftHead = newSeq[int](elementCount + 4)
var rightHead = newSeq[int](elementCount + 4)
for index in 0 .. elementCount + 3:
  leftHead[index] = -1
  rightHead[index] = -1
var leftEvents = newSeq[LeftEvent](0)
var rightEvents = newSeq[RightEvent](0)
```

Binary search assigns each rank in O(log n). Equal values share a rank. Event heads start empty for every time step.

**Left scan.** A forward stack creates left events.

```nim
var stackValues = newSeq[int](elementCount)
var stackCounts = newSeq[int](elementCount)
var stackStarts = newSeq[int](elementCount)
var stackTop = 0
for boundary in 0 .. elementCount - 1:
  let currentRank = ranks[boundary]
  var groupCount = 1
  while stackTop > 0 and stackValues[stackTop - 1] > currentRank:
    stackTop -= 1
    let oldRank = stackValues[stackTop]
    let oldCount = stackCounts[stackTop]
    let firstBoundary = stackStarts[stackTop]
    let lastBoundary = boundary - 1
    addLeftEvent(leftEvents, leftHead, firstBoundary + 2, oldRank, oldCount,
                 -oldCount * (firstBoundary + 1))
    addLeftEvent(leftEvents, leftHead, lastBoundary + 2, oldRank, -oldCount,
                 oldCount * (lastBoundary + 2))
    groupCount += oldCount
  stackValues[stackTop] = currentRank
  stackCounts[stackTop] = groupCount
  stackStarts[stackTop] = boundary
  stackTop += 1
while stackTop > 0:
  stackTop -= 1
  let lastBoundary = elementCount - 1
  let firstBoundary = stackStarts[stackTop]
  addLeftEvent(leftEvents, leftHead, firstBoundary + 2, stackValues[stackTop],
               stackCounts[stackTop], -stackCounts[stackTop] * (firstBoundary + 1))
  addLeftEvent(leftEvents, leftHead, lastBoundary + 2, stackValues[stackTop],
               -stackCounts[stackTop], stackCounts[stackTop] * (lastBoundary + 2))
```

Popped groups keep their counts inside the new group. Two events per group mark when its slope begins and when it flattens.

**Right scan.** A backward stack creates right events.

```nim
var rightValues = newSeq[int](elementCount)
var rightCounts = newSeq[int](elementCount)
var rightStarts = newSeq[int](elementCount)
var rightTop = 0
for position in countdown(elementCount - 1, 0):
  let currentRank = ranks[position]
  var groupCount = 1
  while rightTop > 0 and rightValues[rightTop - 1] > currentRank:
    rightTop -= 1
    let oldRank = rightValues[rightTop]
    let oldCount = rightCounts[rightTop]
    let creationIndex = rightStarts[rightTop]
    let firstStart = position + 2
    let lastStart = creationIndex + 1
    if firstStart - 1 >= 1:
      addRightEvent(rightEvents, rightHead, firstStart - 1, oldRank, oldCount, -1)
    addRightEvent(rightEvents, rightHead, lastStart, oldRank, oldCount, 1)
    groupCount += oldCount
  rightValues[rightTop] = currentRank
  rightCounts[rightTop] = groupCount
  rightStarts[rightTop] = position
  rightTop += 1
while rightTop > 0:
  rightTop -= 1
  addRightEvent(rightEvents, rightHead, rightStarts[rightTop] + 1,
                rightValues[rightTop], rightCounts[rightTop], 1)
```

Each right group has an active range of starting positions. Two events subtract the prefix value before the range and add it at the end.

**Fenwick polynomials.** Three trees store the quadratic prefix function.

```nim
let treeSize = uniqueCount + 3
var slopeTree = newSeq[int64](treeSize + 2)
var linearTree = newSeq[int64](treeSize + 2)
var constantTree = newSeq[int64](treeSize + 2)

proc treeAdd(tree: var seq[int64], index: int, delta: int) =
  var cursor = index
  while cursor < tree.len:
    tree[cursor] = (tree[cursor] + int64(delta)) mod answerMod
    if tree[cursor] < 0:
      tree[cursor] += answerMod
    cursor += cursor and -cursor

proc treePrefix(tree: seq[int64], index: int): int64 =
  var total: int64 = 0
  var cursor = index
  while cursor > 0:
    total += tree[cursor]
    if total >= answerMod:
      total -= answerMod
    cursor -= cursor and -cursor
  return total

proc updatePolynomial(valueRank: int, deltaSlope: int, deltaConstant: int,
                      eventTime: int) =
  treeAdd(slopeTree, valueRank, positiveMod(int64(deltaSlope)))
  treeAdd(linearTree, valueRank,
          positiveMod(int64(deltaSlope) + 2 * int64(deltaConstant)))
  treeAdd(constantTree, valueRank,
          positiveMod(-int64(deltaSlope) * int64(eventTime * eventTime - eventTime) +
                      2 * int64(deltaConstant) * int64(1 - eventTime)))

proc doubledPrefixSum(valueRank: int, timeValue: int): int64 =
  let slope = treePrefix(slopeTree, valueRank)
  let linear = treePrefix(linearTree, valueRank)
  let constant = treePrefix(constantTree, valueRank)
  let timeSquare = int64(timeValue) * int64(timeValue)
  return (slope * timeSquare + linear * int64(timeValue) + constant) mod answerMod
```

The stored function is twice the prefix sum, so all coefficients stay integral. Updates are point adds, and queries sum ranks up to the needed value.

**Final sweep.** Time moves left to right, applying events and accumulating pairs.

```nim
var goodness: int64 = 0
for boundary in 1 .. elementCount:
  var leftCursor = leftHead[boundary]
  while leftCursor != -1:
    let currentEvent = leftEvents[leftCursor]
    updatePolynomial(currentEvent.valueRank, currentEvent.deltaSlope,
                     currentEvent.deltaConstant, boundary)
    leftCursor = currentEvent.nextEvent
  var rightCursor = rightHead[boundary]
  while rightCursor != -1:
    let currentEvent = rightEvents[rightCursor]
    let prefixTotal = doubledPrefixSum(currentEvent.valueRank, boundary)
    let contribution = int64(currentEvent.groupCount) * int64(currentEvent.sign) *
                       halfMod mod answerMod * prefixTotal mod answerMod
    goodness = (goodness + contribution) mod answerMod
    if goodness < 0:
      goodness += answerMod
    rightCursor = currentEvent.nextEvent

appendOutput($goodness)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Left events are applied before right queries at the same time. Multiplying by the inverse of two restores the true prefix count. The answer is written once.

## Complexity

Both stacks create O(n) events, and each event costs one logarithmic tree update.

| phase | time | space |
|---|---|---|
| input and compression | O(n log n) | input plus ranks |
| left and right stacks | O(n) amortized | O(n) events |
| sweep and Fenwick | O(n log n) | three value trees |
| output | one line | block buffer |

The sweep dominates, with O(n log n) time and O(n) space.

| measure | Big O |
|---|---|
| time | O(n log n) |
| space | O(n) |

Enumerating all segment pairs costs O(n⁴). Grouping by minimum turns the count into a small number of events.

Takeaway: one sweep over boundaries and one tree over values solve the whole array.
