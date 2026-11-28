# TILING — Rectangle Tiling (SPOJ)

<https://www.spoj.com/problems/TILING/>

## Problem

Cover a letter board with non-overlapping copies of one rectangular pattern and report the smallest pattern area. Copies keep the same orientation, and every board cell must be covered.

The first integer is the number of test cases. Each case starts with `n` rows and `m` columns, followed by `n` lines of `m` lowercase letters. Print the minimum area of a pattern that tiles the board.

| item | bound |
|---|---|
| test cases `t` | 1 to 100 |
| rows `n` | 1 to 1000 |
| columns `m` | 1 to 1000 |
| judge limit | 1000 ms, 1536 MB |

Let `h` and `w` be the height and width of a candidate pattern. A grid of such copies needs `h` to divide `n` and `w` to divide `m`.

Sample input:

```
3
4 3
aaa
aaa
aaa
aaa
4 4
abab
cdcd
abab
cdcd
3 4
aaaa
aaaa
aaab
```

Sample output:

```
1
4
12
```

## Idea

Think of a tile as a stamp: pressing the same stamp on a regular grid reproduces the board exactly. Only stamps whose height divides `n` and width divides `m` can form that grid. Try divisor pairs by increasing area and test the board against the top-left stamp; the first match is the answer. Searching all possible tilings would explore many placements, while divisor testing checks at most a few small stamps.

The table gives the cost of one candidate stamp.

| item | bound |
|---|---|
| candidate pairs | divisor count of `n` times divisor count of `m` |
| one test | n * m cell comparisons |

This cost shape stays small because divisor counts are low.

## Why It Works

1. A rectangular tile of height `h` and width `w` repeats every `h` rows and every `w` columns.
2. Covering `n` rows needs `n` to be a multiple of `h`.
3. Covering `m` columns needs `m` to be a multiple of `w`.
4. The top-left `h` by `w` block fixes every stamp position in that grid.
5. A board equals its reconstructed grid exactly when every cell matches the model cell.
6. Trying the smallest area first makes the first match the minimum area.

The table names the values used in the code.

| term | meaning |
|---|---|
| `rowDivisors` | heights dividing the row count |
| `columnDivisors` | widths dividing the column count |
| `patternHeight` | candidate tile height |
| `patternWidth` | candidate tile width |
| `tilesCleanly` | true when every cell matches its model |

Each candidate uses one pass over the board.

The worked example uses the third sample case, a 3 by 4 board. The script lists candidates by area.

```
(h,w) = (1,1) area 1   fails: last cell is b
(h,w) = (1,2) area 2   fails: last row columns 3 and 4 differ
(h,w) = (1,4) area 4   fails: last row differs from the first
(h,w) = (3,1) area 3   fails: last column is a a b
(h,w) = (3,2) area 6   fails: right half differs
(h,w) = (3,4) area 12  matches the whole board
answer = 12
```

The first four rows of the second sample case repeat a 2 by 2 stamp, giving area 4.

## Code

**Input and scanning.** The reader collects all lines and extracts integers and letter runs.

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

proc nextLetterRun(data: string, pos: var int, count: int): string =
  result = ""
  while result.len < count:
    while pos < data.len and (data[pos] < 'a' or data[pos] > 'z'):
      pos += 1
    if pos >= data.len:
      break
    result.add data[pos]
    pos += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The letter reader skips headers and line breaks. It returns one flat string of n * m letters. The writer flushes only whole blocks.

**Divisor search.** Each case enumerates divisor pairs and checks the board against the model block.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  let boardCells = nextLetterRun(inputData, scanPos, rowCount * columnCount)
  var rowDivisors: seq[int] = @[]
  var columnDivisors: seq[int] = @[]
  for candidate in 1 .. rowCount:
    if rowCount mod candidate == 0:
      rowDivisors.add candidate
  for candidate in 1 .. columnCount:
    if columnCount mod candidate == 0:
      columnDivisors.add candidate
  var bestArea = rowCount * columnCount
  for heightIndex in 0 .. rowDivisors.len - 1:
    let patternHeight = rowDivisors[heightIndex]
    for widthIndex in 0 .. columnDivisors.len - 1:
      let patternWidth = columnDivisors[widthIndex]
      let candidateArea = patternHeight * patternWidth
      if candidateArea >= bestArea:
        continue
      var tilesCleanly = true
      var rowIndex = 0
      while rowIndex < rowCount and tilesCleanly:
        let modelRow = rowIndex mod patternHeight
        var columnIndex = 0
        while columnIndex < columnCount:
          let modelColumn = columnIndex mod patternWidth
          if boardCells[rowIndex * columnCount + columnIndex] != boardCells[modelRow * columnCount + modelColumn]:
            tilesCleanly = false
            break
          columnIndex += 1
        rowIndex += 1
      if tilesCleanly:
        bestArea = candidateArea
  appendOutput($bestArea)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Divisors are collected once per case. A candidate with area at least the current best is skipped. The modulo index maps each cell to its model cell.

## Complexity

Each case enumerates divisor pairs and may scan the board for each pair.

| phase | time | space |
|---|---|---|
| input read | one pass over all letters | one input string and one board string |
| divisor search | divisor pairs times board size | two divisor arrays |
| output | one write per block | block buffer |

The board string is the largest structure.

| measure | Big O |
|---|---|
| time | O(t * d(n) * d(m) * n * m) worst case |
| space | O(n * m) |

Trying arbitrary tile placements would be far more expensive than testing a few divisor pairs.
