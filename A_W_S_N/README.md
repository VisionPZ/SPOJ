# A_W_S_N — Happy Valentine Day (Valentine Maze Game) (SPOJ)

<https://www.spoj.com/problems/A_W_S_N/>

## Problem

Walk through a maze from `T` to `W`, collecting every `C` on the way. Each step to a side neighbor costs one unit of time, and walls cannot be crossed. Report the minimum time, or `Mission Failed!` when no route collects all chocolates.

Input starts with T, the number of test cases. Each case gives m and n, then m lines of n characters. The characters are `#` for wall, `.` for road, `C` for chocolate, `T` for the start, and `W` for the goal.

| item | bound |
|---|---|
| test cases T | up to 30 |
| rows m and columns n | 1 < m, n <= 100 |
| chocolates per map | fewer than 10 |
| judge limit | 1000 ms, 1536 MB |

`T` and `W` each appear once, and chocolates appear at most nine times.

Sample input:

```
8
3 3
T..
...
..W
3 6
######
#T..W#
######
3 6
######
#T#.W#
######
3 6
##C###
#T..W#
######
3 6
C#C###
.T..W#
######
5 10
##########
#T.#.C#..#
#..#..#..#
#..W..#..#
##########
5 10
##########
#T.#.C#.C#
#..#..#..#
#..W..#..#
##########
5 10
##########
#C.#.C#.C#
#..#..#..#
#..T..W..#
##########
```

Sample output:

```
4
3
Mission Failed!
5
9
12
Mission Failed!
23
```

## Idea

Collecting every chocolate is like visiting a list of shops before going home, like a delivery route with a handful of stops. Measure walking times between the important cells once, then try every visit order with a bitmask.

A breadth-first search from each important cell gives exact walking times across walls. The bitmask dynamic program keeps the cheapest route for each set of collected chocolates and last stop. Enumerating all walks through the maze repeats work and grows quickly with map size.

One set of searches plus a small route table answers each case.

## Why It Works

1. A breadth-first search gives the shortest wall-free walk between any two cells.
2. Only the start, the goal, and the chocolates need their own search.
3. Any valid route visits chocolates in some order, so trying every order covers the optimum.
4. A bitmask records which chocolates are already collected.
5. The dynamic program adds the walking time from the last chocolate to the next one.
6. An unreachable pair gets cost -1 and is never used.

| term | meaning |
|---|---|
| `distanceTable` | walking times from each important cell to all cells |
| `chocolateIndices` | flat cell positions holding chocolates |
| `bestCosts` | cheapest route for each mask and last chocolate |
| `fullMask` | mask with every chocolate collected |
| `unreachableCost` | large sentinel for an impossible route state |

A worked trace from the fourth sample case:

| leg | walk length |
|---|---|
| start to chocolate | 2 |
| chocolate to goal | 3 |
| total | 5 |

The total matches the fourth sample answer.

## Code

**Input and searches.** The reader parses the map and measures walks from every important cell.

```nim
const flushBlockBytes = 1 shl 17
const unreachableCost = 1 shl 28

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

proc nextGridCell(data: string, pos: var int): char =
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\n' or data[pos] == '\r' or data[pos] == '\t'):
    pos += 1
  let cellChar = data[pos]
  pos += 1
  return cellChar

proc bfsDistances(grid: seq[char], rowCount, columnCount, startIndex: int): seq[int] =
  result = newSeq[int](rowCount * columnCount)
  for cellIndex in 0 .. rowCount * columnCount - 1:
    result[cellIndex] = -1
  var queue = newSeq[int](rowCount * columnCount)
  var headIndex = 0
  var tailIndex = 0
  result[startIndex] = 0
  queue[tailIndex] = startIndex
  tailIndex += 1
  while headIndex < tailIndex:
    let currentIndex = queue[headIndex]
    headIndex += 1
    let currentRow = currentIndex div columnCount
    let currentColumn = currentIndex mod columnCount
    for deltaRow in -1 .. 1:
      for deltaColumn in -1 .. 1:
        if (deltaRow == 0 and deltaColumn == 0) or (deltaRow != 0 and deltaColumn != 0):
          continue
        let neighborRow = currentRow + deltaRow
        let neighborColumn = currentColumn + deltaColumn
        if neighborRow >= 0 and neighborRow < rowCount and neighborColumn >= 0 and neighborColumn < columnCount:
          let neighborIndex = neighborRow * columnCount + neighborColumn
          if grid[neighborIndex] != '#' and result[neighborIndex] == -1:
            result[neighborIndex] = result[currentIndex] + 1
            queue[tailIndex] = neighborIndex
            tailIndex += 1
  return result
```

The grid reader skips whitespace between characters.
Each search visits every walkable cell once.
A wall cell never enters the queue.

**Map parsing.** One pass finds the start, goal, and chocolates, then builds the distance table.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCount - 1:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  var grid = newSeq[char](rowCount * columnCount)
  var startIndex = -1
  var destinationIndex = -1
  var chocolateIndices = newSeq[int]()
  for cellIndex in 0 .. rowCount * columnCount - 1:
    let cellChar = nextGridCell(inputData, scanPos)
    grid[cellIndex] = cellChar
    if cellChar == 'T':
      startIndex = cellIndex
    elif cellChar == 'W':
      destinationIndex = cellIndex
    elif cellChar == 'C':
      chocolateIndices.add cellIndex
  var importantIndices = newSeq[int]()
  importantIndices.add startIndex
  for chocolateIndex in chocolateIndices:
    importantIndices.add chocolateIndex
  importantIndices.add destinationIndex
  let importantCount = importantIndices.len
  var distanceTable = newSeq[seq[int]]()
  for pointIndex in 0 .. importantCount - 1:
    distanceTable.add bfsDistances(grid, rowCount, columnCount, importantIndices[pointIndex])
```

Flat cell indexes use row times columns plus column.
The start, goal, and chocolates form the important list.
Each row of the table belongs to one important cell.

**Route table.** The bitmask dynamic program chooses the cheapest visit order.

```nim
  let chocolateCount = chocolateIndices.len
  var answer = 0
  var possible = true
  if chocolateCount == 0:
    answer = distanceTable[0][destinationIndex]
    if answer < 0:
      possible = false
  else:
    let maskLimit = 1 shl chocolateCount
    let fullMask = maskLimit - 1
    var bestCosts = newSeq[int](maskLimit * chocolateCount)
    for costIndex in 0 .. bestCosts.len - 1:
      bestCosts[costIndex] = unreachableCost
    for chocolateSlot in 0 .. chocolateCount - 1:
      let chocolateIndex = chocolateIndices[chocolateSlot]
      let directDistance = distanceTable[0][chocolateIndex]
      if directDistance >= 0:
        bestCosts[(1 shl chocolateSlot) * chocolateCount + chocolateSlot] = directDistance
    for mask in 0 .. fullMask:
      for fromSlot in 0 .. chocolateCount - 1:
        let currentCost = bestCosts[mask * chocolateCount + fromSlot]
        if currentCost >= unreachableCost:
          continue
        if (mask and (1 shl fromSlot)) == 0:
          continue
        for toSlot in 0 .. chocolateCount - 1:
          if (mask and (1 shl toSlot)) != 0:
            continue
          let toChocolate = chocolateIndices[toSlot]
          let stepDistance = distanceTable[fromSlot + 1][toChocolate]
          if stepDistance < 0:
            continue
          let nextMask = mask or (1 shl toSlot)
          let candidateCost = currentCost + stepDistance
          let nextIndex = nextMask * chocolateCount + toSlot
          if candidateCost < bestCosts[nextIndex]:
            bestCosts[nextIndex] = candidateCost
    var bestTotal = unreachableCost
    for lastSlot in 0 .. chocolateCount - 1:
      let finalCost = bestCosts[fullMask * chocolateCount + lastSlot]
      if finalCost >= unreachableCost:
        continue
      let toDestination = distanceTable[lastSlot + 1][destinationIndex]
      if toDestination < 0:
        continue
      let totalCost = finalCost + toDestination
      if totalCost < bestTotal:
        bestTotal = totalCost
    if bestTotal >= unreachableCost:
      possible = false
    else:
      answer = bestTotal
  if possible:
    appendOutput($answer)
  else:
    appendOutput("Mission Failed!")
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The initial state starts at the first chocolate reached from `T`.
Unreachable legs never enter the table.
The final leg runs from the last chocolate to `W`.

## Complexity

Searches and the route table run once per test case.

| phase | time | space |
|---|---|---|
| input read | one pass over map characters | one input string |
| breadth-first searches | one per important cell | one distance row per cell |
| route table | one transition per mask and pair | masks times chocolates |
| output | one line per case | block buffer |

The breadth-first searches dominate the runtime.

| measure | Big O |
|---|---|
| time | O((c + 2) times m n plus 2 to the c times c squared) |
| space | O((c + 2) times m n) |

Re-solving the maze for every visit order would cost far more than one table.
The shared distance rows keep small chocolate counts inexpensive.
