# ALIEN2 — Aliens at the train, again! (SPOJ)

<https://www.spoj.com/problems/ALIEN2/>

## Problem

Find the longest prefix of stations the traveler can cross without the total people seen exceeding K, and report the smallest total for that prefix. Switching trains at a station costs the sum of both station counts; staying costs the current train's count.

Input has one case: N and K, then N counts for train A and N counts for train B. Here 1 ≤ N ≤ 10000, 1 ≤ K ≤ 65000, and each count lies from 1 to 100. Output two numbers: the stations passed and the people seen.

| item | bound |
|---|---|
| stations N | 1 to 10000 |
| people limit K | 1 to 65000 |
| people per station | 1 to 100 |
| judge limit | 100 ms, 1536 MB |

The single case makes a linear two-state scan the right shape.

The first sample case has three stations and a limit of ten.

```
3 10
9 2 4
1 2 9
```

```
3 9
```

The traveler crosses all three stations and sees nine people.

## Idea

The trick is to treat each station as a fork with two lanes, like choosing between toll booths where changing lanes costs both tolls. Keep the cheapest total for each lane and carry only those two numbers forward.

The algorithm is a two-state dynamic program over stations. Each station costs four additions and two comparisons, while listing every route would cost two to the N. The last station whose best total stays within K gives both output numbers.

Scan once, then print the last feasible station and its cost.

## Why It Works

1. The cost to reach a station on train A depends only on the two costs at the previous station.
2. Staying on A adds A at the new station; switching from B to A adds A plus B.
3. The symmetric rule gives the cost to reach the station on train B.
4. Every route ends in one of those two states, so their minimum is the least cost for that station count.
5. Station costs are positive, so the least cost grows with the station count, and the last feasible station is the longest prefix.

| term | meaning |
|---|---|
| `trainA` | people counts on train A by station |
| `previousOnA` | least cost to reach the previous station on A |
| `switchCost` | people seen when changing trains at a station |
| `stationBest` | cheaper of the two costs at the current station |
| `bestPeopleSeen` | least cost at the longest feasible prefix |

The two carried costs summarize every route reaching a station.

The generator compares the scan with shortest paths and with route enumeration.

```
station 1: A= 1, B=2 -> best 1
station 2: A= 8, B=4 -> best 4
station 3: A= 7, B=6 -> best 6
station 4: A= 8, B=8 -> best 8
station 5: A= 9, B=10 -> best 9
```

With limit 10, station five is last and its least cost is nine.

## Code

**Input and scan.** The reader loads both train rows, then carries two costs forward.

```nim
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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner ignores the spaces and line breaks in the train rows.

`appendOutput` is present for the shared program shape.

The two rows are stored because switch cost needs both counts.

**Two-state recurrence.** Each station updates the cost for both trains.

```nim
let stationCount = nextInt(inputData, scanPos)
let peopleLimit = nextInt(inputData, scanPos)
var trainA = newSeq[int](stationCount)
for stationIndex in 0 .. stationCount - 1:
  trainA[stationIndex] = nextInt(inputData, scanPos)
var trainB = newSeq[int](stationCount)
for stationIndex in 0 .. stationCount - 1:
  trainB[stationIndex] = nextInt(inputData, scanPos)

var previousOnA = trainA[0]
var previousOnB = trainB[0]
var bestStationCount = 0
var bestPeopleSeen = 0
for stationIndex in 0 .. stationCount - 1:
  var currentOnA = 0
  var currentOnB = 0
  if stationIndex == 0:
    currentOnA = trainA[0]
    currentOnB = trainB[0]
  else:
    let switchCost = trainA[stationIndex] + trainB[stationIndex]
    currentOnA = min(previousOnA + trainA[stationIndex], previousOnB + switchCost)
    currentOnB = min(previousOnB + trainB[stationIndex], previousOnA + switchCost)
  let stationBest = min(currentOnA, currentOnB)
  if stationBest <= peopleLimit:
    bestStationCount = stationIndex + 1
    bestPeopleSeen = stationBest
  previousOnA = currentOnA
  previousOnB = currentOnB

appendOutput($bestStationCount & " " & $bestPeopleSeen)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The first station starts on either train with its own cost.

The switch cost uses both station counts, as the statement requires.

The answer starts at zero so an impossible first station yields no stations and no people.

## Complexity

The scan touches each station once and writes one line.

| phase | time | space |
|---|---|---|
| input read | one pass over 2N counts | two rows of N counts |
| station scan | one update per station | two carried costs |
| output | one line | one output block |

Costs stay small, so plain `int` arithmetic holds every total.

| measure | Big O |
|---|---|
| time | O(N) |
| space | O(N) |

Enumerating all train choices would cost two to the N, so two carried states are the decisive gain.
