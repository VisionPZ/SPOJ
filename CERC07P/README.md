# CERC07P — Rectangular Polygon (SPOJ)

<https://www.spoj.com/problems/CERC07P/>

## Problem

Given the shuffled corners of a simple axis-aligned polygon, print one direction letter per wall while walking clockwise from the first listed corner. The letters are N, E, S, and W.

Input holds several buildings. Each starts with corner count N, then N coordinate pairs. A blank line follows each building. A line with `0` ends the input. Output holds one direction string per building.

| item | bound |
|---|---|
| corners N | 1 to 1000 |
| coordinate magnitude | up to 10000 |
| walls per building | N |
| judge limit | 1000 ms, 1536 MB |

The corner order in input carries no information; the outline must be rebuilt.

Sample input:

```
4
0 0
2 2
0 2
2 0

6
1 1
2 2
0 1
1 0
0 2
2 0

0
```

Sample output:

```
NESW
WNESWN
```

## Idea

Pair corners along each row and column like matching socks by alternating positions. On any row, boundary crossings alternate inside and outside, so sorted corners pair as first with second, third with fourth. Do the same down each column, walk the resulting cycle, and reverse it when its signed area runs counterclockwise. Each corner gets constant pairing work after ranking; brute-force edge guessing would test every corner pair and still need a cycle check. Pairing settles the outline once.

## Why It Works

1. Every corner has one horizontal neighbor and one vertical neighbor.
2. On a fixed row, sorted corners pair by even and odd positions.
3. On a fixed column, sorted corners pair in the same alternating way.
4. Walking from either mate yields the complete closed outline.
5. Negative signed area means clockwise order in the usual y-up plane.
6. The sign of each coordinate difference gives its direction letter.

| term | meaning |
|---|---|
| `horizontalRank` | count of same-row corners with smaller x |
| `verticalRank` | count of same-column corners with smaller y |
| `horizontalMate` | paired corner on the same row |
| `signedArea` | shoelace sum that fixes the walk direction |
| `orderedCorners` | corner cycle ordered clockwise from the input start |

The table names each step from ranking to final direction.

A script trace of the first sample:

```
row 0: (0,0) rank 0, (2,0) rank 1 -> horizontal mates
column 0: (0,0) rank 0, (0,2) rank 1 -> vertical mates
walk from (0,0): (0,0) (2,0) (2,2) (0,2)
signed area = +8 -> reverse the walk after its first corner
clockwise steps: N E S W
```

The trace ends at NESW, matching the sample.

## Code

**Bulk input and scanner.** All lines become one string, and the scanner reads signed coordinates.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const noNeighbor = -1

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return signValue * value
```

Blank lines need no special case.
The minus branch handles negative coordinates.
`inputData` holds the whole input in memory.

**Buffered output and corner read.** One string collects all direction lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let cornerCount = nextInt(inputData, scanPos)
  if cornerCount == 0:
    break
  var cornerX = newSeq[int](cornerCount)
  var cornerY = newSeq[int](cornerCount)
  for cornerIndex in 0 .. cornerCount - 1:
    cornerX[cornerIndex] = nextInt(inputData, scanPos)
    cornerY[cornerIndex] = nextInt(inputData, scanPos)
```

The zero count ends the loop.
Coordinates stay in two parallel arrays.

**Row and column pairing.** Ranking by x or y gives the alternating mate directly.

```nim
  var horizontalRank = newSeq[int](cornerCount)
  var verticalRank = newSeq[int](cornerCount)
  for cornerIndex in 0 .. cornerCount - 1:
    var smallerX = 0
    var smallerY = 0
    for otherIndex in 0 .. cornerCount - 1:
      if otherIndex == cornerIndex:
        continue
      if cornerY[otherIndex] == cornerY[cornerIndex] and cornerX[otherIndex] < cornerX[cornerIndex]:
        smallerX += 1
      if cornerX[otherIndex] == cornerX[cornerIndex] and cornerY[otherIndex] < cornerY[cornerIndex]:
        smallerY += 1
    horizontalRank[cornerIndex] = smallerX
    verticalRank[cornerIndex] = smallerY

  var horizontalMate = newSeq[int](cornerCount)
  var verticalMate = newSeq[int](cornerCount)
  for cornerIndex in 0 .. cornerCount - 1:
    horizontalMate[cornerIndex] = noNeighbor
    verticalMate[cornerIndex] = noNeighbor
    var wantedHorizontal = horizontalRank[cornerIndex] + 1
    if horizontalRank[cornerIndex] mod 2 == 1:
      wantedHorizontal = horizontalRank[cornerIndex] - 1
    var wantedVertical = verticalRank[cornerIndex] + 1
    if verticalRank[cornerIndex] mod 2 == 1:
      wantedVertical = verticalRank[cornerIndex] - 1
    for otherIndex in 0 .. cornerCount - 1:
      if otherIndex == cornerIndex:
        continue
      if cornerY[otherIndex] == cornerY[cornerIndex] and horizontalRank[otherIndex] == wantedHorizontal:
        horizontalMate[cornerIndex] = otherIndex
      if cornerX[otherIndex] == cornerX[cornerIndex] and verticalRank[otherIndex] == wantedVertical:
        verticalMate[cornerIndex] = otherIndex
```

Odd ranks pair down, even ranks pair up.
`mod` replaces the remainder operator.
The scan is quadratic in N, bounded by 1000.

**Cycle walk and output.** The walk avoids backtracking, then signed area fixes direction.

```nim
  var outline = newSeq[int](cornerCount)
  var currentCorner = 0
  var previousCorner = noNeighbor
  for stepIndex in 0 .. cornerCount - 1:
    outline[stepIndex] = currentCorner
    var nextCorner = horizontalMate[currentCorner]
    if nextCorner == previousCorner:
      nextCorner = verticalMate[currentCorner]
    previousCorner = currentCorner
    currentCorner = nextCorner

  var signedArea: int64 = 0
  for stepIndex in 0 .. cornerCount - 1:
    let firstCorner = outline[stepIndex]
    let secondCorner = outline[(stepIndex + 1) mod cornerCount]
    signedArea = signedArea + int64(cornerX[firstCorner]) * int64(cornerY[secondCorner])
    signedArea = signedArea - int64(cornerX[secondCorner]) * int64(cornerY[firstCorner])

  var orderedCorners = newSeq[int](cornerCount)
  if signedArea > 0:
    orderedCorners[0] = outline[0]
    for stepIndex in 1 .. cornerCount - 1:
      orderedCorners[stepIndex] = outline[cornerCount - stepIndex]
  else:
    for stepIndex in 0 .. cornerCount - 1:
      orderedCorners[stepIndex] = outline[stepIndex]

  var directionLine = ""
  for stepIndex in 0 .. cornerCount - 1:
    let firstCorner = orderedCorners[stepIndex]
    let secondCorner = orderedCorners[(stepIndex + 1) mod cornerCount]
    let deltaX = cornerX[secondCorner] - cornerX[firstCorner]
    let deltaY = cornerY[secondCorner] - cornerY[firstCorner]
    if deltaX > 0:
      directionLine.add 'E'
    elif deltaX < 0:
      directionLine.add 'W'
    elif deltaY > 0:
      directionLine.add 'N'
    else:
      directionLine.add 'S'

  appendOutput(directionLine)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The first listed corner stays first after reversal.
The shoelace sum uses int64 for coordinate products.
One final write flushes all buildings.

## Complexity

Pairing dominates the work, with two quadratic ranking sweeps.

| phase | time | space |
|---|---|---|
| input read | one pass over coordinate tokens | one input string |
| row and column pairing | two N by N rank sweeps | four arrays of N integers |
| walk and output | N steps per building | direction string of N letters |

The buffers keep their size through every building.

| measure | Big O |
|---|---|
| time | O(N^2) per building |
| space | O(N) per building |

Testing every possible wall and then searching for a cycle would cost even more work. Pairing once is the takeaway.
