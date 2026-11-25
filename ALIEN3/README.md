# ALIEN3 — Aliens at the subway (SPOJ)
<https://www.spoj.com/problems/ALIEN3/>

## Problem

Find the fewest station moves from station 0 to station L, using at most one trip per teleporter and at most T moves. Each walk step moves one station forward; each teleporter jumps by its signed value.

Input starts with the case count. Each case gives N and K, then K teleporter values, then L and T. Stations run from 0 to N. Print `Scenario #i: R`, where R is the minimum move count or -1 when L is unreachable within T moves.

| Constraint | Value |
| --- | --- |
| Cases | 1 to 50 |
| Stations N | 1 to 100 |
| Teleporters K | 1 to 17 |
| Teleporter value | -100 to 100 |
| Destination L | 0 to N |
| Move limit T | 1 to 50 |
| Judge time | 600 ms |
| Judge memory | 1536 MB |

The sample input and its expected output follow byte for byte.

```
4
12 6
1 3 4 1 2 -2
10 10
12 6
1 3 2 1 2 -2
10 10
10 2
6 -2
5 10
10 2
1 1
10 5
```

```
Scenario #1: 4
Scenario #2: 6
Scenario #3: 3
Scenario #4: -1
```

## Idea

Remember which teleporters are spent and the lowest cost at each station, like tracking both your remaining tickets and your current stop.

The program uses a subset dynamic program over teleporter masks. For each mask it keeps the fewest moves to arrive at every station by teleport. Walking is handled with a prefix minimum: from station a you can walk to any larger station at extra cost. Each unused teleporter then jumps from every reachable station to a new station. A plain search over walks and ticket orders repeats work. Subset states collapse those repeats. Track masks, fold in walking, then jump.

## Why It Works

1. A mask records exactly which teleporters have been used.
2. Walking only moves forward, so the best cost to reach station s equals s plus the minimum of arrival cost minus arrival station over stations at most s.
3. The prefix scan `adjustedCosts` computes that minimum in one pass per mask.
4. A teleporter with shift v moves from station s to station s+v, when that station stays inside the subway.
5. Processing masks by increasing value works because setting another bit always raises the mask number.

| Term | Meaning |
| --- | --- |
| `visitCosts` | fewest moves to arrive at a station with a given mask |
| `adjustedCosts` | arrival cost minus station number, folded as a prefix minimum |
| `usedMask` | bit set of teleporters already spent |
| `bestAnswer` | smallest move count found for the destination |

A script-generated check uses N of 10, teleporters 6 and -2, and destination 5. Starting at station 0, the first jump lands on station 6 in one move. The second jump lands on station 4 in two moves. One walk reaches station 5 in three moves, which is the answer.

## Code

**Input and scanner.** The reader loads all lines and parses signed values by hand.

```nim
const flushBlockBytes = 1 shl 17
const unreachableCost = 1000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value
```

Negative teleporter values parse through the sign branch.
Each call consumes one integer.
Line breaks do not affect parsing.

**Output writer.** One buffer collects every scenario line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes at a fixed size.
The final flush writes any remaining text.
No write happens per station.

**Subset solver.** Each mask folds walking costs, tests the destination, then spends each unused teleporter.

```nim
let caseTotal = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseTotal - 1:
  let stationCount = nextInt(inputData, scanPos)
  let teleporterCount = nextInt(inputData, scanPos)
  var teleporterValues = newSeq[int](teleporterCount)
  var teleporterIndex = 0
  while teleporterIndex < teleporterCount:
    teleporterValues[teleporterIndex] = nextInt(inputData, scanPos)
    teleporterIndex += 1
  let destination = nextInt(inputData, scanPos)
  let visitLimit = nextInt(inputData, scanPos)
  let maskCount = 1 shl teleporterCount
  let stationTotal = stationCount + 1
  var visitCosts = newSeq[int16](maskCount * stationTotal)
  var cellIndex = 0
  while cellIndex < visitCosts.len:
    visitCosts[cellIndex] = int16(unreachableCost)
    cellIndex += 1
  visitCosts[0] = 0
  var adjustedCosts = newSeq[int](stationTotal)
  var bestAnswer = unreachableCost
  var usedMask = 0
  while usedMask < maskCount:
    var bestAdjusted = unreachableCost
    var stationIndex = 0
    while stationIndex < stationTotal:
      let storedCost = int(visitCosts[usedMask * stationTotal + stationIndex])
      if storedCost < unreachableCost:
        let adjustedCost = storedCost - stationIndex
        if adjustedCost < bestAdjusted:
          bestAdjusted = adjustedCost
      adjustedCosts[stationIndex] = bestAdjusted
      stationIndex += 1
    if bestAdjusted < unreachableCost div 2:
      let walkingAnswer = destination + adjustedCosts[destination]
      if walkingAnswer <= visitLimit and walkingAnswer < bestAnswer:
        bestAnswer = walkingAnswer
      teleporterIndex = 0
      while teleporterIndex < teleporterCount:
        if (usedMask and (1 shl teleporterIndex)) == 0:
          let nextMask = usedMask or (1 shl teleporterIndex)
          let teleporterShift = teleporterValues[teleporterIndex]
          stationIndex = 0
          while stationIndex < stationTotal:
            let adjustedCost = adjustedCosts[stationIndex]
            if adjustedCost < unreachableCost div 2:
              let arrivalCost = stationIndex + adjustedCost + 1
              if arrivalCost <= visitLimit:
                let landingStation = stationIndex + teleporterShift
                if landingStation >= 0 and landingStation <= stationCount:
                  let targetCell = nextMask * stationTotal + landingStation
                  if arrivalCost < int(visitCosts[targetCell]):
                    visitCosts[targetCell] = int16(arrivalCost)
            stationIndex += 1
        teleporterIndex += 1
    usedMask += 1
  var answer = -1
  if bestAnswer <= visitLimit:
    answer = bestAnswer
  appendOutput("Scenario #" & $(caseIndex + 1) & ": " & $answer & "\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

Costs above the move limit are discarded early.
Landings outside the subway are ignored.
The destination check includes walking after the last teleport.

## Complexity

Each mask scans all stations once, then tries every unused teleporter at every station.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over K values | one input string |
| Prefix fold | O(N) per mask | N adjusted costs |
| Teleporter jumps | O(K N) per mask | mask by station table |
| Output | one line per case | one output buffer |

| Measure | Big O |
| --- | --- |
| Time per case | O(2 to the K times K times N) |
| Space | O(2 to the K times N) |

Trying every order of walking and teleporters would multiply work by K factorial.

Subset states collapse all ticket orders, and the prefix fold handles all walking in one pass.
