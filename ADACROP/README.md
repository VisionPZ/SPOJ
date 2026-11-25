# ADACROP — Ada and Harvest (SPOJ)

<https://www.spoj.com/problems/ADACROP/>

## Problem

A long row of vegetables changes one plant at a time. After each change, report how many plants of the newly planted kind sit at earlier positions. Position and kind both matter, and every answer refers to the row after that change.

Input starts with N and Q, then N initial kinds, then Q pairs i and a. Output one line per change with the count of kind a strictly before position i.

| item | bound |
|---|---|
| row length N | 1 to 200000 |
| changes Q | 1 to 200000 |
| kind values | 0 to 1000000000 |
| judge limit | 1000 ms, 1536 MB |

The change count drives the design: an O(N) scan per answer would cost 4e10 comparisons.

Verbatim sample input:

```
5 5
1 2 1 2 1
2 2
4 2
2 3
3 3
4 3
```

Verbatim sample output:

```
1
3
0
1
2
```

## Idea

Treat each plant kind as its own timeline, like sorting mail into one inbox per sender before reading any of them. A change adds a plus event for the new kind and a minus event for the old one. Reading all changes first lets each kind be handled alone with a Fenwick tree over time.

Each event costs one binary search and one log-time tree update, so total work is O((N + Q) log Q). Repositioning at every change with a scan costs O(NQ), which is too slow. Takeaway: split by kind, then count with a time-indexed tree.

## Why It Works

1. A plant contributes to one kind at a time, so removing the old kind and adding the new one keeps the per-kind counts exact.
2. The initial row contributes a plus event at time -1, which precedes every change.
3. For one kind, an answer counts plus events with position below i and time at most t.
4. Sorting that kind's events by position makes the position test a prefix condition.
5. A Fenwick tree over time then answers the time condition with a prefix sum.
6. Queries sort before updates at the same position, so a plant at position i is never counted as being before itself.

The main terms and formulas:

| term | meaning |
|---|---|
| `eventKind` | zero for a query event, one for a plant change |
| `eventTime` | change index, with -1 for the initial row |
| `distinctValues` | sorted unique kinds, used to map a kind to a group |
| `bitStamp` | marker that reuses the tree for each kind without clearing it |
| `answerList` | one answer slot per change, filled out of order |

The stamp array avoids clearing Q cells for every kind, which would be quadratic.

A script-generated trace for the sample case with row [1, 2, 1, 2, 1]:

```
change 0: kind 2 at position 2, earlier kind-2 plants: position 1 -> 1
change 1: kind 2 at position 4, earlier kind-2 plants: positions 1,2,3 -> 3
change 2: kind 3 at position 2, earlier kind-3 plants: none -> 0
change 3: kind 3 at position 3, earlier kind-3 plants: position 2 -> 1
change 4: kind 3 at position 4, earlier kind-3 plants: positions 2,3 -> 2
```

The trace matches all five sample output lines.

Fenwick indices start at one, so time -1 maps to index 1 and change t maps to t + 2. Counts fit in an int because a kind appears at most N times.

## Code

**Input and scanner.** One read loads the whole input and a digit scanner pulls numbers.

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

proc compareValues(firstValue: int64, secondValue: int64): int =
  if firstValue < secondValue:
    return -1
  elif firstValue > secondValue:
    return 1
  return 0
```

`compareValues` serves the explicit sort required by the target compiler.
Output accumulates in a single buffer, shown next.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The final flush follows the answer loop.

**Event records.** Every stored event keeps its kind, position, time and role.

```nim
var eventValueId = newSeq[int](0)
var eventRawValue = newSeq[int64](0)
var eventPosition = newSeq[int](0)
var eventTime = newSeq[int](0)
var eventDelta = newSeq[int](0)
var eventKind = newSeq[int](0)
var eventQueryId = newSeq[int](0)

proc compareEvents(leftEvent: int, rightEvent: int): int =
  if eventValueId[leftEvent] != eventValueId[rightEvent]:
    return eventValueId[leftEvent] - eventValueId[rightEvent]
  if eventPosition[leftEvent] != eventPosition[rightEvent]:
    return eventPosition[leftEvent] - eventPosition[rightEvent]
  if eventKind[leftEvent] != eventKind[rightEvent]:
    return eventKind[leftEvent] - eventKind[rightEvent]
  return eventTime[leftEvent] - eventTime[rightEvent]
```

The comparator orders events by kind group, then position, then query before update.
A plus event carries delta one and a minus event carries delta minus one.

**Fenwick tree with stamps.** Stamps let one tree serve many kinds.

```nim
var bitStamp = newSeq[int](0)
var bitCount = newSeq[int](0)
var currentStamp = 0

proc bitAdd(index: int, delta: int) =
  var position = index
  while position < bitCount.len:
    if bitStamp[position] != currentStamp:
      bitStamp[position] = currentStamp
      bitCount[position] = 0
    bitCount[position] = bitCount[position] + delta
    position = position + (position and (-position))

proc bitPrefix(index: int): int =
  var position = index
  var total = 0
  while position > 0:
    if bitStamp[position] == currentStamp:
      total = total + bitCount[position]
    position = position - (position and (-position))
  return total
```

The low bit of an index drives both update and prefix walk.
A cell is zeroed on first touch within a kind group.

**Kind lookup and event creation.** Binary search maps values to group ids.

```nim
proc findValueId(value: int64, distinctValues: seq[int64]): int =
  var lowIndex = 0
  var highIndex = distinctValues.len - 1
  while lowIndex <= highIndex:
    let middleIndex = lowIndex + (highIndex - lowIndex) div 2
    if distinctValues[middleIndex] < value:
      lowIndex = middleIndex + 1
    elif distinctValues[middleIndex] > value:
      highIndex = middleIndex - 1
    else:
      return middleIndex
  return lowIndex

proc addEvent(value: int64, position: int, time: int, delta: int,
              kind: int, queryId: int) =
  eventRawValue.add value
  eventPosition.add position
  eventTime.add time
  eventDelta.add delta
  eventKind.add kind
  eventQueryId.add queryId
  eventValueId.add 0
```

`addEvent` records all fields in parallel arrays.
The value id is filled after all distinct kinds are known.

**Driver.** The row is read, changes become events, and groups are processed in one pass.

```nim
let fieldLength = nextInt(inputData, scanPos)
let harvestCount = nextInt(inputData, scanPos)
var currentPlant = newSeq[int64](fieldLength)
var allValues = newSeq[int64](fieldLength)
for position in 0 .. fieldLength - 1:
  let plantKind = int64(nextInt(inputData, scanPos))
  currentPlant[position] = plantKind
  allValues[position] = plantKind
  addEvent(plantKind, position, -1, 1, 1, -1)

for harvestIndex in 0 .. harvestCount - 1:
  let harvestedIndex = nextInt(inputData, scanPos)
  let plantedKind = int64(nextInt(inputData, scanPos))
  let oldKind = currentPlant[harvestedIndex]
  currentPlant[harvestedIndex] = plantedKind
  allValues.add plantedKind
  addEvent(oldKind, harvestedIndex, harvestIndex, -1, 1, -1)
  addEvent(plantedKind, harvestedIndex, harvestIndex, 1, 1, -1)
  addEvent(plantedKind, harvestedIndex, harvestIndex, 0, 0, harvestIndex)
```

Each change creates one removal, one addition and one query event.
The simulated row supplies the old kind without a second pass.

```nim
allValues.sort(compareValues)
var distinctValues = newSeq[int64](0)
for value in allValues:
  if distinctValues.len == 0 or distinctValues[distinctValues.len - 1] != value:
    distinctValues.add value

for eventIndex in 0 .. eventValueId.high:
  eventValueId[eventIndex] = findValueId(eventRawValue[eventIndex], distinctValues)

var answerList = newSeq[int](harvestCount)
bitStamp = newSeq[int](harvestCount + 3)
bitCount = newSeq[int](harvestCount + 3)

var eventOrder = newSeq[int](eventValueId.len)
for eventIndex in 0 .. eventOrder.high:
  eventOrder[eventIndex] = eventIndex
eventOrder.sort(compareEvents)
```

Sorting the values gives compact group ids for binary search.
Sorting event indices keeps the parallel arrays untouched.

```nim
var orderIndex = 0
while orderIndex < eventOrder.len:
  let groupValue = eventValueId[eventOrder[orderIndex]]
  currentStamp += 1
  var groupIndex = orderIndex
  while groupIndex < eventOrder.len and eventValueId[eventOrder[groupIndex]] == groupValue:
    let eventIndex = eventOrder[groupIndex]
    if eventKind[eventIndex] == 1:
      bitAdd(eventTime[eventIndex] + 2, eventDelta[eventIndex])
    else:
      answerList[eventQueryId[eventIndex]] = bitPrefix(eventTime[eventIndex] + 2)
    groupIndex += 1
  orderIndex = groupIndex

for harvestIndex in 0 .. harvestCount - 1:
  appendOutput($answerList[harvestIndex])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Each kind group gets a fresh stamp, so old tree cells are ignored.
Answers are written in change order after all groups finish.

## Complexity

Reading all changes first moves the position test into a sort and the time test into a tree.

| phase | time | space |
|---|---|---|
| input read | one pass over N + Q values | event arrays |
| value compression | one sort over N + Q values | distinct kinds |
| event sort | one sort over N + 3Q events | index array |
| group sweep | O((N + Q) log Q) tree steps | Fenwick arrays |
| output | one buffered line per change | block buffer |

The Fenwick sweep dominates because each event costs logarithmically many steps.

| measure | Big O |
|---|---|
| time | O((N + Q) log(N + Q)) |
| space | O(N + Q) |

Scanning earlier positions for every change costs O(NQ), which cannot meet the limit. Takeaway: reorder by kind first, then count by time.
