# MARTIAN — Martian Mining (SPOJ)

<https://www.spoj.com/problems/MARTIAN/>

## Problem

A rectangular field has n rows and m columns. Each cell holds some yeyenum and some bloggium. Put one straight belt in each cell. It runs east to west toward the yeyenum factory or south to north toward the bloggium factory. Maximize minerals reaching the correct factory.

Yeyenum travels west along its row, so every cell west of an east-west belt must also carry an east-west belt. Bloggium travels north along its column, so every cell north of a south-north belt must also carry a south-north belt. Each row therefore has one split column: cells before it carry east-west belts and cells from it onward carry south-north belts. The splits must not decrease from one row to the next.

The first n lines hold yeyenum amounts, with row 0 northernmost and column 0 westernmost. The next n lines hold bloggium amounts in the same order. A block with n = m = 0 ends the input. Print one line per block with the maximum total.

The bounds size the grid:

| item | bound |
|---|---|
| rows n | 1 to 500 |
| columns m | 1 to 500 |
| minerals per cell | 0 to 1000 |
| judge limit | 2000 ms, 1536 MB |

The product n times m sets the work per block, and both dimensions reach 500.

Sample input:

```
4 4
0 0 10 9
1 3 10 0
4 2 1 3 
1 1 20 0
10 0 0 0
1 1 1 30
0 0 5 5
5 10 10 10
0 0
```

Sample output:

```
98
```

## Idea

Choosing belt directions is like drawing one staircase through a grid fence. Each row picks where the fence steps. Those steps only move right as you walk south. One scan down the rows settles the whole design.

For a fixed split column s in row i, the row collects yeyenum from columns 0 through s minus 1. It collects bloggium from columns s through m minus 1. The split is at least the largest split used in earlier rows, since a north belt must continue above every bloggium cell. A dynamic program over rows keeps the best total for each current split.

The trick removes a quadratic loop over pairs of splits. Taking a running maximum of the previous row costs one pass, so each cell is handled once.

## Why It Works

1. An east-west belt carries yeyenum west only if every cell west of it also carries an east-west belt.
2. A south-north belt carries bloggium north only if every cell above it also carries a south-north belt.
3. Let s be the first south-north column in a row. Then yeyenum from columns before s survives, and bloggium from columns s and later survives.
4. Let c be the largest split over earlier rows. Bloggium from row i survives only in columns at least max(c, s), so the next split is max(c, s).
5. The row contribution is the yeyenum prefix at s plus the bloggium suffix at the new split.
6. `prefixBest` stores the best earlier total for every split not exceeding the current one, which covers c at most the new split.
7. `bestMinerals` is the largest total over every final split.

Terms and formulas:

| term | meaning |
|---|---|
| `yPrefix` | row prefix sums of yeyenum, one entry per column boundary |
| `suffixTotals` | bloggium suffix sums for the current row |
| `previousBest` | best total before the row for each current split |
| `prefixBest` | running maximum of `previousBest` over splits |
| `currentBest` | best total after adding this row's contribution |

The running maximum compresses all earlier splits into one array.

The sample trace from gen.py:

```
row 1 best [10, 0, 0, 10, 19]
row 2 best [43, 43, 45, 54, 33]
row 3 best [53, 57, 61, 66, 64]
row 4 best [88, 88, 83, 98, 88]
```

Entry j in each line is the best total when the split after that row equals j. The last line peaks at 98, matching the sample answer.

## Code

**Input and row prefixes.** The reader packs all yeyenum rows into prefix sums.

```nim
const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const unreachableScore = -1 shl 50

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  if rowCount == 0 and columnCount == 0:
    break
  let prefixWidth = columnCount + 1
  var yPrefix = newSeq[int](rowCount * prefixWidth)
  for rowIndex in 0 .. rowCount - 1:
    let rowStart = rowIndex * prefixWidth
    for columnIndex in 0 .. columnCount - 1:
      let mineralAmount = nextInt(inputData, scanPos)
      yPrefix[rowStart + columnIndex + 1] = yPrefix[rowStart + columnIndex] + mineralAmount
```

Prefix entry j holds the first j yeyenum values of that row.
Reading all yeyenum first matches the two-matrix input layout.
The scan reads integers without allocating token strings.

**Row transition.** Each bloggium row builds suffix sums and advances the split DP.

```nim
  var previousBest = newSeq[int64](prefixWidth)
  var currentBest = newSeq[int64](prefixWidth)
  var prefixBest = newSeq[int64](prefixWidth)
  var bloggiumRow = newSeq[int](columnCount)
  var suffixTotals = newSeq[int](prefixWidth)
  previousBest[0] = 0
  for splitIndex in 1 .. columnCount:
    previousBest[splitIndex] = unreachableScore
  for rowIndex in 0 .. rowCount - 1:
    for columnIndex in 0 .. columnCount - 1:
      bloggiumRow[columnIndex] = nextInt(inputData, scanPos)
    suffixTotals[columnCount] = 0
    for columnIndex in countdown(columnCount - 1, 0):
      suffixTotals[columnIndex] = suffixTotals[columnIndex + 1] + bloggiumRow[columnIndex]
    var runningBest: int64 = unreachableScore
    for splitIndex in 0 .. columnCount:
      if previousBest[splitIndex] > runningBest:
        runningBest = previousBest[splitIndex]
      prefixBest[splitIndex] = runningBest
    let rowStart = rowIndex * prefixWidth
    for splitIndex in 0 .. columnCount:
      currentBest[splitIndex] = prefixBest[splitIndex] +
        int64(yPrefix[rowStart + splitIndex]) + int64(suffixTotals[splitIndex])
    let swapBuffer = previousBest
    previousBest = currentBest
    currentBest = swapBuffer
  var bestMinerals: int64 = unreachableScore
  for splitIndex in 0 .. columnCount:
    if previousBest[splitIndex] > bestMinerals:
      bestMinerals = previousBest[splitIndex]
  appendOutput($bestMinerals)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Split 0 starts with score zero before any row is read.
`countdown` builds suffix sums from the last column backward.
The two score arrays swap roles, so no row of the grid is copied.
Scores use 64 bits because totals reach 250 million per block.

## Complexity

Reading and the split scan dominate each block.

| phase | time | space |
|---|---|---|
| input read | one pass over 2 n m amounts | one input string |
| yeyenum prefixes | one pass over n rows | n rows of m + 1 sums |
| split DP | one transition per row and split | three arrays of m + 1 scores |
| output | one line per block | block buffer |

Only three score arrays stay live during the scan.

| measure | Big O |
|---|---|
| time | O(n * m) per block |
| space | O(n * m) |

Enumerating every split sequence costs O(n * m^2), while the running maximum cuts one factor of m.
The staircase constraint makes that shortcut exact.
