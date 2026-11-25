# KROW — K-In-A-Row (SPOJ)

<https://www.spoj.com/problems/KROW/>

## Problem

Read the final boards of several K-in-a-row games and count how many Hansel and Gretel each won. A win means K equal marks in a horizontal, vertical, or diagonal line of adjacent cells.

| item | bound |
|---|---|
| games L | given by the first integer |
| grid size M and N | both below 200 |
| required length K | given per game |
| judge limit | 500 ms, 1536 MB |

The input board is the position right after the game stopped. At most one player has a winning line.

Sample input:

```
2
3 3 3
.x.
.xo
oox
4 7 4
....
..x.
ooox
oxx.
oox.
o.ox
..xx
```

Sample output:

```
0:1
```

## Idea

Read each direction like a strip of tape and start counting only where a matching mark begins. The maximal-run scan walks each same-mark strip once in every one of the four directions. A run of length K or more decides that game. Checking every possible K-length window instead would revisit the same cells many times.

## Why It Works

1. Every legal line lies inside one maximal run of equal marks.
2. A maximal run starts where the previous cell differs or lies outside the grid.
3. The four step pairs cover horizontal, vertical, and both diagonal directions.
4. A run of length at least K proves a win for its mark.
5. A game with no such run has no winner.

The names below match the source identifiers.

| term | meaning |
|---|---|
| `board` | the rows of marks read from the input |
| `runLength` | count of equal adjacent marks in one direction |
| `winnerMark` | the mark that completed a winning run |
| `requiredLength` | the value K for the current game |

This table skips windows that cannot start a new run.

The winning run in the second sample game, produced by the oracle in gen.py:

| row | column 0 | column 1 | column 2 | column 3 |
|---|---|---|---|---|
| 2 | o | o | o | x |
| 3 | o | x | x | . |
| 4 | o | o | x | . |
| 5 | o | . | o | x |

Column 0 holds four circles from row 2 down to row 5, so Gretel wins that game.

## Code

**Input helpers.** The reader loads all lines and extracts numbers and board rows.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const directionCount = 4
const rowStepValues = [0, 1, 1, 1]
const columnStepValues = [1, 0, 1, -1]

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\n' or data[pos] == '\r' or data[pos] == '\t'):
    pos += 1
  let firstCharPos = pos
  while pos < data.len and data[pos] != ' ' and data[pos] != '\n' and data[pos] != '\r' and data[pos] != '\t':
    pos += 1
  return data[firstCharPos ..< pos]
```

The step arrays encode the four legal directions.
Board rows are read as whitespace-delimited tokens.
Both scanners advance a single position through the input string.

**Run scan and totals.** Each game contributes at most one win.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let gameCount = nextInt(inputData, scanPos)
var hanselWins = 0
var gretelWins = 0
for gameIndex in 0 ..< gameCount:
  let columnCount = nextInt(inputData, scanPos)
  let rowCount = nextInt(inputData, scanPos)
  let requiredLength = nextInt(inputData, scanPos)
  var board = newSeq[string](rowCount)
  for rowIndex in 0 ..< rowCount:
    board[rowIndex] = nextWord(inputData, scanPos)
  var winnerMark = '.'
  for rowIndex in 0 ..< rowCount:
    for columnIndex in 0 ..< columnCount:
      let markChar = board[rowIndex][columnIndex]
      if markChar == '.':
        continue
      for directionIndex in 0 ..< directionCount:
        let rowStep = rowStepValues[directionIndex]
        let columnStep = columnStepValues[directionIndex]
        let previousRow = rowIndex - rowStep
        let previousColumn = columnIndex - columnStep
        if previousRow >= 0 and previousRow < rowCount and previousColumn >= 0 and previousColumn < columnCount and board[previousRow][previousColumn] == markChar:
          continue
        var runLength = 0
        var scanRow = rowIndex
        var scanColumn = columnIndex
        while scanRow >= 0 and scanRow < rowCount and scanColumn >= 0 and scanColumn < columnCount and board[scanRow][scanColumn] == markChar:
          runLength += 1
          scanRow += rowStep
          scanColumn += columnStep
        if runLength >= requiredLength:
          winnerMark = markChar
  if winnerMark == 'x':
    hanselWins += 1
  elif winnerMark == 'o':
    gretelWins += 1
appendOutput($hanselWins & ":" & $gretelWins)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The previous-cell test starts each run exactly once.
Empty cells never start a run.
One colon-separated pair is written for all games.

## Complexity

Let R and C be the grid dimensions of one game.

| phase | time | space |
|---|---|---|
| board read | one token per row | one string per row |
| run scan | four passes over the grid | a few counters |
| output | one append for all games | one block buffer |

Each cell joins one run per direction, so the scan stays linear.

| measure | Big O |
|---|---|
| time per game | O(R * C) |
| space per game | O(R * C) |

Testing every K-length window would cost O(R * C * K), while maximal runs finish in one pass.
