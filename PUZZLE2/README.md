# PUZZLE2 — Puzzle (SPOJ)

<https://www.spoj.com/problems/PUZZLE2/>

## Problem

Decide whether a pebble grid can be changed into a target grid using row flips and column swaps. A black button flips every pebble in one row. Two white buttons exchange two whole columns.

Input begins with K blocks. Each block gives N and M, then N rows of initial colors, one blank line, and N rows of final colors. Colors are the words BLUE and RED. Print YES or NO on one line per block.

| item | bound |
|---|---|
| blocks K | not bounded explicitly |
| rows N | 1 to 100 |
| columns M | 1 to 100 |
| judge limit | 500 ms, 1536 MB |

Rows are interchangeable only through flips; columns are freely permutable.

Sample input:

```
2
3 4
BLUE RED BLUE RED
RED BLUE BLUE RED
BLUE BLUE BLUE BLUE

BLUE RED BLUE RED
RED RED BLUE BLUE
BLUE BLUE BLUE BLUE
2 2
BLUE BLUE
BLUE RED

RED RED
RED RED
```

Sample output:

```
YES
NO
```

## Idea

Treat each column as a stack of bits, like a column of coins that can be turned over as a whole. A row flip turns every coin in that row, so it changes a column into its complement. A column swap only moves whole stacks. Therefore two grids match when each initial stack equals some final stack or its complement. The algorithm canonicalizes each stack by choosing the smaller of the stack and its complement, then sorts both lists. Each block costs O(N M log M). Searching all column permutations would cost factorial time. Takeaway: compare stacks up to complement, then up to order.

## Why It Works

1. Write BLUE as 1 and RED as 0, so a row flip toggles every bit in a row.
2. Flipping a set of rows turns one column vector into either itself or its bitwise complement.
3. Column swaps realize any permutation, because adjacent swaps generate all permutations.
4. A transform exists exactly when the initial column vectors match the final column vectors up to complement and reordering.
5. Mapping each vector to the smaller of itself and its complement makes the match a plain multiset comparison.

| term | meaning |
|---|---|
| `initialColumns` | bit strings of the starting columns |
| `finalColumns` | bit strings of the target columns |
| `canonicalColumn` | smaller of a column and its complement |
| `transformable` | whether both sorted lists agree |

The table names the values used by the comparison.

In the first sample block the four canonical columns match after sorting. In the second block the target columns are both all RED, while the starting columns are not, so the answer is NO.

Both sample answers follow from canonical column lists.

## Code

**Input and scanning.** The reader loads colors through a hand scanner made for the words BLUE and RED.

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

proc nextColor(data: string, pos: var int): char =
  while pos < data.len and data[pos] != 'B' and data[pos] != 'R':
    pos += 1
  let foundColor = data[pos]
  pos += 1
  return foundColor

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The color scanner stops at the first B or R.
Blank lines are skipped as ordinary separators.
Output is collected in one block buffer.

**Column helpers.** Each column is reduced to a canonical bit string.

```nim
proc canonicalColumn(column: string): string =
  var complement = newSeq[char](column.len)
  for bitIndex in 0 .. column.len - 1:
    if column[bitIndex] == '1':
      complement[bitIndex] = '0'
    else:
      complement[bitIndex] = '1'
  var complementText = ""
  for bitIndex in 0 .. column.len - 1:
    complementText.add complement[bitIndex]
  if complementText < column:
    return complementText
  return column

proc sortColumns(columns: var seq[string]) =
  for rightIndex in 1 .. columns.len - 1:
    let carriedColumn = columns[rightIndex]
    var leftIndex = rightIndex - 1
    while leftIndex >= 0 and columns[leftIndex] > carriedColumn:
      columns[leftIndex + 1] = columns[leftIndex]
      leftIndex -= 1
    columns[leftIndex + 1] = carriedColumn
```

The complement flips every bit of the column.
The smaller of the two strings is the canonical key.
Insertion sort orders at most 100 keys.

**Block comparison.** Both grids are read column by column and compared.

```nim
let blockCount = nextInt(inputData, scanPos)
for blockIndex in 0 .. blockCount - 1:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  var initialColumns = newSeq[string](columnCount)
  var finalColumns = newSeq[string](columnCount)
  for columnIndex in 0 .. columnCount - 1:
    initialColumns[columnIndex] = ""
    finalColumns[columnIndex] = ""
  for rowIndex in 0 .. rowCount - 1:
    for columnIndex in 0 .. columnCount - 1:
      let pebbleColor = nextColor(inputData, scanPos)
      if pebbleColor == 'B':
        initialColumns[columnIndex].add '1'
      else:
        initialColumns[columnIndex].add '0'
  for rowIndex in 0 .. rowCount - 1:
    for columnIndex in 0 .. columnCount - 1:
      let pebbleColor = nextColor(inputData, scanPos)
      if pebbleColor == 'B':
        finalColumns[columnIndex].add '1'
      else:
        finalColumns[columnIndex].add '0'
  for columnIndex in 0 .. columnCount - 1:
    initialColumns[columnIndex] = canonicalColumn(initialColumns[columnIndex])
    finalColumns[columnIndex] = canonicalColumn(finalColumns[columnIndex])
  sortColumns(initialColumns)
  sortColumns(finalColumns)
  var transformable = true
  for columnIndex in 0 .. columnCount - 1:
    if initialColumns[columnIndex] != finalColumns[columnIndex]:
      transformable = false
      break
  if transformable:
    appendOutput("YES\n")
  else:
    appendOutput("NO\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

Each grid is read row by row into column strings.
Canonical keys are sorted before the equality check.
One answer line is appended per block.

## Complexity

Each block scans its two grids once.

| phase | time | space |
|---|---|---|
| input read | one pass over 2 N M colors | one input string |
| canonicalization | one complement per column | two column arrays |
| sorting and compare | two sorts of M keys | two key arrays |

The two column arrays hold N M bits in total.

| measure | Big O |
|---|---|
| time per block | O(N M log M) |
| space per block | O(N M) |

Trying every column permutation would cost O(M!) time. Canonical keys reduce the decision to two sorts.
