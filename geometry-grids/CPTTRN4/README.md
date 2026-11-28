# CPTTRN4 — Character Patterns (Act 4) (SPOJ)

<https://www.spoj.com/problems/CPTTRN4/>

## Problem

For each test case, print a grid of `l` lines and `c` columns. Each cell is `h` characters tall and `w` characters wide, drawn as dots and fenced by stars. Put one blank line after each case.

The input starts with a case count. Each case gives four positive integers: `l`, `c`, `h`, and `w`, all below 100.

| Item | Bound |
|---|---|
| Test cases | fewer than 100 |
| Lines `l`, columns `c` | 1 to 99 |
| Cell height `h`, width `w` | 1 to 99 |
| Judge limit | 1000 ms, 1536 MB |

The sample:

```
3
3 1 2 1
4 4 1 2
2 5 2 2
```

```
***
*.*
*.*
***
*.*
*.*
***
*.*
*.*
***

*************
*..*..*..*..*
*************
*..*..*..*..*
*************
*..*..*..*..*
*************
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

A star fence appears every `h + 1` rows and every `w + 1` columns. Each gap between fences is one cell of dots.

The program computes the printed size from the four input values. Two modulo tests decide each character, so the same loop draws thin cells and thick cells alike.

Two step sizes, `h + 1` and `w + 1`, define the whole grid.

## Why It Works

1. Horizontal fences occur at rows 0, `h + 1`, `2(h + 1)`, and so on, ending at `l(h + 1)`.
2. Vertical fences occur at columns 0, `w + 1`, `2(w + 1)`, and so on, ending at `c(w + 1)`.
3. Every other position lies inside a cell, so the character is a dot.

| Term | Meaning |
|---|---|
| `cellHeight` | the number of dot rows inside one cell |
| `cellWidth` | the number of dot columns inside one cell |
| `totalRows` | `rowCount * (cellHeight + 1) + 1` |
| `totalColumns` | `columnCount * (cellWidth + 1) + 1` |

The closed forms count fences plus gaps.

A traced run of the sample case `2 2 1 2`:

```
totalRows 5, totalColumns 7
row 0 -> fence -> "*******"
row 1 -> gaps -> "*..*..*"
row 2 -> fence -> "*******"
row 3 -> gaps -> "*..*..*"
row 4 -> fence -> "*******"
```

The trace matches the second sample pattern.

## Code

**Grid loop.** The step sizes come from the cell dimensions.

```nim
let caseCount = nextInt(inputData, scanPos)
for _ in 0 ..< caseCount:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  let cellHeight = nextInt(inputData, scanPos)
  let cellWidth = nextInt(inputData, scanPos)
  let totalRows = rowCount * (cellHeight + 1) + 1
  let totalColumns = columnCount * (cellWidth + 1) + 1
  for rowIndex in 0 ..< totalRows:
    for columnIndex in 0 ..< totalColumns:
      if rowIndex mod (cellHeight + 1) == 0 or columnIndex mod (cellWidth + 1) == 0:
        appendOutput("*")
      else:
        appendOutput(".")
    outputBuffer.add '\n'
  outputBuffer.add '\n'
```

The two `mod` terms are fences. The loop visits exactly the printed area, from 0 to `totalRows - 1` and `totalColumns - 1`.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over the input bytes | input bytes |
| One grid | O(totalRows * totalColumns) writes | one output buffer |
| Output | one write per block | one buffer |

The printed area bounds the work per case.

| Measure | Big O |
|---|---|
| Time | O(total printed characters) |
| Space | O(input bytes) |

Drawing cells one string at a time would copy the same dots many times. The modulo test writes each printed character once.
