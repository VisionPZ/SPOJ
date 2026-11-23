## Problem

Read a sequence of bus networks from one input stream. Each bus follows a fixed circular list of stations and takes one minute per hop. Drivers share every piece of news when they meet at a station, including at minute zero when their start stations match. Print the minute when all drivers know all news, or print NEVER when that never happens.

The bounds and judge limits are:

| Quantity | Bound |
| --- | --- |
| Bus lines in one case | 1 to 49 |
| Stops on one line | 1 to 49 |
| Test cases | until a line holds 0 |
| Time limit | 7000 ms |
| Memory limit | 1536 MB |

Both counts stay small, so a pairwise scan fits the time limit.

## Idea

Model a meeting as a channel that passes news instantly in both directions. For each bus pair, list the meeting minutes inside their least common multiple (the first shared return to both start stations). Simulating every minute of the whole network takes far longer, so we propagate one source's earliest arrival minute across the bus pairs.

Each bus pair costs at most 2352 minute checks, and each propagation step costs one binary search.

## Why It Works

A bus stands at station route[t mod s] at minute t, where s is its stop count. A pair repeats its meetings every l minutes, where l is the least common multiple of the two stop counts. If the pair never meets inside one period of length l, the pair never exchanges news.

News travels along a chain of meetings. The earliest arrival at a bus is enough, since a later arrival cannot help that bus inform others. A shortest chain visits each bus once at most, so at most busCount - 1 hops are needed.

The next meeting after minute t uses withinPeriod = t mod periodLength. A meeting time at or after withinPeriod occurs at t - withinPeriod plus that meeting time. Otherwise it occurs in the next cycle, at t - withinPeriod plus periodLength plus the first meeting time.

The sample network gives these meeting lists:

| Bus pair | Combined cycle | Meeting minutes in one cycle |
| --- | --- | --- |
| 0 and 1 | 3 | none |
| 0 and 2 | 12 | 4, 5 |
| 1 and 2 | 12 | 0, 1 |

Bus 0 meets bus 2 at minute 4, and bus 1 hears that news at minute 12.

The resulting arrival minutes are:

| Source | Bus 0 | Bus 1 | Bus 2 |
| --- | --- | --- | --- |
| 0 | 0 | 12 | 4 |
| 1 | 4 | 0 | 0 |
| 2 | 4 | 0 | 0 |

The largest entry is 12, which is the sample answer.

## Code

The scanner advances one index over one input buffer, which avoids per-line reads. The divisor loop ends after O(log stopCount) steps. Cost is linear in input digits plus pairs.

```
const infiniteTime = 1000000000
const flushBlockBytes = 1 shl 17

type BusPair = object
  firstBus: int
  secondBus: int
  periodLength: int
  meetingTimes: seq[int]

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos = scanPos + 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - 48
    scanPos = scanPos + 1
  return value

proc greatestCommonDivisor(firstValue, secondValue: int): int =
  var leftValue = firstValue
  var rightValue = secondValue
  while rightValue != 0:
    let remainder = leftValue mod rightValue
    leftValue = rightValue
    rightValue = remainder
  return leftValue
```

Binary search keeps each lookup at O(log meetingTimes.len). The last line wraps into the next cycle when no meeting remains. Cost is one lookup per propagation step.

```
proc nextMeetingTime(meetingTimes: seq[int], periodLength, currentTime: int): int =
  let withinPeriod = currentTime mod periodLength
  var lowIndex = 0
  var highIndex = meetingTimes.len
  while lowIndex < highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if meetingTimes[middleIndex] < withinPeriod:
      lowIndex = middleIndex + 1
    else:
      highIndex = middleIndex
  if lowIndex < meetingTimes.len:
    return currentTime - withinPeriod + meetingTimes[lowIndex]
  return currentTime - withinPeriod + periodLength + meetingTimes[0]
```

Route reading ends after stopCount tokens. The pair loop visits each unordered pair once. The minute loop runs exactly periodLength times, which is at most 2352. Empty meeting lists stay out of pairList.

```
var inputData: string
var inputLine: string
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add "\n"

var scanPos = 0
var outputBuffer: string

while true:
  let busCount = nextInt(inputData, scanPos)
  if busCount == 0: break
  var routes: seq[seq[int]] = @[]
  for busIndex in 0 .. busCount - 1:
    let stopCount = nextInt(inputData, scanPos)
    var route: seq[int] = @[]
    for stopIndex in 0 .. stopCount - 1:
      route.add nextInt(inputData, scanPos)
    routes.add route
  var pairList: seq[BusPair] = @[]
  for leftBusIndex in 0 .. busCount - 1:
    for rightBusIndex in leftBusIndex + 1 .. busCount - 1:
      let firstLength = routes[leftBusIndex].len
      let secondLength = routes[rightBusIndex].len
      let divisor = greatestCommonDivisor(firstLength, secondLength)
      let periodLength = firstLength div divisor * secondLength
      var meetingTimes: seq[int] = @[]
      for timeIndex in 0 .. periodLength - 1:
        if routes[leftBusIndex][timeIndex mod firstLength] == routes[rightBusIndex][timeIndex mod secondLength]:
          meetingTimes.add timeIndex
      if meetingTimes.len > 0:
        pairList.add BusPair(firstBus: leftBusIndex, secondBus: rightBusIndex,
                             periodLength: periodLength, meetingTimes: meetingTimes)
```

The propagation loop runs busCount + 1 times at most and stops early when nothing changes. The guards skip buses that have not learned the source yet. One final pass prints the largest arrival or NEVER. Output flushes every flushBlockBytes bytes.

```
  var arrivalTimes = newSeq[seq[int]](busCount)
  for busIndex in 0 .. busCount - 1:
    arrivalTimes[busIndex] = newSeq[int](busCount)
    for sourceIndex in 0 .. busCount - 1:
      if busIndex == sourceIndex:
        arrivalTimes[busIndex][sourceIndex] = 0
      else:
        arrivalTimes[busIndex][sourceIndex] = infiniteTime
  for roundIndex in 0 .. busCount:
    var changed = false
    for busPair in pairList:
      let leftBus = busPair.firstBus
      let rightBus = busPair.secondBus
      let periodLength = busPair.periodLength
      let meetingTimes = busPair.meetingTimes
      for sourceIndex in 0 .. busCount - 1:
        if arrivalTimes[rightBus][sourceIndex] < infiniteTime:
          let candidate = nextMeetingTime(meetingTimes, periodLength, arrivalTimes[rightBus][sourceIndex])
          if candidate < arrivalTimes[leftBus][sourceIndex]:
            arrivalTimes[leftBus][sourceIndex] = candidate
            changed = true
        if arrivalTimes[leftBus][sourceIndex] < infiniteTime:
          let candidate = nextMeetingTime(meetingTimes, periodLength, arrivalTimes[leftBus][sourceIndex])
          if candidate < arrivalTimes[rightBus][sourceIndex]:
            arrivalTimes[rightBus][sourceIndex] = candidate
            changed = true
    if not changed: break
  var latestArrival = 0
  for busIndex in 0 .. busCount - 1:
    for sourceIndex in 0 .. busCount - 1:
      if arrivalTimes[busIndex][sourceIndex] > latestArrival:
        latestArrival = arrivalTimes[busIndex][sourceIndex]
  if latestArrival >= infiniteTime:
    outputBuffer.add "NEVER\n"
  else:
    outputBuffer.add $latestArrival
    outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```

## Complexity

The table gives the cost of each phase, with n for busCount and L for the largest pair cycle:

| Phase | Time | Extra space |
| --- | --- | --- |
| Input and routes | O(total stops) | O(total stops) |
| Meeting lists | O(n^2 L) | O(n^2 L) worst case |
| Propagation | O(n^4 log L) | O(n^2) |
| Output | O(number of cases) | O(flush block) |

The meeting lists and propagation dominate, and both stay small for n at most 49.

Total time is O(n^2 L + n^4 log L + input + output), and total space is O(n^2 L + n^2). A minute-by-minute simulation walks the whole network cycle, which can be much larger than these bounds.
