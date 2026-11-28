# FUCT_FOR_RHOMBUS — Rhombus (SPOJ)

<https://www.spoj.com/problems/FUCT_FOR_RHOMBUS/>

## Problem

Read a side length and print a rhombus of stars outlined by two diagonal edges. The figure has 2n-1 rows. The top and bottom rows are one star each, and the middle row is the widest. Stars sit on every other column.

| Item | Bound |
|---|---|
| Side length | 0 < n ≤ 100 |
| Rows per rhombus | 2n - 1 |
| Judge limit | 1000 ms, 1536 MB |

The sample case:

```
3
```

```
    *
  *   *
*       *
  *   *
    *
```

## Idea

Each row has at most two stars, one on the left edge and one on the right edge. Measure how far a row is from the nearest pointy end. That distance grows by one each row down to the middle, then shrinks back. The left star moves two columns left per step while the right star moves two columns right. Each row is built from spaces, a star, a gap, and a star.

## Why It Works

1. Row i sits at distance d = min(i, 2n-2-i) from the nearest tip.
2. The left star lands on column 2(n-1-d), which walks in then out.
3. The right star lands on column 2(n-1)+2d, which mirrors it.
4. At the tips d = 0, both columns are the same, so one star is printed.
5. Every row ends on a star, so no line needs trimming.

| Term | Meaning |
|---|---|
| `sideLength` | requested rhombus side |
| `rowCount` | 2n-1 rows in the figure |
| `rowDistance` | steps from the nearest tip row |
| `leftIndex` | column of the left star |
| `rightIndex` | column of the right star |

A script-traced example from `gen.py`:

```
side 3, row count 5
middle row stars at columns 0 and 8
top row single star at column 4
```

The middle row is a star, seven spaces, a star, which is the sample's third line.

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
`found` marks the end of input, so several sides in one file all print.
Nothing is allocated per token.

**Space runs.** This block builds the only text a row needs besides stars.

```nim
proc spacesOf(count: int): string =
  var builtLine = newString(count)
  var fillIndex = 0
  while fillIndex < count:
    builtLine[fillIndex] = ' '
    fillIndex += 1
  return builtLine
```

`newString` reserves the exact length, so no growing happens.
Judge 0.19.4 has no `string * int`, hence the loop.

**Rows and buffered output.** This block prints one rhombus per number read.

```nim
var sideFound = false
while true:
  let sideLength = nextSignedInt(inputData, scanPos, sideFound)
  if not sideFound:
    break
  if sideLength <= 0:
    appendOutput("\n")
  else:
    let rowCount = 2 * sideLength - 1
    for rowIndex in 0 ..< rowCount:
      let rowDistance = min(rowIndex, rowCount - 1 - rowIndex)
      let leftIndex = 2 * (sideLength - 1 - rowDistance)
      let rightIndex = 2 * (sideLength - 1) + 2 * rowDistance
      if leftIndex == rightIndex:
        appendOutput(spacesOf(leftIndex) & "*\n")
      else:
        appendOutput(spacesOf(leftIndex) & "*" & spacesOf(rightIndex - leftIndex - 1) & "*\n")
```

`appendOutput` fills a 128 KiB buffer and flushes when full.
The last `stdout.write` emits the final partial block.
The `leftIndex == rightIndex` test handles the two single-star tip rows.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Rhombus build | O(n²) characters per case | one line at a time |
| Output | one write per 128 KiB block | block buffer |

| Measure | Big O |
|---|---|
| Time | O(n²) per case, linear in output size |
| Space | O(input size + block buffer) |

Filling a 2n-1 by 4n-3 grid and trimming each row costs the same time but stores about four times as many characters.
