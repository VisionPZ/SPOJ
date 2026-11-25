# CERC07B — Strange Billboard (SPOJ)

<https://www.spoj.com/problems/CERC07B/>

## Problem

Clear a grid of black and white tiles by tapping tiles; each tap flips the tile and its side neighbors. Find the fewest taps that turn every tile white, or report that no sequence exists.

Each scenario starts with `R` and `C` from 1 to 16, followed by `R` rows of `C` characters: `X` for black and `.` for white. A blank line follows each map. The line `0 0` ends the input. Print `You have to tap T tiles.` or `Damaged billboard.`.

| item | bound |
|---|---|
| rows R | 1 to 16 |
| columns C | 1 to 16 |
| maps | until `0 0` |
| judge limit | 3601 ms, 1536 MB |

Only the first row needs a guess; every lower tap is forced by the row above it.

Sample input:

```
5 5
XX.XX
X.X.X
.XXX.
X.X.X
XX.XX

5 5
.XX.X
.....
..XXX
..X.X
..X..

1 5
...XX

5 5
...X.
...XX
.XX..
..X..
.....

8 9
..XXXXX..
.X.....X.
X..X.X..X
X.......X
X.X...X.X
X..XXX..X
.X.....X.
..XXXXX..

0 0
```

Sample output:

```
You have to tap 5 tiles.
Damaged billboard.
You have to tap 1 tiles.
You have to tap 2 tiles.
You have to tap 25 tiles.
```

## Idea

Fix the first row of taps, then let each row decide the next row, like pushing a row of dominoes downward. Once the taps in one row are known, the only way to clear that row is to tap exactly the black tiles left in the row below. Try every first-row pattern, keep the solvable ones, and choose the one with the fewest taps. Enumerating all tap sets would grow as two to the number of tiles; this sweep grows only as two to the number of columns. Take away the forced step and the search becomes exponential in the whole board.

## Why It Works

1. Tapping a tile toggles itself and its up, down, left, and right neighbors.
2. A flip applied twice cancels, so each row combines effects with exclusive-or.
3. After taps through row `r` are fixed, row `r` can only change further from taps in row `r+1`.
4. Therefore taps in row `r+1` must equal the remaining black bits of row `r`.
5. The last row has no row below it, so it must end all white.
6. Every solvable board appears once in the first-row enumeration.

| term | meaning |
|---|---|
| `boardRows` | black tile mask for each row |
| `tapRows` | tap mask chosen for each row |
| `sameRowFlip` | self and horizontal neighbor flips from one row |
| `fullMask` | mask with one bit per column |
| `bestTaps` | smallest tap count among valid patterns |

The forced choice makes the enumeration complete and avoids repeated work.

Chasing the single row `...XX`:

```
first-row pattern  ...X.   flips tiles 4 and 5   board becomes .....   taps 1
first-row pattern  ....X   flips tile 5 only     board remains ...X.   reject
first-row pattern  ...XX   flips tiles 4,5 twice and 5 once   reject
best valid pattern ...X.   answer 1
```

The trace matches the third sample answer.

## Code

**Input and helpers.** Rows become bit masks, and the scanner skips blank lines.

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

proc nextCell(data: string, pos: var int): char =
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\n' or data[pos] == '\r' or data[pos] == '\t'):
    pos += 1
  let cell = data[pos]
  pos += 1
  return cell

proc countBits(value: uint32): int =
  var remaining = value
  var count = 0
  while remaining != 0:
    count += int(remaining and uint32(1))
    remaining = remaining shr 1
  return count

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Each row fits in 16 bits, so one unsigned integer stores it.
The cell reader ignores the blank lines between maps.
Counting bits gives the tap cost of one complete pattern.

**Row chase.** Each first-row guess forces all lower rows.

```nim
while true:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  if rowCount == 0 and columnCount == 0:
    break
  var boardRows = newSeq[uint32](rowCount)
  for rowIndex in 0 .. rowCount - 1:
    var rowMask = uint32(0)
    for columnIndex in 0 .. columnCount - 1:
      let cell = nextCell(inputData, scanPos)
      if cell == 'X':
        rowMask = rowMask or (uint32(1) shl uint32(columnIndex))
    boardRows[rowIndex] = rowMask
  let fullMask = (uint32(1) shl uint32(columnCount)) - uint32(1)
  let firstRowChoices = 1 shl columnCount
  var bestTaps = -1
  for firstRowPattern in 0 .. firstRowChoices - 1:
    var tapRows = newSeq[uint32](rowCount)
    tapRows[0] = uint32(firstRowPattern)
    for rowIndex in 0 .. rowCount - 2:
      let tapMask = tapRows[rowIndex]
      let sameRowFlip = tapMask xor ((tapMask shl 1) and fullMask) xor (tapMask shr 1)
      var aboveFlip = uint32(0)
      if rowIndex > 0:
        aboveFlip = tapRows[rowIndex - 1]
      tapRows[rowIndex + 1] = boardRows[rowIndex] xor sameRowFlip xor aboveFlip
    let lastRow = rowCount - 1
    let lastTapMask = tapRows[lastRow]
    let lastRowFlip = lastTapMask xor ((lastTapMask shl 1) and fullMask) xor (lastTapMask shr 1)
    var aboveFlip = uint32(0)
    if lastRow > 0:
      aboveFlip = tapRows[lastRow - 1]
    if (boardRows[lastRow] xor lastRowFlip xor aboveFlip) != uint32(0):
      continue
    var tapTotal = 0
    for rowIndex in 0 .. rowCount - 1:
      tapTotal += countBits(tapRows[rowIndex])
    if bestTaps == -1 or tapTotal < bestTaps:
      bestTaps = tapTotal
  if bestTaps == -1:
    appendOutput("Damaged billboard.")
  else:
    appendOutput("You have to tap " & $bestTaps & " tiles.")
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The horizontal flip uses exclusive-or so double flips cancel.
The last row must be white after its own taps and the row above it.
A missing valid pattern means the board is damaged.

## Complexity

One first-row pattern triggers one pass down the board.

| phase | time | space |
|---|---|---|
| input read | one pass over map characters | one input string |
| row chase | `2^C` patterns times `R` rows | one mask per row |
| output | one write per block | block buffer |

The dominant phase is the chase, which grows with the column count.

| measure | Big O |
|---|---|
| time per map | O(2^C * R) |
| space | O(R * C) |

Tapping every subset of tiles would cost two to the number of tiles, far more than two to the columns. The forced lower rows make the smaller bound exact.
