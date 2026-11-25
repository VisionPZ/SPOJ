# ALEAVE — Annual leave calculator (SPOJ)
<https://www.spoj.com/problems/ALEAVE/>

## Problem

Merge a person's leave requests and report how many distinct days are marked as leave. A request covers its start day and stops before its end day, which is the first day back at work.

The first line gives the request count. Each following line gives a start day and an end day between 1 and 366. Requests may arrive out of order and may overlap. Print one integer, the number of leave days.

| Constraint | Value |
| --- | --- |
| Day numbers | 1 to 366 |
| Request count | any number |
| Judge time | 1000 ms |
| Judge memory | 1536 MB |

A 366-day table handles every request in constant time.

The sample input and its expected output follow byte for byte.

```
3
140 145
120 123
121 122
```

```
8
```

The three requests merge into eight distinct days.

## Idea

Counting with a difference table is like marking a calendar with plus signs at each start and minus signs at each return day. Walking the calendar once adds up the marks and tells which days are leave.

The program stores a change at `startDay` and the opposite change at `endDay`. It then sweeps days 1 through 366 and counts days with a positive running total. Overlaps add and cancel naturally.

Marking every requested day would repeat work on overlaps. The difference table touches each request twice and each day once.

## Why It Works

1. A request covers days from start through end minus one.
2. Adding one at start raises the active count for that day onward.
3. Subtracting one at end lowers the count on the first work day.
4. A day is leave exactly when the running count is positive.
5. Counting positive days once gives the union of all requests.

| Term | Meaning |
| --- | --- |
| `dayChanges` | plus and minus marks per day |
| `activeRequests` | running count of overlapping requests |
| `usedDayCount` | number of days with leave |
| `maxLeaveDay` | last day of the year, 366 |

These four names describe the whole calendar pass.

A script check on the sample gives day marks at 120, 121, 140 and 145.

| Day | Running count | Leave day |
| --- | --- | --- |
| 120 | 1 | yes |
| 121 | 2 | yes |
| 122 | 1 | yes |
| 123 | 0 | no |
| 140 | 1 | yes |
| 141 | 1 | yes |
| 142 | 1 | yes |
| 143 | 1 | yes |
| 144 | 1 | yes |
| 145 | 0 | no |

Eight days carry a positive count, which matches the sample output.

## Code

**Input reader and output buffer.** The hand scanner loads the count and every request pair.

```nim
const flushBlockBytes = 1 shl 17
const maxLeaveDay = 366

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

Token parsing skips spaces and line breaks.
One final write empties the buffer.

**Difference table sweep.** Each request writes two marks, then one pass counts leave days.

```nim
let requestCount = nextInt(inputData, scanPos)
var dayChanges = newSeq[int](maxLeaveDay + 2)
for requestIndex in 0 .. requestCount - 1:
  var startDay = nextInt(inputData, scanPos)
  var endDay = nextInt(inputData, scanPos)
  if startDay < 1:
    startDay = 1
  if endDay > maxLeaveDay + 1:
    endDay = maxLeaveDay + 1
  if startDay < endDay:
    dayChanges[startDay] += 1
    dayChanges[endDay] -= 1
var usedDayCount: int64 = 0
var activeRequests = 0
for dayIndex in 1 .. maxLeaveDay:
  activeRequests += dayChanges[dayIndex]
  if activeRequests > 0:
    usedDayCount += 1
appendOutput($usedDayCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Bounds guards keep marks inside the table.
A request whose start equals its end adds no leave days.

## Complexity

Each request costs two writes and each day costs one read.

| Phase | Time | Space |
| --- | --- | --- |
| input read | one pass over the stream | one input string |
| difference marks | constant work per request | 368 counters |
| day sweep | one pass over 366 days | two counters |
| output | one line | block buffer |

Space stays fixed regardless of the request count.

| Measure | Big O |
| --- | --- |
| time | O(requests + 366) |
| space | O(366) |

Marking every requested day would repeat work wherever requests overlap.

The difference table counts each day once.
