# FUCT_FOR_INVPYRA — Inverted pyramid (SPOJ)

<https://www.spoj.com/problems/FUCT_FOR_INVPYRA/>

## Problem

Read a height and print an upside-down pyramid of stars with that many rows. The top row is the widest, and each row below loses one star on each side while shifting two columns to the right. Stars are separated by single spaces.

| Item | Bound |
|---|---|
| Pyramid height | 0 < n ≤ 100 |
| Rows per pyramid | n |
| Judge limit | 1000 ms, 1536 MB |

The sample case:

```
5
```

```
* * * * * * * * *
  * * * * * * *
    * * * * *
      * * *
        *
```

## Idea

Row i is just two numbers: how many spaces to print, and how many stars to print. The spaces grow by two each row and the stars shrink by two each row, so a row is written directly without measuring anything else. No grid, no trimming.

## Why It Works

1. Row i starts at column 2i, which is where the pyramid edge sits.
2. The star count for row i is 2(n-i)-1, an odd number, so stars and single spaces alternate.
3. An odd count means the line ends on a star, so there is nothing to trim.
4. The last row has 2(n-1) spaces and one star, matching the tip.
5. Adding two spaces and dropping two stars keeps the sides straight.

| Term | Meaning |
|---|---|
| `pyramidHeight` | requested number of rows |
| `rowIndex` | row being printed, 0 at the top |
| `starCount` | stars on this row |
| `spacesOf` | builds a run of spaces |
| `starLine` | builds stars separated by single spaces |

A script-traced example from `gen.py`:

```
height 5, top row star count 9
row 1 leading spaces 2, star count 7
last row: 8 spaces then one star
```

That gives the sample's first, second and last lines exactly.

## Code

**Bulk input and hand scanner.** This block loads all of stdin once and reads integers by index.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextSignedInt(data: string, position: var int, found: var bool): int =
  while position < data.len and data[position] != '-' and (data[position] < '0' or data[position] > '9'):
    position += 1
  if position >= data.len:
    found = false
    return 0
  var signValue = 1
  if data[position] == '-':
    signValue = -1
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  found = true
  return signValue * value
```

One pass over the bytes reads every number.
`found` marks the end of input, so several heights in one file all print.
Nothing is allocated per token.

**Line builders.** This block makes the two pieces every row uses.

```nim
proc spacesOf(count: int): string =
  var builtLine = newString(count)
  var fillIndex = 0
  while fillIndex < count:
    builtLine[fillIndex] = ' '
    fillIndex += 1
  return builtLine

proc starLine(starCount: int): string =
  var builtLine = newString(2 * starCount - 1)
  var writeIndex = 0
  while writeIndex < builtLine.len:
    builtLine[writeIndex] = '*'
    writeIndex += 1
    if writeIndex < builtLine.len:
      builtLine[writeIndex] = ' '
      writeIndex += 1
  return builtLine
```

`newString` reserves the exact length, so no growing happens.
`starLine` stops before a trailing space, which keeps the judge's lines clean.
Judge 0.19.4 has no `string * int`, hence the loops.

**Rows and buffered output.** This block prints one pyramid per number read.

```nim
var heightFound = false
while true:
  let pyramidHeight = nextSignedInt(inputData, scanPos, heightFound)
  if not heightFound:
    break
  if pyramidHeight <= 0:
    appendOutput("\n")
  else:
    for rowIndex in 0 ..< pyramidHeight:
      let starCount = 2 * (pyramidHeight - rowIndex) - 1
      appendOutput(spacesOf(2 * rowIndex) & starLine(starCount) & "\n")
```

`appendOutput` fills a 128 KiB buffer and flushes when full.
The last `stdout.write` emits the final partial block.
A height out of range prints one blank line instead of stopping.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Pyramid build | O(n²) characters per case | one line at a time |
| Output | one write per 128 KiB block | block buffer |

| Measure | Big O |
|---|---|
| Time | O(n²) per case, linear in output size |
| Space | O(input size + block buffer) |

A grid plus a trim pass would need n(2n-1) stored cells; writing each row from two counts uses one line.
