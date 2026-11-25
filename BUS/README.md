# BUS — Bus (SPOJ)
<https://www.spoj.com/problems/BUS/>

## Problem

Bus drivers in Buscelona chat whenever they meet at a stop. Each driver starts with news that only he knows. Find the minute when every driver knows all news, or print NEVER.

Input holds many networks separated by blank lines. Each network starts with a bus count n, and n is zero at the end. Each following line gives a stop count s and then s station numbers, starting from the first station. Output one time in minutes or the word NEVER per network.

The bounds and judge limits are:

| Quantity | Bound |
| --- | --- |
| Bus lines per case | 1 to 49 |
| Stops per line | 1 to 49 |
| Test cases | until the count is zero |
| Time limit | 7000 ms |
| Memory limit | 1536 MB |

Both counts stay small, so a pairwise scan fits the limit.

The sample input and output:

```
3
3 1 2 3
3 2 3 1
4 2 3 4 5

2
2 1 2
2 5 8
0
```

```
12
NEVER
```

The first network needs 12 minutes; the second has no shared station.

## Idea

Treat a meeting as a channel that passes news both ways. For each bus pair, list the meeting minutes inside one least common multiple of the route lengths. That period is the first time both buses return to their start stations. Then propagate the earliest news arrival across the pairs. Think of passing a rumor along a chain of friends: the first time each friend hears it is all that matters.

Each pair checks at most 2401 minutes, and each propagation step costs one binary search. Simulating every minute of the whole network would run far longer.

Takeaway: precompute pair meetings, then spread earliest arrival times.

## Why It Works

1. A bus stands at station route[t mod s] at minute t, where s is its stop count.
2. A pair repeats its meetings every l minutes, the least common multiple of the two stop counts.
3. A pair with no meeting in one period never exchanges news.
4. The earliest arrival at a bus is enough, since a later arrival cannot help that bus inform others.
5. `nextMeetingTime` uses binary search to find the first meeting at or after the current minute.
6. A shortest chain visits each bus at most once, so at most n - 1 hops are needed.

The propagation uses these terms.

| Term | Meaning |
| --- | --- |
| `periodLength` | least common multiple of two route lengths |
| `meetingTimes` | sorted minutes inside one period |
| `arrivalTimes[j][k]` | earliest minute bus j learns bus k's news |
| `infiniteTime` | stand-in for a bus not yet informed |

The largest arrival is the answer; infinity becomes NEVER.

The sample network gives these meeting lists:

| Bus pair | Cycle | Meeting minutes |
| --- | --- | --- |
| 0 and 1 | 3 | none |
| 0 and 2 | 12 | 4, 5 |
| 1 and 2 | 12 | 0, 1 |

Bus 0 meets bus 2 at minute 4, and bus 1 hears that news at minute 12.

## Code

**Constants, types, and helpers.**
```nim
const infiniteTime = 1000000000
const flushBlockBytes = 1 shl 17

type BusPair = object
  firstBus: int
  secondBus: int
  periodLength: int
  meetingTimes: seq[int]

proc nextInt(inputData: string, i: var int): int =
  while i < inputData.len and inputData[i] <= ' ':
    i = i + 1
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - 48
    i = i + 1
  return value

proc greatestCommonDivisor(firstValue, secondValue: int): int =
  var leftValue = firstValue
  var rightValue = secondValue
  while rightValue != 0:
    let remainder = leftValue mod rightValue
    leftValue = rightValue
    rightValue = remainder
  return leftValue

proc nextMeetingTime(meetingTimes: seq[int], periodLength, currentTime: int): int =
  let withinPeriod = currentTime mod periodLength
  var i = 0
  var j = meetingTimes.len
  while i < j:
    let k = (i + j) div 2
    if meetingTimes[k] < withinPeriod:
      i = k + 1
    else:
      j = k
  if i < meetingTimes.len:
    return currentTime - withinPeriod + meetingTimes[i]
  return currentTime - withinPeriod + periodLength + meetingTimes[0]
```
`BusPair` stores two bus indices, a period, and meeting minutes. `greatestCommonDivisor` supplies the least common multiple. `nextMeetingTime` binary searches the first meeting at or after a minute.

**Input and routes.**
```nim
var inputData: string
var inputLine: string
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add "\n"

var i = 0
var outputBuffer: string

while true:
  let busCount = nextInt(inputData, i)
  if busCount == 0: break
  var routes: seq[seq[int]] = @[]
  for j in 0 .. busCount - 1:
    let stopCount = nextInt(inputData, i)
    var route: seq[int] = @[]
    for k in 0 .. stopCount - 1:
      route.add nextInt(inputData, i)
    routes.add route
```
The buffer gathers lines, and `nextInt` walks digits. Each network reads its bus count and routes; count zero ends the run.

**Pair meetings and propagation.**
```nim
  var pairList: seq[BusPair] = @[]
  for j in 0 .. busCount - 1:
    for k in j + 1 .. busCount - 1:
      let firstLength = routes[j].len
      let secondLength = routes[k].len
      let divisor = greatestCommonDivisor(firstLength, secondLength)
      let periodLength = firstLength div divisor * secondLength
      var meetingTimes: seq[int] = @[]
      for l in 0 .. periodLength - 1:
        if routes[j][l mod firstLength] == routes[k][l mod secondLength]:
          meetingTimes.add l
      if meetingTimes.len > 0:
        pairList.add BusPair(firstBus: j, secondBus: k,
                             periodLength: periodLength, meetingTimes: meetingTimes)
  var arrivalTimes = newSeq[seq[int]](busCount)
  for j in 0 .. busCount - 1:
    arrivalTimes[j] = newSeq[int](busCount)
    for k in 0 .. busCount - 1:
      if j == k:
        arrivalTimes[j][k] = 0
      else:
        arrivalTimes[j][k] = infiniteTime
  for j in 0 .. busCount:
    var changed = false
    for busPair in pairList:
      let leftBus = busPair.firstBus
      let rightBus = busPair.secondBus
      let periodLength = busPair.periodLength
      let meetingTimes = busPair.meetingTimes
      for k in 0 .. busCount - 1:
        if arrivalTimes[rightBus][k] < infiniteTime:
          let candidate = nextMeetingTime(meetingTimes, periodLength, arrivalTimes[rightBus][k])
          if candidate < arrivalTimes[leftBus][k]:
            arrivalTimes[leftBus][k] = candidate
            changed = true
        if arrivalTimes[leftBus][k] < infiniteTime:
          let candidate = nextMeetingTime(meetingTimes, periodLength, arrivalTimes[leftBus][k])
          if candidate < arrivalTimes[rightBus][k]:
            arrivalTimes[rightBus][k] = candidate
            changed = true
    if not changed: break
```
The code builds one `BusPair` per pair with a shared station. `arrivalTimes` starts at zero on the diagonal and infinity elsewhere. Repeated relaxation spreads news until a full pass changes nothing.

**Answer and output.**
```nim
  var latestArrival = 0
  for j in 0 .. busCount - 1:
    for k in 0 .. busCount - 1:
      if arrivalTimes[j][k] > latestArrival:
        latestArrival = arrivalTimes[j][k]
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
The largest arrival becomes the answer, or NEVER when it stays at infinity. The buffer flushes at the block boundary.

## Complexity

Bus and stop counts are both below 50.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | one pass over input bytes | input bytes |
| Pair meeting lists | O(n squared times lcm) | O(n squared) |
| Propagation | O(n cubed) worst case | n squared integers |
| Output | one write per block | flushBlockBytes |

The least common multiple stays at most 2401, so list building is cheap.

| Measure | Big O |
| --- | --- |
| Time per case | O(n cubed plus n squared times lcm) |
| Space per case | O(n squared) |

Simulating every minute up to the answer could run for thousands of steps, while meeting lists jump straight to the next exchange.
