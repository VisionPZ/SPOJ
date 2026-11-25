# STARJUST — Star Justify (SPOJ)

<https://www.spoj.com/problems/STARJUST/>

## Problem

Pad each string with stars on both sides until it fills a given width. Put the string in the centre; when the two paddings differ, give the larger one to the left.

Input: first line T, the number of cases. Each case uses two lines: first the width, then the string. Output: one padded string per case, on its own line.

| item | bound |
|---|---|
| cases | given by first line |
| width and string | supplied per case |
| judge limit | 1000 ms, 1536 MB |

Strings can contain spaces, so each string line is read whole and kept unchanged.

The sample input:

```
3
10
hello
10
milk
30
to be, or not to be
```

The sample output:

```
***hello**
***milk***
******to be, or not to be*****
```

## Idea

Think of hanging a picture on a wall, then filling the empty space with equal stacks of stars on each side. The leftover star goes on the left when the gap is odd. Compute the left and right padding once per case, then append stars, the text, and stars. This costs O(W) time for width W and needs no array of slots. Filling a temporary array of width cells costs the same time but extra space. Keep the shorter padding on the right.

## Why It Works

1. The total gap is the width minus the string length.
2. Dividing the gap into two halves with one extra for the left gives ceil(gap/2) stars on the left.
3. The remaining stars go on the right, so the output length equals the width.
4. Reading the text as a raw line keeps spaces and trailing blanks intact.

| term | meaning |
|---|---|
| `fieldWidth` | number of characters in one output line |
| `textLine` | the raw string to centre |
| `totalPadding` | field width minus string length |
| `leftPadding` | total padding rounded up, written first |
| `rightPadding` | total padding rounded down, written last |

The two paddings always add back to the total gap.

A trace from the generator with visible counts:

```
width 10, text hello (5): gap 5, left 3, right 2 -> ***hello**
width 10, text milk  (4): gap 6, left 3, right 3 -> ***milk***
width 30, text 19 chars   : gap 11, left 6, right 5 -> six stars, text, five stars
```

The odd gap in the first and third cases places the extra star on the left.

## Code

**Input and buffered output.** Widths come from the scanner, while text comes from raw lines.

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

proc nextRawLine(data: string, pos: var int): string =
  if pos >= data.len:
    return ""
  var lineEnd = pos
  while lineEnd < data.len and data[lineEnd] != '\n':
    lineEnd += 1
  let rawText = data[pos .. lineEnd - 1]
  pos = lineEnd + 1
  return rawText

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The rest of each numeric line is discarded before the following text line.
Raw line reads preserve every internal and trailing space.
The output buffer flushes in blocks instead of once per star.

**Padding loop.** Each case writes left stars, the text, then right stars.

```nim
let caseCount = nextInt(inputData, scanPos)
discard nextRawLine(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let fieldWidth = nextInt(inputData, scanPos)
  discard nextRawLine(inputData, scanPos)
  let textLine = nextRawLine(inputData, scanPos)
  let totalPadding = fieldWidth - textLine.len
  let leftPadding = (totalPadding + 1) div 2
  let rightPadding = totalPadding div 2
  var starIndex = 0
  while starIndex < leftPadding:
    appendOutput("*")
    starIndex += 1
  appendOutput(textLine)
  starIndex = 0
  while starIndex < rightPadding:
    appendOutput("*")
    starIndex += 1
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

A text longer than the width produces no stars and prints the text itself.
The extra from an odd gap goes to the left padding by rounding up.
Each case ends with one newline in the shared output buffer.

## Complexity

Each output character is produced once.

| phase | time | space |
|---|---|---|
| input read | one pass over the input | one input string |
| padding | one star or text character per output position | constant |
| output | block writes | block buffer |

No temporary array of width cells is needed.

| measure | Big O |
|---|---|
| time | O(total output characters) |
| space | O(total input characters) |

Filling a temporary array would match this time but add width-sized space per case; direct appends avoid it.
