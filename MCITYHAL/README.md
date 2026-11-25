# MCITYHAL — Repair City Hall (SPOJ)

<https://www.spoj.com/problems/MCITYHAL/>

## Problem

Fill the damaged cells of a binary wall with vertical blocks of width one and arbitrary height, using the fewest blocks. Report how many blocks of each height the optimal filling needs.

Input contract: one case with M and N, followed by M strings of N characters, where 1 marks intact cells and 0 marks damage. Output contract: print one line per used height, in ascending height order, as the height and its block count.

The bounds from the statement:

| item | bound |
|---|---|
| rows M | 1 to 200 |
| columns N | 1 to 200 |
| judge limit | 1000 ms, 1536 MB |

A block stays inside one column, so columns can be solved one at a time.

Sample input:

```
5 10
1110000111
1100001111
1000000011
1111101111
1110000111
```

Sample output:

```
1 7
2 1
3 2
5 1
```

## Idea

Read each column like a stack of empty slots and put one block into every unbroken run of damaged cells. The algorithm scans columns top to bottom and counts the lengths of maximal runs of zeros. Each cell is visited once, so the work is O(M times N). Splitting a run into smaller blocks would add blocks without covering more cells, so one block per run is optimal. One pass over the grid gives every height count.

## Why It Works

1. A block occupies consecutive rows of one column, so it cannot cross an intact cell.
2. Damaged cells between intact cells form separate runs in that column.
3. One block of the run length covers the whole run at once.
4. Fewer than one block per run cannot cover the run.
5. Counting run lengths over all columns gives the minimum block multiset.

The terms used in the scan:

| term | meaning |
|---|---|
| `wallRows` | the M strings that describe the wall |
| `currentRun` | length of the zero run open at the current row |
| `runLengthCounts` | number of runs recorded for each height |
| `blockHeight` | height printed on one output line |

The run resets at every intact cell, which keeps runs maximal.

A traced pair of columns from the sample:

```
column 4:  0 0 0 1 0   runs [3, 1]   blocks 3 and 1
column 6:  0 0 0 0 0   runs [5]      block 5
totals:    height 1 -> 7, height 2 -> 1, height 3 -> 2, height 5 -> 1
```

Those totals match the sample output exactly.

## Code

**Input and token reader.** The header integers and the wall strings are read from one buffer.

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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let start = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  return data[start ..< pos]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The integer scanner skips line breaks between fields.
The token reader keeps each wall row intact.
Output is collected into one block buffer.

**Run detection.** Every column contributes its maximal zero runs.

```nim
let rowCount = nextInt(inputData, scanPos)
let columnCount = nextInt(inputData, scanPos)
var wallRows = newSeq[string](rowCount)
for rowIndex in 0 .. rowCount - 1:
  wallRows[rowIndex] = nextToken(inputData, scanPos)

var runLengthCounts = newSeq[int](rowCount + 1)
for columnIndex in 0 .. columnCount - 1:
  var currentRun = 0
  for rowIndex in 0 .. rowCount - 1:
    if wallRows[rowIndex][columnIndex] == '0':
      currentRun += 1
    else:
      if currentRun > 0:
        runLengthCounts[currentRun] += 1
        currentRun = 0
  if currentRun > 0:
    runLengthCounts[currentRun] += 1
```

The last row closes a run that reaches the wall bottom.
An intact cell closes any open run at once.
Counts are indexed directly by height.

**Ordered output.** Only heights with a positive count are printed.

```nim
for blockHeight in 1 .. rowCount:
  if runLengthCounts[blockHeight] > 0:
    appendOutput($(blockHeight) & " " & $(runLengthCounts[blockHeight]))
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop visits heights in ascending order.
Empty heights produce no line.
The buffer flushes once at the end.

## Complexity

The grid scan is the only pass over the data.

| phase | time | space |
|---|---|---|
| input read | one pass over all row strings | row strings and input buffer |
| run detection | one visit per grid cell | one count per height |
| output | one line per used height | block buffer |

Each cell is inspected once, so the grid size sets the cost.

| measure | Big O |
|---|---|
| time | O(M times N) |
| space | O(M plus N) |

Testing every possible set of blocks would grow far faster than this single scan.
The run count gives the optimal filling directly.
