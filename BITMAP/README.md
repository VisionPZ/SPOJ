## Problem

Read t test cases, each with an n by m bitmap of '0' and '1' pixels, where '1' means white. For every pixel print the Manhattan distance to the nearest white pixel, as n rows of m space-separated integers. Blank lines separate test cases in the input.

The judge limits are these:

| Quantity | Bound |
| --- | --- |
| Rows n | 1 to 182 |
| Columns m | 1 to 182 |
| White pixels | at least one per bitmap |
| Test cases t | given on the first line |
| Time limit | 4000 ms |
| Memory limit | 1536 MB |

An 182 by 182 bitmap holds 33,124 cells, and the grid size sets the work per case.

Sample in, sample out:

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

## Idea

Compute a two-pass distance transform (a table of each cell's distance to the nearest white cell). Set white cells to zero and all other cells to a large value.

Sweep from the top-left, then sweep from the bottom-right, and keep the smaller value at each cell. The two sweeps replace a queue-based multi-source search, so no per-cell queue or visited state is needed.

Cost: O(1) work per cell per sweep.

Checking every pair of a black pixel and a white pixel costs far more than two scans.

## Why It Works

A shortest Manhattan path from a white pixel enters the current cell through one of four neighbours.

The first sweep reads the upper and left neighbours. These cover white pixels above or left of the cell.

The second sweep reads the lower and right neighbours, which cover the remaining positions. Together the sweeps reach every white pixel.

The update at each cell follows this rule:

distance[cell] = min(distance[cell], distance[neighbour] + 1)

The term distance[cell] keeps the best value found so far. The term distance[neighbour] reads a cell already processed in that sweep. The term + 1 adds the single step from the neighbour to the current cell.

For a 3 by 5 grid with one white pixel in the middle of the second row, the generator prints this grid and these distances:

```
00000
00100
00000
```

```
3 2 1 2 3
2 1 0 1 2
3 2 1 2 3
```

Each entry equals the row gap to the white pixel plus the column gap.

## Code

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
```

The read loop runs once per input line and stops at end of stream. The integer scanner skips blank lines and spaces, so the separator between cases needs no special case.

The bit scanner consumes exactly one binary digit at a time. Parsing costs one pass over the input buffer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

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

The digit value 48 turns a character into its number, and the flush threshold caps memory at 256 KiB. The distance sequence is resized per case and reused across cases. White cells start at zero, so they act as sources that propagate outward.

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

The row loop runs rowCount times and the column loop runs columnCount times. The guards `i > 0` and `j > 0` stop the program reading cells before the flat array. This sweep carries values from the top and left, and it costs one pass over all cells.

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

The reversed loops reach the bottom-right cell first by walking k and l forward. The guards `i < rowCount - 1` and `j < columnCount - 1` stop reads past the flat array. This sweep carries values from the bottom and right, and it costs one more pass over all cells.

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

Each row prints columnCount numbers with spaces between them and a newline at the end. The `j > 0` guard avoids a leading space on each line. The final write flushes any block still buffered after the last case.

## Complexity

Reading input takes time proportional to its length and uses one buffer. Each case initializes the grid in O(n*m) time and O(n*m) space. Each of the two sweeps costs O(n*m) time, and printing also costs O(n*m) time.

Total time is O(t*n*m) and total working space is O(n*m), where n and m are at most 182. A search from every black pixel to every white pixel costs O(n*m*w) for w white pixels, which grows far faster.
