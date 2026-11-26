# VACCINEP — Vaccine Priority (SPOJ)

<https://www.spoj.com/problems/VACCINEP/>

## Problem

`n` towns have coordinates, and `k` of them have a COVID outbreak. The priority `p_i` of town `i` is the number of outbreak towns within 10 km in box distance, that is `max(|dx|, |dy|) ≤ 10`. An outbreak town counts itself. The program prints all town numbers ordered by decreasing priority, and by increasing town number inside a tie.

Input starts with `n` and `k`, then `n` lines with the coordinates of town `i`, then one line with the `k` outbreak town numbers. Output holds one line with `n` space-separated town numbers.

| Item | Bound |
|---|---|
| Towns `n`, outbreaks `k` | 1 ≤ k ≤ n ≤ 100000 |
| Coordinates | 0 ≤ x, y ≤ 10^9 |
| Meeting radius | 10 km |
| Judge limit | 1000 ms, 1536 MB |

The sample case:

```
3 1
0 11
0 10
0 0
3
```

```
2 3 1
```

## Idea

A town is within 10 km in box distance exactly when its x and y both differ by at most 10, so each outbreak town covers a square. Sweep a vertical line from left to right: an outbreak town enters the active set at `x - 10` and leaves just after `x + 10`. While the line passes a town, the outbreak towns in the active set that also fall in its y window are its priority. A Fenwick tree over the compressed outbreak y-values counts those in logarithmic time, and a counting sort by priority puts the towns in the required order. This replaces the naive scan of every town against every outbreak town.

## Why It Works

1. Box distance at most 10 means `|dx| ≤ 10` and `|dy| ≤ 10` at once, which is a square region.
2. An outbreak town is inside that square for a query town of x-coordinate `X` exactly when `ox - 10 ≤ X ≤ ox + 10`, so the event at `ox - 10` adds it and the event at `ox + 10 + 1` removes it before any query with `X ≥ ox + 11`.
3. Queries and events are both processed in increasing x, so when a town is queried the tree holds precisely the outbreak towns whose x window contains it.
4. The tree stores counts at compressed y positions, and the y window `[y - 10, y + 10]` maps to a range of compressed values found by binary search, so the range sum is the priority.
5. Priorities are integers between 0 and `k`, so bucketing by priority is linear, and towns are placed into their bucket in increasing index order, which gives the required tie-break.
6. In the sample the only outbreak is town 3 at (0,0): town 2 sits at box distance `max(0, 10) = 10`, which is inside the limit, town 1 sits at `max(0, 11) = 11`, which is not, and town 3 counts itself, so the priorities are 0, 1, 1 and the order is 2 3 1.

| Term | Meaning |
|---|---|
| `meetingRadius` | the 10 km reach of one outbreak |
| `compressedYs` | sorted unique outbreak y-values |
| `eventXs`, `eventYIndexes`, `eventDeltas` | add and remove events for each outbreak |
| `fenwickTree` | counts of active outbreak towns by y index |
| `priorities` | priority of each town |
| `bucketStarts`, `orderedTowns` | counting sort by priority |

A traced run of the sample:

```
outbreak town 3 at (0,0): add at x=-10, remove at x=11
query town 1 at x=0 : active y {0}, window [1,21] -> 0
query town 2 at x=0 : window [0,20] -> 1
query town 3 at x=0 : window [-10,10] -> 1
buckets: priority 1 -> 2 3, priority 0 -> 1
output 2 3 1
```

## Code

**Input, scanner and output buffer.** This block loads stdin and prepares the writer.

```nim
const flushBlockBytes = 1 shl 17
const meetingRadius = 10

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

One readLine loop collects all input bytes.
The scanner skips whitespace between digits.
The buffer flushes after reaching 128 KiB.

**Range searches.** These two procedures find where a y-value starts and ends in a sorted array.

```nim
proc lowerBound(values: seq[int], target: int): int =
  var lowIndex = 0
  var highIndex = values.len
  while lowIndex < highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if values[middleIndex] < target:
      lowIndex = middleIndex + 1
    else:
      highIndex = middleIndex
  return lowIndex

proc upperBound(values: seq[int], target: int): int =
  var lowIndex = 0
  var highIndex = values.len
  while lowIndex < highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if values[middleIndex] <= target:
      lowIndex = middleIndex + 1
    else:
      highIndex = middleIndex
  return lowIndex
```

Both searches return positions in a sorted array, so the difference of two prefix sums gives a range count.

**Stable index sort.** These procedures sort town indices by a key array without touching the keys.

```nim
proc mergeRanges(keys: seq[int], indexes: var seq[int], buffer: var seq[int], lowIndex, highIndex: int) =
  if lowIndex >= highIndex:
    return
  let middleIndex = (lowIndex + highIndex) div 2
  mergeRanges(keys, indexes, buffer, lowIndex, middleIndex)
  mergeRanges(keys, indexes, buffer, middleIndex + 1, highIndex)
  var leftPos = lowIndex
  var rightPos = middleIndex + 1
  var writePos = lowIndex
  while leftPos <= middleIndex and rightPos <= highIndex:
    if keys[indexes[leftPos]] <= keys[indexes[rightPos]]:
      buffer[writePos] = indexes[leftPos]
      leftPos += 1
    else:
      buffer[writePos] = indexes[rightPos]
      rightPos += 1
    writePos += 1
  while leftPos <= middleIndex:
    buffer[writePos] = indexes[leftPos]
    leftPos += 1
    writePos += 1
  while rightPos <= highIndex:
    buffer[writePos] = indexes[rightPos]
    rightPos += 1
    writePos += 1
  for position in lowIndex .. highIndex:
    indexes[position] = buffer[position]

proc sortIndicesByKey(keys: seq[int]): seq[int] =
  result = newSeq[int](keys.len)
  for index in 0 .. keys.len - 1:
    result[index] = index
  if keys.len > 1:
    var buffer = newSeq[int](keys.len)
    mergeRanges(keys, result, buffer, 0, keys.len - 1)
```

The merge takes the left item on equal keys, so equal x-values keep their original order.
Sorting only the index list leaves the key arrays untouched, so events and queries stay paired with their towns.

**Reading towns and building the sweep data.** This block stores coordinates, compresses outbreak y-values and creates the two events per outbreak.

```nim
let townCount = nextInt(inputData, scanPos)
let outbreakCount = nextInt(inputData, scanPos)
var townXs = newSeq[int](townCount + 1)
var townYs = newSeq[int](townCount + 1)
for townIndex in 1 .. townCount:
  townXs[townIndex] = nextInt(inputData, scanPos)
  townYs[townIndex] = nextInt(inputData, scanPos)
var outbreakTowns = newSeq[int](outbreakCount)
for outbreakIndex in 0 .. outbreakCount - 1:
  outbreakTowns[outbreakIndex] = nextInt(inputData, scanPos)

var outbreakYs = newSeq[int](outbreakCount)
for outbreakIndex in 0 .. outbreakCount - 1:
  outbreakYs[outbreakIndex] = townYs[outbreakTowns[outbreakIndex]]
let sortedYIndices = sortIndicesByKey(outbreakYs)
var compressedYs = newSeq[int](outbreakCount)
var compressedCount = 0
for sortPosition in 0 .. outbreakCount - 1:
  let yValue = outbreakYs[sortedYIndices[sortPosition]]
  if compressedCount == 0 or compressedYs[compressedCount - 1] != yValue:
    compressedYs[compressedCount] = yValue
    compressedCount += 1
compressedYs.setLen(compressedCount)

var eventCount = 2 * outbreakCount
var eventXs = newSeq[int](eventCount)
var eventYIndexes = newSeq[int](eventCount)
var eventDeltas = newSeq[int](eventCount)
for outbreakIndex in 0 .. outbreakCount - 1:
  let outbreakTown = outbreakTowns[outbreakIndex]
  let entryIndex = 2 * outbreakIndex
  eventXs[entryIndex] = townXs[outbreakTown] - meetingRadius
  eventDeltas[entryIndex] = 1
  eventXs[entryIndex + 1] = townXs[outbreakTown] + meetingRadius + 1
  eventDeltas[entryIndex + 1] = -1
  let yIndex = lowerBound(compressedYs, townYs[outbreakTown]) + 1
  eventYIndexes[entryIndex] = yIndex
  eventYIndexes[entryIndex + 1] = yIndex
let sortedEventIndices = sortIndicesByKey(eventXs)

var queryKeys = newSeq[int](townCount)
for townIndex in 1 .. townCount:
  queryKeys[townIndex - 1] = townXs[townIndex]
let sortedQueryIndices = sortIndicesByKey(queryKeys)
```

Duplicate y-values collapse into one slot, which keeps the tree small.
The `+ 1` on the removal x makes the interval half-open, so a query at `ox + 11` sees the town gone.

**Fenwick tree.** This block maintains the active outbreak counts.

```nim
var fenwickTree = newSeq[int](compressedCount + 1)

proc bitAdd(position: int, delta: int) =
  var current = position
  while current <= compressedCount:
    fenwickTree[current] += delta
    current += current and (-current)

proc bitPrefix(position: int): int =
  var current = position
  var total = 0
  while current > 0:
    total += fenwickTree[current]
    current -= current and (-current)
  return total
```

Fenwick trees use 1-based positions, hence the `+ 1` when an outbreak y is indexed.
Each update and each prefix sum walks at most log steps.

**The sweep.** This block answers every town query in increasing x.

```nim
var priorities = newSeq[int](townCount + 1)
var eventPosition = 0
for queryPosition in 0 .. townCount - 1:
  let townIndex = sortedQueryIndices[queryPosition] + 1
  let townX = townXs[townIndex]
  while eventPosition < eventCount:
    let eventIndex = sortedEventIndices[eventPosition]
    if eventXs[eventIndex] > townX:
      break
    bitAdd(eventYIndexes[eventIndex], eventDeltas[eventIndex])
    eventPosition += 1
  let lowY = townYs[townIndex] - meetingRadius
  let highY = townYs[townIndex] + meetingRadius
  let leftCount = lowerBound(compressedYs, lowY)
  let rightCount = upperBound(compressedYs, highY)
  priorities[townIndex] = bitPrefix(rightCount) - bitPrefix(leftCount)
```

Events with the same x as a query are applied first, which is correct because the removal x is one past the last covered column.
The two binary searches bound the y window, and the tree difference counts the outbreaks inside it.

**Bucketing and output.** This block sorts towns by priority and writes the line.

```nim
var priorityCounts = newSeq[int](outbreakCount + 2)
for townIndex in 1 .. townCount:
  priorityCounts[priorities[townIndex]] += 1
var bucketStarts = newSeq[int](outbreakCount + 2)
for priorityValue in 0 .. outbreakCount:
  bucketStarts[priorityValue + 1] = bucketStarts[priorityValue] + priorityCounts[priorityValue]
var bucketCursors = newSeq[int](outbreakCount + 1)
for priorityValue in 0 .. outbreakCount:
  bucketCursors[priorityValue] = bucketStarts[priorityValue]
var orderedTowns = newSeq[int](townCount)
for townIndex in 1 .. townCount:
  let priorityValue = priorities[townIndex]
  orderedTowns[bucketCursors[priorityValue]] = townIndex
  bucketCursors[priorityValue] += 1

var currentPriority = outbreakCount
var firstTownWritten = true
while currentPriority >= 0:
  var bucketPosition = bucketStarts[currentPriority]
  while bucketPosition < bucketStarts[currentPriority + 1]:
    let townIndex = orderedTowns[bucketPosition]
    if firstTownWritten:
      firstTownWritten = false
    else:
      outputBuffer.add ' '
    appendOutput($townIndex)
    bucketPosition += 1
  currentPriority -= 1
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Towns enter a bucket in increasing index order, so ties come out smallest first.
Walking buckets from `k` down to 0 prints the highest priority first.
The flag keeps a single space between numbers and no trailing space.

## Complexity

The cost splits into input, sorting, the sweep, bucketing and output.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Index sorts | O((n + k) log(n + k)) | O(n + k) |
| Sweep | O((n + k) log k) | O(n + k) |
| Bucketing | O(n + k) | O(n + k) |
| Output | one write per 128 KiB block | block buffer |

| Measure | Big O |
|---|---|
| Time | O(n log n) |
| Space | O(n + k) |

The direct scan of every town against every outbreak town costs O(n·k), which is 10^10 checks at the limits.
