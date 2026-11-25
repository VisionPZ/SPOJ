# CPTTRN1 — Character Patterns (Act 1) (SPOJ)

<https://www.spoj.com/problems/CPTTRN1/>

## Problem

For each test case, print a chessboard of `l` lines and `c` columns. Use `*` and `.` and start with `*` in the top-left corner. Put one blank line after each case.

The input starts with a case count. Each case gives two positive integers below 100.

| Item | Bound |
|---|---|
| Test cases | fewer than 100 |
| Lines `l` | 1 to 99 |
| Columns `c` | 1 to 99 |
| Judge limit | 1000 ms, 1536 MB |

The sample:

```
3
3 1
4 4
2 5
```

```
*
.
*

*.*.
.*.*
*.*.
.*.*

*.*.*
.*.*.

```

## Idea

Colour the chessboard by parity. A cell is `*` when its row and column indices add to an even number, and `.` otherwise.

The program loops over every cell and uses one `mod 2` test. Building a row string first would add a copy step without changing the result.

One parity test per cell prints the whole board.

## Why It Works

1. Row 0 and column 0 give an even sum, so the first character is `*`, as required.
2. Moving one cell right or down flips the parity, so the characters alternate in both directions.
3. The blank line after the last row separates cases and matches the sample's byte shape.

| Term | Meaning |
|---|---|
| `rowIndex` | the current line, counting from zero |
| `columnIndex` | the current column, counting from zero |
| `outputBuffer` | the single string that holds every pattern |

The parity of the two indices decides every character.

A traced run of the sample case `2 5`:

```
rowIndex 0: sums 0..4 -> even,odd,even,odd,even -> "*.*.*"
rowIndex 1: sums 1..5 -> odd,even,odd,even,odd  -> ".*.*."
then one blank line
```

The trace matches the last sample pattern.

## Code

**Cell loop.** One parity test per position.

```nim
let caseCount = nextInt(inputData, scanPos)
for _ in 0 ..< caseCount:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  for rowIndex in 0 ..< rowCount:
    for columnIndex in 0 ..< columnCount:
      if (rowIndex + columnIndex) mod 2 == 0:
        appendOutput("*")
      else:
        appendOutput(".")
    outputBuffer.add '\n'
  outputBuffer.add '\n'
```

Nim 0.19.4 has no `%` operator, so the code uses `mod`. The inner loop runs `l * c` times, which is at most 9801 per case.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over the input bytes | input bytes |
| One pattern | O(l * c) cell writes | one output buffer |
| Output | one write per block | one buffer |

The pattern size bounds the work per case.

| Measure | Big O |
|---|---|
| Time | O(total printed characters) |
| Space | O(input bytes) |

A per-character write through the stream would dominate this small pattern. One buffer keeps the cost on the characters themselves.
