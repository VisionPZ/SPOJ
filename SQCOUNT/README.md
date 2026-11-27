# SQCOUNT — Square Count (SPOJ)
<https://www.spoj.com/problems/SQCOUNT/>

## Problem

Several non-overlapping rectangular rooms form a museum. Count every axis-aligned square that fits inside one room or crosses a door into a neighboring room.

| item | bound |
|---|---|
| rooms per case | positive, at most 1000 |
| coordinates | at most 1,000,000 |
| shared side | door length is side length minus two |
| judge limit | 1000 ms, 1536 MB |

A case with `n = 0` ends the input. Each case prints one numbered line.

Sample input:

```
2
0 0 9 3
10 6 4 3
3
11 20 15 24
11 17 15 20
15 16 20 24
0
```

Sample output:

```
Case 1: 86
Case 2: 152
```

## Idea

Counting squares on a tiled floor is like stacking boxes: a wide room holds a predictable count at each size. The algorithm sums a closed form for each room, then adds the squares that fit through a door. Walking every possible square would be impossible at coordinate 1,000,000.

## Why It Works

1. A room of width W and height H holds `(W - s + 1) * (H - s + 1)` squares of size s.
2. Summing that formula over s gives two polynomial terms, so no per-size loop is needed.
3. Two rooms share a door only along a common side longer than two units.
4. A crossing square spends a columns in one room and s - a in the other.
5. Its span along the wall must fit inside the centered door.
6. The split count is piecewise linear in s, so three arithmetic ranges cover it.

| term | meaning |
|---|---|
| `shortSide` | smaller side of one room |
| `longSide` | larger side of one room |
| `doorWidth` | shared side length minus two |
| `sumRange` | sum of `(doorWidth + 1 - s)` times a linear split count |
| `squareTotal` | running 64-bit answer |

For sample case 1, the 9 by 3 room contributes 27, 16, and 7 squares of sizes 1, 2, and 3. The 6 by 3 room contributes 18, 10, and 4. The door allows two 2 by 2 squares and two 3 by 3 squares across it. The total is 27 + 18 + 16 + 10 + 2 + 7 + 4 + 2 = 86.

All sums use `int64`. A single 1,000,000 by 1,000,000 room already needs more than 32 bits.

## Code

**Input and sums.** The reader loads all rooms, and `sumRange` evaluates the polynomial pieces.

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

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc sumRange(firstSize: int, lastSize: int, doorWidth: int, slopeTerm: int, constantTerm: int): int64 =
  if firstSize > lastSize:
    return 0
  let termCount = lastSize - firstSize + 1
  let sumFirst = int64(firstSize + lastSize) * int64(termCount) div 2
  let sumSecond = (int64(lastSize) * int64(lastSize + 1) * int64(2 * lastSize + 1) - int64(firstSize - 1) * int64(firstSize) * int64(2 * firstSize - 1)) div 6
  return int64(doorWidth + 1) * (int64(slopeTerm) * sumFirst + int64(constantTerm) * int64(termCount)) - int64(slopeTerm) * sumSecond - int64(constantTerm) * sumFirst

proc crossingTotal(doorWidth: int, firstDepth: int, secondDepth: int): int64 =
  if doorWidth <= 0 or firstDepth < 1 or secondDepth < 1:
    return 0
  let largestSize = min(doorWidth, firstDepth + secondDepth)
  if largestSize < 2:
    return 0
  let smallerDepth = min(firstDepth, secondDepth)
  let largerDepth = max(firstDepth, secondDepth)
  let firstBreak = smallerDepth + 1
  let secondBreak = largerDepth + 1
  result = sumRange(2, min(firstBreak, largestSize), doorWidth, 1, -1)
  result += sumRange(firstBreak + 1, min(secondBreak, largestSize), doorWidth, 0, smallerDepth)
  result += sumRange(secondBreak + 1, largestSize, doorWidth, -1, largerDepth + smallerDepth + 1)
```

The first and second power sums make each range constant time.
The three ranges cover rising, flat, and falling split counts.
Doors shorter than two units add nothing.

**Room sweep.** Each room contributes its own closed form, then each pair adds its crossing squares.

```nim
var caseNumber = 0
while true:
  let roomCount = nextInt(inputData, scanPos)
  if roomCount == 0:
    break
  caseNumber += 1
  var leftEdges = newSeq[int](roomCount)
  var bottomEdges = newSeq[int](roomCount)
  var rightEdges = newSeq[int](roomCount)
  var topEdges = newSeq[int](roomCount)
  for roomIndex in 0 .. roomCount - 1:
    let firstX = nextInt(inputData, scanPos)
    let firstY = nextInt(inputData, scanPos)
    let secondX = nextInt(inputData, scanPos)
    let secondY = nextInt(inputData, scanPos)
    leftEdges[roomIndex] = min(firstX, secondX)
    rightEdges[roomIndex] = max(firstX, secondX)
    bottomEdges[roomIndex] = min(firstY, secondY)
    topEdges[roomIndex] = max(firstY, secondY)
  var squareTotal: int64 = 0
  for roomIndex in 0 .. roomCount - 1:
    let roomWidth = rightEdges[roomIndex] - leftEdges[roomIndex]
    let roomHeight = topEdges[roomIndex] - bottomEdges[roomIndex]
    let shortSide = min(roomWidth, roomHeight)
    let longSide = max(roomWidth, roomHeight)
    squareTotal += int64(longSide - shortSide) * int64(shortSide) * int64(shortSide + 1) div 2
    squareTotal += int64(shortSide) * int64(shortSide + 1) * int64(2 * shortSide + 1) div 6
  for firstRoom in 0 .. roomCount - 1:
    for secondRoom in firstRoom + 1 .. roomCount - 1:
      let verticalOverlap = min(topEdges[firstRoom], topEdges[secondRoom]) - max(bottomEdges[firstRoom], bottomEdges[secondRoom])
      if rightEdges[firstRoom] == leftEdges[secondRoom] or rightEdges[secondRoom] == leftEdges[firstRoom]:
        squareTotal += crossingTotal(verticalOverlap - 2, rightEdges[firstRoom] - leftEdges[firstRoom], rightEdges[secondRoom] - leftEdges[secondRoom])
      let horizontalOverlap = min(rightEdges[firstRoom], rightEdges[secondRoom]) - max(leftEdges[firstRoom], leftEdges[secondRoom])
      if topEdges[firstRoom] == bottomEdges[secondRoom] or topEdges[secondRoom] == bottomEdges[firstRoom]:
        squareTotal += crossingTotal(horizontalOverlap - 2, topEdges[firstRoom] - bottomEdges[firstRoom], topEdges[secondRoom] - bottomEdges[secondRoom])
  appendOutput("Case ")
  appendOutput($caseNumber)
  appendOutput(": ")
  appendOutput($squareTotal)
  appendOutput("\n")
```

Opposing corners are normalised before any width is taken.
Vertical and horizontal neighbors use the same crossing formula.
The answer is written once per case.

## Complexity

| phase | time | space |
|---|---|---|
| read rooms | one pass over four coordinates per room | four edge arrays |
| single rooms | one closed form per room | constant |
| room pairs | constant work per pair | constant |

| measure | Big O |
|---|---|
| per case | O(n^2) time |
| space | O(n) |

Enumerating every square position would instead cost time proportional to the coordinate range.
