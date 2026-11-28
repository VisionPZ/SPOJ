# GNY07D — Decoding (SPOJ)

<https://www.spoj.com/problems/GNY07D/>

## Problem

Read a bit matrix row by row, follow a clockwise inward spiral from the top-left corner, and turn each five-bit group into a character. Zero means space, 1 means A, through 26 means Z. Drop trailing spaces and any group with fewer than five bits.

Input starts with the dataset count. Each dataset gives R, C, and R*C bits on one line. Output one line per dataset: the dataset number, a space, and the decoded text.

| item | bound |
|---|---|
| datasets N | 1 to 1000 |
| rows R | 1 to 20 |
| columns C | 1 to 20 |
| bit string length | R*C |
| judge limit | 19860 ms, 1536 MB |

The matrix size bounds the work, so one path per dataset is enough.

Sample input:

```
4
4 4 0000110100101100
5 2 0110000010
2 6 010000001001
5 5 0100001000011010110000010
```

Sample output:

```
1 ACM
2 HI
3 HI
4 HI HO
```

## Idea

Think of the spiral as a thread laid over the matrix; pull the bits off in that order. Build the same top-left clockwise path used for encoding, group the pulled bits in fives, and map each group to a letter. Scanning the matrix directly would read bits in the wrong order. The path costs one index pair per cell, so decoding stays linear in the matrix size.

## Why It Works

1. The sender fills cells along the clockwise top-left spiral.
2. Reading that spiral recovers the original bit stream.
3. Five bits give one value from 0 to 26.
4. Groups past the last full five bits are padding and are dropped.
5. Padding values of zero become trailing spaces, which are removed.

| term | meaning |
|---|---|
| `spiralRows` | row of each cell in spiral order |
| `spiralCols` | column of each cell in spiral order |
| `groupValue` | accumulated value of the current five-bit group |
| `decoded` | recovered text before trailing spaces are removed |

One spiral index turns a row-major bit into the next stream bit.

A script trace for the first dataset gives:

```
input  4 4 0000110100101100
grid   0000
       1101
       0010
       1100
spiral 00001 00011 01101 0
values 1 3 13 and a partial group
chars  A C M
out    1 ACM
```

The trace shows the same bit stream used by the encoder, so the message is recovered exactly.

## Code

**Input and output helpers.** Raw lines are kept once and numbers are scanned by hand.

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

proc nextBits(data: string, pos: var int): string =
  if pos < data.len and data[pos] == ' ':
    pos += 1
  var bits = ""
  while pos < data.len and data[pos] != '\n' and data[pos] != '\r':
    if data[pos] == '0' or data[pos] == '1':
      bits.add data[pos]
    pos += 1
  return bits

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`nextBits` ignores the separator and keeps only binary digits.
`appendOutput` collects lines before writing to stdout.
The final flush ends the stream.

**Spiral path.** Four shrinking boundaries list the cells in fill order.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  let receivedBits = nextBits(inputData, scanPos)
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

The guards cover one-row and one-column matrices.
Each cell is stored exactly once.
The loops cost one step per cell.

**Group bits and clean the text.** Full groups become characters; padding is removed.

```nim
  var decoded = ""
  var groupValue = 0
  var groupBits = 0
  for index in 0 .. cellCount - 1:
    let cell = spiralRows[index] * columnCount + spiralCols[index]
    if cell < receivedBits.len:
      groupValue = groupValue * 2
      if receivedBits[cell] == '1':
        groupValue += 1
      groupBits += 1
      if groupBits == 5:
        if groupValue == 0:
          decoded.add ' '
        else:
          decoded.add chr(64 + groupValue)
        groupValue = 0
        groupBits = 0
  while decoded.len > 0 and decoded[decoded.len - 1] == ' ':
    decoded.setLen decoded.len - 1
  var line = $caseIndex & " " & decoded & "\n"
  appendOutput(line)

stdout.write outputBuffer
outputBuffer.setLen 0
```

Partial groups never produce a character.
Trailing zero groups are removed after decoding.
Interior spaces stay in the recovered message.

## Complexity

Both the path and the grouping pass visit each cell once.

| phase | time | space |
|---|---|---|
| input read | one pass over dataset lines | one input string |
| spiral path | one visit per cell | two index arrays |
| decode and output | one pass over bits | decoded text plus buffer |

Work per dataset follows the matrix size alone.

| measure | Big O |
|---|---|
| time | O(N * R * C) |
| space | O(R * C) |

Reading the matrix row by row without the spiral would pair the wrong bits and change every character; the path keeps the mapping exact.
