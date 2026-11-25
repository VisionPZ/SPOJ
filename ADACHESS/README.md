# ADACHESS — Ada and Chess (SPOJ)

<https://www.spoj.com/problems/ADACHESS/>

## Problem

Two pieces start on an 8×8 board and move one at a time. Report the smallest total number of moves that puts both pieces on one square, or `INF` when they cannot meet.

Input begins with T, the number of cases. Each case is one line `f x y F X Y`, where f and F are figure types and x, y, X, Y are coordinates from 0 to 7. Type 0 is King, 1 Knight, 2 Queen, 3 Tower, and 4 Bishop.

Output holds one answer per case. Print the move count as a decimal number, or `INF` when no common square exists.

| item | bound |
|---|---|
| test cases T | 1 to 300000 |
| figure types | 0 to 4 |
| coordinates | 0 to 7 |
| judge limit | 3000 ms, 1536 MB |

This table gives every bound needed by the program.

Sample input:

```
5
1 0 0 1 7 7
2 1 3 3 2 5 
0 1 0 4 5 5
3 1 1 4 3 3
0 1 2 0 3 4
```

The sample has five cases with mixed figure types.

Sample output:

```
6
2
2
1
2
```

The five lines match the five cases in order.

## Idea

Add the two shortest walks to a chosen meeting square, like two friends picking a café and comparing travel times. Try all 64 squares and keep the smallest sum.

The program uses breadth-first search on the 64-square move graph. It runs 320 searches, one for each figure type and starting square. Each search visits at most 64 squares, so the tables cost a few million steps. A later case only reads one cell of the answer table. Running two searches per case would repeat the same work 300000 times.

Precompute all piece distances once, then answer each case with a table lookup.

## Why It Works

1. A piece move is one edge in a graph whose nodes are the 64 squares.
2. Breadth-first search gives the fewest moves from a start to every square.
3. The pieces move one at a time, so total moves equal the sum of the two distances.
4. Any meeting plan has some final square, and that square appears among the 64 candidates.
5. Taking the minimum over all candidate squares gives the optimal plan.
6. A square unreachable by one piece gets cost `unreachableCost`, which never wins.

| term | meaning |
|---|---|
| `adjacencyByFigure` | legal destination squares for each figure and square |
| `distanceTable` | fewest moves between a square pair for one figure |
| `answerTable` | best total moves for a pair of figures and starting squares |
| `meetingSquare` | square where both pieces stand at the end |

The tables cover every combination allowed by the input bounds.

For case `3 1 1 4 3 3`, the first piece is a Tower and the second is a Bishop. The script computed these candidate totals:

| meeting square | Tower moves | Bishop moves | total |
|---|---|---|---|
| (1, 1) | 0 | 1 | 1 |
| (2, 2) | 2 | 1 | 3 |
| (3, 3) | 2 | 0 | 2 |

The smallest row gives answer 1, which matches the sample.

The sentinel `unreachableCost` is far above any real distance, so it cannot win a minimum. Two unreachable costs are summed safely in a 32-bit integer.

## Code

**Input and scanning.** The reader loads all text once and the scanner skips whitespace.

```nim
const flushBlockBytes = 1 shl 17
const boardSize = 8
const squareCount = 64
const figureCount = 5
const unreachableCost = 1000000000
const knightRowSteps = [-2, -2, -1, -1, 1, 1, 2, 2]
const knightColSteps = [-1, 1, -2, 2, -2, 2, -1, 1]
const slideRowSteps = [1, -1, 0, 0, 1, 1, -1, -1]
const slideColSteps = [0, 0, 1, -1, 1, -1, 1, -1]

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
```

The offsets describe knight jumps and sliding directions.

Digits are read directly from the input string.

The scanner needs no sign branch because every input value is non-negative.

**Output helper.** One string collects all answers and flushes in blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Large case lists flush after 131072 bytes.

The program emits no partial lines because each newline is appended separately.

**Move generation.** Each figure type gets a destination list for every square.

```nim
proc addNeighbor(neighbors: var seq[int], targetRow: int, targetCol: int) =
  if targetRow >= 0 and targetRow < boardSize and targetCol >= 0 and targetCol < boardSize:
    neighbors.add targetRow * boardSize + targetCol

var adjacencyByFigure: array[figureCount, seq[seq[int]]]
for figureIndex in 0 .. figureCount - 1:
  adjacencyByFigure[figureIndex] = newSeq[seq[int]](squareCount)
  for sourceSquare in 0 .. squareCount - 1:
    var neighbors = newSeq[int](0)
    let sourceRow = sourceSquare div boardSize
    let sourceCol = sourceSquare mod boardSize
    if figureIndex == 0:
      for rowStep in -1 .. 1:
        for colStep in -1 .. 1:
          if rowStep != 0 or colStep != 0:
            addNeighbor(neighbors, sourceRow + rowStep, sourceCol + colStep)
    elif figureIndex == 1:
      for offsetIndex in 0 .. 7:
        addNeighbor(neighbors, sourceRow + knightRowSteps[offsetIndex], sourceCol + knightColSteps[offsetIndex])
    else:
      let firstDirection = if figureIndex == 3: 0 elif figureIndex == 4: 4 else: 0
      let lastDirection = if figureIndex == 3: 3 else: 7
      for directionIndex in firstDirection .. lastDirection:
        var stepLength = 1
        while true:
          let targetRow = sourceRow + stepLength * slideRowSteps[directionIndex]
          let targetCol = sourceCol + stepLength * slideColSteps[directionIndex]
          if targetRow < 0 or targetRow >= boardSize or targetCol < 0 or targetCol >= boardSize:
            break
          neighbors.add targetRow * boardSize + targetCol
          stepLength += 1
    adjacencyByFigure[figureIndex][sourceSquare] = neighbors
```

Kings step one square, knights jump, and the remaining figures slide.

Sliding stops at the board edge, so no destination leaves the board.

**Distance tables.** Breadth-first search fills distances for every figure and start.

```nim
var distanceTable: array[figureCount, array[squareCount, array[squareCount, int]]]
for figureIndex in 0 .. figureCount - 1:
  for sourceSquare in 0 .. squareCount - 1:
    var distances = newSeq[int](squareCount)
    for targetSquare in 0 .. squareCount - 1:
      distances[targetSquare] = unreachableCost
    var queue = newSeq[int](squareCount)
    var queueHead = 0
    var queueTail = 0
    distances[sourceSquare] = 0
    queue[queueTail] = sourceSquare
    queueTail += 1
    while queueHead < queueTail:
      let currentSquare = queue[queueHead]
      queueHead += 1
      for neighborSquare in adjacencyByFigure[figureIndex][currentSquare]:
        if distances[neighborSquare] == unreachableCost:
          distances[neighborSquare] = distances[currentSquare] + 1
          queue[queueTail] = neighborSquare
          queueTail += 1
    for targetSquare in 0 .. squareCount - 1:
      distanceTable[figureIndex][sourceSquare][targetSquare] = distances[targetSquare]
```

Unvisited squares keep the sentinel value after the search ends.

Each queue entry is processed once, so every search is linear in the board size.

**Meeting table.** All candidate squares are tested once per figure pair.

```nim
var answerTable: array[figureCount, array[squareCount, array[figureCount, array[squareCount, int]]]]
for firstFigure in 0 .. figureCount - 1:
  for firstSquare in 0 .. squareCount - 1:
    for secondFigure in 0 .. figureCount - 1:
      for secondSquare in 0 .. squareCount - 1:
        var bestMoves = unreachableCost
        for meetingSquare in 0 .. squareCount - 1:
          let totalMoves = distanceTable[firstFigure][firstSquare][meetingSquare] + distanceTable[secondFigure][secondSquare][meetingSquare]
          if totalMoves < bestMoves:
            bestMoves = totalMoves
        answerTable[firstFigure][firstSquare][secondFigure][secondSquare] = bestMoves
```

There are 320 starts for the first figure and 320 for the second.

The nested loops finish before any case is read.

**Case driver.** Each case maps its coordinates to one table cell.

```nim
let testCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCount - 1:
  let firstFigure = nextInt(inputData, scanPos)
  let firstRow = nextInt(inputData, scanPos)
  let firstCol = nextInt(inputData, scanPos)
  let secondFigure = nextInt(inputData, scanPos)
  let secondRow = nextInt(inputData, scanPos)
  let secondCol = nextInt(inputData, scanPos)
  let bestMoves = answerTable[firstFigure][firstRow * boardSize + firstCol][secondFigure][secondRow * boardSize + secondCol]
  if bestMoves >= unreachableCost:
    appendOutput("INF")
  else:
    appendOutput($bestMoves)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Square indexes use row times eight plus column.

A sentinel result prints `INF`, and the final flush writes all buffered lines.

## Complexity

Table construction runs before input cases, so case handling only reads memory.

| phase | time | space |
|---|---|---|
| move lists | 320 starts times up to 27 moves | 320 destination lists |
| distance tables | 320 searches over 64 squares | 5 times 64 times 64 integers |
| meeting table | 102400 pairs times 64 squares | 102400 integers |
| case handling | one table lookup per case | output buffer |

Each phase above finishes in a fixed number of small steps.

| measure | Big O |
|---|---|
| preprocessing | O(1) |
| per case | O(1) |
| total space | O(1) |

The constants come from the fixed board and the five figure types.

Searching the board twice per case would cost O(64) edges per case instead of one lookup.

Precomputation pays off after a few cases and keeps every later case constant time.
