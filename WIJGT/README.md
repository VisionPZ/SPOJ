# WIJGT — Will Indiana Jones Get There (SPOJ)

<https://www.spoj.com/problems/WIJGT/>

## Problem

Walls are horizontal or vertical segments, and Indiana starts on one of them. Find the shortest board that lets him move between walls until he reaches the segment holding the trapped person.

Each test case starts with the wall count, then one X, Y, L triple per wall. A positive L runs east from (X, Y), and a negative L runs north. Zero ends the input. Print one distance per case with two decimal places, rounded to the last digit.

| item | bound |
|---|---|
| walls per case | 2 to 1000 |
| coordinates and lengths | -10000 to 10000 |
| precision | two decimals |
| judge limit | 2.857 s, 1536 MB |

The first wall is the start and the second wall is the goal.

Sample input:

```
14
1 1 5
6 8 2
7 2 -2
5 3 3
2 5 2
2 3 2
2 3 -2
4 3 -2
0 7 1
1 8 2
3 6 -2
4 7 2
6 6 1
6 6 -2
3
-10 0 20
-5 1 10
50 50 100
0
```

Sample output:

```
1.41
1.00
```

## Idea

Think of the board as a bridge that can be reused at every gap, like a portable plank crossing streams along a route. The needed length is the largest gap on the best route, not the sum of gaps. Model walls as graph vertices and gaps as edge weights, then compute a minimax path from the first wall to the second. A modified Dijkstra pass settles one wall at a time and keeps the largest gap seen so far. Testing every ordering of walls would be far slower.

## Why It Works

1. Each wall has an axis-aligned bounding box, which is the segment itself.
2. Two walls touch when their boxes overlap, so the gap between them is zero.
3. The gap between two boxes is the square root of the sum of squared axis gaps.
4. Carrying a board of length B crosses every gap of size at most B.
5. The smallest usable B is the minimax path value from the start wall to the goal wall.

| term | meaning |
|---|---|
| `squaredGap` | squared shortest distance between two wall boxes |
| `bestDistance` | smallest bottleneck value known for a wall |
| `settled` | marks walls whose best bottleneck is final |
| `minimumBoardSquared` | Dijkstra-style minimax search over walls |
| `appendDistance` | writes the square root with two decimals |

A script check with horizontal walls spanning x from 0 to 2 at y = 0, y = 3 and y = 5 gives gaps of 3 and 2. The direct gap is 5, but the route through the middle wall needs a board of only 3. The minimax search reports 3.00.

The search compares squared distances, so no square root enters any decision. The final square root is rounded once when the answer is printed.

## Code

**Input and buffering.** The reader loads every case and accepts negative coordinates.

```nim
import math

const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The sign branch handles negative X, Y and L values.
All output is collected in one block buffer.

**Wall boxes.** Each segment becomes one inclusive axis-aligned box.

```nim
var wallCount = 0
var lowerX: seq[int] = @[]
var upperX: seq[int] = @[]
var lowerY: seq[int] = @[]
var upperY: seq[int] = @[]

proc squaredGap(firstIndex: int, secondIndex: int): int64 =
  var gapX = 0'i64
  var gapY = 0'i64
  if lowerX[firstIndex] > upperX[secondIndex]:
    gapX = int64(lowerX[firstIndex] - upperX[secondIndex])
  elif lowerX[secondIndex] > upperX[firstIndex]:
    gapX = int64(lowerX[secondIndex] - upperX[firstIndex])
  if lowerY[firstIndex] > upperY[secondIndex]:
    gapY = int64(lowerY[firstIndex] - upperY[secondIndex])
  elif lowerY[secondIndex] > upperY[firstIndex]:
    gapY = int64(lowerY[secondIndex] - upperY[firstIndex])
  return gapX * gapX + gapY * gapY
```

A positive span extends the x range, and a negative span extends the y range.
A zero-length wall keeps a single point as its box.

**Minimax search.** Each settled wall improves the bottleneck value of its neighbors.

```nim
proc minimumBoardSquared(): int64 =
  var bestDistance = newSeq[int64](wallCount)
  var settled = newSeq[bool](wallCount)
  for wallIndex in 0 .. wallCount - 1:
    bestDistance[wallIndex] = high(int64) div 4
  bestDistance[0] = 0'i64
  for stepIndex in 0 .. wallCount - 1:
    var chosen = -1
    for wallIndex in 0 .. wallCount - 1:
      if not settled[wallIndex] and (chosen == -1 or
          bestDistance[wallIndex] < bestDistance[chosen]):
        chosen = wallIndex
    if chosen == -1:
      break
    settled[chosen] = true
    for otherIndex in 0 .. wallCount - 1:
      if not settled[otherIndex]:
        let candidate = max(bestDistance[chosen], squaredGap(chosen, otherIndex))
        if candidate < bestDistance[otherIndex]:
          bestDistance[otherIndex] = candidate
  return bestDistance[1]

proc appendDistance(squared: int64) =
  let scaled = int64(round(sqrt(float(squared)) * 100.0))
  var text = $int(scaled div 100) & "."
  let fraction = scaled mod 100
  if fraction < 10:
    text.add '0'
  text.add $int(fraction)
  appendOutput(text)
  outputBuffer.add '\n'
```

The relaxation takes the larger of the current bottleneck and the next gap.
The chosen wall is final because every edge out of it has been considered.

**Driver.** Each case builds its boxes, then writes one rounded distance.

```nim
while scanPos < inputData.len:
  wallCount = nextInt(inputData, scanPos)
  if wallCount == 0:
    break
  lowerX = newSeq[int](wallCount)
  upperX = newSeq[int](wallCount)
  lowerY = newSeq[int](wallCount)
  upperY = newSeq[int](wallCount)
  for wallIndex in 0 .. wallCount - 1:
    let originX = nextInt(inputData, scanPos)
    let originY = nextInt(inputData, scanPos)
    let span = nextInt(inputData, scanPos)
    lowerX[wallIndex] = originX
    upperX[wallIndex] = originX
    lowerY[wallIndex] = originY
    upperY[wallIndex] = originY
    if span > 0:
      upperX[wallIndex] = originX + span
    elif span < 0:
      upperY[wallIndex] = originY - span
  appendDistance(minimumBoardSquared())
stdout.write outputBuffer
outputBuffer.setLen 0
```

Wall number zero starts the search, and wall number one ends it.
The final flush writes the buffered result lines.

## Complexity

| phase | time | space |
|---|---|---|
| box build | one pass over walls | four coordinate arrays |
| minimax search | one selection and one relaxation per wall | distance and settled arrays |
| output | one formatted line per case | block buffer |

| measure | Big O |
|---|---|
| time per case | O(n^2) |
| space | O(n) |

Trying every ordering of the walls would enumerate factorial routes instead of settling each wall once.

The quadratic scan stays small for a thousand walls, so cases finish quickly.
