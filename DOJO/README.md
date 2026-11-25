# DOJO — With a Pit of Death (SPOJ)

<https://www.spoj.com/problems/DOJO/>

## Problem

A dojo is a rectangle of floor tiles with one square pit removed. Decide whether the remaining floor can be covered exactly by dominoes that each span two adjacent tiles.

Each test case gives `n`, `m`, `i`, `j`. The floor has `n` rows and `m` columns. The pit occupies row `i` and column `j`. Print `Possible.` when a covering exists, otherwise `Impossible.`. The judge ignores extra whitespace.

| item | bound |
|---|---|
| test cases T | 1 to 1000 |
| rows n | 1 to 32 |
| columns m | 1 to 10 |
| pit row i | 1 to n |
| pit column j | 1 to m |
| judge limit | 1000 ms, 1536 MB |

Only the parities of four numbers matter, so a test case costs constant time.

Sample input:

```
2
3 3 2 2
3 3 1 2
```

Sample output:

```
Possible.
Impossible.
```

## Idea

Mark the floor like a chessboard, and notice that every domino covers one tile of each shade, like pairing black and white socks.

The board has one more black tile than white tile only when both dimensions are odd. Removing the pit must remove that extra black tile. With row 1 and column 1 coloured black, a tile is black when `i + j` is even.

The test is therefore three parity checks. A brute-force tiling search tries many placements for each case. The parity test reads four numbers and answers at once. Keep the pit at even `i + j` only when both dimensions are odd.

## Why It Works

1. A domino always covers two tiles of opposite chessboard colours.
2. A complete covering needs equal counts of black and white tiles.
3. The full rectangle has equal counts when its area is even.
4. When both dimensions are odd, one more black tile exists, so the pit must be black.
5. Tile `(i, j)` is black exactly when `i + j` is even.
6. No rectangle with an even area can pass, because removing one tile leaves an odd count.

| term | meaning |
|---|---|
| `rowCount` | number of rows n |
| `columnCount` | number of columns m |
| `pitRow` | row i of the removed tile |
| `pitColumn` | column j of the removed tile |
| `areaIsOdd` | true when both dimensions are odd |
| `pitHasMajorityColor` | true when `pitRow + pitColumn` is even |

The term table lists every value used by the decision.

A script-traced example for the first sample case:

| step | value |
|---|---|
| dimensions | `n = 3`, `m = 3` |
| area | `9`, which is odd |
| pit | `i = 2`, `j = 2` |
| parity sum | `2 + 2 = 4`, which is even |
| verdict | `Possible.` |

The trace matches the first line of the sample output.

No rounding or overflow risk exists here. All comparisons use remainders modulo 2, so large bounds stay safe.

## Code

**Shared input and output helpers.** The reader consumes stdin once, and the writer flushes in large blocks.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner skips whitespace between numbers.
Every input value is positive, so a minus branch is unnecessary.
One buffer holds all answers until it reaches the block size.

**Case loop.** Each case reduces to three modulo-2 tests.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  let pitRow = nextInt(inputData, scanPos)
  let pitColumn = nextInt(inputData, scanPos)
  let areaIsOdd = rowCount mod 2 == 1 and columnCount mod 2 == 1
  let pitHasMajorityColor = (pitRow + pitColumn) mod 2 == 0
  if areaIsOdd and pitHasMajorityColor:
    appendOutput("Possible.\n")
  else:
    appendOutput("Impossible.\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop reads exactly four numbers per case.
Two flags name the chessboard conditions in plain words.
The final flush writes any remaining bytes once.

## Complexity

Each case reads four values and performs a fixed number of parity checks.

| phase | time | space |
|---|---|---|
| input read | one pass over stdin bytes | one input string |
| parity tests | constant work per case | constant |
| output | one buffered write per block | one output string |

The phase table shows that board size has no effect on runtime.

| measure | Big O |
|---|---|
| time | O(T) |
| space | O(input size) |

A domino-placement search would explore exponentially many layouts; three parity checks settle each case immediately.
