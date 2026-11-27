# FUCT_FOR_ARROW — Right arrow (SPOJ)

<https://www.spoj.com/problems/FUCT_FOR_ARROW/>

## Problem

Read a height and print a right-pointing arrow of stars that many rows tall. Stars sit on every other column, so every line is a run of single spaces between them.

If the number is not greater than 2, print `accept positive integer greater than 2 only!` instead.

| Item | Bound |
|---|---|
| Arrow height | 2 < n ≤ 100 |
| Rows per arrow | n |
| Judge limit | 1000 ms, 1536 MB |

The sample case:

```
5
```

```
* * * * *
  *       *
    *       *
  *       *
* * * * *
```

## Idea

Two rows are solid bars of n stars. Every row between them has exactly two stars, one on each edge. The left edge walks inward by two columns per row until the middle, then walks back out. The right edge keeps a fixed distance to its right, so the gap stays constant. Write one row from three pieces: leading spaces, a star, a fixed gap, a star.

## Why It Works

1. Stars only ever sit on even columns, so a row is spaces plus two stars.
2. Row i sits at distance d = min(i, n-1-i) from the nearest bar row.
3. The left star lands on column 2d, which gives the pointed in-and-out shape.
4. The right star lands 2n-2 columns further, keeping the arrowhead width fixed.
5. Rows 0 and n-1 have d = 0 and are filled in between, which makes the bars.

| Term | Meaning |
|---|---|
| `arrowHeight` | requested number of rows |
| `rowDistance` | steps from the nearest bar row |
| `barLine` | one solid bar of n stars |
| `spacesOf` | builds a run of spaces |
| `starLine` | builds stars separated by single spaces |

A script-traced example from `gen.py`:

```
height 5, middle row index 2
row 1 stars at columns 2 and 10
gap between them 7 spaces
```

Row 1 is two spaces, a star, seven spaces, a star, which is the sample's second line.

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
`found` marks the end of input, so extra numbers on later lines still work.
Nothing is allocated per token.

**Line builders.** This block makes the two kinds of text a row needs.

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
`starLine` writes star, space, star and stops before a trailing space.
Judge 0.19.4 has no `string * int`, hence the loops.

**Rows and buffered output.** This block prints one arrow per number read.

```nim
var heightFound = false
while true:
  let arrowHeight = nextSignedInt(inputData, scanPos, heightFound)
  if not heightFound:
    break
  if arrowHeight <= 2:
    appendOutput("accept positive integer greater than 2 only!\n")
  else:
    let barLine = starLine(arrowHeight)
    appendOutput(barLine & "\n")
    for rowIndex in 1 ..< (arrowHeight - 1):
      let rowDistance = min(rowIndex, arrowHeight - 1 - rowIndex)
      appendOutput(spacesOf(2 * rowDistance) & "*" & spacesOf(2 * arrowHeight - 3) & "*\n")
    appendOutput(barLine & "\n")
```

`appendOutput` fills a 128 KiB buffer and flushes when full.
The last `stdout.write` emits the final partial block.
The loop runs n-2 times, so no row is built twice.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Arrow build | O(n²) characters per case | one line at a time |
| Output | one write per 128 KiB block | block buffer |

| Measure | Big O |
|---|---|
| Time | O(n²) per case, linear in output size |
| Space | O(input size + block buffer) |

Building the whole picture in a grid and trimming spaces costs the same but keeps n² bytes; the three-piece row keeps only one line live.
