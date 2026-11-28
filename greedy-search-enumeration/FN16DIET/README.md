# FN16DIET — Balanced Diet (SPOJ)

<https://www.spoj.com/problems/FN16DIET/>

## Problem

Danny eats one sweet per day, and each sweet type has a target share of the total. A collection is balanced when every type count stays within one sweet of its target share. Given a balanced history, report the largest number of extra days that keep every prefix balanced. Print `forever` when no limit exists.

Input holds several test cases until end of file. Each case has three lines. The first line gives `m`, the number of types, and `k`, the number of sweets already eaten. The second line gives `m` positive weights `a_i`. The third line gives `k` type numbers from 1 to `m`, and that line is empty when `k` is zero. The target share of type `i` is `a_i` divided by the sum of all weights. Output one line per test case.

| item | bound |
|---|---|
| sweet types m | 1 to 100000 |
| eaten sweets k | 0 to 100000 |
| weight sum A | at most 100000 |
| test cases | until end of file |
| judge limit | 10000 ms, 1536 MB |

Every prefix of the given history is guaranteed balanced.

Sample input:

```
6 5
2 1 6 3 5 3
1 2 5 3 5
6 4
2 1 6 3 5 3
1 2 5 3
```

Sample output:

```
1
forever
```

## Idea

Treat each next sweet as a recurring appointment: the appointment is due by a known day, so serve the earliest deadline first. This is greedy scheduling with a min-heap of next due days. Each simulated day costs one heap pop and one heap push, so the work is logarithmic in the number of types. Searching every possible sweet sequence would branch across all types at every day. A greedy schedule follows one path and still reaches the longest possible history. Short takeaway: compute due days, then always serve the earliest one.

## Why It Works

1. Let `A` be the sum of all weights, and let `s_i` be the current count of type `i`.
2. The next portion of type `i` is due by day `A (s_i + 1) / a_i`, rounded up.
3. Serving the earliest due portion keeps every type within one sweet of its target.
4. When the earliest due day is already past, no balanced extension exists beyond the previous day.
5. Reaching a multiple of `A` permits a cyclic extension, so the answer becomes `forever`.

| term | meaning |
|---|---|
| `ratioSum` | sum `A` of all weights |
| `deadlineFor` | ceiling of `A (s_i + 1) / a_i` for one type |
| `heapDeadlines` | min-heap of next due days |
| `currentSize` | total sweets eaten in the simulated history |
| `gained` | extra sweets added by the simulation |

For the first sample case, `A` is 20 and the eaten counts are 1, 1, 1, 0, 2, 0. The six due days are 20, 40, 7, 7, 12, and 7. Serving a type with due day 7 leaves the next earliest due day at 7, which is already past. The simulation stops after one extra sweet. The second sample case has one earlier count, and the schedule reaches a multiple of 20.

The deadline formula rounds up with integer division, so no floating point rounding enters. The loop simulates at most `A` days, because reaching a multiple of `A` already proves the `forever` answer.

## Code

**Input and scanning.** The hand reader loads all test cases into one string.

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

proc hasNextToken(data: string, pos: int): bool =
  var checkPos = pos
  while checkPos < data.len:
    if data[checkPos] >= '0' and data[checkPos] <= '9':
      return true
    checkPos += 1
  return false
```

The scanner skips spaces and line breaks.
It reads exactly `k` type numbers for each case.
An empty type line leaves the scanner at the next header.

**Deadlines and heap.** The heap keeps the earliest due day at the front.

```nim
proc deadlineFor(ratioSum: int64, nextQuantity: int, ratio: int): int64 =
  let product = ratioSum * int64(nextQuantity)
  return (product + int64(ratio) - 1) div int64(ratio)

var heapDeadlines = newSeq[int64](0)
var heapTypes = newSeq[int](0)

proc heapLess(leftIndex: int, rightIndex: int): bool =
  if heapDeadlines[leftIndex] < heapDeadlines[rightIndex]:
    return true
  if heapDeadlines[leftIndex] > heapDeadlines[rightIndex]:
    return false
  return heapTypes[leftIndex] < heapTypes[rightIndex]

proc swapHeap(leftIndex: int, rightIndex: int) =
  let savedDeadline = heapDeadlines[leftIndex]
  let savedType = heapTypes[leftIndex]
  heapDeadlines[leftIndex] = heapDeadlines[rightIndex]
  heapTypes[leftIndex] = heapTypes[rightIndex]
  heapDeadlines[rightIndex] = savedDeadline
  heapTypes[rightIndex] = savedType

proc siftUpHeap(startIndex: int) =
  var childIndex = startIndex
  while childIndex > 0:
    let parentIndex = (childIndex - 1) div 2
    if heapLess(childIndex, parentIndex):
      swapHeap(childIndex, parentIndex)
      childIndex = parentIndex
    else:
      break

proc siftDownHeap(startIndex: int) =
  var parentIndex = startIndex
  while true:
    let leftIndex = parentIndex * 2 + 1
    if leftIndex >= heapDeadlines.len:
      break
    let rightIndex = leftIndex + 1
    var smallestIndex = leftIndex
    if rightIndex < heapDeadlines.len and heapLess(rightIndex, leftIndex):
      smallestIndex = rightIndex
    if heapLess(smallestIndex, parentIndex):
      swapHeap(parentIndex, smallestIndex)
      parentIndex = smallestIndex
    else:
      break

proc pushDeadline(deadline: int64, sweetType: int) =
  heapDeadlines.add deadline
  heapTypes.add sweetType
  siftUpHeap(heapDeadlines.len - 1)

proc popDeadline(deadline: var int64, sweetType: var int) =
  deadline = heapDeadlines[0]
  sweetType = heapTypes[0]
  let lastIndex = heapDeadlines.len - 1
  heapDeadlines[0] = heapDeadlines[lastIndex]
  heapTypes[0] = heapTypes[lastIndex]
  heapDeadlines.setLen(lastIndex)
  heapTypes.setLen(lastIndex)
  if heapDeadlines.len > 0:
    siftDownHeap(0)
```

The ceiling uses integer arithmetic and 64-bit products.
Two parallel arrays store due day and sweet type.
Sift up and sift down keep the heap ordered after each update.

**Simulation and output.** The driver rebuilds the heap for each test case.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while hasNextToken(inputData, scanPos):
  let typeCount = nextInt(inputData, scanPos)
  let eatenCount = nextInt(inputData, scanPos)
  var ratios = newSeq[int](typeCount)
  var ratioSum: int64 = 0
  for typeIndex in 0 .. typeCount - 1:
    ratios[typeIndex] = nextInt(inputData, scanPos)
    ratioSum += int64(ratios[typeIndex])
  var eatenCounts = newSeq[int](typeCount)
  for sweetIndex in 0 .. eatenCount - 1:
    let sweetType = nextInt(inputData, scanPos) - 1
    eatenCounts[sweetType] += 1
  heapDeadlines.setLen(0)
  heapTypes.setLen(0)
  for typeIndex in 0 .. typeCount - 1:
    pushDeadline(deadlineFor(ratioSum, eatenCounts[typeIndex] + 1, ratios[typeIndex]), typeIndex)
  var currentSize = eatenCount
  var simulatedSteps: int64 = 0
  while simulatedSteps < ratioSum:
    var deadline: int64 = 0
    var sweetType = 0
    popDeadline(deadline, sweetType)
    if deadline < int64(currentSize + 1):
      currentSize = int(deadline) - 1
      break
    eatenCounts[sweetType] += 1
    pushDeadline(deadlineFor(ratioSum, eatenCounts[sweetType] + 1, ratios[sweetType]), sweetType)
    currentSize += 1
    simulatedSteps += 1
  let gained = currentSize - eatenCount
  if int64(gained) >= ratioSum:
    appendOutput("forever")
  else:
    appendOutput($gained)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The initial heap holds one due day per sweet type.
An expired due day stops the simulation at the previous total.
Reaching `A` simulated days reports `forever`.

## Complexity

The simulation runs at most `A` days, and each day updates one heap entry.

| phase | time | space |
|---|---|---|
| input read | one pass over all tokens | one input string |
| heap setup | m insertions | two arrays of m entries |
| simulation | at most A pop and push pairs | same heap arrays |
| output | one line per test case | block buffer |

| measure | Big O |
|---|---|
| time per test case | O((m + A) log m) |
| space | O(m) |

Trying every sweet sequence would branch by `m` at each day and grow exponentially. The greedy schedule follows one path and keeps the same maximum length. Short takeaway: one heap drives the whole simulation.
