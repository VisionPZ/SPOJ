# AR1NHAPINMANG — InputOutut Array 2D (SPOJ)

<https://www.spoj.com/problems/AR1NHAPINMANG/>

## Problem

Read the dimensions of a matrix, then read its values, and print the matrix back with tabs between values in each row. The statement pastes its sample with rows joined, so the three source lines are shown below.

The first line holds two integers, the row count and the column count. The next values fill the rows in reading order. The output has one line per row, with a tab between neighboring values.

| item | bound |
|---|---|
| row count | positive integer |
| column count | positive integer |
| values | integers, read in row order |
| judge limit | 1000 ms, 1536 MB |

The value count drives the loop that prints the matrix.

The sample input:

```
2 3
1 2 3
4 5 6
```

The sample output:

```
1	2	3
4	5	6
```

The tabs above are real tab characters, as the statement requires.

## Idea

Treat the input as one long stream of numbers and remember the column count. A counter tells you when a row is full, so you write a newline at that point. This is like dealing cards into fixed-size hands: the deck is read in order, and each hand ends after a known number of cards.

The algorithm is a hand scanner plus a nested loop. Each value costs one parse and one append, so the work is linear in the number of cells. Rebuilding rows by slicing text or copying subarrays would add extra passes over the same values.

One stream, one column counter, and one buffered row solve the whole matrix.

## Why It Works

1. The first two parsed values give the row count and column count.
2. The values that follow belong to rows in reading order.
3. A tab separates two values inside the same row.
4. A newline closes a row after exactly column count values.
5. Buffering a whole row before writing keeps the output path simple.

| term | meaning |
|---|---|
| `rowCount` | number of rows to print |
| `columnCount` | number of values in one row |
| `cellValue` | one parsed matrix value |
| `rowText` | the buffered text of the current row |

The two counts define the shape of the output and the loop bounds.

A script trace of the sample shows how the stream maps to rows. The counter resets at each newline in the output.

```
stream position:  0  1  2  3  4  5  6  7
parsed value:     2  3  1  2  3  4  5  6
role:             r  c  v  v  v  v  v  v
row 1 cells:      1  2  3
row 2 cells:      4  5  6
```

The trace gives the same two tab-separated rows as the sample answer.

Values are parsed with a digit scanner, so negative signs are not consumed. The statement only uses non-negative integers.

## Code

**Input and output setup.** The reader loads stdin and defines the hand integer scanner and block writer.

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

var outputBuffer = ""
```

The scanner skips spaces and newlines before each number.
It builds values one digit at a time without conversion calls.
The buffer is shared by every row of the matrix.

**Row writer.** The nested loop assembles each row and appends its newline.

```nim
proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let rowCount = nextInt(inputData, scanPos)
let columnCount = nextInt(inputData, scanPos)
for rowIndex in 0 .. rowCount - 1:
  var rowText = ""
  for columnIndex in 0 .. columnCount - 1:
    let cellValue = nextInt(inputData, scanPos)
    if columnIndex > 0:
      rowText.add '\t'
    rowText.add $cellValue
  appendOutput(rowText)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The tab is added only after the first value of a row.
Each row is appended once, then closed with a newline.
The final flush emits any remaining buffered bytes.

## Complexity

The program parses each cell once and builds one output row per input row.

| phase | time | space |
|---|---|---|
| input read | one pass over all lines | one input string |
| matrix parse | one scan over all cell values | no extra storage |
| output | one append per row | one row string |

Each cell is visited once during parsing and once while being written.

| measure | Big O |
|---|---|
| time | O(R times C) for R rows and C columns |
| space | O(L) for input plus one row string |

Reading and writing cell by cell keeps the work linear in the cell count.
A single buffered row avoids many small writes.
