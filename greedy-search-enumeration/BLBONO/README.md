# BLBONO — Bono v3 (SPOJ)

<https://www.spoj.com/problems/BLBONO/>

## Problem

Several independent three-by-three boards start with some cells filled. Players take turns filling one empty cell, and any board with a full row, column, or diagonal disappears. The player with no legal move loses; decide who wins with best play.

Input begins with `T` games. Each game gives `N`, then `N` nine-character binary strings. A `1` marks a filled cell, and cell `(r, c)` is character `(r-1)×3+c`. Output one name per game: `Kang` for the first player or `Kung` for the second.

| Item | Bound |
|---|---|
| Games T | up to 1000 |
| Boards per game N | up to 1000 |
| Board cells | 9 per board |
| Judge limit | 1000 ms, 1536 MB |

Each board has only 512 possible states.

The sample has one empty board, two empty boards, and two partly filled boards:

```
3
1
000000000
2
000000000
000000000
2
100010000
101000000
```

The expected output is:

```
Kang
Kung
Kung
```

Two equal boards cancel, so the second and third games go to the second player.

## Idea

Treat each board like a pile in Nim: the piles add by XOR, so equal piles cancel. Compute a Grundy number for every one of the 512 board states by working backward from full boards. XOR the numbers for all boards in a game; a nonzero result means the first player wins.

## Why It Works

1. A board with a completed line has no legal move, so its Grundy number is zero.
2. Every other move adds one cell, so successors have a larger bit mask.
3. Scanning masks from 511 down to 0 leaves every successor value ready.
4. The Mexican permutation of successor values gives the board's Grundy number.
5. Disjoint games add by XOR, and zero means the previous player wins.

| Term | Meaning |
|---|---|
| `boardMask` | nine bits describing filled cells |
| `winningLines` | the eight rows, columns, and diagonals |
| `grundyValues` | Grundy number for each mask |
| `combinedValue` | XOR of all boards in one game |

The table lists every value the program needs.

Grundy values for a few masks:

```
000000000  -> 1
100010000  -> 2
101000000  -> 2
111111111  -> 0 (already destroyed)
```

The two equal values give XOR zero, which matches the third sample game.

## Code

**Input and scanning.** Two hand readers load counts and nine-bit board strings.

```nim
const flushBlockBytes = 1 shl 17
const boardCellCount = 9
const winningLines = [7, 56, 448, 73, 146, 292, 273, 84]

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

proc nextBoardMask(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '0' and data[pos] != '1':
    pos += 1
  var maskValue = 0
  var bitsRead = 0
  while pos < data.len and bitsRead < boardCellCount and (data[pos] == '0' or data[pos] == '1'):
    maskValue = maskValue * 2 + int(data[pos]) - 48
    pos += 1
    bitsRead += 1
  return maskValue
```

The board reader consumes exactly nine bits.
It does not lose leading zeros as an integer parser would.
The eight line masks are constants.

**Terminal test and output buffer.** A completed line ends that board immediately.

```nim
proc hasWinningLine(boardMask: int): bool =
  for lineMask in winningLines:
    if (boardMask and lineMask) == lineMask:
      return true
  return false

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The test checks all eight lines with bit masks.
A destroyed board contributes zero to the game.
Names collect in the block buffer before writing.

**Grundy table.** Working downward makes every successor value available.

```nim
var grundyValues = newSeq[int](1 shl boardCellCount)
var boardMask = (1 shl boardCellCount) - 1
while boardMask >= 0:
  if hasWinningLine(boardMask):
    grundyValues[boardMask] = 0
  else:
    var seenValues = 0
    for cellIndex in 0 .. boardCellCount - 1:
      if (boardMask and (1 shl cellIndex)) == 0:
        let nextMask = boardMask or (1 shl cellIndex)
        var nextValue = 0
        if not hasWinningLine(nextMask):
          nextValue = grundyValues[nextMask]
        seenValues = seenValues or (1 shl nextValue)
    var mexValue = 0
    while (seenValues and (1 shl mexValue)) != 0:
      mexValue += 1
    grundyValues[boardMask] = mexValue
  boardMask -= 1
```

The loop visits 512 masks once.
A bit set marks each reachable Grundy value.
The lowest clear bit is the mex.

**Game resolution.** XOR across boards decides the winner.

```nim
let gameCount = nextInt(inputData, scanPos)
for gameIndex in 0 .. gameCount - 1:
  let boardCount = nextInt(inputData, scanPos)
  var combinedValue = 0
  for boardIndex in 0 .. boardCount - 1:
    let startMask = nextBoardMask(inputData, scanPos)
    combinedValue = combinedValue xor grundyValues[startMask]
  if combinedValue != 0:
    appendOutput("Kang")
  else:
    appendOutput("Kung")
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Each game reads exactly `boardCount` boards.
A zero XOR hands the win to the second player.
One final flush writes all game results.

## Complexity

Precomputation is fixed at 512 states, and each game scans its boards.

| Phase | Time | Space |
|---|---|---|
| Grundy table | 512 masks times nine cells | 512 integers |
| Game read | one pass over all board strings | one input string |
| Output | one line per game | block buffer |

No phase depends on the product of games and boards.

| Measure | Big O |
|---|---|
| Time | O(512 × 9 + total boards) |
| Space | O(512 + input bytes) |

Replaying every possible game tree would grow exponentially, so Grundy values replace search.
