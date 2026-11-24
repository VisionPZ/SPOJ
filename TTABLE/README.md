## Problem

Read several test cases. Each case lists direct trains for every city. Find all optimal connections from city 1 to the last city. Print their count, then each departure and arrival time in increasing departure order.

A connection is optimal when no journey leaves at or after its departure, arrives at or before its arrival, and travels faster. Duplicate departure and arrival pairs count once.

The statement and judge table give these bounds.

| Item | Bound |
| --- | --- |
| Cities per case | 2 to 100 000 |
| Train positions over all timetables | at most 1 000 000 |
| Clock times | 00:00 to 23:59 |
| Judge limit | 1956 ms, 1536 MB |

A day has 1440 minutes, so every time index stays small.

## Idea

Build a Pareto frontier of suffix journeys for every city. A suffix journey leaves a city and reaches the destination. Each pair stores a departure time and its earliest arrival at the destination.

Process train departures from latest to earliest. A train arrives after it departs, so its destination frontier is already complete. The frontier reuses finished work, so one binary search replaces a fresh full search.

Cost per train: one binary search over at most 1440 pairs.

## Why It Works

Four facts prove the method.

First, an arrival no later than another and a departure no earlier than another never increase trip time. The time drops strictly unless both clock times match. Optimal connections are therefore the Pareto-maximal pairs.

Second, a frontier sorted by departure from latest to earliest also sorts by arrival from latest to earliest. The earliest feasible arrival after time B sits at the last pair whose departure is at least B.

Third, a train from v at A reaches w at B, and B is greater than A. Every suffix from w departs after B, hence after A. Earlier departure groups have already built that frontier.

Fourth, a new pair departs earlier than every stored pair. The last stored pair holds the smallest arrival. The new pair survives only when its arrival is smaller.

These terms drive the update.

| Term | Meaning |
| --- | --- |
| `JourneyFrontier` | stored pairs, ordered by departure from latest to earliest |
| `earliestSuffixArrival` | finds the last feasible pair in a frontier |
| `arrivalTime` | time the current train reaches its destination |
| `currentDeparture` | departure of the group now being processed |

`foundIndex` is the largest stored index whose departure is at least `arrivalTime`. `suffixArrival` is that pair's arrival, the earliest trip end the train can still reach. A pair enters the frontier when `candidateArrival` is smaller than the last stored arrival.

This trace uses the sample input, which gen.py checks.

| Step | Train | Continuation | City 1 frontier after the step |
| --- | --- | --- | --- |
| 1 | 11:00 to city 3, arrive 20:00 | destination suffix starts at 20:00 | (11:00, 20:00) |
| 2 | 10:00 to city 2, arrive 12:00 | city 2 suffix gives 14:00 | (11:00, 20:00), (10:00, 14:00) |
| 3 | 09:00 to city 3, arrive 15:00 | 15:00 loses to 14:00 | unchanged |

The two surviving pairs print as 10:00 14:00 and 11:00 20:00.

## Code

**Setup and bulk input.**

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const minuteCount = 1440

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
```

The read loop runs to EOF, so all input lands in one string. `minuteCount` bounds every time index. Cost: one pass over the input bytes.

**Digit scanner.**

```nim
proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value
```

The scanner skips colons and spaces, since every number is non-negative. `position` advances by index and builds no token object. Cost: one pass over each number's digits.

**Output helpers.**

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

One buffer collects all output and flushes every 256 KiB. `appendClockTime` writes two fixed-width digits per field. Cost: one flush per block, not per line.

**Frontier query.**

```nim
type JourneyFrontier = seq[tuple[departure: int; arrival: int]]

proc earliestSuffixArrival(frontier: JourneyFrontier, earliestDeparture: int): int =
  if frontier.len == 0: return high(int)
  var lowIndex = 0
  var highIndex = frontier.len - 1
  var foundIndex = -1
  while lowIndex <= highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if frontier[middleIndex].departure >= earliestDeparture:
      foundIndex = middleIndex
      lowIndex = middleIndex + 1
    else:
      highIndex = middleIndex - 1
  if foundIndex < 0: return high(int)
  return frontier[foundIndex].arrival
```

The search finds the rightmost pair whose departure is at least `earliestDeparture`. That pair has the smallest arrival among feasible suffixes. `high(int)` marks an unreachable destination. Cost: at most 11 comparisons.

**Reusable storage.**

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

The program reuses these arrays across cases. `setLen 0` clears a sequence without freeing its storage. `stampValue` avoids clearing a whole city table per group. Cost: constant work per case start.

**Input for one case.**

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let cityCount = nextInt(inputData, scanPos)
  departureTimes.setLen 0
  arrivalTimes.setLen 0
  sourceCities.setLen 0
  destinationCities.setLen 0
  for cityNumber in 1..cityCount:
    let positionCount = nextInt(inputData, scanPos)
    for positionIndex in 0..<positionCount:
      let departHour = nextInt(inputData, scanPos)
      let departMinute = nextInt(inputData, scanPos)
      let arriveHour = nextInt(inputData, scanPos)
      let arriveMinute = nextInt(inputData, scanPos)
      let targetCity = nextInt(inputData, scanPos)
      departureTimes.add departHour * 60 + departMinute
      arrivalTimes.add arriveHour * 60 + arriveMinute
      sourceCities.add cityNumber
      destinationCities.add targetCity
  let trainCount = departureTimes.len
```

Two digit reads build each clock time, so colons need no special handling. Each train stores four integers in flat arrays. Cost: one add per train position.

**Counting sort by departure.**

```nim
  for minuteIndex in 0..<minuteCount: departureCounts[minuteIndex] = 0
  for trainIndex in 0..<trainCount:
    departureCounts[departureTimes[trainIndex]] += 1
  var runningSlot = 0
  var minuteIndex = minuteCount - 1
  while minuteIndex >= 0:
    nextSlot[minuteIndex] = runningSlot
    runningSlot += departureCounts[minuteIndex]
    minuteIndex -= 1
  trainOrder.setLen trainCount
  for trainIndex in 0..<trainCount:
    let departTime = departureTimes[trainIndex]
    trainOrder[nextSlot[departTime]] = trainIndex
    nextSlot[departTime] += 1
```

The minute scan runs from 1439 down to 0, so `trainOrder` starts at the latest departure. Counting sort replaces a comparison sort over up to one million trains. Cost: O(trainCount + 1440).

**Frontier construction.**

```nim
  cityFrontiers.setLen cityCount + 1
  for cityNumber in 0..cityCount: cityFrontiers[cityNumber].setLen 0
  bestArrivalByCity.setLen cityCount + 1
  cityStamp.setLen cityCount + 1

  var orderIndex = 0
  while orderIndex < trainCount:
    let currentDeparture = departureTimes[trainOrder[orderIndex]]
    var groupEnd = orderIndex
    while groupEnd < trainCount and departureTimes[trainOrder[groupEnd]] == currentDeparture:
      groupEnd += 1
    stampValue += 1
    touchedCities.setLen 0
    for scanIndex in orderIndex..<groupEnd:
      let trainIndex = trainOrder[scanIndex]
      let sourceCity = sourceCities[trainIndex]
      if sourceCity == cityCount: continue
      let targetCity = destinationCities[trainIndex]
      let arrivalTime = arrivalTimes[trainIndex]
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
    orderIndex = groupEnd
```

The outer loop visits each departure group once. Trains that share a departure collapse to the smallest arrival per source city. The last-entry test drops dominated pairs. Cost: O(trainCount log 1440).

**Output.**

```nim
  let answerFrontier = cityFrontiers[1]
  appendOutput($(answerFrontier.len))
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
  for frontierIndex in 0..<answerFrontier.len:
    let storedIndex = answerFrontier.len - 1 - frontierIndex
    appendClockTime(answerFrontier[storedIndex].departure)
    outputBuffer.add ' '
    appendClockTime(answerFrontier[storedIndex].arrival)
    outputBuffer.add '\n'
    if outputBuffer.len >= flushBlockBytes:
      stdout.write outputBuffer
      outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
```

Reverse indexing prints increasing departure times. The final write flushes the remaining bytes. Cost: one line per optimal pair.

## Complexity

Costs by phase:

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over input bytes | input string |
| Counting sort | O(trainCount + 1440) | one order array |
| Frontier build | O(trainCount log 1440) | one pair per kept suffix |
| Output | one flush per 256 KiB | 256 KiB buffer |

The frontier build dominates the run, since 1440 stays fixed.

Totals use T for train positions in one case and C for cities.

| Measure | Form |
| --- | --- |
| Time | O(T log 1440) per case |
| Space | O(C + T) per case |

A fresh search from every train costs O(T squared) in the worst case.
