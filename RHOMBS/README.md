## Problem

Read a simple polygon on a triangular grid. Each side gives a direction from 1 to 6 and a length. The polygon can be split into rhombs of three types, A, B and C. Print the count of each type in any valid split.

| Quantity | Bound |
| --- | --- |
| Sides in a polygon | 3 to 50000 |
| Sum of side lengths | at most 100000 |
| Time limit | 7000 ms |
| Memory limit | 1536 MB |

The counts come from the boundary alone, so the program never builds a split.

## Idea

Walk once around the polygon and keep two running sums. Each side adds a small value that depends on its direction and on the position of the walk. The two sums give the counts of A and C, and the polygon area gives B. A search for a real split tries many choices and can take exponential time, while one walk costs one step per side.

Cost: O(n) work for a polygon with n sides.

## Why It Works

Each unit cell of the grid holds a lower triangle and an upper triangle. A rhomb joins two neighboring triangles, and the direction of their shared edge fixes the rhomb type. Add a triangle coordinate over lower triangles and subtract it over upper triangles: every rhomb cancels except the ones that use that coordinate.

Use grid coordinates (x, y). Direction 1 steps (+1, 0) and direction 2 steps (0, +1); the other four steps follow from these two. Let (x, y) be the position before a side and let k be its length. The rules below update the two counts, and nextX and nextY hold the position after the side.

| Direction | Side step | Change to A | Change to C |
| --- | --- | --- | --- |
| 1, north-west | (+1, 0) | 0 | k*x + k(k-1)/2 |
| 2, north-east | (0, +1) | -(k*y + k(k-1)/2) | 0 |
| 3, east | (-1, +1) | 0 | 0 |
| 4, south-east | (-1, 0) | 0 | k(k+1)/2 - k*x |
| 5, south-west | (0, -1) | k*y - k(k+1)/2 | 0 |
| 6, west | (+1, -1) | 0 | 0 |

Each product of k values is even, so the half is exact. The shoelace term x*nextY - nextX*y adds double the area, and rhombCountB divides that area by two and subtracts both other counts.

The sample hexagon has six sides of length 2. The table shows one walk around it, from direction 1 through direction 6.

| Direction | k | Start (x, y) | Change to C | Change to A | Area term |
| --- | --- | --- | --- | --- | --- |
| 1 | 2 | (0, 0) | +1 | +0 | +0 |
| 2 | 2 | (2, 0) | +0 | -1 | +4 |
| 3 | 2 | (2, 2) | +0 | +0 | +8 |
| 4 | 2 | (0, 4) | +3 | +0 | +8 |
| 5 | 2 | (-2, 4) | +0 | +5 | +4 |
| 6 | 2 | (-2, 2) | +0 | +0 | +0 |

The sums give A = 4, C = 4, double area = 24, and B = 12 - 4 - 4 = 4, so the program prints `4 4 4`.

## Code

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const directionNorthWest = 1
const directionNorthEast = 2
const directionEast = 3
const directionSouthEast = 4
const directionSouthWest = 5
const directionWest = 6

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  return value
```

The read loop ends when `readLine` fails, so the whole stream is scanned once. The scanner skips whitespace and adds digit values, so it handles the spaces and line ends in the input. Both loops run once per input character.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

One buffer collects all answers, and a write happens only after 256 KiB collects. Reusing the buffer with `setLen 0` avoids a new allocation at each flush. The cost is one string add per case.

```nim
let caseCount = nextInt(inputData, i)
for j in 0..<caseCount:
  let sideCount = nextInt(inputData, i)
  var latticeX: int64 = 0
  var latticeY: int64 = 0
  var doubleArea: int64 = 0
  var totalRhombsA: int64 = 0
  var totalRhombsC: int64 = 0
  for k in 0..<sideCount:
    let direction = nextInt(inputData, i)
    let sideLength = int64(nextInt(inputData, i))
    var nextX = latticeX
    var nextY = latticeY
    case direction
    of directionNorthWest:
      nextX = latticeX + sideLength
      totalRhombsC += sideLength * latticeX + sideLength * (sideLength - 1) div 2
    of directionNorthEast:
      nextY = latticeY + sideLength
      totalRhombsA -= sideLength * latticeY + sideLength * (sideLength - 1) div 2
    of directionEast:
      nextX = latticeX - sideLength
      nextY = latticeY + sideLength
    of directionSouthEast:
      nextX = latticeX - sideLength
      totalRhombsC += sideLength * (sideLength + 1) div 2 - sideLength * latticeX
    of directionSouthWest:
      nextY = latticeY - sideLength
      totalRhombsA += sideLength * latticeY - sideLength * (sideLength + 1) div 2
    of directionWest:
      nextX = latticeX + sideLength
      nextY = latticeY - sideLength
    else:
      discard
    doubleArea += latticeX * nextY - nextX * latticeY
    latticeX = nextX
    latticeY = nextY
  let totalRhombsB = doubleArea div 2 - totalRhombsA - totalRhombsC
  appendOutput($(totalRhombsA) & " " & $(totalRhombsB) & " " & $(totalRhombsC))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The side loop runs exactly `sideCount` times, one time per side. The `int64` casts keep products of long sides safe. Updates use the position before the side, and `nextX` and `nextY` hold the position after it. The walk costs one pass with constant work per side.

## Complexity

Input reading takes time proportional to the input size and uses one string. The walk takes O(n) time per polygon with n sides and O(1) extra space, since it stores five running values. Output takes time proportional to the number of answers and uses one bounded buffer. The total is O(N) time and O(S) space, with N the total number of sides and S the input size. A tiling search would explore exponentially many splits.
