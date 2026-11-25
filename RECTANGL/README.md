# RECTANGL — Rectangles (SPOJ)

<https://www.spoj.com/problems/RECTANGL/>

## Problem

Given N distinct points in the plane, count the axis-parallel rectangles whose four corners all belong to the set. Coordinates are signed 32-bit integers.

The input holds N, then N lines with one x coordinate and one y coordinate. Output the rectangle count as a single number followed by a newline.

| item | bound |
|---|---|
| points N | 1 to 250000 |
| coordinates | signed 32-bit integers |
| output | one integer |
| judge limit | 1000 ms, 1536 MB |

A rectangle needs two distinct x values and two shared y values.

Sample input:

```
6
-1 0
-1 1
0 0
0 1
1 0
1 1
```

Sample output:

```
3
```

## Idea

Two columns of points form one rectangle for every pair of y rows they share, like counting matching rungs between two ladders. Narrow columns contribute pairs of rungs into a hash table; each repeated pair across two columns becomes a rectangle. Wide columns are few, so each one can be compared directly with every other column. Checking all column pairs would cost quadratic time. The split keeps both parts bounded and the takeaway is that column width decides the counting method.

## Why It Works

1. A rectangle is fixed by two x columns and two rows shared by both columns.
2. Narrow columns hold at most `columnSplit` points, so each contributes few row pairs.
3. The hash table counts how many columns contain one row pair.
4. A row pair seen in c columns yields c times (c-1)/2 rectangles.
5. At most N divided by `columnSplit` columns are wide, so direct scans stay bounded.
6. Each wide column marks its rows, then counts shared rows in the other columns.

| term | meaning |
|---|---|
| `columnYids` | compressed row id of each point, grouped by column |
| `hashKeys` | row-pair keys from narrow columns |
| `hashCounts` | number of narrow columns holding each row pair |
| `marks` | stamp array used to test row membership |
| `rectangleCount` | accumulated answer |

The row compression uses sorted distinct y values, so negative coordinates work unchanged.

A script trace of the sample gives these numbers:

```
columns at x = -1, 0, 1 each hold rows 0 and 1
three column pairs, each sharing two rows
per pair 2 * 1 / 2 = 1 rectangle
answer 3
```

The script value 3 matches the printed sample answer.

## Code

**Input and scanner.** The reader loads the points and the scanner accepts minus signs.

```nim
import algorithm

const flushBlockBytes = 1 shl 17
const columnSplit = 256

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value

proc compareIntegers(left: int, right: int): int =
  if left < right:
    return -1
  elif left > right:
    return 1
  return 0
```

The minus branch reads negative coordinates.
The comparator serves both sorts below.
One input string holds every point.

**Output buffer.** One buffer holds the single answer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes at 131072 bytes.
A final write clears the answer.
The output has one line by contract.

**Row compression and column build.** Points are sorted once and grouped by x.

```nim
let pointCount = nextInt(inputData, scanPos)
var xCoordinates = newSeq[int](pointCount)
var yCoordinates = newSeq[int](pointCount)
for pointIndex in 0 .. pointCount - 1:
  xCoordinates[pointIndex] = nextInt(inputData, scanPos)
  yCoordinates[pointIndex] = nextInt(inputData, scanPos)

var sortedY = newSeq[int](pointCount)
for pointIndex in 0 .. pointCount - 1:
  sortedY[pointIndex] = yCoordinates[pointIndex]
sort(sortedY, compareIntegers)
var distinctY = 0
for pointIndex in 0 .. pointCount - 1:
  if pointIndex == 0 or sortedY[pointIndex] != sortedY[pointIndex - 1]:
    sortedY[distinctY] = sortedY[pointIndex]
    distinctY += 1
sortedY.setLen(distinctY)

var yIds = newSeq[int](pointCount)
for pointIndex in 0 .. pointCount - 1:
  var lowIndex = 0
  var highIndex = distinctY - 1
  while lowIndex <= highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if sortedY[middleIndex] < yCoordinates[pointIndex]:
      lowIndex = middleIndex + 1
    else:
      highIndex = middleIndex - 1
  yIds[pointIndex] = lowIndex

var pointOrder = newSeq[int](pointCount)
for pointIndex in 0 .. pointCount - 1:
  pointOrder[pointIndex] = pointIndex

proc comparePoints(left: int, right: int): int =
  if xCoordinates[left] != xCoordinates[right]:
    return compareIntegers(xCoordinates[left], xCoordinates[right])
  return compareIntegers(yIds[left], yIds[right])

sort(pointOrder, comparePoints)

var columnYids = newSeq[int](pointCount)
var columnStarts = newSeq[int]()
var columnEnds = newSeq[int]()
var filled = 0
var readIndex = 0
while readIndex < pointCount:
  let currentX = xCoordinates[pointOrder[readIndex]]
  columnStarts.add(filled)
  while readIndex < pointCount and xCoordinates[pointOrder[readIndex]] == currentX:
    columnYids[filled] = yIds[pointOrder[readIndex]]
    filled += 1
    readIndex += 1
  columnEnds.add(filled)
let columnCount = columnStarts.len
```

Binary search maps each y to its compressed id.
Sorting by x then y groups each column contiguously.
Start and end offsets avoid one sequence per column.

**Narrow column pairs.** A custom hash table counts row pairs.

```nim
var isLargeColumn = newSeq[bool](columnCount)
var largeColumns = newSeq[int]()
var pairTotal: int64 = 0
for columnIndex in 0 .. columnCount - 1:
  let columnSize = columnEnds[columnIndex] - columnStarts[columnIndex]
  if columnSize > columnSplit:
    isLargeColumn[columnIndex] = true
    largeColumns.add(columnIndex)
  else:
    pairTotal = pairTotal + int64(columnSize * (columnSize - 1) div 2)

var hashCapacity = 16
while int64(hashCapacity) < pairTotal * 2:
  hashCapacity = hashCapacity shl 1
var hashShift = 0
var capacityProbe = 1
while capacityProbe < hashCapacity:
  capacityProbe = capacityProbe shl 1
  hashShift += 1
const hashMultiplier = 11400714819323198485'u64
var hashKeys = newSeq[int64](hashCapacity)
var hashCounts = newSeq[int32](hashCapacity)
for slotIndex in 0 .. hashCapacity - 1:
  hashKeys[slotIndex] = -1

proc recordPair(pairKey: int64) =
  var slotIndex = int((cast[uint64](pairKey) * hashMultiplier) shr (64 - hashShift))
  while hashKeys[slotIndex] != -1 and hashKeys[slotIndex] != pairKey:
    slotIndex = (slotIndex + 1) and (hashCapacity - 1)
  if hashKeys[slotIndex] == -1:
    hashKeys[slotIndex] = pairKey
    hashCounts[slotIndex] = 1
  else:
    hashCounts[slotIndex] = hashCounts[slotIndex] + 1

for columnIndex in 0 .. columnCount - 1:
  if isLargeColumn[columnIndex]:
    continue
  for firstPos in columnStarts[columnIndex] .. columnEnds[columnIndex] - 1:
    for secondPos in firstPos + 1 .. columnEnds[columnIndex] - 1:
      let pairKey = int64(columnYids[firstPos]) * int64(distinctY) + int64(columnYids[secondPos])
      recordPair(pairKey)

var rectangleCount: int64 = 0
for slotIndex in 0 .. hashCapacity - 1:
  if hashKeys[slotIndex] != -1:
    let count = int64(hashCounts[slotIndex])
    rectangleCount = rectangleCount + count * (count - 1) div 2
```

The capacity is a power of two with room to spare.
The multiplier spreads pair keys across slots.
Each repeated key adds its combination count.

**Wide column scans.** Each wide column marks its rows and scans the rest.

```nim
var marks = newSeq[int](distinctY)
for yIndex in 0 .. distinctY - 1:
  marks[yIndex] = -1
for largePosition in 0 .. largeColumns.len - 1:
  let largeColumn = largeColumns[largePosition]
  let stamp = largeColumn + 1
  for yPos in columnStarts[largeColumn] .. columnEnds[largeColumn] - 1:
    marks[columnYids[yPos]] = stamp
  for otherColumn in 0 .. columnCount - 1:
    if otherColumn == largeColumn:
      continue
    if isLargeColumn[otherColumn] and otherColumn < largeColumn:
      continue
    var commonCount: int64 = 0
    for yPos in columnStarts[otherColumn] .. columnEnds[otherColumn] - 1:
      if marks[columnYids[yPos]] == stamp:
        commonCount += 1
    rectangleCount = rectangleCount + commonCount * (commonCount - 1) div 2

appendOutput($rectangleCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The stamp avoids clearing the mark array.
Skipping earlier wide columns prevents double counting.
The count uses 64-bit arithmetic for large grids.

## Complexity

The column split sets both major costs.

| phase | time | space |
|---|---|---|
| input read | one pass over point pairs | one input string |
| sort and compress | O(N log N) comparisons | offset and row arrays |
| narrow pairs | O(N times columnSplit) hash updates | pair hash table |
| wide scans | O(N squared divided by columnSplit) | one stamp array |
| output | one buffered write | block buffer |

Both counting paths stay bounded by the split threshold.

| measure | Big O |
|---|---|
| time | O(N log N + N times columnSplit + N squared divided by columnSplit) |
| space | O(N) plus the pair hash table |

Checking all column pairs directly would take quadratic time on dense inputs.
The split keeps sparse and dense cases short.
