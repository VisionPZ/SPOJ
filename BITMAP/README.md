# BITMAP — Bitmap (SPOJ)
<https://www.spoj.com/problems/BITMAP/>

## Problem

Each case gives a grid of pixels marked white or black, with at least one white pixel. For every pixel, compute its Manhattan distance (sum of row and column gaps) to the nearest white pixel.

Input starts with a case count t, and blank lines separate cases. Each case gives n and m, then n strings of length m where '1' means white. At least one cell is white. Output n rows of m integers per case.

The bounds set the grid size:

| Quantity | Bound |
| --- | --- |
| Rows n | 1 to 182 |
| Columns m | 1 to 182 |
| White cells | at least one per bitmap |
| Time limit | 4000 ms |
| Memory limit | 1536 MB |

A full grid holds 33,124 cells, so two linear sweeps fit easily.

The sample input and output:

```
1
3 4
0001
0011
0110
```

```
3 2 1 0
2 1 0 0
1 0 0 1
```

The far top-left corner is three steps from the nearest white cell.

## Idea

Spread distances across the grid from each white pixel, like a wave advancing one cell per step. Set white cells to zero and every other cell to a large number. Sweep from the top-left, then from the bottom-right, and keep the smaller value at each cell. This is a two-pass distance transform (a table that replaces a search).

Each sweep visits each cell once and reads only the up, left, down, and right neighbours, so the cost is O(1) per cell. A queue-based multi-source search would push every cell and allocate queue state, which costs more on a 33,124-cell grid.

Takeaway: two sweeps replace a full search.

## Why It Works

1. A white pixel has distance zero, so it anchors every ripple.
2. Any neighbour of a cell with distance d has a distance of at most d + 1.
3. The top-left sweep propagates influence from up and left; the bottom-right sweep propagates from down and right.
4. A shortest Manhattan path to a white cell approaches from one of those four directions, so the two sweeps cover every case.
5. The smaller of the two sweep values is the true minimum.

The distance array uses one term per state.

| Term | Meaning |
| --- | --- |
| distance[cellIndex] | best distance known for that cell |
| infDistance | large stand-in for a cell not yet reached |
| candidate | neighbour distance plus one |
| nextBit | reads a single '0' or '1' token |

Each row maps to one part of the code.

A script traced the sample grid:

| Cell (row, col) | White? | Distance |
| --- | --- | --- |
| (0, 0) | no | 3 |
| (0, 2) | no | 1 |
| (0, 3) | yes | 0 |
| (2, 2) | yes | 0 |
| (2, 3) | no | 1 |

Bottom-right white cells keep zero, and the corner reaches three.

## Code

**Constants, scanner, and output helper.**
```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const infDistance = 1000000000

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextBit(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '0' and data[pos] != '1':
    pos += 1
  let value = int(data[pos]) - firstDigitValue
  pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```
The buffer gathers all input lines. `nextInt` skips non-digits, and `nextBit` skips to the next '0' or '1'. `appendOutput` flushes in blocks so the large output stays cheap.

**Grid setup.**
```nim
let caseCount = nextInt(inputData, scanPos)
var distance: seq[int] = @[]

for caseIndex in 0..<caseCount:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  let cellCount = rowCount * columnCount
  distance.setLen cellCount
  for cellIndex in 0..<cellCount:
    if nextBit(inputData, scanPos) == 1:
      distance[cellIndex] = 0
    else:
      distance[cellIndex] = infDistance
```
Each case resets `distance` to cellCount entries. A '1' token sets a cell to zero, and a '0' token sets it to infDistance. The flat index i times columnCount plus j addresses a cell.

**Forward sweep.**
```nim
  for i in 0..<rowCount:
    for j in 0..<columnCount:
      let cellIndex = i * columnCount + j
      if i > 0:
        let upIndex = cellIndex - columnCount
        let candidate = distance[upIndex] + 1
        if candidate < distance[cellIndex]:
          distance[cellIndex] = candidate
      if j > 0:
        let leftIndex = cellIndex - 1
        let candidate = distance[leftIndex] + 1
        if candidate < distance[cellIndex]:
          distance[cellIndex] = candidate
```
The first sweep reads the up and left neighbours. A candidate one step larger replaces the current value when it is smaller. The flat indices subtract columnCount and one.

**Backward sweep.**
```nim
  for k in 0..<rowCount:
    let i = rowCount - 1 - k
    for l in 0..<columnCount:
      let j = columnCount - 1 - l
      let cellIndex = i * columnCount + j
      if i < rowCount - 1:
        let downIndex = cellIndex + columnCount
        let candidate = distance[downIndex] + 1
        if candidate < distance[cellIndex]:
          distance[cellIndex] = candidate
      if j < columnCount - 1:
        let rightIndex = cellIndex + 1
        let candidate = distance[rightIndex] + 1
        if candidate < distance[cellIndex]:
          distance[cellIndex] = candidate
```
The second sweep walks rows and columns in reverse. It reads the down and right neighbours by adding columnCount and one. Together the two sweeps settle every cell.

**Output.**
```nim
  for i in 0..<rowCount:
    for j in 0..<columnCount:
      if j > 0:
        appendOutput " "
      appendOutput $(distance[i * columnCount + j])
    appendOutput "\n"

stdout.write outputBuffer
outputBuffer.setLen 0
```
Each row prints m values separated by spaces. The final write flushes the buffer tail, so no distance stays unwritten.

## Complexity

Work grows with the number of cells.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | one pass over input bytes | input bytes |
| Grid setup | O(n m) | cellCount integers |
| Two sweeps | 2 times O(n m) | same array |
| Output | one write per block | flushBlockBytes |
| Total per case | O(n m) | O(n m) |

Each cell is touched a constant number of times.

| Measure | Big O |
| --- | --- |
| Time per case | O(n m) |
| Space per case | O(n m) |

Checking every black-white pair would cost O((n m)^2), while two sweeps reach the same answer in linear time.
