# CPTTRN2 — Character Patterns (Act 2) (SPOJ)

<https://www.spoj.com/problems/CPTTRN2/>

## Problem

For each test case, print a rectangular frame of `l` lines and `c` columns. Fill the border with `*` and the inside with `.`. A frame with one line or one column is all stars. Put one blank line after each case.

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
*
*

****
*..*
*..*
****

*****
*****

```

## Idea

Draw the border first, then leave the middle empty. Think of taping the edge of a picture frame: every cell on an edge is a star, and only the cells well inside the frame stay dots.

The program tests four edge conditions for each cell. When the frame has no inside, the same condition prints stars everywhere.

One border test per cell finishes the case.

## Why It Works

1. A cell is on the border when its row is the first or last, or its column is the first or last.
2. A frame of height 1 or width 1 has no interior cells, so the explicit check prints all stars.
3. The blank line after the pattern matches the sample's byte shape.

| Term | Meaning |
|---|---|
| `onBorder` | true when the cell touches an edge |
| `rowCount` | the frame height |
| `columnCount` | the frame width |

The edge test and the thin-frame test cover every cell.

A traced run of the sample case `4 4`:

```
row 0 -> all four cells on the top edge -> "****"
row 1 -> only columns 0 and 3 are edges -> "*..*"
row 2 -> only columns 0 and 3 are edges -> "*..*"
row 3 -> all four cells on the bottom edge -> "****"
```

The trace matches the middle sample pattern.

## Code

**Frame loop.** One border test per cell.

```nim
let caseCount = nextInt(inputData, scanPos)
for _ in 0 ..< caseCount:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  for rowIndex in 0 ..< rowCount:
    for columnIndex in 0 ..< columnCount:
      let onBorder = rowIndex == 0 or rowIndex == rowCount - 1 or
                     columnIndex == 0 or columnIndex == columnCount - 1
      if onBorder or rowCount == 1 or columnCount == 1:
        appendOutput("*")
      else:
        appendOutput(".")
    outputBuffer.add '\n'
  outputBuffer.add '\n'
```

`onBorder` is computed once per cell. The `rowCount == 1` and `columnCount == 1` checks handle the two thin-frame cases the sample shows.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over the input bytes | input bytes |
| One frame | O(l * c) cell writes | one output buffer |
| Output | one write per block | one buffer |

The frame size bounds the work per case.

| Measure | Big O |
|---|---|
| Time | O(total printed characters) |
| Space | O(input bytes) |

Constructing border and interior rows as separate strings would copy bytes. Testing each cell once avoids that copy.
