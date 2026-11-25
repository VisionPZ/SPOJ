# CINECOVI — Cinema seating, covid 19 version (SPOJ)

<https://www.spoj.com/problems/CINECOVI/>

## Problem

Groups of friends take consecutive seats in a cinema grid. Each group needs an empty seat beside it, and occupied rows have one empty row between them.

The first line gives the row count and the seats per row. Every later integer is the size of one group, in booking order. Output the label `Seats:` followed by the whole grid, with rows printed from back to front. When groups cannot sit, append `Failed to seat:` followed by their sizes with no separators.

| item | bound |
|---|---|
| rows | positive integer |
| seats per row | positive integer |
| group sizes | positive integers |
| judge limit | 1000 ms, 1536 MB |

The sample uses 5 rows of 20 seats and 15 booked groups.

Sample input:

```
5 20 7 9 8 7 6 5 4 3 2 1 9 2 11 4 8
```

Sample output:

```
Seats:1111110111110111100000000000000000000000111111110111111100000000000000000000000011111110111111111000Failed to seat:321921148
```

Here the first seven groups sit and the remaining eight are turned away.

## Idea

Filling shelves gives the same picture: put each box on the left, leave one slot, then skip a shelf. A cursor walks the seats of one row and jumps two rows when the current row runs out. The algorithm is a greedy placement simulation. Trying every possible block for every group wastes time on positions the cursor already passed. Fill in booking order, then print the grid in reverse row order.

## Why It Works

1. A group occupies consecutive free seats starting at the cursor.
2. The cursor advances past the group and one empty seat.
3. When the group no longer fits, the next usable row is two rows back.
4. That skipped row supplies the empty row behind the group.
5. The first group without a row ends the seating, and all later groups fail.

| term | meaning |
|---|---|
| `seatGrid` | one string of zeros and ones per row |
| `currentRow` | row where the next group is tried |
| `nextColumn` | first free column in that row |
| `firstFailedIndex` | position of the first group turned away |

For a 3 by 10 cinema and groups 5, 4, 3, 2, 1, the front row becomes 1111101111. Row two stays 0000000000. The back row becomes 1110110100. Printing back to front gives 1110110100, then 0000000000, then 1111101111, which matches the sample.

The grid starts as zeros, so no guard is needed for empty rows.

## Code

**Input and scanning.** The reader stores the group sizes and builds empty rows.

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

proc hasNextToken(data: string, pos: int): bool =
  var checkPos = pos
  while checkPos < data.len:
    if data[checkPos] >= '0' and data[checkPos] <= '9':
      return true
    checkPos += 1
  return false
```

Token detection handles the variable number of groups.
The two grid sizes are read first.
Every remaining number is a group size.

**Placement pass.** The cursor fills a row, then jumps back two rows.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let rowCount = nextInt(inputData, scanPos)
let columnCount = nextInt(inputData, scanPos)
var groupSizes = newSeq[int]()
while hasNextToken(inputData, scanPos):
  groupSizes.add nextInt(inputData, scanPos)
var emptyRow = ""
for columnIndex in 0 .. columnCount - 1:
  emptyRow.add '0'
var seatGrid = newSeq[string](rowCount)
for rowIndex in 0 .. rowCount - 1:
  seatGrid[rowIndex] = emptyRow
var currentRow = 0
var nextColumn = 0
var firstFailedIndex = -1
for groupIndex in 0 .. groupSizes.len - 1:
  let groupSize = groupSizes[groupIndex]
  var placed = false
  while currentRow < rowCount:
    if nextColumn + groupSize <= columnCount:
      for columnOffset in 0 .. groupSize - 1:
        seatGrid[currentRow][nextColumn + columnOffset] = '1'
      nextColumn += groupSize + 1
      placed = true
      break
    currentRow += 2
    nextColumn = 0
  if not placed:
    firstFailedIndex = groupIndex
    break
```

Writing a group also reserves the gap after it.
The two-row jump keeps one empty row between groups.
A failed group stops the whole booking.

**Output pass.** The grid is printed from the back row forward on screen.

```nim
appendOutput("Seats:")
var printRow = rowCount - 1
while printRow >= 0:
  appendOutput(seatGrid[printRow])
  printRow -= 1
if firstFailedIndex >= 0:
  appendOutput("Failed to seat:")
  for groupIndex in firstFailedIndex .. groupSizes.len - 1:
    appendOutput($groupSizes[groupIndex])
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Labels appear next to their data with no separator.
The grid rows print from last to first.
Buffered output is written in blocks.

## Complexity

Placement writes each occupied seat once; printing writes the whole grid once.

| phase | time | space |
|---|---|---|
| input read | one pass over all group sizes | group list |
| placement | one seat write per occupied seat | cinema grid |
| output | one pass over the grid | block output buffer |

| measure | Big O |
|---|---|
| time | O(R times C plus G) |
| space | O(R times C plus G) |

Searching every free block for every group revisits seats that the cursor has already ruled out.

The cursor advances once and visits each candidate row once.
