# BAT4 — BATMAN4 (SPOJ)

<https://www.spoj.com/problems/BAT4/>

## Problem

A flyer crosses a square grid of buildings from the top-left cell to the bottom-right cell. Moves go only right or down, and vertical travel costs one time unit per height unit.

Each case gives the grid size N and time budget M, followed by N rows of N heights. Print `YES : D T` when a route exists, where D is the smallest maximum single climb and T is the time left. Print `NO` when no route leaves time.

| item | bound |
|---|---|
| grid size N | 1 to 20 |
| time budget M | 1 to 100 |
| judge limit | 1000 ms, 1536 MB |

The maximum climb has priority over the remaining time.

Sample input:

```
1
3 40
2 4 3
4 5 3
2 4 6
```

Sample output:

```
YES : 2 32
```

## Idea

Picture a hiker choosing the gentlest steepest step, like picking the easiest rung on a ladder.

A minimax DP finds the smallest possible worst climb to every cell. A second DP marks which total travel times are reachable without exceeding that worst climb. The largest reachable time gives the least time left.

Testing every climb limit and every path costs far more than two grid sweeps.

The two-stage DP keeps climb quality ahead of time.

## Why It Works

1. A right or down move is the only way to advance.
2. A move's travel time is the absolute height difference.
3. A move's climb is the positive height difference.
4. The minimax value of a cell is the smallest worst climb over its routes.
5. A route with worst climb D uses only moves whose climb is at most D.
6. The time DP records reachable arrival times below the budget.
7. The largest reachable time leaves the smallest positive remainder.

| term | meaning |
|---|---|
| `minimumClimbs` | smallest worst climb needed to reach each cell |
| `targetClimb` | worst climb at the destination |
| `reachableTimes` | arrival times possible under that climb |
| `timeBudget` | starting time M |
| `latestArrival` | largest reachable time below the budget |

A flat grid gives zero climb and zero travel time.

A script trace uses the sample grid and budget 40:

```
minimax climb grid  0 2 2
                    2 2 2
                    2 2 2
target climb        2
best route time     2 + 2 + 2 + 2 = 8
time left           40 - 8 = 32
```

The trace reproduces the sample output `YES : 2 32`.

## Code

**Input and minimax sweep.** The reader loads heights and ranks each cell's worst climb.

```nim
const flushBlockBytes = 1 shl 17
const unreachableCost = 1000000000

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

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let gridSize = nextInt(inputData, scanPos)
  let timeBudget = nextInt(inputData, scanPos)
  var buildingHeights = newSeq[seq[int]](gridSize)
  for rowIndex in 0 .. gridSize - 1:
    buildingHeights[rowIndex] = newSeq[int](gridSize)
    for colIndex in 0 .. gridSize - 1:
      buildingHeights[rowIndex][colIndex] = nextInt(inputData, scanPos)
  var minimumClimbs = newSeq[seq[int]](gridSize)
  for rowIndex in 0 .. gridSize - 1:
    minimumClimbs[rowIndex] = newSeq[int](gridSize)
  for rowIndex in 0 .. gridSize - 1:
    for colIndex in 0 .. gridSize - 1:
      if rowIndex == 0 and colIndex == 0:
        minimumClimbs[rowIndex][colIndex] = 0
      else:
        var bestClimb = unreachableCost
        if rowIndex > 0:
          let heightRise = buildingHeights[rowIndex][colIndex] - buildingHeights[rowIndex - 1][colIndex]
          var climbHere = minimumClimbs[rowIndex - 1][colIndex]
          if heightRise > climbHere:
            climbHere = heightRise
          if climbHere < bestClimb:
            bestClimb = climbHere
        if colIndex > 0:
          let heightRise = buildingHeights[rowIndex][colIndex] - buildingHeights[rowIndex][colIndex - 1]
          var climbHere = minimumClimbs[rowIndex][colIndex - 1]
          if heightRise > climbHere:
            climbHere = heightRise
          if climbHere < bestClimb:
            bestClimb = climbHere
        minimumClimbs[rowIndex][colIndex] = bestClimb
  let targetClimb = minimumClimbs[gridSize - 1][gridSize - 1]
```

Each cell reads its upper and left neighbor.
The larger of climb and neighbor value is the local cost.
The smaller of the two neighbor costs wins.

**Reachable-time sweep.** The second pass tracks travel times under the chosen climb.

```nim
  let slotStride = timeBudget
  var reachableTimes = newSeq[bool](gridSize * gridSize * timeBudget)
  for slotIndex in 0 .. reachableTimes.len - 1:
    reachableTimes[slotIndex] = false
  reachableTimes[0] = true
  for rowIndex in 0 .. gridSize - 1:
    for colIndex in 0 .. gridSize - 1:
      for spentTime in 0 .. timeBudget - 1:
        let sourceSlot = (rowIndex * gridSize + colIndex) * slotStride + spentTime
        if not reachableTimes[sourceSlot]:
          continue
        for successor in 0 .. 1:
          var nextRow = rowIndex
          var nextCol = colIndex
          if successor == 0:
            nextRow += 1
          else:
            nextCol += 1
          if nextRow >= gridSize or nextCol >= gridSize:
            continue
          let heightStep = buildingHeights[nextRow][nextCol] - buildingHeights[rowIndex][colIndex]
          if heightStep > targetClimb:
            continue
          var travelCost = heightStep
          if travelCost < 0:
            travelCost = -travelCost
          let nextTime = spentTime + travelCost
          if nextTime < timeBudget:
            let targetSlot = (nextRow * gridSize + nextCol) * slotStride + nextTime
            reachableTimes[targetSlot] = true
  var latestArrival = -1
  for spentTime in 0 .. timeBudget - 1:
    let targetSlot = ((gridSize - 1) * gridSize + gridSize - 1) * slotStride + spentTime
    if reachableTimes[targetSlot]:
      latestArrival = spentTime
  if latestArrival < 0:
    appendOutput("NO")
  else:
    appendOutput("YES : " & $targetClimb & " " & $(timeBudget - latestArrival))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

One flat slot table stores all cell and time pairs.
Moves with a larger climb are rejected.
Only arrival times below the budget are kept.

## Complexity

Both sweeps visit every cell and every allowed time.

| phase | time | space |
|---|---|---|
| input read | one pass over heights | one input string |
| minimax sweep | one pass over cells | N by N values |
| time sweep | M times N by N states | M by N by N flags |

The time table holds at most 40000 flags.

| measure | Big O |
|---|---|
| time per case | O(M * N^2) |
| space per case | O(M * N^2) |

Walking every path would enumerate a binomial number of routes.

The climb-first, time-second DP is the takeaway.
