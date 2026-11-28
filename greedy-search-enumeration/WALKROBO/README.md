# WALKROBO — Walking Robot (SPOJ)
<https://www.spoj.com/problems/WALKROBO/>

## Problem

A robot walks on a small grid using movements it has learned and learns new movements at marked cells. Find the fewest steps from the bottom-left cell to the top-right cell, or -1 when no route exists.

The first line of each case gives `rowCount`, `columnCount`, `moveCount`, and `knownCount`. Then come `moveCount` movement pairs, one line of `knownCount` known movement numbers, and `rowCount` grid lines of `columnCount` values.

A zero value is free ground and a positive value marks a download for that movement. A line of four zeros ends the input.

Print `Case #X: S` per case.

The table lists the input and judge limits.

| item | bound |
|---|---|
| rows and columns | 2 to 15 |
| movements K | 1 to 12 |
| initial movements T | 0 to K |
| movement offsets | -10 to 10 |
| judge limit | 100 ms, 1536 MB |

The first grid line is the top row, while position (0, 0) is bottom-left.

The sample below is verbatim from the statement.

```
4 3 2 1
1 0
0 1
1
0 0 0
0 0 0
0 0 0
0 0 2
5 5 4 1
2 1
-1 1
-1 0
-1 -2
1
0 4 3 0 0
0 0 0 0 0
0 0 0 0 2
0 0 0 0 0
0 0 0 0 0
5 5 4 1
2 1
-1 1
-1 0
-1 -2
1
4 0 3 0 0
0 0 0 0 0
0 0 0 0 2
0 0 0 0 0
0 0 0 0 0
7 7 3 0
1 1
2 2
4 4
0 0 0 0 0 0 0
0 0 0 0 0 0 0
0 0 0 0 0 0 0
0 0 0 0 0 0 0
0 0 3 0 0 0 0
0 2 0 0 0 0 0
1 0 0 0 0 0 0
```

```
Case #1: 6
Case #2: 11
Case #3: -1
Case #4: 5
```

The first case walks right twice, learns once, then walks up three times.

## Idea

Knowledge becomes a second map coordinate, like unlocking doors while walking through a maze.

The algorithm runs breadth-first search over pairs of a cell and a knowledge mask. Every move or download costs one step, so the first visit to the goal is shortest.

Each state expands at most `moveCount` moves and one download. Trying move orders separately would multiply paths without bound.

The mask folds all those paths into one state.

## Why It Works

1. All moves and downloads cost one step, so breadth-first search gives the minimum.
2. The state keeps both the cell and the set of known movements.
3. A move is legal only when its movement bit is set and its target stays in the grid.
4. A download sets one more bit at the same cell after one step.
5. The first popped goal cell gives the answer with any knowledge mask.

The table names the state parts.

| term | meaning |
|---|---|
| `knowledgeMask` | bit set of learned movements |
| `cellIndex` | linear position in the grid |
| `distances` | step count for each state |
| `initialMask` | movements known at the start |

The state index is `knowledgeMask` times `cellCount` plus `cellIndex`.

In case one, the robot starts at (0, 0) knowing movement 1, which is (1, 0). Two moves reach (2, 0), where a download teaches movement 2, which is (0, 1).

Three more moves reach (2, 3), for 6 steps in total.

Grid line zero is the top row, so the cell at height `row` reads `grid[rowCount - 1 - row]`. This guard keeps the download spot aligned with the bottom-left start.

## Code

**Input and signed scanner.** Movement offsets can be negative, so the scanner keeps a minus branch.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

```

The termination line breaks the case loop. Grid values are read without line assumptions.

The buffer holds case lines.

**State setup.** The case builds movement arrays and the initial bit mask.

```nim
while true:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  let moveCount = nextInt(inputData, scanPos)
  let knownCount = nextInt(inputData, scanPos)
  if rowCount == 0 and columnCount == 0 and moveCount == 0 and knownCount == 0:
    break
  caseNumber += 1
  var moveX = newSeq[int](moveCount)
  var moveY = newSeq[int](moveCount)
  for moveIndex in 0 .. moveCount - 1:
    moveX[moveIndex] = nextInt(inputData, scanPos)
    moveY[moveIndex] = nextInt(inputData, scanPos)
  var initialMask = 0
  for knownIndex in 0 .. knownCount - 1:
    let moveNumber = nextInt(inputData, scanPos)
    initialMask = initialMask or (1 shl (moveNumber - 1))
  var grid = newSeq[seq[int]](rowCount)
  for rowIndex in 0 .. rowCount - 1:
    grid[rowIndex] = newSeq[int](columnCount)
    for columnIndex in 0 .. columnCount - 1:
      grid[rowIndex][columnIndex] = nextInt(inputData, scanPos)
  let cellCount = rowCount * columnCount
  let maskCount = 1 shl moveCount
  var distances = newSeq[int](maskCount * cellCount)
  for stateIndex in 0 .. distances.len - 1:
    distances[stateIndex] = -1
  var queue = newSeq[int](maskCount * cellCount)
  var queueHead = 0
  var queueTail = 0
  let startState = initialMask * cellCount
  distances[startState] = 0
  queue[queueTail] = startState
  queueTail += 1
```

`cellCount` counts grid cells and `maskCount` counts knowledge sets. Distances start at -1 for every state.

The queue begins with the start cell and initial mask.

**Breadth-first search.** Each state expands moves and one possible download.

```nim
  var answer = -1
  while queueHead < queueTail:
    let state = queue[queueHead]
    queueHead += 1
    let knowledgeMask = state div cellCount
    let cellIndex = state mod cellCount
    let row = cellIndex div columnCount
    let column = cellIndex mod columnCount
    let stepsTaken = distances[state]
    if row == rowCount - 1 and column == columnCount - 1:
      answer = stepsTaken
      break
    for moveIndex in 0 .. moveCount - 1:
      if (knowledgeMask and (1 shl moveIndex)) == 0:
        continue
      let nextColumn = column + moveX[moveIndex]
      let nextRow = row + moveY[moveIndex]
      if nextColumn >= 0 and nextColumn < columnCount and nextRow >= 0 and nextRow < rowCount:
        let nextState = knowledgeMask * cellCount + nextRow * columnCount + nextColumn
        if distances[nextState] < 0:
          distances[nextState] = stepsTaken + 1
          queue[queueTail] = nextState
          queueTail += 1
    let downloadSpot = grid[rowCount - 1 - row][column]
    if downloadSpot > 0:
      let moveBit = 1 shl (downloadSpot - 1)
      if (knowledgeMask and moveBit) == 0:
        let nextState = (knowledgeMask or moveBit) * cellCount + cellIndex
        if distances[nextState] < 0:
          distances[nextState] = stepsTaken + 1
          queue[queueTail] = nextState
          queueTail += 1
  appendOutput("Case #" & $caseNumber & ": " & $answer & "\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

Moves stay inside the grid boundary. A download adds a bit without changing the cell.

The first goal state ends the search.

## Complexity

The table shows the work in each phase.

| phase | time | space |
|---|---|---|
| input read | K pairs and M times N cells | one input string |
| state setup | one mask count allocation | M times N times 2 to the K |
| search | K moves per visited state | same distance and queue arrays |
| output | one line per case | block buffer |

K is the movement count and M, N are the grid sizes.

| measure | Big O |
|---|---|
| time | O(M N 2 to the K K) per case |
| space | O(M N 2 to the K) per case |

Trying each order of learned moves would scale with the factorial of K. The mask folds those orders into one visited state.
