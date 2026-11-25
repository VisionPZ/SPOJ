# AARTDARK — Ascii Art Darkness Calculator (SPOJ)

<https://www.spoj.com/problems/AARTDARK/>

## Problem

Small ASCII pictures use an asterisk for a dark pixel and a dot for a bright pixel. Report the fraction of dark pixels in each picture.

The input starts with the picture count. Each picture gives its side length, then one character per pixel. Print one fraction per picture.

| item | bound |
|---|---|
| side length | not stated |
| pixel characters | `*` and `.` |
| judge limit | 1000 ms, 1536 MB |

The picture is square, so pixel count is the side squared.

Sample input:

```
2
2
...*
8
..................*..*...........*....*...****..................
```

Sample output:

```
0.25
0.125
```

## Idea

Count dark cells and divide, like tallying shaded squares on a grid sheet. The side length gives the total cell count directly. Scan each picture's characters once and count asterisks. One division turns that count into the required darkness value.

## Why It Works

1. A square of side k holds exactly k squared pixels.
2. Every pixel contributes either one dark mark or none.
3. Darkness is the dark pixel count divided by the pixel total.
4. Floating division with short decimal output reproduces the sample values.

| term | meaning |
|---|---|
| `sideLength` | length of one side of the square picture |
| `pixelCount` | total cells, side squared |
| `darkPixels` | number of asterisk characters |

Characters are read one at a time, so line breaks do not matter.

Script-generated trace for the first sample picture:

```
quantity | value
side | 2
pixel count | 4
dark pixels | 1
darkness | 1 / 4 = 0.25
```

The value matches the first sample line.

## Code

**Bulk input and scanners.** The whole stream is read once; integers and pixels use separate cursors.

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

proc nextPixel(data: string, pos: var int): char =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  result = data[pos]
  pos += 1
```

The integer scanner skips pixel characters.
The pixel scanner skips whitespace only.
Both walk one shared input buffer.

**Dark pixel count and output.** Each picture costs one pass over its cells.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let imageCount = nextInt(inputData, scanPos)
for imageIndex in 0 .. imageCount - 1:
  let sideLength = nextInt(inputData, scanPos)
  let pixelCount = sideLength * sideLength
  var darkPixels = 0
  for pixelIndex in 0 .. pixelCount - 1:
    let pixelValue = nextPixel(inputData, scanPos)
    if pixelValue == '*':
      darkPixels += 1
  appendOutput($(float(darkPixels) / float(pixelCount)))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop reads exactly side squared cells.
Only the dark count is accumulated.
Each picture writes one buffered line.

## Complexity

One pass over all pixels serves the whole input.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| pixel count | one character per pixel | a few counters |
| output | one line per picture | block buffer |

No picture grid is stored.

| measure | Big O |
|---|---|
| time | O(total pixels) |
| space | O(input bytes) |

Counting twice or storing rows would add work without changing the answer.
