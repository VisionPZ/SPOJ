# EPTT — Easy Programming Tutorials (SPOJ)

<https://www.spoj.com/problems/EPTT/>

## Problem

Students request lessons at given minute marks, and each lesson lasts 30 minutes. A tutor works one stretch of at most four back-to-back lessons, so find the smallest number of tutors that covers every request.

Input starts with `R`, followed by `R` start times, one per line. Output one integer, the minimum tutor count. A request at minute `S` must be taught by a tutor free at `S`, and a tutor's lesson starts differ by exactly 30 minutes.

| item | bound |
|---|---|
| requests R | 1 to 1000000 |
| start minute | 0 to 1410 |
| lessons per tutor | at most 4, back-to-back |
| judge limit | 2000 ms, 1536 MB |

The sample from the statement:

```
5
0
0
30
60
61
```

```
3
```

## Idea

Group requests by their minute remainder, like sorting appointments into separate calendars. A tutor who teaches at minute 30 cannot teach at 61, because lessons must touch, so times with different remainders mod 30 never share a tutor. Within one calendar, reuse a tutor who taught fewer lessons first; that tutor stays usable longer.

The algorithm counts requests per minute, then scans each of the 30 calendars. Each step reuses available tutors and starts new ones only for the leftover demand. Counting and scanning cost `O(R + 1410)`, while testing every group of tutors would be far slower. Reuse with the longest remaining stretch keeps the tutor count minimal.

## Why It Works

1. Back-to-back lessons start 30 minutes apart, so a tutor only serves times with the same remainder mod 30.
2. Two requests at the same minute need two tutors, since one tutor teaches one lesson at a time.
3. An empty minute ends every active stretch, because a skipped lesson breaks consecutiveness.
4. A tutor who taught one lesson can teach at most three more; one who taught three can teach one more.
5. Reusing the least-used tutor first preserves the longest future stretch for later minutes.

| term | meaning |
|---|---|
| `requestCounts` | number of requests at each minute from 0 to 1410 |
| `freshTutors` | tutors who taught one lesson and can continue |
| `onceUsedTutors` | tutors who taught two lessons and can continue |
| `twiceUsedTutors` | tutors who taught three lessons and can continue |
| `tutorCount` | total number of tutors started |

The table names the three reusable pools and the final answer.

A script trace of the sample follows.

| minute | demand | reuse | new tutors | running total |
|---|---|---|---|---|
| 0 | 2 | none available | 2 | 2 |
| 30 | 1 | one fresh tutor | 0 | 2 |
| 60 | 1 | one fresh tutor | 0 | 2 |
| 61 | 1 | none available | 1 | 3 |

The trace ends at three tutors, matching the sample output.

## Code

**Input counting.** The hand scanner loads the request count and every start minute.

```nim
const flushBlockBytes = 1 shl 17
const latestStart = 1410
const minutesPerLesson = 30
const residueCount = 30

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

let requestCount = nextInt(inputData, scanPos)
var requestCounts = newSeq[int](latestStart + 1)
for requestIndex in 0 .. requestCount - 1:
  let startMinute = nextInt(inputData, scanPos)
  requestCounts[startMinute] += 1
```

Start minutes index an array directly, so no sorting is needed.
Requests at the same minute accumulate in one cell.
The buffer flushes only when it reaches the block size.

**Tutor reuse scan.** Each remainder class is scanned 30 minutes apart.

```nim
var tutorCount = 0
for residue in 0 .. residueCount - 1:
  var freshTutors = 0
  var onceUsedTutors = 0
  var twiceUsedTutors = 0
  var lessonStart = residue
  while lessonStart <= latestStart:
    let demand = requestCounts[lessonStart]
    if demand == 0:
      freshTutors = 0
      onceUsedTutors = 0
      twiceUsedTutors = 0
    else:
      var remainingDemand = demand
      let useFresh = min(remainingDemand, freshTutors)
      remainingDemand -= useFresh
      let useOnce = min(remainingDemand, onceUsedTutors)
      remainingDemand -= useOnce
      let useTwice = min(remainingDemand, twiceUsedTutors)
      remainingDemand -= useTwice
      freshTutors = remainingDemand
      onceUsedTutors = useFresh
      twiceUsedTutors = useOnce
      tutorCount += remainingDemand
    lessonStart += minutesPerLesson

appendOutput($tutorCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

An empty minute clears all three reusable pools.
Fresh tutors are reused first, then once-used tutors, then twice-used tutors.
Only unserved requests start a new tutor.

## Complexity

Counting and scanning dominate the runtime.

| phase | time | space |
|---|---|---|
| input read | one pass over `R` start minutes | one input string |
| counting | `O(R)` increments | 1411 counters |
| tutor scan | 30 short walks over the counters | three small pools |
| output | one integer | block buffer |

The number of requests drives input time; the fixed minute range drives scan time.

| measure | Big O |
|---|---|
| time | `O(R + 1410)` |
| space | `O(R + 1410)` |

Checking groups of tutors by trial would grow with the number of requests. The direct reuse scan handles a million requests with a fixed amount of work per minute.
