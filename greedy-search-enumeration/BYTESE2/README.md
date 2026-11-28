# BYTESE2 — The Great Ball (SPOJ)

<https://www.spoj.com/problems/BYTESE2/>

## Problem

Count the largest number of dancers present at one moment during a ball, using each recorded entry time and exit time. The door allows one move at a time, so entry and exit times are all different.

The input starts with the test count `T`. Each test starts with the record count `N`, then `N` lines with one entry time and one exit time. Output one peak count per test.

| item | bound |
|---|---|
| test cases T | 1 to 100 |
| records N per test | 1 to 100 |
| entry and exit times | up to 10000000 |
| judge limit | 1000 ms, 1536 MB |

All times are distinct and every entry time is smaller than its exit time.

Sample input:

```
1
5
1 7
2 4
6 9
3 8
5 10
```

Sample output:

```
4
```

## Idea

Turn each visit into two events on one timeline, like tallying guests as a doorman reads arrival and departure notes in time order. An entry adds one dancer and an exit removes one dancer.

The algorithm sorts the events by time, walks them once, and tracks the running total. Sorting costs O(N log N) with a balanced sort, and this solution uses insertion sort, so each test costs O(N²). Scanning every minute up to 10000000 would waste work on empty minutes.

The event sweep touches only times that change the crowd size.

## Why It Works

1. Every visit contributes one entry event and one exit event.
2. All event times are distinct, so the sweep has no tie cases.
3. Between two consecutive event times the crowd size stays constant.
4. The running total after each event equals the crowd size after that moment.
5. The largest running total over the sweep is the required peak.

| term | meaning |
|---|---|
| `hallEvents` | sorted list of timed crowd changes |
| `dancerDelta` | +1 for an entry, -1 for an exit |
| `dancersNow` | crowd size after the current event |
| `peakDancers` | largest crowd seen so far |

The sample produces these events in order: (1,+1), (2,+1), (3,+1), (4,-1), (5,+1), (6,+1), (7,-1), (8,-1), (9,-1), (10,-1). The running totals are 1, 2, 3, 2, 3, 4, 3, 2, 1, 0, so the peak is 4.

The peak of the running total is exactly the answer.

## Code

**Input and event builder.** The reader loads every integer and pairs entries with exits.

```nim
const flushBlockBytes = 1 shl 17

type HallEvent = tuple[eventTime: int, dancerDelta: int]

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

proc sortEvents(events: var seq[HallEvent]) =
  for rightIndex in 1 .. events.high:
    let heldEvent = events[rightIndex]
    var leftIndex = rightIndex - 1
    while leftIndex >= 0 and events[leftIndex].eventTime > heldEvent.eventTime:
      events[leftIndex + 1] = events[leftIndex]
      leftIndex -= 1
    events[leftIndex + 1] = heldEvent
```

Insertion sort keeps the code short for N up to 100.
The tuple fields give each number a clear role.
The scanner skips line breaks without special cases.

**Event sweep and output.** The solver walks sorted events once per test.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let visitorCount = nextInt(inputData, scanPos)
  var hallEvents = newSeq[HallEvent](2 * visitorCount)
  for visitorIndex in 0 .. visitorCount - 1:
    let enterTime = nextInt(inputData, scanPos)
    let leaveTime = nextInt(inputData, scanPos)
    hallEvents[2 * visitorIndex] = (enterTime, 1)
    hallEvents[2 * visitorIndex + 1] = (leaveTime, -1)
  sortEvents(hallEvents)
  var dancersNow = 0
  var peakDancers = 0
  for eventIndex in 0 .. hallEvents.high:
    dancersNow += hallEvents[eventIndex].dancerDelta
    if dancersNow > peakDancers:
      peakDancers = dancersNow
  appendOutput($peakDancers)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Each test produces exactly one answer line.
The running total never needs the large time bound.
One buffered write flushes all answers at the end.

## Complexity

Each test sorts 2N events and then walks them once.

| phase | time | space |
|---|---|---|
| input read | one pass over all tokens | one input string |
| event sort | insertion sort on 2N events | 2N event tuples |
| event sweep | one pass over 2N events | constant |
| output | one buffered write | block buffer |

The sort dominates for large N within the stated bound.

| measure | Big O |
|---|---|
| time | O(T · N²) with insertion sort |
| space | O(N) |

A minute-by-minute scan would cost O(T · 10000000) and waste most steps. The event sweep touches only moments that matter.
