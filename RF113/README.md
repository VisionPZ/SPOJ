# RF113 — WEIS GRADO 11 (SPOJ)
<https://www.spoj.com/problems/RF113/>

## Problem

A travel-time matrix should be zero on its main diagonal, since a place is zero minutes from itself.
Some diagonals contain bad nonzero values, and those matrices must be flagged.
Print `true` when every diagonal entry is zero and `false` otherwise.
The input holds several square matrices, each preceded by its dimension.
A line containing only zero ends the input.

| Item | Bound |
|---|---|
| Matrices | not stated |
| Dimension | not stated |
| Time limit | 1000 ms |
| Memory | 1536 MB |

Only the diagonal cells matter, so one pass over all values is enough.

The sample from the statement:

```
2
0 1
3 0
3
0 1 2
1 0 2
4 2 0
3
1 2 3
1 0 2
4 2 0
2
0 1
1 1
0
```

```
true
true
false
false
```

## Idea

Checking a diagonal is like inspecting the corner squares of a tiled floor.
The program reads all input once and scans every number by index.
Values in a square matrix arrive row by row.
A value sits on the diagonal when its position is a multiple of n plus one.
Any nonzero value at such a position sets a failure flag.
One word per matrix leaves the output buffer.

One pass over the cells decides whether the diagonal is clean.

## Why It Works

1. The diagonal cell of row i is column i of that row.
2. Cell position i times (n + 1) marks each diagonal entry.
3. All other positions are ignored by the check.
4. A single nonzero diagonal value makes the answer `false`.
5. The zero dimension is consumed before any flag is set.

The main terms follow.

| Term | Meaning |
|---|---|
| `dimension` | size of the current square matrix |
| `columnCount` | width used to find diagonal positions |
| `cellCount` | number of values in the matrix |
| `diagonalIsZero` | flag for a clean main diagonal |
| `cellValue` | number scanned at the current position |

Each matrix costs one scan and one word of output.

A trace from `gen.py --trace` for the sample:

```
diagonal [0, 0] -> true
diagonal [0, 0, 0] -> true
diagonal [1, 0, 0] -> false
diagonal [0, 1] -> false
```

The trace matches all four sample answers.

## Code

**Bulk input and scanner.** This block reads stdin once and parses integers.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    inc pos
  if pos >= data.len:
    return 0
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - firstDigitValue)
    inc pos
  return value
```

Spaces and line breaks are skipped as plain separators.
The scanner builds values without allocating token strings.
Values arrive in row order, which fixes each diagonal position.

**Output buffer.** This block buffers text and flushes in blocks.

```nim
var outputBuffer = ""

proc flushIfReady() =
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendOutput(text: string) =
  outputBuffer.add text
  flushIfReady()
```

The buffer leaves after reaching 131072 bytes.
The last partial block is written after the loop.
No write happens per cell.

**Diagonal check loop.** This block scans cells and prints one answer.

```nim
while scanPos < inputData.len:
  let dimension = nextInt(inputData, scanPos)
  if dimension == 0:
    break
  if dimension < 0:
    break
  let columnCount = int(dimension)
  let cellCount = columnCount * columnCount
  var diagonalIsZero = true
  for cell in 0..<cellCount:
    let cellValue = nextInt(inputData, scanPos)
    if cell mod (columnCount + 1) == 0 and cellValue != 0:
      diagonalIsZero = false
  if diagonalIsZero:
    appendOutput("true\n")
  else:
    appendOutput("false\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The dimension gives the closed form n squared for the cell count.
The modulo expression selects only diagonal positions.
A zero dimension ends the run without producing output.

## Complexity

Cost follows the number of cells in every matrix.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Diagonal check | one scan of each cell | one flag |
| Output | one write per block | block buffer |

One scan over the matrix decides the answer for its diagonal.

| Measure | Big O |
|---|---|
| Time | O(I + C) for C cells |
| Space | O(I + B) |

Here I is input bytes, C is total cells, and B is block size.

Reading each diagonal entry with a separate lookup would need the whole matrix stored.
The streaming check needs one flag and no stored rows.
