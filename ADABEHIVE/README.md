# ADABEHIVE — Ada and Behives (SPOJ)
<https://www.spoj.com/problems/ADABEHIVE/>

## Problem

A grid of hive populations supports two operations. A birth query adds bees to one cell. A region query asks for the total bees inside an axis-aligned rectangle. Print one total per region query.

The first line gives rows N, columns M and query count Q. Next come N rows of M population values. Each later line starts with 1 for a birth or 2 for a region. Use one-based coordinates throughout.

The bounds from the statement:

| Item | Bound |
|---|---|
| Rows N | 1 ≤ N ≤ 2000 |
| Columns M | 1 ≤ M ≤ 2000 |
| Queries Q | 1 ≤ Q ≤ 100000 |
| Judge time | 2000 ms |
| Judge memory | 1536 MB |

The query count drives the design; each query must stay near logarithmic.

The sample case:

```
6 5 8
1 2 3 4 5
1 2 3 4 5
6 6 6 6 6
5 4 3 2 1
5 4 3 2 1
6 6 6 6 6
2 1 1 6 5
2 1 1 2 4
2 4 2 5 4
1 5 4 4
1 1 1 665
2 1 1 6 5
2 1 1 2 4
2 4 2 5 4
```

```
120
20
18
789
685
22
```

## Idea

Use a two-dimensional Fenwick tree. Think of a stack of ledger pages, where each page records running totals for a range of rows. A point change updates one cell on every page that covers its row. A rectangle total comes from four prefix sums.

## Why It Works

1. A Fenwick node at index i holds a range of length `i and -i`.
2. A point update climbs row and column indices with that same low-bit step.
3. A prefix sum walks the same indices downward and adds each visited node.
4. Inclusion-exclusion turns four prefix sums into one rectangle total.

The main terms:

| Term | Meaning |
|---|---|
| `fenwick` | flat array holding the two-dimensional tree |
| `stride` | row length, equal to M + 1 |
| `addHive` | routine applying one point update |
| `prefixSum` | routine summing the rectangle from row 1, column 1 |

These terms show how one flat array replaces a grid of separate trees.

A script trace of the sample gives 120 for the whole grid. The birth of 665 at cell (1,1) raises that total to 789. Both values match the sample output.

## Code

**Input buffer and scanner.**
```nim
const firstDigitValue = 48
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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```
One read pass stores all bytes. The scanner reads every integer by index.

**Linear tree construction.**
```nim
let rowCount = nextInt(inputData, scanPos)
let colCount = nextInt(inputData, scanPos)
let queryCount = nextInt(inputData, scanPos)
let stride = colCount + 1
var fenwick = newSeq[int64](stride * (rowCount + 1))

for row in 1..rowCount:
  let base = row * stride
  for col in 1..colCount:
    let hiveSize = nextInt(inputData, scanPos)
    fenwick[base + col] += int64(hiveSize)
    let parent = col + (col and -col)
    if parent <= colCount:
      fenwick[base + parent] += fenwick[base + col]

for row in 1..rowCount:
  let parent = row + (row and -row)
  if parent <= rowCount:
    let base = row * stride
    let parentBase = parent * stride
    for col in 1..colCount:
      fenwick[parentBase + col] += fenwick[base + col]
```
The first loop builds each column tree. The second loop folds rows into parent rows. Together they cost one grid pass.

**Update and prefix routines.**
```nim
proc addHive(rowPos: int, colPos: int, delta: int64) =
  var row = rowPos
  while row <= rowCount:
    let base = row * stride
    var col = colPos
    while col <= colCount:
      fenwick[base + col] += delta
      col += col and -col
    row += row and -row

proc prefixSum(rowPos: int, colPos: int): int64 =
  var total: int64 = 0
  var row = rowPos
  while row > 0:
    let base = row * stride
    var col = colPos
    while col > 0:
      total += fenwick[base + col]
      col -= col and -col
    row -= row and -row
  return total

proc rectangleSum(firstRow: int, firstCol: int, lastRow: int, lastCol: int): int64 =
  return prefixSum(lastRow, lastCol) - prefixSum(firstRow - 1, lastCol) -
         prefixSum(lastRow, firstCol - 1) + prefixSum(firstRow - 1, firstCol - 1)
```
Both loops take logarithmic steps. Sums use int64 because totals exceed 32 bits.

**Query loop and flush.**
```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

for q in 0..<queryCount:
  let queryType = nextInt(inputData, scanPos)
  if queryType == 1:
    let rowPos = nextInt(inputData, scanPos)
    let colPos = nextInt(inputData, scanPos)
    let bornBees = nextInt(inputData, scanPos)
    addHive(rowPos, colPos, int64(bornBees))
  else:
    let firstRow = nextInt(inputData, scanPos)
    let firstCol = nextInt(inputData, scanPos)
    let lastRow = nextInt(inputData, scanPos)
    let lastCol = nextInt(inputData, scanPos)
    appendOutput($(rectangleSum(firstRow, firstCol, lastRow, lastCol)))
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```
Birth queries change the tree only. Region queries append one buffered line.

## Complexity

The one-time build is linear; each query is logarithmic in both dimensions.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Tree build | one pass over N times M cells | one int64 per cell |
| One query | O(log N log M) steps | constant |
| Output | one write per 128 KiB block | block buffer |

The build never applies millions of single point updates.

Big O uses G = N times M and Q as the query count.

| Measure | Big O |
|---|---|
| Time | O(G + Q log N log M) |
| Space | O(G) |

Rescanning the rectangle on every query would cost O(QG). The Fenwick tree removes that factor.
