# LANDPLAN — Aby and Land Plan (SPOJ)

<https://www.spoj.com/problems/LANDPLAN/>

## Problem

Draw a square frame of side `N` with `#` on the border and `.` inside. Print one frame per test case, followed by a blank line.

The first input line holds the number of test cases, `T`. Each following line holds one side length `N`. For `N = 1`, the frame is a single `#`. For `N = 2`, all four cells are `#`.

| item | bound |
|---|---|
| test cases `T` | not stated; small |
| side length `N` | 1 to 100 |
| judge limit | 1000 ms, 1536 MB |

Rows are printed top to bottom. Columns are printed left to right.

Sample input:

```
3
1
2
5
```

Sample output:

```
#

##
##

#####
#...#
#...#
#...#
#####

```

Each frame ends with its own blank line, including the last one.

## Idea

The frame has only two row types, like a picture made from two reusable stamps. Build the top row and the middle row once, then print them the right number of times. A fresh scan of every cell would repeat the same border check thousands of times. Two prepared rows turn each case into one print loop. Print the bottom row only when `N` is at least two.

## Why It Works

1. The top and bottom rows are `N` copies of `#`.
2. A middle row is `#`, then `N-2` copies of `.`, then `#`.
3. There are `N-2` middle rows, so they vanish when `N` is one or two.
4. Printing the prepared rows in order reproduces every cell.
5. A blank line closes the case, as the sample shows.

| term | meaning |
|---|---|
| `sideLength` | `N`, the square side length |
| `borderRow` | the prepared top row |
| `innerRow` | the prepared middle row |
| `rowIndex` | row counter for the middle rows |

The generator draws the case `N = 5` cell by cell. It gets `#####`, then three copies of `#...#`, then `#####`. The prepared rows reproduce that same picture.

## Code

**Input and scanning.** The hand reader collects all lines into one buffer.

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
```

The scanner ignores line breaks and spaces.
It reads one side length for each case.
The whole input is in memory before drawing starts.

**Row templates and printing.** Two prepared strings supply every row.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let sideLength = nextInt(inputData, scanPos)
  var borderRow = ""
  for columnIndex in 1 .. sideLength:
    borderRow.add '#'
  var innerRow = "#"
  for columnIndex in 2 .. sideLength - 1:
    innerRow.add '.'
  if sideLength >= 2:
    innerRow.add '#'
  appendOutput(borderRow)
  outputBuffer.add '\n'
  for rowIndex in 2 .. sideLength - 1:
    appendOutput(innerRow)
    outputBuffer.add '\n'
  if sideLength >= 2:
    appendOutput(borderRow)
    outputBuffer.add '\n'
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The middle loop is empty for the two smallest sizes.
The bottom row is skipped for a single cell.
Every case appends exactly one closing blank line.

## Complexity

Each case builds two rows and prints all `N` rows.

| phase | time | space |
|---|---|---|
| input read | one pass over `T` sizes | one input string |
| row build | O(N) work for two rows | two strings of length `N` |
| printing | N row writes | block buffer |
| output | one flush at the end | block buffer |

| measure | Big O |
|---|---|
| time per case | O(N^2) characters |
| space per case | O(N) |

Testing every cell separately gives the same O(N^2) characters but repeats border decisions.

Preparing two rows keeps the decisions to a constant count.
