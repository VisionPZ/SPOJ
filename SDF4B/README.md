# SDF4B — Building Schedules (SPOJ)

<https://www.spoj.com/problems/SDF4B/>

## Problem

Hold as many booked events as the available rooms allow. After each event, its room stays busy for 30 minutes plus one minute per participant.

The first line gives N rooms and M bookings. Each booking gives a start time, an end time as `HH:MM - HH:MM`, and a participant count. Print two Indonesian lines with the event count and the room count.

| item | bound |
|---|---|
| rooms N | 1 to 100000 |
| bookings M | 1 to 10000 |
| participants per event | up to 100 |
| clock range | 00:00 to 23:59 |
| judge limit | 250 ms, 1536 MB |

Room count limits how many overlapping events can run at once.

The first sample input:

```
3 3
06:00 - 08:30 20
07:00 - 09:00 10
09:40 - 11:00 5
```

It gives three bookings in a building with three rooms.

The first sample output:

```
Jumlah kegiatan/acara: 3
Jumlah ruang: 2
```

All three events run, and two rooms suffice.

## Idea

Think of each booking as a table that stays reserved while staff clear it, like a restaurant turning tables. Sort bookings by finish time, then place each in the room that frees latest but still before its start. That best-fit choice accepts the most events and opens a new room only when needed. Checking every subset costs O(2^M) and is far slower. Takeaway: sort once, then place greedily.

## Why It Works

1. A room frees at end time plus 30 plus the participant count.
2. Two events share a room when the first finish is at or before the second start.
3. Sorting by finish leaves later events with the widest room choice.
4. Best fit keeps early-freeing rooms ready for events that start soon.
5. A new room opens only when no room fits, so the room count stays minimal.

| term | meaning |
|---|---|
| `startTime` | event start in minutes from midnight |
| `finishTime` | end plus 30 minutes plus cleanup minutes |
| `roomFreetimes` | sorted list of minutes when each room becomes free |
| `bestRoomIndex` | rightmost room free before this event starts |
| `scheduledCount` | number of events accepted |

The table tracks one booking from its clock times to a room choice.

A script trace of the first sample uses finishes 09:20, 09:40 and 11:35. The first event takes room one until 09:20. The second starts at 07:00, so room two opens until 09:40. The third starts at 09:40 and reuses room one.

```
06:00 - 08:30 + 20 + 30 -> 09:20
07:00 - 09:00 + 10 + 30 -> 09:40
09:40 - 11:00 + 5 + 30 -> 11:35
accepted 3 events in 2 rooms
```

The trace matches the first sample output.

Times stay as integer minutes, so no rounding guard is needed.

## Code

**Parsing and finish sort.** The scanner reads clock fields as integers, and insertion sort orders bookings.

```nim
type Schedule = object
  startTime: int
  finishTime: int

const flushBlockBytes = 1 shl 17
const minutesPerHour = 60
const cleanupMinutes = 30

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

let roomCount = nextInt(inputData, scanPos)
let eventCount = nextInt(inputData, scanPos)
var schedules = newSeq[Schedule](eventCount)
for eventIndex in 0 .. eventCount - 1:
  let startHour = nextInt(inputData, scanPos)
  let startMinute = nextInt(inputData, scanPos)
  let endHour = nextInt(inputData, scanPos)
  let endMinute = nextInt(inputData, scanPos)
  let participantCount = nextInt(inputData, scanPos)
  schedules[eventIndex].startTime = startHour * minutesPerHour + startMinute
  schedules[eventIndex].finishTime = endHour * minutesPerHour + endMinute + cleanupMinutes + participantCount

for sortIndex in 1 .. eventCount - 1:
  let currentSchedule = schedules[sortIndex]
  var previousIndex = sortIndex - 1
  while previousIndex >= 0:
    let earlierSchedule = schedules[previousIndex]
    if earlierSchedule.finishTime < currentSchedule.finishTime:
      break
    if earlierSchedule.finishTime == currentSchedule.finishTime and earlierSchedule.startTime <= currentSchedule.startTime:
      break
    schedules[previousIndex + 1] = earlierSchedule
    previousIndex -= 1
  schedules[previousIndex + 1] = currentSchedule
```

Colons and dashes are skipped by the integer scanner.
Cleanup enters `finishTime` during parsing.
Ties keep the earlier start first.

**Room placement and output.** A binary search finds the last fitting room, then its free time moves right.

```nim
var roomFreetimes = newSeq[int](0)
var scheduledCount = 0
for eventIndex in 0 .. eventCount - 1:
  let currentStart = schedules[eventIndex].startTime
  let currentFinish = schedules[eventIndex].finishTime
  var lowIndex = 0
  var highIndex = roomFreetimes.len - 1
  var bestRoomIndex = -1
  while lowIndex <= highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if roomFreetimes[middleIndex] <= currentStart:
      bestRoomIndex = middleIndex
      lowIndex = middleIndex + 1
    else:
      highIndex = middleIndex - 1
  if bestRoomIndex >= 0:
    roomFreetimes[bestRoomIndex] = currentFinish
    while bestRoomIndex + 1 < roomFreetimes.len and roomFreetimes[bestRoomIndex] > roomFreetimes[bestRoomIndex + 1]:
      swap roomFreetimes[bestRoomIndex], roomFreetimes[bestRoomIndex + 1]
      bestRoomIndex += 1
    scheduledCount += 1
  elif roomFreetimes.len < roomCount:
    roomFreetimes.add currentFinish
    var insertedIndex = roomFreetimes.len - 1
    while insertedIndex > 0 and roomFreetimes[insertedIndex] < roomFreetimes[insertedIndex - 1]:
      swap roomFreetimes[insertedIndex], roomFreetimes[insertedIndex - 1]
      insertedIndex -= 1
    scheduledCount += 1

appendOutput("Jumlah kegiatan/acara: " & $scheduledCount)
outputBuffer.add '\n'
appendOutput("Jumlah ruang: " & $roomFreetimes.len)
outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The search picks the latest free time that still fits.
A new room appears only when every existing room is busy.
The two result lines use the exact Indonesian wording.

## Complexity

Sorting dominates small inputs, while room shifts dominate dense ones.

| phase | time | space |
|---|---|---|
| input read | one pass over M bookings | one input string |
| finish sort | M insertions | M booking records |
| room placement | binary search plus shifts per event | up to min(N, M) rooms |
| output | two lines | block buffer |

The room array never holds more entries than the event count.

| measure | Big O |
|---|---|
| time | O(M log M + M min(N, M)) worst case |
| space | O(M) |

Checking every subset of bookings would cost O(2^M).

Takeaway: best-fit placement keeps both counts correct without subset search.
