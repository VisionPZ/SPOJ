# OVERLAP — Overlapping Words (SPOJ)

<https://www.spoj.com/problems/OVERLAP/>

## Problem

For each word placed on a square crossword grid, count the other words that share at least one cell with it. A word is a straight horizontal or vertical run given by its two end cells.

Input starts with the child count N, then the grid size M. Each of the next N lines holds R1, S1, R2, S2, the inclusive ends of one word. Rows and columns run from 1 to M. Print N lines, where line k is the count for child k. A word does not count itself.

| item | bound |
|---|---|
| words N | 1 to 300000 |
| grid size M | 1 to 100000 |
| coordinates | 1 to M |
| judge limit | 1000 ms, 1536 MB |

Horizontal words have equal rows and increasing columns. Vertical words have equal columns and increasing rows.

Sample input:

```
5
4
2 1 2 4
2 1 2 4
4 1 4 3
1 3 3 3
2 3 4 3
```

Sample output:

```
3
3
1
3
4
```

## Idea

Split the count into four independent sweeps, like sorting mail into same-street and cross-street piles before delivering it.

Same-direction words overlap only on the same row or column, where a sorted-end binary search counts them. Opposite-direction words cross at one cell, so two Fenwick-tree sweeps count crossings from each side. Every pass touches each word once, giving O(N log M) time instead of O(N²) pair checks.

## Why It Works

1. Two horizontal words overlap only if their rows match and their column intervals intersect.
2. For intervals on one row, the count is starts at most hi minus ends below lo, minus one for self.
3. A vertical word crosses a horizontal word at one cell when both coordinate ranges contain it.
4. A row sweep activates vertical words over their row span and queries columns with a Fenwick tree.
5. A column sweep activates horizontal words over their column span and queries rows the same way.

| term | meaning |
|---|---|
| `horizontalWords` | word indices with equal rows |
| `verticalWords` | word indices with equal columns |
| `upperBound` | count of sorted starts at most a value |
| `lowerBound` | count of sorted ends below a value |
| `columnTree` | Fenwick tree of active vertical words |
| `overlapCounts` | final answer per child |

The worked example uses the first sample, where rows and columns run from 1 to 4.

| child | word | same-direction hits | crossing hits | total |
|---|---|---|---|---|
| 1 | row 2, cols 1-4 | 1 | 2 | 3 |
| 2 | row 2, cols 1-4 | 1 | 2 | 3 |
| 4 | col 3, rows 1-3 | 1 | 2 | 3 |
| 5 | col 3, rows 2-4 | 1 | 3 | 4 |

Child 3 has one crossing hit and no same-direction hit, so its total is 1.

Subtracting one in the interval formula removes the word itself. Events at end plus one are skipped past the grid edge, so no Fenwick index exceeds M.

## Code

**Input and helpers.** The reader loads stdin once and supplies integer scanning, binary searches, and Fenwick updates.

```nim
import algorithm

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

proc byValue(left: int, right: int): int =
  return left - right

proc upperBound(values: seq[int], limit: int): int =
  var low = 0
  var high = values.len
  while low < high:
    let middle = low + (high - low) div 2
    if values[middle] <= limit:
      low = middle + 1
    else:
      high = middle
  return low

proc lowerBound(values: seq[int], limit: int): int =
  var low = 0
  var high = values.len
  while low < high:
    let middle = low + (high - low) div 2
    if values[middle] < limit:
      low = middle + 1
    else:
      high = middle
  return low

proc bitAdd(tree: var seq[int], index: int, delta: int, treeSize: int) =
  var position = index
  while position <= treeSize:
    tree[position] += delta
    position += position and -position

proc bitSum(tree: seq[int], index: int): int =
  var position = index
  var total = 0
  while position > 0:
    total += tree[position]
    position -= position and -position
  return total
```

The two searches replace a scan of all intervals in a group.
Fenwick updates and queries both cost O(log M).
The comparator serves the sorts used by the sweeps.

**Word storage and comparators.** Each word is split into row bounds and column bounds, then sorted by the key each sweep needs.

```nim
var firstRow = newSeq[int](0)
var firstColumn = newSeq[int](0)
var lastRow = newSeq[int](0)
var lastColumn = newSeq[int](0)
var overlapCounts = newSeq[int](0)

proc byRowAndColumn(left: int, right: int): int =
  if firstRow[left] != firstRow[right]:
    return firstRow[left] - firstRow[right]
  if firstColumn[left] != firstColumn[right]:
    return firstColumn[left] - firstColumn[right]
  return lastColumn[left] - lastColumn[right]

proc byColumnAndRow(left: int, right: int): int =
  if firstColumn[left] != firstColumn[right]:
    return firstColumn[left] - firstColumn[right]
  if firstRow[left] != firstRow[right]:
    return firstRow[left] - firstRow[right]
  return lastRow[left] - lastRow[right]

proc byRow(left: int, right: int): int =
  return firstRow[left] - firstRow[right]

proc byColumn(left: int, right: int): int =
  return firstColumn[left] - firstColumn[right]

var eventCoordinate = newSeq[int](0)
var eventValue = newSeq[int](0)
var eventDelta = newSeq[int](0)
var eventOrder = newSeq[int](0)

proc byEventCoordinate(left: int, right: int): int =
  return eventCoordinate[left] - eventCoordinate[right]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Horizontal and vertical words are kept in separate index lists.
Event arrays are reused by both crossing sweeps.
Output is staged in the shared block buffer.

**Interval reads.** The parser assigns each word to its orientation.

```nim
let childCount = nextInt(inputData, scanPos)
let gridSize = nextInt(inputData, scanPos)
firstRow.setLen(childCount)
firstColumn.setLen(childCount)
lastRow.setLen(childCount)
lastColumn.setLen(childCount)
overlapCounts.setLen(childCount)
var horizontalWords = newSeq[int](0)
var verticalWords = newSeq[int](0)
for childIndex in 0 .. childCount - 1:
  let startRow = nextInt(inputData, scanPos)
  let startColumn = nextInt(inputData, scanPos)
  let endRow = nextInt(inputData, scanPos)
  let endColumn = nextInt(inputData, scanPos)
  firstRow[childIndex] = startRow
  lastRow[childIndex] = endRow
  if startRow == endRow:
    firstColumn[childIndex] = startColumn
    lastColumn[childIndex] = endColumn
    horizontalWords.add childIndex
  else:
    firstColumn[childIndex] = startColumn
    lastColumn[childIndex] = endColumn
    verticalWords.add childIndex
```

Equal rows mark a horizontal word, and equal columns mark a vertical word.
Bounds are stored directly because the statement guarantees increasing ends.
Every child keeps its original index for output order.

**Same-direction counts.** Words sharing a row or column are handled group by group.

```nim
sort(horizontalWords, byRowAndColumn)
var groupStart = 0
while groupStart < horizontalWords.len:
  let groupRow = firstRow[horizontalWords[groupStart]]
  var groupEnd = groupStart
  while groupEnd < horizontalWords.len and firstRow[horizontalWords[groupEnd]] == groupRow:
    groupEnd += 1
  let groupLength = groupEnd - groupStart
  var starts = newSeq[int](groupLength)
  var ends = newSeq[int](groupLength)
  for offset in 0 .. groupLength - 1:
    let wordIndex = horizontalWords[groupStart + offset]
    starts[offset] = firstColumn[wordIndex]
    ends[offset] = lastColumn[wordIndex]
  sort(starts, byValue)
  sort(ends, byValue)
  for offset in 0 .. groupLength - 1:
    let wordIndex = horizontalWords[groupStart + offset]
    let wordStart = firstColumn[wordIndex]
    let wordEnd = lastColumn[wordIndex]
    overlapCounts[wordIndex] += upperBound(starts, wordEnd) - lowerBound(ends, wordStart) - 1
  groupStart = groupEnd

sort(verticalWords, byColumnAndRow)
groupStart = 0
while groupStart < verticalWords.len:
  let groupColumn = firstColumn[verticalWords[groupStart]]
  var groupEnd = groupStart
  while groupEnd < verticalWords.len and firstColumn[verticalWords[groupEnd]] == groupColumn:
    groupEnd += 1
  let groupLength = groupEnd - groupStart
  var starts = newSeq[int](groupLength)
  var ends = newSeq[int](groupLength)
  for offset in 0 .. groupLength - 1:
    let wordIndex = verticalWords[groupStart + offset]
    starts[offset] = firstRow[wordIndex]
    ends[offset] = lastRow[wordIndex]
  sort(starts, byValue)
  sort(ends, byValue)
  for offset in 0 .. groupLength - 1:
    let wordIndex = verticalWords[groupStart + offset]
    let wordStart = firstRow[wordIndex]
    let wordEnd = lastRow[wordIndex]
    overlapCounts[wordIndex] += upperBound(starts, wordEnd) - lowerBound(ends, wordStart) - 1
  groupStart = groupEnd
```

Sorted starts and ends give the interval count in two binary searches.
The minus one removes the word from its own total.
The second loop swaps rows and columns for vertical words.

**Row sweep.** Active vertical words contribute crossings to each horizontal word.

```nim
var horizontalByRow = newSeq[int](horizontalWords.len)
for index in 0 .. horizontalWords.len - 1:
  horizontalByRow[index] = horizontalWords[index]
sort(horizontalByRow, byRow)
eventCoordinate.setLen(0)
eventValue.setLen(0)
eventDelta.setLen(0)
for wordIndex in verticalWords:
  let column = firstColumn[wordIndex]
  eventCoordinate.add firstRow[wordIndex]
  eventValue.add column
  eventDelta.add 1
  if lastRow[wordIndex] + 1 <= gridSize:
    eventCoordinate.add lastRow[wordIndex] + 1
    eventValue.add column
    eventDelta.add -1
eventOrder.setLen(eventCoordinate.len)
for index in 0 .. eventOrder.len - 1:
  eventOrder[index] = index
sort(eventOrder, byEventCoordinate)
var columnTree = newSeq[int](gridSize + 1)
var eventPosition = 0
for wordIndex in horizontalByRow:
  let queryRow = firstRow[wordIndex]
  while eventPosition < eventOrder.len and eventCoordinate[eventOrder[eventPosition]] <= queryRow:
    let activeEvent = eventOrder[eventPosition]
    bitAdd(columnTree, eventValue[activeEvent], eventDelta[activeEvent], gridSize)
    eventPosition += 1
  let wordStart = firstColumn[wordIndex]
  let wordEnd = lastColumn[wordIndex]
  overlapCounts[wordIndex] += bitSum(columnTree, wordEnd) - bitSum(columnTree, wordStart - 1)
```

A vertical word enters at its first row and leaves after its last row.
The query returns active words whose column lies in the horizontal span.
Events and queries both advance in sorted order.

**Column sweep.** Active horizontal words contribute crossings to each vertical word.

```nim
var verticalByColumn = newSeq[int](verticalWords.len)
for index in 0 .. verticalWords.len - 1:
  verticalByColumn[index] = verticalWords[index]
sort(verticalByColumn, byColumn)
eventCoordinate.setLen(0)
eventValue.setLen(0)
eventDelta.setLen(0)
for wordIndex in horizontalWords:
  let row = firstRow[wordIndex]
  eventCoordinate.add firstColumn[wordIndex]
  eventValue.add row
  eventDelta.add 1
  if lastColumn[wordIndex] + 1 <= gridSize:
    eventCoordinate.add lastColumn[wordIndex] + 1
    eventValue.add row
    eventDelta.add -1
eventOrder.setLen(eventCoordinate.len)
for index in 0 .. eventOrder.len - 1:
  eventOrder[index] = index
sort(eventOrder, byEventCoordinate)
var rowTree = newSeq[int](gridSize + 1)
eventPosition = 0
for wordIndex in verticalByColumn:
  let queryColumn = firstColumn[wordIndex]
  while eventPosition < eventOrder.len and eventCoordinate[eventOrder[eventPosition]] <= queryColumn:
    let activeEvent = eventOrder[eventPosition]
    bitAdd(rowTree, eventValue[activeEvent], eventDelta[activeEvent], gridSize)
    eventPosition += 1
  let wordStart = firstRow[wordIndex]
  let wordEnd = lastRow[wordIndex]
  overlapCounts[wordIndex] += bitSum(rowTree, wordEnd) - bitSum(rowTree, wordStart - 1)

for childIndex in 0 .. childCount - 1:
  appendOutput($overlapCounts[childIndex])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The column sweep mirrors the row sweep with coordinates swapped.
Each crossing pair is counted once for each of its two words.
Answers are written in input order.

## Complexity

Four sweeps process every word and every event once.

| phase | time | space |
|---|---|---|
| input read | one pass over 4N coordinates | arrays of N integers |
| same-direction groups | sorting plus two searches per word | two group arrays |
| crossing sweeps | O(N log M) events and queries | two trees of size M |
| output | one line per word | block buffer |

| measure | Big O |
|---|---|
| time | O(N log N + N log M) |
| space | O(N + M) |

Checking all word pairs costs O(N²) and fails at the stated limit.
Sorting once and sweeping replaces every pair test with a logarithmic query.

The self subtraction applies only to same-direction groups, since a word never crosses itself.
Skipping end events beyond M keeps all tree indices inside the grid.
