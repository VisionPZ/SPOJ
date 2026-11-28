# REMGAME — Stone Removing Game (SPOJ)

<https://www.spoj.com/problems/REMGAME/>

## Problem

Two players remove consecutive pieces from a 5 by 5 board, and the player forced to take the last piece loses. Decide whether the first player can force a win.

The first integer is the number of test cases. Each case gives five rows of five integers, where 1 marks a piece and 0 an empty cell. Print `winning` if the player to move has a forced win, else `losing`.

| item | bound |
|---|---|
| board size | always 5 by 5 |
| cell values | 0 or 1 |
| judge limit | 100 ms, 1536 MB |

A move selects one row or column and removes a nonempty consecutive run of pieces from it.

Sample input:

```
1 
1 0 0 0 0 
1 1 0 0 0 
1 1 1 0 0 
1 1 1 1 0 
1 1 1 1 1
```

Sample output:

```
winning
```

## Idea

Treat every board as a bit pattern and let a move carve out one contiguous slice. A position wins when some move hands the opponent a losing position; taking the last piece is never a winning move. Memoized recursion stores each visited board once, so repeated lines share work. Enumerating full play trees repeats the same boards many times, while memoization keeps one answer per board.

The table gives the cost of one board.

| item | bound |
|---|---|
| move count | at most 150 per board |
| distinct boards visited | bounded by 2 to the power of 25 |

This cost shape makes memoization essential.

## Why It Works

1. Number the 25 cells from 0 to 24 and store occupied cells as bits of an integer.
2. A legal move removes a nonempty consecutive subsegment of a row run or a column run.
3. Removing the last piece loses, so a move to an empty board is discarded.
4. A board with no legal move is losing for the player to move.
5. A nonempty board wins when at least one move reaches a losing nonempty board.
6. Storing each board result once turns the game tree into a table of 25-bit keys.

The table names the values used in the code.

| term | meaning |
|---|---|
| `stones` | bit mask of occupied cells |
| `runStart` | first cell of a consecutive run |
| `removedMask` | bits removed by one candidate move |
| `remaining` | board after a candidate move |
| `outcomeTable` | cached win or lose mark per board |

Each mark is one byte per visited board.

The worked example uses the sample board, which has 15 pieces. The script finds one winning move.

```
pieces        = 15
winning move  = remove bottom row columns 3, 4 and 5
pieces left   = 12
position left = losing
answer        = winning
```

A board with a single piece is losing because the only move takes that last piece.

## Code

**Scanner, cache, and move generator.** The reader turns each board into a bit mask and the recursion explores row and column segments.

```nim
const flushBlockBytes = 1 shl 17
const boardSize = 5
const cellCount = boardSize * boardSize
const winningMark = 1
const losingMark = 2

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

var outcomeTable = newSeq[int8](1 shl cellCount)

proc positionWins(stones: int): bool =
  if stones == 0:
    return false
  let cached = outcomeTable[stones]
  if cached == winningMark:
    return true
  if cached == losingMark:
    return false
  for rowIndex in 0 .. boardSize - 1:
    var lineIndex = 0
    while lineIndex < boardSize:
      let cellBit = 1 shl (rowIndex * boardSize + lineIndex)
      if (stones and cellBit) == 0:
        lineIndex += 1
      else:
        let runStart = lineIndex
        while lineIndex < boardSize and (stones and (1 shl (rowIndex * boardSize + lineIndex))) != 0:
          lineIndex += 1
        var segmentStart = runStart
        while segmentStart < lineIndex:
          var removedMask = 0
          var segmentEnd = segmentStart
          while segmentEnd < lineIndex:
            removedMask = removedMask or (1 shl (rowIndex * boardSize + segmentEnd))
            let remaining = stones xor removedMask
            if remaining != 0 and not positionWins(remaining):
              outcomeTable[stones] = winningMark
              return true
            segmentEnd += 1
          segmentStart += 1
  for columnIndex in 0 .. boardSize - 1:
    var lineIndex = 0
    while lineIndex < boardSize:
      let cellBit = 1 shl (lineIndex * boardSize + columnIndex)
      if (stones and cellBit) == 0:
        lineIndex += 1
      else:
        let runStart = lineIndex
        while lineIndex < boardSize and (stones and (1 shl (lineIndex * boardSize + columnIndex))) != 0:
          lineIndex += 1
        var segmentStart = runStart
        while segmentStart < lineIndex:
          var removedMask = 0
          var segmentEnd = segmentStart
          while segmentEnd < lineIndex:
            removedMask = removedMask or (1 shl (segmentEnd * boardSize + columnIndex))
            let remaining = stones xor removedMask
            if remaining != 0 and not positionWins(remaining):
              outcomeTable[stones] = winningMark
              return true
            segmentEnd += 1
          segmentStart += 1
  outcomeTable[stones] = losingMark
  return false
```

Rows and columns use the same segment loop with a different bit index. A winning move returns immediately. The losing mark is stored after every move has been checked.

**Case loop and output.** Each case builds its mask and writes one verdict.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  var stones = 0
  for cellIndex in 0 .. cellCount - 1:
    if nextInt(inputData, scanPos) == 1:
      stones = stones or (1 shl cellIndex)
  if positionWins(stones):
    appendOutput("winning")
  else:
    appendOutput("losing")
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The cache is shared across all cases in a run. The verdict strings are buffered with the same writer as other solutions.

## Complexity

The cache holds one byte for each possible board and each visited board generates its legal moves.

| phase | time | space |
|---|---|---|
| input read | one pass over 25 integers per case | one input string |
| recursion | up to 150 moves per visited board | one byte per board |
| output | one line per case | block buffer |

The outcome table is the largest allocation.

| measure | Big O |
|---|---|
| time | O(V * M) for V visited boards and M moves |
| space | O(2^25) bytes for the full table |

Replaying the game tree without a cache repeats the same boards many times; memoization evaluates each board once.
