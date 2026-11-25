# TTABLE — Timetable (SPOJ)

<https://www.spoj.com/problems/TTABLE/>

## Problem

A rail passenger wants a booklet listing the best connections from city 1 to city n. Each station posts only direct trains, and a change costs no time. A connection is optimal when no alternative leaves no earlier, arrives no later, and takes strictly less time.

Input starts with the test count `t`. Each case starts with `n`, then lists `n` timetables. A timetable starts with `m`, followed by `m` rows of departure `A`, arrival `B`, and destination city. Clock times use `hh:mm` form, departures are sorted, and all `m` values sum to at most 1,000,000. Output the count `r`, then `r` increasing departure rows of the form `A B`. Duplicate clock pairs print once.

The judge warns about enormous input and output.

| Item | Bound |
| --- | --- |
| Cities per case | 2 to 100000 |
| Train positions over all timetables | at most 1000000 |
| Clock times | 00:00 to 23:59 |
| Judge limit | 1956 ms, 1536 MB |

A day holds 1440 minutes, so every time index stays tiny.

The sample input and output follow verbatim.

```
1
3
3
09:00 15:00 3
10:00 12:00 2
11:00 20:00 3
2
11:30 13:00 3
12:30 14:00 3
0
```

```
2
10:00 14:00
11:00 20:00
```

## Idea

Work backward from the destination and keep only journeys that cannot be beaten. Think of planning the last leg of a trip first, then saving the best departure and arrival pair for each earlier station.

Each city keeps a Pareto frontier of suffix journeys: pairs of departure time and earliest arrival at the destination. Trains are processed from latest departure to earliest. Because every train arrives after it leaves, the destination frontier is already complete. One binary search replaces a fresh full search through the graph.

A search restarted at every train costs quadratic work in the train count. Reusing finished frontiers cuts each train to logarithmic cost.

Finished suffixes turn a graph search into a table lookup.

## Why It Works

Four facts prove the method.

1. Arriving no later and departing no earlier never increases travel time. Optimal connections are the Pareto-maximal pairs of departure and arrival.
2. A frontier sorted by departure from latest to earliest also sorts by arrival from latest to earliest. The earliest feasible arrival after a time `B` sits at the last pair whose departure is at least `B`.
3. A train from `v` at `A` reaches `w` at `B`, with `B > A`. Every suffix from `w` departs after `A`, and earlier departure groups have already built that frontier.
4. A new pair departs earlier than every stored pair. It survives only when its arrival is smaller than the last stored arrival.

The table names the update values.

| Term | Meaning |
| --- | --- |
| `JourneyFrontier` | stored pairs, latest departure first |
| `earliestSuffixArrival` | finds the last feasible pair in a frontier |
| `arrivalTime` | time the current train reaches its destination |
| `currentDeparture` | departure of the group being processed |
| `suffixArrival` | earliest trip end the train can still reach |

`l` is the largest stored index whose departure is at least `arrivalTime`. A pair enters the frontier only when `candidateArrival` beats the last arrival.

This trace uses the sample input.

| Step | Train | Continuation | City 1 frontier afterward |
| --- | --- | --- | --- |
| 1 | 11:00 to city 3, arrive 20:00 | destination suffix starts at 20:00 | (11:00, 20:00) |
| 2 | 10:00 to city 2, arrive 12:00 | city 2 suffix gives 14:00 | (11:00, 20:00), (10:00, 14:00) |
| 3 | 09:00 to city 3, arrive 15:00 | 15:00 loses to 14:00 | unchanged |

The two surviving pairs print as `10:00 14:00` and `11:00 20:00`.

## Code

**Input setup.** Constants, bulk input, and the scanner set up parsing.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const minuteCount = 1440

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0
```

The read loop runs to EOF, so all input lands in one string. `minuteCount` bounds every time index. Cost is one pass over the input bytes.

**Digit scanner.** The digit scanner skips separators, including colons.

```nim
proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  return value
```

Every number is non-negative, so the scanner ignores signs and colons. It builds no token object. Each call costs time proportional to its digits.

**Clock output.** The output helpers write fixed-width clock times.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendClockTime(minutesValue: int) =
  let hourPart = minutesValue div 60
  let minutePart = minutesValue mod 60
  outputBuffer.add char(firstDigitValue + hourPart div 10)
  outputBuffer.add char(firstDigitValue + hourPart mod 10)
  outputBuffer.add ':'
  outputBuffer.add char(firstDigitValue + minutePart div 10)
  outputBuffer.add char(firstDigitValue + minutePart mod 10)
```

One buffer collects output and flushes every 256 KiB. `appendClockTime` writes two fixed-width digits per field. Cost is one flush per block, not per line.

**Frontier query.** The frontier query finds the best continuation.

```nim
type JourneyFrontier = seq[tuple[departure: int; arrival: int]]

proc earliestSuffixArrival(frontier: JourneyFrontier, earliestDeparture: int): int =
  if frontier.len == 0: return high(int)
  var i = 0
  var j = frontier.len - 1
  var l = -1
  while i <= j:
    let k = (i + j) div 2
    if frontier[k].departure >= earliestDeparture:
      l = k
      i = k + 1
    else:
      j = k - 1
  if l < 0: return high(int)
  return frontier[l].arrival
```

The search finds the rightmost pair departing at or after `earliestDeparture`. That pair has the smallest arrival among feasible suffixes. `high(int)` marks an unreachable destination. Cost is at most 11 comparisons.

**Reusable arrays.** Storage arrays are reused across cases.

```nim
var departureTimes: seq[int] = @[]
var arrivalTimes: seq[int] = @[]
var sourceCities: seq[int] = @[]
var destinationCities: seq[int] = @[]
var trainOrder: seq[int] = @[]
var departureCounts: array[minuteCount, int]
var nextSlot: array[minuteCount, int]
var cityFrontiers: seq[JourneyFrontier] = @[]
var bestArrivalByCity: seq[int] = @[]
var cityStamp: seq[int] = @[]
var touchedCities: seq[int] = @[]
var stampValue = 0
```

`setLen 0` clears a sequence without freeing its storage. `stampValue` avoids clearing a whole city table per departure group. Cost at a case start is constant.

**Case input.** Input for one case fills the flat arrays.

```nim
let caseCount = nextInt(inputData, i)
for j in 0..<caseCount:
  let cityCount = nextInt(inputData, i)
  departureTimes.setLen 0
  arrivalTimes.setLen 0
  sourceCities.setLen 0
  destinationCities.setLen 0
  for k in 1..cityCount:
    let positionCount = nextInt(inputData, i)
    for l in 0..<positionCount:
      let departHour = nextInt(inputData, i)
      let departMinute = nextInt(inputData, i)
      let arriveHour = nextInt(inputData, i)
      let arriveMinute = nextInt(inputData, i)
      let targetCity = nextInt(inputData, i)
      departureTimes.add departHour * 60 + departMinute
      arrivalTimes.add arriveHour * 60 + arriveMinute
      sourceCities.add k
      destinationCities.add targetCity
  let trainCount = departureTimes.len
```

Two digit reads build each clock time, so colons need no branch. Each train stores four integers. Cost is one add per train position.

**Counting sort.** Counting sort orders trains by departure.

```nim
  for k in 0..<minuteCount: departureCounts[k] = 0
  for k in 0..<trainCount:
    departureCounts[departureTimes[k]] += 1
  var runningSlot = 0
  var k = minuteCount - 1
  while k >= 0:
    nextSlot[k] = runningSlot
    runningSlot += departureCounts[k]
    k -= 1
  trainOrder.setLen trainCount
  for k in 0..<trainCount:
    let departTime = departureTimes[k]
    trainOrder[nextSlot[departTime]] = k
    nextSlot[departTime] += 1
```

The minute scan runs from 1439 down to 0, so `trainOrder` starts latest. Counting sort replaces a comparison sort over a million trains. Cost is `O(trainCount + 1440)`.

**Frontier sweep.** The sweep builds each city frontier from latest departure to earliest.

```nim
  cityFrontiers.setLen cityCount + 1
  for k in 0..cityCount: cityFrontiers[k].setLen 0
  bestArrivalByCity.setLen cityCount + 1
  cityStamp.setLen cityCount + 1

  var l = 0
  while l < trainCount:
    let currentDeparture = departureTimes[trainOrder[l]]
    var k = l
    while k < trainCount and departureTimes[trainOrder[k]] == currentDeparture:
      k += 1
    stampValue += 1
    touchedCities.setLen 0
    for i in l..<k:
      let k = trainOrder[i]
      let sourceCity = sourceCities[k]
      if sourceCity == cityCount: continue
      let targetCity = destinationCities[k]
      let arrivalTime = arrivalTimes[k]
      var suffixArrival: int
      if targetCity == cityCount:
        suffixArrival = arrivalTime
      else:
        suffixArrival = earliestSuffixArrival(cityFrontiers[targetCity], arrivalTime)
      if suffixArrival == high(int): continue
      if cityStamp[sourceCity] != stampValue:
        cityStamp[sourceCity] = stampValue
        bestArrivalByCity[sourceCity] = suffixArrival
        touchedCities.add sourceCity
      elif suffixArrival < bestArrivalByCity[sourceCity]:
        bestArrivalByCity[sourceCity] = suffixArrival
    for sourceCity in touchedCities:
      let candidateArrival = bestArrivalByCity[sourceCity]
      let frontierSize = cityFrontiers[sourceCity].len
      if frontierSize > 0 and candidateArrival >= cityFrontiers[sourceCity][frontierSize - 1].arrival: continue
      cityFrontiers[sourceCity].add (currentDeparture, candidateArrival)
    l = k
```

The outer loop visits each departure group once. Trains sharing a departure collapse to the smallest arrival per city. The last-entry test drops dominated pairs. Cost is `O(trainCount log 1440)`.

**Answer output.** Output prints city 1's frontier in increasing departure order.

```nim
  let answerFrontier = cityFrontiers[1]
  appendOutput($(answerFrontier.len))
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
  for k in 0..<answerFrontier.len:
    let l = answerFrontier.len - 1 - k
    appendClockTime(answerFrontier[l].departure)
    outputBuffer.add ' '
    appendClockTime(answerFrontier[l].arrival)
    outputBuffer.add '\n'
    if outputBuffer.len >= flushBlockBytes:
      stdout.write outputBuffer
      outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
```

Reverse indexing prints increasing departure times. The final write flushes the remaining bytes. Cost is one line per optimal pair.

## Complexity

Each phase has a clear bound.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over input bytes | input string |
| Counting sort | O(T + 1440) | one order array |
| Frontier build | O(T log 1440) | one pair per kept suffix |
| Output | one flush per 256 KiB | 256 KiB buffer |

The frontier build dominates, since 1440 stays fixed.

Totals use `T` for train positions in one case and `C` for cities.

| Measure | Big O |
| --- | --- |
| Time | O(T log 1440) per case |
| Space | O(C + T) per case |

A fresh graph search from every train costs `O(T^2)` in the worst case.
