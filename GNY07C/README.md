# GNY07C — Encoding (SPOJ)

<https://www.spoj.com/problems/GNY07C/>

## Problem

Write a short text into a matrix along a clockwise inward spiral, starting at the top-left corner, then send the matrix row by row. Each character becomes five bits: space is 0, A is 1, through Z is 26. Unused cells hold zero.

Input starts with the dataset count. Each dataset gives R, C, and the text on one line. Output one line per dataset: the dataset number, a space, and the R*C bit string in row-major order.

| item | bound |
|---|---|
| datasets N | 1 to 1000 |
| rows R | 1 to 20 |
| columns C | 1 to 20 |
| text length | at most R*C/5 |
| judge limit | 14950 ms, 1536 MB |

The number of cells fixes the output width, so the spiral order drives the design.

Sample input:

```
4
4 4 ACM
5 2 HI
2 6 HI
5 5 HI HO
```

Sample output:

```
1 0000110100101100
2 0110000010
3 010000001001
4 0100001000011010110000010
```

## Idea

Picture a snail crawling inward from the top-left corner; its path is the fill order. Precompute that path once per dataset, drop the five-bit groups onto it, then read the matrix row by row. The spiral walk costs one step per cell, so no cell is visited twice by the fill step. Recomputing a direction at each cell would repeat work and lose the simple index map. A fixed path keeps encoding linear in the matrix size.

## Why It Works

1. Five bits hold every value from 0 to 26.
2. The spiral path visits each cell exactly once.
3. Padding with zeros fills cells after the last character.
4. Row-major reading turns the filled matrix into the sent bit string.

| term | meaning |
|---|---|
| `spiralRows` | row of each cell in spiral order |
| `spiralCols` | column of each cell in spiral order |
| `encodedBits` | five-bit groups plus zero padding |
| `grid` | matrix in row-major storage |

The two index arrays turn one spiral step into one direct write.

A script trace for `4 4 ACM` places bits as follows:

```
bits   00001 00011 01101 0
cells  (0,0)(0,1)(0,2)(0,3)(1,3)(2,3)(3,3)(3,2)
       (3,1)(3,0)(2,0)(1,0)(1,1)(1,2)(2,2)(2,1)
rows   0000
       1101
       0010
       1100
out    1 0000110100101100
```

The last row of the trace is the required first output line.

## Code

**Input and output helpers.** The reader keeps raw lines and parses numbers by hand.

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

proc nextText(data: string, pos: var int): string =
  if pos < data.len and data[pos] == ' ':
    pos += 1
  var text = ""
  while pos < data.len and data[pos] != '\n' and data[pos] != '\r':
    text.add data[pos]
    pos += 1
  return text

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`nextText` keeps spaces inside the message.
`appendOutput` writes only when the buffer reaches its block size.
One final flush ends the stream.

**Spiral path and fill.** Four shrinking boundaries produce the clockwise path.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  let message = nextText(inputData, scanPos)
  let cellCount = rowCount * columnCount
  var spiralRows = newSeq[int](cellCount)
  var spiralCols = newSeq[int](cellCount)
  var cellIndex = 0
  var topRow = 0
  var leftCol = 0
  var bottomRow = rowCount - 1
  var rightCol = columnCount - 1
  while topRow <= bottomRow and leftCol <= rightCol:
    var col = leftCol
    while col <= rightCol:
      spiralRows[cellIndex] = topRow
      spiralCols[cellIndex] = col
      cellIndex += 1
      col += 1
    topRow += 1
    var row = topRow
    while row <= bottomRow:
      spiralRows[cellIndex] = row
      spiralCols[cellIndex] = rightCol
      cellIndex += 1
      row += 1
    rightCol -= 1
    if topRow <= bottomRow:
      col = rightCol
      while col >= leftCol:
        spiralRows[cellIndex] = bottomRow
        spiralCols[cellIndex] = col
        cellIndex += 1
        col -= 1
      bottomRow -= 1
    if leftCol <= rightCol:
      row = bottomRow
      while row >= topRow:
        spiralRows[cellIndex] = row
        spiralCols[cellIndex] = leftCol
        cellIndex += 1
        row -= 1
      leftCol += 1
```

The boundary guards handle a single row or column.
Each cell receives one pair of coordinates.
The path length equals `cellCount`.

**Bit groups and output.** Bits follow the path and the grid is sent in order.

```nim
  var encodedBits = ""
  for charIndex in 0 .. message.len - 1:
    let letter = message[charIndex]
    var value = 0
    if letter == ' ':
      value = 0
    else:
      value = int(letter) - 64
    for bitIndex in 0 .. 4:
      let bitValue = (value div (1 shl (4 - bitIndex))) mod 2
      encodedBits.add chr(48 + bitValue)
  while encodedBits.len < cellCount:
    encodedBits.add '0'
  var grid = newSeq[char](cellCount)
  for index in 0 .. cellCount - 1:
    grid[index] = '0'
  for index in 0 .. cellCount - 1:
    let cell = spiralRows[index] * columnCount + spiralCols[index]
    grid[cell] = encodedBits[index]
  var line = $caseIndex & " "
  for index in 0 .. cellCount - 1:
    line.add grid[index]
  line.add '\n'
  appendOutput(line)

stdout.write outputBuffer
outputBuffer.setLen 0
```

Five shifts emit high bits first.
Zeros fill cells left after the message.
The line is appended once, not per bit.

## Complexity

The spiral path and the bit fill both scale with the matrix size.

| phase | time | space |
|---|---|---|
| input read | one pass over dataset lines | one input string |
| spiral path | one visit per cell | two index arrays |
| encode and output | one write per dataset line | one bit string and grid |

Each dataset spends time proportional to the product of its dimensions.

| measure | Big O |
|---|---|
| time | O(N * R * C) |
| space | O(R * C) |

A walker that searched for a free neighbor at every step would still be linear but harder to map back to cells; the precomputed path keeps each write direct.
