# ROT — Rescue On Time (SPOJ)

<https://www.spoj.com/problems/ROT/>

## Problem

Reach a fixed hostage in a grid whose walls and guards change each minute, while the clock can move one minute forward or back with every step. Report the fewest steps, or a fixed failure message.

Input starts with a test count. Each case gives columns, rows, and the number of minute layers, followed by that many grids. `X` is the start at minute 1, `O` is the hostage, `#` is a wall, `!` is a guard, and `s` is free space. Print the step count, or `Hostage is death, destroy the bunker`.

| item | bound |
|---|---|
| test cases | up to 10 |
| columns and rows | up to 15 each |
| minute layers | up to 10 |
| judge limit | 500 ms, 1536 MB |

The grid-size product times the layer count sets the state space.

Sample input:

```
2
3 3 1
sss
ssX
Oss
3 3 3
Xss      
#s!
s!O
sss
#!s
!sO
ss!
#s!
ssO
```

Sample output:

```
3
4
```

## Idea

Treat each grid square at each minute as a separate room, like stations on a railway with several timetables. A step walks to a neighboring room and picks the next timetable, one minute earlier, later, or the same. Breadth-first search visits rooms in step order, so the first visit to the hostage is the minimum. Trying all time-travel sequences grows exponentially with the layer count.

Room count stays below 2250, so one queue finds the answer quickly.

## Why It Works

1. A state is a square plus a minute layer, so the search holds all relevant history.
2. Each step moves one square and changes the layer by minus one, zero, or plus one.
3. Walls and guards block the destination square in the chosen layer.
4. Every transition costs one step, so breadth-first search gives shortest distances.
5. The hostage sits at one square in every layer, and the first arrival wins.

| term | meaning |
|---|---|
| `layerSize` | squares in one grid |
| `stateCount` | squares times minute layers |
| `distanceByState` | best step count for each state |
| `queueStates` | states waiting in breadth-first order |

Layers stay inside the valid minute range, so no state lies outside the bunker.

The first sample has one layer and a Manhattan distance of three from `X` to `O`.

```
start (row 2, col 3) -> (row 2, col 2) -> (row 2, col 1) -> O
steps: 1 + 1 + 1 = 3
```

The trace matches the first sample answer.

## Code

**Input and tokens.** The reader keeps all input and pulls grid rows as whitespace-delimited tokens.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
```

`nextInt` reads the header numbers.

`nextToken` ignores trailing spaces on grid rows.

**Grid loading.** Every layer is stored in one flat character array.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let columnCount = nextInt(inputData, scanPos)
  let rowCount = nextInt(inputData, scanPos)
  let timeCount = nextInt(inputData, scanPos)
  let layerSize = rowCount * columnCount
  let stateCount = timeCount * layerSize
  var cellChars = newSeq[char](stateCount)
```

The state index packs layer, row, and column into one integer.

The start square and hostage square are recorded during the scan.

**Breadth-first search.** Each popped state tries four squares and three layers.

```nim
  var distanceByState = newSeq[int](stateCount)
  for stateIndex in 0 .. stateCount - 1:
    distanceByState[stateIndex] = -1
  var queueStates = newSeq[int](stateCount)
  var queueHead = 0
  var queueTail = 0
```

Distances start at minus one, meaning unvisited.

The queue never holds more than `stateCount` states.

```nim
      var timeShift = -1
      while timeShift <= 1:
        let neighborLayer = currentLayer + timeShift
        if neighborLayer >= 0 and neighborLayer < timeCount:
          let neighborState = neighborLayer * layerSize + neighborRow * columnCount + neighborColumn
          let neighborChar = cellChars[neighborState]
          if neighborChar != '#' and neighborChar != '!' and distanceByState[neighborState] < 0:
            distanceByState[neighborState] = currentDistance + 1
            queueStates[queueTail] = neighborState
            queueTail += 1
        timeShift += 1
```

Guards and walls reject the destination square.

The first visit fixes the shortest step count.

## Complexity

The search visits each packed state at most once.

| phase | time | space |
|---|---|---|
| input read | one pass over all grid rows | input string |
| grid load | one assignment per square | flat character array |
| search | twelve transitions per state | distance array and queue |

The transition loop dominates the running time.

| measure | Big O |
|---|---|
| time | O(R * C * Time) per case |
| space | O(R * C * Time) per case |

R and C are the grid dimensions, and Time is the layer count.

Enumerating time-travel orders is exponential, while the packed-state search stays linear in the state count.
