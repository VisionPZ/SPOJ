# RHOMBS — Rhombs (SPOJ)

<https://www.spoj.com/problems/RHOMBS/>

## Problem

A polygon on a triangular grid can be tiled by rhombs of three orientations. Report the counts of each type in any valid tiling.

Input: `t` cases. Each starts with `n`, then `n` lines `d k`: a direction from 1 to 6 and a side length in triangle edges, listed clockwise. Output: three integers `A B C`, the counts for the three rhomb types.

The bounds from the statement:

| Item | Bound |
|---|---|
| Sides `n` | 3 ≤ n ≤ 50000 |
| Total side length | sum of all `k` ≤ 100000 |
| Directions | 1 through 6 on the triangular lattice |
| Judge limit | 7000 ms, 1536 MB |

No two consecutive sides lie on the same straight line.

The sample input and output:

```
1
6 
1 2 
2 2 
3 2 
4 2 
5 2 
6 2 
```

```
4 4 4
```

## Idea

Walk around the polygon and count diamonds as they appear in the wake of each side. Imagine tracing a tiled floor and counting the tiles your path exposes.

The program tracks lattice coordinates `(X, Y)` while walking. Each of the six directions updates `X` or `Y` and adjusts counters `A` and `C` with closed-form triangular sums. A shoelace sum (a cross-product formula for polygon area) computes twice the area.

Every diamond covers two unit triangles, so the total tile count is the area. Subtracting `A` and `C` leaves `B`.

Each side costs constant work, so a case costs O(n). Trying tilings by backtracking would grow exponentially with the perimeter.

A single boundary walk determines all three tile counts.

## Why It Works

Four facts carry the counting.

1. Each direction changes the lattice coordinates by a fixed vector. The code names them `directionNorthWest` through `directionWest`.
2. A side of length `k` passing coordinate `X` adds `k·X` plus the triangular number `k(k − 1)/2` rhombs of type `C`. The paired direction subtracts the same form, and `Y` plays the same role for type `A`.
3. The update `doubleArea += X·nextY − nextX·Y` sums signed cross-products around the boundary. Its absolute value gives twice the area in unit triangles.
4. Each rhomb covers two unit triangles, so `doubleArea / 2` is the total number of rhombs. Subtracting `A` and `C` gives `B`.

The values the walk maintains:

| Term | Meaning |
|---|---|
| `latticeX`, `latticeY` | current triangular-grid coordinates |
| `totalRhombsA`, `totalRhombsC` | running counts for tile types A and C |
| `doubleArea` | shoelace sum, twice the polygon area |
| `totalRhombsB` | remainder after subtracting A and C |

The shoelace sum closes the loop, so the walk returns to the origin.

A script-traced example with the sample hexagon, six sides of length 2:

```
step  dir  k  next (X,Y)   A    C    doubleArea
0     -    -  (0,0)        0    0    0
1     1    2  (2,0)        0    1    0
2     2    2  (2,2)       -1    1    4
3     3    2  (0,4)       -1    1   12
4     4    2  (-2,4)      -1    4   20
5     5    2  (-2,2)       4    4   24
6     6    2  (0,0)        4    4   24

area = 24 / 2 = 12
B = 12 - 4 - 4 = 4
output: 4 4 4
```

## Code

**Constants and scanner.** The six directions get named integer codes.

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

`firstDigitValue` supports the hand scanner. `nextInt` reads one integer by index, skipping whitespace between sides.

**Output helper.** One line holds the three counts.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`appendOutput` flushes at 256 KiB. The block path keeps output cost low on large inputs.

**Case loop.** Each side updates coordinates, tile counters, and the shoelace sum.

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

The `case` statement handles all six directions with named constants. Division by two stays exact because the summed terms are even. The final subtraction yields type B, and one line prints all three counts.

## Complexity

Each case walks the boundary once and prints one line.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Boundary walk | O(n) sides, constant work each | O(1) |
| Output | one write per 256 KiB block | 256 KiB |
| Total per case | O(n) | O(1) |

The walk keeps only a handful of integers.

| Measure | Big O |
|---|---|
| Time | O(n) per case |
| Space | O(1) per case, plus input and output buffers |

Searching for a tiling by backtracking would take exponential time in the perimeter.

The closed-form sums replace a search over tilings with one linear walk along the boundary.
