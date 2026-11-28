# FLING1 — FLING1 (SPOJ)

<https://www.spoj.com/problems/FLING1/>

## Problem

Balls sit on a small grid. A fling sends one ball into another in the same row or column, provided a gap of at least one empty cell separates them. Report whether the board can be reduced to one ball.

| item | bound |
|---|---|
| test cases | 1 to 100 |
| rows and columns | 1 to 10 each |
| balls | about one tenth of the cells |
| judge limit | 5000 ms, 1536 MB |

Input starts with the test count. Each case gives the dimensions, then one row of dots and `B` characters per row. Output is `Yes` or `No` per case.

Sample input:

```
4
5 5
.....
.....
..B..
.....
.B..B
5 4
....
B...
B...
....
B...
3 4
BB..
....
.B..
1 1
B
```

Sample output:

```
Yes
Yes
No
Yes
```

## Idea

Treat a board as a state in a maze and walk every reachable board, like exploring rooms with a map. Each legal fling removes exactly one ball, so the walk always ends after a fixed number of steps. Memoize boards already checked, then report whether some path reaches one ball.

A naive search revisits the same board through different move orders. The hash set turns those repeats into constant-time lookups.

## Why It Works

1. A fling needs a target ball at least two cells away in a straight line.
2. Every ball beyond the flinger in that direction moves one cell toward the flinger.
3. The flinger itself leaves the board, so the ball count drops by exactly one.
4. A board with at most one ball is a solved puzzle.
5. Memoizing failed boards is safe because the ball count fixes the remaining depth.
6. Exhausting all moves without reaching one ball proves the puzzle unsolvable.

| term | meaning |
|---|---|
| `board` | one grid state encoded as cells of `B` or `.` |
| `visitedBoards` | hash set of states already proved unsolvable |
| `hitPositions` | all balls struck by one fling |
| `remainingBalls` | number of balls left before this move |

The table names the values that the search maintains.

A trace from the generator for the first sample case uses a breadth-first search. Rows and columns below start at zero.

```
fling ball (4,4) left: ball (4,1) shifts to (4,2), board = {(2,2),(4,2)}
fling ball (2,2) down: ball (4,2) shifts to (3,2), board = {(3,2)}
one ball remains, so the oracle prints Yes
```

The generated answer matches the sample.

## Code

**Search setup.** The solver uses one hash set of visited boards.

```nim
import sets

const flushBlockBytes = 1 shl 17
const directionCount = 4

var rowCount = 0
var columnCount = 0
var visitedBoards: HashSet[string]
visitedBoards.init()

proc inBounds(rowIndex: int, columnIndex: int): bool =
  return rowIndex >= 0 and rowIndex < rowCount and
         columnIndex >= 0 and columnIndex < columnCount
```

The hash set is initialized once.
Bounds checks use the global dimensions.
No comments appear in the source.

**Upward and leftward flings.** Each branch validates the gap and shifts the targets.

```nim
proc solveBoard(board: var seq[char], remainingBalls: int): bool =
  if remainingBalls <= 1:
    return true
  var boardKey = ""
  for cell in board:
    boardKey.add cell
  if boardKey in visitedBoards:
    return false
  visitedBoards.incl boardKey
  for rowIndex in 0 .. rowCount - 1:
    for columnIndex in 0 .. columnCount - 1:
      let startIndex = rowIndex * columnCount + columnIndex
      if board[startIndex] != 'B':
        continue
      for directionIndex in 0 .. directionCount - 1:
        case directionIndex
        of 0:
          var neighborRow = rowIndex - 1
          var neighborColumn = columnIndex
          if not inBounds(neighborRow, neighborColumn):
            continue
          if board[neighborRow * columnCount + neighborColumn] != '.':
            continue
          var hitPositions = newSeq[int]()
          var scanRow = rowIndex - 2
          var scanColumn = columnIndex
          while inBounds(scanRow, scanColumn):
            if board[scanRow * columnCount + scanColumn] == 'B':
              hitPositions.add scanRow * columnCount + scanColumn
            scanRow -= 1
          if hitPositions.len == 0:
            continue
          var savedBoard = newSeq[char](board.len)
          for cellIndex in 0 .. board.len - 1:
            savedBoard[cellIndex] = board[cellIndex]
          board[startIndex] = '.'
          for hitIndex in hitPositions:
            board[hitIndex] = '.'
            board[hitIndex + columnCount] = 'B'
          if solveBoard(board, remainingBalls - 1):
            return true
          board = savedBoard
```

The first line stops a solved board early.
The scan starts two cells away to enforce the gap.
A fresh copy of the board allows exact backtracking.

**Sideways flings.** Left and right moves shift targets by one column.

```nim
        of 1:
          var neighborRow = rowIndex
          var neighborColumn = columnIndex - 1
          if not inBounds(neighborRow, neighborColumn):
            continue
          if board[neighborRow * columnCount + neighborColumn] != '.':
            continue
          var hitPositions = newSeq[int]()
          var scanRow = rowIndex
          var scanColumn = columnIndex - 2
          while inBounds(scanRow, scanColumn):
            if board[scanRow * columnCount + scanColumn] == 'B':
              hitPositions.add scanRow * columnCount + scanColumn
            scanColumn -= 1
          if hitPositions.len == 0:
            continue
          var savedBoard = newSeq[char](board.len)
          for cellIndex in 0 .. board.len - 1:
            savedBoard[cellIndex] = board[cellIndex]
          board[startIndex] = '.'
          for hitIndex in hitPositions:
            board[hitIndex] = '.'
            board[hitIndex + 1] = 'B'
          if solveBoard(board, remainingBalls - 1):
            return true
          board = savedBoard
        of 2:
          var neighborRow = rowIndex
          var neighborColumn = columnIndex + 1
          if not inBounds(neighborRow, neighborColumn):
            continue
          if board[neighborRow * columnCount + neighborColumn] != '.':
            continue
          var hitPositions = newSeq[int]()
          var scanRow = rowIndex
          var scanColumn = columnIndex + 2
          while inBounds(scanRow, scanColumn):
            if board[scanRow * columnCount + scanColumn] == 'B':
              hitPositions.add scanRow * columnCount + scanColumn
            scanColumn += 1
          if hitPositions.len == 0:
            continue
          var savedBoard = newSeq[char](board.len)
          for cellIndex in 0 .. board.len - 1:
            savedBoard[cellIndex] = board[cellIndex]
          board[startIndex] = '.'
          for hitIndex in hitPositions:
            board[hitIndex] = '.'
            board[hitIndex - 1] = 'B'
          if solveBoard(board, remainingBalls - 1):
            return true
          board = savedBoard
```

An adjacent ball blocks the direction.
The scan collects every ball in the ray.
Backtracking restores all changed cells.

**Downward fling.** The last branch completes the four directions.

```nim
        else:
          var neighborRow = rowIndex + 1
          var neighborColumn = columnIndex
          if not inBounds(neighborRow, neighborColumn):
            continue
          if board[neighborRow * columnCount + neighborColumn] != '.':
            continue
          var hitPositions = newSeq[int]()
          var scanRow = rowIndex + 2
          var scanColumn = columnIndex
          while inBounds(scanRow, scanColumn):
            if board[scanRow * columnCount + scanColumn] == 'B':
              hitPositions.add scanRow * columnCount + scanColumn
            scanRow += 1
          if hitPositions.len == 0:
            continue
          var savedBoard = newSeq[char](board.len)
          for cellIndex in 0 .. board.len - 1:
            savedBoard[cellIndex] = board[cellIndex]
          board[startIndex] = '.'
          for hitIndex in hitPositions:
            board[hitIndex] = '.'
            board[hitIndex - columnCount] = 'B'
          if solveBoard(board, remainingBalls - 1):
            return true
          board = savedBoard
  return false
```

Returning false records no winning path.
The caller memoizes that result immediately.
Each branch uses the same move shape.

**Driver.** The hand reader loads every board and starts one search per case.

```nim
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

proc nextBoardLine(data: string, pos: var int, width: int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var lineText = ""
  while pos < data.len and data[pos] > ' ' and lineText.len < width:
    lineText.add data[pos]
    pos += 1
  return lineText
```

The board reader stops after the stated width.
Dot and ball characters need no integer parsing.
One buffer holds the whole input.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  rowCount = nextInt(inputData, scanPos)
  columnCount = nextInt(inputData, scanPos)
  var board = newSeq[char](rowCount * columnCount)
  var ballCount = 0
  for rowIndex in 0 .. rowCount - 1:
    let boardLine = nextBoardLine(inputData, scanPos, columnCount)
    for columnIndex in 0 .. columnCount - 1:
      let cellIndex = rowIndex * columnCount + columnIndex
      board[cellIndex] = boardLine[columnIndex]
      if board[cellIndex] == 'B':
        ballCount += 1
  visitedBoards.init()
  if solveBoard(board, ballCount):
    appendOutput("Yes")
  else:
    appendOutput("No")
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The visitation set is cleared per case.
Each answer is appended as one line.
A single flush writes all answers.

## Complexity

The search visits each reachable board at most once, and each board offers at most four times the ball count moves.

| phase | time | space |
|---|---|---|
| input read | one pass over board lines | one input string |
| move generation | four directions per ball | one hit list |
| memoization | one hash insert per board | one set of board keys |
| output | one write per block | one output string |

The table shows that memoization bounds repeated work.

| measure | Big O |
|---|---|
| time per case | O(S * B * 4), S reachable states, B balls |
| space per case | O(S * cells) for visited keys |

Trying each move order without memoization repeats whole subtrees, so hashing board states is the practical choice.
