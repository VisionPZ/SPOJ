# LANDPLAN — Aby and Land Plan (SPOJ)

<https://www.spoj.com/problems/LANDPLAN/>

## Problem

For each test, draw a square plot of side N made of `#` border rows and columns with `.` filling the interior. A blank line separates the plots.

The first line holds T, the number of cases. Each of the next T lines holds one side length N with 1 ≤ N ≤ 100.

| item | bound |
|---|---|
| side length N | 1 ≤ N ≤ 100 |
| judge limit | 1000 ms, 1536 MB |

Output size grows with N^2, so the drawing itself is the work.

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

## Idea

A picture frame needs two full rows and, between them, rows with two nails and empty space. The program builds one border row and one inner row per case, then prints them in the right order.

Reusing the same two row strings avoids rebuilding text for every line. A blank line after each plot keeps the cases apart.

Takeaway: build two row templates, then repeat them.

## Why It Works

1. The top and bottom rows are N copies of `#`.
2. An inner row is `#`, then N-2 dots, then `#`, so only the border columns are filled.
3. For N = 1 the single character `#` is both border and row, and the code prints it alone.
4. For N = 2 there is no interior, so two full rows appear.
5. A trailing blank line after each case matches the sample spacing.

For the sample, the 5 case prints a full row, three inner rows, a full row, then a blank line.

The N = 1 case has no inner row and no bottom row, which the guards handle.

## Code

**Input and scanning.** The hand reader loads the file and parses integers.

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

The scanner skips spaces and newlines.
Every value is positive, so no minus branch is needed.

**Buffered output.** One string collects all the drawing lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Large outputs flush in blocks.
One final write closes the remaining text.

**Row templates.** Two strings describe every line of a plot.

```nim
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
```

The border row is N hashes.
The inner row keeps hashes only at its ends.

**Drawing.** The templates are written in order.

```nim
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

The top row always prints.
Inner rows print only when N ≥ 3.
The bottom row prints only when N ≥ 2.
The final newline of each case is the separating blank line.

## Complexity

Each case writes N rows of N characters.

| phase | time | space |
|---|---|---|
| read input | one pass over the file | one string |
| draw | N rows per case | two row strings |
| output | one block buffer | block buffer |

| measure | Big O |
|---|---|
| time | O(total N^2) |
| space | O(N) |

Rebuilding each row from scratch per line would multiply string work.

Takeaway: two templates draw the whole square.
