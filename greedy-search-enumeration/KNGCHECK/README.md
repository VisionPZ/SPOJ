# KNGCHECK — Check (SPOJ)

<https://www.spoj.com/problems/KNGCHECK/>

## Problem

Given a chessboard of kings, knights, and pawns, decide whether a white piece can capture the black king on the next move. Ignore turn order and check the board as it stands.

The first line holds the case count. Each case has eight rows of eight tokens, with blank lines between cases. Tokens are `BK`, `WK`, `WH`, `BP`, `WP`, `BH`, or `-`.

| item | bound |
|---|---|
| board size | 8 by 8 |
| black kings | exactly one per case |
| white piece moves | knight L-shape, king neighbor, pawn upward diagonal |
| judge limit | 1000 ms, 1536 MB |

White pawns attack toward smaller row indices.

Sample input:

```
3
- - - - - - - -
- - - - - - - -
- - - - - - - -
- BH - - - - - -
- - - BK - - - -
- - WP - - - - -
- - - - - - - -
- - - - - - - -

- - - - - - - -
BH - - BH - - - -
- - - - - - - -
- - - - - - - -
- - - BK - - - -
- - - - - - - -
- WP - - - - WH -
- - - WK - - - -

- - - - - - - -
- - - - - - - -
- - - - - - - -
- - - BK - - - -
- - WK - - - - -
- - - - - - WH -
- - - - - - - -
- - - - - - - -
```

Sample output:

```
Case #1: Check
Case #2: Not Check
Case #3: Check
```

## Idea

Think of drawing every white attack square with a marker, then looking for the black king's square among the marks.

The program first locates the black king, then compares each white piece with that square. Each comparison is constant work, so one board costs 64 checks.

Generating all legal move trees for chess would add needless work.

A direct distance test gives the answer in one board pass.

## Why It Works

1. A white knight attacks when row and column gaps are 1 and 2 in either order.
2. A white king attacks any of the eight neighboring squares.
3. A white pawn attacks one row upward and one column to either side.
4. Row indices grow downward, so upward means row minus one.
5. Black pieces never threaten the black king in this problem.
6. Any single matching white piece makes the answer `Check`.

| term | meaning |
|---|---|
| `kingRow` | row index of the black king |
| `kingCol` | column index of the black king |
| `rowGap` | absolute row distance to the king |
| `colGap` | absolute column distance to the king |
| `attacked` | whether a white piece can reach the king |

Blank tokens are ignored during the scan.

A script trace explains sample case 1:

```
black king       row 4 col 3
white pawn       row 5 col 2
pawn targets     row 4 col 1 and row 4 col 3
king square      row 4 col 3 -> Check
```

The trace matches the first sample verdict.

## Code

**Input and tokens.** The reader turns the board into 64 tokens per case.

```nim
const flushBlockBytes = 1 shl 17

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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token
```

Blank lines vanish because the token reader skips whitespace.
The case count uses the integer scanner.
Every case yields exactly 64 cells.

**King and attack scan.** The board is checked piece by piece.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  var boardCells = newSeq[string](64)
  for cellIndex in 0 .. 63:
    boardCells[cellIndex] = nextToken(inputData, scanPos)
  var kingRow = -1
  var kingCol = -1
  for cellIndex in 0 .. 63:
    if boardCells[cellIndex] == "BK":
      kingRow = cellIndex div 8
      kingCol = cellIndex mod 8
  var attacked = false
  for cellIndex in 0 .. 63:
    let piece = boardCells[cellIndex]
    if piece == "-":
      continue
    let pieceRow = cellIndex div 8
    let pieceCol = cellIndex mod 8
    let rowGap = abs(kingRow - pieceRow)
    let colGap = abs(kingCol - pieceCol)
    if piece == "WH":
      if (rowGap == 1 and colGap == 2) or (rowGap == 2 and colGap == 1):
        attacked = true
    elif piece == "WP":
      if pieceRow - kingRow == 1 and colGap == 1:
        attacked = true
    elif piece == "WK":
      if rowGap <= 1 and colGap <= 1:
        attacked = true
  appendOutput("Case #" & $(caseIndex + 1) & ": ")
  if attacked:
    appendOutput("Check")
  else:
    appendOutput("Not Check")
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Cell index 0 is the top-left corner.
Integer division gives the row and modulus gives the column.
One matching piece sets the verdict immediately.

## Complexity

Each board is read once and scanned once.

| phase | time | space |
|---|---|---|
| input read | one pass over 64 tokens per case | one input string |
| king lookup | 64 cells | 64 tokens |
| attack scan | 64 cells with constant tests | constant extra space |

The token array is small enough to rebuild per case.

| measure | Big O |
|---|---|
| time per case | O(64), constant |
| space per case | O(64), constant |

Simulating whole games would add work without changing the verdict.

The direct token scan is the takeaway.
