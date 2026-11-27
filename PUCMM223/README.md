# PUCMM223 — C You and Me (SPOJ)

<https://www.spoj.com/problems/PUCMM223/>

## Problem

Two pieces start on a grid of at most 20 by 20 cells, one marked a and one marked b. On each move both pieces step to a neighboring cell or stay, and the goal is to exchange their starting cells.

Walls block movement, the pieces may never share a cell, and they may not pass through each other. Each case gives its dimensions and board rows; a line with two zeros ends the input.

Output the fewest moves or the word IMPOSSIBLE for each case.

| item | bound |
|---|---|
| rows and columns | 1 to 20 |
| board symbols | dot, hash, a, b |
| test cases | until a line containing 0 0 |
| judge limit | 1000 ms, 1536 MB |

The joint positions form up to 160000 states, which a breadth-first search can cover.

Sample input:

```
3 4
#..#
a..b
####
3 7
#######
#a...b#
#######
4 4
a...
###.
##..
b...
0 0
```

Sample output:

```
5
IMPOSSIBLE
11
```

## Idea

Treat the two pieces as one traveler, like a pair of dancers moving together. The state is the pair of occupied cells, and one move changes both cells at once. Breadth-first search gives the fewest moves because every step has the same cost.

From each state there are at most 25 next states, minus the illegal ones. A separate search per permutation would miss the rule that both pieces move in the same turn.

Stop as soon as the swapped state is reached.

## Why It Works

1. A state records the cell of piece a and the cell of piece b.
2. Both pieces choose one of five actions: stay, up, down, left, or right.
3. A next state is illegal if a wall is hit or both pieces land on the same cell.
4. Swapping the two current cells in one turn is also illegal, since the pieces would cross.
5. Breadth-first search visits states in increasing move count, so the first goal hit is optimal.
6. A generation marker avoids clearing the visited arrays between cases.

| term | meaning |
|---|---|
| `maxStateCount` | largest possible number of joint states |
| `neighbors` | legal next cells for each board cell and action |
| `seenStates` | case marker for each visited state |
| `stateDistances` | move count at which a state was first reached |
| `goalState` | piece a at the start of b and piece b at the start of a |

Each state is pushed once, so the queue never exceeds the state count.

A script-generated trace of the shortest swap on a 2 by 2 board follows.

| move | piece a | piece b |
|---|---|---|
| 0 | (0,0) | (0,1) |
| 1 | (0,0) | (1,1) |
| 2 | (0,0) | (1,0) |
| 3 | (0,1) | (0,0) |

Three moves are needed, matching the short edge case in the generator.

## Code

**Input, scanning, and buffers.** The reader loads board rows cell by cell and sets up the search arrays.

```nim
const flushBlockBytes = 1 shl 17
const maxCellCount = 400
const maxStateCount = maxCellCount * maxCellCount

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

proc skipToBoard(data: string, pos: var int) =
  while pos < data.len and data[pos] != '.' and data[pos] != '#' and data[pos] != 'a' and data[pos] != 'b':
    pos += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var seenStates = newSeq[int](maxStateCount)
var stateDistances = newSeq[int](maxStateCount)
var queueStates = newSeq[int](maxStateCount)
var caseNumber = 0
```

The board skip stops at the first board symbol after each header.
Three fixed arrays serve every case without reallocation.
The case marker replaces an expensive per-case array clear.

**Board setup.** Each cell gets its five possible destinations after wall checks.

```nim
while true:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  if rowCount == 0 and columnCount == 0:
    break
  caseNumber += 1
  var board = ""
  for rowIndex in 0 .. rowCount - 1:
    skipToBoard(inputData, scanPos)
    for columnIndex in 0 .. columnCount - 1:
      board.add inputData[scanPos]
      scanPos += 1
  let cellCount = rowCount * columnCount
  var startPieceA = -1
  var startPieceB = -1
  for cellIndex in 0 .. cellCount - 1:
    if board[cellIndex] == 'a':
      startPieceA = cellIndex
    elif board[cellIndex] == 'b':
      startPieceB = cellIndex
  var neighbors = newSeq[int](cellCount * 5)
  for cellIndex in 0 .. cellCount - 1:
    let rowIndex = cellIndex div columnCount
    let columnIndex = cellIndex mod columnCount
    for moveIndex in 0 .. 4:
      var neighborRow = rowIndex
      var neighborColumn = columnIndex
      case moveIndex
      of 0:
        discard
      of 1:
        neighborRow -= 1
      of 2:
        neighborRow += 1
      of 3:
        neighborColumn -= 1
      of 4:
        neighborColumn += 1
      else:
        discard
      var neighborIndex = -1
      if neighborRow >= 0 and neighborRow < rowCount and neighborColumn >= 0 and neighborColumn < columnCount:
        let candidateIndex = neighborRow * columnCount + neighborColumn
        if board[candidateIndex] != '#':
          neighborIndex = candidateIndex
      neighbors[cellIndex * 5 + moveIndex] = neighborIndex
```

Positions outside the board or inside walls get a negative marker.
The starting cells are found with one pass over the board string.
The neighbor table is reused for both pieces in every state.

**Breadth-first search and output.** States are dequeued until the swapped goal appears.

```nim
  let goalState = startPieceB * cellCount + startPieceA
  let startState = startPieceA * cellCount + startPieceB
  var queueHead = 0
  var queueTail = 0
  seenStates[startState] = caseNumber
  stateDistances[startState] = 0
  queueStates[queueTail] = startState
  queueTail += 1
  var answerMoves = -1
  while queueHead < queueTail:
    let currentState = queueStates[queueHead]
    queueHead += 1
    if currentState == goalState:
      answerMoves = stateDistances[currentState]
      break
    let pieceA = currentState div cellCount
    let pieceB = currentState mod cellCount
    for moveA in 0 .. 4:
      let nextA = neighbors[pieceA * 5 + moveA]
      if nextA < 0:
        continue
      for moveB in 0 .. 4:
        let nextB = neighbors[pieceB * 5 + moveB]
        if nextB < 0:
          continue
        if nextA == nextB:
          continue
        if nextA == pieceB and nextB == pieceA:
          continue
        let nextState = nextA * cellCount + nextB
        if seenStates[nextState] != caseNumber:
          seenStates[nextState] = caseNumber
          stateDistances[nextState] = stateDistances[currentState] + 1
          queueStates[queueTail] = nextState
          queueTail += 1
  if answerMoves < 0:
    appendOutput("IMPOSSIBLE")
  else:
    appendOutput($answerMoves)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The collision and crossing checks reject illegal next states early.
Each accepted state is enqueued once with its distance.
An empty queue means the goal cannot be reached.

## Complexity

There are at most 400 cells, so at most 160000 joint states.

| phase | time | space |
|---|---|---|
| board setup | five checks per cell | one neighbor table |
| search | 25 transitions per state | state, distance, and queue arrays |
| output | one line per case | block buffer |

The phase table shows that search work dominates each case.

| measure | Big O |
|---|---|
| time | O((M*N)^2) per case |
| space | O((M*N)^2) |

Trying move sequences without memoising states can grow without bound, while this search settles each state once.
