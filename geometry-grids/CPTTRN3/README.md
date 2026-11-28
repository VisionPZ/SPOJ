# CPTTRN3 — Character Patterns (Act 3) (SPOJ)

<https://www.spoj.com/problems/CPTTRN3/>

## Problem

For each test case, print a grid of `l` lines and `c` columns. Each grid cell is three characters wide and three characters tall, filled with dots and outlined with stars. Put one blank line after each case.

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
****
*..*
*..*
****
*..*
*..*
****

*************
*..*..*..*..*
*..*..*..*..*
*************
*..*..*..*..*
*..*..*..*..*
*************
*..*..*..*..*
*..*..*..*..*
*************

****************
*..*..*..*..*..*
*..*..*..*..*..*
****************
*..*..*..*..*..*
*..*..*..*..*..*
****************

```

## Idea

A cell takes three columns and two rows. Stars land on every third column and every second row. The rest of the grid is dots.

The program computes the total width as `3 * c + 1` and the total height as `3 * l + 1`. Two modulo tests decide each character, so no cell string is ever built.

One modulo per axis prints the whole grid.

## Why It Works

1. A vertical star line appears at column 0, 3, 6, and so on, up to `3 * c`.
2. A horizontal star line appears at row 0, 3, 6, and so on, up to `3 * l`.
3. Every other position lies inside a cell and is a dot.

| Term | Meaning |
|---|---|
| `totalRows` | `3 * rowCount + 1`, the printed height |
| `totalColumns` | `3 * columnCount + 1`, the printed width |
| `rowIndex` | the current printed line |

The step size 3 defines both axes of the picture.

A traced run of the sample case `1 2`:

```
totalRows 4, totalColumns 7
row 0 -> every column is a border -> "*******"
row 1 -> columns 0,3,6 are stars -> "*..*..*"
row 2 -> columns 0,3,6 are stars -> "*..*..*"
row 3 -> every column is a border -> "*******"
```

The trace follows the same rule as the larger sample cases.

## Code

**Grid loop.** Two modulo tests per character.

```nim
let caseCount = nextInt(inputData, scanPos)
for _ in 0 ..< caseCount:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  let totalRows = 3 * rowCount + 1
  let totalColumns = 3 * columnCount + 1
  for rowIndex in 0 ..< totalRows:
    for columnIndex in 0 ..< totalColumns:
      if rowIndex mod 3 == 0 or columnIndex mod 3 == 0:
        appendOutput("*")
      else:
        appendOutput(".")
    outputBuffer.add '\n'
  outputBuffer.add '\n'
```

The closed form `3 * rowCount + 1` counts three rows per cell plus the closing border. The column test uses the same step for the three-character cell width.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over the input bytes | input bytes |
| One grid | O(l * c) character writes | one output buffer |
| Output | one write per block | one buffer |

The printed area bounds the work per case.

| Measure | Big O |
|---|---|
| Time | O(total printed characters) |
| Space | O(input bytes) |

Building each cell as a three-character string would triple the copy work. Two modulo tests keep the pass over the output area alone.
