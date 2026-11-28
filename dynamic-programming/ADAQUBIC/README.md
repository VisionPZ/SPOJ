# ADAQUBIC — Ada and TicTacToe (SPOJ)

<https://www.spoj.com/problems/ADAQUBIC/>

## Problem

Given an unfinished, valid 3×3×3 tic-tac-toe board where Ada plays `x` and started first, determine who wins when both players play optimally. Think of a referee checking every possible continuation of the game and picking the stronger player.

| item | bound |
|---|---|
| test cases T | 1 to 1000 |
| board | 9 lines of 3 characters per case |
| marks | `.` empty, `x` Ada, `o` Vinit |
| judge limit | 2000 ms, 1536 MB |

A blank line precedes each test case. The first three rows are the top layer, the next three the middle layer, and the last three the bottom layer.

Sample input:

```
7

..o
o.x
xox
x.x
...
x.o
...
o.o
.x.

.x.
...
..o
o.x
x..
..o
..x
...
...

o..
...
o.x
.x.
...
.x.
o.o
.xx
oox

..x
..x
.o.
..x
..x
xo.
o..
..o
...

...
..x
..x
.o.
..x
o..
...
...
x.o

...
..x
..o
...
...
xo.
ox.
...
.ox

o..
x..
...
oxx
..o
.ox
..o
.x.
.x.
```

Sample output:

```
Vinit
Vinit
Ada
Vinit
Ada
Vinit
Vinit
```

## Idea

Maximise the current player's outcome by exploring moves, like a chess engine looking ahead, but stop as soon as a win or forced loss is visible. Minimax with alpha-beta pruning and a transposition table searches only relevant continuations. At each node, a single pass over the 49 winning lines finds immediate wins and crossing threats. Plain minimax revisits the same board thousands of times through different move orders. The takeaway is that threat detection plus caching turns a huge game tree into a short search.

## Why It Works

1. The cube has 27 cells and exactly 49 winning triples.
2. Equal mark counts mean Ada moves next; one extra `x` means Vinit moves next.
3. A line with two of the mover's marks and one empty cell is an immediate win.
4. Two different threat cells for the opponent cannot both be blocked by one move.
5. Negamax returns 1 for a win, 0 for a draw, and -1 for a loss for the player to move.
6. Alpha-beta bounds and a transposition table reuse results across move orders.

| term | meaning |
|---|---|
| `crossMask` | bit mask of Ada's marks |
| `circleMask` | bit mask of Vinit's marks |
| `winningLines` | all 49 three-cell lines |
| `winningCells` | empty cells that finish a line for the mover |
| `blockingCells` | empty cells that stop an opponent's immediate win |
| `transpositionKeys` | cached state keys in a direct-mapped table |

The worked example uses the boards printed in the statement and counts from the generator's independent coordinate-board oracle.

| board | mark counts | player to move | visible threats | result |
|---|---|---|---|---|
| example 2 | x = 11, o = 11 | Ada | five immediate winning cells | Ada |
| sample case 5 | x = 4, o = 3 | Vinit | no immediate win | Ada |
| sample case 6 | x = 4, o = 4 | Ada | two crossing threats | Vinit |

In example 2, playing cell (0,1,1) completes the diagonal (0,0,0), (0,1,1), (0,2,2). The search records a win without exploring further.

The cache stores exact values and bound flags, so narrow alpha-beta windows stay correct. Draws are handled with score 0 even though optimal play in this variant rarely reaches one.

## Code

**Lines and cache.** The program builds all winning triples, orders cells by line count, and reserves the transposition table.

```nim
const flushBlockBytes = 1 shl 17
const cellCount = 27
const tableBits = 24
const tableSize = 1 shl tableBits
const tableMask = tableSize - 1
const shiftPerMask = 27

proc cellIndex(firstCoord, secondCoord, thirdCoord: int): int =
  return firstCoord * 9 + secondCoord * 3 + thirdCoord

var winningLines = newSeq[int64]()
var linesThroughCell = newSeq[seq[int64]](cellCount)
```

Axis lines, face diagonals, and space diagonals fill the list.
Each cell remembers the lines that pass through it.
The insertion sort puts high-degree cells first.

```nim
var moveOrder = newSeq[int]()
for cellNumber in 0 .. cellCount - 1:
  moveOrder.add cellNumber
var orderIndex = 1
while orderIndex < moveOrder.len:
  let heldCell = moveOrder[orderIndex]
  let heldPriority = linesThroughCell[heldCell].len
  var compareIndex = orderIndex - 1
  while compareIndex >= 0 and linesThroughCell[moveOrder[compareIndex]].len < heldPriority:
    moveOrder[compareIndex + 1] = moveOrder[compareIndex]
    compareIndex -= 1
  moveOrder[compareIndex + 1] = heldCell
  orderIndex += 1

var transpositionKeys = newSeq[int64](tableSize)
var transpositionValues = newSeq[int8](tableSize)
var transpositionFlags = newSeq[int8](tableSize)
```

The table packs both mark masks into one key.
Each slot stores a value and a bound flag.

**Search.** The search detects immediate wins, forced blocks, and then recurses with alpha-beta.

```nim
proc searchPosition(crossMask: int64, circleMask: int64, crossToMove: bool, alphaInput, betaInput: int): int =
  let stateKey = crossMask or (circleMask shl shiftPerMask)
  let slotIndex = int(stateKey and int64(tableMask))
  let storedKey = transpositionKeys[slotIndex]
  if storedKey != 0:
    if storedKey == stateKey + 1:
      let storedValue = int(transpositionValues[slotIndex]) - 1
      let storedFlag = transpositionFlags[slotIndex]
      if storedFlag == 0:
        return storedValue
      if storedFlag == 1 and storedValue >= betaInput:
        return storedValue
      if storedFlag == 2 and storedValue <= alphaInput:
        return storedValue
  var alphaValue = alphaInput
  var betaValue = betaInput
  var bestScore = -2
  let occupiedMask = crossMask or circleMask
  let moverMask = if crossToMove: crossMask else: circleMask
  let rivalMask = if crossToMove: circleMask else: crossMask
  var winningCells = 0'i64
  var blockingCells = 0'i64
  for lineMask in winningLines:
    let ownMissing = lineMask and not moverMask
    if ownMissing != 0 and (ownMissing and (ownMissing - 1)) == 0 and (lineMask and not occupiedMask) != 0:
      winningCells = winningCells or (lineMask and not occupiedMask)
    let rivalMissing = lineMask and not rivalMask
    if rivalMissing != 0 and (rivalMissing and (rivalMissing - 1)) == 0 and (lineMask and not occupiedMask) != 0:
      blockingCells = blockingCells or (lineMask and not occupiedMask)
```

One bit scan classifies every empty cell as a win or a forced block.
Two distinct blocks mean the position is already lost.

```nim
  if winningCells != 0:
    bestScore = 1
  elif blockingCells != 0 and (blockingCells and (blockingCells - 1)) != 0:
    bestScore = -1
  else:
    for cellNumber in moveOrder:
      let cellBit = 1'i64 shl cellNumber
      if (occupiedMask and cellBit) != 0 or (blockingCells and cellBit) == 0:
        continue
      let nextCrossMask = crossMask or (if crossToMove: cellBit else: 0'i64)
      let nextCircleMask = circleMask or (if crossToMove: 0'i64 else: cellBit)
      let moveScore = -searchPosition(nextCrossMask, nextCircleMask, not crossToMove, -betaValue, -alphaValue)
      if moveScore > bestScore:
        bestScore = moveScore
      if bestScore > alphaValue:
        alphaValue = bestScore
      if alphaValue >= betaValue:
        break
    if blockingCells == 0:
      for cellNumber in moveOrder:
        let cellBit = 1'i64 shl cellNumber
        if (occupiedMask and cellBit) != 0:
          continue
        let nextCrossMask = crossMask or (if crossToMove: cellBit else: 0'i64)
        let nextCircleMask = circleMask or (if crossToMove: 0'i64 else: cellBit)
        let moverAfterMove = if crossToMove: nextCrossMask else: nextCircleMask
        var createsLine = false
        for lineMask in linesThroughCell[cellNumber]:
          if (moverAfterMove and lineMask) == lineMask:
            createsLine = true
            break
        let moveScore = if createsLine: 1 else: -searchPosition(nextCrossMask, nextCircleMask, not crossToMove, -betaValue, -alphaValue)
        if moveScore > bestScore:
          bestScore = moveScore
        if bestScore > alphaValue:
          alphaValue = bestScore
        if alphaValue >= betaValue:
          break
```

A single block is tried before every other move.
With no block, moves follow static cell priority.
The negamax call flips the score and the player.

```nim
  if bestScore == -2:
    bestScore = 0
  var storedFlag = 0'i8
  if bestScore <= alphaInput:
    storedFlag = 2
  elif bestScore >= betaInput:
    storedFlag = 1
  transpositionKeys[slotIndex] = stateKey + 1
  transpositionValues[slotIndex] = int8(bestScore + 1)
  transpositionFlags[slotIndex] = storedFlag
  return bestScore
```

An empty move list produces the draw score.
The flag records whether the stored value is exact or a bound.

**Driver.** The reader skips blank lines and converts marks into two bit masks.

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

proc nextBoardChar(data: string, pos: var int): char =
  while pos < data.len and data[pos] != 'x' and data[pos] != 'o' and data[pos] != '.':
    pos += 1
  result = data[pos]
  pos += 1
```

The character scanner ignores all whitespace.
One call consumes one board cell.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Answers accumulate in one buffer.
Large batches flush during the loop.

```nim
let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  var crossMask = 0'i64
  var circleMask = 0'i64
  var crossCount = 0
  var circleCount = 0
  for cellNumber in 0 .. cellCount - 1:
    let boardChar = nextBoardChar(inputData, scanPos)
    if boardChar == 'x':
      crossMask = crossMask or (1'i64 shl cellNumber)
      crossCount += 1
    elif boardChar == 'o':
      circleMask = circleMask or (1'i64 shl cellNumber)
      circleCount += 1
  let crossToMove = crossCount == circleCount
  var adaWins = false
  if crossMask == 0 and circleMask == 0:
    adaWins = true
  else:
    let outcome = searchPosition(crossMask, circleMask, crossToMove, -2, 2)
    if outcome == 0:
      adaWins = true
    elif outcome == 1:
      adaWins = crossToMove
    else:
      adaWins = not crossToMove
  if adaWins:
    appendOutput("Ada\n")
  else:
    appendOutput("Vinit\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

Mark counts decide whose turn it is.
The cached search returns the outcome for that player.
The winner's name is appended once per test case.

## Complexity

Line construction is constant work; the search dominates.

| phase | time | space |
|---|---|---|
| line setup | 49 triples and 27 lists | small fixed arrays |
| search per case | visited states times 49 line checks | transposition table |
| output | one line per case | block buffer |

| measure | Big O |
|---|---|
| time | O(visited states times 49), exponential worst case |
| space | O(number of cached states) |

Plain minimax revisits the same positions through many move orders. The takeaway is that threats, pruning, and caching make each case short in practice.
