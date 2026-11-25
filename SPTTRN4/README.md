# SPTTRN4 — Straight Line Spiral Pattern, Act 4 (SPOJ)

<https://www.spoj.com/problems/SPTTRN4/>

## Problem

A spiral is drawn with stars and dots in a square grid of side `s`. The starred cells form a continuous counter-clockwise path that starts at the top-left corner and winds inward. The statement prints example spirals with their rows joined onto one line. Given a size and a row and column, print only the character at that cell.

The first line gives the test count. Each later line holds `s`, `i`, and `j`. Rows and columns are counted from one. Print one character followed by a newline for each query.

| Item | Bound |
|---|---|
| Test cases | 1000 |
| Size `s` | 3 to 10000 |
| Row `i` | 1 to `s` |
| Column `j` | 1 to `s` |
| Judge limit | 1000 ms, 1536 MB |

The statement renders the sample without line breaks:

```
33 1 14 3 25 2 3
```

```
*.*
```

Decoded into lines, the sample input is:

```
3
3 1 1
4 3 2
5 2 3
```

Decoded into lines, the sample output is:

```
*
.
*
```

## Idea

Think of a painter walking a square path and turning at each corner, leaving a one-cell gap between parallel strokes. The path has exactly `s` straight arms. Arm lengths shrink in steps of two as the painter moves inward.

The program computes the length and start of each possible arm from the query cell. A cell can belong only to a horizontal arm on its own row or a vertical arm on its own column. Those facts fix at most six arm indices. Testing those indices gives the character in constant time.

## Why It Works

1. The walk starts at row zero, column zero, then goes down, right, up, and left repeatedly.
2. The first three arms have length `s - 1`; later arms come in pairs of decreasing length.
3. Arm `k` begins at a corner determined by `(k - 1) div 4` and `(k - 1) mod 4`.
4. The walk has exactly `s` arms, so no arm index reaches `s`.
5. A starred cell lies on one arm, and an arm covers only one fixed row or one fixed column.
6. A query therefore needs only arms aligned with its row or column.
7. Testing those few arms decides membership without drawing the grid.

| Term | Meaning |
|---|---|
| `size` | side length `s` of the spiral |
| `armIndex` | zero-based index of a straight segment |
| `group` | which square ring an arm belongs to |
| `kind` | direction of an arm: right, up, left, or down |
| `length` | number of cells an arm adds |
| `pointOnArm` | checks one arm against the query cell |

A script-generated trace of the three queries:

```
s=3, i=1, j=1 -> row 0 col 0, the start cell -> *
s=4, i=3, j=2 -> row 2 col 1, no arm covers it -> .
s=5, i=2, j=3 -> row 1 col 2, the down arm at column 2 -> *
```

The traced characters match the decoded sample output.

## Code

**Input and scanner.** Read all lines once and scan integers by index.

```nim
const firstDigitValue = 48
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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner skips the spaces and newlines between the three fields. The buffer flushes every 128 KiB.

**Arm geometry.** Compute lengths and test the four segment directions.

```nim
proc armLength(armIndex: int, size: int): int =
  if armIndex <= 2:
    return size - 1
  return size - 3 - 2 * ((armIndex - 3) div 2)

proc pointOnArm(armIndex: int, row: int, col: int, size: int): bool =
  if armIndex < 0 or armIndex >= size:
    return false
  if armIndex == 0:
    return col == 0 and row <= size - 1
  let group = (armIndex - 1) div 4
  let kind = (armIndex - 1) mod 4
  let length = armLength(armIndex, size)
  if kind == 0:
    return row == size - 1 - 2 * group and col >= 2 * group + 1 and col <= 2 * group + length
  if kind == 1:
    return col == size - 1 - 2 * group and row >= size - 1 - 2 * group - length and row <= size - 2 * group - 1
  if kind == 2:
    return row == 2 * group and col >= size - 1 - 2 * group - length and col <= size - 2 * group - 1
  return col == 2 * group + 2 and row >= 2 * group + 1 and row <= 2 * group + length
```

The group and kind reproduce the start corner of each arm. Arm zero is special because the walk begins there.

**Cell lookup.** Test only the arms that align with the query row or column.

```nim
proc spiralCharacter(size: int, row: int, col: int): char =
  if pointOnArm(0, row, col, size):
    return '*'
  if col >= 2 and col mod 2 == 0:
    if pointOnArm(2 * col, row, col, size):
      return '*'
  if (size - 1 - col) mod 2 == 0:
    let distance = size - 1 - col
    if pointOnArm(2 * distance + 2, row, col, size):
      return '*'
    if pointOnArm(2 * distance + 3, row, col, size):
      return '*'
  if row mod 2 == 0:
    if pointOnArm(2 * row + 3, row, col, size):
      return '*'
    if row >= 2:
      if pointOnArm(2 * row + 4, row, col, size):
        return '*'
  if (size - 1 - row) mod 2 == 0:
    let distance = size - 1 - row
    if pointOnArm(2 * distance + 1, row, col, size):
      return '*'
  return '.'
```

The candidate indices come from the row and column bounds of the arms. Any untested arm cannot reach the cell.

**Driver.** Convert to zero-based coordinates and write one character.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let size = nextInt(inputData, scanPos)
  let oneBasedRow = nextInt(inputData, scanPos)
  let oneBasedCol = nextInt(inputData, scanPos)
  appendOutput($spiralCharacter(size, oneBasedRow - 1, oneBasedCol - 1))
  outputBuffer.add '\n'
stdout.write outputBuffer
```

Input rows and columns are one-based, so each is reduced by one. The final write flushes any remaining bytes.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | one input string |
| One query | at most six arm tests | O(1) |
| Output | one write per filled buffer | one output string |

| Measure | Big O |
|---|---|
| Time | O(test cases + input size) |
| Space | O(1) beyond input |

Drawing the whole grid would cost O(s²) cells per query. Walking every arm would cost O(s). With size up to 10000 and 1000 queries, neither approach is needed.
